import '../support/financial_html_test_clock.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

List<Map<String, dynamic>> actualHistorical({
  String corp = '00115694',
  String receipt = '20230321001219',
  String name = 'DB증권(주)',
  bool cfs = false,
  DateTime? end,
  String? cover,
  Uri? source,
}) {
  const base = 'test/fixtures/financial_html/historical-db';
  final m = jsonDecode(File('$base/metadata.json').readAsStringSync());
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: cover ?? File('$base/cover.html').readAsStringSync(),
    statementHtml: File('$base/OFS.html').readAsStringSync(),
    coverSource: source ?? Uri.parse(m['coverUrl']),
    statementSource: Uri.parse(m['OFSSource']),
    receipt: receipt,
    corpCode: corp,
    companyName: name,
    periodStart: DateTime.utc(2022),
    periodEnd: end ?? DateTime.utc(2022, 12, 31),
    consolidated: cfs,
  );
}

void main() {
  test(
    'official shell and actual source fetch preserve normal current-name call',
    () async {
      const base = 'test/fixtures/financial_html/historical-db';
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
      final source = await fastFinancialHtmlFetcher(client).fetchAnnual(
        '20230321001219',
        reportName: '사업보고서 (2022.12)',
        corpCode: '00115694',
        companyName: 'DB증권(주)',
        bsnsYear: 2022,
        periodEnd: DateTime.utc(2022, 12, 31),
        consolidated: false,
      );
      expect(source.rows.length, 8);
      expect(
        (source.rows.first['html_provenance']
            as Map)['historicalCompanyIdentity']['currentName'],
        'DB증권(주)',
      );
      client.close();
    },
  );

  test('exact current name uses preserved historical printed identity and eight actual core rows', () {
    final r = actualHistorical();
    expect(r.length, 8);
    expect(r.every((r) => r['account_id'] == null), isTrue);
    expect(
      (r.first['html_provenance']
          as Map)['historicalCompanyIdentity']['printedHistoricalName'],
      'DB금융투자주식회사',
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
        () => actualHistorical(
          corp: kind == 'corp' ? '00115695' : '00115694',
          receipt: kind == 'receipt' ? '20230321001220' : '20230321001219',
          name: kind == 'name' ? '다른증권' : 'DB증권(주)',
          end: kind == 'date' ? DateTime.utc(2021, 12, 31) : null,
          cfs: kind == 'basis',
          cover: kind == 'cover'
              ? File('test/fixtures/financial_html/historical-db/cover.html')
                    .readAsStringSync()
                    .replaceFirst('DB금융투자', '다른금융투자')
              : null,
          source: kind == 'source'
              ? Uri.parse(
                  'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001219&dcmNo=9083870&eleId=2&offset=784&length=3924&dtd=dart3.xsd',
                )
              : null,
        ),
        throwsFormatException,
      );
    });
  }
}
