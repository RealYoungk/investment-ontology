import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'primitives.dart' show Collector, fields;

void main() {
  final f = File(
    'investment_ontology_serverpod_flutter/lib/features/watchlist/watchlist_page.dart',
  );
  var s = f.readAsStringSync();
  final c = Collector();
  parseString(content: s, throwIfDiagnostics: false).unit.accept(c);
  final n = c.calls.firstWhere(
    (n) =>
        (n is InstanceCreationExpression
            ? n.constructorName.type.name.lexeme
            : (n as MethodInvocation).methodName.name) ==
        'PopupMenuButton',
  );
  final arguments = n is InstanceCreationExpression
      ? n.argumentList
      : (n as MethodInvocation).argumentList;
  final a = fields(arguments);
  final builder =
      arguments.arguments
              .whereType<NamedExpression>()
              .firstWhere((x) => x.name.label.name == 'itemBuilder')
              .expression
          as FunctionExpression;
  final list = (builder.body as ExpressionFunctionBody).expression;
  var items = s.substring(list.offset, list.end);
  final nested = Collector();
  list.accept(nested);
  final edits = <(int, int, String)>[];
  for (final item in nested.calls.where(
    (n) =>
        (n is InstanceCreationExpression
            ? n.constructorName.type.name.lexeme
            : (n as MethodInvocation).methodName.name) ==
        'PopupMenuItem',
  )) {
    final p = fields(
      item is InstanceCreationExpression
          ? item.argumentList
          : (item as MethodInvocation).argumentList,
    );
    edits.add((
      item.offset - list.offset,
      item.end - list.offset,
      "ShadContextMenuItem(enabled: !_busy, onPressed: () => (${a['onSelected']})(${p['value']}), child: ${p['child']})",
    ));
  }
  edits.sort((a, b) => b.$1.compareTo(a.$1));
  for (final e in edits) items = items.replaceRange(e.$1, e.$2, e.$3);
  s = s.replaceRange(
    n.offset,
    n.end,
    "ShadContextMenu(controller: _companyMenus.putIfAbsent(company.corpCode, ShadPopoverController.new), items: $items, child: ShadIconButton.ghost(enabled: !_busy, semanticLabel: ${a['tooltip']}, onPressed: () => _companyMenus[company.corpCode]!.toggle(), icon: const Icon(Icons.more_vert)))",
  );
  s = s
      .replaceAll(
        '  bool _busy = false;',
        '  bool _busy = false;\n  final _companyMenus = <String, ShadPopoverController>{};',
      )
      .replaceFirst(
        '  void dispose() {',
        '  void dispose() {\n    for (final menu in _companyMenus.values) { menu.dispose(); }',
      );
  f.writeAsStringSync(s);
}
