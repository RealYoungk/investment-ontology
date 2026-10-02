import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

List<Map<String, dynamic>> actualSk({
  String corp = '01188730',
  String receipt = '20250320001633',
  String name = 'SK시그넷(주)',
  bool cfs = false,
  DateTime? end,
  String? cover,
  Uri? source,
}) {
  const base = 'test/fixtures/financial_html/sk-signet-exact';
  final m = jsonDecode(File('$base/metadata.json').readAsStringSync());
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: cover ?? File('$base/cover.html').readAsStringSync(),
    statementHtml: File('$base/OFS.html').readAsStringSync(),
    coverSource: source ?? Uri.parse(m['coverUrl']),
    statementSource: Uri.parse(m['OFSSource']),
    receipt: receipt,
    corpCode: corp,
    companyName: name,
    periodStart: DateTime.utc(2024),
    periodEnd: end ?? DateTime.utc(2024, 12, 31),
    consolidated: cfs,
  );
}

List<Map<String, dynamic>> consolidatedSk({
  String? body,
  Uri? statementSource,
}) {
  const path = 'assets/financial_source_cache/20250320001633-cfs';
  final manifest = jsonDecode(File('$path/manifest.json').readAsStringSync());
  final docs = {for (final v in manifest['sources']) v['label']: v};
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: File('$path/cover.html').readAsStringSync(),
    statementHtml: body ?? File('$path/cfs.html').readAsStringSync(),
    coverSource: Uri.parse(docs['cover']['url']),
    statementSource: statementSource ?? Uri.parse(docs['cfs']['url']),
    receipt: '20250320001633',
    corpCode: '01188730',
    companyName: 'SK시그넷(주)',
    periodStart: DateTime.utc(2024),
    periodEnd: DateTime.utc(2024, 12, 31),
    consolidated: true,
  );
}

void main() {
  test('CFS exact source rejects altered money, dates and OFS coordinates', () {
    final raw = File(
      'assets/financial_source_cache/20250320001633-cfs/cfs.html',
    ).readAsStringSync();
    expect(
      () => consolidatedSk(
        body: raw.replaceFirst('83,805,774,666', '83,805,774,665'),
      ),
      throwsFormatException,
    );
    expect(
      () => consolidatedSk(body: raw.replaceFirst('2024', '2023')),
      throwsFormatException,
    );
    expect(
      () => consolidatedSk(
        statementSource: Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=21&offset=310000&length=10&dtd=dart4.xsd',
        ),
      ),
      throwsFormatException,
    );
  });
  test(
    'actual consolidated source preserves independent current whole seven',
    () {
      const path = 'assets/financial_source_cache/20250320001633-cfs';
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: File('$path/cover.html').readAsStringSync(),
        statementHtml: File('$path/cfs.html').readAsStringSync(),
        coverSource: Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=1&offset=958&length=4511&dtd=dart4.xsd',
        ),
        statementSource: Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=19&offset=204119&length=101809&dtd=dart4.xsd',
        ),
        receipt: '20250320001633',
        corpCode: '01188730',
        companyName: 'SK시그넷(주)',
        periodStart: DateTime.utc(2024),
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: true,
      );
      expect(rows.length, 7);
      expect(rows.map((r) => r['thstrm_amount']).toSet(), {
        '243910853554',
        '346677333242',
        '-102766479688',
        '83805774666',
        '-242762417908',
        '-244070248163',
        '-66690869744',
      });
      expect(rows.every((r) => r['account_id'] == null), isTrue);
    },
  );
  test(
    'official shell and actual source fetch preserve normal current-name call',
    () async {
      const base = 'test/fixtures/financial_html/sk-signet-exact';
      final m = jsonDecode(File('$base/metadata.json').readAsStringSync());
      final client = MockClient((r) async {
        final file = r.url.path == '/dsaf001/main.do'
            ? 'shell.html'
            : r.url.toString() == m['coverUrl']
            ? 'cover.html'
            : r.url.toString() == m['OFSSource']
            ? 'OFS.html'
            : null;
        if (file == null) throw StateError('Unexpected source');
        return http.Response.bytes(
          File('$base/$file').readAsBytesSync(),
          200,
          request: r,
        );
      });
      final source = await PublicFinancialHtmlFetcher(client).fetchAnnual(
        '20250320001633',
        reportName: '사업보고서 (2024.12)',
        corpCode: '01188730',
        companyName: 'SK시그넷(주)',
        bsnsYear: 2024,
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: false,
      );
      expect(source.rows.length, 7);
      expect(
        (source.rows.first['html_provenance']
            as Map)['historicalCompanyIdentity']['currentName'],
        'SK시그넷(주)',
      );
      client.close();
    },
  );

  test('exact current name uses preserved historical printed identity and seven actual core rows', () {
    final r = actualSk();
    expect(r.length, 7);
    expect(r.every((r) => r['account_id'] == null), isTrue);
    expect(
      (r.first['html_provenance']
          as Map)['historicalCompanyIdentity']['printedHistoricalName'],
      '에스케이시그넷주식회사',
    );
  });
  for (final kind in [
    'corp',
    'receipt',
    'name',
    'date',
    'basis',
    'cover',
    'source',
  ]) {
    test('historical alias rejects $kind', () {
      expect(
        () => actualSk(
          corp: kind == 'corp' ? '01188731' : '01188730',
          receipt: kind == 'receipt' ? '20250320001634' : '20250320001633',
          name: kind == 'name' ? '다른증권' : 'SK시그넷(주)',
          end: kind == 'date' ? DateTime.utc(2021, 12, 31) : null,
          cfs: kind == 'basis',
          cover: kind == 'cover'
              ? File('test/fixtures/financial_html/sk-signet-exact/cover.html')
                    .readAsStringSync()
                    .replaceFirst('에스케이시그넷', '다른금융투자')
              : null,
          source: kind == 'source'
              ? Uri.parse(
                  'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=2&offset=958&length=4511&dtd=dart4.xsd',
                )
              : null,
        ),
        throwsFormatException,
      );
    });
  }
}
