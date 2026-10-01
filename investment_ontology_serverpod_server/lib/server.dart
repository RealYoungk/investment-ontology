import 'dart:io';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

import 'src/cache_busting.dart';
import 'src/ontology/auth/admin_provisioning.dart';
import 'src/ontology/auth/account_security.dart';
import 'src/generated/serverpod.dart';
import 'src/ontology/ingest/ingest_schedule.dart';
import 'src/web/routes/app_config_route.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod. The generated Serverpod class is already connected
  // with your project's generated code.
  final pod = Serverpod(args);

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      // Authentication mail uses the configured transactional email provider.
      AdminProvisioning.fromEnvironment().configuration(),
    ],
  );

  pod.authenticationHandler = AccountSecurity.authenticate;

  // Serve all files in the web/static relative directory under /web.
  // These are used by the default web page.
  pod.webServer.addRoute(
    StaticRoute.withCacheBusting(cacheBustingConfig),
    cacheBustingConfig.mountPrefix,
  );

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/assets/assets/config.json',
  );

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under /.
    pod.webServer.addRoute(
      FlutterRoute(
        appDir,
        // If building the Flutter app with WASM, set the below parameter to
        // true and add the --wasm flag to the flutter build command.
        enableWasmHeaders: false,
      ),
      '/',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    final defaultRoute = StaticRoute.file(
      File(
        Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
      ),
    );

    pod.webServer.addMiddleware(
      FallbackMiddleware(
        fallback: defaultRoute,
        on: (response) => response.statusCode == 404,
      ).call,
      '/',
    );

    pod.webServer.addRoute(
      defaultRoute,
      '/**',
    );
  }

  // Configure cloud storage.
  // This setup works with Serverpod Cloud without extra configuration.
  // If you want to use a custom provider for cloud storage, replace these
  // with your preferred provider.
  pod.addCloudStorage(
    await ServerpodCloudProvider.private(
      fallback: () => DatabaseCloudStorage('private'),
    ),
  );
  pod.addCloudStorage(
    await ServerpodCloudProvider.public(
      fallback: () => DatabaseCloudStorage('public'),
    ),
  );

  // 수집 예약 함수를 서버 시작 전에 넣는다. pod.start()가 FutureCall 실행을 시작하므로,
  // 그 전에 없으면 끊겼다 다시 실행되는 수집이 이어받기 예약 없이 돈다.
  IngestSchedule.installHooks();

  // Start the server.
  await pod.start();

  // 조회 전용 배포는 작업을 복구하거나 예약하지 않는다. 같은 DB를 쓰는
  // 수집 worker의 실행 중 작업을 끊긴 작업으로 오인하지 않도록 한다.
  if (!pod.config.futureCallExecutionEnabled) return;

  // 끊긴 수집을 정리·이어받고, 시세·재무 매일 자동 수집을 예약한다.
  final session = await pod.createSession(enableLogging: false);
  try {
    await IngestSchedule.onServerStart(session);
  } finally {
    await session.close();
  }
}
