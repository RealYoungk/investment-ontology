import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/samsungsec_2022_own_audit_source.dart';

void main() {
  for (final basis in ['cfs']) {
    final dir =
        'assets/financial_source_cache/20230309000572-$basis-samsungsec-own-audit-current-eight';
    final profile =
        SamsungSec2022OwnAuditSource.profiles[basis] as Map<String, dynamic>;
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
      String corp = '00104856',
      String receipt = '20230309000572',
      DateTime? start,
      DateTime? end,
      bool? consolidated,
    }) => SamsungSec2022OwnAuditSource.parse(
      raw: input ?? raw,
      uris: links ?? uris,
      receipt: receipt,
      corp: corp,
      start: start ?? DateTime.utc(2022),
      end: end ?? DateTime.utc(2022, 12, 31),
      consolidated: consolidated ?? (basis == 'cfs'),
    );
    test(
      '$basis own primary7 and gross note preserve distinct printed precision',
      () {
        final rows = parse();
        expect(rows.length, 8);
        expect(
          rows.map((r) => r['thstrm_amount']),
          [
            '53848261017182',
            '47652352674387',
            '6195908342795',
            '13486895836000',
            '578093894808',
            '422405108435',
            '7436435916241',
            '14057193562',
          ],
        );
        expect(rows[3]['html_provenance']['printedUnit'], '천원');
        expect(rows[3]['html_provenance']['precisionUnit'], '1000');
        expect(rows[3]['html_provenance']['currentCell'], '13,486,895,836');
        expect(rows[3]['html_provenance']['printedPhysicalLabel'], '소계');
        expect(rows[3]['html_provenance']['printedCategory'], '영업수익');
        expect(rows[4]['html_provenance']['precisionUnit'], '1');
        expect(rows[4]['thstrm_amount'], '578093894808');
        expect(
          profile['scopeProof']['sourceDiscrepancies'][1]['differenceWon'],
          808,
        );
        expect(raw['main']!.contains('2021년'), true);
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
      },
    );
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
                .replaceFirst('422,405,108,435', '422,405,108,436')
                .replaceFirst('175,248,933,538', '175,248,933,539'),
          },
        ),
        throwsFormatException,
      ),
    );
    test(
      '$basis same-name wrongcorp rejected',
      () => expect(() => parse(corp: '00104855'), throwsFormatException),
    );
    test(
      '$basis wrong own receipt rejected',
      () =>
          expect(() => parse(receipt: '20230309000573'), throwsFormatException),
    );
    test(
      '$basis current year transplanted rejected',
      () => expect(
        () => parse(start: DateTime.utc(2021), end: DateTime.utc(2021, 12, 31)),
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
              'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230309000573',
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
    test(
      'own gross note amount changed rejected',
      () => expect(
        () => parse(
          input: {
            ...raw,
            'cfs': raw['cfs']!.replaceFirst('13,486,895,836', '13,486,895,837'),
          },
        ),
        throwsFormatException,
      ),
    );
    test(
      'own gross note unit changed rejected',
      () => expect(
        () => parse(
          input: {
            ...raw,
            'cfs': (() {
              final cell = RegExp(
                r'<table\b[^>]*>([\s\S]*?)</table>',
                caseSensitive: false,
              ).allMatches(raw['cfs']!).elementAt(206);
              return raw['cfs']!.replaceRange(
                cell.start,
                cell.end,
                cell.group(0)!.replaceFirst('천원', '원'),
              );
            })(),
          },
        ),
        throwsFormatException,
      ),
    );
    test(
      'own attachment shell missing rejected',
      () => expect(
        () => parse(input: {...raw}..remove('auditShell')),
        throwsFormatException,
      ),
    );
  }
}
