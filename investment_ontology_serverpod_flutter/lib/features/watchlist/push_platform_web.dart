import 'dart:js_interop';

@JS('alfinderPush.status')
external JSPromise<JSString> _status();
@JS('alfinderPush.enable')
external JSPromise<JSString> _enable(JSString key, JSString owner);
@JS('alfinderPush.endpoint')
external JSPromise<JSAny?> _endpoint();
@JS('alfinderPush.disable')
external JSPromise<JSAny?> _disable();
Future<String> pushStatus() async => (await _status().toDart).toDart;
Future<String> enablePush(String key, String owner) async =>
    (await _enable(key.toJS, owner.toJS).toDart).toDart;
Future<String?> pushEndpoint() async =>
    (await _endpoint().toDart as JSString?)?.toDart;
Future<void> disablePush() async {
  await _disable().toDart;
}
