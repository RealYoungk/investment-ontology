import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

/// Only MockClient can enter this helper: no real request loses its cadence.
PublicFinancialHtmlFetcher fastFinancialHtmlFetcher(MockClient client) =>
    PublicFinancialHtmlFetcher.withTimingForTesting(
      client,
      timing: _sharedClock.timing,
    );

final _sharedClock = VirtualFinancialHtmlClock();

class VirtualFinancialHtmlClock {
  DateTime now = DateTime.utc(2030);
  final waits = <Duration>[];
  late final timing = FinancialHtmlRequestTiming.forTesting(
    now: () => now,
    wait: (duration) async {
      waits.add(duration);
      now = now.add(duration);
    },
  );
}
