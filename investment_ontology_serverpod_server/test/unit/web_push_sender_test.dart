import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:investment_ontology_serverpod_server/src/ontology/watchlist/web_push_sender.dart';

void main() {
  test('RFC 8291 published encryption vector', () {
    final bytes = WebPushSender.encrypt(
      utf8.encode('When I grow up, I want to be a watermelon'),
      'BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4',
      'BTBZMqHH6r4Tts7J_aSIgg',
      ephemeralSecret: WebPushSender.integer(
        WebPushSender.decode('yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw'),
      ),
      salt: WebPushSender.decode('DGv6ra1nlYgDCS1FRnbzlw'),
    );
    expect(
      WebPushSender.b64(bytes),
      'DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN',
    );
  });
  test('VAPID signature verifies and expires within one day', () {
    final now = DateTime.utc(2026, 10, 1);
    final key = BigInt.from(42);
    final header = WebPushSender.authorization(
      'https://fcm.googleapis.com/a',
      key,
      now,
    );
    final jwt = header.split('t=')[1].split(',')[0].split('.');
    final claims = jsonDecode(utf8.decode(WebPushSender.decode(jwt[1])));
    expect(claims['aud'], 'https://fcm.googleapis.com');
    expect(
      claims['exp'],
      now.add(const Duration(hours: 6)).millisecondsSinceEpoch ~/ 1000,
    );
    final signature = WebPushSender.decode(jwt[2]);
    final verifier = pc.ECDSASigner(pc.SHA256Digest())
      ..init(
        false,
        pc.PublicKeyParameter(
          pc.ECPublicKey(WebPushSender.curve.G * key, WebPushSender.curve),
        ),
      );
    expect(
      verifier.verifySignature(
        Uint8List.fromList(utf8.encode('${jwt[0]}.${jwt[1]}')),
        pc.ECSignature(
          WebPushSender.integer(signature.sublist(0, 32)),
          WebPushSender.integer(signature.sublist(32)),
        ),
      ),
      isTrue,
    );
  });
  test('rejects internal endpoints and deceptive provider hostnames', () {
    for (final url in [
      'http://fcm.googleapis.com/a',
      'https://127.0.0.1/a',
      'https://fcm.googleapis.com.attacker.com/a',
      'https://x@fcm.googleapis.com/a',
      'https://fcm.googleapis.com:8443/a',
    ]) {
      expect(WebPushSender.validEndpoint(url), isFalse, reason: url);
    }
    expect(WebPushSender.validEndpoint('https://web.push.apple.com/a'), isTrue);
  });
}
