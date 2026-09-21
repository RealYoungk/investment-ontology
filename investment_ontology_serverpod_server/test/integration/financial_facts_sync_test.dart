import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

typedef Filing = ({String corp, String name, String rcept, String date});

/// 가짜 DART. 공시 목록과 재무제표 응답을 테스트에서 바꿀 수 있다.
class FakeDart {
  final filings = <Filing>[];

  /// `corp|year|reprt|fs` → 응답 본문. 없으면 013.
  final statements = <String, String>{};
  final financialCalls = <String>[];
  var listCalls = 0;

  static String key(String corp, int year, String code, String fs) =>
      '$corp|$year|$code|$fs';

  void setRows(
    String corp,
    int year,
    String code,
    String fs,
    List<Map<String, String>> rows,
  ) => statements[key(corp, year, code, fs)] = jsonEncode({
    'status': '000',
    'message': '정상',
    'list': rows,
  });

  DartClient client() => DartClient(
    'key',
    httpClient: MockClient((req) async {
      final q = req.url.queryParameters;
      if (req.url.path.endsWith('list.json')) {
        listCalls++;
        final items = [
          for (final f in filings)
            if (f.date.compareTo(q['bgn_de']!) >= 0 &&
                f.date.compareTo(q['end_de']!) <= 0 &&
                (q['corp_code'] == null || q['corp_code'] == f.corp))
              {
                'corp_code': f.corp,
                'corp_name': f.corp,
                'stock_code': '000001',
                'corp_cls': 'Y',
                'report_nm': f.name,
                'rcept_no': f.rcept,
                'rcept_dt': f.date,
              },
        ];
        if (items.isEmpty) {
          return _body('{"status":"013","message":"조회된 데이타가 없습니다."}');
        }
        return _body(
          jsonEncode({
            'status': '000',
            'total_page': 1,
            'total_count': items.length,
            'list': items,
          }),
        );
      }
      final k = key(
        q['corp_code']!,
        int.parse(q['bsns_year']!),
        q['reprt_code']!,
        q['fs_div']!,
      );
      financialCalls.add(k);
      return _body(
        statements[k] ?? '{"status":"013","message":"조회된 데이타가 없습니다."}',
      );
    }),
  );

  static http.Response _body(String s) =>
      http.Response.bytes(utf8.encode(s), 200);
}

Map<String, String> row(
  String rcept,
  String sjDiv,
  String accountId,
  String name,
  String amount, {
  String detail = '-',
  String ord = '1',
  String? cumulative,
  String? prior,
}) => {
  'rcept_no': rcept,
  'corp_code': '00000001',
  'bsns_year': '2025',
  'reprt_code': '11011',
  'sj_div': sjDiv,
  'account_id': accountId,
  'account_nm': name,
  'account_detail': detail,
  'thstrm_nm': '제 57 기',
  'thstrm_amount': amount,
  'thstrm_add_amount': ?cumulative,
  'frmtrm_nm': '제 56 기',
  'frmtrm_amount': ?prior,
  'ord': ord,
  'currency': 'KRW',
};

void main() {
  withServerpod('Given FinancialFactsSync', (sessionBuilder, endpoints) {
    late Session session;
    late FakeDart dart;
    final now = DateTime.utc(2026, 9, 17, 3);
    final resumes = <DateTime>[];

    Future<IngestJob> runSync({
      int dailyBudget = 18000,
      String? corpCode,
    }) async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      await FinancialFactsSync(
        session,
        dart.client(),
        job.id!,
        dailyBudget: dailyBudget,
        callInterval: Duration.zero,
        clock: () => now,
        corpCode: corpCode,
        scheduleResume: (at) async => resumes.add(at),
      ).run();
      return (await IngestJob.db.findById(session, job.id!))!;
    }

    Future<Company> company(String corp, {int fiscalMonth = 12}) =>
        Company.db.insertRow(
          session,
          Company(
            corpCode: corp,
            name: corp,
            market: Market.kospi,
            fiscalMonth: fiscalMonth,
          ),
        );

    setUp(() async {
      session = sessionBuilder.build();
      dart = FakeDart();
      resumes.clear();
      await company('00000001');
      dart.filings.add((
        corp: '00000001',
        name: '사업보고서 (2025.12)',
        rcept: '20260310000001',
        date: '20260310',
      ));
      dart.setRows('00000001', 2025, '11011', 'CFS', [
        row(
          '20260310000001',
          'BS',
          'ifrs-full_Assets',
          '자산총계',
          '566942110000000',
          prior: '514531948000000',
        ),
        row(
          '20260310000001',
          'IS',
          'dart_OperatingIncomeLoss',
          '영업이익',
          '43601051000000',
          ord: '6',
        ),
        row(
          '20260310000001',
          'SCE',
          'dart_ChangesInConsolidatedCompanies',
          '연결실체의 변동',
          '0',
          detail: '자본 [구성요소]|자본금 [구성요소]',
        ),
        row('20260310000001', 'CIS', '-표준계정코드 미사용-', '기타', '12.5'),
      ]);
    });

    test('공시 목록의 정기보고서를 연결·별도로 받아 출처와 함께 저장한다', () async {
      final job = await runSync();

      expect(job.status, IngestStatus.succeeded, reason: job.message);
      expect(dart.financialCalls, [
        '00000001|2025|11011|CFS',
        '00000001|2025|11011|OFS',
      ]);
      final filing = (await DartFiling.db.find(session)).single;
      expect(filing.reportCode, FinancialReportCode.annual);
      expect(filing.bsnsYear, 2025);
      expect(filing.consolidatedStatus, FilingFetchStatus.stored);
      expect(filing.separateStatus, FilingFetchStatus.noData);

      final report = (await FinancialReport.db.find(session)).single;
      expect(report.fsDiv, FsDiv.consolidated);
      expect(report.rceptNo, '20260310000001');
      expect(report.receivedDate, DateTime.utc(2026, 3, 10));
      expect(report.factCount, 4);
      expect(report.invalidAmountCount, 1);
      final source = (await Source.db.findById(session, report.sourceId))!;
      expect(source.kind, SourceKind.dartReport);
      expect(source.reference, '20260310000001');

      final facts = await FinancialFact.db.find(
        session,
        orderBy: (t) => t.id,
      );
      expect(facts.map((f) => f.statement), [
        FinancialStatementKind.balanceSheet,
        FinancialStatementKind.incomeStatement,
        FinancialStatementKind.equityChanges,
        FinancialStatementKind.comprehensiveIncome,
      ]);
      expect(facts[0].amount, BigInt.parse('566942110000000'));
      expect(facts[0].priorAmount, BigInt.parse('514531948000000'));
      expect(facts[0].priorPeriodName, '제 56 기');
      expect(facts[2].accountDetail, '자본 [구성요소]|자본금 [구성요소]');
      expect(facts[3].accountId, isNull);
      expect(facts[3].amount, isNull, reason: '소수는 비워 둔다');
      expect(facts.every((f) => f.sourceId == report.sourceId), isTrue);
    });

    test('최근 며칠 공시는 종류를 가리지 않고 상장사 것만 장부에 남긴다', () async {
      dart.filings.addAll([
        (
          corp: '00000001',
          name: '단일판매ㆍ공급계약체결',
          rcept: '20260915000010',
          date: '20260915',
        ),
        (
          corp: '00000009',
          name: '주식등의대량보유상황보고서',
          rcept: '20260915000011',
          date: '20260915',
        ),
      ]);

      await runSync();

      final feed = await DartDisclosure.db.find(session);
      expect(
        feed.map((d) => d.rceptNo),
        ['20260915000010'],
        reason: '기업 목록에 없는 곳의 공시는 남기지 않는다',
      );
      expect(feed.single.reportName, '단일판매ㆍ공급계약체결');
      expect(
        await DartFiling.db.count(
          session,
          where: (f) => f.rceptNo.equals('20260915000010'),
        ),
        0,
        reason: '정기보고서가 아니므로 재무 수집 장부에는 들어가지 않는다',
      );

      // 다시 돌려도 같은 공시를 두 번 넣지 않는다.
      await runSync();
      expect(await DartDisclosure.db.count(session), 1);
    });

    test('공시 목록은 달력 3개월을 넘지 않는 구간으로 나눠 조회한다', () async {
      final ranges = <(String, String)>[];
      final base = dart.client();
      final recording = DartClient(
        'key',
        httpClient: MockClient((req) async {
          if (req.url.path.endsWith('list.json')) {
            ranges.add((
              req.url.queryParameters['bgn_de']!,
              req.url.queryParameters['end_de']!,
            ));
          }
          return http.Response.bytes(
            utf8.encode('{"status":"013","message":"없음"}'),
            200,
          );
        }),
      );
      base.close();
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      await FinancialFactsSync(
        session,
        recording,
        job.id!,
        callInterval: Duration.zero,
        clock: () => now,
      ).run();

      expect(
        ranges.first,
        ('20260914', '20260917'),
        reason: '먼저 최근 며칠 공시 피드를 훑는다',
      );
      expect(ranges[1].$1, '20220101', reason: '분기·반기 5개 사업연도 = FY2022부터');
      expect(ranges.last.$2, '20260917');
      for (final (from, to) in ranges) {
        final f = DateTime.parse(from);
        final t = DateTime.parse(to);
        final limit = DateTime.utc(f.year, f.month + 3, f.day);
        expect(t.isBefore(limit), isTrue, reason: '$from~$to');
      }
    });

    test('전체 스캔은 커서 이후만 다시 훑고, 기업 하나 수집은 커서를 움직이지 않는다', () async {
      await company('00000002');
      dart.filings.add((
        corp: '00000002',
        name: '사업보고서 (2025.12)',
        rcept: '20260311000007',
        date: '20260311',
      ));

      final single = await runSync(corpCode: '00000002');

      expect(single.message, startsWith('00000002: '));
      expect(await DartFilingScan.db.count(session), 0);
      expect(dart.financialCalls, [
        '00000002|2025|11011|CFS',
        '00000002|2025|11011|OFS',
      ]);
      expect(
        (await DartFiling.db.find(session)).map((f) => f.corpCode),
        ['00000002'],
        reason: '다른 기업 공시는 장부에 넣지 않는다',
      );

      dart.listCalls = 0;
      await runSync();
      final cursor = (await DartFilingScan.db.findFirstRow(session))!;
      expect(cursor.scannedThrough, DateTime.utc(2026, 9, 17));
      expect(
        {for (final f in await DartFiling.db.find(session)) f.corpCode},
        {'00000001', '00000002'},
      );
      final fullScanCalls = dart.listCalls;

      dart.listCalls = 0;
      await runSync();
      expect(dart.listCalls, lessThan(fullScanCalls));
      expect(dart.listCalls, 2, reason: '공시 피드 1회 + 커서 7일 전부터 한 구간');
    });

    test('수집 범위가 넓어져 커서가 과거를 덮지 않으면 처음부터 다시 훑는다', () async {
      // 3년 범위일 때 남은 커서: 2024-01-01부터 오늘까지 훑음.
      await DartFilingScan.db.insertRow(
        session,
        DartFilingScan(
          scannedFrom: DateTime.utc(2024, 1, 1),
          scannedThrough: DateTime.utc(2026, 9, 17),
          updatedAt: DateTime.utc(2026, 9, 17),
        ),
      );
      dart.filings.add((
        corp: '00000001',
        name: '사업보고서 (2021.12)',
        rcept: '20220310000008',
        date: '20220310',
      ));

      await runSync();

      expect(
        (await DartFiling.db.find(session)).map((f) => f.rceptNo),
        contains('20220310000008'),
      );
      final cursor = (await DartFilingScan.db.findFirstRow(session))!;
      expect(cursor.scannedFrom, DateTime.utc(2022, 1, 1));
      expect(cursor.scannedThrough, DateTime.utc(2026, 9, 17));

      // 아직 받을 것이 남아 있으면 범위는 5개년 그대로다.
      final first = (await DartFiling.db.findFirstRow(session))!;
      await DartFiling.db.updateRow(
        session,
        first.copyWith(consolidatedStatus: FilingFetchStatus.pending),
      );
      dart.listCalls = 0;
      await runSync();
      expect(dart.listCalls, 2, reason: '공시 피드 1회 + 다시 덮였으니 커서 7일 전부터만');
    });

    test('최근 5개년을 다 받으면 10년으로 넓혀 다시 훑는다', () async {
      await runSync();
      expect(
        (await DartFilingScan.db.findFirstRow(session))!.scannedFrom,
        DateTime.utc(2022, 1, 1),
        reason: '처음에는 5개년',
      );
      // 받을 것이 남지 않은 상태에서 다시 돌리면 범위를 넓힌다.
      final pending = await DartFiling.db.find(
        session,
        where: (t) =>
            t.consolidatedStatus.equals(FilingFetchStatus.pending) |
            t.separateStatus.equals(FilingFetchStatus.pending),
      );
      for (final f in pending) {
        await DartFiling.db.updateRow(
          session,
          f.copyWith(
            consolidatedStatus: FilingFetchStatus.stored,
            separateStatus: FilingFetchStatus.stored,
          ),
        );
      }
      await runSync();
      expect(
        (await DartFilingScan.db.findFirstRow(session))!.scannedFrom,
        DateTime.utc(2017, 1, 1),
        reason: '다 받았으면 10개년',
      );
    });

    test('다시 돌리면 받은 공시는 호출하지 않는다', () async {
      await runSync();
      dart.financialCalls.clear();

      final job = await runSync();

      expect(dart.financialCalls, isEmpty);
      expect(job.total, 0);
      expect(await FinancialReport.db.count(session), 1);
    });

    test('정정공시는 새 행을 추가하고 이전 보고서·사실을 supersededBy로 잇는다', () async {
      await runSync();
      dart.filings.add((
        corp: '00000001',
        name: '[기재정정]사업보고서 (2025.12)',
        rcept: '20260915000002',
        date: '20260915',
      ));
      dart.setRows('00000001', 2025, '11011', 'CFS', [
        row(
          '20260915000002',
          'BS',
          'ifrs-full_Assets',
          '자산총계',
          '566942110000001',
        ),
        row(
          '20260915000002',
          'IS',
          'dart_OperatingIncomeLoss',
          '영업이익',
          '43601051000000',
          ord: '6',
        ),
      ]);

      await runSync();

      final reports = await FinancialReport.db.find(
        session,
        orderBy: (t) => t.id,
      );
      expect(reports, hasLength(2));
      expect(reports[0].supersededById, reports[1].id);
      expect(reports[1].supersededById, isNull);
      expect(reports[1].reportName, '[기재정정]사업보고서 (2025.12)');

      final old = await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(reports[0].id!),
        orderBy: (t) => t.id,
      );
      expect(old, hasLength(4), reason: '이전 사실은 지우지 않는다');
      final current = {
        for (final f in await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(reports[1].id!),
        ))
          f.accountName: f,
      };
      expect(old[0].supersededById, current['자산총계']!.id);
      expect(old[1].supersededById, current['영업이익']!.id);
      expect(old[2].supersededById, isNull, reason: '정정본에 없는 칸');
      expect(current['자산총계']!.amount, BigInt.parse('566942110000001'));
    });

    test('빈 응답은 실패로 세고, 허용 횟수를 넘으면 더 부르지 않는다', () async {
      dart.statements[FakeDart.key('00000001', 2025, '11011', 'CFS')] = '';

      for (var i = 0; i < FinancialFactsSync.maxAttempts; i++) {
        final job = await runSync();
        expect(job.failed, 1);
      }
      final filing = (await DartFiling.db.find(session)).single;
      expect(filing.consolidatedStatus, FilingFetchStatus.failed);
      expect(filing.attempts, FinancialFactsSync.maxAttempts);
      expect(filing.lastError, contains('empty'));
      dart.financialCalls.clear();

      await runSync();

      expect(dart.financialCalls, isEmpty);
    });

    test('연결·별도가 모두 실패해도 실패 횟수는 한 번 실행에 1씩 오른다', () async {
      dart.statements[FakeDart.key('00000001', 2025, '11011', 'CFS')] = '';
      dart.statements[FakeDart.key('00000001', 2025, '11011', 'OFS')] = '';

      await runSync();
      expect((await DartFiling.db.find(session)).single.attempts, 1);
      await runSync();
      expect((await DartFiling.db.find(session)).single.attempts, 2);

      dart.financialCalls.clear();
      await runSync();
      expect(
        dart.financialCalls,
        hasLength(2),
        reason: '세 번째 실행에서도 연결·별도를 모두 다시 시도한다',
      );
    });

    test('응답의 회사·사업연도·보고서 코드가 요청과 다르면 저장하지 않는다', () async {
      dart.setRows('00000001', 2025, '11011', 'CFS', [
        {
          ...row('20260310000001', 'BS', 'ifrs-full_Assets', '자산총계', '1'),
          'bsns_year': '2024',
        },
      ]);

      await runSync();

      expect(await FinancialReport.db.count(session), 0);
      final filing = (await DartFiling.db.find(session)).single;
      expect(filing.consolidatedStatus, FilingFetchStatus.failed);
      expect(filing.lastError, contains('mismatch'));
    });

    test('재무제표가 안 바뀐 정정(첨부추가)은 이전 접수번호로, 표시를 뗀 이름으로 저장한다', () async {
      dart.filings
        ..clear()
        ..add((
          corp: '00000001',
          name: '[첨부추가]사업보고서 (2025.12)',
          rcept: '20260320000009',
          date: '20260320',
        ));

      await runSync();

      final report = (await FinancialReport.db.find(session)).single;
      expect(report.rceptNo, '20260310000001');
      expect(report.reportName, '사업보고서 (2025.12)');
      expect(
        (await DartFiling.db.find(session)).single.consolidatedStatus,
        FilingFetchStatus.stored,
      );
    });

    test('판정할 수 없는 보고서는 받지 않고, 범위 밖 사업연도는 장부에 넣지 않는다', () async {
      await company('00000002', fiscalMonth: 6);
      dart.filings
        ..add((
          corp: '00000002',
          name: '반기보고서 (2026.03)',
          rcept: '20260515000003',
          date: '20260515',
        ))
        ..add((
          corp: '00000001',
          name: '[기재정정]사업보고서 (2020.12)',
          rcept: '20260201000004',
          date: '20260201',
        ))
        ..add((
          corp: '99999999',
          name: '사업보고서 (2025.12)',
          rcept: '20260310000005',
          date: '20260310',
        ));

      await runSync();

      final filings = {
        for (final f in await DartFiling.db.find(session)) f.rceptNo: f,
      };
      expect(
        filings.keys,
        unorderedEquals(['20260310000001', '20260515000003']),
      );
      expect(
        filings['20260515000003']!.consolidatedStatus,
        FilingFetchStatus.unsupported,
      );
      expect(
        dart.financialCalls.where((c) => c.startsWith('00000002')),
        isEmpty,
      );
    });

    test('일일 예산에 닿으면 멈추고 다음 날 이어받기를 예약한다', () async {
      // 첫 실행: 공시 목록 스캔 호출 수를 센다.
      final scanOnly = FakeDart()..filings.addAll(dart.filings);
      dart = scanOnly;
      await runSync(dailyBudget: 1000);
      final scanCalls = dart.listCalls;
      await DartFiling.db.deleteWhere(
        session,
        where: (t) => t.id.notEquals(null),
      );
      await ApiCallUsage.db.deleteWhere(
        session,
        where: (t) => t.id.notEquals(null),
      );
      await DartFilingScan.db.deleteWhere(
        session,
        where: (t) => t.id.notEquals(null),
      );
      resumes.clear();
      dart = FakeDart()..filings.addAll(scanOnly.filings);

      final job = await runSync(dailyBudget: scanCalls + 1);

      expect(dart.financialCalls, ['00000001|2025|11011|CFS']);
      expect(job.status, IngestStatus.succeeded);
      expect(job.message, contains('예산'));
      expect(resumes, [DateTime.utc(2026, 9, 17, 15, 10)]);
      final filing = (await DartFiling.db.find(session)).single;
      expect(filing.separateStatus, FilingFetchStatus.pending);
    });
  });
}
