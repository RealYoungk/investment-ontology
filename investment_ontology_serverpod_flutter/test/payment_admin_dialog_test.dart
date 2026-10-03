import 'support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/payment_admin_dialog.dart';

void main() {
  final user = AccountView(
    userId: 'fixture',
    email: 'member@example.test',
    createdAt: DateTime.utc(2026),
    isAdmin: false,
    blocked: false,
  );
  BillingPaymentView row(String status) => BillingPaymentView(
    attemptId: 42,
    orderId: 'alfinder-order-fixture',
    status: status,
    amountKrw: 2900,
    paidFromUtc: DateTime.utc(2026, 10),
    paidThroughUtc: DateTime.utc(2026, 11),
  );

  testWidgets(
    'confirmation is required and pending is never shown as refunded',
    (tester) async {
      var requests = 0;
      var state = 'paid';
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            home: Scaffold(
              body: PaymentAdminDialog(
                user: user,
                loadPayments: () async => [row(state)],
                refundPayment: (id, order) async {
                  expect(id, 42);
                  expect(order, 'alfinder-order-fixture');
                  requests++;
                  state = 'refundRequested';
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('전액 환불'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      await tester.tap(find.text('돌아가기'));
      await tester.pumpAndSettle();
      expect(requests, 0);
      await tester.tap(find.text('전액 환불'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('전액 환불 요청'));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(find.textContaining('2900원 · 환불 확인 중'), findsOneWidget);
      expect(find.textContaining('전액 환불 완료'), findsNothing);
    },
  );

  testWidgets('320px dialog can show a long order and only confirmed refunds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          home: Scaffold(
            body: PaymentAdminDialog(
              user: user,
              loadPayments: () async => [row('refunded')],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('2900원 · 전액 환불 완료'), findsOneWidget);
    expect(find.text('전액 환불'), findsNothing);
  });
}
