import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/koreanre_2021_own_ofs_source.dart';

void main() {
  for (final basis in ['ofs']) {
    final dir =
        'assets/financial_source_cache/20220816002265-$basis-koreanre-current-eight';
    final profile =
        KoreanRe2021OwnOfsSource.profiles[basis] as Map<String, dynamic>;
    final uris = <String, Uri>{
      for (final s in profile['sources'] as List)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    final raw = <String, String>{
      for (final s in profile['sources'] as List)
        s['label'] as String: File('$dir/${s['file']}').readAsStringSync(),
    };
    List<Map<String, dynamic>> parse({
      Map<String, String>? input,
      Map<String, Uri>? links,
      String corp = '00113191',
      String receipt = '20220816002265',
      DateTime? start,
      DateTime? end,
      bool? consolidated,
    }) => KoreanRe2021OwnOfsSource.parse(
      raw: input ?? raw,
      uris: links ?? uris,
      receipt: receipt,
      corp: corp,
      start: start ?? DateTime.utc(2021),
      end: end ?? DateTime.utc(2021, 12, 31),
      consolidated: consolidated ?? (basis == 'cfs'),
    );
    test('$basis actual current8 and separate profit definitions', () {
      final rows = parse();
      expect(rows.length, 8);
      expect(
        rows.map((r) => r['thstrm_amount']),
        [
          '12875853931938',
          '10316477165720',
          '2559376766218',
          '10785912873469',
          '233593137961',
          '177967811055',
          '664417584473',
          '953716675',
        ],
      );
      expect(
        rows[5]['html_provenance']['multiLineProfitDefinitions'],
        profile['profitDefinitions'],
      );
      expect(
        rows[5]['html_provenance']['currentCell'],
        profile['core'][5]['printed'],
      );
      expect(
        rows[5]['html_provenance']['selectedPrintedLine'],
        profile['profitDefinitions']['NI'],
      );
      expect(
        rows.every(
          (r) =>
              r['account_id'] == null &&
              r['ord'] is String &&
              r['fs_div'] == basis.toUpperCase(),
        ),
        true,
      );
      expect(
        rows.every(
          (r) =>
              r['html_provenance']['fullStatementCollected'] == false &&
              r['html_provenance']['notesVerified'] == false,
        ),
        true,
      );
    });
    test(
      '$basis packaged proof unchanged',
      () => expect(
        profile,
        jsonDecode(File('$dir/current-evidence.json').readAsStringSync()),
      ),
    );
    test(
      '$basis changed own current amount rejected',
      () => expect(
        () => parse(
          input: {
            ...raw,
            basis: raw[basis]!
                .replaceFirst('157,856,566,876', '157,856,566,877')
                .replaceFirst('177,967,811,055', '177,967,811,056'),
          },
        ),
        throwsFormatException,
      ),
    );
    test(
      '$basis same-name wrongcorp rejected',
      () => expect(() => parse(corp: '00113190'), throwsFormatException),
    );
    test(
      '$basis wrong own receipt rejected',
      () =>
          expect(() => parse(receipt: '20220816002266'), throwsFormatException),
    );
    test(
      '$basis current year transplanted rejected',
      () => expect(
        () => parse(start: DateTime.utc(2020), end: DateTime.utc(2020, 12, 31)),
        throwsFormatException,
      ),
    );
    test(
      '$basis opposite body cannot be reused',
      () => expect(
        () => parse(consolidated: basis != 'cfs'),
        throwsFormatException,
      ),
    );
    test(
      '$basis source URI changed rejected',
      () => expect(
        () => parse(
          links: {
            ...uris,
            basis: Uri.parse(
              'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220816002266',
            ),
          },
        ),
        throwsFormatException,
      ),
    );
    test(
      '$basis absent raw source rejected',
      () => expect(
        () => parse(input: {...raw}..remove('cover')),
        throwsFormatException,
      ),
    );
  }
}
