import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_business_document.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/endpoints/governance_endpoint.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/disclosure_links.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/api_call_budget.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/disclosure_sync.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

/// 가짜 DART 주요정보. `api|corp|year` → 응답 행. 없으면 013.
class _PublicBodyFixture extends PublicBusinessDocument {
  _PublicBodyFixture({this.fail = false});
  final bool fail;
  final receipts = <String>[];
  final errors = <String, Object>{};
  @override
  Future<PublicBusinessBody> fetch(String receipt) async {
    receipts.add(receipt);
    if (errors[receipt] case final error?) throw error;
    if (fail) throw TimeoutException("fixture public transport timeout");
    return PublicBusinessBody(
      receipt: receipt,
      title: "사업보고서",
      text: "공개 원문 제품 설명",
      sourceUri: Uri.parse(
        // Synthetic coordinates, same six-field shape as bodyUri(receipt, shell).
        "https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt&dcmNo=10000001&eleId=9&offset=1000&length=2048&dtd=dart4.xsd",
      ),
      bodySha256: "fixture-hash",
    );
  }
}

class FakeDisclosures {
  final rows = <String, List<Map<String, String>>>{};
  final calls = <String>[];
  final reportCodes = <String>[];

  /// 호출마다 실행한다 (다른 수집이 동시에 호출을 쓰는 상황 흉내).
  Future<void> Function()? onCall;

  /// 접수번호 → 공시 원본 XML. 없으면 014 (파일 없음).
  final documents = <String, String>{};
  String? documentError;

  /// 회사별 공시 목록 (`list.json`, 원본·정정 모두). (접수번호, 보고서 이름, 접수일)
  final filings = <String, List<(String, String, String)>>{};
  final filingQueries = <Map<String, String>>[];
  final filingPages = <int, List<(String, String, String)>>{};

  void set(String api, String corp, int year, List<Map<String, String>> list) =>
      rows['$api|$corp|$year'] = list;

  DartClient client() => DartClient(
    'key',
    httpClient: MockClient((req) async {
      final q = req.url.queryParameters;
      if (req.url.path.endsWith('document.xml')) {
        final rcept = q['rcept_no']!;
        calls.add('document|$rcept');
        if (documentError != null) {
          return http.Response(
            jsonEncode({
              'status': documentError,
              'message': 'fixture API error',
            }),
            200,
          );
        }
        final xml = documents[rcept];
        if (xml == null) {
          return http.Response.bytes(
            utf8.encode(
              '<?xml version="1.0" encoding="UTF-8"?><result><status>014</status>'
              '<message>파일이 존재하지 않습니다.</message></result>',
            ),
            200,
          );
        }
        final archive = Archive()
          ..addFile(ArchiveFile.bytes('$rcept.xml', utf8.encode(xml)));
        return http.Response.bytes(ZipEncoder().encodeBytes(archive), 200);
      }
      if (req.url.path.endsWith('list.json')) {
        calls.add('list|${q['corp_code']}');
        filingQueries.add(Map.of(q));
        final items = filingPages.isEmpty
            ? filings[q['corp_code']] ?? const []
            : filingPages[int.parse(q['page_no']!)] ?? const [];
        final body = items.isEmpty
            ? '{"status":"013","message":"조회된 데이타가 없습니다."}'
            : jsonEncode({
                'status': '000',
                'total_page': filingPages.isEmpty ? 1 : filingPages.length,
                'total_count': items.length,
                'list': [
                  for (final (rcept, name, date) in items)
                    {
                      'corp_code': q['corp_code'],
                      'corp_name': q['corp_code'],
                      'report_nm': name,
                      'rcept_no': rcept,
                      'rcept_dt': date,
                    },
                ],
              });
        return http.Response.bytes(utf8.encode(body), 200);
      }
      final api = req.url.pathSegments.last.replaceAll('.json', '');
      final key = '$api|${q['corp_code']}|${q['bsns_year']}';
      calls.add(key);
      reportCodes.add('$api|${q['bsns_year']}|${q['reprt_code']}');
      await onCall?.call();
      final list = rows['$key|${q['reprt_code']}'] ?? rows[key];
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
  withServerpod('Given DisclosureSync', (anonymous, endpoints) {
    final sessionBuilder = anonymous.asAdmin;
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
      int businessBudget = DisclosureSync.defaultBusinessBudget,
      String? corpCode,
      PublicBusinessDocument? publicDocuments,
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
        businessBudget: businessBudget,
        publicFallbackEnabled: publicDocuments != null,
        publicDocuments: publicDocuments,
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
      String? name,
      FinancialReportCode code = FinancialReportCode.annual,
    }) => DartFiling.db.insertRow(
      session,
      DartFiling(
        rceptNo: rcept,
        corpCode: corp,
        companyId: ids[corp],
        reportName: name ?? '사업보고서 ($year.12)',
        receivedDate: DateTime.utc(year + 1, 3, 10),
        bsnsYear: year,
        reportCode: code,
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
          Company(
            corpCode: corp,
            name: name,
            stockCode: corp.substring(2),
            market: Market.kospi,
          ),
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

    test('전체 수집은 재무 백필 중에도 각 기업의 최신 분기 지배구조를 받는다', () async {
      for (final (corp, receipt, code) in [
        (samsung, '20260814000001', FinancialReportCode.halfYear),
        (life, '20260515000002', FinancialReportCode.q1),
      ]) {
        await filing(
          corp,
          receipt,
          2026,
          code: code,
          financial: FilingFetchStatus.pending,
        );
      }
      await runSync();
      for (final corp in [samsung, life]) {
        for (final api in [
          'hyslrSttus',
          'exctvSttus',
          'otrCprInvstmntSttus',
          'mrhlSttus',
        ]) {
          expect(dart.calls, contains('$api|$corp|2026'));
        }
      }
      for (final code in ['11012', '11013']) {
        expect(dart.reportCodes, contains('hyslrSttus|2026|$code'));
        expect(dart.reportCodes, contains('exctvSttus|2026|$code'));
      }
    });

    test('반기 최대주주를 11012로 수집하고 동일 연도 사업보고서와 구분 보존한다', () async {
      const interim = '20260814000001';
      await filing(
        samsung,
        interim,
        2026,
        code: FinancialReportCode.halfYear,
        name: '반기보고서 (2026.06)',
      );
      dart.rows['hyslrSttus|$samsung|2026|11012'] = [
        {
          ...holder(interim, samsung, '삼성생명보험㈜', '최대주주 본인', '8.40'),
          'stlm_dt': '2026-06-30',
        },
      ];
      await runSync(corpCode: samsung);
      expect(dart.reportCodes, contains('hyslrSttus|2026|11012'));
      expect(dart.reportCodes, contains('exctvSttus|2026|11012'));
      expect(dart.reportCodes, contains('otrCprInvstmntSttus|2026|11012'));
      final half = await DisclosureReport.db.findFirstRow(
        session,
        where: (t) =>
            t.rceptNo.equals(interim) &
            t.section.equals(DartSection.largestShareholders),
      );
      expect(half, isNotNull);
      expect(half!.reportCode, FinancialReportCode.halfYear);
      expect(half.settlementDate, DateTime.utc(2026, 6, 30));
      final entries = await ShareholderEntry.db.find(
        session,
        where: (t) => t.reportId.equals(half.id!),
      );
      expect(entries.single.ratioEnd, 8.40);
      final current = await GovernanceEndpoint().summary(session, samsung);
      expect(current!.shareholderPeriodEnd, DateTime.utc(2026, 6, 30));
      expect(current.shareholders.single.ratioEnd, 8.40);
      const annual = '20270310000001';
      await filing(samsung, annual, 2026);
      dart.rows['hyslrSttus|$samsung|2026|11011'] = [
        {
          ...holder(annual, samsung, '삼성생명보험㈜', '최대주주 본인', '8.30'),
          'stlm_dt': '2026-12-31',
        },
      ];
      await runSync(corpCode: samsung);
      final active = await DisclosureReport.db.find(
        session,
        where: (t) =>
            t.companyId.equals(ids[samsung]!) &
            t.bsnsYear.equals(2026) &
            t.section.equals(DartSection.largestShareholders) &
            t.supersededById.equals(null),
      );
      expect(active.map((r) => r.reportCode).toSet(), {
        FinancialReportCode.halfYear,
        FinancialReportCode.annual,
      });
    });

    test('통신 장애는 항목 재시도 횟수를 소진하지 않고 자동 재개한다', () async {
      dart.onCall = () async =>
          throw http.ClientException('Failed host lookup');
      final job = await runSync(businessBudget: 0);
      expect(job.status, IngestStatus.failed);
      expect(job.apiCalls, 1);
      expect(resumes, [now.add(const Duration(minutes: 15))]);
      final items = await DartFilingSection.db.find(session);
      expect(items.every((item) => item.attempts == 0), isTrue);
      expect(
        items.every((item) => item.status == FilingFetchStatus.pending),
        isTrue,
      );
      dart.onCall = null;
      expect((await runSync(businessBudget: 0)).status, IngestStatus.succeeded);
    });

    test('사업보고서마다 28개 항목을 받아 원문 행과 타입 층을 출처와 함께 저장한다', () async {
      final job = await runSync();
      expect(job.status, IngestStatus.succeeded, reason: job.message);
      expect(await DartFilingSection.db.count(session), 5 * 29);
      // 주요정보 28종 + 사업의 내용(원본 파일 1회).
      expect(dart.calls, hasLength(5 * 29));

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
      // 기업마다 가장 최근 사업보고서(삼성 등 4곳 FY2025, 다른회사 FY2026) × 핵심 9종,
      // 그리고 백필 중에도 받는 "사업의 내용" 본문 5건 (기업마다 최근 보고서 하나).
      expect(dart.calls, hasLength(5 * 9 + 5));
      expect(
        dart.calls.take(5).every((c) => c.startsWith('document|')),
        isTrue,
      );
      expect(dart.calls, contains('hyslrSttus|$other|2026'));
      expect(dart.calls, isNot(contains('hyslrSttus|$other|2025')));
      expect(
        await DartFilingSection.db.count(
          session,
          where: (t) => t.status.equals(FilingFetchStatus.pending),
        ),
        // 본문 5건을 이 실행에서 받았으므로 그만큼 줄어 있다.
        5 * 20 + 29 + 29 - 5,
      );
    });

    test('본문 우선수집은 이전 연간 대신 최신 기간의 최종 접수번호만 받는다', () async {
      final receipts = <String>[];
      for (final corp in [samsung, life, cnt, other, another]) {
        final receipt = '20260814${corp.substring(2)}';
        await filing(
          corp,
          receipt,
          2026,
          code: FinancialReportCode.halfYear,
          financial: FilingFetchStatus.pending,
        );
        receipts.add(receipt);
      }
      await filing(
        samsung,
        '20260515000001',
        2026,
        code: FinancialReportCode.q1,
      );
      const corrected = '20260901000001';
      await filing(
        samsung,
        corrected,
        2026,
        code: FinancialReportCode.halfYear,
      );
      receipts[0] = corrected;
      for (final receipt in receipts) {
        dart.documents[receipt] =
            '<DOCUMENT><BODY>'
            '<TITLE>II. 사업의 내용</TITLE><P>최신 제품과 사업</P>'
            '<TITLE>III. 재무에 관한 사항</TITLE></BODY></DOCUMENT>';
      }
      await runSync();
      expect(
        dart.calls.where((call) => call.startsWith('document|')),
        unorderedEquals(receipts.map((receipt) => 'document|$receipt')),
      );
      expect(await BusinessDocument.db.count(session), receipts.length);
      // 최신 본문 저장 후 남은 연간 본문이 우선 대상으로 승격되지 않는다.
      dart.calls.clear();
      await runSync();
      expect(dart.calls.where((call) => call.startsWith('document|')), isEmpty);
      expect(
        await DartFilingSection.db.count(
          session,
          where: (t) =>
              t.section.equals(DartSection.businessContent) &
              t.status.equals(FilingFetchStatus.pending),
        ),
        greaterThan(0),
      );
    });

    test('최신 본문을 먼저 받아도 공용 우선수집 예산을 넘지 않는다', () async {
      await filing(
        samsung,
        '20260814000001',
        2026,
        code: FinancialReportCode.halfYear,
        financial: FilingFetchStatus.pending,
      );
      final job = await runSync(priorityBudget: 2);
      expect(dart.calls, hasLength(2));
      expect(dart.calls.every((call) => call.startsWith('document|')), isTrue);
      expect(job.status, IngestStatus.succeeded);
    });

    test('API 예산 소진 상태에서 공개 본문과 출처를 정상 저장한다', () async {
      final reader = _PublicBodyFixture();
      await runSync(corpCode: samsung, dailyBudget: 0, publicDocuments: reader);
      expect(dart.calls, isEmpty);
      expect(reader.receipts, ['20260310000001']);
      final doc = (await BusinessDocument.db.find(session)).single;
      expect(doc.text, '공개 원문 제품 설명');
      final report = (await DisclosureReport.db.find(session)).single;
      final source = await Source.db.findById(session, report.sourceId);
      expect(source!.url, contains('rcpNo=20260310000001'));
      expect(source.title, contains('fixture-hash'));
      final complete = await endpoints.ingest.coverage(sessionBuilder);
      expect(complete.companiesWithBusinessText, 1);
      expect(complete.companiesWithLatestBusinessText, 1);
      final correction = await filing(samsung, '20260901000001', 2025);
      final waiting = await endpoints.ingest.coverage(sessionBuilder);
      expect(waiting.companiesWithBusinessText, 1);
      expect(waiting.companiesWithLatestBusinessText, 0);
      await runSync(corpCode: samsung, dailyBudget: 0);
      final section = (await DartFilingSection.db.find(
        session,
        where: (t) =>
            t.filingId.equals(correction.id!) &
            t.section.equals(DartSection.businessContent),
      )).single;
      await DartFilingSection.db.updateRow(
        session,
        section.copyWith(status: FilingFetchStatus.failed, attempts: 1),
      );
      await runSync(corpCode: samsung, dailyBudget: 0, publicDocuments: reader);
      final retried = await DartFilingSection.db.findById(session, section.id!);
      expect(retried!.status, FilingFetchStatus.stored);
      expect(
        (await endpoints.ingest.coverage(sessionBuilder))
            .companiesWithLatestBusinessText,
        1,
      );
    });

    test('본문 수집 대상인 other 기업은 지배구조 이름 연결 대상에 추가하지 않는다', () async {
      for (final corp in [life, other]) {
        final company = (await Company.db.findById(session, ids[corp]!))!;
        await Company.db.updateRow(
          session,
          company.copyWith(market: Market.other),
        );
      }
      await runSync(corpCode: samsung);
      final holder = (await ShareholderEntry.db.find(
        session,
        where: (t) =>
            t.companyId.equals(ids[samsung]!) & t.holderName.equals('삼성생명보험㈜'),
      )).single;
      expect(holder.holderCompanyId, isNull);
      final investment = (await InvestmentEntry.db.find(
        session,
        where: (t) => t.companyId.equals(ids[samsung]!),
        orderBy: (t) => t.ord,
      )).first;
      expect(investment.investeeCompanyId, isNull);
      expect(
        (await Company.db.findById(session, ids[life]!))!.stockCode,
        isNotNull,
      );
      expect(
        (await Company.db.findById(session, ids[other]!))!.stockCode,
        isNotNull,
      );
    });

    test('종목코드가 있는 other 세 기업의 최신본문을 저장하고 정확 최신 집계에 포함한다', () async {
      var count = 0;
      for (final (corp, name, stock, receipt, code, reportName) in [
        (
          '00534191',
          '코스나인',
          '082660',
          '20260515003027',
          FinancialReportCode.q1,
          '분기보고서 (2026.03)',
        ),
        (
          '00139834',
          '원풍물산',
          '008290',
          '20260814002734',
          FinancialReportCode.halfYear,
          '반기보고서 (2026.06)',
        ),
        (
          '00183518',
          '코다코',
          '046070',
          '20260814003077',
          FinancialReportCode.halfYear,
          '반기보고서 (2026.06)',
        ),
      ]) {
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: name,
            stockCode: stock,
            market: Market.other,
          ),
        );
        ids[corp] = company.id!;
        final latest = await filing(
          corp,
          receipt,
          2026,
          code: code,
          name: reportName,
        );
        final reader = _PublicBodyFixture();
        await runSync(corpCode: corp, dailyBudget: 0, publicDocuments: reader);
        expect(reader.receipts, [receipt]);
        final section = (await DartFilingSection.db.find(
          session,
          where: (t) =>
              t.filingId.equals(latest.id!) &
              t.section.equals(DartSection.businessContent),
        )).single;
        expect(section.status, FilingFetchStatus.stored);
        final body = (await BusinessDocument.db.find(
          session,
          where: (t) => t.companyId.equals(company.id!),
        )).single;
        expect(body.rceptNo, receipt);
        expect(
          (await Company.db.findById(session, company.id!))!.market,
          Market.other,
        );
        count++;
        expect(
          (await endpoints.ingest.coverage(sessionBuilder))
              .companiesWithLatestBusinessText,
          count,
        );
      }
    });

    test('명시 첨부정정의 공개 사업노드 없음은 실제 이전 원본으로 연결한다', () async {
      const corrected = '20260901000001';
      await filing(samsung, corrected, 2025, name: '[첨부정정]사업보고서 (2025.12)');
      final reader = _PublicBodyFixture()
        ..errors[corrected] = const PublicBusinessNodeMissing();
      await runSync(corpCode: samsung, dailyBudget: 0, publicDocuments: reader);
      expect(reader.receipts, [corrected, rSamsung]);
      final body = (await BusinessDocument.db.find(session)).single;
      expect(body.rceptNo, rSamsung);
      final source = (await Source.db.find(session)).single;
      expect(source.reference, rSamsung);
      expect(source.url, contains('rcpNo=$rSamsung'));
      expect(
        (await endpoints.ingest.coverage(sessionBuilder))
            .companiesWithLatestBusinessText,
        0,
      );
    });

    test('일반 기재정정의 노드 없음과 첨부정정의 모호한 노드는 이전 원본으로 넘기지 않는다', () async {
      for (final (receipt, name, error) in [
        (
          '20260901000001',
          '[기재정정]사업보고서 (2025.12)',
          const PublicBusinessNodeMissing(),
        ),
        (
          '20260902000001',
          '[첨부정정]사업보고서 (2025.12)',
          const FormatException('Business section node ambiguous'),
        ),
      ]) {
        final latest = await filing(samsung, receipt, 2025, name: name);
        final reader = _PublicBodyFixture()..errors[receipt] = error;
        await runSync(
          corpCode: samsung,
          dailyBudget: 0,
          publicDocuments: reader,
        );
        expect(reader.receipts, [receipt]);
        final section = (await DartFilingSection.db.find(
          session,
          where: (t) =>
              t.filingId.equals(latest.id!) &
              t.section.equals(DartSection.businessContent),
        )).single;
        expect(section.status, FilingFetchStatus.failed);
      }
      expect(await BusinessDocument.db.count(session), 0);
    });

    test('DART 020 호출 제한 오류 뒤에도 공개 본문을 저장하고 API는 더 부르지 않는다', () async {
      dart.documentError = '020';
      final reader = _PublicBodyFixture();
      await runSync(corpCode: samsung, publicDocuments: reader);
      expect(dart.calls, ['document|$rSamsung']);
      expect(reader.receipts, [rSamsung]);
      expect(await BusinessDocument.db.count(session), 1);
    });

    test('공개 원문 취득 실패를 자료 없음으로 확정하거나 이전 원문으로 대체하지 않는다', () async {
      final latest = await filing(
        samsung,
        '20260814000001',
        2026,
        code: FinancialReportCode.halfYear,
      );
      final reader = _PublicBodyFixture(fail: true);
      final job = await runSync(corpCode: samsung, publicDocuments: reader);
      final section = (await DartFilingSection.db.find(
        session,
        where: (t) =>
            t.filingId.equals(latest.id!) &
            t.section.equals(DartSection.businessContent),
      )).single;
      expect(section.status, FilingFetchStatus.failed);
      expect(section.lastError, contains('다음 실행 재시도'));
      expect(job.status, IngestStatus.failed);
      expect(await BusinessDocument.db.count(session), 0);
    });

    test('일반 기재정정의 최신 원문이 없으면 이전 원문은 최신 확보로 세지 않는다', () async {
      final latest = await filing(
        samsung,
        '20260901000001',
        2025,
        name: '[기재정정]사업보고서 (2025.12)',
      );
      dart.documents[rSamsung] = '<TITLE AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE><P>이전 본문</P><TITLE>III.</TITLE>';
      await runSync(corpCode: samsung);
      final section = (await DartFilingSection.db.find(
        session,
        where: (t) =>
            t.filingId.equals(latest.id!) &
            t.section.equals(DartSection.businessContent),
      )).single;
      expect(section.status, FilingFetchStatus.noData);
      expect(
        (await endpoints.ingest.coverage(sessionBuilder))
            .companiesWithLatestBusinessText,
        0,
      );
    });

    test('공개 본문 6회 연속 실패하면 이번 실행의 공개 요청을 중지한다', () async {
      for (final corp in ['00000006', '00000007']) {
        final company = await Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            stockCode: corp.substring(2),
            name: corp,
            market: Market.kospi,
          ),
        );
        ids[corp] = company.id!;
        await filing(corp, '20260310${corp.substring(2)}', 2025);
      }
      final reader = _PublicBodyFixture(fail: true);
      final job = await runSync(publicDocuments: reader);
      expect(reader.receipts, hasLength(6));
      expect(job.status, IngestStatus.failed);
      expect(job.failed, greaterThanOrEqualTo(6));
    });

    test('기업별 최신 본문 우선수집은 요청한 기업만 대상으로 한다', () async {
      dart.documents['20260310000001'] =
          '<DOCUMENT><DOCUMENT-NAME>사업보고서</DOCUMENT-NAME>'
          '<TITLE>II. 사업의 내용</TITLE><P>요청 기업의 제품 설명</P>'
          '<TITLE>III. 재무에 관한 사항</TITLE></DOCUMENT>';
      await runSync(corpCode: samsung);
      expect(
        dart.calls.where((call) => call.startsWith('document|')),
        everyElement('document|20260310000001'),
      );
      expect(await BusinessDocument.db.count(session), 1);
    });

    test('본문은 하루 몫만큼만 받고 나머지는 다음 날로 남긴다', () async {
      // 재무 백필이 남아 있는 상태 (그때만 본문에 하루 몫을 따로 준다).
      final old = await filing(samsung, '20250310000001', 2024);
      await DartFiling.db.updateRow(
        session,
        old.copyWith(consolidatedStatus: FilingFetchStatus.pending),
      );
      await runSync(businessBudget: 2);
      expect(
        dart.calls.where((c) => c.startsWith('document|')),
        hasLength(2),
      );
      expect(
        await DartFilingSection.db.count(
          session,
          where: (t) =>
              t.section.equals(DartSection.businessContent) &
              t.status.equals(FilingFetchStatus.pending),
        ),
        greaterThan(0),
      );
    });

    test('하루 몫을 다 쓰면 멈추고 다음 날 이어받기를 예약한다', () async {
      final job = await runSync(dailyBudget: 10);
      expect(dart.calls, hasLength(10));
      expect(job.message, contains('다음 날 이어서 받음'));
      expect(resumes, [DateTime.utc(2026, 9, 19, 15, 1)]);
    });

    test('함께 도는 다른 수집이 호출을 쓰면 공용 장부를 보고 도중에 멈춘다', () async {
      // 이 수집의 몫은 1,000회지만, 호출마다 다른 수집이 100회씩 쓴다.
      dart.onCall = () => ApiCallBudget.record(session, ApiProvider.dart, 100);
      final job = await runSync(dailyBudget: 1000);
      expect(dart.calls.length, lessThanOrEqualTo(26));
      expect(job.message, contains('다음 날 이어서 받음'));
    });

    test('사업보고서 원본 파일에서 사업의 내용을 뽑아 하위 절로 보여 준다', () async {
      dart.documents[rSamsung] = '''
<DOCUMENT><BODY>
<TITLE ATOC="Y" AASSOCNOTE="D-0-1-0-0">I. 회사의 개요</TITLE><P>개요</P>
<TITLE ATOC="Y" AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE>
<TITLE ATOC="Y" AASSOCNOTE="L-0-2-1-L1">1. 사업의 개요</TITLE>
<P>당사는 DRAM과 NAND Flash를 생산합니다.</P>
<TITLE ATOC="Y" AASSOCNOTE="L-0-2-2-L1">2. 주요 제품 및 서비스</TITLE>
<TABLE><TR><TH>부문</TH><TH>주요 제품</TH></TR>
<TR><TD>DS</TD><TE>DRAM &amp; NAND</TE></TR></TABLE>
<TITLE ATOC="Y" AASSOCNOTE="D-0-3-0-0">III. 재무에 관한 사항</TITLE><P>재무</P>
</BODY></DOCUMENT>''';
      await runSync(corpCode: samsung);
      final doc = (await BusinessDocument.db.findFirstRow(session))!;
      expect(doc.rceptNo, rSamsung);
      expect(doc.text, isNot(contains('재무')));
      final content = (await endpoints.disclosure.businessContent(
        sessionBuilder,
        samsung,
      ))!;
      expect(content.title, 'II. 사업의 내용');
      expect(
        [for (final s in content.sections) s.title],
        [
          '1. 사업의 개요',
          '2. 주요 제품 및 서비스',
        ],
      );
      expect(content.sections.last.text, '부문 | 주요 제품\nDS | DRAM & NAND');
      expect(content.source!.reference, rSamsung);
    });

    test('최신 반기 본문을 연간과 별개로 저장하고 원문·시장점유율 기간을 보존한다', () async {
      const half = '20260814009999';
      final halfFiling = await filing(
        samsung,
        half,
        2026,
        name: '반기보고서 (2026.06)',
        code: FinancialReportCode.halfYear,
      );
      dart.documents[rSamsung] = '<DOCUMENT><BODY><TITLE AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE><P>2025년 연간 사업</P></BODY></DOCUMENT>';
      dart.documents[half] =
          '''<DOCUMENT><BODY><TITLE AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE>
        <TABLE><TR><TH>제 품</TH><TH>2026년 반기</TH><TH>2025년</TH><TH>2024년</TH></TR>
        <TR><TD>DRAM</TD><TD>39.4%</TD><TD>34.0%</TD><TD>41.5%</TD></TR></TABLE>
        <P>※ 시장점유율은 금액기준이며, 2026년 반기 시장점유율은 당사 추정치입니다.</P>
        </BODY></DOCUMENT>''';
      await runSync(corpCode: samsung);
      final reports = await DisclosureReport.db.find(
        session,
        where: (t) => t.section.equals(DartSection.businessContent),
      );
      expect(
        reports.map((r) => r.reportCode),
        containsAll([FinancialReportCode.annual, FinancialReportCode.halfYear]),
      );
      expect(reports.every((r) => r.supersededById == null), isTrue);
      expect(
        reports
            .singleWhere((r) => r.reportCode == FinancialReportCode.halfYear)
            .settlementDate,
        DateTime.utc(2026, 6, 30),
      );
      final ledger = await DartFilingSection.db.find(
        session,
        where: (t) => t.filingId.equals(halfFiling.id!),
      );
      expect(
        ledger.map((r) => r.section),
        unorderedEquals([
          DartSection.businessContent,
          DartSection.largestShareholders,
          DartSection.executives,
          DartSection.investments,
          DartSection.minorityShareholders,
        ]),
      );
      final core = await DartFilingSection.db.findFirstRow(
        session,
        where: (t) =>
            t.companyId.equals(ids[samsung]!) &
            t.section.equals(DartSection.largestShareholders),
      );
      expect(core!.yearRank, 0);
      final content = await endpoints.disclosure.businessContent(
        sessionBuilder,
        samsung,
      );
      expect(content!.bsnsYear, 2026);
      expect(content.rceptNo, half);
      final annualContent = await endpoints.disclosure.businessContent(
        sessionBuilder,
        samsung,
        bsnsYear: 2025,
      );
      expect(annualContent!.rceptNo, rSamsung);
      final facts = await endpoints.disclosure.factTrends(
        sessionBuilder,
        samsung,
      );
      expect(
        facts.map((f) => (f.asOf, f.value)),
        containsAll([
          (DateTime.utc(2026, 6, 30), 39.4),
          (DateTime.utc(2025, 12, 31), 34.0),
        ]),
      );
      final calls = dart.calls.length;
      await runSync(corpCode: samsung);
      expect(dart.calls.length, calls); // idempotent
      const correction = '20260901009999';
      await filing(
        samsung,
        correction,
        2026,
        name: '[기재정정]반기보고서 (2026.06)',
        code: FinancialReportCode.halfYear,
      );
      dart.documents[correction] = dart.documents[half]!.replaceAll(
        '39.4%',
        '39.5%',
      );
      await runSync(corpCode: samsung);
      final corrected = await endpoints.disclosure.factTrends(
        sessionBuilder,
        samsung,
      );
      expect(
        corrected
            .where((f) => f.asOf == DateTime.utc(2026, 6, 30))
            .map((f) => f.value),
        [39.5],
      );
      final annual = await DisclosureReport.db.findFirstRow(
        session,
        where: (t) =>
            t.rceptNo.equals(rSamsung) &
            t.section.equals(DartSection.businessContent),
      );
      expect(annual!.supersededById, isNull);
    });

    test('정정공시의 원본 파일이 없으면 같은 사업연도의 이전 접수번호로 받는다', () async {
      const corrected = '20260401000001';
      await filing(samsung, corrected, 2025, name: '[첨부정정]사업보고서 (2025.12)');
      dart.documents[rSamsung] =
          '<TITLE AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE><P>본문</P>'
          '<TITLE AASSOCNOTE="D-0-3-0-0">III.</TITLE>';
      await runSync(corpCode: samsung);
      expect(
        dart.calls,
        containsAllInOrder([
          'document|$corrected',
          'document|$rSamsung',
        ]),
      );
      final doc = (await BusinessDocument.db.findFirstRow(session))!;
      expect(doc.rceptNo, rSamsung);
    });

    test('첨부만 고친 정정공시뿐이면 공시 목록에서 원본 사업보고서를 찾아 받는다', () async {
      // 장부에는 최종 보고서(첨부정정)만 있다. 원본 파일이 없으니(014) 목록을 물어 원본을 찾는다.
      // 원본은 장부(dart_filing)에 없다 — 목록을 last_reprt_at=Y로 훑기 때문이다.
      const attachmentFix = '20260319000633', original = '20260305000009';
      await filing(
        life,
        attachmentFix,
        2025,
        name: '[첨부정정]사업보고서 (2025.12)',
      );
      dart.filings[life] = [
        (original, '사업보고서 (2025.12)', '20260310'),
        (attachmentFix, '[첨부정정]사업보고서 (2025.12)', '20260319'),
      ];
      dart.documents[original] =
          '<TITLE AASSOCNOTE="D-0-2-0-0">II. 사업의 내용</TITLE><P>본문</P>'
          '<TITLE AASSOCNOTE="D-0-3-0-0">III.</TITLE>';

      await runSync(corpCode: life);

      expect(
        dart.calls,
        containsAllInOrder([
          'document|$attachmentFix',
          'list|$life',
          'document|$original',
        ]),
      );
      final doc = (await BusinessDocument.db.findFirstRow(
        session,
        where: (t) => t.companyId.equals(ids[life]!),
      ))!;
      expect(doc.rceptNo, original);
      final coverage = await endpoints.ingest.coverage(sessionBuilder);
      expect(coverage.companiesWithLatestBusinessText, 0);
    });

    test('한 사업연도에 정기보고서가 둘이면 이 보고서의 행만 저장한다', () async {
      // 결산월이 바뀐 리츠 등은 같은 사업연도·보고서 코드로 두 건을 내서, 응답에 두
      // 접수번호의 행이 함께 온다. 예전에는 통째로 실패 처리했다.
      const earlier = '20250522000350';
      dart.set('hyslrSttus', samsung, 2025, [
        holder(earlier, samsung, '옛 최대주주㈜', '최대주주 본인', '5.00'),
        holder(rSamsung, samsung, '삼성생명보험㈜', '최대주주 본인', '8.51'),
      ]);

      final job = await runSync(corpCode: samsung);

      expect(job.failed, 0);
      final reports = await DisclosureReport.db.find(
        session,
        where: (t) => t.section.equals(DartSection.largestShareholders),
      );
      expect([for (final r in reports) r.rceptNo], [rSamsung]);
      final gov = (await endpoints.governance.summary(
        sessionBuilder,
        samsung,
      ))!;
      expect([for (final s in gov.shareholders) s.holderName], ['삼성생명보험㈜']);
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
