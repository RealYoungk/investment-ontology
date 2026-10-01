import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/peers/discovery_taxonomy.dart';

void main() {
  test('longest prefix separates holdings, semiconductors and software', () {
    for (final entry in {
      '64992': 'holdings',
      '649': 'finance',
      '29271': 'semiconductor',
      '29272': 'machinery',
      '261': 'semiconductor',
      '262': 'electronics',
      '58221': 'software',
      '581': 'content',
      '313': 'aerospace',
      '311': 'shipbuilding',
      '721': 'research',
      '212': 'pharma',
      '70113': 'pharma',
      '21301': 'medical',
      '28519': 'electronics',
    }.entries) {
      expect(DiscoveryTaxonomy.category(entry.key).$1, entry.value);
    }
    expect(DiscoveryTaxonomy.category(null).$1, 'unclassified');
    expect(DiscoveryTaxonomy.category('invalid').$1, 'unclassified');
  });
  test(
    'all numerical official codes in both revisions have a navigation category',
    () {
      for (final revision in [10, 11]) {
        final rows =
            (jsonDecode(
                  File('assets/ksic/ksic_$revision.json').readAsStringSync(),
                ) as Map)['items']
                as List;
        final missing = [
          for (final row in rows)
            if ((row['level'] as int) >= 2 &&
                DiscoveryTaxonomy.category(row['code']).$1 == 'unclassified')
              row['code'],
        ];
        expect(missing, isEmpty, reason: 'KSIC $revision');
      }
    },
  );
}
