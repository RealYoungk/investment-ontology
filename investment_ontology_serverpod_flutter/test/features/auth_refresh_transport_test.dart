import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart'
    as ontology;
import 'package:investment_ontology_serverpod_flutter/features/auth/rejected_refresh_handler.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

class _MemoryStorage implements ClientAuthSuccessStorage {
  AuthSuccess? value;
  @override
  Future<AuthSuccess?> get() async => value;
  @override
  Future<void> set(AuthSuccess? data) async {
    value = data;
  }
}

AuthSuccess _auth(String token, {bool expired = false}) => AuthSuccess(
  authStrategy: 'jwt',
  token: token,
  refreshToken: 'test-refresh',
  tokenExpiresAt: DateTime.now().toUtc().add(
    Duration(minutes: expired ? -1 : 10),
  ),
  authUserId: UuidValue.fromString('11111111-1111-4111-8111-111111111111'),
  scopeNames: {'serverpod.admin'},
);

void main() {
  for (final outcome in ['success', 'revoked', 'unavailable']) {
    test(
      'real generated client handles expired access token: $outcome',
      () async {
        // A separate loopback fixture, never the user's server or credentials.
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        var refreshCalls = 0;
        final sentHeaders = <String?>[];
        server.listen((request) async {
          await request.drain<void>();
          request.response.headers.contentType = ContentType.json;
          if (request.uri.path == '/jwtRefresh/refreshAccessToken') {
            refreshCalls++;
            if (outcome == 'revoked') {
              request.response.statusCode = 401;
              request.response.write(
                jsonEncode({
                  'className':
                      'serverpod_auth_core.RefreshTokenNotFoundException',
                  'data': RefreshTokenNotFoundException().toJson(),
                }),
              );
            } else if (outcome == 'unavailable') {
              request.response.statusCode = 503;
              request.response.write('{}');
            } else {
              request.response.write(
                jsonEncode(_auth('renewed-access').toJson()),
              );
            }
          } else {
            sentHeaders.add(
              request.headers.value(HttpHeaders.authorizationHeader),
            );
            request.response.write('[]');
          }
          await request.response.close();
        });

        final storage = _MemoryStorage();
        final cleared = Completer<void>();
        late ontology.Client client;
        client = ontology.Client(
          'http://127.0.0.1:${server.port}/',
          onFailedCall: (context, error, stack) async {
            await handleRejectedRefresh(
              context,
              error,
              clearLocalSession: () async {
                await client.auth.updateSignedInUser(null);
                if (!cleared.isCompleted) cleared.complete();
              },
            );
          },
        )..authSessionManager = FlutterAuthSessionManager(storage: storage);
        addTearDown(client.close);
        await client.auth.updateSignedInUser(
          _auth('expired-access', expired: true),
        );

        await client.ingest.latestOfKinds(['financial_facts']);
        if (outcome == 'success') {
          expect(client.auth.authInfo?.token, 'renewed-access');
          expect(sentHeaders, ['Bearer renewed-access']);
          await client.ingest.latestOfKinds(['financial_facts']);
          expect(refreshCalls, 1);
        } else if (outcome == 'revoked') {
          await cleared.future.timeout(const Duration(seconds: 2));
          expect(client.auth.isAuthenticated, isFalse);
          expect(storage.value, isNull);
          expect(sentHeaders, [
            isNull,
          ], reason: 'Do not resend the rejected access token');
          await client.ingest.latestOfKinds(['financial_facts']);
          expect(refreshCalls, 1, reason: 'No rejected-refresh request loop');
        } else {
          expect(client.auth.isAuthenticated, isTrue);
          expect(storage.value, isNotNull);
          expect(cleared.isCompleted, isFalse);
        }
      },
    );
  }
}
