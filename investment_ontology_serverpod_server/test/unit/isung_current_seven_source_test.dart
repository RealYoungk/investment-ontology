import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/isung_current_seven_source.dart';

void main() {
  for (final receipt in ['20230323000123', '20240321000294']) {
    final profile = IsungCurrentSevenSource.profiles[receipt] as Map;
    final year = profile['year'] as int;
    final dir =
        'assets/financial_source_cache/$receipt-ofs-isung-current-seven';
    final manifest = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    final raw = <String, String>{};
    final uris = <String, Uri>{};
    for (final source in manifest['sources'] as List) {
      raw[source['label']] = File('$dir/${source['file']}').readAsStringSync();
      uris[source['label']] = Uri.parse(source['url']);
    }
    List<Map<String, dynamic>> parse({
      bool consolidated = false,
      String? corp,
      DateTime? start,
      Map<String, String>? changed,
    }) => IsungCurrentSevenSource.parse(
      raw: changed ?? raw,
      uris: uris,
      receipt: receipt,
      corp: corp ?? '01365384',
      start: start ?? DateTime.utc(year),
      end: DateTime.utc(year, 12, 31),
      consolidated: consolidated,
    );
    test('$receipt own current seven exact physical cells', () {
      final rows = parse();
      expect(rows, hasLength(7));
      expect(
        rows.map((r) => r['thstrm_amount']),
        (profile['core'] as List).map((c) => c['value']),
      );
      for (final row in rows) {
        expect(row['account_id'], isNull);
        expect(int.parse(row['ord'] as String), greaterThan(0));
        final proof = row['html_provenance'] as Map;
        expect(proof['partialCore7'], isTrue);
        expect(proof['fullStatementCollected'], isFalse);
        expect(proof['optionalAccountsNotCollected'], ['capex']);
        expect(proof['cashFx'], contains('no zero'));
      }
    });
    test(
      '$receipt rejects opposite basis',
      () => expect(() => parse(consolidated: true), throwsFormatException),
    );
    test(
      '$receipt rejects other issuer',
      () => expect(() => parse(corp: '00000000'), throwsFormatException),
    );
    test(
      '$receipt rejects prior period',
      () => expect(
        () => parse(start: DateTime.utc(year - 1)),
        throwsFormatException,
      ),
    );
    test(
      '$receipt rejects changed original',
      () => expect(
        () => parse(changed: {...raw, 'ofs': '${raw['ofs']} '}),
        throwsFormatException,
      ),
    );
  }
}
