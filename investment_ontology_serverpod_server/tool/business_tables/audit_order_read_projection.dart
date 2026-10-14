import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/stored_order_fact_projection.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3 && args.length != 4) {
    stderr.writeln(
      'Usage: AUDIT_JSON CORPUS_JSONL OUTPUT_JSON [ALL_SNAPSHOT_DIR]',
    );
    exitCode = 64;
    return;
  }
  final audit =
      jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  var selected = (audit['findings'] as List)
      .cast<Map<String, dynamic>>()
      .where(
        (r) =>
            r['computedCheck'] == 'unresolvedSourceValue' &&
            (r['fact']['kind'] as String).startsWith('order'),
      )
      .toList();
  if (args.length == 4) {
    final unique = <String, Map<String, dynamic>>{};
    for (final directory in Directory(
      args[3],
    ).listSync().whereType<Directory>()) {
      final file = File('${directory.path}/snapshot.json');
      if (!file.existsSync()) continue;
      final snapshot =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final raw
          in (snapshot['disclosure/factTrends'] as List? ?? const [])) {
        final fact = raw as Map<String, dynamic>;
        if (!(fact['kind'] as String).startsWith('order') ||
            fact['extractedBy'] != 'api') {
          continue;
        }
        final key =
            fact['id']?.toString() ??
            '${fact['documentId']}|${fact['kind']}|${fact['label']}|${fact['value']}';
        unique[key] = {
          'corpCode': snapshot['company']['corpCode'],
          'fact': fact,
        };
      }
    }
    selected = unique.values.toList();
  }
  final ids = selected.map((r) => r['fact']['documentId']).toSet();
  final docs = <int, Map<String, dynamic>>{};
  await for (final line in File(
    args[1],
  ).openRead().transform(utf8.decoder).transform(const LineSplitter())) {
    final d = jsonDecode(line) as Map<String, dynamic>;
    if (ids.contains(d['documentId'])) docs[d['documentId'] as int] = d;
  }
  final results = <Map<String, dynamic>>[];
  final counts = <String, int>{};
  final rowCache = <int, List<OrderFactSourceRow>>{};
  final componentCache = <int, List<OrderFactSourceRow>>{};
  final rejectedCache = <int, Set<String>>{};
  final ambiguousCache = <int, Set<String>>{};
  final printedCache = <int, Map<String, OrderFactPrintedValues>>{};
  for (final finding in selected) {
    final fact = DocumentFact.fromJson(finding['fact'] as Map<String, dynamic>);
    final doc = docs[fact.documentId];
    var status = 'source_missing_retained_unresolved',
        reason = 'No active source; not classified as incorrect.';
    double? projected;
    if (doc != null) {
      final text = doc['text'] as String;
      if (!rowCache.containsKey(fact.documentId)) {
        final rejected = <String>{};
        final components = <OrderFactSourceRow>[];
        final ambiguous = <String>{};
        final printed = <String, OrderFactPrintedValues>{};
        rowCache[fact.documentId] = OrderFacts.parse(
          text,
          rejectedEvidence: rejected,
          verifiedRows: components,
          ambiguousEvidence: ambiguous,
          printedValues: printed,
        );
        componentCache[fact.documentId] = components;
        rejectedCache[fact.documentId] = rejected;
        ambiguousCache[fact.documentId] = ambiguous;
        printedCache[fact.documentId] = printed;
      }
      final rows = rowCache[fact.documentId]!;
      final components = componentCache[fact.documentId]!;
      var matches = rows
          .where((r) => r.evidence == fact.evidence.trim())
          .toList();
      if (matches.isEmpty) {
        matches = components
            .where((r) => r.evidence == fact.evidence.trim())
            .toList();
      }
      final output = matches.length == 1
          ? [fact]
          : StoredOrderFactProjection.revalidate(
              [fact],
              text,
              companyName: doc['name'] as String?,
            );
      if (matches.length == 1) {
        final r = matches.single;
        projected = switch (fact.kind) {
          DocumentFactKind.orderTotal => r.total,
          DocumentFactKind.orderDelivered => r.delivered,
          _ => r.backlog,
        };
        status = (projected - fact.value).abs() < 0.001 && r.unit == fact.unit
            ? 'source_equation_confirmed'
            : 'corrected_header_selected_amount';
        reason =
            'Header-selected ${r.total} - ${r.delivered} ≈ signed ${r.backlog} (${r.unit}); residual ${r.total - r.delivered - r.backlog}, existing 0.5% tolerance; quantity/FX excluded.';
      } else if (matches.length > 1 &&
          output.length == 1 &&
          (output.single.reviewedBy ?? '').contains('현재 금액 열 및 수주 차감식 재검산')) {
        projected = output.single.value;
        status = 'equivalent_source_proofs_confirmed';
        reason = output.single.reviewNote ?? '';
      } else if (output.isEmpty) {
        final literal = printedCache[fact.documentId]![fact.evidence.trim()];
        if (ambiguousCache[fact.documentId]!.contains(fact.evidence.trim())) {
          status = 'currency_quantity_columns_ambiguous_raw_only';
          reason = 'Amount column role cannot be proven; raw source retained without scalar monetary measure.';
        } else if (literal != null) {
          final sourceValue = switch (fact.kind) {
            DocumentFactKind.orderTotal => literal.total,
            DocumentFactKind.orderDelivered => literal.delivered?.abs(),
            _ => literal.backlog,
          };
          if (sourceValue == null) {
            status = 'missing_or_derived_component_source_only';
            reason = 'Component is missing or a derived flow total; no disclosed scalar is asserted. Explicit remaining monetary cells stay source-only.';
          } else if ((sourceValue - fact.value).abs() < 0.001 &&
              literal.unit == fact.unit) {
            status =
                'cash_literal_confirmed_equation_unverified_source_observation';
            reason = 'Stored amount matches the explicit cash column, but equation fails. Kept in source-only insight, not arithmetic-verified fact.';
          } else {
            status =
                'cash_column_mismatch_equation_unverified_source_observation';
            reason =
                'Stored amount differs from named cash column ($sourceValue ${literal.unit}); raw monetary observations retained, verified fact withheld.';
          }
        } else {
          status = 'withheld_invalid_scalar_or_equation_no_cash_proof';
          reason = 'Strict supported scalar/equation proof absent; raw source remains available. Not a claim that all historical evidence is false.';
        }
      } else {
        status = 'retained_unresolved_source_shape';
        reason = text.contains(fact.evidence)
            ? 'Source evidence present but current parser does not uniquely support this shape; prior value retained with current-recheck-unconfirmed annotation.'
            : 'Evidence absent/composed in current active text; prior value retained unresolved, not newly confirmed.';
        final amount = RegExp(r'(\d[\d,]*)조\s*(\d[\d,]*)억\s*원')
            .allMatches(fact.evidence)
            .toList();
        final index = fact.kind == DocumentFactKind.orderTotal
            ? 0
            : fact.kind == DocumentFactKind.orderBacklog
            ? amount.length - 1
            : -1;
        if (index >= 0 &&
            index < amount.length &&
            {'백만원', '억원'}.contains(fact.unit) &&
            text.contains(fact.evidence)) {
          final m = amount[index];
          final value =
              (double.parse(m.group(1)!.replaceAll(',', '')) * 10000 +
                  double.parse(m.group(2)!.replaceAll(',', ''))) *
              (fact.unit == '백만원' ? 100 : 1);
          if ((value - fact.value).abs() < 0.001) {
            status = 'explicit_korean_currency_scale_confirmed';
            reason =
                '${m.group(0)} = $value ${fact.unit}; existing amount valid, DB unchanged.';
          }
        }
      }
    }
    counts[status] = (counts[status] ?? 0) + 1;
    results.add({
      'corpCode': finding['corpCode'],
      'name': doc?['name'],
      'documentId': fact.documentId,
      'sourceReceipt': doc?['receipt'],
      'factId': fact.id,
      'kind': fact.kind.name,
      'storedValue': fact.value,
      'unit': fact.unit,
      'classification': status,
      'projectedValue': projected,
      'reason': reason,
      'evidence': fact.evidence,
      'explicitSourceScope': doc == null
          ? null
          : StoredOrderFactProjection.explicitScope(
              doc['text'] as String,
              fact.evidence.trim(),
              companyName: doc['name'] as String?,
            ),
      'sourceEvidencePresent':
          doc != null && (doc['text'] as String).contains(fact.evidence),
    });
  }
  File(args[2]).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'selectedFacts': selected.length,
      'scope': args.length == 4
          ? 'all_public_snapshot_primary_order_facts'
          : '54_previously_unresolved_findings',
      'counts': counts,
      'results': results,
    }),
  );
  stdout.writeln(jsonEncode(counts));
}
