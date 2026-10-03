import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/capital_structure_card.dart';

void main() {
  test('complete actual CB/BW quantities exclude EB and other classes', () {
    final data = <String, dynamic>{
      'state': 'ready',
      'states': {'CB': 'verified', 'BW': 'none', 'EB': 'missing'},
      'entries': [
        {
          'type': 'CB',
          'stockKind': '보통주',
          'shares': '200',
          'validation': 'verified',
        },
        {
          'type': 'CB',
          'stockKind': '우선주',
          'shares': '50',
          'validation': 'verified',
        },
        {
          'type': 'EB',
          'stockKind': '보통주',
          'shares': '900',
          'validation': 'verified',
        },
      ],
    };
    expect(disclosedNewShares(data, '보통주'), BigInt.from(200));
    expect(disclosedNewShares(data, '우선주'), BigInt.from(50));
    data['states'] = {'CB': 'verified', 'BW': 'missing'};
    expect(disclosedNewShares(data, '보통주'), isNull);
    data['states'] = {'CB': 'partial', 'BW': 'none'};
    expect(disclosedNewShares(data, '보통주'), isNull);
  });
  test(
    'only explicit absence supports zero and unknown classes block maximum',
    () {
      expect(
        disclosedNewShares({
          'state': 'ready',
          'states': {'CB': 'none', 'BW': 'none'},
          'entries': [],
        }, '보통주'),
        BigInt.zero,
      );
      expect(disclosedNewShares(null, '보통주'), isNull);
      expect(
        disclosedNewShares({
          'state': 'ready',
          'states': {'CB': 'verified', 'BW': 'none'},
          'entries': [
            {
              'type': 'CB',
              'stockKind': '미확인',
              'shares': '200',
              'validation': 'verified',
            },
          ],
        }, '보통주'),
        isNull,
      );
    },
  );
  test('maximum dilution uses actual new shares over fully diluted shares', () {
    expect(
      maximumOwnershipDilution(BigInt.from(1000), BigInt.from(200)),
      closeTo(16.666667, 0.000001),
    );
    expect(maximumOwnershipDilution(BigInt.from(1000), BigInt.zero), 0);
    expect(maximumOwnershipDilution(null, BigInt.from(200)), isNull);
    expect(maximumOwnershipDilution(BigInt.zero, BigInt.from(200)), isNull);
    expect(maximumOwnershipDilution(BigInt.from(1000), null), isNull);
  });
}
