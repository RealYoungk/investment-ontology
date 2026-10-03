import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'primitives.dart' show Collector, fields;

void main() {
  for (final f
      in Directory('investment_ontology_serverpod_flutter/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    var s = f.readAsStringSync();
    final c = Collector();
    parseString(content: s, throwIfDiagnostics: false).unit.accept(c);
    final edits = <(int, int, String)>[];
    for (final n in c.calls.whereType<MethodInvocation>()) {
      if (!['showShadDialog', 'showShadSheet'].contains(n.methodName.name))
        continue;
      final a = fields(n.argumentList);
      final b = n.argumentList.arguments
          .whereType<NamedExpression>()
          .where((e) => e.name.label.name == 'builder')
          .firstOrNull;
      if (b == null || b.toSource().contains('InheritedTheme.captureAll'))
        continue;
      edits.add((
        b.expression.offset,
        b.expression.end,
        '(overlayContext) => InheritedTheme.captureAll(${a['context']}, Builder(builder: ${b.expression.toSource()}))',
      ));
    }
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in edits) s = s.replaceRange(e.$1, e.$2, e.$3);
    if (edits.isNotEmpty) f.writeAsStringSync(s);
  }
}
