import 'dart:convert';

import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_key_vault.dart';
import 'package:test/test.dart';

void main() {
  final vault = BillingKeyVault(List.generate(32, (i) => i));
  test('roundtrip is randomized and never contains plaintext', () async {
    final a = await vault.seal('owner-one', 'opaque+/billing-reference==');
    final b = await vault.seal('owner-one', 'opaque+/billing-reference==');
    expect(a, isNot(b));
    expect(a.contains('billing-reference'), false);
    expect(await vault.open('owner-one', a), 'opaque+/billing-reference==');
  });
  test('cross-account ciphertext cannot decrypt', () async {
    final sealed = await vault.seal('owner-one', 'reference');
    await expectLater(vault.open('owner-two', sealed), throwsStateError);
  });
  test('modified ciphertext and wrong key are rejected', () async {
    final sealed = await vault.seal('owner-one', 'reference');
    final changed = jsonDecode(sealed) as Map<String, dynamic>;
    changed['m'] = base64Encode(List.filled(16, 0));
    await expectLater(
      vault.open('owner-one', jsonEncode(changed)),
      throwsStateError,
    );
    await expectLater(
      BillingKeyVault(List.filled(32, 0)).open('owner-one', sealed),
      throwsStateError,
    );
  });
  test('key length and malformed ciphertext fail closed', () async {
    expect(() => BillingKeyVault([1]), throwsArgumentError);
    await expectLater(vault.open('owner-one', 'invalid'), throwsStateError);
  });
}
