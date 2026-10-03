import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/source_verified_partial_core.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';

void main() {
  const dir = 'test/fixtures/financial_html/source-six-partial';
  for (final (rec, corp, name, expected) in [
    (
      '20230314001271',
      '00148832',
      '주식회사 제주은행',
      [
        '7311029000000',
        '6789175000000',
        '521854000000',
        '27020000000',
        '22820000000',
        '114388000000',
      ],
    ),
    (
      '20230309000572',
      '00104856',
      '삼성증권주식회사',
      [
        '47708236385999',
        '41728539853389',
        '5979696532610',
        '522368891429',
        '377508787620',
        '6690981692494',
      ],
    ),
    (
      '20230323001133',
      '01185867',
      '퓨쳐메디신주식회사',
      [
        '6036252189',
        '4510737502',
        '1525514687',
        '-7578443900',
        '-6999527850',
        '-6948451571',
      ],
    ),
  ]) {
    final proof =
        jsonDecode(File('$dir/$rec/proof.json').readAsStringSync()) as Map;
    Uri uri(String key) => Uri.parse(
      (proof['sources'] as List).singleWhere((e) => e['label'] == key)['url'],
    );
    final cover = File('$dir/$rec/cover.html').readAsStringSync(),
        raw = File('$dir/$rec/ofs.html').readAsStringSync();
    List<Map<String, dynamic>> parse({
      String? html,
      String? owner,
      bool cfs = false,
      bool allowPartial = true,
    }) => PublicFinancialHtml.parseStandardAnnual(
      allowSourceVerifiedPartialCore: allowPartial,
      coverHtml: cover,
      statementHtml: html ?? raw,
      coverSource: uri('cover'),
      statementSource: uri('ofs'),
      receipt: rec,
      corpCode: corp,
      companyName: owner ?? name,
      periodStart: DateTime.utc(2022),
      periodEnd: DateTime.utc(2022, 12, 31),
      consolidated: cfs,
    );
    bool verified(
      List<Map<String, dynamic>> rows, {
      String? digest,
      String? owner,
      String? basis,
    }) => SourceVerifiedPartialCore.verifiedRows(
      rows,
      bodySha256: sha256.convert(utf8.encode(raw)).toString(),
      sourceDigest:
          digest ?? sha256.convert(utf8.encode('$cover\n$raw')).toString(),
      sourceUrl: uri('ofs').toString(),
      companyCode: owner ?? corp,
      targetReceipt: rec,
      basis: basis ?? 'separate',
      year: 2022,
    );
    test('actual $rec whole-only default rejects missing revenue', () {
      expect(() => parse(allowPartial: false), throwsFormatException);
    });
    test(
      'actual $rec six numeric rows revenue unavailable and independent whole CE',
      () {
        for (final e in proof['sources']) {
          if (e['label'] == 'cfs') continue;
          expect(
            sha256
                .convert(File('$dir/$rec/${e['label']}.html').readAsBytesSync())
                .toString(),
            e['sha256'],
          );
        }
        final rows = parse();
        expect(rows.map((r) => r['thstrm_amount']).toList(), expected);
        expect(verified(rows), isTrue);
        final converted = FinancialRows.toFacts(
          rows,
          reportId: 1,
          companyId: 1,
          bsnsYear: 2022,
          reportCode: FinancialReportCode.annual,
          fsDiv: FsDiv.separate,
          sourceId: 1,
        );
        for (var i = 0; i < converted.facts.length; i++) {
          converted.facts[i].id = i + 1;
        }
        final lines = FinancialAccounts.pick(converted.facts);
        expect(lines.map((l) => l.key).toSet(), {
          'assets',
          'liabilities',
          'equity',
          'operatingIncome',
          'netIncome',
          'operatingCashFlow',
        });
        expect(lines.any((l) => l.key == 'revenue'), isFalse);
        expect(
          lines.singleWhere((l) => l.key == 'netIncome').amount.toString(),
          expected[4],
        );
        expect(
          rows.every(
            (r) =>
                r['account_id'] == null &&
                (r['html_provenance']
                        as Map)['partialCoreProof']['missingAccount'] ==
                    'revenue',
          ),
          isTrue,
        );
      },
    );
    for (final bad in [
      'digest',
      'owner',
      'basis',
      'amount',
      'CEonly',
      'mixedperiod',
      'revenuezero',
    ]) {
      test('$rec partial proof rejects $bad', () {
        final rows = (jsonDecode(jsonEncode(parse())) as List)
            .cast<Map<String, dynamic>>();
        if (bad == 'amount') rows.last['thstrm_amount'] = '1';
        if (bad == 'mixedperiod') {
          rows.last['html_provenance']['periodEnd'] = '2021-12-31';
        }
        if (bad == 'CEonly') {
          for (final r in rows) {
            r['html_provenance']['partialCoreProof']['wholeCE']['wholeProfit'] =
                '1';
          }
        }
        if (bad == 'revenuezero') {
          rows.add({
            ...rows.first,
            'account_nm': '영업수익',
            'thstrm_amount': '0',
            'sj_div': 'CIS',
          });
        }
        expect(
          verified(
            rows,
            digest: bad == 'digest' ? '0' * 64 : null,
            owner: bad == 'owner' ? '00000000' : null,
            basis: bad == 'basis' ? 'consolidated' : null,
          ),
          isFalse,
        );
      });
    }
    test(
      '$rec wrong company rejected before partial extraction',
      () => expect(() => parse(owner: '다른회사'), throwsFormatException),
    );
    test(
      '$rec cannot reuse OFS as CFS',
      () => expect(() => parse(cfs: true), throwsFormatException),
    );
    test('$rec original source CE-only contradiction rejected', () {
      final tables = RegExp(
        r'<TABLE\b[^>]*>.*?</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(raw).toList();
      final ce = tables.singleWhere(
        (t) =>
            t.group(0)!.contains('총') &&
            t.group(0)!.contains('2022') &&
            t.group(0)!.contains('당기순') &&
            !t.group(0)!.contains('영업활동'),
      );
      final money = BigInt.parse(expected[2]);
      final printed = money.toString();
      final unit = rec == '20230314001271' ? 1000000 : 1;
      String grouped(BigInt value) => value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
      final before = grouped(money ~/ BigInt.from(unit));
      final at = ce.start + ce.group(0)!.lastIndexOf(before);
      expect(at, greaterThan(ce.start));
      expect(
        () => parse(
          html: raw.replaceRange(
            at,
            at + before.length,
            grouped(money ~/ BigInt.from(unit) + BigInt.one),
          ),
        ),
        throwsFormatException,
      );
      expect(printed, isNotEmpty);
    });
  }
  for (final bad in [
    '지배기업소유주당기순이익(대손준비금반영후조정이익당기:1원전기:2원전전기:3원)',
    '대손준비금반영후조정이익당기:1원전기:2원전전기:3원',
    '당기순이익(대손준비금반영후조정이익당기:1,,2원전기:2원전전기:3원)',
    '당기순이익(대손준비금반영후조정이익당기:1달러전기:2원전전기:3원)',
  ]) {
    test(
      'finite normalization rejects $bad',
      () => expect(FinancialAccounts.normalizedName(bad), isNot('당기순이익')),
    );
  }
  test(
    'Dart SQL annotation mapping shares exact finite expression',
    () => expect(
      FinancialAccounts.resolvedIdSql('f'),
      contains(FinancialAccounts.adjustedProfitAnnotation),
    ),
  );
}
