import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class Unwrap extends RecursiveAstVisitor<void> {
  final edits = <(int, int, String)>[];
  void call(AstNode node, String name, ArgumentList args) {
    if (name != 'ShadInputAccessibility') return;
    final child = args.arguments
        .whereType<NamedExpression>()
        .firstWhere((x) => x.name.label.name == 'child')
        .expression;
    edits.add((node.offset, node.end, child.toSource()));
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression n) {
    call(n, n.constructorName.type.name.lexeme, n.argumentList);
    super.visitInstanceCreationExpression(n);
  }

  @override
  void visitMethodInvocation(MethodInvocation n) {
    call(n, n.methodName.name, n.argumentList);
    super.visitMethodInvocation(n);
  }
}

void main() {
  for (final directory in [
    'investment_ontology_serverpod_flutter/lib',
    'investment_ontology_serverpod_flutter/test',
    'examples/shad_review/lib',
  ]) {
    for (final f
        in Directory(directory)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      var s = f.readAsStringSync();
      final v = Unwrap();
      parseString(content: s, throwIfDiagnostics: false).unit.accept(v);
      v.edits.sort((a, b) => b.$1.compareTo(a.$1));
      for (final e in v.edits) s = s.replaceRange(e.$1, e.$2, e.$3);
      s = s
          .replaceAll(
            RegExp(
              r"import '[^']*(?:shad_input_accessibility|shad_support)[^']*';\n",
            ),
            '',
          )
          .replaceAll(
            'find.byType(ShadInputAccessibility)',
            'find.byType(ShadInput)',
          );
      f.writeAsStringSync(s);
    }
  }
}
