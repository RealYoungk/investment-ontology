import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

void main() {
  const root = 'test/fixtures/financial_html/whole-core-ce-grammar';
  for (final c in [
    (
      '20220315000921',
      '00113359',
      '교보증권(주)',
      2021,
      [
        '10989004086447',
        '9592303476726',
        '1396700609721',
        '2234605378883',
        '185009452284',
        '143691283619',
        '-972275164564',
      ],
    ),
    (
      '20220315001266',
      '00162416',
      '한양증권(주)',
      2021,
      [
        '1633398450357',
        '1201053825996',
        '432344624361',
        '874165603240',
        '116239144300',
        '79443581011',
        '-71389082428',
      ],
    ),
    (
      '20220315001273',
      '00148610',
      '한화투자증권(주)',
      2021,
      [
        '10989358819577',
        '9128664909818',
        '1860693909759',
        '1860706840350',
        '202640629212',
        '141767367786',
        '-856341358433',
      ],
    ),
    (
      '20230317000614',
      '01023822',
      '(주)메디젠휴먼케어',
      2022,
      [
        '5272046686',
        '13867392174',
        '-8595345488',
        '3949759031',
        '-2268707170',
        '-2792081425',
        '-2499085336',
      ],
    ),
  ]) {
    final raw = File('$root/${c.$1}/ofs.html').readAsStringSync();
    final cover = File('$root/${c.$1}/cover.html').readAsStringSync();
    final proof =
        jsonDecode(File('$root/${c.$1}/proof.json').readAsStringSync()) as Map;
    Uri uri(String key) => Uri.parse(
      (proof['sources'] as List).singleWhere((x) => x['label'] == key)['url'],
    );
    List<Map<String, dynamic>> parse(
      String html, {
      bool cfs = false,
      String? owner,
    }) => PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover,
      statementHtml: html,
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      receipt: c.$1,
      corpCode: c.$2,
      companyName: owner ?? c.$3,
      periodStart: DateTime.utc(c.$4),
      periodEnd: DateTime.utc(c.$4, 12, 31),
      consolidated: cfs,
    );
    test('${c.$1} seven direct printed values and independent whole CE', () {
      final rows = parse(raw);
      expect(rows.take(7).map((x) => x['thstrm_amount']).toList(), c.$5);
      const caps = {
        '20220315000921': '-8629403578',
        '20220315001273': '-5764244844',
        '20230317000614': '-353418663',
      };
      if (caps.containsKey(c.$1)) {
        expect(rows.length, 8);
        expect(rows.last['thstrm_amount'], caps[c.$1]);
        expect(
          FinancialAccounts.normalizedName(rows.last['account_nm']),
          '유형자산의취득',
        );
      } else {
        expect(rows.length, 7);
      }
      expect(rows.every((x) => x['account_id'] == null), isTrue);
      final p = rows.first['html_provenance']['wholeCoreProof'] as Map;
      expect(p['bodySha256'], sha256.convert(utf8.encode(raw)).toString());
      expect(p['source'], uri('ofs').toString());
      expect(p['wholeCE']['wholeProfit'], c.$5[5]);
      expect(p['wholeCE']['closingEquity'], c.$5[2]);
      expect(
        rows[5]['account_nm'],
        contains(c.$4 == 2022 ? '당기순이익(손실)' : '당기순'),
      );
      expect(
        FinancialAccounts.normalizedName(rows[5]['account_nm']),
        c.$4 == 2022 ? '당기순이익(손실)' : '당기순이익',
      );
    });
    test('${c.$1} CE-only total conflict rejected', () {
      final p =
          parse(raw).first['html_provenance']['wholeCoreProof']['wholeCE']
              as Map;
      final tables = RegExp(
        r'<TABLE\b[^>]*>(.*?)</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(raw).toList();
      final t = tables[p['tableIndex'] as int];
      final cells = p['printedProfitCells'] as List;
      final printed = cells.last as String;
      expect(printed, isNotEmpty);
      final changed = t[0]!.replaceAll(printed, '9,999,999,999,999');
      expect(changed, isNot(t[0]));
      expect(
        () => parse(raw.replaceRange(t.start, t.end, changed)),
        throwsFormatException,
      );
    });
    test('${c.$1} own money unit cannot be changed to USD', () {
      final bad = raw.replaceAll(RegExp(r'단위\s*:\s*원'), '단위:USD');
      expect(bad, isNot(raw));
      expect(() => parse(bad), throwsFormatException);
    });
    if (c.$4 == 2022) {
      test('Medizen cannot relax colspan 7 to 8', () {
        final bad = raw.replaceAll(
          RegExp(r'colspan=(["\x27]?)7', caseSensitive: false),
          'colspan=8',
        );
        expect(bad, isNot(raw));
        expect(() => parse(bad), throwsFormatException);
      });
      test('Medizen whole CE cannot be NCI group', () {
        final bad = raw.replaceAll('지배기업소유주지분', '비지배기업소유주지분');
        expect(bad, isNot(raw));
        expect(() => parse(bad), throwsFormatException);
      });
    } else {
      test('${c.$1} parent annotation cannot become whole profit', () {
        final bad = raw.replaceAll('대손준비금', '지배기업대손준비금');
        expect(() => parse(bad), throwsFormatException);
      });
    }
    test(
      '${c.$1} cannot reuse OFS as CFS',
      () => expect(() => parse(raw, cfs: true), throwsFormatException),
    );
    test(
      '${c.$1} wrong issuer rejected',
      () => expect(() => parse(raw, owner: '다른회사'), throwsFormatException),
    );
  }
  for (final label in [
    '당기순이익(대손준비금반영후조정이익당기:1원전기:2원)',
    '당기순손익(대손준비금반영후조정이익:당기:1원전기:2원전전기:3원)',
  ]) {
    test(
      'finite whole annotation $label',
      () => expect(FinancialAccounts.normalizedName(label), '당기순이익'),
    );
  }
  for (final label in [
    '지배기업소유주당기순이익(대손준비금반영후조정이익당기:1원전기:2원)',
    '당기순이익(대손준비금반영후조정이익당기:1달러전기:2원)',
    '당기순이익(대손준비금반영후조정이익당기:1,,2원전기:2원)',
    '대손준비금반영후조정이익당기:1원전기:2원',
    '당기순이익(대손준비금반영후조정이익당기:1원전기:2원)(EPS)',
  ]) {
    test(
      'ambiguous/parent annotation rejected $label',
      () => expect(FinancialAccounts.normalizedName(label), isNot('당기순이익')),
    );
  }
}
