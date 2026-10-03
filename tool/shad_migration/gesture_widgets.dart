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
          ? n.methodName.name
          : '';
      if (type != 'InkWell') continue;
      final a = fields(
        n is InstanceCreationExpression
            ? n.argumentList
            : (n as MethodInvocation).argumentList,
      );
      edits.add((
        n.offset,
        n.end,
        "ShadButton.ghost(height: 0, width: double.infinity, padding: EdgeInsets.zero, onPressed: ${a['onTap']}, child: Flexible(child: ${a['child']}))",
      ));
    }
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in edits) s = s.replaceRange(e.$1, e.$2, e.$3);
    f.writeAsStringSync(s);
  }
}
