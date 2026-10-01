import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'financial_rows.dart';

/// Appends verified current core facts while preserving every legacy comparison
/// fact. This source-proved recovery is intentionally restricted to one receipt.
abstract final class FinancialCurrentCoreRecovery {
  static const receipt = '20250318001380';
  static const corpCode = '00855093';
  static const marker = 'verified-sunjin-current-core-once';
  static const ids = {
    'ifrs-full_Assets',
    'ifrs-full_Liabilities',
    'ifrs-full_Equity',
    'ifrs-full_Revenue',
    'dart_OperatingIncomeLoss',
    'ifrs-full_ProfitLoss',
    'ifrs-full_CashFlowsFromUsedInOperatingActivities',
  };
  static bool eligible(DartFiling f) =>
      f.rceptNo == receipt &&
      f.corpCode == corpCode &&
      f.bsnsYear == 2024 &&
      f.reportCode == FinancialReportCode.annual &&
      RegExp(r'사업보고서\s*\(2024\.12\)').hasMatch(f.reportName);

  static Future<bool> append(
    Session session, {
    required FinancialReport report,
    required DartFiling filing,
    required Company company,
    required FsDiv div,
    required List<Map<String, dynamic>> rows,
    required Uri source,
    required String digest,
  }) async {
    if (!eligible(filing) ||
        company.corpCode != corpCode ||
        filing.companyId != company.id ||
        report.rceptNo != receipt ||
        report.companyId != company.id ||
        report.bsnsYear != 2024 ||
        report.reportCode != FinancialReportCode.annual ||
        report.fsDiv != div ||
        report.reportName != filing.reportName ||
        source.scheme != 'https' ||
        source.host != 'dart.fss.or.kr' ||
        source.path != '/pdf/download/ifrs.do' ||
        source.queryParameters['rcp_no'] != receipt ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(digest) ||
        rows.length != 7 ||
        rows.any(
          (r) =>
              r['rcept_no'] != receipt ||
              r['corp_code'] != corpCode ||
              r['bsns_year'].toString() != '2024' ||
              r['reprt_code'] != '11011' ||
              r['currency'] != 'KRW' ||
              (r['fs_div'] != null &&
                  r['fs_div'] != FinancialCodes.fsDivToDart(div)) ||
              !ids.contains(r['account_id']),
        )) {
      return false;
    }
    final converted = FinancialRows.toFacts(
      rows,
      reportId: report.id!,
      companyId: company.id!,
      bsnsYear: 2024,
      reportCode: FinancialReportCode.annual,
      fsDiv: div,
      sourceId: report.sourceId,
    );
    final facts = converted.facts;
    if (converted.invalidAmounts != 0 ||
        converted.skippedRows != 0 ||
        facts.length != 7 ||
        facts.map((f) => f.accountId).toSet().length != 7 ||
        facts.any(
          (f) =>
              f.amount == null ||
              f.currency != 'KRW' ||
              f.priorAmount != null ||
              f.beforePriorAmount != null ||
              f.cumulativeAmount != null ||
              f.periodName != '2024-01-01~2024-12-31',
        )) {
      return false;
    }
    BigInt value(String id) =>
        facts.singleWhere((f) => f.accountId == id).amount!;
    if (value('ifrs-full_Assets') !=
        value('ifrs-full_Liabilities') + value('ifrs-full_Equity')) {
      return false;
    }
    return session.db.transaction((tx) async {
      await session.db.unsafeExecute(
        'SELECT pg_advisory_xact_lock(461103, @id)',
        parameters: QueryParameters.named({'id': report.id!}),
        transaction: tx,
      );
      await session.db.unsafeQuery(
        'SELECT id FROM financial_report WHERE id=@id FOR UPDATE',
        parameters: QueryParameters.named({'id': report.id!}),
        transaction: tx,
      );
      final current = (await FinancialReport.db.findById(
        session,
        report.id!,
        transaction: tx,
      ))!;
      if (current.companyId != company.id ||
          current.rceptNo != receipt ||
          current.bsnsYear != 2024 ||
          current.reportCode != FinancialReportCode.annual ||
          current.fsDiv != div ||
          current.reportName != filing.reportName) {
        return false;
      }
      final old = await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(report.id!),
        transaction: tx,
      );
      final auditRef = 'financial-current-core-recovery:${report.id}';
      final audit = await Source.db.findFirstRow(
        session,
        where: (t) => t.reference.equals(auditRef),
        transaction: tx,
      );
      if (audit != null) {
        final payload = jsonDecode(audit.title) as Map;
        final primary = await Source.db.findById(
          session,
          current.sourceId,
          transaction: tx,
        );
        if (primary == null ||
            primary.kind != SourceKind.dartReport ||
            primary.reference != receipt ||
            primary.url != source.toString() ||
            payload['newSourceId'] != current.sourceId ||
            payload['sha256'] != digest ||
            payload['receipt'] != receipt ||
            payload['corpCode'] != corpCode ||
            payload['basis'] != div.name ||
            !primary.title.startsWith('DART 원문 XBRL 당기 핵심계정 복구') ||
            current.supersededById != null) {
          return false;
        }

        final active = old
            .where((f) => f.sourceId == current.sourceId)
            .toList();
        return active.length == 7 &&
            facts.every(
              (f) => active.any(
                (a) =>
                    a.reportId == current.id &&
                    a.companyId == company.id &&
                    a.bsnsYear == 2024 &&
                    a.fsDiv == div &&
                    a.reportCode == FinancialReportCode.annual &&
                    a.supersededById == null &&
                    a.cumulativeAmount == null &&
                    a.statement == f.statement &&
                    a.accountDetail == f.accountDetail &&
                    a.accountName == f.accountName &&
                    a.priorAmount == null &&
                    a.beforePriorAmount == null &&
                    a.accountId == f.accountId &&
                    a.amount == f.amount &&
                    a.currency == f.currency &&
                    a.periodName == f.periodName,
              ),
            );
      }
      if (old.isEmpty ||
          old.any((f) => f.amount != null || f.cumulativeAmount != null) ||
          current.sourceId != report.sourceId) {
        return false;
      }
      if (current.supersededById != null ||
          old.any((f) => f.supersededById != null) ||
          await FinancialReport.db.count(
                session,
                where: (t) => t.supersededById.equals(current.id!),
                transaction: tx,
              ) >
              0 ||
          await FinancialFact.db.count(
                session,
                where: (t) =>
                    t.supersededById.inSet(old.map((f) => f.id!).toSet()),
                transaction: tx,
              ) >
              0) {
        return false;
      }
      final priorSource = await Source.db.findById(
        session,
        current.sourceId,
        transaction: tx,
      );
      if (priorSource == null ||
          priorSource.reference != receipt ||
          priorSource.kind != SourceKind.dartReport ||
          !priorSource.title.startsWith('DART 전체 재무제표')) {
        return false;
      }
      final now = DateTime.now().toUtc();
      final fresh = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: receipt,
          url: source.toString(),
          retrievedAt: now,
          title:
              'DART 원문 XBRL 당기 핵심계정 복구 · 현재 7계정만 복구; 7계정 밖 미복구 · 기존 비교값 SourceID:${priorSource.id} · ${priorSource.title} · ${priorSource.url} · SHA256:$digest',
        ),
        transaction: tx,
      );
      await FinancialFact.db.insert(session, [
        for (final f in facts) f.copyWith(sourceId: fresh.id!),
      ], transaction: tx);
      await FinancialReport.db.updateRow(
        session,
        current.copyWith(
          sourceId: fresh.id!,
          factCount: old.length + 7,
          fetchedAt: now,
        ),
        transaction: tx,
      );
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          reference: auditRef,
          url: source.toString(),
          retrievedAt: now,
          title: jsonEncode({
            'action': 'append-verified-current-seven-preserve-comparison-facts',
            'receipt': receipt,
            'corpCode': corpCode,
            'basis': div.name,
            'oldSourceId': priorSource.id,
            'newSourceId': fresh.id,
            'oldSourceTitle': priorSource.title,
            'oldSourceUrl': priorSource.url,
            'preservedFactIds': old.map((f) => f.id).toList(),
            'sha256': digest,
            'note': '당기 7계정만 원문 검증; 기존 비교값·숫자·출처·정정 관계 불변, 전체 재무제표 복구 아님',
          }),
        ),
        transaction: tx,
      );
      return true;
    });
  }
}
