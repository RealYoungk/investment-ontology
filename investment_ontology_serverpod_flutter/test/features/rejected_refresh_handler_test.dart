import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/app/ingest_monitor.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/rejected_refresh_handler.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

const refresh = MethodCallContext(
  endpointName: 'jwtRefresh',
  methodName: 'refreshAccessToken',
  arguments: {},
);

void main() {
  testWidgets(
    'rejected refresh stops polling, including an in-flight response',
    (tester) async {
      final response = Completer<List<Never>>();
      var requests = 0;
      final monitor = IngestMonitor.test(
        fetch: (_) {
          requests++;
          return response.future;
        },
      );
      addTearDown(monitor.dispose);
      monitor.start();
      var signedIn = true;
      await handleRejectedRefresh(
        refresh,
        RefreshTokenNotFoundException(),
        clearLocalSession: () async {
          signedIn = false;
          monitor.stop();
        },
      );
      response.complete([]);
      await tester.pump();
      await tester.pump(const Duration(minutes: 1));
      expect(signedIn, isFalse);
      expect(requests, 1);
    },
  );

  test('transient and ordinary request failures retain the login', () async {
    var cleared = 0;
    for (final error in [
      TimeoutException('offline'),
      ServerpodClientUnauthorized(),
      Exception('server error'),
    ]) {
      await handleRejectedRefresh(
        refresh,
        error,
        clearLocalSession: () async {
          cleared++;
        },
      );
    }
    await handleRejectedRefresh(
      const MethodCallContext(
        endpointName: 'ingest',
        methodName: 'latestOfKinds',
        arguments: {},
      ),
      RefreshTokenNotFoundException(),
      clearLocalSession: () async {
        cleared++;
      },
    );
    expect(cleared, 0);
  });

  test('all definitive refresh rejections clear the local login', () async {
    var cleared = 0;
    for (final error in [
      RefreshTokenMalformedException(),
      RefreshTokenNotFoundException(),
      RefreshTokenExpiredException(),
      RefreshTokenInvalidSecretException(),
    ]) {
      await handleRejectedRefresh(
        refresh,
        error,
        clearLocalSession: () async {
          cleared++;
        },
      );
    }
    expect(cleared, 4);
  });
}
