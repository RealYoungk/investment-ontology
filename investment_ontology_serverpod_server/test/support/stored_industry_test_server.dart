import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test/serverpod_test.dart';

import 'package:investment_ontology_serverpod_server/src/generated/endpoints.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

/// Focused harness for installed serverpod_test 4.0.0. The current CLI's
/// generated group helper passes a newer unsupported ephemeralDatabase option.
/// Invoke the real generated dispatch without modifying any generated file.
void withIndustryServerpod(
  String name,
  TestClosure<StoredIndustryTestEndpoints> tests,
) {
  buildWithServerpod<StoredIndustryTestEndpoints>(
    name,
    TestServerpod(
      testEndpoints: StoredIndustryTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      isDatabaseEnabled: true,
      applyMigrations: true,
      runMode: 'test',
      serverpodLoggingMode: null,
      testServerOutputMode: null,
      configOverride: (config) =>
          config.copyWith(futureCallExecutionEnabled: false),
    ),
    maybeRollbackDatabase: null,
    maybeEnableSessionLogging: null,
    maybeTestGroupTagsOverride: null,
    maybeServerpodStartTimeout: null,
    maybeTestServerOutputMode: null,
  )(tests);
}

class StoredIndustryTestEndpoints implements InternalTestEndpoints {
  late final StoredIndustryCalls industry;

  @override
  void initialize(
    DatabaseSerializationManager serializationManager,
    EndpointDispatch endpoints,
  ) {
    industry = StoredIndustryCalls(endpoints, serializationManager);
  }
}

class StoredIndustryCalls {
  StoredIndustryCalls(this.dispatch, this.protocol);
  final EndpointDispatch dispatch;
  final DatabaseSerializationManager protocol;

  Future<IndustryDiscovery> browse(
    TestSessionBuilder builder, {
    String? industry,
  }) => _call(builder, 'browse', {'industry': industry});

  Future<IndustryDiscovery> discover(TestSessionBuilder builder) =>
      _call(builder, 'discover', {});

  Future<IndustryDiscovery> rebuild(TestSessionBuilder builder) =>
      _call(builder, 'rebuild', {});

  Future<IndustryDiscovery> _call(
    TestSessionBuilder builder,
    String method,
    Map<String, Object?> parameters,
  ) => callAwaitableFunctionAndHandleExceptions(() async {
    final session = (builder as InternalTestSessionBuilder).internalBuild(
      endpoint: 'industry',
      method: method,
    );
    try {
      final call = await dispatch.getMethodCallContext(
        createSessionCallback: (_) => session,
        endpointPath: 'industry',
        methodName: method,
        parameters: testObjectToJson(parameters),
        serializationManager: protocol,
      );
      return await (call.method.call(session, call.arguments)
          as Future<IndustryDiscovery>);
    } finally {
      await session.close();
    }
  });
}
