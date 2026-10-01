import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final fixture = File(
    'test/fixtures/financial_xbrl/cosnine_20250409002838.zip',
  ).readAsBytesSync();
  List<Map<String, dynamic>> parse(
    List<int> zip, {
    String corp = '00442455',
    DateTime? end,
    bool cfs = true,
  }) => PublicFinancialXbrl.parse(
    zip,
    receipt: '20250409002838',
    corpCode: corp,
    bsnsYear: 2024,
    periodEnd: end ?? DateTime.utc(2024, 12, 31),
    consolidated: cfs,
  );
  List<int> change(String from, String to) {
    final archive = ZipDecoder().decodeBytes(fixture);
    final instance = archive.files.singleWhere((f) => f.name.endsWith('.xbrl'));
    final xml = utf8.decode(instance.content).replaceAll(from, to);
    return ZipEncoder().encodeBytes(
      Archive()..addFile(ArchiveFile.bytes(instance.name, utf8.encode(xml))),
    );
  }

  test(
    'public transport binds receipt and forwards the download session',
    () async {
      final requests = <http.Request>[];
      final reader = PublicFinancialXbrl(
        MockClient((request) async {
          requests.add(request);
          expect(request.url.host, 'dart.fss.or.kr');
          expect(request.url.queryParameters.containsKey('crtfc_key'), isFalse);
          if (request.url.path == '/dsaf001/main.do') {
            return http.Response(
              "openPdfDownload('20250409002838', '10571658')",
              200,
              headers: {'set-cookie': 'JSESSIONID=fixture; Path=/'},
            );
          }
          expect(request.headers['Cookie'], 'JSESSIONID=fixture');
          expect(request.headers['Referer'], isNotNull);
          if (request.url.path == '/pdf/download/main.do') {
            return http.Response(
              '<a href="/pdf/download/ifrs.do?rcp_no=20250409002838&amp;dcm_no=10571658&amp;lang=ko">XBRL</a>',
              200,
            );
          }
          return http.Response.bytes(fixture, 200);
        }),
      );
      final original = await reader.fetch('20250409002838');
      expect(original.source.queryParameters['rcp_no'], '20250409002838');
      expect(original.source.queryParameters['dcm_no'], '10571658');
      expect(parse(original.zip), isNotEmpty);
      expect(requests, hasLength(3));
    },
  );
  test('wrong receipt shell cannot redirect the original fallback', () async {
    final reader = PublicFinancialXbrl(
      MockClient(
        (_) async =>
            http.Response("openPdfDownload('20250409002839', '10571658')", 200),
      ),
    );
    await expectLater(reader.fetch('20250409002838'), throwsFormatException);
  });
  test(
    'actual exact-receipt XBRL matches printed current-year CFS and OFS tables',
    () {
      final cfs = {
        for (final r in parse(fixture)) r['account_id']: r['thstrm_amount'],
      };
      final ofs = {
        for (final r in parse(fixture, cfs: false))
          r['account_id']: r['thstrm_amount'],
      };
      expect(cfs['ifrs-full_Assets'], '39024201117');
      expect(cfs['ifrs-full_Revenue'], '9745770767');
      expect(cfs['dart_OperatingIncomeLoss'], '-8285302600');
      expect(cfs['ifrs-full_ProfitLoss'], '-19463045883');
      expect(
        cfs['ifrs-full_CashFlowsFromUsedInOperatingActivities'],
        '-12117877327',
      );
      expect(ofs['ifrs-full_Assets'], '39283113892');
      expect(ofs['ifrs-full_Revenue'], '9741301967');
      expect(ofs['ifrs-full_ProfitLoss'], '-19406159233');
    },
  );
  test('entity and requested actual period cannot be relabelled', () {
    expect(() => parse(fixture, corp: '00000001'), throwsFormatException);
    expect(
      () => parse(fixture, end: DateTime.utc(2025, 12, 31)),
      throwsFormatException,
    );
  });
  test('nonKRW and rounded amounts are rejected', () {
    expect(
      () => parse(change('iso4217:KRW', 'iso4217:USD')),
      throwsFormatException,
    );
    expect(
      () => parse(change('decimals="0"', 'decimals="-3"')),
      throwsFormatException,
    );
  });
}
