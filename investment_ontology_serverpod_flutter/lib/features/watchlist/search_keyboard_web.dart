import 'package:web/web.dart' as web;

web.HTMLInputElement? _input;

/// WebKit needs focus inside the original tap, before Flutter mounts the sheet.
/// Flutter takes over the input when its autofocus field is mounted.
void prepareSearchKeyboard() {
  if (!RegExp(r'iPhone|iPad|iPod').hasMatch(web.window.navigator.userAgent)) {
    return;
  }
  releaseSearchKeyboard();
  final input = web.HTMLInputElement()
    ..type = 'text'
    ..tabIndex = -1;
  input.style
    ..position = 'fixed'
    ..left = '0'
    ..top = '0'
    ..width = '1px'
    ..height = '1px'
    ..opacity = '0'
    ..fontSize = '16px'
    ..pointerEvents = 'none';
  web.document.body?.append(input);
  _input = input;
  input.focus();
}

void releaseSearchKeyboard() {
  _input?.remove();
  _input = null;
}
