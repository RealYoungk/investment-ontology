Future<String> pushStatus() async => 'unsupported';
Future<String> enablePush(String key, String owner) async =>
    throw UnsupportedError('기기 알림은 지원되는 브라우저에서 켤 수 있습니다.');
Future<String?> pushEndpoint() async => null;
Future<void> disablePush() async {}
