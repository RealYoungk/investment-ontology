import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/billing/subscription_rules.dart';

void main() {
  final origin = DateTime.utc(2026, 1, 31, 12);
  late SubscriptionSnapshot sub;
  void paid(int p) =>
      sub.recordPaid(period: p, orderId: 'order_$p', paymentKey: 'payment_$p');
  setUp(() => sub = SubscriptionSnapshot(ownerId: 'user_A', origin: origin));
  test('anniversary clamps without March drift and respects leap years', () {
    expect(
      SubscriptionRules.boundary(origin, 1),
      DateTime.utc(2026, 2, 28, 12),
    );
    expect(
      SubscriptionRules.boundary(origin, 2),
      DateTime.utc(2026, 3, 31, 12),
    );
    expect(
      SubscriptionRules.boundary(DateTime.utc(2024, 1, 31), 1),
      DateTime.utc(2024, 2, 29),
    );
  });
  test('unpaid and future periods do not remove ads', () {
    expect(sub.adFree(origin), false);
    paid(1);
    expect(sub.adFree(origin), false);
    expect(sub.adFree(DateTime.utc(2026, 3, 1)), true);
  });
  test('access expires at exact period boundary independent of scopes', () {
    paid(0);
    expect(sub.adFree(origin), true);
    expect(sub.adFree(DateTime.utc(2026, 2, 28, 11, 59, 59)), true);
    expect(sub.adFree(DateTime.utc(2026, 2, 28, 12)), false);
  });
  test('duplicate approval does not extend access', () {
    paid(0);
    paid(0);
    expect(sub.adFree(DateTime.utc(2026, 3, 1)), false);
  });
  test('cancel stops charging and retains paid access', () {
    paid(0);
    sub.cancel();
    expect(sub.adFree(origin), true);
    expect(sub.canStartCharge(1, DateTime.utc(2026, 2, 28, 12)), false);
  });
  test('approval arriving after cancellation cannot re-enable renewal', () {
    sub.cancel();
    paid(0);
    expect(sub.adFree(origin), true);
    expect(sub.cancelAtPeriodEnd, true);
    expect(sub.canStartCharge(1, DateTime.utc(2026, 2, 28, 12)), false);
  });
  test('refund revokes access; repeated approval cannot undo refund', () {
    paid(0);
    sub.recordFullRefund('order_0', 'payment_0');
    paid(0);
    sub.recordFullRefund('order_0', 'payment_0');
    expect(sub.adFree(origin), false);
  });
  test('refund of old period preserves another paid period', () {
    paid(0);
    paid(1);
    sub.recordFullRefund('order_0', 'payment_0');
    expect(sub.adFree(DateTime.utc(2026, 3, 1)), true);
  });
  test('foreign refund cannot alter entitlement', () {
    paid(0);
    expect(() => sub.recordFullRefund('order_0', 'foreign'), throwsStateError);
    expect(sub.adFree(origin), true);
  });
  test('conflicting and reused payment identities rejected', () {
    paid(0);
    expect(
      () => sub.recordPaid(
        period: 0,
        orderId: 'different',
        paymentKey: 'different',
      ),
      throwsStateError,
    );
    expect(
      () => sub.recordPaid(
        period: 1,
        orderId: 'order_0',
        paymentKey: 'payment_0',
      ),
      throwsStateError,
    );
  });
  test('deleted account cannot regain access from late approval', () {
    sub.delete();
    paid(0);
    expect(sub.adFree(origin), false);
    expect(sub.canStartCharge(1, DateTime.utc(2026, 2, 28, 12)), false);
  });
  test('future/missed/paid periods cannot be automatically charged', () {
    expect(sub.canStartCharge(1, origin), false);
    expect(sub.canStartCharge(0, DateTime.utc(2026, 3, 1)), false);
    expect(sub.canStartCharge(0, origin), true);
    paid(0);
    expect(sub.canStartCharge(0, origin), false);
  });
}
