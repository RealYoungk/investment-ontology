import 'package:flutter/widgets.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../client.dart';
import 'app_viewer.dart';
import '../monetization/membership_monitor.dart';

/// 클라이언트의 로그인 상태를 앱의 [AppViewer]로 옮긴다.
///
/// 역할 표시는 로그인 응답의 스코프를 따른다. 막는 것은 언제나 서버다 —
/// 로그인한 뒤 관리자 권한을 받았다면 토큰이 갱신되거나 다시 로그인해야 표시가 바뀐다.
abstract final class AppAuth {
  static final viewer = ValueNotifier<AppViewer?>(null);

  static bool _bound = false;
  static final _source = ValueNotifier<AppViewer?>(null);
  static MembershipMonitor? _membership;
  static AppLifecycleListener? _lifecycle;

  static Future<void> refreshMembership() async => _membership?.refresh();

  /// [initializeClient] 뒤에 한 번.
  static void bind(FlutterAuthSessionManager auth) {
    if (_bound) return;
    _bound = true;
    final monitor = _membership = MembershipMonitor(
      source: _source,
      fetch: () => client.membership.status(),
    );
    monitor.viewer.addListener(() => viewer.value = monitor.viewer.value);
    _lifecycle ??= AppLifecycleListener(onResume: () => refreshMembership());
    void sync() {
      final info = auth.authInfo;
      _source.value = info == null
          ? null
          : AppViewer.fromScopes(info.authUserId.uuid, info.scopeNames);
    }

    auth.authInfoListenable.addListener(sync);
    sync();
  }

  /// 이 기기에서 로그아웃. 서버에 알리지 못해도 기기의 로그인은 지운다.
  static Future<void> signOut() => client.auth.signOutDevice();
}
