import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/sk_signet_identity.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';

void main() {
  String raw(String label) =>
      File('${SkSignetIdentity.directory}/$label.html').readAsStringSync();
  List<Map<String, dynamic>> parse({
    String? overview,
    String? shell,
    String receipt = SkSignetIdentity.receipt,
    String corp = SkSignetIdentity.corpCode,
    bool cfs = false,
    DateTime? end,
    Uri? overviewUri,
  }) => PublicFinancialHtml.parseStandardAnnual(
    coverHtml: raw('cover'),
    statementHtml: raw('ofs'),
    coverSource: Uri.parse(SkSignetIdentity.urls['cover']!),
    statementSource: Uri.parse(SkSignetIdentity.urls['ofs']!),
    receipt: receipt,
    corpCode: corp,
    companyName: 'SK시그넷 주식회사',
    periodStart: DateTime.utc(2024),
    periodEnd: end ?? DateTime.utc(2024, 12, 31),
    consolidated: cfs,
    skSignetIdentity: SkSignetIdentity(
      shell: shell ?? raw('shell'),
      overview: overview ?? raw('overview'),
      overviewSource:
          overviewUri ?? Uri.parse(SkSignetIdentity.urls['overview']!),
    ),
  );
  test(
    'official whole source retains actual labels and direct rename proof',
    () {
      final rows = parse();
      expect(rows.length, 8);
      expect(rows.every((r) => r['account_id'] == null), true);
      for (final row in rows) {
        final p =
            (row['html_provenance'] as Map)['issuerIdentityEvidence'] as Map;
        expect(p['completedDate'], '2022-03-30');
        expect(p['printedCoverName'], '에스케이시그넷 주식회사');
        expect(p['printedStatementName'], 'SK시그넷 주식회사');
      }
    },
  );
  for (final change in <String, String>{
    'future': '변경할 예정입니다.',
    'another subject': '종속회사는',
    'different month': '2022.04',
    'different predecessor': '시그넷다른회사',
    'duplicate': 'SK시그넷(주) SK시그넷(주)',
  }.entries) {
    test('reject altered ${change.key} direct evidence', () {
      var text = raw('overview');
      text = switch (change.key) {
        'future' => text.replaceAll('변경하였습니다.', change.value),
        'another subject' => text.replaceAll('당사는', change.value),
        'different month' => text.replaceAll('2022.03', change.value),
        'different predecessor' => text.replaceAll('시그넷이브이', change.value),
        _ => text.replaceAll('SK시그넷(주)', change.value),
      };
      expect(text, isNot(raw('overview')));
      expect(() => parse(overview: text), throwsFormatException);
    });
  }
  test('owner, receipt, basis, period and coordinates are strict', () {
    expect(() => parse(corp: '00126380'), throwsFormatException);
    expect(() => parse(receipt: '20250320001634'), throwsFormatException);
    expect(() => parse(cfs: true), throwsFormatException);
    expect(() => parse(end: DateTime.utc(2023, 12, 31)), throwsFormatException);
    expect(
      () => parse(
        overviewUri: Uri.parse(SkSignetIdentity.urls['overview']!)
            .replace(query: 'rcpNo=20250320001633'),
      ),
      throwsFormatException,
    );
    expect(
      () => parse(shell: raw('shell').replaceAll('01188730', '00126380')),
      throwsFormatException,
    );
  });
}
