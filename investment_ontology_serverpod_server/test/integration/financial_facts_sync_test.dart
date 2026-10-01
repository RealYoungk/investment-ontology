import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_period_metadata.dart';

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/api_call_budget.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_collection_scope.dart';
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
  bool offline = false;
  bool publicXbrl = false;
  final publicOriginals = <String, List<int>>{};

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
      if (offline) throw http.ClientException('Failed host lookup');
      if (req.url.host == 'dart.fss.or.kr') {
        final receipt =
            req.url.queryParameters['rcpNo'] ??
            req.url.queryParameters['rcp_no'] ??
            '20250409002838';
        if (!publicXbrl) return http.Response('unavailable', 503);
        if (req.url.path == '/dsaf001/main.do') {
          return http.Response(
            "openPdfDownload('$receipt', '10571658')",
            200,
          );
        }
        if (req.url.path == '/pdf/download/main.do') {
          return http.Response(
            '<a href="/pdf/download/ifrs.do?rcp_no=$receipt&amp;dcm_no=10571658&amp;lang=ko">XBRL</a>',
            200,
          );
        }
        return http.Response.bytes(
          publicOriginals[receipt] ??
              File('test/fixtures/financial_xbrl/cosnine_20250409002838.zip')
                  .readAsBytesSync(),
          200,
        );
      }
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

class AttachmentOriginalClient extends DartClient {
  AttachmentOriginalClient(this.originalReceipt, this.zip)
    : super(
        'test-key',
        httpClient: MockClient(
          (_) async => http.Response('{"status":"013"}', 200),
        ),
      );
  final String originalReceipt;
  final List<int> zip;
  int linkedCalls = 0;
  @override
  Future<({List<int> zip, Uri source})> fetchPublicAnnualXbrl(
    String receipt,
  ) async => throw const FormatException('No exact target XBRL');
  @override
  Future<
    ({
      List<int> zip,
      Uri source,
      String receipt,
      String correctionReceipt,
      Uri correctionSource,
    })
  >
  fetchLinkedAnnualXbrl(
    String receipt, {
    required String reportName,
    required String corpCode,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    linkedCalls++;
    return (
      zip: zip,
      source: Uri.parse(
        'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=$originalReceipt',
      ),
      receipt: originalReceipt,
      correctionReceipt: receipt,
      correctionSource: Uri.parse(
        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
      ),
    );
  }
}

class MetadataOnlyClient extends DartClient {
  MetadataOnlyClient({this.transportFailure = false, this.failFirst = false})
    : super(
        'test-key',
        httpClient: MockClient(
          (r) async =>
              http.Response('{"status":"013","message":"no data"}', 200),
        ),
      );
  final bool transportFailure;
  final bool failFirst;
  int metadataCalls = 0;
  int xbrlCalls = 0;
  @override
  Future<PublicFinancialPeriodMetadata> fetchAnnualPeriodMetadata(
    String receipt, {
    required String corpCode,
    required String companyName,
    required String targetReceipt,
    required DateTime periodEnd,
    bool halfYear = false,
  }) async {
    metadataCalls++;
    if (transportFailure || (failFirst && metadataCalls == 1)) {
      throw const FormatException('Invalid metadata response');
    }
    return PublicFinancialPeriodMetadata(
      receipt: receipt,
      corpCode: corpCode,
      periodStart: DateTime.utc(2025, 1, 1),
      periodEnd: periodEnd,
      shellSource: Uri.parse(
        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
      ),
      coverSource: Uri.parse(
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=$receipt',
      ),
      digest: 'a' * 64,
    );
  }

  @override
  Future<({List<int> zip, Uri source})> fetchPublicAnnualXbrl(
    String receipt,
  ) async {
    xbrlCalls++;
    throw const FormatException('Unexpected numeric replacement');
  }
}

class ExactPublicOriginalClient extends AttachmentOriginalClient {
  ExactPublicOriginalClient(super.originalReceipt, super.zip);
  @override
  Future<({List<int> zip, Uri source})> fetchPublicAnnualXbrl(
    String receipt,
  ) async {
    if (receipt != originalReceipt) {
      throw const FormatException('Wrong receipt');
    }
    return (
      zip: zip,
      source: Uri.parse(
        'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=$receipt',
      ),
    );
  }
}

class AttachmentHtmlClient extends AttachmentOriginalClient {
  AttachmentHtmlClient() : super('20240701000635', const []);
  int htmlCalls = 0;
  @override
  Future<
    ({
      List<int> zip,
      Uri source,
      String receipt,
      String correctionReceipt,
      Uri correctionSource,
    })
  >
  fetchLinkedAnnualXbrl(
    String receipt, {
    required String reportName,
    required String corpCode,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async => throw const FormatException('No original XBRL');
  @override
  Future<PublicFinancialHtmlSource> fetchAttachmentAnnualHtml(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    htmlCalls++;
    final ledger = jsonDecode(
      File('test/fixtures/financial_html/financial-html-source-ledger.json')
          .readAsStringSync(),
    ) as List;
    Uri source(String basis) => Uri.parse(
      (ledger.firstWhere((r) => r['basis'] == basis) as Map)['url'] as String,
    );
    final basis = consolidated ? 'cfs' : 'ofs';
    return PublicFinancialHtmlSource(
      sourceReceipt: originalReceipt,
      correctionReceipt: receipt,
      correctionSource: Uri.parse(
        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
      ),
      coverHtml: File(
        'test/fixtures/financial_html/$originalReceipt-cover.html',
      ).readAsStringSync(),
      coverSource: source('cover'),
      statementHtml: File(
        'test/fixtures/financial_html/$originalReceipt-$basis.html',
      ).readAsStringSync(),
      statementSource: source(basis),
      periodStart: DateTime.utc(2023, 4, 1),
      periodEnd: DateTime.utc(2024, 3, 31),
      rows: const [],
    );
  }
}

class HalfYearHtmlClient extends AttachmentOriginalClient {
  HalfYearHtmlClient({this.wrongReceipt = false})
    : super('20260814002145', const []);
  final bool wrongReceipt;
  int halfCalls = 0;
  @override
  Future<PublicFinancialHtmlSource> fetchHalfYearHtml(
    String receipt, {
    required String reportName,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    halfCalls++;
    expect(consolidated, isFalse);
    const dir = 'test/fixtures/financial_html/wonforyou-half-20260814002145';
    return PublicFinancialHtmlSource(
      sourceReceipt: wrongReceipt ? '20260814002146' : receipt,
      correctionReceipt: null,
      correctionSource: null,
      coverHtml: File('$dir/cover.html').readAsStringSync(),
      statementHtml: File('$dir/financial-body.html').readAsStringSync(),
      coverSource: Uri.parse(
        (jsonDecode(File('$dir/cover-source-evidence.json').readAsStringSync())
                as Map)['source']
            as String,
      ),
      statementSource: Uri.parse(
        (jsonDecode(File('$dir/source-evidence.json').readAsStringSync())
                as Map)['financialBodyUri']
            as String,
      ),
      periodStart: DateTime.utc(2026, 1, 1),
      periodEnd: DateTime.utc(2026, 6, 30),
      rows: const [],
    );
  }
}

void main() {
  withServerpod('Given FinancialFactsSync', (sessionBuilder, endpoints) {
    late Session session;
    late FakeDart dart;
    final now = DateTime.utc(2026, 9, 17, 3);
    final resumes = <DateTime>[];

    Future<IngestJob> runSync({
      int? dailyBudget = 18000,
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

    test('공시 검색 통신 장애는 실패로 기록하고 15분 뒤 재개한다', () async {
      dart.offline = true;
      final job = await runSync();
      expect(job.status, IngestStatus.failed);
      expect(job.apiCalls, 1);
      expect(resumes, [now.add(const Duration(minutes: 15))]);
      dart.offline = false;
      expect((await runSync()).status, IngestStatus.succeeded);
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

    test('재무 예산을 이미 넘겨 쓴 날에도 공시 피드는 돈다', () async {
      // 오늘 DART 호출을 재무 예산보다 많이 쓴 상태 (다른 수집이 썼다).
      await ApiCallBudget.record(
        session,
        ApiProvider.dart,
        19538,
        now: now,
      );
      dart.filings.add((
        corp: '00000001',
        name: '단일판매ㆍ공급계약체결',
        rcept: '20260915000010',
        date: '20260915',
      ));

      final job = await runSync(dailyBudget: 0);

      expect(await DartDisclosure.db.count(session), 1);
      expect(job.message, contains('공시 피드 1건'));
      expect(dart.financialCalls, isEmpty, reason: '재무제표는 한 벌도 받지 않는다');
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
      expect(ranges[1].$1, '20210101', reason: '기업별 결산월의 연간 5개년을 발견하는 목록 창');
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
      expect(cursor.scannedFrom, DateTime.utc(2021, 1, 1));
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

    test('최근 5개년을 다 받아도 10년으로 자동 확대하지 않는다', () async {
      await runSync();
      expect(
        (await DartFilingScan.db.findFirstRow(session))!.scannedFrom,
        DateTime.utc(2021, 1, 1),
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
        DateTime.utc(2021, 1, 1),
        reason: '다 받아도 5개년',
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

    for (final mismatchError in [
      'fresh receiptPeriodMismatch',
      'DartApiException(mismatch): wrong year',
      'DartApiException(receiptPeriodMismatch): wrong period',
      'OFS: API period mismatch; exact-receipt XBRL fallback failed',
    ]) {
      test(
        'exhausted annual $mismatchError recovers only from exact receipt XBRL with provenance',
        () async {
          final c = (await Company.db.find(session)).single;
          await Company.db.updateRow(
            session,
            c.copyWith(
              corpCode: '00442455',
              market: Market.other,
              stockCode: '082660',
            ),
          );
          dart.filings.clear();
          final bad =
              row('20250409002838', 'BS', 'ifrs-full_Assets', '자산총계', '1')
                ..['corp_code'] = '00442455'
                ..['bsns_year'] = mismatchError == 'fresh receiptPeriodMismatch'
                    ? '2024'
                    : '2025'
                ..['rcept_no'] = mismatchError == 'fresh receiptPeriodMismatch'
                    ? '20240319000001'
                    : '20250409002838';
          for (final fs in ['CFS', 'OFS']) {
            dart.setRows('00442455', 2024, '11011', fs, [bad]);
          }
          await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: '20250409002838',
              corpCode: '00442455',
              companyId: c.id,
              reportName: '[기재정정]사업보고서 (2024.12)',
              receivedDate: DateTime.utc(2025, 4, 9),
              bsnsYear: 2024,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: mismatchError == 'fresh receiptPeriodMismatch'
                  ? 0
                  : FinancialFactsSync.maxAttempts,
              lastError: mismatchError,
              discoveredAt: now,
            ),
          );
          dart.publicXbrl = true;
          final job = await runSync(
            corpCode: '00442455',
            dailyBudget: mismatchError == 'fresh receiptPeriodMismatch'
                ? 18000
                : 0,
          );
          expect(
            dart.financialCalls,
            mismatchError == 'fresh receiptPeriodMismatch'
                ? orderedEquals([
                    '00442455|2024|11011|CFS',
                    '00442455|2024|11011|OFS',
                  ])
                : isEmpty,
            reason: 'fresh mismatch checks both API bases; verified prior mismatch uses only the exact public original',
          );
          expect(job.status, IngestStatus.succeeded);
          expect(job.message, contains('원문 XBRL 핵심계정 복구 2벌'));
          final reports = await FinancialReport.db.find(session);
          expect(reports, hasLength(2));
          expect(
            reports.every(
              (r) => r.rceptNo == '20250409002838' && r.bsnsYear == 2024,
            ),
            isTrue,
          );
          final sources = await Source.db.find(
            session,
            where: (t) => t.reference.equals('20250409002838'),
          );
          expect(
            sources.every(
              (s) =>
                  s.title.contains('원문 XBRL') &&
                  s.title.contains('SHA256:') &&
                  s.url!.contains('/ifrs.do'),
            ),
            isTrue,
          );
          final digest = PublicFinancialXbrl.digest(
            File('test/fixtures/financial_xbrl/cosnine_20250409002838.zip')
                .readAsBytesSync(),
          );
          expect(
            sources.every((s) => s.title.contains('SHA256:$digest')),
            isTrue,
          );
          final facts = await FinancialFact.db.find(
            session,
            where: (t) => t.accountId.equals('ifrs-full_Assets'),
          );
          expect(
            facts.map((f) => f.amount),
            containsAll([BigInt.from(39024201117), BigInt.from(39283113892)]),
          );
          expect(
            (await DartFiling.db.find(session)).single.attempts,
            mismatchError == 'fresh receiptPeriodMismatch'
                ? 0
                : FinancialFactsSync.maxAttempts,
          );
        },
      );
    }

    for (final (corp, target, original, year, asset) in [
      ('01669226', '20250321001370', '20250110000545', 2024, '1586401656876'),
      ('01688896', '20240118000263', '20240118000098', 2023, '742411662610'),
    ]) {
      test(
        'verified attachment $target stores actual original $original and audits target completion',
        () async {
          final c = (await Company.db.find(session)).single;
          await Company.db.updateRow(
            session,
            c.copyWith(corpCode: corp, fiscalMonth: 10),
          );
          final targetFiling = await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: target,
              corpCode: corp,
              companyId: c.id,
              reportName: '[첨부정정]사업보고서 ($year.10)',
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.failed,
              attempts: 3,
              lastError: 'OFS: API period mismatch; exact-receipt XBRL fallback failed',
              discoveredAt: now,
            ),
          );
          final reader = AttachmentOriginalClient(
            original,
            File('test/fixtures/financial_xbrl/$original.zip')
                .readAsBytesSync(),
          );
          final j = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          await FinancialFactsSync(
            session,
            reader,
            j.id!,
            dailyBudget: 0,
            corpCode: corp,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(reader.linkedCalls, 1);
          final report = (await FinancialReport.db.find(session)).single;
          expect(report.rceptNo, original);
          expect(report.bsnsYear, year);
          expect(report.reportName, '사업보고서 ($year.10)');
          final facts = await FinancialFact.db.find(session);
          expect(
            facts.singleWhere((f) => f.accountId == 'ifrs-full_Assets').amount,
            BigInt.parse(asset),
          );
          final source = (await Source.db.findById(session, report.sourceId))!;
          expect(source.reference, original);
          expect(source.url, contains('rcp_no=$original'));
          final done = (await DartFiling.db.findById(
            session,
            targetFiling.id!,
          ))!;
          expect(done.separateStatus, FilingFetchStatus.stored);
          expect(done.consolidatedStatus, FilingFetchStatus.noData);
          expect(
            done.lastError,
            'verified-attachment-source:$target->$original',
          );
          final audit = (await Source.db.findFirstRow(
            session,
            where: (t) => t.reference.equals(
              'financial-attachment-recovery:$target:separate',
            ),
          ))!;
          expect(jsonDecode(audit.title)['sourceReceipt'], original);
          expect(audit.url, contains('rcpNo=$target'));
          expect(
            (await DartFiling.db.findFirstRow(
              session,
              where: (t) => t.rceptNo.equals(original),
            ))!.separateStatus,
            FilingFetchStatus.stored,
          );
        },
      );
    }
    test('linked original from different actual period never creates reports or a source ledger', () async {
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(session, c.copyWith(corpCode: '01688896'));
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20240118000263',
          corpCode: '01688896',
          companyId: c.id,
          reportName: '[첨부정정]사업보고서 (2023.12)',
          bsnsYear: 2023,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'DartApiException(receiptPeriodMismatch)',
          discoveredAt: now,
        ),
      );
      final reader = AttachmentOriginalClient(
        '20240118000098',
        File('test/fixtures/financial_xbrl/20240118000098.zip')
            .readAsBytesSync(),
      );
      final j = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      await FinancialFactsSync(
        session,
        reader,
        j.id!,
        dailyBudget: 0,
        corpCode: '01688896',
        clock: () => now,
      ).run();
      expect(await FinancialReport.db.count(session), 0);
      expect(await DartFiling.db.count(session), 1);
      expect(
        (await DartFiling.db.find(session)).single.separateStatus,
        FilingFetchStatus.failed,
      );
    });

    test('fresh metadata batch remaining resumes in thirty seconds despite a first transport failure', () async {
      for (var i = 1; i <= 21; i++) {
        final c = await company('9${i.toString().padLeft(7, '0')}');
        await Company.db.updateRow(
          session,
          c.copyWith(stockCode: i.toString().padLeft(6, '0')),
        );
        final original = '20260301${i.toString().padLeft(6, '0')}';
        final target = '20260302${i.toString().padLeft(6, '0')}';
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: target,
            corpCode: c.corpCode,
            companyId: c.id,
            reportName: '사업보고서 (2025.12)',
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.stored,
            discoveredAt: now,
          ),
        );
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            title: 'API source',
            reference: original,
            retrievedAt: now,
          ),
        );
        final report = await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: c.id!,
            rceptNo: original,
            fsDiv: FsDiv.separate,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            reportName: '사업보고서 (2025.12)',
            factCount: 1,
            sourceId: source.id!,
            fetchedAt: now,
          ),
        );
        await FinancialFact.db.insertRow(
          session,
          FinancialFact(
            reportId: report.id!,
            companyId: c.id!,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.separate,
            statement: FinancialStatementKind.balanceSheet,
            accountName: '기존 숫자',
            amount: BigInt.one,
            sourceId: source.id!,
          ),
        );
      }
      final reader = MetadataOnlyClient(failFirst: true);
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      final scheduled = <DateTime>[];
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        clock: () => now,
        callInterval: Duration.zero,
        scheduleResume: (at) async => scheduled.add(at),
      ).run();
      expect(reader.metadataCalls, 20);
      expect(reader.xbrlCalls, 0);
      expect(scheduled, [now.add(const Duration(seconds: 30))]);
      expect(await FinancialReport.db.count(session), 21);
      expect(await FinancialFact.db.count(session), 21);
      expect(
        (await IngestJob.db.findById(session, job.id!))!.message,
        contains('2건 다음 실행 재개'),
      );
    });

    test('stored receipt with only prior facts fails finitely without overwriting numbers or claiming current recovery', () async {
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(session, c.copyWith(stockCode: '000001'));
      final target = await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20260310000001',
          corpCode: c.corpCode,
          companyId: c.id,
          reportName: '사업보고서 (2025.12)',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.stored,
          discoveredAt: now,
        ),
      );
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: 'Old prior-only source',
          reference: target.rceptNo,
          retrievedAt: now,
        ),
      );
      final report = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: c.id!,
          rceptNo: target.rceptNo,
          fsDiv: FsDiv.separate,
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          reportName: target.reportName,
          factCount: 1,
          sourceId: source.id!,
          fetchedAt: now,
        ),
      );
      final fact = await FinancialFact.db.insertRow(
        session,
        FinancialFact(
          reportId: report.id!,
          companyId: c.id!,
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          statement: FinancialStatementKind.balanceSheet,
          accountName: '과거 계정',
          priorAmount: BigInt.from(123),
          sourceId: source.id!,
        ),
      );
      final reader = MetadataOnlyClient();
      for (var i = 0; i < 4; i++) {
        final job = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: FinancialFactsSync.kind,
            status: IngestStatus.running,
            startedAt: now,
          ),
        );
        await FinancialFactsSync(
          session,
          reader,
          job.id!,
          dailyBudget: 0,
          corpCode: c.corpCode,
          clock: () => now,
          callInterval: Duration.zero,
        ).run();
      }
      final ledger = (await DartFiling.db.findById(session, target.id!))!;
      expect(ledger.separateStatus, FilingFetchStatus.failed);
      expect(ledger.attempts, 3);
      expect(ledger.lastError, contains('storedCurrentAmountsMissing'));
      expect(
        ledger.lastError,
        isNot(contains('source-annual-actual-period-gap')),
      );
      final preserved = (await FinancialFact.db.findById(session, fact.id!))!;
      expect(preserved.priorAmount, BigInt.from(123));
      expect(preserved.amount, isNull);
      expect(preserved.cumulativeAmount, isNull);
      expect(preserved.sourceId, source.id);
      expect(await FinancialReport.db.count(session), 1);
      expect(reader.xbrlCalls, 0);
      expect(reader.calls, 0);
    });

    for (final halfYear in [false, true]) {
      for (final transportFailure in [false, true]) {
        test(
          'primary source period anchor half=$halfYear failure=$transportFailure preserves stored full facts without replacement',
          () async {
            final c = (await Company.db.find(session)).single;
            await Company.db.updateRow(
              session,
              c.copyWith(corpCode: '01036446', stockCode: '000001'),
            );
            final target = await DartFiling.db.insertRow(
              session,
              DartFiling(
                rceptNo: '20260319000602',
                corpCode: '01036446',
                companyId: c.id,
                reportName: halfYear ? '반기보고서 (2025.06)' : '사업보고서 (2025.12)',
                bsnsYear: 2025,
                reportCode: halfYear
                    ? FinancialReportCode.halfYear
                    : FinancialReportCode.annual,
                consolidatedStatus: FilingFetchStatus.stored,
                separateStatus: FilingFetchStatus.stored,
                discoveredAt: now,
              ),
            );
            final source = await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartReport,
                title: 'DART full API source',
                reference: '20260318001250',
                retrievedAt: now,
              ),
            );
            final factIds = <int>[];
            for (final div in FsDiv.values) {
              final report = await FinancialReport.db.insertRow(
                session,
                FinancialReport(
                  companyId: c.id!,
                  rceptNo: '20260318001250',
                  fsDiv: div,
                  bsnsYear: 2025,
                  reportCode: halfYear
                      ? FinancialReportCode.halfYear
                      : FinancialReportCode.annual,
                  reportName: halfYear ? '반기보고서 (2025.06)' : '사업보고서 (2025.12)',
                  factCount: 1,
                  sourceId: source.id!,
                  fetchedAt: now,
                ),
              );
              final fact = await FinancialFact.db.insertRow(
                session,
                FinancialFact(
                  reportId: report.id!,
                  companyId: c.id!,
                  bsnsYear: 2025,
                  reportCode: halfYear
                      ? FinancialReportCode.halfYear
                      : FinancialReportCode.annual,
                  fsDiv: div,
                  statement: FinancialStatementKind.balanceSheet,
                  accountName: '기존전체 API계정',
                  amount: BigInt.from(123),
                  sourceId: source.id!,
                ),
              );
              factIds.add(fact.id!);
            }
            final reader = MetadataOnlyClient(
              transportFailure: transportFailure,
            );
            final job = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            final scheduled = <DateTime>[];
            await FinancialFactsSync(
              session,
              reader,
              job.id!,
              dailyBudget: 0,
              corpCode: '01036446',
              clock: () => now,
              callInterval: Duration.zero,
              scheduleResume: (at) async => scheduled.add(at),
            ).run();
            expect(reader.metadataCalls, 1);
            expect(reader.xbrlCalls, 0);
            expect(reader.calls, 0);
            expect(await FinancialReport.db.count(session), 2);
            for (final id in factIds) {
              final f = (await FinancialFact.db.findById(session, id))!;
              expect(f.amount, BigInt.from(123));
              expect(f.sourceId, source.id);
              expect(f.supersededById, isNull);
            }
            final anchor = await DartFiling.db.find(
              session,
              where: (t) => t.rceptNo.equals('20260318001250'),
            );
            expect(anchor, transportFailure ? isEmpty : hasLength(1));
            expect(
              (await DartFiling.db.findById(
                session,
                target.id!,
              ))!.separateStatus,
              FilingFetchStatus.stored,
            );
            final flags = await session.db.unsafeQuery(
              'WITH ${FinancialCollectionScope.cte} SELECT consolidated_period_stored,separate_period_stored FROM financial_scope WHERE id=@id',
              parameters: QueryParameters.named({'id': target.id}),
            );
            expect(flags.single, [!transportFailure, !transportFailure]);
            if (transportFailure) {
              expect(scheduled, contains(now.add(const Duration(minutes: 15))));
            } else {
              final audit = await Source.db.find(
                session,
                where: (t) => t.reference.equals(
                  'financial-source-period-anchor:20260318001250:20260319000602',
                ),
              );
              expect(audit, hasLength(1));
              expect(audit.single.title, contains('전체 금액 재검증 없음'));
            }
          },
        );
      }
    }
    test('stored annual ledger with another actual month recovers only missing basis without API or changing old facts', () async {
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(
        session,
        c.copyWith(corpCode: '01885222', fiscalMonth: 5, stockCode: '000001'),
      );
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: 'existing October report',
          reference: '20251111000001',
          retrievedAt: now,
        ),
      );
      final old = await FinancialReport.db.insertRow(
        session,
        FinancialReport(
          companyId: c.id!,
          rceptNo: '20251111000001',
          fsDiv: FsDiv.separate,
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          reportName: '사업보고서 (2025.10)',
          factCount: 1,
          sourceId: source.id!,
          fetchedAt: now,
        ),
      );
      final oldFact = await FinancialFact.db.insertRow(
        session,
        FinancialFact(
          reportId: old.id!,
          companyId: c.id!,
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          statement: FinancialStatementKind.balanceSheet,
          accountId: 'ifrs-full_Assets',
          accountName: '자산총계',
          amount: BigInt.from(123),
          currency: 'KRW',
          sourceId: source.id!,
        ),
      );
      final target = await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20250811000434',
          corpCode: '01885222',
          companyId: c.id,
          reportName: '사업보고서 (2025.05)',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.noData,
          separateStatus: FilingFetchStatus.stored,
          discoveredAt: now,
        ),
      );
      final reader = ExactPublicOriginalClient(
        '20250811000434',
        File('test/fixtures/financial_xbrl/daishin_value_20250811000434.zip')
            .readAsBytesSync(),
      );
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      await FinancialFactsSync(
        session,
        reader,
        job.id!,
        dailyBudget: 0,
        corpCode: '01885222',
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      final updated = (await DartFiling.db.findById(session, target.id!))!;
      expect(updated.consolidatedStatus, FilingFetchStatus.noData);
      expect(updated.separateStatus, FilingFetchStatus.stored);
      final reports = await FinancialReport.db.find(session);
      expect(reports, hasLength(2));
      final recovered = reports.singleWhere((r) => r.rceptNo == target.rceptNo);
      expect(recovered.reportName, '사업보고서 (2025.05)');
      expect(recovered.fsDiv, FsDiv.separate);
      expect(recovered.factCount, 6);
      final preserved = (await FinancialFact.db.findById(
        session,
        oldFact.id!,
      ))!;
      expect(preserved.amount, BigInt.from(123));
      expect(preserved.sourceId, source.id);
      expect(preserved.supersededById, isNull);
      expect(
        (await FinancialReport.db.findById(session, old.id!))!.supersededById,
        isNull,
      );
      expect(reader.calls, 0);
      final scope = await session.db.unsafeQuery(
        'WITH ${FinancialCollectionScope.cte} SELECT separate_period_stored FROM financial_scope WHERE id=@id',
        parameters: QueryParameters.named({'id': target.id}),
      );
      expect(scope.single.single, true);
    });

    test('declared original partial OFS core explicitly records missing whole profit loss while CFS remains full core', () async {
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(
        session,
        c.copyWith(corpCode: '01885222', fiscalMonth: 5),
      );
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20250811000434',
          corpCode: '01885222',
          companyId: c.id,
          reportName: '사업보고서 (2025.05)',
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'DartApiException(receiptPeriodMismatch)',
          discoveredAt: now,
        ),
      );
      final reader = ExactPublicOriginalClient(
        '20250811000434',
        File('test/fixtures/financial_xbrl/daishin_value_20250811000434.zip')
            .readAsBytesSync(),
      );
      final j = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      await FinancialFactsSync(
        session,
        reader,
        j.id!,
        dailyBudget: 0,
        corpCode: '01885222',
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      final reports = await FinancialReport.db.find(session);
      expect(reports, hasLength(2));
      for (final report in reports) {
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
        );
        final source = (await Source.db.findById(session, report.sourceId))!;
        expect(source.reference, '20250811000434');
        if (report.fsDiv == FsDiv.separate) {
          expect(facts, hasLength(6));
          expect(
            facts.any((f) => f.accountId == 'ifrs-full_ProfitLoss'),
            isFalse,
          );
          expect(source.title, contains('부분 핵심계정'));
          expect(source.title, contains('당기순손익 미확보'));
          expect(source.title, contains('순손익 wholecontext 미확보'));
        } else {
          expect(facts, hasLength(7));
          expect(
            facts.any((f) => f.accountId == 'ifrs-full_ProfitLoss'),
            isTrue,
          );
          expect(source.title, isNot(contains('부분 핵심계정')));
        }
      }
      expect(
        (await IngestJob.db.findById(session, j.id!))!.message,
        contains('전체 재무제표 아님'),
      );
    });

    test('verified missing-XBRL attachment HTML stores actual original printed account labels without invented IDs', () async {
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(
        session,
        c.copyWith(corpCode: '00677334', name: '(주)아하', fiscalMonth: 3),
      );
      final target = await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20240702000525',
          corpCode: '00677334',
          companyId: c.id,
          reportName: '[첨부정정]사업보고서 (2024.03)',
          bsnsYear: 2024,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'DartApiException(receiptPeriodMismatch)',
          discoveredAt: now,
        ),
      );
      final reader = AttachmentHtmlClient();
      final j = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: FinancialFactsSync.kind,
          status: IngestStatus.running,
          startedAt: now,
        ),
      );
      await FinancialFactsSync(
        session,
        reader,
        j.id!,
        dailyBudget: 0,
        corpCode: '00677334',
        clock: () => now,
        callInterval: Duration.zero,
      ).run();
      expect(reader.htmlCalls, 2);
      final reports = await FinancialReport.db.find(session);
      expect(reports, hasLength(2));
      for (final report in reports) {
        expect(report.rceptNo, '20240701000635');
        final facts = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(report.id!),
          orderBy: (t) => t.ord,
        );
        expect(facts, hasLength(7));
        expect(facts.every((f) => f.accountId == null), isTrue);
        expect(facts.every((f) => f.accountName.isNotEmpty), isTrue);
        final expected = report.fsDiv == FsDiv.consolidated
            ? [
                '101131149053',
                '62690969504',
                '38440179549',
                '78305621279',
                '3006702112',
                '1327808656',
                '-7911425271',
              ]
            : [
                '101309722186',
                '62043404550',
                '39266317636',
                '77432069841',
                '3025665889',
                '1934425181',
                '-8609316999',
              ];
        expect(facts.map((f) => f.amount.toString()), expected);
        final source = (await Source.db.findById(session, report.sourceId))!;
        expect(source.reference, '20240701000635');
        expect(source.url, contains('rcpNo=20240701000635'));
        expect(source.title, contains('HTML 부분 핵심계정'));
        expect(source.title, contains('XBRL 계정 ID 미제공'));
        expect(source.title, isNot(contains('XBRL 핵심계정')));
        final basis = report.fsDiv == FsDiv.consolidated ? 'cfs' : 'ofs';
        final cover = File(
          'test/fixtures/financial_html/20240701000635-cover.html',
        ).readAsStringSync();
        final statement = File(
          'test/fixtures/financial_html/20240701000635-$basis.html',
        ).readAsStringSync();
        final rawDigest = PublicFinancialXbrl.digest(
          utf8.encode('$cover\n$statement'),
        );
        expect(source.title, contains('SHA256:$rawDigest'));

        final audit = (await Source.db.findFirstRow(
          session,
          where: (t) => t.reference.equals(
            'financial-attachment-recovery:20240702000525:${report.fsDiv.name}',
          ),
        ))!;
        expect(jsonDecode(audit.title)['originalFormat'], 'html');
        expect(jsonDecode(audit.title)['originalSource'], source.url);
        expect(
          jsonDecode(audit.title)['coverSource'],
          contains('rcpNo=20240701000635'),
        );
        expect(jsonDecode(audit.title)['originalSha256'], rawDigest);
      }
      final done = (await DartFiling.db.findById(session, target.id!))!;
      expect(done.consolidatedStatus, FilingFetchStatus.stored);
      expect(done.separateStatus, FilingFetchStatus.stored);
      final job = (await IngestJob.db.findById(session, j.id!))!;
      expect(job.message, contains('HTML 부분 핵심계정 복구 2벌'));
      expect(job.message, isNot(contains('XBRL 핵심계정 복구')));
    });
    test(
      'ordinary correction cannot use attachment-only HTML fallback',
      () async {
        final c = (await Company.db.find(session)).single;
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: '20240702000525',
            corpCode: c.corpCode,
            companyId: c.id,
            reportName: '[기재정정]사업보고서 (2024.03)',
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.failed,
            attempts: 3,
            lastError: 'DartApiException(receiptPeriodMismatch)',
            discoveredAt: now,
          ),
        );
        final reader = AttachmentHtmlClient();
        final j = await IngestJob.db.insertRow(
          session,
          IngestJob(
            kind: FinancialFactsSync.kind,
            status: IngestStatus.running,
            startedAt: now,
          ),
        );
        await FinancialFactsSync(
          session,
          reader,
          j.id!,
          dailyBudget: 0,
          corpCode: c.corpCode,
          clock: () => now,
          callInterval: Duration.zero,
        ).run();
        expect(reader.htmlCalls, 0);
        expect(await FinancialReport.db.count(session), 0);
      },
    );

    for (final (corp, target, original, year, oldMonth, count) in [
      ('01669226', '20250321001370', '20250110000545', 2024, 4, 86),
      ('01688896', '20240118000263', '20240118000098', 2023, 1, 72),
    ]) {
      for (final failure in ['none', 'coreAmount', 'correctionLink']) {
        test(
          'exact original period-name repair $corp $failure preserves all facts and source IDs',
          () async {
            final c = (await Company.db.find(session)).single;
            await Company.db.updateRow(
              session,
              c.copyWith(corpCode: corp, fiscalMonth: oldMonth),
            );
            final targetFiling = await DartFiling.db.insertRow(
              session,
              DartFiling(
                rceptNo: target,
                corpCode: corp,
                companyId: c.id,
                reportName: '[첨부정정]사업보고서 ($year.10)',
                bsnsYear: year,
                reportCode: FinancialReportCode.annual,
                consolidatedStatus: FilingFetchStatus.noData,
                separateStatus: FilingFetchStatus.failed,
                attempts: 3,
                lastError: 'DartApiException(receiptPeriodMismatch)',
                discoveredAt: now,
              ),
            );
            final zip = File('test/fixtures/financial_xbrl/$original.zip')
                .readAsBytesSync();
            final rows = PublicFinancialXbrl.parse(
              zip,
              receipt: original,
              corpCode: corp,
              bsnsYear: year,
              periodEnd: DateTime.utc(year, 10, 31),
              consolidated: false,
            );
            final oldName =
                '사업보고서 ($year.${oldMonth.toString().padLeft(2, '0')})';
            final source = await Source.db.insertRow(
              session,
              Source(
                kind: SourceKind.dartReport,
                reference: original,
                title: 'DART 전체 재무제표 (fnlttSinglAcntAll) · $oldName · 별도',
                url: DartClient.financialApiUrl(
                  corp,
                  year,
                  '11011',
                  'OFS',
                ).toString(),
                retrievedAt: now,
              ),
            );
            final report = await FinancialReport.db.insertRow(
              session,
              FinancialReport(
                companyId: c.id!,
                rceptNo: original,
                bsnsYear: year,
                reportCode: FinancialReportCode.annual,
                fsDiv: FsDiv.separate,
                reportName: oldName,
                sourceId: source.id!,
                factCount: count,
                invalidAmountCount: 0,
                fetchedAt: now,
              ),
            );
            final converted = FinancialRows.toFacts(
              rows,
              reportId: report.id!,
              companyId: c.id!,
              bsnsYear: year,
              reportCode: FinancialReportCode.annual,
              fsDiv: FsDiv.separate,
              sourceId: source.id!,
            );
            for (final f in converted.facts) {
              await FinancialFact.db.insertRow(
                session,
                f.copyWith(
                  amount:
                      failure == 'coreAmount' &&
                          f.accountId == 'ifrs-full_Assets'
                      ? f.amount! + BigInt.one
                      : f.amount,
                  priorAmount: BigInt.from(11),
                  beforePriorAmount: BigInt.from(22),
                ),
              );
            }
            for (var i = 7; i < count; i++) {
              await FinancialFact.db.insertRow(
                session,
                FinancialFact(
                  reportId: report.id!,
                  companyId: c.id!,
                  bsnsYear: year,
                  reportCode: FinancialReportCode.annual,
                  fsDiv: FsDiv.separate,
                  statement: FinancialStatementKind.balanceSheet,
                  accountId: 'dart_Extra_$i',
                  accountName: '추가계정 $i',
                  amount: BigInt.from(i),
                  priorAmount: BigInt.from(i + 1),
                  beforePriorAmount: BigInt.from(i + 2),
                  currency: 'KRW',
                  sourceId: source.id!,
                ),
              );
            }
            if (failure == 'correctionLink') {
              final linked = await FinancialReport.db.insertRow(
                session,
                FinancialReport(
                  companyId: c.id!,
                  rceptNo: '${year}01010000001',
                  bsnsYear: year,
                  reportCode: FinancialReportCode.annual,
                  fsDiv: FsDiv.separate,
                  reportName: oldName,
                  sourceId: source.id!,
                  factCount: 0,
                  invalidAmountCount: 0,
                  fetchedAt: now,
                  supersededById: report.id,
                ),
              );
              expect(linked.supersededById, report.id);
            }
            final beforeFacts = (await FinancialFact.db.find(
              session,
              where: (t) => t.reportId.equals(report.id!),
              orderBy: (t) => t.id,
            )).map((f) => f.toJson()).toList();
            final reader = AttachmentOriginalClient(original, zip);
            final j = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            await FinancialFactsSync(
              session,
              reader,
              j.id!,
              dailyBudget: 0,
              corpCode: corp,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            final after = (await FinancialReport.db.findById(
              session,
              report.id!,
            ))!;
            expect(
              after.reportName,
              failure == 'none' ? '사업보고서 ($year.10)' : oldName,
            );
            expect(after.sourceId, source.id);
            expect(after.bsnsYear, year);
            expect(
              (await Source.db.findById(session, source.id!))!.toJson(),
              source.toJson(),
            );
            expect(
              (await FinancialFact.db.find(
                session,
                where: (t) => t.reportId.equals(report.id!),
                orderBy: (t) => t.id,
              )).map((f) => f.toJson()).toList(),
              beforeFacts,
            );
            final audit = await Source.db.findFirstRow(
              session,
              where: (t) => t.reference.equals(
                'financial-report-period-name-repair:${report.id}',
              ),
            );
            final done = (await DartFiling.db.findById(
              session,
              targetFiling.id!,
            ))!;
            if (failure == 'none') {
              expect(audit, isNotNull);
              final detail = jsonDecode(audit!.title);
              expect(detail['oldReportName'], oldName);
              expect(detail['verifiedCurrentCore'], hasLength(7));
              expect(detail['unchangedFacts'], count);
              expect(detail['auditNote'], contains('전체 계정·비교기간 값 재검증 아님'));
              expect(done.separateStatus, FilingFetchStatus.stored);
              expect(
                (await IngestJob.db.findById(session, j.id!))!.message,
                contains('보고기간 명칭 복구 1벌'),
              );
            } else {
              expect(audit, isNull);
              expect(done.separateStatus, FilingFetchStatus.failed);
            }
          },
        );
      }
    }

    for (final fail in [false, true]) {
      test(
        'latest source-reviewed half HTML $fail preserves separate quarter and cumulative amounts without requeuing ordinary noData',
        () async {
          final c = (await Company.db.find(session)).single;
          await Company.db.updateRow(
            session,
            c.copyWith(corpCode: '00337296', name: '(주)원포유', fiscalMonth: 12),
          );
          final target = await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: '20260814002145',
              corpCode: '00337296',
              companyId: c.id,
              reportName: '반기보고서 (2026.06)',
              bsnsYear: 2026,
              reportCode: FinancialReportCode.halfYear,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.noData,
              discoveredAt: now,
            ),
          );
          final other = await Company.db.insertRow(
            session,
            Company(
              corpCode: '00999999',
              name: 'API 노데이터 회사',
              stockCode: '999999',
              market: Market.kosdaq,
              fiscalMonth: 12,
            ),
          );
          final untouched = await DartFiling.db.insertRow(
            session,
            DartFiling(
              rceptNo: '20260814002146',
              corpCode: other.corpCode,
              companyId: other.id,
              reportName: '반기보고서 (2026.06)',
              bsnsYear: 2026,
              reportCode: FinancialReportCode.halfYear,
              consolidatedStatus: FilingFetchStatus.noData,
              separateStatus: FilingFetchStatus.noData,
              discoveredAt: now,
            ),
          );
          final reader = HalfYearHtmlClient(wrongReceipt: fail);
          final j = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          await FinancialFactsSync(
            session,
            reader,
            j.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
          ).run();
          expect(reader.halfCalls, 1);
          final done = (await DartFiling.db.findById(session, target.id!))!;
          expect(done.consolidatedStatus, FilingFetchStatus.noData);
          final ordinary = (await DartFiling.db.findById(
            session,
            untouched.id!,
          ))!;
          expect(ordinary.separateStatus, FilingFetchStatus.noData);
          expect(ordinary.lastError, isNull);
          if (fail) {
            expect(done.separateStatus, FilingFetchStatus.failed);
            expect(done.attempts, 1);
            expect(await FinancialReport.db.count(session), 0);
          } else {
            expect(done.separateStatus, FilingFetchStatus.stored);
            final report = (await FinancialReport.db.find(session)).single;
            expect(report.fsDiv, FsDiv.separate);
            expect(report.reportCode, FinancialReportCode.halfYear);
            expect(report.rceptNo, '20260814002145');
            final facts = await FinancialFact.db.find(session);
            expect(facts, hasLength(8));
            expect(facts.every((f) => f.accountId == null), isTrue);
            FinancialFact fact(String label) => facts.singleWhere(
              (f) => f.accountName.replaceAll(RegExp(r'\s+'), '') == label,
            );
            expect(fact('매출액').amount, BigInt.from(2095889269));
            expect(fact('매출액').cumulativeAmount, BigInt.from(6919979049));
            expect(fact('영업이익').amount, BigInt.from(148858512));
            expect(fact('영업이익').cumulativeAmount, BigInt.from(380535800));
            expect(fact('반기순이익').amount, BigInt.from(417050487));
            expect(fact('반기순이익').cumulativeAmount, BigInt.from(672321812));
            expect(fact('영업활동으로인한현금흐름').amount, BigInt.from(840691078));
            expect(fact('자산총계').amount, BigInt.from(53813466290));
            final source = (await Source.db.findById(
              session,
              report.sourceId,
            ))!;
            expect(source.title, contains('HTML 부분 핵심계정'));
            expect(source.reference, '20260814002145');
            final audit = (await Source.db.findFirstRow(
              session,
              where: (t) => t.reference.equals(
                'financial-half-html-recovery:20260814002145:separate',
              ),
            ))!;
            expect(jsonDecode(audit.title)['note'], contains('3개월'));
            expect(
              (await IngestJob.db.findById(session, j.id!))!.message,
              contains('HTML 부분 핵심계정 복구 1벌'),
            );
          }
        },
      );
    }

    Future<void> seedNonDecember({
      bool oldReceipt = false,
      bool noRows = false,
      bool corruptStored = false,
    }) async {
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(session, c.copyWith(fiscalMonth: 3));
      dart.filings.clear();
      for (final (receipt, year, date) in [
        ('20250813000001', 2026, DateTime.utc(2025, 8, 13)),
        ('20260813000001', 2027, DateTime.utc(2026, 8, 13)),
      ]) {
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: receipt,
            corpCode: c.corpCode,
            companyId: c.id,
            reportName: '분기보고서 (${year - 1}.06)',
            receivedDate: date,
            bsnsYear: year,
            reportCode: FinancialReportCode.q1,
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.noData,
            discoveredAt: now,
          ),
        );
      }
      if (!noRows) {
        for (final fs in ['CFS', 'OFS']) {
          dart.setRows(c.corpCode, 2026, '11013', fs, [
            {
              ...row(
                oldReceipt ? '20250813000001' : '20260813000001',
                'BS',
                'ifrs-full_Assets',
                '자산총계',
                '94135633463',
              ),
              'bsns_year': '2026',
              'corp_code': c.corpCode,
              'reprt_code': '11013',
            },
          ]);
        }
      }
      if (corruptStored) {
        final source = await Source.db.insertRow(
          session,
          Source(
            kind: SourceKind.dartReport,
            title: 'old misassigned report',
            reference: '20260813000001',
            retrievedAt: now,
          ),
        );
        await FinancialReport.db.insertRow(
          session,
          FinancialReport(
            companyId: c.id!,
            rceptNo: '20260813000001',
            fsDiv: FsDiv.consolidated,
            bsnsYear: 2026,
            reportCode: FinancialReportCode.q1,
            reportName: '분기보고서 (2026.06)',
            factCount: 0,
            sourceId: source.id!,
            fetchedAt: now,
          ),
        );
      }
    }

    test('nonDecember latest noData uses actual API calendar year with reserve and canonical storage', () async {
      await seedNonDecember();
      final job = await runSync(corpCode: '00000001', dailyBudget: 0);
      expect(job.status, IngestStatus.succeeded);
      expect(
        dart.financialCalls,
        containsAll(['00000001|2026|11013|CFS', '00000001|2026|11013|OFS']),
      );
      expect(dart.financialCalls.any((k) => k.contains('|2027|')), isFalse);
      final reports = await FinancialReport.db.find(session);
      expect(reports, hasLength(2));
      expect(
        reports.every(
          (r) => r.bsnsYear == 2027 && r.rceptNo == '20260813000001',
        ),
        isTrue,
      );
      final historical = (await DartFiling.db.find(
        session,
        where: (t) => t.rceptNo.equals('20250813000001'),
      )).single;
      expect(historical.consolidatedStatus, FilingFetchStatus.noData);
      expect(historical.lastError, isNull);
      expect(job.message, contains('조회연도 보완 2호출'));
    });
    test('old API receipt cannot be mapped into next fiscal year', () async {
      await seedNonDecember(oldReceipt: true);
      await runSync(corpCode: '00000001', dailyBudget: 0);
      expect(await FinancialReport.db.count(session), 0);
      final latest = (await DartFiling.db.find(
        session,
        where: (t) => t.rceptNo.equals('20260813000001'),
      )).single;
      expect(latest.consolidatedStatus, FilingFetchStatus.failed);
      expect(latest.lastError, contains('receiptPeriodMismatch'));
    });
    test('actual 013 after oneoff calendar-year retry stays noData without infinite requeue', () async {
      await seedNonDecember(noRows: true);
      await runSync(corpCode: '00000001', dailyBudget: 0);
      expect(dart.financialCalls, hasLength(2));
      dart.financialCalls.clear();
      await runSync(corpCode: '00000001', dailyBudget: 0);
      expect(dart.financialCalls, isEmpty);
      expect(await FinancialReport.db.count(session), 0);
    });
    test('same receipt corrupted stored canonical period is failed without rewriting reports', () async {
      await seedNonDecember(corruptStored: true);
      await runSync(corpCode: '00000001', dailyBudget: 0);
      final latest = (await DartFiling.db.find(
        session,
        where: (t) => t.rceptNo.equals('20260813000001'),
      )).single;
      expect(latest.consolidatedStatus, FilingFetchStatus.failed);
      expect(latest.lastError, contains('storedPeriodMismatch'));
      final report = (await FinancialReport.db.find(
        session,
        where: (t) => t.fsDiv.equals(FsDiv.consolidated),
      )).single;
      expect(report.bsnsYear, 2026);
    });
    test('shared hardcap blocks calendar repair even when dedicated reserve exists', () async {
      await seedNonDecember();
      await ApiCallUsage.db.insertRow(
        session,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-09-17',
          calls: 20000,
        ),
      );
      await runSync(corpCode: '00000001', dailyBudget: 0);
      expect(dart.financialCalls, isEmpty);
      expect(await FinancialReport.db.count(session), 0);
    });
    test('one remaining shared call permits only one repair basis', () async {
      await seedNonDecember();
      await ApiCallUsage.db.insertRow(
        session,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-09-17',
          calls: 19999,
        ),
      );
      await runSync(corpCode: '00000001', dailyBudget: 0);
      expect(dart.financialCalls, hasLength(1));
      expect(await FinancialReport.db.count(session), 1);
    });

    test('fresh exact-period values repair wrong canonical year without changing amounts or source', () async {
      await seedNonDecember(corruptStored: true);
      final existing = (await FinancialReport.db.find(session)).single;
      final fresh =
          jsonDecode(dart.statements['00000001|2026|11013|CFS']!)['list']
              as List<dynamic>;
      final converted = FinancialRows.toFacts(
        fresh.cast<Map<String, dynamic>>(),
        reportId: existing.id!,
        companyId: existing.companyId,
        bsnsYear: 2026,
        reportCode: FinancialReportCode.q1,
        fsDiv: FsDiv.consolidated,
        sourceId: existing.sourceId,
      );
      await FinancialFact.db.insert(session, converted.facts);
      await FinancialReport.db.updateRow(
        session,
        existing.copyWith(factCount: converted.facts.length),
      );
      final before = (await FinancialFact.db.find(session)).single;
      final job = await runSync(corpCode: '00000001', dailyBudget: 0);
      final report = (await FinancialReport.db.findById(
        session,
        existing.id!,
      ))!;
      final fact = (await FinancialFact.db.findById(session, before.id!))!;
      expect(report.bsnsYear, 2027);
      expect(fact.bsnsYear, 2027);
      expect(fact.amount, before.amount);
      expect(fact.sourceId, before.sourceId);
      expect(report.sourceId, existing.sourceId);
      expect(job.message, contains('메타데이터 복구 1벌'));
    });

    test('repair reserve caps at forty calls and leaves other latest filings pending', () async {
      dart.filings.clear();
      for (var i = 0; i < 21; i++) {
        final code = '${10000000 + i}';
        final c = await company(code, fiscalMonth: 3);
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: '20260813${i.toString().padLeft(6, '0')}',
            corpCode: code,
            companyId: c.id,
            reportName: '분기보고서 (2026.06)',
            receivedDate: DateTime.utc(2026, 8, 13),
            bsnsYear: 2027,
            reportCode: FinancialReportCode.q1,
            consolidatedStatus: FilingFetchStatus.noData,
            separateStatus: FilingFetchStatus.noData,
            discoveredAt: now,
          ),
        );
      }
      await runSync(dailyBudget: 0);
      expect(
        dart.financialCalls,
        hasLength(FinancialFactsSync.calendarYearRepairReserve),
      );
      expect(
        await DartFiling.db.count(
          session,
          where: (t) => t.consolidatedStatus.equals(FilingFetchStatus.pending),
        ),
        1,
      );
      expect(await FinancialReport.db.count(session), 0);
    });

    test('zero API allowance continues through multiple verified annual public recoveries', () async {
      dart.filings.clear();
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(session, c.copyWith(corpCode: '00442455'));
      final second = await company('00442456');
      final original = File(
        'test/fixtures/financial_xbrl/cosnine_20250409002838.zip',
      ).readAsBytesSync();
      final instance = ZipDecoder()
          .decodeBytes(original)
          .files
          .singleWhere((f) => f.name.endsWith('.xbrl'));
      dart.publicOriginals['20250409002839'] = ZipEncoder().encodeBytes(
        Archive()..addFile(
          ArchiveFile.bytes(
            instance.name,
            utf8.encode(
              utf8.decode(instance.content).replaceAll('00442455', '00442456'),
            ),
          ),
        ),
      );
      for (final (corp, id, receipt) in [
        ('00442455', c.id!, '20250409002838'),
        ('00442456', second.id!, '20250409002839'),
      ]) {
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: receipt,
            corpCode: corp,
            companyId: id,
            reportName: '사업보고서 (2024.12)',
            receivedDate: DateTime.utc(2025, 4, 9),
            bsnsYear: 2024,
            reportCode: FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.failed,
            separateStatus: FilingFetchStatus.failed,
            attempts: 3,
            lastError: 'DartApiException(mismatch)',
            discoveredAt: now,
          ),
        );
      }
      dart.publicXbrl = true;
      final job = await runSync(dailyBudget: 0);
      expect(dart.financialCalls, isEmpty);
      expect(await FinancialReport.db.count(session), 4);
      expect(job.message, contains('핵심계정 복구 4벌'));
    });

    Future<void> recoveryBudgetFixture(int used, {bool recover = true}) async {
      dart.filings.clear();
      final c = (await Company.db.find(session)).single;
      await ApiCallUsage.db.insertRow(
        session,
        ApiCallUsage(
          provider: ApiProvider.dart,
          day: '2026-09-17',
          calls: used,
        ),
      );
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20260901000001',
          corpCode: c.corpCode,
          companyId: c.id,
          reportName: '사업보고서 (2025.06)',
          bsnsYear: recover ? null : 2025,
          reportCode: recover ? null : FinancialReportCode.annual,
          consolidatedStatus: recover
              ? FilingFetchStatus.unsupported
              : FilingFetchStatus.pending,
          separateStatus: recover
              ? FilingFetchStatus.unsupported
              : FilingFetchStatus.pending,
          discoveredAt: now,
        ),
      );
      dart.setRows(c.corpCode, 2025, '11011', 'CFS', [
        row('20260901000001', 'BS', 'ifrs-full_Assets', '자산총계', '123'),
      ]);
    }

    test('default annual ledger recovery uses residual calls above 19000 only for reclassified source', () async {
      await recoveryBudgetFixture(19000);
      final job = await runSync(dailyBudget: null);
      expect(await FinancialReport.db.count(session), 1);
      expect(dart.financialCalls, hasLength(2));
      expect(job.updated, 1);
    });
    test('ordinary default financial target still waits at 19000', () async {
      await recoveryBudgetFixture(19000, recover: false);
      await runSync(dailyBudget: null);
      expect(dart.financialCalls, isEmpty);
      expect(resumes, hasLength(1));
    });
    test(
      'explicit zero remains a hard block for reclassified annual API recovery',
      () async {
        await recoveryBudgetFixture(19000);
        await runSync(dailyBudget: 0);
        expect(dart.financialCalls, isEmpty);
        expect(await FinancialReport.db.count(session), 0);
      },
    );
    test('annual recovery stops at 19900 and schedules next day with unconsumed basis', () async {
      // One feed call plus one CFS call must consume the final two slots.
      await recoveryBudgetFixture(19898);
      final job = await runSync(dailyBudget: null);
      expect(dart.financialCalls, hasLength(1));
      expect(
        (await DartFiling.db.find(session)).single.separateStatus,
        FilingFetchStatus.pending,
      );
      expect(job.message, contains('19900건'));
      expect(resumes, hasLength(1));
    });
    test('현재마스터와 다른 과거annual unsupported 원장을 재분류하되 과거quarter는 보존한다', () async {
      final c = (await Company.db.find(session)).single;
      dart.filings.clear();
      final raw = await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20240901000001',
          corpCode: c.corpCode,
          companyId: c.id,
          reportName: '사업보고서 (2024.06)',
          consolidatedStatus: FilingFetchStatus.unsupported,
          separateStatus: FilingFetchStatus.unsupported,
          discoveredAt: now,
        ),
      );
      final historical = await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20240901000002',
          corpCode: c.corpCode,
          companyId: c.id,
          reportName: '분기보고서 (2024.06)',
          consolidatedStatus: FilingFetchStatus.unsupported,
          separateStatus: FilingFetchStatus.unsupported,
          discoveredAt: now,
        ),
      );
      dart.setRows(c.corpCode, 2024, '11011', 'CFS', [
        row(raw.rceptNo, 'BS', 'ifrs-full_Assets', '자산총계', '123')
          ..['bsns_year'] = '2024'
          ..['corp_code'] = c.corpCode,
      ]);
      await runSync(corpCode: c.corpCode);
      final recovered = (await DartFiling.db.findById(session, raw.id!))!;
      expect(recovered.reportCode, FinancialReportCode.annual);
      expect(recovered.bsnsYear, 2024);
      expect(recovered.consolidatedStatus, FilingFetchStatus.stored);
      final untouched = (await DartFiling.db.findById(
        session,
        historical.id!,
      ))!;
      expect(untouched.reportCode, isNull);
      expect(untouched.bsnsYear, isNull);
      expect(untouched.consolidatedStatus, FilingFetchStatus.unsupported);
      final report = (await FinancialReport.db.find(session)).single;
      expect(report.rceptNo, raw.rceptNo);
      expect(report.bsnsYear, 2024);
      final source = (await Source.db.findById(session, report.sourceId))!;
      expect(source.reference, raw.rceptNo);
    });

    test('SQL scope and fetch scope both retain distinct annual March/September and latest period correction', () async {
      final c = (await Company.db.find(session)).single;
      await Company.db.updateRow(session, c.copyWith(stockCode: '000001'));
      dart.filings.clear();
      for (final (id, name, year, receipt) in [
        (1, '사업보고서 (2020.03)', 2020, '20200501000001'),
        (2, '사업보고서 (2025.03)', 2025, '20250501000001'),
        (3, '사업보고서 (2025.09)', 2025, '20251101000001'),
        (4, '[기재정정]사업보고서 (2025.03)', 2025, '20260101000001'),
        (5, '분기보고서 (2025.06)', 2025, '20250801000001'),
      ]) {
        await DartFiling.db.insertRow(
          session,
          DartFiling(
            rceptNo: receipt,
            corpCode: c.corpCode,
            companyId: c.id,
            reportName: name,
            bsnsYear: year,
            reportCode: id == 5
                ? FinancialReportCode.q3
                : FinancialReportCode.annual,
            consolidatedStatus: FilingFetchStatus.pending,
            separateStatus: FilingFetchStatus.pending,
            discoveredAt: now,
          ),
        );
      }
      final all = await DartFiling.db.find(session);
      final ids = FinancialFactsSync.financialScopeIds(all);
      final sql = await session.db.unsafeQuery(
        'WITH ${FinancialCollectionScope.cte} SELECT id FROM financial_scope',
      );
      expect(sql.map((r) => r[0]).toSet(), ids);
      expect(ids, {
        all.singleWhere((f) => f.rceptNo == '20251101000001').id!,
        all.singleWhere((f) => f.rceptNo == '20260101000001').id!,
      });
    });

    test('종목코드가 있는 기타시장 기업도 동일 재무 범위로 수집한다', () async {
      final original = (await Company.db.find(session)).single;
      await Company.db.updateRow(
        session,
        original.copyWith(market: Market.other, stockCode: '000001'),
      );
      final job = await runSync(corpCode: '00000001');
      expect(job.status, IngestStatus.succeeded);
      expect(dart.financialCalls, isNotEmpty);
      expect(
        (await DartFiling.db.find(session)).single.consolidatedStatus,
        FilingFetchStatus.stored,
      );
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

      final exhausted = await runSync();
      expect(exhausted.status, IngestStatus.failed);
      expect(exhausted.message, contains('남은 공시 1건'));
      expect(exhausted.message, contains('재시도 한도'));
      expect(
        (await DartFiling.db.find(session)).single.attempts,
        FinancialFactsSync.maxAttempts,
      );
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

    test('재무제표가 안 바뀐 정정(첨부추가)은 검증된 동일기간 이전 접수번호로 저장한다', () async {
      final c = (await Company.db.find(session)).single;
      await DartFiling.db.insertRow(
        session,
        DartFiling(
          rceptNo: '20260310000001',
          corpCode: c.corpCode,
          companyId: c.id,
          reportName: '사업보고서 (2025.12)',
          receivedDate: DateTime.utc(2026, 3, 10),
          bsnsYear: 2025,
          reportCode: FinancialReportCode.annual,
          consolidatedStatus: FilingFetchStatus.pending,
          separateStatus: FilingFetchStatus.pending,
          discoveredAt: now,
        ),
      );
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
        (await DartFiling.db.find(
          session,
          where: (t) => t.rceptNo.equals('20260320000009'),
        )).single.consolidatedStatus,
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

    test('공시를 발견하기 전 예산이 소진돼도 다음 날 검색을 재개한다', () async {
      await runSync(dailyBudget: 0);
      expect(resumes, [DateTime.utc(2026, 9, 17, 15, 10)]);
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
