// Real provider test-key runner; requires test auth from Toss card registration.
// No server is started, no persistent entitlement is granted, no live key allowed.
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:investment_ontology_serverpod_server/src/ontology/billing/toss_sandbox_gateway.dart';

Future<void> main(List<String> args) async {
  String setting(String name) {
    final value = Platform.environment[name];
    if (value == null || value.isEmpty) throw StateError('Missing $name');
    return value;
  }

  if (args.length != 1 ||
      !const {'lookup', 'approve-and-refund'}.contains(args.single)) {
    stderr.writeln(
      'Use lookup or approve-and-refund. Credentials/references must be environment variables.',
    );
    exitCode = 64;
    return;
  }
  final client = http.Client();
  try {
    final gateway = TossSandboxGateway(
      secretKey: setting('TOSS_TEST_SECRET_KEY'),
      client: client,
    );
    final order = setting('TOSS_TEST_ORDER_ID');
    if (args.single == 'lookup') {
      final p = await gateway.lookup(order);
      stdout.writeln(
        'Test order verified: status=${p.status}, amount=${p.amount}, balance=${p.balance}',
      );
    } else {
      final customer = setting('TOSS_TEST_CUSTOMER_KEY');
      final key = await gateway.issueBillingKey(
        authKey: setting('TOSS_TEST_AUTH_KEY'),
        customerKey: customer,
        idempotencyKey: setting('TOSS_TEST_ISSUE_IDEMPOTENCY'),
      );
      final p = await gateway.charge(
        billingKey: key,
        customerKey: customer,
        orderId: order,
        idempotencyKey: setting('TOSS_TEST_CHARGE_IDEMPOTENCY'),
      );
      if (p.status != 'DONE') {
        throw const SandboxPaymentException('not_approved', uncertain: true);
      }
      final same = await gateway.lookup(order);
      if (same.key != p.key || same.status != 'DONE') {
        throw const SandboxPaymentException('reconciliation', uncertain: true);
      }
      final refund = await gateway.refund(
        paymentKey: p.key,
        orderId: order,
        idempotencyKey: setting('TOSS_TEST_REFUND_IDEMPOTENCY'),
      );
      stdout.writeln(
        'Provider test approval, lookup and full refund verified: balance=${refund.balance}',
      );
    }
  } on SandboxPaymentException catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  } catch (_) {
    // ArgumentError must not echo credential values into console output.
    stderr.writeln(
      'Test setup failed. Check required variables and test-only key.',
    );
    exitCode = 1;
  } finally {
    client.close();
  }
}
