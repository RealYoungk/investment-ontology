import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import 'features/auth/rejected_refresh_handler.dart';

// When you are running the app on a physical device, you need to set the
// server URL to the IP address of your computer. You can find the IP
// address by running `ipconfig` on Windows or `ifconfig` on Mac/Linux.
//
// You can set the variable when running or building your app like this:
// E.g. `flutter run --dart-define=SERVER_URL=https://api.example.com/`.
//
// Otherwise, the server URL is fetched from the assets/config.json file or
// defaults to http://$localhost:8080/ if not found.
final serverUrl = _resolveServerUrl();

/// API 주소를 정한다.
///
/// 1. `--dart-define=SERVER_URL=...` 가 있으면 그것.
/// 2. 웹에서 http로 열었으면 **앱을 내려받은 그 host의 8080**. 맥을 서버로 두고 집
///    네트워크로 들어올 때, 주소마다 다시 빌드하지 않아도 된다.
/// 3. 웹에서 https로 열었으면 **같은 주소의 `/api/`**. Tailscale serve나 Caddy처럼
///    앞단이 한 주소로 앱과 API를 같이 내보내는 경우다 (`deploy/Caddyfile` 참고).
/// 4. 나머지는 Serverpod 기본 (assets/config.json → localhost:8080).
Future<String> _resolveServerUrl() async {
  const fromEnv = String.fromEnvironment('SERVER_URL');
  final base = Uri.base;
  if (fromEnv.isNotEmpty) {
    final configured = Uri.parse(fromEnv);
    // A LAN browser must call the laptop, rather than its own localhost.
    if (kIsWeb &&
        base.scheme == 'http' &&
        base.host.isNotEmpty &&
        base.host != 'localhost' &&
        base.host != '127.0.0.1' &&
        (configured.host == 'localhost' || configured.host == '127.0.0.1')) {
      return configured.replace(host: base.host).toString();
    }
    return fromEnv;
  }
  if (kIsWeb && base.host.isNotEmpty) {
    if (base.scheme == 'https') return '${base.origin}/api/';
    if (base.scheme == 'http' &&
        base.host != 'localhost' &&
        base.host != '127.0.0.1') {
      return '${Uri(scheme: 'http', host: base.host, port: 8080)}/';
    }
  }
  return getServerUrl();
}

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app. The client is generated from your server code
/// and is set up to connect to a Serverpod running on a local server on
/// the default port. You will need to modify this to connect to staging or
/// production servers.
/// In a larger app, you may want to use the dependency injection of your choice
/// instead of using a global client object. This is just a simple example.
late final Client client;

Future<void> initializeClient() async {
  client =
      Client(
          await serverUrl,
          onFailedCall: (context, error, stackTrace) async {
            await handleRejectedRefresh(
              context,
              error,
              clearLocalSession: () => client.auth.updateSignedInUser(null),
            );
          },
        )
        ..connectivityMonitor = FlutterConnectivityMonitor()
        ..authSessionManager = FlutterAuthSessionManager(
          storage: const bool.fromEnvironment('LOCAL_PREVIEW_SESSION')
              ? _PreviewSessionStorage()
              : null,
        );
  if (kIsWeb) client.cookieAuth = true;
  // 저장된 로그인을 되살리고 서버에 확인한 뒤에야 첫 화면을 정한다 (로그인 문이 로그인
  // 화면과 앱 사이를 깜빡이지 않게). 서버가 늦거나 꺼져 있으면 시간 초과가 밖으로
  // 나오는데, 그때는 되살린 로그인을 그대로 쓰고 다음 요청에서 다시 확인된다.
  try {
    await client.auth.initialize();
  } catch (_) {}
}

/// Explicit isolated-review build only: no credentials are persisted on HTTP.
class _PreviewSessionStorage implements ClientAuthSuccessStorage {
  AuthSuccess? _value;
  @override
  Future<AuthSuccess?> get() async => _value;
  @override
  Future<void> set(AuthSuccess? data) async {
    _value = data;
  }
}
