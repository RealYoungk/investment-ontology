import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dated_current_header_proof.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

const expectedCore = <String, Map<String, String>>{
  '20220331002887': {
    'assets': '14175354670',
    'liabilities': '6323150135',
    'equity': '7852204535',
    'revenue': '13512147067',
    'operating': '-923914191',
    'profit': '2849833720',
    'cfo': '-664457202',
  },
  '20230427000895': {
    'assets': '13907201162',
    'liabilities': '6882730233',
    'equity': '7024470929',
    'revenue': '15128062871',
    'operating': '722007194',
    'profit': '-276230202',
    'cfo': '354779988',
  },
  '20220331003444': {
    'assets': '45662358056',
    'liabilities': '40709356991',
    'equity': '4953001065',
    'revenue': '34557425427',
    'operating': '3011651602',
    'profit': '2755379556',
    'cfo': '555856724',
  },
  '20250328002132': {
    'assets': '29858644034',
    'liabilities': '48996225788',
    'equity': '-19137581754',
    'revenue': '513465000',
    'operating': '-5805056459',
    'profit': '-326882498',
    'cfo': '-3966776148',
  },
  '20240320001359': {
    'assets': '5785800111',
    'liabilities': '3309417871',
    'equity': '2476382240',
    'revenue': '476359384',
    'operating': '-4624792871',
    'profit': '-3884183151',
    'cfo': '-2658881374',
  },
  '20240704000080': {
    'assets': '42035972141',
    'liabilities': '25700060987',
    'equity': '16335911154',
    'revenue': '17372009452',
    'operating': '-2628301836',
    'profit': '-2795459101',
    'cfo': '-1897300484',
  },
};
const companyNames = <String, String>{
  '20220331002887': '(주)제이엠멀티',
  '20230427000895': '(주)제이엠멀티',
  '20220331003444': '(주)유진테크놀로지',
  '20250328002132': '주식회사 유엑스엔',
  '20240320001359': '(주)에피바이오텍',
  '20240704000080': '(주)코나솔',
};
String directory(String rc) =>
    'assets/financial_source_cache/$rc-${rc == '20220331003444' ? 'cfs' : 'ofs'}-dated';
Map<String, dynamic> manifest(String rc) =>
    jsonDecode(File('${directory(rc)}/manifest.json').readAsStringSync());
String body(String rc) =>
    File('${directory(rc)}/${rc == '20220331003444' ? 'cfs' : 'ofs'}.html')
        .readAsStringSync();
Map<String, dynamic>? actualProof(
  String rc, {
  String Function(String)? change,
  String? company,
  DateTime? end,
  Uri? source,
  bool? cfs,
}) {
  final m = manifest(rc), src = m['sources'] as List;
  return DatedCurrentHeaderProof.verify(
    coverHtml: File('${directory(rc)}/cover.html').readAsStringSync(),
    statementHtml: change == null ? body(rc) : change(body(rc)),
    coverSource: Uri.parse(src[1]['url']),
    statementSource: source ?? Uri.parse(src[2]['url']),
    receipt: rc,
    companyName: company ?? companyNames[rc]!,
    start: DateTime.utc(m['year']),
    end: end ?? DateTime.utc(m['year'], 12, 31),
    consolidated: cfs ?? m['basis'] == 'consolidated',
  );
}

String replaceLast(String value, String old, String replacement) {
  final at = value.lastIndexOf(old);
  expect(at, greaterThanOrEqualTo(0));
  return value.replaceRange(at, at + old.length, replacement);
}

String changeEquity(String rc, String s, String money) {
  final proof = actualProof(rc)!;
  final tables = RegExp(
    r'<TABLE\b[^>]*>(.*?)</TABLE>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(s).toList();
  final t = tables[proof['equityTableIndex'] as int];
  final replacement = replaceLast(t[0]!, money, '1');
  return s.replaceRange(t.start, t.end, replacement);
}

void main() {
  for (final rc in expectedCore.keys) {
    test('actual $rc independently printed whole7 normal parser', () {
      final p = actualProof(rc);
      expect(p, isNotNull);
      expect(p!['core'], expectedCore[rc]);
      final m = manifest(rc), src = m['sources'] as List;
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: File('${directory(rc)}/cover.html').readAsStringSync(),
        statementHtml: body(rc),
        coverSource: Uri.parse(src[1]['url']),
        statementSource: Uri.parse(src[2]['url']),
        receipt: rc,
        corpCode: m['corpCode'],
        companyName: companyNames[rc]!,
        periodStart: DateTime.utc(m['year']),
        periodEnd: DateTime.utc(m['year'], 12, 31),
        consolidated: m['basis'] == 'consolidated',
      );
      expect(rows.length, greaterThanOrEqualTo(7));
      expect(
        rows.take(7).map((x) => x['thstrm_amount']).toList(),
        expectedCore[rc]!.values.toList(),
      );
      expect(rows.every((x) => x['account_id'] == null), true);
      final proof =
          (rows.first['html_provenance']
                  as Map)['supportingWholeCurrentEvidence']
              as Map;
      expect(proof['statementUri'], src[2]['url']);
      expect(proof['statementSha256'], src[2]['sha256']);
    });
    for (final bad in [
      'issuer',
      'year',
      'receipt',
      'dcm',
      'basis',
      'unit',
      'endDate',
      'wholeNet',
      'wholeEquity',
    ]) {
      test('$rc rejects independent proof $bad', () {
        final m = manifest(rc), uri = Uri.parse(m['sources'][2]['url']);
        final values = expectedCore[rc]!;
        String comma(String v) => v
            .replaceAll('-', '')
            .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
        String change(String s) => switch (bad) {
          'unit' => s.replaceAll('원', 'USD'),
          'endDate' =>
            s
                .replaceAll('${m['year']}년 12월 31일', '${m['year']}년 12월 30일')
                .replaceAll('${m['year']}.12.31', '${m['year']}.12.30'),
          'wholeNet' => changeEquity(rc, s, comma(values['profit']!)),
          'wholeEquity' => changeEquity(rc, s, comma(values['equity']!)),
          _ => s,
        };
        expect(
          actualProof(
            rc,
            change: change,
            company: bad == 'issuer' ? '다른회사' : null,
            end: bad == 'year' ? DateTime.utc(m['year'] - 1, 12, 31) : null,
            cfs: bad == 'basis' ? m['basis'] != 'consolidated' : null,
            source: bad == 'receipt'
                ? uri.replace(
                    queryParameters: {
                      ...uri.queryParameters,
                      'rcpNo': '20260000000000',
                    },
                  )
                : bad == 'dcm'
                ? uri.replace(
                    queryParameters: {...uri.queryParameters, 'dcmNo': '999'},
                  )
                : null,
          ),
          isNull,
          reason: bad,
        );
      });
    }
  }
  for (final rc in [
    '20220331002887',
    '20230427000895',
    '20240320001359',
    '20240704000080',
  ]) {
    test('$rc actual second header term is mandatory', () {
      expect(
        actualProof(
          rc,
          change: (s) => s
              .replaceAll(RegExp(r'제\s*(14|15|9|27)\s*기'), '제99기')
              .replaceAll('>27<', '>99<'),
        ),
        isNull,
      );
    });
  }
  test('CFS current CF two-cell group cannot accept second numeric amount', () {
    const rc = '20220331003444';
    final s = body(rc), at = s.indexOf('555,856,724');
    expect(at, greaterThan(0));
    final before = s.substring(0, at), blank = before.lastIndexOf('<BR/>');
    expect(blank, greaterThan(0));
    expect(
      actualProof(rc, change: (_) => s.replaceRange(blank, blank + 5, '1')),
      isNull,
    );
  });
}
