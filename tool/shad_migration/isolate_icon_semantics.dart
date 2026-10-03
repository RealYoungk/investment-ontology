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
      final type = n is InstanceCreationExpression
          ? n.constructorName.type.name.lexeme
          : n is MethodInvocation
          ? n.methodName.name
          : '';
      if (type != 'Semantics') continue;
      final a = n is InstanceCreationExpression
          ? n.argumentList
          : (n as MethodInvocation).argumentList;
      final named = {
        for (final v in a.arguments.whereType<NamedExpression>())
          v.name.label.name: v.expression,
      };
      if (named.containsKey('container')) continue;
      final child = named['child']?.toSource() ?? '';
      if (child.startsWith('ExcludeSemantics(') &&
          child.contains('ShadIconButton'))
        edits.add(a.leftParenthesis.end);
    }
    edits.sort((a, b) => b.compareTo(a));
    for (final e in edits) s = s.replaceRange(e, e, 'container: true, ');
    f.writeAsStringSync(s);
  }
}
