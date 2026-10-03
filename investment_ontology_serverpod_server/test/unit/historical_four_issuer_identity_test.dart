import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_historical_company_identity.dart';

void main() {
  const directory = 'assets/financial_source_cache/historical-four-identity';
  final contracts =
      jsonDecode(File('$directory/contracts.json').readAsStringSync()) as List;
  for (final raw in contracts) {
    final r = raw as Map;
    final receipt = r['receipt'] as String;
    final cover = File('$directory/$receipt-cover.html').readAsStringSync();
    Map<String, String>? verify({
      String? code,
      String? actor,
      String? current,
      DateTime? end,
      String? body,
      Uri? uri,
      bool cfs = true,
    }) => VerifiedHistoricalCompanyIdentity.evidence(
      receipt: receipt,
      corpCode: code ?? r['corpCode'] as String,
      currentName: current ?? r['currentCompanyName'] as String,
      printedName: actor ?? r['ownPrintedCompanyName'] as String,
      periodEnd: end ?? DateTime.utc(r['year'] as int, 12, 31),
      consolidated: cfs,
      coverSource: uri ?? Uri.parse(r['ownCoverURL'] as String),
      coverHtml: body ?? cover,
    );
    test(
      '$receipt binds actual own cover and independent official change body',
      () {
        final proof = verify()!;
        expect(proof['corpCode'], r['corpCode']);
        expect(
          proof['coverSha256'],
          sha256.convert(utf8.encode(cover)).toString(),
        );
        final shell = File('$directory/$receipt-shell.html').readAsStringSync();
        expect(shell, contains("openCorpInfoNew('${r['corpCode']}'"));
        expect(
          proof['historicalOwnShellSha256'],
          sha256.convert(utf8.encode(shell)).toString(),
        );
        final files = {
          '20220329001197': 'solumix-change.html',
          '20220321000965': 'protia-change.html',
          '20230328000161': 'siseon-change.html',
        };
        final bytes = File('$directory/${files[receipt]}').readAsBytesSync();
        expect(
          proof['legalNameEvidenceSha256'],
          sha256.convert(bytes).toString(),
        );
        final change = utf8
            .decode(bytes)
            .replaceAll(RegExp('<[^>]*>|\\s+|&nbsp;'), '');
        final labels = {
          '20220329001197': ['로보쓰리에이아이', '솔루믹스', '로보쓰리'],
          '20220321000965': ['프로테옴텍', '프로티아', '2023-11-15'],
          '20230328000161': ['씨유박스', '시선에이아이', '2025-03-26'],
        };
        for (final label in labels[receipt]!) {
          expect(change, contains(label));
        }
        expect(proof['numericApproval'], 'false');
      },
    );
    test('$receipt rejects changed issuer, year, URI and original bytes', () {
      expect(verify(code: '00000000'), isNull);
      expect(verify(actor: '다른회사'), isNull);
      expect(verify(current: '다른회사'), isNull);
      expect(verify(end: DateTime.utc((r['year'] as int) + 1, 12, 31)), isNull);
      expect(verify(body: '$cover '), isNull);
      expect(verify(uri: Uri.parse('${r['ownCoverURL']}&other=1')), isNull);
      if (receipt == '20230328000161') expect(verify(cfs: false), isNull);
    });
  }
  test('Bellock SPAC short period is not an approved calendar-year alias', () {
    expect(
      VerifiedHistoricalCompanyIdentity.evidence(
        receipt: '20230323000728',
        corpCode: '01622331',
        currentName: '주식회사 벨로크',
        printedName: '아이비케이에스제18호기업인수목적 주식회사',
        periodEnd: DateTime.utc(2022, 12, 31),
        consolidated: true,
        coverSource: Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000728&dcmNo=9095573&eleId=1&offset=814&length=4040&dtd=dart3.xsd',
        ),
        coverHtml: '',
      ),
      isNull,
    );
  });
}
