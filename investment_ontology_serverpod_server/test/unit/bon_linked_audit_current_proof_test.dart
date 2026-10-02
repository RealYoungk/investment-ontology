import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/bon_linked_audit_current_proof.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/linked_correction_audit_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/same_receipt_audit_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  final e = VerifiedAnnualSourceRegistry.find(
    LinkedCorrectionAuditSource.bonTarget,
    FsDiv.separate,
  )!;
  final profile =
      SameReceiptAuditSource.profiles[LinkedCorrectionAuditSource.bonOriginal]!;
  final body = File('${e.assetDirectory}/ofs.html').readAsStringSync();
  final target = File('${e.assetDirectory}/targetOfs.html').readAsStringSync();
  late List<Map<String, dynamic>> rows;
  setUpAll(() async {
    final result = await VerifiedAnnualSourceCache().verifyRegistered(
      filing(e),
      company(e),
      e.basis,
    );
    rows = result.numeric!.rows;
  });
  Map<String, dynamic> verify({
    String? sourceBody,
    String? targetBody,
    String? corpCode,
    String? sourceReceipt,
    bool consolidated = false,
    DateTime? end,
    Uri? source,
    List<Map<String, dynamic>>? changedRows,
  }) => BonLinkedAuditCurrentProof.verify(
    targetReceipt: e.receipt,
    sourceReceipt: sourceReceipt ?? LinkedCorrectionAuditSource.bonOriginal,
    corpCode: corpCode ?? e.corpCode,
    consolidated: consolidated,
    start: DateTime.utc(2025),
    end: end ?? e.periodEnd,
    source: source ?? Uri.parse(profile.statement),
    sourceBody: sourceBody ?? body,
    targetSource: Uri.parse(LinkedCorrectionAuditSource.bonWitnessUri),
    targetBody: targetBody ?? target,
    rows: changedRows ?? rows,
  );
  test('actual audit seven current rows match target without whole statement claim', () {
    final proof = verify();
    expect(proof['matchingDirectAccounts'], hasLength(7));
    expect(proof['allStatementValuesCompared'], false);
    expect(proof['capexTotalAvailable'], false);
    expect(proof['sourceReceipt'], LinkedCorrectionAuditSource.bonOriginal);
    expect(proof['targetReceipt'], e.receipt);
  });
  for (final testCase in <String, void Function()>{
    'wrong corporation': () => verify(corpCode: '01872458'),
    'wrong original receipt': () => verify(sourceReceipt: e.receipt),
    'wrong basis': () => verify(consolidated: true),
    'wrong period': () => verify(end: DateTime.utc(2025, 6, 30)),
    'wrong actual source URL': () =>
        verify(source: Uri.parse('${profile.statement}&changed=1')),
    'target direct amount conflict': () => verify(
      targetBody: target.replaceFirst('9,454,690,182', '9,454,690,183'),
    ),
    'audit CE closing date conflict': () =>
        verify(sourceBody: body.replaceAll('2025.12.31', '2025.06.30')),
    'audit original bytes mismatch': () => verify(sourceBody: '$body '),
    'target original bytes mismatch': () => verify(targetBody: '$target '),
    'unverified extra account': () =>
        verify(changedRows: [...rows, rows.first]),
  }.entries) {
    test(testCase.key, () => expect(testCase.value, throwsFormatException));
  }
}
