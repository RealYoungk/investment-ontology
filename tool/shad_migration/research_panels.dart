// One-time reform: only neutral research containers, never chart marks or state fills.
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class Calls extends RecursiveAstVisitor<void> {
  final nodes = <(AstNode, ArgumentList)>[];
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression n) {
    if (n.constructorName.type.name.lexeme == 'Container')
      nodes.add((n, n.argumentList));
    super.visitInstanceCreationExpression(n);
  }

  @override
  void visitMethodInvocation(MethodInvocation n) {
    if (n.target == null && n.methodName.name == 'Container')
      nodes.add((n, n.argumentList));
    super.visitMethodInvocation(n);
  }
}

void main(List<String> args) {
  final apply = args.contains('--apply');
  final records = <Map<String, Object?>>[];
  for (final file
      in Directory('investment_ontology_serverpod_flutter/lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    var source = file.readAsStringSync();
    final calls = Calls();
    parseString(content: source).unit.accept(calls);
    final edits = <(int, int, String)>[];
    for (final (node, list) in calls.nodes.reversed) {
      final fields = {
        for (final a in list.arguments.whereType<NamedExpression>())
          a.name.label.name: a.expression,
      };
      if (fields.keys.any(
        (k) => ![
          'child',
          'key',
          'width',
          'padding',
          'margin',
          'decoration',
        ].contains(k),
      ))
        continue;
      if (fields['padding']?.toSource().contains('EdgeInsets.symmetric') ??
          false)
        continue;
      if (fields['width'] != null &&
          fields['width']!.toSource() != 'double.infinity')
        continue;
      final deco = fields['decoration'];
      if (deco == null || fields['child'] == null) continue;
      final dl = deco is InstanceCreationExpression
          ? deco.argumentList
          : deco is MethodInvocation
          ? deco.argumentList
          : null;
      if (dl == null) continue;
      final d = {
        for (final a in dl.arguments.whereType<NamedExpression>())
          a.name.label.name: a.expression.toSource(),
      };
      if (d.keys.any((k) => !['color', 'border', 'borderRadius'].contains(k)))
        continue;
      if (d['color'] != null &&
          ![
            'c.surface',
            'context.colors.surface',
            'colors.surface',
          ].contains(d['color']))
        continue;
      if (d['border'] != null &&
          !RegExp(r'^Border.all\(color: (c|context.colors|colors).border,?\)$')
              .hasMatch(d['border']!))
        continue;
      if (d['color'] == null && d['border'] == null) continue;
      if (edits.any((e) => node.offset < e.$2 && node.end > e.$1)) continue;
      var replacement =
          'DataPanel(${fields['key'] == null ? '' : 'key: ${fields['key']!.toSource()}, '}child: ${fields['child']!.toSource()})';
      if (fields['margin'] != null)
        replacement =
            'Padding(padding: ${fields['margin']!.toSource()}, child: $replacement)';
      records.add({
        'file': file.path,
        'line': source.substring(0, node.offset).split('\n').length,
        'original': node.toSource().split('child:').first,
        'nestedBlocksPreserved': true,
      });
      edits.add((node.offset, node.end, replacement));
    }
    if (apply && edits.isNotEmpty) {
      edits.sort((a, b) => b.$1.compareTo(a.$1));
      for (final e in edits) source = source.replaceRange(e.$1, e.$2, e.$3);
      if (!source.contains(
            "import '../../design/components/components.dart';",
          ) &&
          !source.contains(
            "import '../../../design/components/components.dart';",
          ) &&
          !source.contains("import '../../design/components/data_panel.dart';"))
        source =
            "import 'package:investment_ontology_serverpod_flutter/design/components/data_panel.dart';\n$source";
      file.writeAsStringSync(source);
    }
  }
  File('outputs/design/reform/neutral-panels${apply ? '-applied' : ''}.json')
      .writeAsStringSync(JsonEncoder.withIndent('  ').convert(records));
  print(
    '${records.length} neutral research containers ${apply ? 'migrated' : 'identified'}.',
  );
}
