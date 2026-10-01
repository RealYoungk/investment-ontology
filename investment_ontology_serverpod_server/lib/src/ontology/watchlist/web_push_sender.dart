import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart' as pc;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../api_secret.dart';

/// RFC 8291 aes128gcm + RFC 8292 VAPID. No gateway or third-party SDK.
abstract final class WebPushSender {
  static final curve = pc.ECDomainParameters('prime256v1');
  static const _private = ApiSecret(
    passwordName: 'webPushPrivateKey',
    envName: 'WEB_PUSH_PRIVATE_KEY',
  );
  static String b64(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');
  static Uint8List decode(String value) =>
      base64Url.decode(base64Url.normalize(value));
  static BigInt integer(List<int> bytes) =>
      bytes.fold(BigInt.zero, (n, b) => (n << 8) | BigInt.from(b));
  static Uint8List octets(BigInt n) => Uint8List.fromList(
    List.generate(
      32,
      (i) => ((n >> ((31 - i) * 8)) & BigInt.from(255)).toInt(),
    ),
  );
  static Uint8List randomBytes(int size) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(size, (_) => random.nextInt(256)));
  }

  static BigInt newPrivateKey() {
    while (true) {
      final n = integer(randomBytes(32));
      if (n > BigInt.zero && n < curve.n) return n;
    }
  }

  static Uint8List publicBytes(BigInt secret) =>
      (curve.G * secret)!.getEncoded(false);
  static String? publicKey(Session session) {
    try {
      final key = _private.read(session);
      if (key == null) return null;
      final bytes = decode(key);
      final n = integer(bytes);
      if (bytes.length != 32 || n <= BigInt.zero || n >= curve.n) return null;
      return b64(publicBytes(n));
    } catch (_) {
      return null;
    }
  }

  /// Strict provider allowlist prevents authenticated clients turning this
  /// sender into an SSRF relay. Redirects are disabled when sending.
  static bool validEndpoint(String endpoint) {
    final u = Uri.tryParse(endpoint);
    if (u == null ||
        endpoint.length > 2048 ||
        u.scheme != 'https' ||
        u.userInfo.isNotEmpty ||
        u.hasFragment ||
        (u.hasPort && u.port != 443)) {
      return false;
    }
    return u.host == 'fcm.googleapis.com' ||
        u.host == 'updates.push.services.mozilla.com' ||
        u.host == 'web.push.apple.com' ||
        u.host == 'wns.windows.com' ||
        u.host.endsWith('.wns.windows.com');
  }

  static void validate(String endpoint, String key, String auth) {
    if (!validEndpoint(endpoint)) {
      throw const FormatException('Unsupported push provider');
    }
    final point = decode(key), secret = decode(auth);
    if (point.length != 65 ||
        point.first != 4 ||
        secret.length != 16 ||
        curve.curve.decodePoint(point)?.isInfinity != false) {
      throw const FormatException('Invalid push keys');
    }
  }

  static List<int> _hmac(List<int> key, List<int> value) =>
      crypto.Hmac(crypto.sha256, key).convert(value).bytes;

  /// Optional deterministic inputs are only used by the published RFC vector test.
  static Uint8List encrypt(
    List<int> payload,
    String receiverKey,
    String auth, {
    BigInt? ephemeralSecret,
    Uint8List? salt,
  }) {
    if (payload.length > 3000) {
      throw const FormatException('Push payload too large');
    }
    final ua = decode(receiverKey);
    if (ua.length != 65 || ua.first != 4 || decode(auth).length != 16) {
      throw const FormatException('Invalid push keys');
    }
    final remote = curve.curve.decodePoint(ua);
    if (remote == null || remote.isInfinity) {
      throw const FormatException('Invalid curve point');
    }
    final secret = ephemeralSecret ?? newPrivateKey();
    final asPublic = publicBytes(secret);
    final shared = octets((remote * secret)!.x!.toBigInteger()!);
    final ikm = _hmac(_hmac(decode(auth), shared), [
      ...ascii.encode('WebPush: info'),
      0,
      ...ua,
      ...asPublic,
      1,
    ]);
    final s = salt ?? randomBytes(16);
    final prk = _hmac(s, ikm);
    final cek = _hmac(prk, [
      ...ascii.encode('Content-Encoding: aes128gcm'),
      0,
      1,
    ]).sublist(0, 16);
    final nonce = _hmac(prk, [
      ...ascii.encode('Content-Encoding: nonce'),
      0,
      1,
    ]).sublist(0, 12);
    final aes = pc.GCMBlockCipher(pc.AESEngine())
      ..init(
        true,
        pc.AEADParameters(
          pc.KeyParameter(Uint8List.fromList(cek)),
          128,
          Uint8List.fromList(nonce),
          Uint8List(0),
        ),
      );
    final ciphertext = aes.process(Uint8List.fromList([...payload, 2]));
    return Uint8List.fromList([
      ...s,
      0,
      0,
      16,
      0,
      65,
      ...asPublic,
      ...ciphertext,
    ]);
  }

  static String authorization(
    String endpoint,
    BigInt privateKey,
    DateTime now,
  ) {
    final u = Uri.parse(endpoint);
    final head = b64(utf8.encode(jsonEncode({'typ': 'JWT', 'alg': 'ES256'})));
    final body = b64(
      utf8.encode(
        jsonEncode({
          'aud': u.origin,
          'exp':
              now.add(const Duration(hours: 6)).millisecondsSinceEpoch ~/ 1000,
          'sub': 'https://alfinder.kr',
        }),
      ),
    );
    final message = '$head.$body';
    final signer = pc.ECDSASigner(
      pc.SHA256Digest(),
      pc.HMac(pc.SHA256Digest(), 64),
    )..init(true, pc.PrivateKeyParameter(pc.ECPrivateKey(privateKey, curve)));
    final signature = signer.generateSignature(
      Uint8List.fromList(utf8.encode(message)),
    ) as pc.ECSignature;
    return 'vapid t=$message.${b64([...octets(signature.r), ...octets(signature.s)])}, k=${b64(publicBytes(privateKey))}';
  }

  static Future<int> send(
    Session session,
    WebPushSubscription sub,
    Map<String, Object> payload, {
    http.Client? client,
  }) async {
    final key = _private.read(session);
    if (key == null) throw StateError('Push not configured');
    validate(sub.endpoint, sub.p256dh, sub.auth);
    final owned = client == null;
    final transport = client ?? http.Client();
    try {
      final request = http.Request('POST', Uri.parse(sub.endpoint))
        ..followRedirects = false;
      request.headers.addAll({
        'Authorization': authorization(
          sub.endpoint,
          integer(decode(key)),
          DateTime.now().toUtc(),
        ),
        'TTL': '3600',
        'Urgency': 'normal',
        'Content-Encoding': 'aes128gcm',
        'Content-Type': 'application/octet-stream',
      });
      request.bodyBytes = encrypt(
        utf8.encode(jsonEncode(payload)),
        sub.p256dh,
        sub.auth,
      );
      final response = await transport
          .send(request)
          .timeout(const Duration(seconds: 10));
      await response.stream.drain<void>().timeout(const Duration(seconds: 10));
      return response.statusCode;
    } finally {
      if (owned) transport.close();
    }
  }
}
