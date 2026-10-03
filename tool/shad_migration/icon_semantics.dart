// One-time service call-site compatibility fix; upstream source stays unchanged.
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
      if (type != 'ShadIconButton') continue;
      final args = n is InstanceCreationExpression
          ? n.argumentList
          : (n as MethodInvocation).argumentList;
      final named = {
        for (final a in args.arguments.whereType<NamedExpression>())
          a.name.label.name: a.expression.toSource(),
      };
      if (!named.containsKey('semanticLabel') ||
          !named.containsKey('onPressed'))
        continue;
      final enabled = named['enabled'] ?? 'true';
      final original = s.substring(n.offset, n.end);
      edits.add((
        n.offset,
        n.end,
        'Semantics(label: ${named['semanticLabel']}, button: true, enabled: $enabled, onTap: ($enabled) ? ${named['onPressed']} : null, child: ExcludeSemantics(child: $original))',
      ));
    }
    final leaves = edits
        .where((e) => !edits.any((other) => other.$1 > e.$1 && other.$2 < e.$2))
        .toList();
    leaves.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in leaves) s = s.replaceRange(e.$1, e.$2, e.$3);
    f.writeAsStringSync(s);
  }
}
