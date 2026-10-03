import 'dart:async';
import 'dart:math';

import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

/// Explicit reads only: new endpoints never gain retry behavior implicitly.
class ReadRetry {
  static const methods = <String>{
    'account.list',
    'account.mailConfigured',
    'membership.paymentsForAccount',
    'ai.status',
    'ai.pending',
    'ai.documentText',
    'ai.documentTexts',
    'review.list',
    'review.context',
    'review.checks',
    'review.facts',
    'review.forCompany',
    'company.overview',
    'company.divisions',
    'company.list',
    'company.detail',
    'companyNews.recent',
    'research.data',
    'research.connectionStatus',
    'disclosure.understanding',
    'disclosure.sections',
    'disclosure.table',
    'disclosure.businessContent',
    'disclosure.shareholderReturn',
    'disclosure.facts',
    'disclosure.factPeriods',
    'disclosure.factTrends',
    'disclosure.recentOf',
    'disclosure.digest',
    'disclosure.recentFilings',
    'financial.summary',
    'financial.report',
    'governance.summary',
    'governance.ownershipHistory',
    'governance.searchPersons',
    'governance.person',
    'graph.neighborhood',
    'group.list',
    'group.of',
    'industry.browse',
    'industry.discover',
    'ingest.coverage',
    'ingest.latest',
    'ingest.latestOf',
    'ingest.schedule',
    'ingest.latestOfKinds',
    'macro.overview',
    'market.companyCapHistory',
    'market.industryTreemap',
    'market.capHistory',
    'market.indexHistory',
    'market.priceHistory',
    'screen.peerCandidates',
    'screen.list',
    'screen.peers',
    'theme.list',
    'theme.detail',
    'theme.themesOf',
    'watchlist.mine',
    'account.me',
    'membership.status',
    'membershipOffer.offer',
  };

  static bool transient(Object error) =>
      error is TimeoutException ||
      error is ServerpodClientNetworkException ||
      (error is ServerpodClientHttpException &&
          const {502, 503, 504}.contains(error.statusCode));

  static Future<T> run<T>(
    String method,
    Future<T> Function() request, {
    Future<void> Function(Duration)? wait,
    int Function(int)? jitter,
  }) async {
    for (var attempt = 0; ; attempt++) {
      try {
        final pending = request();
        return await (methods.contains(method)
            ? pending.timeout(const Duration(seconds: 15))
            : pending);
      } catch (error) {
        if (!methods.contains(method) || !transient(error) || attempt >= 2) {
          rethrow;
        }
        final delay = Duration(
          milliseconds:
              (attempt == 0 ? 500 : 1500) + (jitter ?? Random().nextInt)(250),
        );
        await (wait ?? Future<void>.delayed)(delay);
      }
    }
  }
}

/// Preserves Serverpod's authentication refresh, serialization and callbacks.
class ResilientClient extends Client {
  ResilientClient(super.host, {super.onFailedCall});

  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) => ReadRetry.run(
    '$endpoint.$method',
    () => super.callServerEndpoint<T>(
      endpoint,
      method,
      args,
      authenticated: authenticated,
    ),
  );
}
