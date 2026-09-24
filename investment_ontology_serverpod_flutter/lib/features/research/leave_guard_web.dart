import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Asks before the browser tab is closed or reloaded while [active] is true.
///
/// Router navigation is guarded by `onExit`/`PopScope`; closing the tab,
/// reloading or typing another address never reaches the router.
class LeaveGuard {
  LeaveGuard(this.active);
  final bool Function() active;
  late final JSFunction _listener = _onBeforeUnload.toJS;

  void _onBeforeUnload(web.BeforeUnloadEvent event) {
    if (!active()) return;
    event.preventDefault();
    event.returnValue = '';
  }

  void attach() => web.window.addEventListener('beforeunload', _listener);
  void detach() => web.window.removeEventListener('beforeunload', _listener);
}
