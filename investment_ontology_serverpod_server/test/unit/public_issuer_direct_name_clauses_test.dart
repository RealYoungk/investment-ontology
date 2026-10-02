import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_issuer_legal_name.dart';

void main() {
  for (final receipt in [
    '20250321001825',
    '20230320000571',
    '20230317000589',
    '20250319000137',
  ]) {
    final dir =
        'test/fixtures/financial_html/direct-issuer-name-clauses/$receipt';
    final data = jsonDecode(File('$dir/evidence.json').readAsStringSync());
    final year = data['year'] as int;
    String raw(String label) => File('$dir/$label.html').readAsStringSync();
    Uri url(String label) => Uri.parse(
      (data['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
    );
    final shell = raw('shell'),
        overview = raw('issuer-overview'),
        cover = raw('cover');
    final coverText = cover
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', '')
        .replaceAll(RegExp(r'\s+'), '');
    final printed = RegExp(r'회사명:(.*?)(?:공동)?대표이사:')
        .firstMatch(coverText)!
        .group(1)!;
    Map<String, String>? verify({
      String? body,
      String? company,
      String? code,
      String? target,
      Uri? shellUri,
      Uri? overviewUri,
      Uri? coverUri,
      String? coverBody,
      DateTime? end,
    }) =>
        PublicIssuerLegalName(
          shellHtml: shell,
          shellSource: shellUri ?? url('shell'),
          overviewHtml: body ?? overview,
          overviewSource: overviewUri ?? url('issuer-overview'),
        ).verify(
          receipt: target ?? receipt,
          corpCode: code ?? data['corpCode'],
          masterName: data['masterName'],
          printedName: company ?? printed,
          coverSource: coverUri ?? url('cover'),
          coverHtml: coverBody ?? cover,
          periodStart: DateTime.utc(year),
          periodEnd: end ?? DateTime.utc(year, 12, 31),
        );
    group(receipt, () {
      test('official raw bytes and URI are preserved', () {
        for (final s in data['sources']) {
          expect(
            sha256
                .convert(File('$dir/${s['file']}').readAsBytesSync())
                .toString(),
            s['sha256'],
          );
          expect(Uri.parse(s['url']).queryParameters['rcpNo'], receipt);
        }
      });
      if (receipt == '20250319000137') {
        test(
          'planned rename without direct legal naming section remains rejected',
          () {
            expect(overview, contains('결의할 예정'));
            expect(verify(), isNull);
          },
        );
        return;
      }
      test('direct same-issuer legal declaration matches printed cover without alias', () {
        final proof = verify();
        expect(proof, isNotNull);
        expect(
          PublicIssuerLegalName.normalize(proof!['declaredLegalName']!),
          PublicIssuerLegalName.normalize(printed),
        );
        expect(proof['receipt'], receipt);
        expect(proof['corpCode'], data['corpCode']);
        expect(proof['currentName'], data['masterName']);
        expect(
          proof['legalNameEvidenceSource'],
          url('issuer-overview').toString(),
        );
      });
      test(
        'wrong corp, receipt, printed company, period and source dcm reject',
        () {
          expect(verify(code: '99999999'), isNull);
          expect(verify(target: '19990101000000'), isNull);
          expect(verify(company: '다른주식회사'), isNull);
          expect(verify(end: DateTime.utc(year - 1, 12, 31)), isNull);
          expect(
            verify(
              overviewUri: url('issuer-overview').replace(
                queryParameters: {
                  ...url('issuer-overview').queryParameters,
                  'dcmNo': '99999999',
                },
              ),
            ),
            isNull,
          );
          expect(
            verify(
              overviewUri: url('issuer-overview').replace(host: 'example.com'),
            ),
            isNull,
          );
        },
      );
      test('duplicate issuer heading or subsidiary/proposed naming cannot corroborate', () {
        final text = RegExp(
          r'<P\b[^>]*>.*?(?:회사의 법적|회사의 명칭).*?</P>',
          caseSensitive: false,
          dotAll: true,
        ).firstMatch(overview);
        expect(text, isNotNull);
        final duplicate = overview.replaceFirst(
          '</BODY>',
          '${text!.group(0)}</BODY>',
        );
        expect(duplicate, isNot(overview));
        expect(verify(body: duplicate), isNull);
        expect(
          verify(
            body: overview
                .replaceAll('당사의 한글 명칭은', '자회사의 한글 명칭은')
                .replaceAll('회사의 명칭은', '자회사의 명칭은')
                .replaceAll('당사의 명칭은', '자회사의 명칭은'),
          ),
          isNull,
        );
        expect(
          verify(body: overview.replaceAll('명칭은', '예정 명칭은')),
          isNull,
        );
      });
    });
  }
}
