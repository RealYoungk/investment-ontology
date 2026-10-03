import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'primitives.dart' show Collector, fields;

String? type(AstNode n) => n is InstanceCreationExpression
    ? n.constructorName.type.name.lexeme
    : n is MethodInvocation
    ? (n.target is SimpleIdentifier
          ? (n.target as SimpleIdentifier).name
          : n.methodName.name)
    : null;
ArgumentList args(AstNode n) => n is InstanceCreationExpression
    ? n.argumentList
    : (n as MethodInvocation).argumentList;
void main() {
  for (final f
      in Directory('investment_ontology_serverpod_flutter/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
    var source = f.readAsStringSync();
    if (!source.contains('ShadInput(')) continue;
    final prior = Process.runSync('git', ['show', 'HEAD:${f.path}']);
    if (prior.exitCode != 0) continue;
    final originals = Collector();
    parseString(
      content: prior.stdout as String,
      throwIfDiagnostics: false,
    ).unit.accept(originals);
    final lookup = <String, List<Map<String, String>>>{};
    for (final old in originals.calls.where((n) => type(n) == 'TextField')) {
      final a = fields(args(old));
      final key = a['controller'] ?? '';
      final deco = args(old).arguments
          .whereType<NamedExpression>()
          .where((a) => a.name.label.name == 'decoration')
          .firstOrNull
          ?.expression;
      if (deco is InstanceCreationExpression || deco is MethodInvocation)
        lookup.putIfAbsent(key, () => []).add(fields(args(deco!)));
    }
    final current = Collector();
    parseString(
      content: source,
      throwIfDiagnostics: false,
    ).unit.accept(current);
    final edits = <(int, int, String)>[];
    for (final n in current.calls.where((n) => type(n) == 'ShadInput')) {
      final a = fields(args(n));
      final found = lookup[a['controller'] ?? ''];
      if (found == null || found.isEmpty) continue;
      final d = found.removeAt(0);
      final extra = <String>[];
      if (!a.containsKey('placeholder') &&
          (d['hintText'] != null || d['labelText'] != null))
        extra.add('placeholder: Text(${d['hintText'] ?? d['labelText']})');
      if (!a.containsKey('leading') && d['prefixIcon'] != null)
        extra.add('leading: ${d['prefixIcon']}');
      if (!a.containsKey('trailing') && d['suffixIcon'] != null)
        extra.add('trailing: ${d['suffixIcon']}');
      if (extra.isNotEmpty)
        edits.add((
          args(n).offset + 1,
          args(n).offset + 1,
          '${extra.join(', ')}, ',
        ));
    }
    edits.sort((a, b) => b.$1.compareTo(a.$1));
    for (final e in edits) source = source.replaceRange(e.$1, e.$2, e.$3);
    f.writeAsStringSync(source);
  }
}
