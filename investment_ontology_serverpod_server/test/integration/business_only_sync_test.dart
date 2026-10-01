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
        dailyBudget: daily,
        publicFallbackEnabled: public != null,
        publicDocuments: public,
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
