import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class Collector extends RecursiveAstVisitor<void> {
  final calls = <AstNode>[];
  @override
  void visitMethodInvocation(MethodInvocation node) {
    calls.add(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    calls.add(node);
    super.visitInstanceCreationExpression(node);
  }
}

Map<String, String> fields(ArgumentList args) => {
  for (final a in args.arguments.whereType<NamedExpression>())
    a.name.label.name: a.expression.toSource(),
};
void main() {
  final removed = <String>[];
  for (final file
      in Directory('investment_ontology_serverpod_flutter/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    var source = file.readAsStringSync();
    final c = Collector();
    parseString(content: source, throwIfDiagnostics: false).unit.accept(c);
    final edits = <(int, int, String)>[];
    for (final call in c.calls) {
      final String type;
      final String? factory;
      final ArgumentList arguments;
      if (call is InstanceCreationExpression) {
        type = call.constructorName.type.name.lexeme;
        factory = call.constructorName.name?.name;
        arguments = call.argumentList;
      } else if (call is MethodInvocation) {
        type = call.target is SimpleIdentifier
            ? (call.target as SimpleIdentifier).name
            : call.methodName.name;
        factory = call.target is SimpleIdentifier ? call.methodName.name : null;
        arguments = call.argumentList;
      } else {
        continue;
      }
      final args = fields(arguments);
      if (factory == 'styleFrom') continue;
      String? target;
      if (type == 'TextField') {
        target = 'ShadInput';
        final deco = arguments.arguments
            .whereType<NamedExpression>()
            .where((a) => a.name.label.name == 'decoration')
            .firstOrNull
            ?.expression;
        args.remove('decoration');
        if (deco is InstanceCreationExpression || deco is MethodInvocation) {
          final d = fields(
            deco is InstanceCreationExpression
                ? deco.argumentList
                : (deco as MethodInvocation).argumentList,
          );
          if (d['hintText'] != null || d['labelText'] != null)
            args['placeholder'] = 'Text(${d['hintText'] ?? d['labelText']})';
          if (d['prefixIcon'] != null) args['leading'] = d['prefixIcon']!;
          if (d['suffixIcon'] != null) args['trailing'] = d['suffixIcon']!;
          removed.add(
            '${file.path}:${call.offset} InputDecoration styling => service theme; original keys: ${d.keys.join(',')}',
          );
        }
        if (args.containsKey('onTapOutside'))
          args['onPressedOutside'] = args.remove('onTapOutside')!;
        if (args.containsKey('onTapAlwaysCalled'))
          args['onPressedAlwaysCalled'] = args.remove('onTapAlwaysCalled')!;
        if (args.containsKey('onTap'))
          args['onPressed'] = args.remove('onTap')!;
      } else if ([
        'TextButton',
        'OutlinedButton',
        'ElevatedButton',
        'FilledButton',
      ].contains(type)) {
        target = switch (type) {
          'TextButton' => 'ShadButton.ghost',
          'OutlinedButton' => 'ShadButton.outline',
          _ => 'ShadButton',
        };
        if (factory == 'icon') {
          if (args.containsKey('icon')) args['leading'] = args.remove('icon')!;
          if (args.containsKey('label')) args['child'] = args.remove('label')!;
        }
        if (args.containsKey('style')) {
          args.remove('style');
          removed.add(
            '${file.path}:${call.offset} Material button style => shad theme',
          );
        }
        if (args['onPressed'] == 'null') args['enabled'] = 'false';
        if (args.containsKey('child'))
          args['child'] = 'Flexible(child: ${args['child']})';
      } else if (type == 'AppNotice') {
        target = 'ShadAlert';
        final message = args.remove('message');
        args['description'] = 'Text($message)';
      } else if (type == 'AppTag') {
        target = 'ShadBadge.raw';
        final label = args.remove('label');
        final filled = args.remove('filled') ?? 'false';
        final color = args.remove('color');
        args.remove('numeric');
        args.remove('size');
        args['variant'] = filled == 'true'
            ? 'ShadBadgeVariant.primary'
            : filled == 'false'
            ? 'ShadBadgeVariant.outline'
            : '($filled) ? ShadBadgeVariant.primary : ShadBadgeVariant.outline';
        if (color != null) {
          args['foregroundColor'] = color;
          if (filled == 'true')
            args['backgroundColor'] = '$color.withValues(alpha: 0.12)';
        }
        args['child'] = 'Text($label, maxLines: 1, softWrap: false)';
      } else if (type == 'DropdownMenuItem') {
        target = 'MapEntry';
        final child = arguments.arguments
            .whereType<NamedExpression>()
            .where((a) => a.name.label.name == 'child')
            .firstOrNull
            ?.expression;
        if (child is! InstanceCreationExpression && child is! MethodInvocation)
          continue;
        final childArgs = child is InstanceCreationExpression
            ? child.argumentList
            : (child as MethodInvocation).argumentList;
        final label = childArgs.arguments
            .where((a) => a is! NamedExpression)
            .firstOrNull
            ?.toSource();
        if (label == null) continue;
        final replacement = 'MapEntry(${args['value']}, $label)';
        edits.add((call.offset, call.end, replacement));
        continue;
      } else if (type == 'DropdownButton' ||
          type == 'DropdownButtonFormField') {
        target =
            'AppSelect${call is InstanceCreationExpression
                ? call.constructorName.type.typeArguments?.toSource() ?? ''
                : call is MethodInvocation
                ? call.typeArguments?.toSource() ?? ''
                : ''}';
        // Process only once every nested menu item has become a label/key entry.
        if ((args['items'] ?? '').contains('DropdownMenuItem')) continue;
        final entries = args['items'] ?? '[]';
        final value = args['value'] ?? args['initialValue'] ?? 'null';
        final changed = args['onChanged'] ?? '(_) {}';
        final key = args['key'];
        args.clear();
        if (key != null) args['key'] = key;
        args['options'] = 'Map.fromEntries($entries)';
        args['value'] = value;
        args['onChanged'] = changed;
        args['placeholder'] = "'선택'";
        args['allowClear'] = 'false';
      } else if (type == 'CheckboxListTile') {
        target = 'ShadCheckbox';
        if (args.containsKey('title')) args['label'] = args.remove('title')!;
        if (args.containsKey('subtitle'))
          args['sublabel'] = args.remove('subtitle')!;
        if (args.containsKey('contentPadding'))
          args['padding'] = args.remove('contentPadding')!;
        for (final key in [
          'dense',
          'controlAffinity',
          'selected',
          'activeColor',
          'checkColor',
          'shape',
          'visualDensity',
          'tileColor',
        ]) {
          args.remove(key);
        }
      } else if (type == 'CircularProgressIndicator') {
        target = 'ShadSpinner';
        for (final key in [
          'value',
          'valueColor',
          'backgroundColor',
          'strokeAlign',
          'semanticsLabel',
          'semanticsValue',
          'constraints',
          'year2023',
        ]) {
          args.remove(key);
        }
      } else if (type == 'LinearProgressIndicator') {
        target = 'ShadProgress';
        args.remove('year2023');
      } else if (type == 'showDialog') {
        target =
            'showShadDialog${call is MethodInvocation ? call.typeArguments?.toSource() ?? '' : ''}';
        for (final key in [
          'useSafeArea',
          'requestFocus',
          'traversalEdgeBehavior',
          'animationStyle',
        ]) {
          args.remove(key);
        }
        args.putIfAbsent('barrierLabel', () => "'닫기'");
      } else if (type == 'AlertDialog' || type == 'Dialog') {
        target = 'ShadDialog';
        if (args.containsKey('content'))
          args['child'] = args.remove('content')!;
        if (args.containsKey('contentPadding'))
          args['padding'] = args.remove('contentPadding')!;
        for (final key in [
          'elevation',
          'surfaceTintColor',
          'shape',
          'insetPadding',
          'clipBehavior',
          'titlePadding',
          'actionsPadding',
          'icon',
          'iconColor',
          'iconPadding',
          'buttonPadding',
          'actionsOverflowAlignment',
          'actionsOverflowButtonSpacing',
          'actionsOverflowDirection',
          'contentTextStyle',
          'titleTextStyle',
        ]) {
          args.remove(key);
        }
      } else if (type == 'IconButton') {
        target = 'ShadIconButton.ghost';
        if (args.containsKey('tooltip'))
          args['semanticLabel'] = args.remove('tooltip')!;
        if (args.containsKey('color'))
          args['foregroundColor'] = args.remove('color')!;
        if (args.containsKey('iconSize')) {
          /* same API */
        }
        for (final key in [
          'style',
          'constraints',
          'visualDensity',
          'alignment',
          'splashRadius',
          'splashColor',
          'highlightColor',
        ]) {
          if (args.remove(key) != null)
            removed.add(
              '${file.path}:${call.offset} IconButton.$key => shad defaults',
            );
        }
        if (args['onPressed'] == 'null') args['enabled'] = 'false';
      }
      if (target != null) {
        final prefix =
            call is InstanceCreationExpression &&
                call.keyword?.lexeme == 'const'
            ? 'const '
            : '';
        edits.add((
          call.offset,
          call.end,
          '$prefix$target(${args.entries.map((e) => '${e.key}: ${e.value}').join(', ')})',
        ));
      }
    }
    // Nested converted controls must be handled on the next pass; do not drop inner edits.
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    var boundary = source.length;
    var changed = false;
    for (final e in edits) {
      if (e.$2 > boundary) continue;
      source = source.replaceRange(e.$1, e.$2, e.$3);
      boundary = e.$1;
      changed = true;
    }
    if (changed) {
      if (source.contains('AppSelect') &&
          !source.contains("components/components.dart';") &&
          !source.contains("components/app_select.dart';"))
        source =
            "import 'package:investment_ontology_serverpod_flutter/design/components/app_select.dart';\n$source";
      if (!source.contains("import 'package:shad/shad.dart';") &&
          !source.contains("components/components.dart';"))
        source = "import 'package:shad/shad.dart';\n$source";
      file.writeAsStringSync(source);
    }
  }
  File('outputs/design/shad-review/primitive-migration.txt')
      .writeAsStringSync(removed.join('\n') + '\n', mode: FileMode.append);
}
