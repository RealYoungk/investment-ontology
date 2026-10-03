import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_api_key.dart';
import '../dart/dart_client.dart';
import '../dart/public_charter_source.dart';
import '../disclosure/charter_comparison_rules.dart';
import '../disclosure/charter_xml.dart';
import 'api_call_budget.dart';
import 'charter_hooks.dart';
import 'ingest_jobs.dart';

/// Administrator-started all-issuer source collection. No request-time AI.
class CharterFutureCall extends FutureCall {
  static const kind = 'charter_notices';
  static const snapshotKind = 'charterNotice';

  static bool _executing = false;

  Future<void> run(Session session) async {
    if (_executing) return;
    _executing = true;
    try {
      await _run(session);
    } finally {
      _executing = false;
    }
  }

  Future<void> _run(Session session) async {
    final active = await IngestJobs.latest(session, kind);
    if (active == null ||
        active.status == IngestStatus.succeeded ||
        active.status == IngestStatus.cancelled) {
      return;
    }
    final jobId = active.id!;
    final claimed = await IngestJobs.claim(session, jobId);
    if (claimed == null) return;
    IngestJob job = claimed;
    final key = DartApiKey.read(session);
    if (key == null) {
      await IngestJobs.fail(session, jobId, 'DART API 키가 설정되지 않았습니다.');
      return;
    }
    final client = DartClient(key);
    final meter = ApiCallMeter(ApiProvider.dart, () => client.calls);
    final priorCalls = job.apiCalls;
    try {
      final index = jsonDecode(
        await File('assets/charter/notice_index.json').readAsString(),
      ) as Map<String, dynamic>;
      final companies = await Company.db.find(
        session,
        where: (t) =>
            t.market.inSet({Market.kospi, Market.kosdaq, Market.konex}),
      );
      final byCode = {for (final c in companies) c.corpCode: c};
      final notices =
          (index['notices'] as List)
              .cast<Map<String, dynamic>>()
              .where((n) => byCode.containsKey(n['corpCode']))
              .toList()
            ..sort(
              (a, b) =>
                  (a['receipt'] as String).compareTo(b['receipt'] as String),
            );
      job.total = notices.length;
      // Bounded chunks let other scheduled jobs run; durable cursor survives restarts.
      final end = (job.processed + 40).clamp(0, notices.length);
      for (var i = job.processed; i < end; i++) {
        if (await IngestJobs.isCancelled(session, jobId)) return;
        if (await ApiCallBudget.reached(
          session,
          ApiProvider.dart,
          ApiCallBudget.dartDisclosureBudget,
        )) {
          job.message = '오늘 API 예산 소진 · 다음 날 같은 접수번호부터 이어받습니다.';
          await IngestJobs.save(session, job);
          await CharterHooks.schedule(
            session,
            jobId,
            ApiCallBudget.nextKstMidnight(DateTime.now())
                .add(const Duration(minutes: 10)),
          );
          return;
        }
        final n = notices[i],
            company = byCode[n['corpCode']]!,
            receipt = n['receipt'] as String;
        final existing = await ResearchSnapshot.db.findFirstRow(
          session,
          where: (t) =>
              t.companyId.equals(company.id!) &
              t.kind.equals(snapshotKind) &
              t.digest.equals(receipt),
        );
        if (existing == null) {
          try {
            final body = await _document(
              session,
              client,
              receipt,
              company.corpCode,
            );
            if (body == null) {
              job.failed++;
            } else {
              final url =
                  'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt';
              final data = {
                ...CharterComparisonRules.parse(body),
                'corpCode': company.corpCode,
                'receipt': receipt,
                'stage': 'proposal',
                'reportName': n['reportName'],
                'sourceUrl': url,
                'filingDate':
                    '${receipt.substring(0, 4)}-${receipt.substring(4, 6)}-${receipt.substring(6, 8)}',
                'sha256': sha256.convert(utf8.encode(body)).toString(),
                'retrievedAt': DateTime.now().toUtc().toIso8601String(),
              };
              await session.db.transaction((tx) async {
                final source = await Source.db.insertRow(
                  session,
                  Source(
                    kind: SourceKind.dartReport,
                    title: '주주총회소집공고 정관 비교표',
                    reference: receipt,
                    url: url,
                    retrievedAt: DateTime.now().toUtc(),
                  ),
                  transaction: tx,
                );
                data['source'] = source.toJson();
                await ResearchSnapshot.db.insertRow(
                  session,
                  ResearchSnapshot(
                    companyId: company.id!,
                    kind: snapshotKind,
                    provider: 'DART 원문 API',
                    payload: jsonEncode(data),
                    sourceId: source.id!,
                    digest: receipt,
                    createdAt: DateTime.now().toUtc(),
                  ),
                  transaction: tx,
                );
              });
              job.updated++;
            }
          } on DartApiException catch (e) {
            if (e.isFatal) rethrow;
            job.failed++;
          } on FormatException catch (e) {
            session.log(
              '정관 표 파싱 실패 $receipt · ${e.message}',
              level: LogLevel.warning,
            );
            job.failed++;
          }
        }
        await meter.flush(session);
        job.processed = i + 1;
        job.apiCalls = priorCalls + client.calls;
        job.message =
            '소집공고 ${job.processed}/${job.total}건 · 원문 확인 실패 ${job.failed}건';
        job = await IngestJobs.save(session, job);
      }
      if (job.processed >= notices.length) {
        job.status = IngestStatus.succeeded;
        job.finishedAt = DateTime.now().toUtc();
        job.message = job.failed == 0
            ? '전체 대상 원문 확인 완료 · 미확보 0건'
            : '전체 대상 조회 완료 · 실패 ${job.failed}건은 다시 실행하면 재시도합니다.';
        await IngestJobs.save(session, job);
      } else {
        await CharterHooks.schedule(
          session,
          jobId,
          DateTime.now().toUtc().add(const Duration(seconds: 10)),
        );
      }
    } catch (_) {
      await IngestJobs.fail(
        session,
        jobId,
        '정관 원문 수집 중단 · 저장된 자료는 유지됩니다. 다시 실행해 이어받으세요.',
        apiCalls: priorCalls + client.calls,
      );
    } finally {
      await meter.flush(session);
      client.close();
    }
  }

  /// Attachment-only corrections sometimes have no API XML; the official
  /// viewer remains usable and is independently bound to issuer and receipt.
  static Future<String?> _document(
    Session session,
    DartClient client,
    String receipt,
    String code,
  ) async {
    List<int>? bytes;
    try {
      bytes = await client.fetchDocument(receipt);
    } on DartApiException catch (e) {
      if (e.isFatal) rethrow;
      session.log(
        '정관 원문 API 재시도 대상 $receipt · 상태 ${e.status}',
        level: LogLevel.warning,
      );
    }
    if (bytes != null) {
      try {
        final body = CharterXml.boundDocument(bytes, code);
        CharterComparisonRules.parse(
          body,
        ); // A malformed XML grid may render correctly in HTML.
        return body;
      } on FormatException catch (e) {
        session.log(
          '정관 XML 검증 실패 $receipt · ${e.message}',
          level: LogLevel.warning,
        );
        // Try the independently validated official HTML representation.
      }
    }
    final reader = PublicCharterSource();
    try {
      return (await reader.fetch(receipt, code, notice: true)).document;
    } catch (e) {
      session.log(
        '정관 공식 화면 확인 실패 $receipt · $e',
        level: LogLevel.warning,
      );
      return null;
    } finally {
      reader.close();
    }
  }
}
