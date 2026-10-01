import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/research_feed.dart';

void main() {
  const base = {'date': '2025-01-02', 'stockCode': '005930'};
  test('program net shares keep integer precision above double range', () {
    final rows = ResearchFeed.validate('program', [
      {
        ...base,
        'buyVolume': '9007199254740993',
        'sellVolume': '9007199254740992',
      },
    ]);
    expect(rows.single['netVolume'], '1');
  });
  test('credit and lending require observed nonnegative integer balances', () {
    for (final kind in ['credit', 'lending']) {
      expect(
        ResearchFeed.validate(kind, [
          {...base, 'balanceVolume': '0'},
        ]).single['balanceVolume'],
        '0',
      );
      for (final value in [null, '-1', '1.5']) {
        expect(
          () => ResearchFeed.validate(kind, [
            {...base, 'balanceVolume': value},
          ]),
          throwsFormatException,
        );
      }
    }
  });
  test('same security and date cannot be duplicated or mixed silently', () {
    final row = {...base, 'balanceVolume': '1'};
    expect(
      () => ResearchFeed.validate('credit', [row, row]),
      throwsFormatException,
    );
    expect(
      ResearchFeed.validate('credit', [
        row,
        {...row, 'stockCode': '005935'},
      ]),
      hasLength(2),
    );
  });
}
