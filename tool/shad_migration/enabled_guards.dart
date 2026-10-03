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
    for (final n in c.calls) {
      final type = n is InstanceCreationExpression
          ? n.constructorName.type.name.lexeme
          : n is MethodInvocation
          ? (n.target is SimpleIdentifier
                ? (n.target as SimpleIdentifier).name
                : n.methodName.name)
          : '';
      if (!['ShadButton', 'ShadIconButton'].contains(type)) continue;
      final args = n is InstanceCreationExpression
          ? n.argumentList
          : (n as MethodInvocation).argumentList;
      final a = fields(args);
      if (a.containsKey('enabled')) continue;
      final on = args.arguments
          .whereType<NamedExpression>()
          .where((e) => e.name.label.name == 'onPressed')
          .firstOrNull
          ?.expression;
      if (on is! ConditionalExpression) continue;
      final enabled = on.thenExpression is NullLiteral
          ? '!(${on.condition.toSource()})'
          : on.elseExpression is NullLiteral
          ? on.condition.toSource()
          : null;
      if (enabled != null)
        edits.add((args.offset + 1, args.offset + 1, 'enabled: $enabled, '));
    }
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in edits) s = s.replaceRange(e.$1, e.$2, e.$3);
    if (edits.isNotEmpty) f.writeAsStringSync(s);
  }
}
