// Isolated browser fixture only: not imported by lib/server.dart or production.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/membership_ledger.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_provider_config.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/subscription_rules.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  final fixturePath = Platform.environment['ALFINDER_BROWSER_FIXTURE'];
  if (fixturePath == null) {
    test(
      'browser fixture is opt-in',
      () {},
      skip: 'Run scripts/test-billing-browser.sh',
    );
    return;
  }
  withServerpod(
    'Isolated authenticated browser billing fixture',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, _) {
      test('serve real RPC and database with provider mock', () async {
        AuthServices.set(
          tokenManagerBuilders: [
            JwtConfig(
              algorithm: JwtAlgorithm.hmacSha512(
                SecretKey('browser-fixture-only-signing-secret'),
              ),
              refreshTokenHashPepper: 'browser-fixture-only-pepper',
            ),
          ],
          identityProviderBuilders: [],
        );
        final session = builder.build();
        final pod = session.serverpod;
        if (pod.runMode != 'test') throw StateError('Test mode required');
        final user = await const AuthUsers().create(session);
        final other = await const AuthUsers().create(session);
        final token = Uuid().v4(), otherToken = Uuid().v4();
        final orders = <String, Map<String, dynamic>>{};
        var charges = 0, issues = 0, deletes = 0;
        final provider = MockClient((request) async {
          if (request.url.host != 'api.tosspayments.com') {
            throw StateError('Unexpected external request');
          }
          if (request.method == 'DELETE') {
            deletes++;
            return http.Response('', 204);
          }
          final body = request.body.isEmpty
              ? <String, dynamic>{}
              : jsonDecode(request.body) as Map<String, dynamic>;
          if (request.url.path.endsWith('/issue')) {
            issues++;
            return http.Response(
              jsonEncode({
                'customerKey': body['customerKey'],
                'billingKey': 'opaque+/fixture-$issues==',
              }),
              200,
            );
          }
          Map<String, dynamic>? payment;
          if (request.url.path.endsWith('/cancel')) {
            payment = orders.values.firstWhere(
              (p) => p['paymentKey'] == request.url.pathSegments[2],
            );
            payment['status'] = 'CANCELED';
            payment['balanceAmount'] = 0;
          } else if (request.method == 'GET') {
            payment = orders[request.url.pathSegments.last];
          } else {
            final id = body['orderId'] as String;
            payment = orders[id];
            if (payment == null) {
              charges++;
              payment = orders[id] = {
                'orderId': id,
                'paymentKey': 'payment-$id',
                'type': 'BILLING',
                'currency': 'KRW',
                'totalAmount': body['amount'],
                'balanceAmount': body['amount'],
                'status': 'DONE',
              };
            }
          }
          return http.Response(
            jsonEncode(payment ?? {}),
            payment == null ? 404 : 200,
          );
        });
        pod.authenticationHandler = (_, key) async {
          if (key == token) {
            return AuthenticationInfo(
              user.id.toString(),
              {},
              authId: 'browser-reader',
            );
          }
          if (key == otherToken) {
            return AuthenticationInfo(
              other.id.toString(),
              {},
              authId: 'browser-other',
            );
          }
          return null;
        };
        await http.runWithClient(
          () => pod.withPausedRequestHandling(() async {}),
          () => provider,
        );
        final control = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final done = <String>[];
        control.listen((request) async {
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          request.response.headers.set(
            'Access-Control-Allow-Headers',
            'Authorization,Content-Type',
          );
          if (request.uri.path == '/billing_loader.js' ||
              request.uri.path == '/ad_loader.js') {
            request.response.headers.contentType = ContentType(
              'application',
              'javascript',
              charset: 'utf-8',
            );
            if (request.uri.path == '/ad_loader.js') {
              request.response.write(
                await File(
                  '../investment_ontology_serverpod_flutter/test/web/ad_browser_transport_fixture.js',
                ).readAsString(),
              );
            }
            request.response.write(
              await File(
                '../investment_ontology_serverpod_flutter/web${request.uri.path}',
              ).readAsString(),
            );
            await request.response.close();
            return;
          }
          if (request.method == 'OPTIONS') {
            await request.response.close();
            return;
          }
          if (request.headers.value('Authorization') != 'Bearer $token') {
            request.response.statusCode = 401;
            await request.response.close();
            return;
          }
          try {
            final sub = await BillingSubscription.db.findFirstRow(
              session,
              where: (t) => t.ownerId.equals(user.id),
            );
            final worker = BillingSandboxConfig.service(session, provider)!;
            if (request.uri.path == '/expire' && sub != null) {
              sub.originUtc = DateTime.now().toUtc().subtract(
                const Duration(days: 32),
              );
              await BillingSubscription.db.updateRow(session, sub);
              final rows = await BillingPaymentAttempt.db.find(
                session,
                where: (t) => t.subscriptionId.equals(sub.id!),
              );
              for (final row in rows) {
                row.paidFromUtc = SubscriptionRules.boundary(
                  sub.originUtc,
                  row.period - sub.cycleStartPeriod,
                );
                row.paidThroughUtc = SubscriptionRules.boundary(
                  sub.originUtc,
                  row.period - sub.cycleStartPeriod + 1,
                );
                await BillingPaymentAttempt.db.updateRow(session, row);
              }
            } else if (request.uri.path == '/expireAll' && sub != null) {
              final rows = await BillingPaymentAttempt.db.find(
                session,
                where: (t) => t.subscriptionId.equals(sub.id!),
              );
              for (final row in rows) {
                row.paidThroughUtc = DateTime.now().toUtc().subtract(
                  const Duration(seconds: 1),
                );
                await BillingPaymentAttempt.db.updateRow(session, row);
              }
            } else if (request.uri.path == '/renew' && sub != null) {
              await worker.run(session, sub.id!);
            } else if (request.uri.path == '/refund' && sub != null) {
              final row = (await BillingPaymentAttempt.db.findFirstRow(
                session,
                where: (t) =>
                    t.subscriptionId.equals(sub.id!) & t.status.equals('paid'),
                orderBy: (t) => t.period.desc(),
              ))!;
              final result = await worker.gateway.refund(
                paymentKey: row.paymentKey!,
                orderId: row.orderId,
                idempotencyKey: 'refund-${row.idempotencyKey}',
              );
              await MembershipLedger.fullRefund(session, row.id!, result);
            } else if (request.uri.path == '/stop') {
              done.add('stop');
            }
            request.response.headers.contentType = ContentType.json;
            request.response.write(
              jsonEncode({
                'charges': charges,
                'issues': issues,
                'deletes': deletes,
              }),
            );
          } catch (_) {
            request.response.statusCode = 500;
          }
          await request.response.close();
        });
        final file = File(fixturePath);
        await file.writeAsString(
          jsonEncode({
            'BILLING_BROWSER_FIXTURE': jsonEncode({
              'url': 'http://localhost:${pod.server.port}/',
              'control': 'http://127.0.0.1:${control.port}',
              'token': token,
              'otherToken': otherToken,
              'user': user.id.toString(),
              'other': other.id.toString(),
            }),
          }),
        );
        await Process.run('chmod', ['600', fixturePath]);
        final limit = DateTime.now().add(const Duration(minutes: 20));
        while (done.isEmpty && DateTime.now().isBefore(limit)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        await control.close(force: true);
        await file.delete();
      }, timeout: const Timeout(Duration(minutes: 21)));
    },
  );
}
