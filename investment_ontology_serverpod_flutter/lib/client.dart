import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

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
///    네트워크나 Tailscale로 들어올 때, 주소마다 다시 빌드하지 않아도 된다.
/// 3. 나머지는 Serverpod 기본 (assets/config.json → localhost:8080).
Future<String> _resolveServerUrl() async {
  const fromEnv = String.fromEnvironment('SERVER_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  final base = Uri.base;
  if (kIsWeb &&
      base.scheme == 'http' &&
      base.host.isNotEmpty &&
      base.host != 'localhost' &&
      base.host != '127.0.0.1') {
    return '${Uri(scheme: 'http', host: base.host, port: 8080)}/';
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
  client = Client(await serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();
  unawaited(client.auth.initialize());
}
