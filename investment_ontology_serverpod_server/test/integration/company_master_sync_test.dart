import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_client.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/api_call_budget.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/company_master_sync.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// 가짜 DART. corpCode.xml 목록과 기업개황 응답을 테스트에서 바꿀 수 있다.
class FakeDart {
  final corps = <String, ({String name, String? stock, String modify})>{};
  final profiles = <String, Map<String, dynamic>>{};
  final companyCalls = <String>[];

  DartClient client() => DartClient(
    'key',
    httpClient: MockClient((req) async {
      if (req.url.path.endsWith('corpCode.xml')) {
        final xml = StringBuffer('<result>');
        corps.forEach((code, c) {
          xml.write(
            '<list><corp_code>$code</corp_code><corp_name>${c.name}</corp_name>'
            '<stock_code>${c.stock ?? ' '}</stock_code><modify_date>${c.modify}</modify_date></list>',
          );
        });
        xml.write('</result>');
        final zip = ZipEncoder().encodeBytes(
          Archive()..addFile(
            ArchiveFile.bytes('CORPCODE.xml', utf8.encode(xml.toString())),
          ),
        );
        return http.Response.bytes(zip, 200);
      }
      final code = req.url.queryParameters['corp_code']!;
      companyCalls.add(code);
      return http.Response.bytes(
        utf8.encode(jsonEncode({'status': '000', ...profiles[code]!})),
        200,
      );
    }),
  );
}

Map<String, dynamic> profile(
  String name,
  String cls, {
  String ceo = '대표',
  String est = '19690113',
}) => {
  'corp_name': name,
  'corp_cls': cls,
  'stock_code': '005930',
  'ceo_nm': ceo,
  'induty_code': '264',
  'est_dt': est,
  'acc_mt': '12',
};

void main() {
  withServerpod('Given CompanyMasterSync', (sessionBuilder, endpoints) {
    late Session session;
    late FakeDart dart;

    Future<IngestJob> runSync({bool force = false}) async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: CompanyMasterSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      await CompanyMasterSync(
        session,
        dart.client(),
        job.id!,
      ).run(force: force);
      return (await IngestJob.db.findById(session, job.id!))!;
    }

    setUp(() {
      session = sessionBuilder.build();
      dart = FakeDart()
        ..corps['00000001'] = (name: '상장사', stock: '000001', modify: '20260101')
        ..corps['00000002'] = (name: '폐지사', stock: '000002', modify: '20250101')
        ..corps['00000003'] = (name: '비상장', stock: null, modify: '20250101')
        ..profiles['00000001'] = profile('상장사', 'Y')
        ..profiles['00000002'] = profile('폐지사', 'E');
    });

    test('상장사는 정규화해서 출처와 함께 저장, 폐지사는 장부에만', () async {
      final job = await runSync();

      expect(job.status, IngestStatus.succeeded);
      expect(dart.companyCalls, ['00000001', '00000002']);
      final companies = await Company.db.find(session);
      expect(companies.single.name, '상장사');
      expect(companies.single.market, Market.kospi);
      expect(companies.single.establishedDate, DateTime.utc(1969, 1, 13));
      expect(companies.single.dartModifiedDate, DateTime.utc(2026, 1, 1));
      expect(companies.single.sectionCode, 'C');
      expect(companies.single.profileSourceId, isNotNull);
      final statuses = await DartCorpStatus.db.find(session);
      expect(
        {for (final s in statuses) s.corpCode: s.corpCls},
        {
          '00000001': 'Y',
          '00000002': 'E',
        },
      );
    });

    test('다시 돌리면 변경일이 같은 기업은 상장·폐지 모두 호출하지 않는다', () async {
      await runSync();
      dart.companyCalls.clear();

      final job = await runSync();

      expect(job.total, 0);
      expect(dart.companyCalls, isEmpty);
    });

    test('변경일이 바뀌면 다시 받고, 바뀐 필드를 출처와 함께 이력으로 남긴다', () async {
      await runSync();
      final firstSourceCount = await Source.db.count(session);
      dart
        ..corps['00000001'] = (name: '상장사', stock: '000001', modify: '20260901')
        ..profiles['00000001'] = profile('상장사', 'Y', ceo: '새대표');

      final job = await runSync();

      expect(job.updated, 1);
      final company = (await Company.db.find(session)).single;
      expect(company.ceoName, '새대표');
      final changes = await CompanyChange.db.find(session);
      expect(changes.single.field, 'ceoName');
      expect(changes.single.oldValue, '대표');
      expect(changes.single.newValue, '새대표');
      expect(changes.single.sourceId, company.profileSourceId);
      expect(await Source.db.count(session), firstSourceCount + 1);
    });

    test('다시 받았는데 내용이 같으면 출처·이력을 늘리지 않는다', () async {
      await runSync();
      final sources = await Source.db.count(session);
      dart.corps['00000001'] = (
        name: '상장사',
        stock: '000001',
        modify: '20260901',
      );

      final job = await runSync();

      expect(job.updated, 0);
      expect(await Source.db.count(session), sources);
      expect(await CompanyChange.db.count(session), 0);
      final company = (await Company.db.find(session)).single;
      expect(company.dartModifiedDate, DateTime.utc(2026, 9, 1));
    });

    test('형식이 잘못된 설립일은 null', () async {
      dart.profiles['00000001'] = profile('상장사', 'Y', est: '00000000');

      await runSync();

      expect((await Company.db.find(session)).single.establishedDate, isNull);
    });

    test('전체 갱신은 한 번도 안 했거나 30일이 지나면 필요', () async {
      expect(await CompanyMasterSync.isFullRefreshDue(session), isTrue);

      Future<void> fullJob(DateTime finishedAt) => IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: CompanyMasterSync.kind,
          status: IngestStatus.succeeded,
          startedAt: finishedAt,
          finishedAt: finishedAt,
          fullRefresh: true,
        ),
      );
      final now = DateTime.now().toUtc();
      await fullJob(now.subtract(const Duration(days: 31)));
      expect(await CompanyMasterSync.isFullRefreshDue(session), isTrue);

      await fullJob(now.subtract(const Duration(days: 3)));
      expect(await CompanyMasterSync.isFullRefreshDue(session), isFalse);
    });

    test('실패한 전체 갱신은 주기 계산에 넣지 않는다', () async {
      final now = DateTime.now().toUtc();
      await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: CompanyMasterSync.kind,
          status: IngestStatus.failed,
          startedAt: now,
          finishedAt: now,
          fullRefresh: true,
        ),
      );
      expect(await CompanyMasterSync.isFullRefreshDue(session), isTrue);
    });

    test('DART 요청 제한(020)이면 멈추고 한도 안내와 함께 실패로 남긴다', () async {
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: CompanyMasterSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      final client = DartClient(
        'bad',
        httpClient: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode('{"status":"020","message":"요청 제한을 초과하였습니다."}'),
            200,
          ),
        ),
      );

      await CompanyMasterSync(session, client, job.id!).run(force: false);

      final result = (await IngestJob.db.findById(session, job.id!))!;
      expect(result.status, IngestStatus.failed);
      expect(result.message, contains('한도'));
    });

    test('오늘 DART 호출이 한도에 가까우면 남은 만큼만 받고 멈춘다', () async {
      // 재무 수집이 오늘 이미 많이 썼다고 둔다.
      await ApiCallBudget.record(session, ApiProvider.dart, 100);
      final job = await IngestJob.db.insertRow(
        session,
        IngestJob(
          kind: CompanyMasterSync.kind,
          status: IngestStatus.running,
          startedAt: DateTime.now().toUtc(),
        ),
      );
      final client = dart.client();

      // 상한 102 - 사용 100 = 2회: corpCode.xml 1회 + 기업개황 1회에서 멈춘다.
      await CompanyMasterSync(
        session,
        client,
        job.id!,
        dailyLimit: 102,
      ).run(force: true);

      final result = (await IngestJob.db.findById(session, job.id!))!;
      expect(result.status, IngestStatus.failed);
      expect(result.message, contains('2건 중 1건에서 멈춤'));
      expect(dart.companyCalls, hasLength(1));
      expect(
        await CompanyMasterSync.lastFullRefresh(session),
        isNull,
        reason: '끝나지 않은 전체 갱신은 완료로 치지 않는다',
      );
    });
  });
}
