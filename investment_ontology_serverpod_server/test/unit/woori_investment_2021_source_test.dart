import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/woori_investment_2021_source.dart';

void main() {
  for (final cfs in [true, false]) {
    final basis = cfs ? 'cfs' : 'ofs';
    final dir = cfs
        ? 'test/fixtures/financial_html/woori-investment-2021-cfs-conflict'
        : 'assets/financial_source_cache/20220715000446-ofs';
    final m = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    Uri uri(String name) => Uri.parse(
      (m['sources'] as List).singleWhere((s) => s['label'] == name)['url'],
    );
    String raw(String name) => File('$dir/$name.html').readAsStringSync();
    List<Map<String, dynamic>> parse({
      String? st,
      String receipt = '20220715000446',
      String corp = '00231664',
      DateTime? end,
      Uri? source,
    }) => WooriInvestment2021Source.parse(
      shell: raw('shell'),
      cover: raw('cover'),
      statement: st ?? raw(basis),
      shellSource: uri('shell'),
      coverSource: uri('cover'),
      statementSource: source ?? uri(basis),
      sourceReceipt: receipt,
      corpCode: corp,
      periodStart: DateTime.utc(2021),
      periodEnd: end ?? DateTime.utc(2021, 12, 31),
      consolidated: cfs,
    );
    test(
      cfs
          ? 'CFS actual one-won activity conflict remains rejected'
          : 'OFS seven whole amounts and independent cash/CE proofs',
      () {
        if (cfs) {
          expect(
            parse,
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'exact cash proof failure',
                'Woori direct cash rollforward mismatch',
              ),
            ),
          );
          return;
        }
        final rows = parse();
        expect(rows, hasLength(7));
        expect(rows.map((r) => r['account_id']), everyElement(isNull));
        expect(rows.last['account_nm'], 'I. 영업활동으로 인한 순현금흐름');
        final p = rows.last['html_provenance'] as Map;
        expect(p['cashRollforward']['bsCurrentPriorCashMatched'], true);
        expect(p['fullStatementCollected'], false);
        expect(p['cashRollforward']['fxAmountAvailable'], cfs);
        if (!cfs) expect(p['cashRollforward']['printedFx'], '-');
      },
    );
    for (final n in <String, void Function()>{
      'receipt': () => parse(receipt: '20220715000445'),
      'corp': () => parse(corp: '00112332'),
      'year': () => parse(end: DateTime.utc(2022, 12, 31)),
      'URI': () =>
          parse(source: uri(basis).replace(query: 'rcpNo=20220715000446')),
      'unit': () => parse(st: raw(basis).replaceAll('단위: 원', '단위: 천원')),
      'parent': () =>
          parse(st: raw(basis).replaceFirst('VII. 당기순이익', 'VII. 지배기업순이익')),
      'CF partial label': () =>
          parse(st: raw(basis).replaceFirst('I. 영업활동으로 인한 순현금흐름', 'I. 영업활동')),
      'one won': () => parse(
        st: raw(basis)
            .replaceFirst(cfs ? '922,989,936,891' : '919,280,938,907', '1'),
      ),
    }.entries) {
      test(
        '$basis rejects ${n.key}',
        () => expect(n.value, throwsFormatException),
      );
    }
  }
}
