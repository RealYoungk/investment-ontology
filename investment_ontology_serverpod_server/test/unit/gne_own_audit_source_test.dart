import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/gne_own_audit_source.dart';
import 'package:test/test.dart';

void main() {
  String read(String name) =>
      File('test/fixtures/financial_html/gne-own-audit/$name.html')
          .readAsStringSync();
  final shell = read('shell'),
      cover = read('cover'),
      statement = read('statement');
  List<Map<String, dynamic>> parse({
    String? sh,
    String? co,
    String? st,
    String receipt = GneOwnAuditSource.receipt,
    String corp = GneOwnAuditSource.corp,
    bool cfs = false,
    DateTime? end,
    Uri? uri,
  }) => GneOwnAuditSource.parse(
    shell: sh ?? shell,
    cover: co ?? cover,
    statement: st ?? statement,
    shellSource: Uri.parse(GneOwnAuditSource.shellUri),
    coverSource: Uri.parse(GneOwnAuditSource.coverUri),
    statementSource: uri ?? Uri.parse(GneOwnAuditSource.statementUri),
    sourceReceipt: receipt,
    corpCode: corp,
    periodStart: DateTime.utc(2025),
    periodEnd: end ?? DateTime.utc(2025, 12, 31),
    consolidated: cfs,
  );
  test('own official seven direct rows, same receipt and null XBRL IDs', () {
    final rows = parse();
    expect(rows, hasLength(7));
    expect(rows.map((r) => r['account_id']), everyElement(isNull));
    expect(
      rows.map((r) => r['rcept_no']),
      everyElement(GneOwnAuditSource.receipt),
    );
    expect(rows.map((r) => r['thstrm_amount']), [
      '6973822992',
      '2274518676',
      '4699304316',
      '4896995158',
      '371658968',
      '377901260',
      '701750215',
    ]);
    expect(rows.last['account_nm'], 'Ⅰ.영업활동으로 인한 현금흐름');
  });
  final negatives = <String, void Function()>{
    'no earlier receipt mapping': () => parse(receipt: '20260429000962'),
    'wrong corporate identity': () => parse(corp: '01035942'),
    'CFS not absence inferred': () => parse(cfs: true),
    'wrong actual period': () => parse(end: DateTime.utc(2025, 6, 30)),
    'wrong dcm': () => parse(
      uri: Uri.parse(
        GneOwnAuditSource.statementUri.replaceFirst('11355074', '11354877'),
      ),
    ),
    'shell company mutation': () =>
        parse(sh: shell.replaceAll('01188749', '01035942')),
    'cover date mutation': () => parse(co: cover.replaceAll('2025', '2024')),
    'unit mutation': () => parse(st: statement.replaceAll('단위 : 원', '단위 : 천원')),
    'one won balance mutation': () =>
        parse(st: statement.replaceAll('6,973,822,992', '6,973,822,993')),
    'parent profit replacement': () =>
        parse(st: statement.replaceAll('X. 당기순이익(손실)', '지배기업순이익')),
    'CE period mutation': () =>
        parse(st: statement.replaceAll('2025.12.31', '2024.12.31')),
  };
  for (final n in negatives.entries) {
    test(n.key, () => expect(n.value, throwsFormatException));
  }
}
