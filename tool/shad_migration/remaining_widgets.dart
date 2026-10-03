import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'primitives.dart' show Collector;

String name(AstNode n) => n is InstanceCreationExpression
    ? n.constructorName.type.name.lexeme
    : n is MethodInvocation
    ? n.methodName.name
    : '';
ArgumentList args(AstNode n) => n is InstanceCreationExpression
    ? n.argumentList
    : (n as MethodInvocation).argumentList;
void main() {
  for (final f
      in Directory('investment_ontology_serverpod_flutter/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    var s = f.readAsStringSync();
    var changed = false;
    while (true) {
      final c = Collector();
      parseString(content: s, throwIfDiagnostics: false).unit.accept(c);
      final calls = c.calls
          .where(
            (n) => ['ExpansionTile', 'Tooltip', 'ListTile'].contains(name(n)),
          )
          .toList();
      if (calls.isEmpty) break;
      final edits = <(int, int, String)>[];
      for (final n in calls) {
        if (calls.any((o) => o.offset > n.offset && o.end < n.end)) continue;
        final a = {
          for (final x in args(n).arguments.whereType<NamedExpression>())
            x.name.label.name: x.expression.toSource(),
        };
        String r;
        if (name(n) == 'Tooltip') {
          r = "ShadTooltip(${a['key'] == null ? '' : 'key: ${a['key']},'} ${a['waitDuration'] == null ? '' : 'waitDuration: ${a['waitDuration']},'} ${a['showDuration'] == null ? '' : 'showDuration: ${a['showDuration']},'} builder: (_) => Text(${a['message']}), child: Semantics(tooltip: ${a['message']}, child: ${a['child']}))";
        } else if (name(n) == 'ExpansionTile') {
          var title = a['title']!;
          if (a['subtitle'] != null)
            title =
                'Column(crossAxisAlignment: CrossAxisAlignment.start, children: [$title, ${a['subtitle']}])';
          if (a['leading'] != null)
            title =
                'Row(children: [${a['leading']}, const SizedBox(width: AppSpace.sm), Expanded(child: $title)])';
          var child =
              'Column(crossAxisAlignment: ${a['expandedCrossAxisAlignment'] ?? 'CrossAxisAlignment.start'}, children: ${a['children'] ?? 'const <Widget>[]'})';
          if (a['childrenPadding'] != null)
            child = 'Padding(padding: ${a['childrenPadding']}, child: $child)';
          r = "ShadAccordion<int>(${a['key'] == null ? '' : 'key: ${a['key']},'} maintainState: ${a['maintainState'] ?? 'true'}, initialValue: (${a['initiallyExpanded'] ?? 'false'}) ? 0 : null, children: [ShadAccordionItem<int>(value: 0, title: $title, ${a['tilePadding'] == null ? '' : 'padding: ${a['tilePadding']},'} child: $child)])";
        } else {
          var title = a['title'] ?? 'const SizedBox.shrink()';
          if (a['subtitle'] != null)
            title =
                'Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [$title, ${a['subtitle']}])';
          r = "Row(children: [${a['leading'] == null ? '' : '${a['leading']}, const SizedBox(width: AppSpace.sm),'} Expanded(child: $title), ${a['trailing'] == null ? '' : 'const SizedBox(width: AppSpace.sm), ${a['trailing']},'}])";
          if (a['onTap'] != null) {
            r = "ShadButton.ghost(${a['key'] == null ? '' : 'key: ${a['key']},'} width: double.infinity, height: null, padding: ${a['contentPadding'] ?? 'const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm)'}, onPressed: ${a['onTap']}, child: $r)";
            if (a['selected'] != null)
              r = 'Semantics(selected: ${a['selected']}, child: DecoratedBox(decoration: BoxDecoration(color: (${a['selected']}) ? ${a['selectedTileColor'] ?? 'context.colors.surfaceHover'} : null), child: $r))';
          } else
            r = "Padding(${a['key'] == null ? '' : 'key: ${a['key']},'} padding: ${a['contentPadding'] ?? 'const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm)'}, child: $r)";
        }
        edits.add((n.offset, n.end, r));
      }
      edits.sort((a, b) => b.$1.compareTo(a.$1));
      for (final e in edits) s = s.replaceRange(e.$1, e.$2, e.$3);
      changed = true;
    }
    if (changed) {
      if (!s.contains("package:shad/shad.dart"))
        s = "import 'package:shad/shad.dart';\n$s";
      if (!s.contains("tokens.dart'"))
        s = "import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';\n$s";
      f.writeAsStringSync(s);
    }
  }
}
