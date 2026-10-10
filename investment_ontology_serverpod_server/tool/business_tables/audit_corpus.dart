import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/segment_revenue.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/order_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/business_table_insights.dart';

Future<void> main(List<String> args) async {
  final out = File(args[1]).openSync(mode: FileMode.write);
  var count = 0;
  await for (final line in File(
    args[0],
  ).openRead().transform(utf8.decoder).transform(const LineSplitter())) {
    final d = jsonDecode(line) as Map<String, dynamic>;
    final text = d.remove('text') as String;
    final period = d['reportPeriod'] as String?;
    final tables = period == null
        ? []
        : BusinessTableInsights.parse(text, reportPeriod: period);
    d['productionRows'] = ProductionFacts.parse(text, owner: d['name']).length;
    d['revenueRows'] = SegmentRevenue.parse(text).length;
    d['orderRows'] = OrderFacts.parse(text).length;
    d['rndTable'] = RndFacts.parse(text, bsnsYear: d['year']) != null;
    d['topics'] = {
      for (final t in tables)
        t.topic: {'rows': t.rows.length, 'measures': t.measures.length},
    };
    d['candidates'] = [
      if (text.contains('가동률') && d['productionRows'] == 0) 'utilization',
      if (RegExp(r'매출액.*비중|매출액.*비율').hasMatch(text) && d['revenueRows'] == 0)
        'revenue',
      if (text.contains('연구개발비') && !d['rndTable']) 'rnd',
    ];
    out.writeStringSync('${jsonEncode(d)}\n');
    count++;
  }
  out.closeSync();
  stdout.writeln(
    'Parsed $count stored documents; candidates require source verification.',
  );
}
