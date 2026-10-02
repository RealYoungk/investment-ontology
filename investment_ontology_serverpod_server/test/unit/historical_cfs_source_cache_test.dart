import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/primary_historical_issuer.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/historical_cfs_whole_proof.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/pureun_exact_basis_absence.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final cases = jsonDecode(
    File('test/fixtures/financial_html/historical-cfs-source/cases.json')
        .readAsStringSync(),
  ) as List;
  for (final c in cases) {
    final e = VerifiedAnnualSourceRegistry.find(
      c['receipt'],
      FsDiv.consolidated,
    )!;
    final manifest = jsonDecode(
      File('${e.assetDirectory}/manifest.json').readAsStringSync(),
    );
    String raw(String l) =>
        File('${e.assetDirectory}/$l.html').readAsStringSync();
    Uri url(String l) => Uri.parse(
      (manifest['sources'] as List).singleWhere((s) => s['label'] == l)['url'],
    );
    test('${e.receipt} independent actual CFS source', () async {
      final read = <String>[];
      final f = filing(e), before = f.toJson();
      final result = await VerifiedAnnualSourceCache(
        readAsset: (p) async {
          read.add(p);
          return File(p).readAsBytes();
        },
      ).verifyRegistered(f, company(e), FsDiv.consolidated);
      expect(read, hasLength(e.requiresIssuerOverview ? 5 : 4));
      expect(f.toJson(), before);
      if (e.absenceLiteral != null) {
        expect(result.numeric, isNull);
        final none = result.absence!;
        expect(none.evidence, ': 해당사항 없음');
        expect(none.statementSource, url('cfs'));
        expect(none.sourceReceipt, e.receipt);
        expect(none.corpCode, e.corpCode);
        expect(none.periodStart, DateTime.utc(e.year));
        expect(none.periodEnd, DateTime.utc(e.year, 12, 31));
      } else {
        expect(result.absence, isNull);
        final rows = result.numeric!.rows;
        expect(rows, hasLength(7));
        expect(
          rows.map((r) => [r['account_nm'], r['thstrm_amount']]).toList(),
          c['expectedRows'],
        );
        expect(
          rows.every(
            (r) =>
                r['account_id'] == null &&
                r['html_provenance']['basis'] == 'CFS',
          ),
          true,
        );
        expect(
          BigInt.parse(rows[0]['thstrm_amount']),
          BigInt.parse(rows[1]['thstrm_amount']) +
              BigInt.parse(rows[2]['thstrm_amount']),
        );
      }
    });
    for (final label in [
      'manifest.json',
      'shell.html',
      'cover.html',
      'cfs.html',
      if (e.requiresIssuerOverview) 'overview.html',
    ]) {
      test('${e.receipt} pinned $label tamper rejects', () async {
        await expectLater(
          VerifiedAnnualSourceCache(
            readAsset: (p) async {
              final b = await File(p).readAsBytes();
              return p.endsWith(label) ? [...b, 32] : b;
            },
          ).verifyRegistered(filing(e), company(e), FsDiv.consolidated),
          throwsFormatException,
        );
      });
    }
    if (e.absenceLiteral == null) {
      List<Map<String, dynamic>> parse({
        String? body,
        String? corp,
        Uri? uri,
      }) => PublicFinancialHtml.parseStandardAnnual(
        coverHtml: raw('cover'),
        statementHtml: body ?? raw('cfs'),
        coverSource: url('cover'),
        statementSource: uri ?? url('cfs'),
        receipt: e.receipt,
        corpCode: corp ?? e.corpCode,
        companyName: e.companyName,
        periodStart: DateTime.utc(e.year),
        periodEnd: DateTime.utc(e.year, 12, 31),
        consolidated: true,
        primaryIssuerProof: PrimaryHistoricalIssuer(
          shell: raw('shell'),
          shellSource: url('shell'),
        ),
      );
      test(
        '${e.receipt} actual whole CE cannot be replaced by another profit input',
        () {
          final expected = c['expectedRows'] as List;
          Map<String, dynamic> verify(BigInt profit, BigInt equity) =>
              HistoricalCfsWholeProof.verify(
                receipt: e.receipt,
                corp: e.corpCode,
                start: DateTime.utc(e.year),
                end: DateTime.utc(e.year, 12, 31),
                source: url('cfs'),
                html: raw('cfs'),
                netIncome: profit,
                equity: equity,
              );
          final net = BigInt.parse(expected[5][1]),
              equity = BigInt.parse(expected[2][1]);
          final proof = verify(net, equity);
          expect(proof['wholeColumn'], 6);
          expect(proof['nonControllingColumn'], 5);
          expect(proof['currentProfit'], net.toString());
          expect(() => verify(net + BigInt.one, equity), throwsFormatException);
          expect(() => verify(net, equity + BigInt.one), throwsFormatException);
          if (e.receipt == '20230714000217') {
            expect(proof['printedCurrentProfitCells'][4], '(3,429,585,772)');
            expect(proof['printedCurrentProfitCells'][5], '(137,052,900)');
            expect(proof['printedCurrentProfitCells'][6], '(3,566,638,672)');
            expect(
              () => verify(BigInt.from(-3429585772), equity),
              throwsFormatException,
            );
            expect(
              () => verify(BigInt.from(-137052900), equity),
              throwsFormatException,
            );
          }
        },
      );
      test('${e.receipt} opposite node and owner reject', () {
        expect(() => parse(corp: '99999999'), throwsFormatException);
        expect(() => parse(uri: url('cover')), throwsFormatException);
      });
      test('${e.receipt} current period contradiction rejects', () {
        expect(
          () => parse(
            body: raw('cfs')
                .replaceAll('${e.year}.12.31', '${e.year - 1}.12.31')
                .replaceAll('${e.year}년 12월 31일', '${e.year - 1}년 12월 31일'),
          ),
          throwsFormatException,
        );
      });
      test('${e.receipt} BS or CE whole mutation rejects', () {
        final amount = BigInt.parse(c['expectedRows'][2][1]);
        String commas(BigInt v) => v.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
        final b = raw('cfs');
        final a = commas(amount);
        expect(b.contains(a), true);
        expect(
          () => parse(body: b.replaceAll(a, commas(amount + BigInt.one))),
          throwsFormatException,
        );
      });
      test('${e.receipt} CE-only whole equity contradiction rejects', () {
        final amount = BigInt.parse(c['expectedRows'][2][1]);
        String commas(BigInt v) => v.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
        final b = raw('cfs');
        final a = commas(amount);
        expect(b.contains(a), true);
        expect(
          () => parse(
            body: b.replaceRange(
              b.lastIndexOf(a),
              b.lastIndexOf(a) + a.length,
              commas(amount + BigInt.one),
            ),
          ),
          throwsFormatException,
        );
      });
    } else {
      bool matches({String? body, String? corp, Uri? uri, DateTime? end}) =>
          PureunExactBasisAbsence.matches(
            receipt: e.receipt,
            corp: corp ?? e.corpCode,
            shellSource: url('shell'),
            shell: raw('shell'),
            start: DateTime.utc(e.year),
            end: end ?? DateTime.utc(e.year, 12, 31),
            coverSource: url('cover'),
            cover: raw('cover'),
            statementSource: uri ?? url('cfs'),
            body: body ?? raw('cfs'),
          );
      test('Pureun exact source cannot widen colon grammar', () {
        expect(matches(), true);
        for (final b in [
          "${raw('cfs')} ",
          raw('cfs').replaceAll(': 해당사항 없음', ': 해당사항 없음 1'),
          raw('cfs').replaceAll(': 해당사항 없음', '조건에 따라 해당사항 없음'),
          raw(
            'cfs',
          ).replaceAll('</BODY>', '<TABLE><TR><TD>1</TD></TR></TABLE></BODY>'),
          raw('cfs').replaceAll('</BODY>', '<script>없음</script></BODY>'),
        ]) {
          expect(matches(body: b), false);
        }
        expect(matches(corp: '99999999'), false);
        expect(matches(end: DateTime.utc(2021, 12, 31)), false);
        expect(matches(uri: url('cover')), false);
      });
    }
  }
}
