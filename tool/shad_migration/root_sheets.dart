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
    final edits = <int>[];
    for (final n in c.calls) {
      if (n is! MethodInvocation || n.methodName.name != 'showShadSheet')
        continue;
      final a = n.argumentList;
      if (a.arguments.whereType<NamedExpression>().any(
        (v) => v.name.label.name == 'useRootNavigator',
      ))
        continue;
      edits.add(a.leftParenthesis.end);
    }
    edits.sort((a, b) => b.compareTo(a));
    for (final e in edits) s = s.replaceRange(e, e, 'useRootNavigator: true, ');
    f.writeAsStringSync(s);
  }
}
