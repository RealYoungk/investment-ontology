import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Authenticated encryption; ciphertext is bound to the owning account.
/// Only the server receives the encryption key. Never serialize decrypted keys.
class BillingKeyVault {
  BillingKeyVault(List<int> key) : _key = SecretKey(key) {
    if (key.length != 32) {
      throw ArgumentError('A 32-byte encryption key is required');
    }
  }
  final SecretKey _key;
  final _algorithm = AesGcm.with256bits();

  Future<String> seal(String owner, String reference) async {
    if (owner.isEmpty || reference.isEmpty) {
      throw ArgumentError('Missing owner/reference');
    }
    final box = await _algorithm.encrypt(
      utf8.encode(reference),
      secretKey: _key,
      aad: utf8.encode(owner),
    );
    return jsonEncode({
      'v': 1,
      'n': base64Encode(box.nonce),
      'c': base64Encode(box.cipherText),
      'm': base64Encode(box.mac.bytes),
    });
  }

  Future<String> open(String owner, String encrypted) async {
    try {
      final value = jsonDecode(encrypted) as Map<String, dynamic>;
      if (value['v'] != 1) throw StateError('Invalid version');
      final box = SecretBox(
        base64Decode(value['c'] as String),
        nonce: base64Decode(value['n'] as String),
        mac: Mac(base64Decode(value['m'] as String)),
      );
      return utf8.decode(
        await _algorithm.decrypt(box, secretKey: _key, aad: utf8.encode(owner)),
      );
    } catch (_) {
      throw StateError('Billing reference could not be verified');
    }
  }
}
