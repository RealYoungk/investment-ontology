import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/public_regular_business_source.dart';
import '../dart/dart_report_name.dart';
import 'ingest_jobs.dart';
import 'disclosure_sync.dart';
import 'api_call_budget.dart';

/// Internal normal-ingest service; no endpoint or credential bypass.
/// A verified periodic filing is registered; existing business ingest stores
/// the original body under its actual receipt, never under a substitute label.
abstract final class MissingRegularSourceRecovery {
  static Future<MissingRegularRecoveryProgress> recoverMissing(
    Session session,
    int jobId, {
    http.Client Function()? clientFactory,
    Duration interval = const Duration(seconds: 1),
    int limit = 20,
    String? corpCode,
  }) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job == null ||
        job.kind != DisclosureSync.businessKind ||
        job.status != IngestStatus.running) {
      throw StateError(
        'Missing regular source recovery requires normal running business job',
      );
    }
    final rows = await session.db.unsafeQuery(
      'SELECT c.id FROM company c WHERE c."stockCode" IS NOT NULL AND (CAST(@corpCode AS text) IS NULL OR c."corpCode"=@corpCode) AND NOT EXISTS(SELECT 1 FROM dart_filing f WHERE f."companyId"=c.id AND f."reportCode" IN (\'annual\',\'halfYear\',\'q1\',\'q3\')) ORDER BY c.id',
      parameters: QueryParameters.named({'corpCode': corpCode}),
    );
    var registered = 0,
        unidentified = 0,
        failed = 0,
        deferred = 0,
        attempted = 0;
    for (final row in rows) {
      if (await IngestJobs.isCancelled(session, jobId)) break;
      final company = (await Company.db.findById(
        session,
        row.toColumnMap()['id'] as int,
      ))!;
      final now = DateTime.now().toUtc(),
          day = ApiCallBudget.kstDay(DateTime.now());
      final reference =
          'regular-source-discovery-attempt:${company.corpCode}:$day';
      final prior = await Source.db.findFirstRow(
        session,
        where: (t) => t.reference.equals(reference),
        orderByList: (t) => [t.retrievedAt.desc()],
      );
      if (prior != null) {
        final audit = jsonDecode(prior.title) as Map;
        if (audit['status'] == 'unidentified') {
          unidentified++;
          continue;
        }
        if (audit['status'] == 'failed' &&
            prior.retrievedAt.add(const Duration(minutes: 15)).isAfter(now)) {
          failed++;
          continue;
        }
      }
      if (attempted >= limit.clamp(0, 20) || failed >= 6) {
        deferred++;
        continue;
      }
      attempted++;
      final client = clientFactory?.call() ?? http.Client();
      String status, reason;
      try {
        final success = await recover(
          session,
          jobId,
          company,
          client,
          interval: interval,
        );
        if (await IngestJobs.isCancelled(session, jobId)) break;
        status = success ? 'registered' : 'already_indexed';
        reason = 'Exact official periodic metadata and actual business body verified';
        if (success) registered++;
      } catch (error) {
        if (error is FormatException &&
            (error.message ==
                    'Regular report not identified by company navigation' ||
                error.message ==
                    'Unsupported or nonperiodic navigation source')) {
          status = 'unidentified';
          reason = error.message;
          unidentified++;
        } else {
          status = 'failed';
          reason = error is FormatException
              ? error.message
              : error.runtimeType.toString();
          failed++;
        }
      } finally {
        client.close();
      }
      if (await IngestJobs.isCancelled(session, jobId)) break;
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: reference,
          url: Uri.https('dart.fss.or.kr', '/navi/searchNavi.do', {
            'naviCode': 'A002',
            'naviCrpCik': company.corpCode,
            'naviCrpNm': company.name,
          }).toString(),
          retrievedAt: now,
          title: jsonEncode({
            'kind': 'public-regular-source-discovery-attempt',
            'scope': 'missing_periodic_filings',
            'corpCode': company.corpCode,
            'companyName': company.name,
            'jobId': jobId,
            'status': status,
            'reason': reason,
            'backoff': status == 'failed'
                ? '15 minutes'
                : status == 'unidentified'
                ? 'next KST day'
                : 'none',
            'validationNote': '탐색 상태 기록이며 보고서 자료없음/본문 수집 완료를 뜻하지 않음',
          }),
        ),
      );
    }
    return MissingRegularRecoveryProgress(
      registered,
      unidentified,
      failed,
      deferred,
    );
  }

  static Future<bool> recover(
    Session session,
    int jobId,
    Company company,
    http.Client client, {
    Duration interval = const Duration(seconds: 1),
  }) async {
    final job = await IngestJob.db.findById(session, jobId);
    if (job == null ||
        job.kind != DisclosureSync.businessKind ||
        job.status != IngestStatus.running ||
        company.id == null ||
        company.stockCode == null) {
      throw StateError(
        'Missing regular source recovery requires normal running business job',
      );
    }
    final known = await DartFiling.db.findFirstRow(
      session,
      where: (t) =>
          t.companyId.equals(company.id!) &
          t.reportCode.inSet({
            FinancialReportCode.annual,
            FinancialReportCode.halfYear,
            FinancialReportCode.q1,
            FinancialReportCode.q3,
          }),
    );
    if (known != null || await IngestJobs.isCancelled(session, jobId)) {
      return false;
    }
    final proof = await PublicRegularBusinessSource.fetch(
      client,
      corpCode: company.corpCode,
      companyName: company.name,
      fiscalMonth: company.fiscalMonth,
      interval: interval,
    );
    if (await IngestJobs.isCancelled(session, jobId)) return false;
    final parsed = DartReportName.parse(proof.reportName)!;
    final resolved = parsed.resolve(company.fiscalMonth)!;
    final code = parsed.kind == DartReportKind.halfYear
        ? FinancialReportCode.halfYear
        : FinancialReportCode.annual;
    return session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(hashtextextended(@receipt,0))',
        parameters: QueryParameters.named({'receipt': proof.metadata.receipt}),
        transaction: tx,
      );
      final current = await Company.db.findById(
        session,
        company.id!,
        transaction: tx,
      );
      final currentJob = await IngestJob.db.findById(
        session,
        jobId,
        transaction: tx,
      );
      if (currentJob?.status != IngestStatus.running) return false;
      if (current == null ||
          current.corpCode != company.corpCode ||
          current.fiscalMonth != company.fiscalMonth ||
          current.stockCode == null) {
        throw const FormatException('Changed discovery company identity');
      }
      final existing = await DartFiling.db.findFirstRow(
        session,
        where: (t) => t.rceptNo.equals(proof.metadata.receipt),
        transaction: tx,
      );
      if (existing != null) {
        if (existing.companyId != company.id ||
            existing.corpCode != company.corpCode ||
            existing.bsnsYear != resolved.bsnsYear ||
            existing.reportCode != code) {
          throw const FormatException('Conflicting discovered receipt');
        }
        return false;
      }
      final regular = await DartFiling.db.findFirstRow(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) &
            t.reportCode.inSet({
              FinancialReportCode.annual,
              FinancialReportCode.halfYear,
              FinancialReportCode.q1,
              FinancialReportCode.q3,
            }),
        transaction: tx,
      );
      if (regular != null) return false;
      final receipt = proof.metadata.receipt;
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          companyId: company.id,
          corpCode: company.corpCode,
          rceptNo: receipt,
          reportName: proof.reportName,
          bsnsYear: resolved.bsnsYear,
          reportCode: code,
          receivedDate: DateTime.utc(
            int.parse(receipt.substring(0, 4)),
            int.parse(receipt.substring(4, 6)),
            int.parse(receipt.substring(6, 8)),
          ),
          consolidatedStatus: FilingFetchStatus.pending,
          separateStatus: FilingFetchStatus.pending,
          discoveredAt: DateTime.now().toUtc(),
          lastError: 'verified-public-regular-source-metadata',
        ),
        transaction: tx,
      );
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: 'public-regular-source-metadata:$receipt',
          url: proof.metadata.coverSource.toString(),
          retrievedAt: DateTime.now().toUtc(),
          title: jsonEncode({
            'kind': 'public-regular-source-metadata',
            'corpCode': company.corpCode,
            'receipt': receipt,
            'reportName': proof.reportName,
            'discoverySource': proof.discoverySource.toString(),
            'shellSource': proof.metadata.shellSource.toString(),
            'coverSource': proof.metadata.coverSource.toString(),
            'metadataSha256': proof.metadata.digest,
            'periodStart': proof.metadata.periodStart.toIso8601String(),
            'periodEnd': proof.metadata.periodEnd.toIso8601String(),
            'businessBodySource': proof.body.sourceUri.toString(),
            'businessBodySha256': proof.body.bodySha256,
            'validationNote': '공식 법인코드·정기보고서 종류·표지기간·실제 사업본문 존재만 검증; 재무 금액 미검증·본문 저장은 정상 본문수집 경로',
          }),
        ),
        transaction: tx,
      );
      return true;
    });
  }
}

class MissingRegularRecoveryProgress {
  const MissingRegularRecoveryProgress(
    this.registered,
    this.unidentified,
    this.failed,
    this.deferred,
  );
  final int registered, unidentified, failed, deferred;
  String get message =>
      '공개 정기보고서 등록 $registered · 정기보고서 미식별 $unidentified기업 · 공개 탐색 오류 $failed기업 · 탐색 대기 $deferred기업';
}
