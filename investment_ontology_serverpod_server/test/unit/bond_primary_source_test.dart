import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/capital_structure_parser.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/bond_trends.dart';
import 'package:test/test.dart';

void main() {
  test('recorded DART face balances: Jaeyoung 2022 to 2023 decreases 2.3 billion KRW, cause unconfirmed', () {
    final manifest = (jsonDecode(
      File('test/fixtures/bond_trends/manifest.json').readAsStringSync(),
    ) as List).cast<Map<String, dynamic>>();
    final periods = <Map<String, dynamic>>[];
    for (final entry in manifest) {
      final raw = File('test/fixtures/bond_trends/${entry['file']}')
          .readAsStringSync();
      expect(
        sha256.convert(utf8.encode(raw)).toString(),
        entry['fixtureSha256'],
      );
      final parsed = CapitalStructureParser.parse(
        raw,
        receipt: entry['receipt'],
        periodEnd: entry['periodEnd'],
        companyName: entry['companyName'],
      );
      expect(parsed['balanceStates']['CB'], 'verified');
      periods.add({...parsed, 'state': 'ready'});
    }
    final feed = BondTrends.build(periods);
    expect(feed['points'].first['balanceWon'], '25000000000');
    expect(feed['points'].last['balanceWon'], '22700000000');
    expect(feed['points'].last['netDecreaseWon'], '2300000000');
    expect(feed['changes'].first['series'], '제 12회');
    expect(feed['changes'].first['unexplainedDecreaseWon'], '2300000000');
    expect(feed['changes'].first['confirmedConversionWon'], isNull);
    expect(feed['changes'].last['netDecreaseWon'], '0');
  });
}
