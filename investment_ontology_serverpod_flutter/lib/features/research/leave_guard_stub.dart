/// Asks before the browser tab is closed or reloaded; nothing to do off the web.
class LeaveGuard {
  LeaveGuard(this.active);
  final bool Function() active;
  void attach() {}
  void detach() {}
}
