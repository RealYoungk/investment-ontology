import 'dart:async';
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
///
/// 실제 `fnlttSinglAcntAll`은 접수번호를 받지 않고 회사·사업연도·보고서 코드·구분만
/// 받아 그 조합의 "현재" 재무제표를 돌려주므로, 응답 내용은 [setRows]를 다시 부를
/// 때마다 같은 키로 덮어써진다 — 원본·정정본이 서로 다른 시점에 같은 키로 조회되는
/// 상황을 그대로 흉내낸다.
class FakeDart {
  final filings = <Filing>[];
  final statements = <String, String>{};
  final financialCalls = <String>[];
  Future<void> Function(String key)? beforeFinancialResponse;

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
      final response =
          statements[k] ?? '{"status":"013","message":"조회된 데이타가 없습니다."}';
      await beforeFinancialResponse?.call(k);
      return _body(response);
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
  String ord = '1',
}) => {
  'rcept_no': rcept,
  'corp_code': '00000001',
  'bsns_year': '2025',
  'reprt_code': '11011',
  'sj_div': sjDiv,
  'account_id': accountId,
  'account_nm': name,
  'account_detail': '-',
  'thstrm_nm': '제 57 기',
  'thstrm_amount': amount,
  'ord': ord,
  'currency': 'KRW',
};

void main() {
  withServerpod('Given FinancialFactsSync with out-of-order corrections', (
    sessionBuilder,
    _,
  ) {
    late Session session;
    late FakeDart dart;
    final now = DateTime.utc(2026, 9, 17, 3);

    Future<IngestJob> runSync() async {
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
        callInterval: Duration.zero,
        // 회사별 재수집은 각 실행에서 과거 공시 목록도 다시 확인한다.
        corpCode: '00000001',
        clock: () => now,
      ).run();
      return (await IngestJob.db.findById(session, job.id!))!;
    }

    setUp(() async {
      session = sessionBuilder.build();
      dart = FakeDart();
      await Company.db.insertRow(
        session,
        Company(
          corpCode: '00000001',
          name: '00000001',
          market: Market.kospi,
          fiscalMonth: 12,
        ),
      );
    });

    Future<Map<String, FinancialFact>> factsByName(int reportId) async => {
      for (final f in await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(reportId),
      ))
        f.accountName: f,
    };

    test(
      '정상 순서(원본 먼저, 정정 나중)로 들어오면 정정본이 원본을 대체한다',
      () async {
        dart.filings.add((
          corp: '00000001',
          name: '사업보고서 (2025.12)',
          rcept: '20260310000001',
          date: '20260310',
        ));
        dart.setRows('00000001', 2025, '11011', 'CFS', [
          row('20260310000001', 'BS', 'ifrs-full_Assets', '자산총계', '1'),
          row(
            '20260310000001',
            'IS',
            'dart_OperatingIncomeLoss',
            '영업이익',
            '100',
          ),
        ]);
        await runSync();

        dart.filings.add((
          corp: '00000001',
          name: '[기재정정]사업보고서 (2025.12)',
          rcept: '20260915000002',
          date: '20260915',
        ));
        dart.setRows('00000001', 2025, '11011', 'CFS', [
          row('20260915000002', 'BS', 'ifrs-full_Assets', '자산총계', '2'),
          row(
            '20260915000002',
            'IS',
            'dart_OperatingIncomeLoss',
            '영업이익',
            '100',
          ),
        ]);
        await runSync();

        final reports = {
          for (final r in await FinancialReport.db.find(session)) r.rceptNo: r,
        };
        expect(reports, hasLength(2));
        final original = reports['20260310000001']!;
        final correction = reports['20260915000002']!;
        expect(original.supersededById, correction.id);
        expect(correction.supersededById, isNull);

        final originalFacts = await factsByName(original.id!);
        final correctionFacts = await factsByName(correction.id!);
        expect(
          originalFacts['자산총계']!.supersededById,
          correctionFacts['자산총계']!.id,
        );
        expect(
          originalFacts['자산총계']!.amount,
          BigInt.one,
          reason: '원본 값은 지우지 않는다',
        );
        expect(
          originalFacts['자산총계']!.sourceId,
          original.sourceId,
          reason: '대체되어도 자신의 출처는 그대로다',
        );
      },
    );

    test(
      '역순(정정 먼저, 원본 나중)으로 들어와도 접수번호가 더 큰 쪽만 활성으로 남는다',
      () async {
        // 원본 수집 요청은 먼저 시작했지만 응답은 정정본보다 늦게 도착한다.
        // 새로운 실행은 최신 정정만 선택하고, 이미 실행 중인 원본 요청은 자신의
        // 응답·출처 그대로 저장한 뒤 더 최신 보고서에 연결해야 한다.
        final originalRequested = Completer<void>();
        final releaseOriginal = Completer<void>();
        dart.beforeFinancialResponse = (key) async {
          if (key.endsWith('|CFS')) {
            originalRequested.complete();
            await releaseOriginal.future;
          }
        };
        dart.filings.add((
          corp: '00000001',
          name: '사업보고서 (2025.12)',
          rcept: '20260310000001',
          date: '20260310',
        ));
        dart.setRows('00000001', 2025, '11011', 'CFS', [
          row('20260310000001', 'BS', 'ifrs-full_Assets', '자산총계', '1'),
          row(
            '20260310000001',
            'IS',
            'dart_OperatingIncomeLoss',
            '영업이익',
            '100',
          ),
        ]);
        final originalRun = runSync();
        await originalRequested.future;
        dart.beforeFinancialResponse = null;
        dart.filings.add((
          corp: '00000001',
          name: '[기재정정]사업보고서 (2025.12)',
          rcept: '20260915000002',
          date: '20260915',
        ));
        dart.setRows('00000001', 2025, '11011', 'CFS', [
          row('20260915000002', 'BS', 'ifrs-full_Assets', '자산총계', '2'),
          row(
            '20260915000002',
            'IS',
            'dart_OperatingIncomeLoss',
            '영업이익',
            '100',
          ),
        ]);
        await runSync();
        releaseOriginal.complete();
        await originalRun;

        final reports = {
          for (final r in await FinancialReport.db.find(session)) r.rceptNo: r,
        };
        expect(reports, hasLength(2));
        final original = reports['20260310000001']!;
        final correction = reports['20260915000002']!;

        // 활성(정정되지 않은) 보고서는 접수번호가 큰(더 늦게 접수된) 쪽 하나뿐이어야
        // 한다. 고쳐지기 전에는 둘 다 null로 남는 버그가 있었다.
        expect(
          correction.supersededById,
          isNull,
          reason: '더 늦게 접수된 쪽이 최종본으로 활성 상태여야 한다',
        );
        expect(
          original.supersededById,
          correction.id,
          reason: '나중에 저장됐어도 접수번호가 더 작으므로 최종본에 대체되어야 한다',
        );

        final activeCount = await FinancialReport.db.count(
          session,
          where: (t) =>
              t.companyId.equals(original.companyId) &
              t.bsnsYear.equals(2025) &
              t.fsDiv.equals(FsDiv.consolidated) &
              t.supersededById.equals(null),
        );
        expect(activeCount, 1, reason: '같은 기간에 활성 보고서가 둘 이상 남으면 안 된다');

        final originalFacts = await factsByName(original.id!);
        final correctionFacts = await factsByName(correction.id!);
        expect(
          originalFacts['자산총계']!.supersededById,
          correctionFacts['자산총계']!.id,
        );
        expect(
          originalFacts['영업이익']!.supersededById,
          correctionFacts['영업이익']!.id,
        );
        // 지는 쪽(원본)의 값 자체와 출처는 훼손되지 않는다 — supersededById만 잇는다.
        expect(originalFacts['자산총계']!.amount, BigInt.one);
        expect(
          originalFacts['자산총계']!.sourceId,
          original.sourceId,
          reason: '원본으로 저장했던 사실의 출처는 정정본 출처로 바뀌지 않는다',
        );
        expect(correctionFacts['자산총계']!.amount, BigInt.two);
      },
    );

    test(
      '세 버전이 뒤섞인 순서로 들어와도 접수번호가 가장 큰 하나만 활성으로 남고, 변하지 않은 값도 최종본으로 바로 이어진다',
      () async {
        // 세 실행의 대상은 각 시작 시점의 최신 접수번호다. 원본과 중간 정정
        // 요청을 대기시킨 뒤 최신 정정을 먼저 저장해 응답 도착 순서를 뒤집는다.
        final originalRequested = Completer<void>();
        final middleRequested = Completer<void>();
        final releaseOriginal = Completer<void>();
        final releaseMiddle = Completer<void>();
        dart.beforeFinancialResponse = (key) async {
          if (key.endsWith('|CFS')) {
            originalRequested.complete();
            await releaseOriginal.future;
          }
        };
        dart.filings.add((
          corp: '00000001',
          name: '사업보고서 (2025.12)',
          rcept: '20260310000001',
          date: '20260310',
        ));
        dart.setRows('00000001', 2025, '11011', 'CFS', [
          row('20260310000001', 'BS', 'ifrs-full_Assets', '자산총계', '1'),
          row(
            '20260310000001',
            'IS',
            'dart_OperatingIncomeLoss',
            '영업이익',
            '100',
          ),
        ]);
        final originalRun = runSync();
        await originalRequested.future;
        dart.beforeFinancialResponse = (key) async {
          if (key.endsWith('|CFS')) {
            middleRequested.complete();
            await releaseMiddle.future;
          }
        };
        dart.filings.add((
          corp: '00000001',
          name: '[기재정정]사업보고서 (2025.12)',
          rcept: '20260610000003',
          date: '20260610',
        ));
        dart.setRows('00000001', 2025, '11011', 'CFS', [
          row('20260610000003', 'BS', 'ifrs-full_Assets', '자산총계', '2'),
          row(
            '20260610000003',
            'IS',
            'dart_OperatingIncomeLoss',
            '영업이익',
            '100',
          ),
        ]);
        final middleRun = runSync();
        await middleRequested.future;
        dart.beforeFinancialResponse = null;
        dart.filings.add((
          corp: '00000001',
          name: '[기재정정]사업보고서 (2025.12)',
          rcept: '20260915000002',
          date: '20260915',
        ));
        dart.setRows('00000001', 2025, '11011', 'CFS', [
          row('20260915000002', 'BS', 'ifrs-full_Assets', '자산총계', '3'),
          row(
            '20260915000002',
            'IS',
            'dart_OperatingIncomeLoss',
            '영업이익',
            '100',
          ),
        ]);
        await runSync();
        releaseMiddle.complete();
        await middleRun;
        releaseOriginal.complete();
        await originalRun;

        final reports = {
          for (final r in await FinancialReport.db.find(session)) r.rceptNo: r,
        };
        expect(reports, hasLength(3));
        final oldest = reports['20260310000001']!;
        final middle = reports['20260610000003']!;
        final latest = reports['20260915000002']!;

        expect(latest.supersededById, isNull);
        expect(
          oldest.supersededById,
          latest.id,
          reason: '가장 오래된 원본도 최종본으로 바로 이어진다',
        );
        expect(
          middle.supersededById,
          latest.id,
          reason: '중간 정정도 최종본으로 바로 이어진다(사슬로 잇지 않는다)',
        );

        final activeCount = await FinancialReport.db.count(
          session,
          where: (t) =>
              t.companyId.equals(oldest.companyId) &
              t.bsnsYear.equals(2025) &
              t.fsDiv.equals(FsDiv.consolidated) &
              t.supersededById.equals(null),
        );
        expect(activeCount, 1);

        final oldestFacts = await factsByName(oldest.id!);
        final middleFacts = await factsByName(middle.id!);
        final latestFacts = await factsByName(latest.id!);

        // 값이 안 바뀐 계정(영업이익)도, 중간에 몇 버전이 있었든 최종본 사실로
        // 곧장 이어져야 한다 — 중간 버전에 걸려 멈추면 안 된다.
        expect(oldestFacts['영업이익']!.supersededById, latestFacts['영업이익']!.id);
        expect(middleFacts['영업이익']!.supersededById, latestFacts['영업이익']!.id);
        expect(oldestFacts['영업이익']!.amount, BigInt.from(100));
        expect(middleFacts['영업이익']!.amount, BigInt.from(100));

        // 값이 바뀐 계정(자산총계)도 최종본으로 바로 이어지고, 지나간 버전의
        // 값·출처는 그대로 보존된다.
        expect(oldestFacts['자산총계']!.supersededById, latestFacts['자산총계']!.id);
        expect(middleFacts['자산총계']!.supersededById, latestFacts['자산총계']!.id);
        expect(oldestFacts['자산총계']!.amount, BigInt.one);
        expect(middleFacts['자산총계']!.amount, BigInt.two);
        expect(latestFacts['자산총계']!.amount, BigInt.from(3));
        expect(oldestFacts['자산총계']!.sourceId, oldest.sourceId);
        expect(middleFacts['자산총계']!.sourceId, middle.sourceId);
      },
    );
  });
}
