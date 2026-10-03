import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'primitives.dart' show Collector;

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
    for (final n in c.calls) {
      final args = n is InstanceCreationExpression
          ? n.argumentList
          : n is MethodInvocation
          ? n.argumentList
          : null;
      if (args == null) continue;
      for (final a in args.arguments.whereType<NamedExpression>()) {
        final e = a.expression;
        if (a.name.label.name == 'onTap' &&
            e is ConditionalExpression &&
            ['true', '(true)'].contains(e.condition.toSource()))
          edits.add((
            e.offset,
            e.end,
            s.substring(e.thenExpression.offset, e.thenExpression.end),
          ));
      }
    }
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in edits) s = s.replaceRange(e.$1, e.$2, e.$3);
    f.writeAsStringSync(s);
  }
}
