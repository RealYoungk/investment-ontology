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
      final type = n is InstanceCreationExpression
          ? n.constructorName.type.name.lexeme
          : n is MethodInvocation
          ? (n.target is SimpleIdentifier
                ? (n.target as SimpleIdentifier).name
                : n.methodName.name)
          : '';
      if (type != 'ShadButton') continue;
      final args = n is InstanceCreationExpression
          ? n.argumentList
          : (n as MethodInvocation).argumentList;
      for (final child in args.arguments.whereType<NamedExpression>().where(
        (x) => x.name.label.name == 'child',
      )) {
        final e = child.expression;
        if (e.toSource().startsWith('Row('))
          edits.add((
            e.offset,
            e.end,
            'Flexible(child: ${s.substring(e.offset, e.end)})',
          ));
      }
    }
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in edits) s = s.replaceRange(e.$1, e.$2, e.$3);
    f.writeAsStringSync(s);
  }
}
