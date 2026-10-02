import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dated_current_header_proof.dart';
import 'package:test/test.dart';

const root = 'test/fixtures/financial_html/dated-current-header';
Map<String, dynamic>? proof(
  String receipt,
  bool cfs, {
  String Function(String)? changeBody,
  String? name,
  Uri? source,
  DateTime? start,
  DateTime? end,
}) {
  final p = jsonDecode(File('$root/$receipt/proof.json').readAsStringSync());
  Uri url(String label) => Uri.parse(
    (p['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
  );
  final body = File('$root/$receipt/${cfs ? 'cfs' : 'ofs'}.html')
      .readAsStringSync();
  return DatedCurrentHeaderProof.verify(
    coverHtml: File('$root/$receipt/cover.html').readAsStringSync(),
    statementHtml: changeBody == null ? body : changeBody(body),
    coverSource: url('cover'),
    statementSource: source ?? url(cfs ? 'cfs' : 'ofs'),
    receipt: receipt,
    companyName: name ?? p['name'],
    start: start ?? DateTime.utc(2025),
    end: end ?? DateTime.utc(2025, 12, 31),
    consolidated: cfs,
  );
}

String replaceLast(String s, String from, String to) {
  final at = s.lastIndexOf(from);
  expect(at, greaterThanOrEqualTo(0));
  return s.replaceRange(at, at + from.length, to);
}

void main() {
  for (final receipt in ['20260323000759', '20260330001644']) {
    for (final cfs in [true, false]) {
      test(
        'actual $receipt ${cfs ? 'CFS' : 'OFS'} dated headers match independent whole CE totals',
        () {
          final p = proof(receipt, cfs);
          expect(p, isNotNull);
          expect((p!['core'] as Map).length, 7);
          final core = p['core'] as Map;
          expect(
            BigInt.parse(core['assets']),
            BigInt.parse(core['liabilities']) + BigInt.parse(core['equity']),
          );
          final bytes = File('$root/$receipt/${cfs ? 'cfs' : 'ofs'}.html')
              .readAsBytesSync();
          expect(p['statementSha256'], sha256.convert(bytes).toString());
          if (receipt == '20260330001644' && cfs) {
            expect(
              core['profit'],
              '-4599586',
              reason: '지배기업105271578이나 비지배-109871164로 대체하지 않음',
            );
            expect(core['equity'], '-11081347051');
          }
        },
      );
    }
  }
  test(
    'CE section heading must be literal one full-width cell with no money',
    () {
      final mutations = [
        (String s) =>
            s.replaceFirst("colspan='7'>총포괄이익:", "colspan='6'>총포괄이익:"),
        (String s) => s.replaceFirst(
          "colspan='7'>총포괄이익:&nbsp;</TD>",
          "colspan='7'>총포괄이익:</TD><TD>추가절</TD>",
        ),
        (String s) =>
            s.replaceFirst("colspan='7'>총포괄이익:&nbsp;", "colspan='7'>총포괄이익:123"),
        (String s) => s.replaceFirst(
          "colspan='7'>총포괄이익:&nbsp;",
          "colspan='7'>다른절:&nbsp;",
        ),
      ];
      for (final mutation in mutations) {
        expect(proof('20260323000759', true, changeBody: mutation), isNull);
      }
    },
  );
  test(
    'actual Pandora OFS title27 vs current table26 conflict remains rejected',
    () => expect(proof('20260323001293', false), isNull),
  );
  test(
    'different issuer does not receive a caller-trusted header proof',
    () => expect(proof('20260330001644', false, name: '다른회사'), isNull),
  );
  test(
    'different annual period is rejected',
    () => expect(
      proof('20260330001644', false, end: DateTime.utc(2024, 12, 31)),
      isNull,
    ),
  );
  test(
    'CFS body cannot supply an OFS proof',
    () => expect(
      proof(
        '20260330001644',
        false,
        changeBody: (_) =>
            File('$root/20260330001644/cfs.html').readAsStringSync(),
      ),
      isNull,
    ),
  );
  test('source receipt, dcm and foreign host are bound', () {
    final p = jsonDecode(
      File('$root/20260330001644/proof.json').readAsStringSync(),
    );
    final uri = Uri.parse(
      (p['sources'] as List).singleWhere((s) => s['label'] == 'ofs')['url'],
    );
    for (final bad in [
      uri.replace(host: 'example.org'),
      uri.replace(
        queryParameters: {...uri.queryParameters, 'rcpNo': '20260323000759'},
      ),
      uri.replace(queryParameters: {...uri.queryParameters, 'dcmNo': '1'}),
    ]) {
      expect(proof('20260330001644', false, source: bad), isNull);
    }
  });
  test('wrong current primary term or fully printed date is rejected', () {
    expect(
      proof(
        '20260330001644',
        false,
        changeBody: (s) => s.replaceFirst('제 26(당)기말', '제 25(당)기말'),
      ),
      isNull,
    );
    expect(
      proof(
        '20260330001644',
        false,
        changeBody: (s) =>
            s.replaceFirst('2025년 12월 31일 현재', '2024년 12월 31일 현재'),
      ),
      isNull,
    );
  });
  test('duplicate current column and oversized span fail closed', () {
    expect(
      proof(
        '20260330001644',
        true,
        changeBody: (s) => s.replaceFirstMapped(
          RegExp(r'(<TH\b[^>]*>)전기말.*?</TH>', dotAll: true),
          (m) => '${m[1]}당기말</TH>',
        ),
      ),
      isNull,
    );
    expect(
      proof(
        '20260330001644',
        true,
        changeBody: (s) => s.replaceFirst(
          '>30,824,548,545</TD>',
          " colspan='20'>30,824,548,545</TD>",
        ),
      ),
      isNull,
    );
  });
  test(
    'one-won BS mismatch, CE net mismatch and parent substitution reject',
    () {
      expect(
        proof(
          '20260330001644',
          true,
          changeBody: (s) => s.replaceFirst('30,824,548,545', '30,824,548,546'),
        ),
        isNull,
      );
      expect(
        proof(
          '20260330001644',
          true,
          changeBody: (s) => replaceLast(s, '(4,599,586)', '(4,599,587)'),
        ),
        isNull,
      );
      expect(
        proof(
          '20260330001644',
          true,
          changeBody: (s) => replaceLast(s, '(4,599,586)', '105,271,578'),
        ),
        isNull,
      );
    },
  );
  test(
    'whole CE total cannot be relabeled as a parent total',
    () => expect(
      proof(
        '20260330001644',
        true,
        changeBody: (s) => s.replaceAll('총 계', '지배기업'),
      ),
      isNull,
    ),
  );
  test(
    'different units across CE/primary do not pass amount crosschecks',
    () => expect(
      proof(
        '20260330001644',
        false,
        changeBody: (s) => s.replaceFirst('(단위: 원)', '(단위: 천원)'),
      ),
      isNull,
    ),
  );
}
