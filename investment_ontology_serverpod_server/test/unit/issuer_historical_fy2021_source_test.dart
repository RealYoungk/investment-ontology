import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/primary_historical_issuer.dart';

void main() {
  for (final receipt in [
    '20210629000260',
    '20220322000542',
    '20220429000083',
  ]) {
    final dir = 'test/fixtures/financial_html/direct-issuer-fy2021/$receipt';
    String raw(String label) => File('$dir/$label.html').readAsStringSync();
    final meta = jsonDecode(File('$dir/proof.json').readAsStringSync());
    Uri uri(String label) => Uri.parse(
      (meta['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
    );
    final start = receipt == '20210629000260'
        ? DateTime.utc(2020, 4, 1)
        : DateTime.utc(2021);
    final end = receipt == '20210629000260'
        ? DateTime.utc(2021, 3, 31)
        : DateTime.utc(2021, 12, 31);
    final name = RegExp(r'회사명:(.*?)(?:공동)?대표이사:')
        .firstMatch(raw('cover').replaceAll(RegExp('<[^>]*>|\\s+|&nbsp;'), ''))!
        .group(1)!;
    final issuer = PublicIssuerLegalName(
      shellHtml: raw('shell'),
      shellSource: uri('shell'),
      overviewHtml: raw('overview'),
      overviewSource: uri('overview'),
    );
    test('$receipt direct legal identity and exact whole source', () {
      final identity = issuer.verify(
        receipt: receipt,
        corpCode: meta['corp'],
        masterName: meta['name'],
        printedName: name,
        coverSource: uri('cover'),
        coverHtml: raw('cover'),
        periodStart: start,
        periodEnd: end,
      );
      final primary = PrimaryHistoricalIssuer(
        shell: raw('shell'),
        shellSource: uri('shell'),
      );
      if (receipt == '20220429000083') {
        expect(identity, isNull);
        expect(
          primary.verify(
            receipt: receipt,
            corp: meta['corp'],
            consolidated: false,
            coverSource: uri('cover'),
            cover: raw('cover'),
            statementSource: uri('ofs'),
            statement: raw('ofs'),
            start: start,
            end: end,
          ),
          isNotNull,
        );
      } else {
        expect(identity, isNotNull);
      }
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: raw('cover'),
        statementHtml: raw('ofs'),
        coverSource: uri('cover'),
        statementSource: uri('ofs'),
        receipt: receipt,
        corpCode: meta['corp'],
        companyName: meta['name'],
        periodStart: start,
        periodEnd: end,
        consolidated: false,
        issuerProof: receipt == '20220429000083' ? null : issuer,
        primaryIssuerProof: receipt == '20220429000083' ? primary : null,
      );
      expect(rows.length, inInclusiveRange(7, 8));
      expect(
        issuer.verify(
          receipt: receipt,
          corpCode: '00000000',
          masterName: meta['name'],
          printedName: name,
          coverSource: uri('cover'),
          coverHtml: raw('cover'),
          periodStart: start,
          periodEnd: end,
        ),
        isNull,
      );
      if (receipt != '20220429000083') {
        final proposed = PublicIssuerLegalName(
          shellHtml: raw('shell'),
          shellSource: uri('shell'),
          overviewHtml: raw('overview').replaceAll('당사의 명칭은', '향후 당사의 명칭은'),
          overviewSource: uri('overview'),
        );
        expect(
          proposed.verify(
            receipt: receipt,
            corpCode: meta['corp'],
            masterName: meta['name'],
            printedName: name,
            coverSource: uri('cover'),
            coverHtml: raw('cover'),
            periodStart: start,
            periodEnd: end,
          ),
          isNull,
        );
      }
    });
  }
}
