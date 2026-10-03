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
      final args = n is InstanceCreationExpression
          ? n.argumentList
          : n is MethodInvocation
          ? n.argumentList
          : null;
      if (args == null) continue;
      final a = fields(args);
      String? r;
      if (type == 'ChoiceChip')
        r = "ShadToggle.outline(${a['key'] == null ? '' : 'key: ${a['key']},'} value: ${a['selected'] ?? 'false'}, onChanged: ${a['onSelected'] ?? 'null'}, ${a['avatar'] == null ? '' : 'leading: ${a['avatar']},'} child: ${a['label']})";
      if (type == 'Chip') r = "ShadBadge.outline(child: ${a['label']})";
      if (type == 'InputChip') {
        final remove =
            "ShadIconButton.ghost(semanticLabel: ${a['deleteButtonTooltipMessage'] ?? "'Delete'"}, width: 24, height: 24, padding: EdgeInsets.zero, onPressed: ${a['onDeleted']}, icon: const Icon(Icons.close, size: 14))";
        final label = a['onPressed'] == null
            ? a['label']
            : "ShadButton.link(height: 0, padding: EdgeInsets.zero, onPressed: ${a['onPressed']}, child: Flexible(child: ${a['label']}))";
        r = "ShadBadge.outline(child: Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: $label), $remove]))";
      }
      if (type == 'SnackBar')
        r = "ShadToast(description: ${a['content']}, ${a['duration'] == null ? '' : 'duration: ${a['duration']},'} ${a['backgroundColor'] == null ? '' : 'backgroundColor: ${a['backgroundColor']},'})";
      if (r != null) edits.add((n.offset, n.end, r));
    }
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in edits) s = s.replaceRange(e.$1, e.$2, e.$3);
    if (s.contains('ScaffoldMessenger'))
      s = s
          .replaceAll('ScaffoldMessenger', 'ShadToaster')
          .replaceAll('.showSnackBar(', '.show(')
          .replaceAll('..showSnackBar(', '..show(')
          .replaceAll('..hideCurrentSnackBar()', '..hide()');
    if (edits.isNotEmpty) {
      if (!s.contains("package:shad/shad.dart"))
        s = "import 'package:shad/shad.dart';\n$s";
      f.writeAsStringSync(s);
    }
  }
}
