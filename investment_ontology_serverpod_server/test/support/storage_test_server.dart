import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test/serverpod_test.dart';

import 'package:investment_ontology_serverpod_server/src/generated/endpoints.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

/// Storage-only tests use the installed Serverpod test API directly. No runtime
/// server, credentials, authentication override or generated RPC tools involved.
final class StorageTestEndpoints implements InternalTestEndpoints {
  @override
  void initialize(
    DatabaseSerializationManager serializationManager,
    EndpointDispatch endpoints,
  ) {}
}

void withStorageServerpod(
  String name,
  TestClosure<StorageTestEndpoints> tests,
) {
  buildWithServerpod<StorageTestEndpoints>(
    name,
    TestServerpod(
      applyMigrations: true,
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      isDatabaseEnabled: true,
      testEndpoints: StorageTestEndpoints(),
      serverpodLoggingMode: null,
      runMode: 'test',
      testServerOutputMode: null,
    ),
    maybeRollbackDatabase: null,
    maybeEnableSessionLogging: false,
    maybeTestGroupTagsOverride: null,
    maybeServerpodStartTimeout: null,
    maybeTestServerOutputMode: null,
  )(tests);
}
