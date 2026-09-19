import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/disclosure_links.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/disclosure_sync.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// 가짜 DART 주요정보. `api|corp|year` → 응답 행. 없으면 013.
class FakeDisclosures {
  final rows = <String, List<Map<String, String>>>{};
  final calls = <String>[];

  void set(String api, String corp, int year, List<Map<String, String>> list) =>
      rows['$api|$corp|$year'] = list;

  DartClient client() => DartClient(
    'key',
    httpClient: MockClient((req) async {
      final api = req.url.pathSegments.last.replaceAll('.json', '');
      final q = req.url.queryParameters;
      final key = '$api|${q['corp_code']}|${q['bsns_year']}';
      calls.add(key);
      final list = rows[key];
      final body = list == null
          ? '{"status":"013","message":"조회된 데이타가 없습니다."}'
          : jsonEncode({'status': '000', 'message': '정상', 'list': list});
      return http.Response.bytes(utf8.encode(body), 200);
    }),
  );
}

Map<String, String> holder(
  String rcept,
  String corp,
  String nm,
  String relate,
  String ratio, {
  String kind = '보통주',
}) => {
  'rcept_no': rcept,
  'corp_cls': 'Y',
  'corp_code': corp,
  'corp_name': corp,
  'nm': nm,
  'relate': relate,
  'stock_knd': kind,
  'bsis_posesn_stock_co': '1,000',
  'bsis_posesn_stock_qota_rt': ratio,
  'trmend_posesn_stock_co': '1,000',
  'trmend_posesn_stock_qota_rt': ratio,
  'rm': '-',
  'stlm_dt': '2025-12-31',
};

void main() {
  withServerpod('Given DisclosureSync', (sessionBuilder, endpoints) {
    late Session session;
    late FakeDisclosures dart;
    final now = DateTime.utc(2026, 9, 19, 3);
    final resumes = <DateTime>[];
    final ids = <String, int>{};

    const samsung = '00000001', life = '00000002', cnt = '00000003';
    const other = '00000004', another = '00000005';
    const rSamsung = '20260310000001';

    Future<IngestJob> runSync({
      int dailyBudget = 18000,
      int priorityBudget = 9000,
      String? corpCode,
    }) async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: DisclosureSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      await DisclosureSync(
        session,
        dart.client(),
        job.id!,
        dailyBudget: dailyBudget,
        priorityBudget: priorityBudget,
        callInterval: Duration.zero,
        clock: () => now,
        corpCode: corpCode,
        scheduleResume: (at) async => resumes.add(at),
      ).run();
      return (await IngestJob.db.findById(session, job.id!))!;
    }

    Future<DartFiling> filing(
      String corp,
      String rcept,
      int year, {
      FilingFetchStatus financial = FilingFetchStatus.stored,
    }) => DartFiling.db.insertRow(
      session,
      DartFiling(
        rceptNo: rcept,
        corpCode: corp,
        companyId: ids[corp],
        reportName: '사업보고서 ($year.12)',
        receivedDate: DateTime.utc(year + 1, 3, 10),
        bsnsYear: year,
        reportCode: FinancialReportCode.annual,
        consolidatedStatus: financial,
        separateStatus: financial,
        discoveredAt: now,
      ),
    );

    setUp(() async {
      session = sessionBuilder.build();
      dart = FakeDisclosures();
      resumes.clear();
      for (final (corp, name) in [
        (samsung, '삼성전자(주)'),
        (life, '삼성생명보험(주)'),
        (cnt, '삼성물산(주)'),
        (other, '(주)다른회사'),
        (another, '(주)또다른회사'),
      ]) {
        final c = await Company.db.insertRow(
          session,
          Company(corpCode: corp, name: name, market: Market.kospi),
        );
        ids[corp] = c.id!;
      }
      await filing(samsung, rSamsung, 2025);
      await filing(life, '20260310000002', 2025);
      await filing(cnt, '20260310000003', 2025);
      await filing(other, '20260310000004', 2025);
      await filing(another, '20260310000005', 2025);

      dart.set('hyslrSttus', samsung, 2025, [
        holder(rSamsung, samsung, '삼성생명보험㈜', '최대주주 본인', '8.51'),
        holder(rSamsung, samsung, '삼성물산㈜', '계열회사', '5.05'),
        holder(rSamsung, samsung, '이재용', '최대주주의 특수관계인', '1.65'),
        holder(rSamsung, samsung, '이재용', '최대주주의 특수관계인', '0.02', kind: '우선주'),
        holder(rSamsung, samsung, '전영현', '계열회사 임원', '0.00'),
        holder(rSamsung, samsung, '이부진', '계열회사 임원', '0.71'),
        holder(rSamsung, samsung, '계', '-', '15.23'),
      ]);
      dart.set('exctvSttus', samsung, 2025, [
        {
          'rcept_no': rSamsung,
          'corp_code': samsung,
          'nm': '전영현',
          'sexdstn': '남',
          'birth_ym': '1960년 12월',
          'ofcps': '부회장',
          'rgist_exctv_at': '사내이사',
          'fte_at': '상근',
          'chrg_job': '대표이사',
          'hffc_pd': '10개월',
          'tenure_end_on': '2028년 03월 18일',
          'stlm_dt': '2025-12-31',
        },
      ]);
      dart.set('otrCprInvstmntSttus', samsung, 2025, [
        {
          'rcept_no': rSamsung,
          'corp_code': samsung,
          'inv_prm': '(주)다른회사',
          'invstmnt_purps': '단순투자',
          'trmend_blce_qota_rt': '3.0',
          'trmend_blce_acntbk_amount': '445,244,000,000',
          'stlm_dt': '2025-12-31',
        },
        {
          'rcept_no': rSamsung,
          'corp_code': samsung,
          'inv_prm': 'SDMA',
          'invstmnt_purps': '경영참여',
          'trmend_blce_qota_rt': '75.0',
          'stlm_dt': '2025-12-31',
        },
        {
          'rcept_no': rSamsung,
          'corp_code': samsung,
          'inv_prm': '합계',
          'invstmnt_purps': '-',
          'trmend_blce_acntbk_amount': '500,000,000,000',
          'stlm_dt': '2025-12-31',
        },
      ]);
      dart.set('alotMatter', samsung, 2025, [
        {
          'rcept_no': rSamsung,
          'corp_code': samsung,
          'se': '(연결)당기순이익(백만원)',
          'stock_knd': '-',
          'thstrm': '44,260,956',
          'frmtrm': '33,621,363',
          'lwfr': '14,473,401',
          'stlm_dt': '2025-12-31',
        },
        {
          'rcept_no': rSamsung,
          'corp_code': samsung,
          'se': '주당 현금배당금(원)',
          'stock_knd': '보통주',
          'thstrm': '1,668',
          'frmtrm': '1,446',
          'lwfr': '1,444',
          'stlm_dt': '2025-12-31',
        },
      ]);
      // 자료가 없으면 값이 모두 '-'인 줄을 준다.
      dart.set('cprndNrdmpBlce', samsung, 2025, [
        {
          'rcept_no': rSamsung,
          'corp_code': samsung,
          'remndr_exprtn1': '-',
          'remndr_exprtn2': '-',
          'sm': '-',
          'stlm_dt': '2025-12-31',
        },
      ]);
      dart.set('hyslrSttus', life, 2025, [
        holder('20260310000002', life, '삼성물산㈜', '최대주주 본인', '19.34'),
        holder('20260310000002', life, '이재용', '최대주주의 특수관계인', '10.44'),
      ]);
      dart.set('hyslrSttus', cnt, 2025, [
        holder('20260310000003', cnt, '이 재 용', '최대주주 본인', '19.76'),
        holder('20260310000003', cnt, '이 부 진', '친인척', '6.10'),
      ]);
      // 서로 지분으로 이어지지 않은 두 회사의 같은 이름은 합치지 않는다.
      dart.set('hyslrSttus', other, 2025, [
        holder('20260310000004', other, '김영수', '최대주주 본인', '30.00'),
      ]);
      dart.set('hyslrSttus', another, 2025, [
        holder('20260310000005', another, '김영수', '최대주주 본인', '40.00'),
      ]);
    });

    test('사업보고서마다 28개 항목을 받아 원문 행과 타입 층을 출처와 함께 저장한다', () async {
      final job = await runSync();
      expect(job.status, IngestStatus.succeeded, reason: job.message);
      expect(await DartFilingSection.db.count(session), 5 * 28);
      expect(dart.calls, hasLength(5 * 28));

      final report = (await DisclosureReport.db.findFirstRow(
        session,
        where: (t) =>
            t.rceptNo.equals(rSamsung) &
            t.section.equals(DartSection.largestShareholders),
      ))!;
      expect(report.rowCount, 7);
      expect(report.settlementDate, DateTime.utc(2025, 12, 31));
      final source = (await Source.db.findById(session, report.sourceId))!;
      expect(source.reference, rSamsung);
      expect(
        await DisclosureRow.db.count(
          session,
          where: (t) => t.reportId.equals(report.id!),
        ),
        7,
      );

      final holders = await ShareholderEntry.db.find(
        session,
        where: (t) => t.reportId.equals(report.id!),
        orderBy: (t) => t.ord,
      );
      expect(holders[0].holderCompanyId, ids[life]);
      expect(holders[1].holderCompanyId, ids[cnt]);
      expect(holders.last.isTotal, isTrue);
      expect(holders[0].ratioEnd, 8.51);

      final investments = await InvestmentEntry.db.find(
        session,
        where: (t) => t.companyId.equals(ids[samsung]!),
        orderBy: (t) => t.ord,
      );
      expect(investments.first.investeeCompanyId, ids[other]);
      expect(investments.first.bookValueEnd, BigInt.parse('445244000000'));
      expect(investments[1].investeeCompanyId, isNull);
      expect(investments.last.isTotal, isTrue);

      final dividends = await DividendEntry.db.find(
        session,
        orderBy: (t) => t.ord,
      );
      expect(
        [for (final d in dividends) (d.unit, d.current)],
        [('백만원', 44260956.0), ('원', 1668.0)],
      );

      // 값이 모두 '-'인 줄만 오면 '자료 없음'.
      final bond = (await DartFilingSection.db.findFirstRow(
        session,
        where: (t) =>
            t.companyId.equals(ids[samsung]!) &
            t.section.equals(DartSection.corporateBondBalance),
      ))!;
      expect(bond.status, FilingFetchStatus.noData);
    });

    test('임원은 출생년월로, 주주는 같은 보고서 임원·기업 묶음으로 인물에 잇는다', () async {
      await runSync();
      final samsungHolders = await ShareholderEntry.db.find(
        session,
        where: (t) => t.companyId.equals(ids[samsung]!),
        orderBy: (t) => t.ord,
      );
      final exec = (await ExecutiveEntry.db.findFirstRow(session))!;
      final execPerson = (await Person.db.findById(session, exec.personId!))!;
      expect(execPerson.estimated, isFalse);
      expect((execPerson.birthYear, execPerson.birthMonth), (1960, 12));
      expect(exec.termEndDate, DateTime.utc(2028, 3, 18));
      expect(exec.tenureMonths, 10);

      final jeon = samsungHolders.firstWhere((h) => h.holderName == '전영현');
      expect(jeon.holderPersonId, exec.personId);
      expect(jeon.holderLinkBasis, DisclosureLinkBasis.executiveSameReport);

      // 삼성전자·삼성생명·삼성물산은 서로 지분으로 이어져 있다 → 이재용은 한 사람(추정).
      final lee = await ShareholderEntry.db.find(
        session,
        where: (t) =>
            t.holderLinkBasis.equals(DisclosureLinkBasis.ownershipCluster) &
            t.holderName.inSet({'이재용', '이 재 용'}),
      );
      expect(
        {for (final s in lee) s.companyId},
        {
          ids[samsung],
          ids[life],
          ids[cnt],
        },
      );
      expect({for (final s in lee) s.holderPersonId}, hasLength(1));
      final person = (await Person.db.findById(
        session,
        lee.first.holderPersonId!,
      ))!;
      expect(person.name, '이재용');
      expect(person.estimated, isTrue);

      // 한 곳은 '계열회사 임원', 다른 곳은 '친인척'으로 적어도 같은 묶음이면 같은 사람(추정).
      final boojin = await ShareholderEntry.db.find(
        session,
        where: (t) => t.holderName.inSet({'이부진', '이 부 진'}),
      );
      expect({for (final s in boojin) s.holderPersonId}, hasLength(1));
      expect(boojin.first.holderPersonId, isNotNull);

      final kim = await ShareholderEntry.db.find(
        session,
        where: (t) => t.holderName.equals('김영수'),
      );
      expect([for (final s in kim) s.holderPersonId], [null, null]);

      // 관계 색인: 주주 → 기업은 보통주 지분율 합, 추정 인물은 draft.
      final leeToSamsung = (await OntologyRelation.db.findFirstRow(
        session,
        where: (t) =>
            t.subjectPersonId.equals(person.id!) &
            t.objectCompanyId.equals(ids[samsung]!),
      ))!;
      expect(leeToSamsung.weight, 1.65);
      expect(leeToSamsung.status, RelationStatus.draft);
      final lifeToSamsung = (await OntologyRelation.db.findFirstRow(
        session,
        where: (t) =>
            t.subjectCompanyId.equals(ids[life]!) &
            t.objectCompanyId.equals(ids[samsung]!),
      ))!;
      expect(lifeToSamsung.predicate, RelationPredicate.shareholderOf);
      expect(lifeToSamsung.status, RelationStatus.verified);
    });

    test('지배구조·인물 조회와 추정 연결 끊기', () async {
      await runSync();
      final gov = (await endpoints.governance.summary(
        sessionBuilder,
        samsung,
      ))!;
      expect(gov.bsnsYear, 2025);
      expect(gov.shareholders, hasLength(7));
      expect(gov.executives, hasLength(1));
      expect({for (final c in gov.companies) c.corpCode}, {life, cnt, other});

      final otherGov = (await endpoints.governance.summary(
        sessionBuilder,
        other,
      ))!;
      expect([for (final l in otherGov.investors) l.corpCode], [samsung]);
      final lifeGov = (await endpoints.governance.summary(
        sessionBuilder,
        life,
      ))!;
      expect(
        [for (final l in lifeGov.holdings) (l.corpCode, l.weight)],
        [
          (samsung, 8.51),
        ],
      );

      final leeId = gov.shareholders
          .firstWhere((s) => s.holderName == '이재용')
          .holderPersonId!;
      final profile = (await endpoints.governance.person(
        sessionBuilder,
        leeId,
      ))!;
      expect({for (final r in profile.roles) r.corpCode}, {samsung, life, cnt});
      expect(profile.roles.every((r) => r.estimated), isTrue);

      await endpoints.governance.rejectPersonLink(
        sessionBuilder,
        samsung,
        '이재용',
      );
      await DisclosureLinks(session).rebuild();
      // 삼성물산은 이름을 '이 재 용'으로 적었다.
      final after = await ShareholderEntry.db.find(
        session,
        where: (t) => t.holderName.inSet({'이재용', '이 재 용'}),
      );
      expect(
        {
          for (final s in after) s.companyId: s.holderPersonId != null,
        },
        {ids[samsung]: false, ids[life]: true, ids[cnt]: true},
      );
    });

    test('원문 표와 주주환원', () async {
      await runSync();
      final sections = await endpoints.disclosure.sections(
        sessionBuilder,
        samsung,
      );
      expect(
        [for (final s in sections) s.section],
        [
          DartSection.largestShareholders,
          DartSection.executives,
          DartSection.investments,
          DartSection.dividend,
        ],
      );
      final table = (await endpoints.disclosure.table(
        sessionBuilder,
        samsung,
        DartSection.dividend,
      ))!;
      expect(table.headers, ['구분', '주식 종류', '당기', '전기', '전전기']);
      expect(table.rows.first.cells, [
        '(연결)당기순이익(백만원)',
        null,
        '44,260,956',
        '33,621,363',
        '14,473,401',
      ]);
      final ret = (await endpoints.disclosure.shareholderReturn(
        sessionBuilder,
        samsung,
      ))!;
      expect(ret.dividends, hasLength(2));
      expect(ret.sources, isNotEmpty);
    });

    test('재무 백필이 남아 있으면 기업마다 가장 최근 사업보고서의 핵심 항목만 받는다', () async {
      final old = await filing(samsung, '20250310000001', 2024);
      await DartFiling.db.updateRow(
        session,
        old.copyWith(consolidatedStatus: FilingFetchStatus.pending),
      );
      // 결산월이 달라 FY2026 사업보고서가 먼저 나온 기업이 있어도, 다른 기업의 최근 보고서는 FY2025다.
      await filing(other, '20260610000004', 2026);
      final job = await runSync();
      expect(job.message, contains('핵심 항목 완료'));
      // 기업마다 가장 최근 사업보고서(삼성 등 4곳 FY2025, 다른회사 FY2026) × 핵심 9종만 호출.
      expect(dart.calls, hasLength(5 * 9));
      expect(dart.calls, contains('hyslrSttus|$other|2026'));
      expect(dart.calls, isNot(contains('hyslrSttus|$other|2025')));
      expect(
        await DartFilingSection.db.count(
          session,
          where: (t) => t.status.equals(FilingFetchStatus.pending),
        ),
        5 * 19 + 28 + 28,
      );
    });

    test('하루 몫을 다 쓰면 멈추고 다음 날 이어받기를 예약한다', () async {
      final job = await runSync(dailyBudget: 10);
      expect(dart.calls, hasLength(10));
      expect(job.message, contains('다음 날 이어서 받음'));
      expect(resumes, [DateTime.utc(2026, 9, 19, 15, 5)]);
    });

    test('정정공시가 나오면 이전 보고서를 새 보고서가 대체한다', () async {
      await runSync(corpCode: samsung);
      const corrected = '20260401000001';
      await filing(samsung, corrected, 2025);
      dart.set('hyslrSttus', samsung, 2025, [
        holder(corrected, samsung, '삼성생명보험㈜', '최대주주 본인', '8.60'),
      ]);
      await runSync(corpCode: samsung);
      final reports = await DisclosureReport.db.find(
        session,
        where: (t) => t.section.equals(DartSection.largestShareholders),
        orderBy: (t) => t.rceptNo,
      );
      expect([for (final r in reports) r.rceptNo], [rSamsung, corrected]);
      expect(reports.first.supersededById, reports.last.id);
      final gov = (await endpoints.governance.summary(
        sessionBuilder,
        samsung,
      ))!;
      expect([for (final s in gov.shareholders) s.ratioEnd], [8.60]);
    });
  });
}
