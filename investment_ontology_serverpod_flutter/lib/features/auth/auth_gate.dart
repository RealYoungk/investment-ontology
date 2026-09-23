import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app_viewer.dart';

/// 로그인 전에는 데이터 화면을 만들지 않고, 로그인 뒤 원래 주소를 유지한다.
/// 계정 교체 때는 한 프레임 동안 라우터를 내려 Navigator의 GlobalKey 상태도 폐기한다.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.viewer,
    required this.signIn,
    required this.child,
    this.allowAnonymous = false,
  });

  final ValueListenable<AppViewer?> viewer;
  final Widget signIn;
  final Widget child;
  final bool allowAnonymous;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AppViewer? _current;
  bool _switching = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.viewer.value;
    widget.viewer.addListener(_changed);
  }

  @override
  void didUpdateWidget(AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewer != widget.viewer) {
      oldWidget.viewer.removeListener(_changed);
      widget.viewer.addListener(_changed);
      _changed();
    }
  }

  void _changed() {
    final next = widget.viewer.value;
    final generation = ++_generation;
    if (_current != null && next != null && _current!.userId != next.userId) {
      setState(() {
        _current = null;
        _switching = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _current = widget.viewer.value;
          _switching = false;
        });
      });
      return;
    }
    setState(() {
      _current = next;
      _switching = false;
    });
  }

  @override
  void dispose() {
    widget.viewer.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_switching) return const SizedBox.shrink();
    final current = _current;
    if (current == null && !widget.allowAnonymous) {
      // ラウ터 바깥에서도 인증 폼에 Navigator/Overlay를 제공한다.
      return Navigator(
        key: const ValueKey('sign-in'),
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => widget.signIn),
      );
    }
    return AppViewerScope(viewer: current, child: widget.child);
  }
}
