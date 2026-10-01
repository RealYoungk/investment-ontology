import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http/testing.dart';

import 'package:http/http.dart' as http;
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_document.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/disclosure_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/api_call_budget.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod/protocol.dart' as sp;
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_jobs.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'disclosure_sync_test.dart' show FakeDisclosures;
import 'test_tools/serverpod_test_tools.dart';

class BrokenPublicBody extends PublicBusinessDocument {
  int calls = 0;
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    calls++;
    throw http.ClientException('transient fixture');
  }
}

class ProgressPublicBody extends PublicBusinessDocument {
  ProgressPublicBody(this.onTwentyFirst);
  final Future<void> Function() onTwentyFirst;
  int calls = 0;
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    calls++;
    if (calls == 21) await onTwentyFirst();
    return PublicBusinessBody(
      receipt: receipt,
      title: '사업의 내용',
      text: '제품과 사용처 원문',
      sourceUri: Uri.parse(
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt',
      ),
      bodySha256: 'fixture',
    );
  }
}

class SelectivePublicBody extends PublicBusinessDocument {
  SelectivePublicBody(this.blocked);
  final Set<String> blocked;
  final receipts = <String>[];
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    receipts.add(receipt);
    if (blocked.contains(receipt)) throw const PublicBusinessNodeMissing();
    return PublicBusinessBody(
      receipt: receipt,
      title: '사업의 내용',
      text: '공개 회사 제품 사업본문',
      sourceUri: Uri.parse(
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt',
      ),
      bodySha256: 'fixture',
    );
  }
}

class OneTimeoutPublicBody extends SelectivePublicBody {
  OneTimeoutPublicBody(this.timeoutReceipt) : super({});
  final String timeoutReceipt;
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    if (receipt == timeoutReceipt) {
      receipts.add(receipt);
      throw TimeoutException('source fixture timeout');
    }
    return super.fetch(receipt);
  }
}

class OverlappingPublicBody extends SelectivePublicBody {
  OverlappingPublicBody() : super({});
  final first = Completer<void>();
  final active = <String>[];
  int peak = 0;
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    active.add(receipt);
    if (active.length > peak) peak = active.length;
    if (receipts.isEmpty) {
      receipts.add(receipt);
      await first.future;
    } else {
      receipts.add(receipt);
      first.complete();
    }
    active.remove(receipt);
    return PublicBusinessBody(
      receipt: receipt,
      title: '사업의 내용',
      text: '제품 원문 $receipt',
      sourceUri: Uri.parse(
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt',
      ),
      bodySha256: 'fixture',
    );
  }
}

class ForeignReceiptPublicBody extends SelectivePublicBody {
  ForeignReceiptPublicBody() : super({});
  @override
  Future<PublicBusinessBody> fetch(String receipt) =>
      super.fetch('20260310999999');
}

class CancelAfterHttpBody extends SelectivePublicBody {
  CancelAfterHttpBody(this.cancel) : super({});
  final Future<void> Function() cancel;
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    final body = await super.fetch(receipt);
    await cancel();
    return body;
  }
}

class ActualOriginalPublicBody extends PublicBusinessDocument {
  ActualOriginalPublicBody(String receipt, this.target)
    : super(
        client: MockClient((request) async {
          final name = request.url.path == '/dsaf001/main.do'
              ? 'shell'
              : 'business';
          return http.Response(
            File('test/fixtures/business_apiwait/$receipt/$name.html')
                .readAsStringSync(),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
  final String target;
  final receipts = <String>[];
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    receipts.add(receipt);
    if (receipt == target) throw const PublicBusinessNodeMissing();
    return super.fetch(receipt);
  }
}

void main() {
  withServerpod('Business-only collection', (anonymous, endpoints) {
    late Session session;
    late FakeDisclosures client;
    late Company company;
    final resumes = <DateTime>[];
    final now = DateTime.utc(2026, 10, 2);
    setUp(() async {
      session = anonymous.asAdmin.build();
      client = FakeDisclosures();
      resumes.clear();
      company = await Company.db.insertRow(
        session,
        Company(
          corpCode: '00000001',
          name: '본문회사',
          market: Market.kospi,
          stockCode: '000001',
        ),
      );
    });
    Future<DartFiling> filing(
      int year,
      String receipt, {
      FinancialReportCode code = FinancialReportCode.annual,
      String? name,
    }) async {
      final f = await DartFiling.db.insertRow(
        session,
        DartFiling(
          corpCode: company.corpCode,
          companyId: company.id,
          rceptNo: receipt,
          bsnsYear: year,
          reportCode: code,
          reportName:
              name ??
              (code == FinancialReportCode.annual
                  ? '사업보고서 ($year.12)'
                  : '반기보고서 ($year.06)'),
          receivedDate: now,
          discoveredAt: now,
          consolidatedStatus: FilingFetchStatus.stored,
          separateStatus: FilingFetchStatus.stored,
        ),
      );
      client.documents[receipt] = '<DOCUMENT><TITLE>II. 사업의 내용</TITLE><P>회사 제품의 사용처 설명</P><TITLE>III. 재무에 관한 사항</TITLE></DOCUMENT>';
      return f;
    }

    Future<IngestJob> run({
      int limit = 9000,
      int runLimit = 200,
      int? daily = 18000,
      PublicBusinessDocument? public,
      bool only = true,
    }) async {
      final j = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: only ? DisclosureSync.businessKind : DisclosureSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      await DisclosureSync(
        session,
        client.client(),
        j.id!,
        businessOnly: only,
        businessBudget: limit,
        businessRunLimit: runLimit,
        dailyBudget: daily,
        publicFallbackEnabled: public != null,
        publicDocuments: public,
        businessAnchorClientFactory: () => MockClient(
          (r) async => http.Response.bytes(
            utf8.encode(
              "openCorpInfoNew('${company.corpCode}', 'winCorpInfo', '/dsae001/selectPopup.ax');openPdfDownload('${r.url.queryParameters['rcpNo']}', '1');<select id='family'></select>",
            ),
            200,
            request: r,
          ),
        ),
        clock: () => now,
        callInterval: Duration.zero,
        scheduleResume: (at) async {
          resumes.add(at);
        },
      ).run();
      return (await IngestJob.db.findById(session, j.id!))!;
    }

    test('final revisions, five annual years and latest interim only; no 28 status mutation', () async {
      for (var y = 2019; y <= 2025; y++) {
        await filing(y, '${y + 1}0310000001');
      }
      final finalAnnual = await filing(2025, '20260410000001');
      await filing(2026, '20260515000001', code: FinancialReportCode.q1);
      await filing(2026, '20260814000001', code: FinancialReportCode.halfYear);
      final untouched = await DartFilingSection.db.insertRow(
        session,
        DartFilingSection(
          filingId: finalAnnual.id!,
          companyId: company.id!,
          bsnsYear: 2025,
          section: DartSection.executives,
          tier: 0,
          status: FilingFetchStatus.failed,
          attempts: 2,
        ),
      );
      final job = await run();
      final receipts = (await BusinessDocument.db.find(session))
          .map((d) => d.rceptNo)
          .toSet();
      expect(receipts, {
        '20220310000001',
        '20230310000001',
        '20240310000001',
        '20250310000001',
        '20260410000001',
        '20260814000001',
      });
      expect(client.calls.every((c) => c.startsWith('document|')), isTrue);
      expect(
        (await DartFilingSection.db.findById(session, untouched.id!))!.status,
        FilingFetchStatus.failed,
      );
      expect(
        (await DartFilingSection.db.findById(session, untouched.id!))!.attempts,
        2,
      );
      expect(await DartFilingSection.db.count(session), 7);
      expect(job.processed, 6);
      expect(resumes, isEmpty);
    });
    test('bounded slice resumes healthy remaining without repeating stored receipts', () async {
      for (var y = 2021; y <= 2025; y++) {
        await filing(y, '${y + 1}0310000001');
      }
      final first = await run(limit: 2);
      expect(first.total, 5);
      expect(first.processed, 2);
      expect(resumes.single, now.add(const Duration(seconds: 30)));
      final second = await run();
      expect(second.processed, 3);
      expect(await BusinessDocument.db.count(session), 5);
    });
    test('independent run limit yields after two annual bodies then resumes only the remaining one', () async {
      for (final year in [2023, 2024, 2025]) {
        await filing(year, '${year + 1}0310000001');
      }
      final first = await run(runLimit: 2);
      expect(first.total, 3);
      expect(first.processed, 2);
      expect(first.updated, 2);
      expect(first.message, contains('남은 전체 1'));
      expect(resumes, [now.add(const Duration(seconds: 30))]);
      expect(await BusinessDocument.db.count(session), 2);
      final firstReceipts = client.calls
          .where((c) => c.startsWith('document|'))
          .toList();
      expect(firstReceipts, hasLength(2));
      client.calls.clear();
      resumes.clear();
      final second = await run(runLimit: 2);
      expect(second.total, 1);
      expect(second.processed, 1);
      expect(second.updated, 1);
      expect(second.message, contains('남은 전체 0'));
      expect(resumes, isEmpty);
      expect(await BusinessDocument.db.count(session), 3);
      final secondReceipts = client.calls
          .where((c) => c.startsWith('document|'))
          .toList();
      expect(secondReceipts, hasLength(1));
      expect(firstReceipts, isNot(contains(secondReceipts.single)));
      expect(client.calls.every((c) => c.startsWith('document|')), isTrue);
    });
    test('fresh bodies proceed after one timeout and failed-only remainder backs off', () async {
      for (final year in [2023, 2024, 2025]) {
        await filing(year, '${year + 1}0310000001');
      }
      final body = OneTimeoutPublicBody('20260310000001');
      final first = await run(runLimit: 1, daily: 0, public: body);
      expect(first.failed, 1);
      expect(first.updated, 0);
      expect(resumes, [now.add(const Duration(seconds: 30))]);
      expect(body.receipts, ['20260310000001']);
      resumes.clear();
      final second = await run(runLimit: 1, daily: 0, public: body);
      expect(second.updated, 1);
      expect(second.failed, 0);
      expect(body.receipts.last, '20250310000001');
      expect(resumes, [now.add(const Duration(seconds: 30))]);
      resumes.clear();
      final third = await run(runLimit: 1, daily: 0, public: body);
      expect(third.updated, 1);
      expect(third.failed, 0);
      expect(body.receipts.last, '20240310000001');
      expect(resumes, [now.add(const Duration(minutes: 15))]);
      expect(await BusinessDocument.db.count(session), 2);
      final section = await DartFilingSection.db.findFirstRow(
        session,
        where: (t) => t.attempts.equals(1),
      );
      expect(section!.attempts, 1);
      resumes.clear();
      final fourth = await run(runLimit: 1, daily: 0, public: body);
      expect(fourth.failed, 1);
      expect(body.receipts.last, '20260310000001');
      expect(resumes, [now.add(const Duration(minutes: 15))]);
    });
    test('API-zero HTTP overlap keeps exact receipt sources and sequential storage', () async {
      await filing(2025, '20260310000001');
      await filing(2024, '20250310000001');
      final reader = OverlappingPublicBody();
      final job = await run(daily: 0, public: reader);
      expect(job.updated, 2);
      expect(job.apiCalls, 0);
      expect(reader.peak, 2);
      expect(client.calls, isEmpty);
      final docs = await BusinessDocument.db.find(session);
      expect(docs.length, 2);
      for (final doc in docs) {
        expect(doc.text, contains(doc.rceptNo));
        final report = await DisclosureReport.db.findById(
          session,
          doc.reportId,
        );
        expect(report!.rceptNo, doc.rceptNo);
        final source = await Source.db.findById(session, report.sourceId);
        expect(source!.reference, doc.rceptNo);
      }
    });
    test(
      'cancellation after HTTP prevents storage and the reserved second launch',
      () async {
        await filing(2025, '20260310000001');
        await filing(2024, '20250310000001');
        final reader = CancelAfterHttpBody(() async {
          final job = (await IngestJobs.latest(
            session,
            DisclosureSync.businessKind,
          ))!;
          await IngestJob.db.updateRow(
            session,
            job.copyWith(status: IngestStatus.cancelled),
          );
        });
        final job = await run(daily: 0, public: reader);
        expect(job.status, IngestStatus.cancelled);
        expect(job.updated, 0);
        expect(reader.receipts, ['20260310000001']);
        expect(await BusinessDocument.db.count(session), 0);
        expect(resumes, isEmpty);
      },
    );

    test(
      'prefetched foreign receipt never reaches source or body storage',
      () async {
        await filing(2025, '20260310000001');
        final job = await run(daily: 0, public: ForeignReceiptPublicBody());
        expect(job.updated, 0);
        expect(job.failed, 1);
        expect(await BusinessDocument.db.count(session), 0);
        final section = (await DartFilingSection.db.find(session)).single;
        expect(section.attempts, 1);
        expect(section.status, FilingFetchStatus.failed);
      },
    );

    test('public six-failure circuit preserves remainder and retries in 15 minutes', () async {
      for (var i = 0; i < 8; i++) {
        final c = await Company.db.insertRow(
          session,
          Company(
            corpCode: '0000010$i',
            name: '공개$i',
            market: Market.kospi,
            stockCode: '00010$i',
          ),
        );
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            corpCode: c.corpCode,
            companyId: c.id,
            rceptNo: '2026031000010$i',
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2025.12)',
            receivedDate: now,
            discoveredAt: now,
            consolidatedStatus: FilingFetchStatus.stored,
            separateStatus: FilingFetchStatus.stored,
          ),
        );
      }
      final reader = BrokenPublicBody();
      final job = await run(daily: 0, public: reader);
      expect(reader.calls, 6);
      expect(job.processed, 6);
      expect(client.calls, isEmpty);
      expect(resumes.single, now.add(const Duration(minutes: 15)));
      expect(
        await DartFilingSection.db.count(
          session,
          where: (t) => t.status.equals(FilingFetchStatus.pending),
        ),
        2,
      );
    });
    test('default 28 job yields before API calls while requested body job survives restart', () async {
      await filing(2025, '20260310000001');
      await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: DisclosureSync.businessKind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final job = await run(only: false);
      expect(client.calls, isEmpty);
      expect(job.status, IngestStatus.succeeded);
      expect(resumes.single, now.add(const Duration(minutes: 15)));
      expect(await DartFilingSection.db.count(session), 0);
    });
    test(
      'queued body resume makes earlier 28 call yield before a job exists',
      () async {
        await filing(2025, '20260310000001');
        await sp.FutureCallEntry.db.insertRow(
          session,
          sp.FutureCallEntry(
            name: 'DisclosureResumeBusinessFutureCall',
            time: now.add(const Duration(seconds: 10)),
            serverId: 'test',
            identifier: 'business_documents_resume',
          ),
        );
        final job = await run(only: false);
        expect(client.calls, isEmpty);
        expect(job.processed, 0);
        expect(resumes.single, now.add(const Duration(minutes: 15)));
      },
    );
    test('restart retains serialized business run job instead of creating duplicates', () async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: DisclosureSync.businessKind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      await sp.FutureCallEntry.db.insertRow(
        session,
        sp.FutureCallEntry(
          name: 'DisclosureRunBusinessFutureCall',
          time: now,
          serverId: 'test',
          serializedObject: '{"jobId":${job.id}}',
        ),
      );
      final result = await IngestJobs.recoverInterrupted(session);
      expect(result.rerunning, contains(DisclosureSync.businessKind));
      expect(result.orphaned, isNot(contains(DisclosureSync.businessKind)));
      expect(
        (await IngestJob.db.findById(session, job.id!))!.status,
        IngestStatus.running,
      );
    });
    test(
      'progress is persisted at twenty before twenty-first fetch completes',
      () async {
        for (var i = 0; i < 21; i++) {
          final c = await Company.db.insertRow(
            session,
            Company(
              corpCode: '000002${i.toString().padLeft(2, '0')}',
              name: '진척$i',
              market: Market.kospi,
              stockCode: '0002${i.toString().padLeft(2, '0')}',
            ),
          );
          await DartFiling.db.insertRow(
            session,
            DartFiling(
              corpCode: c.corpCode,
              companyId: c.id,
              rceptNo: '202603100002${i.toString().padLeft(2, '0')}',
              bsnsYear: 2025,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (2025.12)',
              receivedDate: now,
              discoveredAt: now,
              consolidatedStatus: FilingFetchStatus.stored,
              separateStatus: FilingFetchStatus.stored,
            ),
          );
        }
        final reader = ProgressPublicBody(() async {
          final job = await IngestJobs.latest(
            session,
            DisclosureSync.businessKind,
          );
          expect(job!.processed, 20);
          expect(job.updated, 20);
          expect(job.status, IngestStatus.running);
        });
        final job = await run(daily: 0, public: reader);
        expect(reader.calls, 21);
        expect(job.processed, 21);
      },
    );
    test('ordinary corrected legacy stored row is refetched; explicit attachment reuses real period body', () async {
      await filing(2025, '20260310000001');
      await run();
      final correction = await filing(
        2025,
        '20260410000001',
        name: '[기재정정]사업보고서 (2025.12)',
      );
      await DartFilingSection.db.insertRow(
        session,
        DartFilingSection(
          filingId: correction.id!,
          companyId: company.id!,
          bsnsYear: 2025,
          section: DartSection.businessContent,
          tier: 2,
          status: FilingFetchStatus.stored,
          attempts: 0,
        ),
      );
      final fixed = await run();
      expect(fixed.processed, 1);
      expect(
        (await BusinessDocument.db.find(session)).map((d) => d.rceptNo),
        contains(correction.rceptNo),
      );
      final attachment = await filing(
        2025,
        '20260411000001',
        name: '[첨부정정]사업보고서 (2025.12)',
      );
      await DartFilingSection.db.insertRow(
        session,
        DartFilingSection(
          filingId: attachment.id!,
          companyId: company.id!,
          bsnsYear: 2025,
          section: DartSection.businessContent,
          tier: 2,
          status: FilingFetchStatus.pending,
          attempts: 0,
        ),
      );
      final count = client.calls.length;
      final reconciled = await run();
      expect(reconciled.processed, 0);
      expect(client.calls.length, count);
      expect(
        (await DartFilingSection.db.findFirstRow(
          session,
          where: (t) => t.filingId.equals(attachment.id!),
        ))!.status,
        FilingFetchStatus.stored,
      );
    });
    test('same-year June and December bodies stay separate in fallback, coverage and supersession', () async {
      final june = await filing(
        2025,
        '20250810000001',
        name: '사업보고서 (2025.06)',
      );
      await run();
      final december = await filing(
        2025,
        '20260310000001',
        name: '사업보고서 (2025.12)',
      );
      await run();
      final reports = await DisclosureReport.db.find(session);
      expect(reports, hasLength(2));
      expect(reports.every((r) => r.supersededById == null), isTrue);
      final decReport = reports.singleWhere(
        (r) => r.rceptNo == december.rceptNo,
      );
      // A legacy undated body is usable only through its exact source filing.
      final juneReport = reports.singleWhere((r) => r.rceptNo == june.rceptNo);
      await DisclosureReport.db.updateRow(
        session,
        juneReport.copyWith(settlementDate: null),
      );
      final juneAttachment = await filing(
        2025,
        '20260409000001',
        name: '[첨부정정]사업보고서 (2025.06)',
      );
      client.documents.remove(juneAttachment.rceptNo);
      final priorCalls = client.calls.length;
      await run();
      expect(client.calls.length, priorCalls);
      expect(
        (await DartFilingSection.db.findFirstRow(
          session,
          where: (t) =>
              t.filingId.equals(juneAttachment.id!) &
              t.section.equals(DartSection.businessContent),
        ))!.status,
        FilingFetchStatus.stored,
      );

      await BusinessDocument.db.deleteWhere(
        session,
        where: (t) => t.reportId.equals(decReport.id!),
      );
      await DisclosureReport.db.deleteRow(session, decReport);
      final attachment = await filing(
        2025,
        '20260410000001',
        name: '[첨부정정]사업보고서 (2025.12)',
      );
      client.documents.remove(attachment.rceptNo);
      client.documents.remove(december.rceptNo);
      final reader = SelectivePublicBody({
        attachment.rceptNo,
        december.rceptNo,
      });
      final job = await run(public: reader);
      expect(job.processed, greaterThan(0));
      expect(reader.receipts, isNot(contains(june.rceptNo)));
      final section = (await DartFilingSection.db.findFirstRow(
        session,
        where: (t) =>
            t.filingId.equals(attachment.id!) &
            t.section.equals(DartSection.businessContent),
      ))!;
      expect(section.status, isNot(FilingFetchStatus.stored));
    });
    test('August attachment finds March original beyond 120 days and consumes all bounded listing pages', () async {
      final attachment = await filing(
        2025,
        '20260813001590',
        name: '[첨부정정]사업보고서 (2025.12)',
      );
      client.documents.remove(attachment.rceptNo);
      client.documents['20260319000984'] = '<DOCUMENT><TITLE>II. 사업의 내용</TITLE><P>원본 제품 설명</P><TITLE>III. 재무에 관한 사항</TITLE></DOCUMENT>';
      client.filingPages[1] = [
        ('20260301000001', '사업보고서 (2025.06)', '20260301'),
      ];
      client.filingPages[2] = [
        ('20260319000984', '사업보고서 (2025.12)', '20260319'),
      ];
      final job = await run();
      expect(job.updated, 1);
      expect(client.filingQueries.map((q) => q['page_no']), ['1', '2']);
      expect(
        client.filingQueries.every(
          (q) => q['bgn_de'] == '20251201' && q['last_reprt_at'] == 'N',
        ),
        isTrue,
      );
      expect(
        (await BusinessDocument.db.find(session)).single.rceptNo,
        '20260319000984',
      );
      expect(client.calls, isNot(contains('document|20260301000001')));
    });
    test('attachment listing budget exhausted before next page remains pending rather than noData', () async {
      final attachment = await filing(
        2025,
        '20260813001590',
        name: '[첨부정정]사업보고서 (2025.12)',
      );
      client.documents.remove(attachment.rceptNo);
      client.filingPages[1] = [
        ('20260301000001', '사업보고서 (2025.06)', '20260301'),
      ];
      client.filingPages[2] = [
        ('20260319000984', '사업보고서 (2025.12)', '20260319'),
      ];
      await run(daily: 2);
      expect(client.filingQueries, hasLength(1));
      expect(
        (await DartFilingSection.db.findFirstRow(
          session,
          where: (t) =>
              t.filingId.equals(attachment.id!) &
              t.section.equals(DartSection.businessContent),
        ))!.status,
        FilingFetchStatus.pending,
      );
      expect(await BusinessDocument.db.count(session), 0);
      expect(resumes, hasLength(1));
    });
    test('noData exhaustion remains failed with total remaining instead of false success', () async {
      await filing(2025, '20260310000001');
      client.documents['20260310000001'] =
          '<DOCUMENT><TITLE>감사보고서</TITLE><P>사업내용 없음</P></DOCUMENT>';
      for (var i = 0; i < 3; i++) {
        final job = await run();
        expect(job.status, IngestStatus.failed);
      }
      resumes.clear();
      final calls = client.calls.length;
      final job = await run();
      expect(job.status, IngestStatus.failed);
      expect(job.processed, 0);
      expect(job.failed, 1);
      expect(job.message, contains('남은 전체 1'));
      expect(job.message, contains('한도초과 1'));
      expect(client.calls.length, calls);
      expect(resumes, isEmpty);
    });
    const apiWait = '사업본문 API 대기: 첨부정정의 공식 이전접수 탐색에 호출 예산 필요';
    Future<void> markWait(DartFiling target) async {
      await DartFilingSection.db.insertRow(
        session,
        DartFilingSection(
          filingId: target.id!,
          companyId: company.id!,
          bsnsYear: target.bsnsYear!,
          tier: 2,
          section: DartSection.businessContent,
          yearRank: 0,
          status: FilingFetchStatus.pending,
          lastError: apiWait,
          attempts: 0,
        ),
      );
    }

    for (final example in [
      ('00104722', '국제약품(주)', '20250320000537', '20250320000780'),
      ('01504211', '주식회사 라메디텍', '20250319000268', '20250319000467'),
    ]) {
      test('APIwait uses actual exact earlier source ${example.$1}', () async {
        company = await Company.db.updateRow(
          session,
          company.copyWith(corpCode: example.$1, name: example.$2),
        );
        await filing(2024, example.$3);
        final target = await filing(
          2024,
          example.$4,
          name: '[첨부정정]사업보고서 (2024.12)',
        );
        await markWait(target);
        final reader = ActualOriginalPublicBody(example.$3, example.$4);
        final job = await run(daily: 0, public: reader);
        expect(job.updated, 1);
        expect(client.calls, isEmpty);
        expect(reader.receipts, [example.$4, example.$3]);
        final body = (await BusinessDocument.db.find(session)).single;
        expect(body.rceptNo, example.$3);
        expect(body.charCount, greaterThan(10000));
        final report = (await DisclosureReport.db.findById(
          session,
          body.reportId,
        ))!;
        expect(report.rceptNo, example.$3);
        expect(report.bsnsYear, 2024);
        expect(report.reportCode, FinancialReportCode.annual);
        final source = (await Source.db.findById(session, report.sourceId))!;
        final primaryProof = jsonDecode(
          File('test/fixtures/business_apiwait/${example.$3}/proof.json')
              .readAsStringSync(),
        ) as Map;
        final businessProof = (primaryProof['sources'] as List).singleWhere(
          (s) => s['label'] == 'business',
        ) as Map;
        expect(primaryProof['shellCorpIds'], [example.$1]);
        expect(source.url, businessProof['url']);
        expect(source.title, contains('SHA256=${businessProof['sha256']}'));
        expect(
          (await DartFilingSection.db.findFirstRow(
            session,
            where: (t) =>
                t.filingId.equals(target.id!) &
                t.section.equals(DartSection.businessContent),
          ))!.status,
          FilingFetchStatus.stored,
        );
      });
    }
    for (final invalid in [
      'company',
      'corp',
      'period',
      'quarter',
      'nextquarter',
      'laterReceipt',
      'laterDate',
      'absent',
    ]) {
      test(
        'APIwait rejects known-source $invalid without target GET or reset',
        () async {
          final target = await filing(
            2024,
            '20250320000780',
            name: '[첨부정정]사업보고서 (2024.12)',
          );
          if (invalid != 'absent') {
            final other = invalid == 'company'
                ? await Company.db.insertRow(
                    session,
                    Company(
                      corpCode: '00000002',
                      name: '다른회사',
                      market: Market.kospi,
                      stockCode: '000002',
                    ),
                  )
                : null;
            var original = await filing(
              2024,
              invalid == 'laterReceipt' ? '20250320000781' : '20250320000537',
            );
            original = original.copyWith(
              companyId: invalid == 'company' ? other!.id : original.companyId,
              corpCode: invalid == 'corp' ? '99999999' : original.corpCode,
              reportName: invalid == 'nextquarter'
                  ? '사업보고서 (2025.03)'
                  : invalid == 'period'
                  ? '사업보고서 (2024.06)'
                  : invalid == 'quarter'
                  ? '반기보고서 (2024.12)'
                  : original.reportName,
              receivedDate: invalid == 'laterDate'
                  ? now.add(const Duration(days: 1))
                  : original.receivedDate,
            );
            await DartFiling.db.updateRow(session, original);
          }
          await markWait(target);
          final reader = SelectivePublicBody({target.rceptNo});
          final job = await run(daily: 0, public: reader);
          expect(reader.receipts, isNot(contains(target.rceptNo)));
          expect(job.updated, lessThanOrEqualTo(1));
          expect(client.calls, isEmpty);
          final item = (await DartFilingSection.db.findFirstRow(
            session,
            where: (t) =>
                t.filingId.equals(target.id!) &
                t.section.equals(DartSection.businessContent),
          ))!;
          expect(item.status, FilingFetchStatus.pending);
          expect(item.attempts, 0);
          expect(item.lastError, apiWait);
        },
      );
    }
    test(
      'APIwait known source cancellation stops GET/storage without reset',
      () async {
        await filing(2024, '20250320000537');
        final target = await filing(
          2024,
          '20250320000780',
          name: '[첨부정정]사업보고서 (2024.12)',
        );
        await markWait(target);
        final reader = CancelAfterHttpBody(() async {
          final job = (await IngestJobs.latest(
            session,
            DisclosureSync.businessKind,
          ))!;
          await IngestJobs.cancel(session, job.id!);
        });
        final job = await run(daily: 0, public: reader);
        expect(job.status, IngestStatus.cancelled);
        expect(reader.receipts, [target.rceptNo]);
        expect(await BusinessDocument.db.count(session), 0);
        expect(client.calls, isEmpty);
        final item = (await DartFilingSection.db.findFirstRow(
          session,
          where: (t) =>
              t.filingId.equals(target.id!) &
              t.section.equals(DartSection.businessContent),
        ))!;
        expect(item.attempts, 0);
        expect(item.status, FilingFetchStatus.pending);
        expect(resumes, isEmpty);
      },
    );
    test('APIwait known source limited run remains fresh with thirty-second resume', () async {
      await filing(2024, '20250320000537');
      final target = await filing(
        2024,
        '20250320000780',
        name: '[첨부정정]사업보고서 (2024.12)',
      );
      await markWait(target);
      final reader = SelectivePublicBody({target.rceptNo});
      final first = await run(limit: 1, daily: 0, public: reader);
      expect(first.updated, 0);
      expect(reader.receipts, [target.rceptNo]);
      expect(resumes.single, now.add(const Duration(seconds: 30)));
      final item = (await DartFilingSection.db.findFirstRow(
        session,
        where: (t) =>
            t.filingId.equals(target.id!) &
            t.section.equals(DartSection.businessContent),
      ))!;
      expect(item.attempts, 0);
      expect(item.status, FilingFetchStatus.pending);
      resumes.clear();
      final next = await run(daily: 0, public: reader);
      expect(next.updated, 1);
      expect(
        (await BusinessDocument.db.find(session)).single.rceptNo,
        '20250320000537',
      );
    });
    test('API-blocked attachment first does not starve public body and waits until next midnight only when it remains alone', () async {
      const blocked = '20260411000001', ordinary = '20250310000001';
      await filing(2025, blocked, name: '[첨부정정]사업보고서 (2025.12)');
      await filing(2024, ordinary);
      final reader = SelectivePublicBody({blocked});
      final job = await run(daily: 0, public: reader);
      expect(reader.receipts, [blocked, ordinary]);
      expect(client.calls, isEmpty);
      expect(job.processed, 1);
      expect(job.updated, 1);
      expect(
        (await BusinessDocument.db.find(session)).single.rceptNo,
        ordinary,
      );
      final waiting = (await DartFilingSection.db.find(
        session,
        where: (t) => t.status.equals(FilingFetchStatus.pending),
      )).single;
      expect(waiting.lastError, contains('API 대기'));
      expect(waiting.attempts, 0);
      expect(
        resumes.single,
        ApiCallBudget.nextKstMidnight(now).add(const Duration(minutes: 1)),
      );
      resumes.clear();
      final nextReader = SelectivePublicBody({blocked});
      final next = await run(daily: 0, public: nextReader);
      expect(next.processed, 0);
      expect(nextReader.receipts, isEmpty);
      expect(
        resumes.single,
        ApiCallBudget.nextKstMidnight(now).add(const Duration(minutes: 1)),
      );
      expect(await BusinessDocument.db.count(session), 1);
    });
    test('bounded public remainder gets short resume and confirmed API wait is deprioritized next run', () async {
      const blocked = '20260411000001',
          first = '20250310000001',
          last = '20240310000001';
      await filing(2025, blocked, name: '[첨부정정]사업보고서 (2025.12)');
      await filing(2024, first);
      await filing(2023, last);
      final a = SelectivePublicBody({blocked});
      final job = await run(daily: 0, limit: 2, public: a);
      expect(a.receipts, [blocked, first]);
      expect(job.processed, 1);
      expect(resumes.single, now.add(const Duration(seconds: 30)));
      resumes.clear();
      final b = SelectivePublicBody({blocked});
      await run(daily: 0, limit: 1, public: b);
      expect(b.receipts, [last]);
      expect(client.calls, isEmpty);
      expect(
        resumes.single,
        ApiCallBudget.nextKstMidnight(now).add(const Duration(minutes: 1)),
      );
    });
    test('business-only default uses remaining shared daily budget above disclosure allocation; explicit override is preserved', () async {
      const receipt = '20260310000001';
      await filing(2025, receipt);
      await ApiCallUsage.db.insertRow(
        session,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: ApiCallBudget.kstDay(now),
          calls: 18062,
        ),
      );
      final job = await run(daily: null);
      expect(job.updated, 1);
      expect(client.calls, ['document|$receipt']);
      final normal = DisclosureSync(session, client.client(), -1);
      final business = DisclosureSync(
        session,
        client.client(),
        -1,
        businessOnly: true,
      );
      final override = DisclosureSync(
        session,
        client.client(),
        -1,
        businessOnly: true,
        dailyBudget: 0,
      );
      expect(normal.dailyBudget, ApiCallBudget.dartDisclosureBudget);
      expect(business.dailyBudget, ApiCallBudget.dartDailyLimit - 100);
      expect(override.dailyBudget, 0);
    });
  });
}
