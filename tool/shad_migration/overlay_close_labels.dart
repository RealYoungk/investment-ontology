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
      if (!['ShadDialog', 'ShadSheet'].contains(type)) continue;
      final a = n is InstanceCreationExpression
          ? n.argumentList
          : (n as MethodInvocation).argumentList;
      if (a.arguments.whereType<NamedExpression>().any(
        (v) => v.name.label.name == 'closeIcon',
      ))
        continue;
      edits.add(a.leftParenthesis.end);
    }
    edits.sort((a, b) => b.compareTo(a));
    for (final e in edits)
      s = s.replaceRange(
        e,
        e,
        "closeIcon: Builder(builder: (context) => Semantics(container: true, label: '닫기', button: true, onTap: () => Navigator.of(context).pop(), child: ExcludeSemantics(child: ShadIconButton.ghost(width: 20, height: 20, padding: EdgeInsets.zero, icon: const Icon(Icons.close, size: 16), onPressed: () => Navigator.of(context).pop())))), ",
      );
    f.writeAsStringSync(s);
  }
}
