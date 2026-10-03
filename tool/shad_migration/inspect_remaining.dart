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
    final c = Collector();
    parseString(
      content: f.readAsStringSync(),
      throwIfDiagnostics: false,
    ).unit.accept(c);
    for (final n in c.calls) {
      final name = n is InstanceCreationExpression
          ? n.constructorName.type.name.lexeme
          : n is MethodInvocation
          ? n.methodName.name
          : '';
      if ([
        'ExpansionTile',
        'Tooltip',
        'ListTile',
        'PopupMenuButton',
      ].contains(name)) {
        final a = n is InstanceCreationExpression
            ? n.argumentList
            : (n as MethodInvocation).argumentList;
        print(
          '${f.path}: $name ${a.arguments.whereType<NamedExpression>().map((x) => x.name.label.name).join(',')}',
        );
      }
    }
  }
}
