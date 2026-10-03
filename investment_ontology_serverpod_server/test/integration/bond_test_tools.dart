import 'package:investment_ontology_serverpod_server/src/generated/endpoints.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test/serverpod_test.dart';
export 'package:serverpod_test/serverpod_test.dart';

/// Small handwritten harness for the pinned serverpod_test 4.0.0 API.
/// Uses real endpoint dispatch, auth overrides and the isolated test database.
/// The installed generator emits a newer TestServerpod constructor, so no
/// generated file is patched to make this test run.
void withBondServerpod(String label, TestClosure<BondTestEndpoints> closure) {
  buildWithServerpod<BondTestEndpoints>(
    label,
    TestServerpod(
      testEndpoints: BondTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: null,
      applyMigrations: null,
      isDatabaseEnabled: true,
      serverpodLoggingMode: null,
      testServerOutputMode: null,
    ),
    maybeRollbackDatabase: null,
    maybeEnableSessionLogging: null,
    maybeTestGroupTagsOverride: null,
    maybeServerpodStartTimeout: null,
    maybeTestServerOutputMode: null,
  )(closure);
}

extension BondTestAuth on TestSessionBuilder {
  TestSessionBuilder get asAnonymous =>
      copyWith(authentication: AuthenticationOverride.unauthenticated());
  TestSessionBuilder get asReader => copyWith(
    authentication: AuthenticationOverride.authenticationInfo(
      '00000000-0000-4000-8000-000000000001',
      {},
    ),
  );
}

class BondTestEndpoints implements InternalTestEndpoints {
  late EndpointDispatch _dispatch;
  late DatabaseSerializationManager _serialization;
  BondTestEndpoints get bond => this;
  @override
  void initialize(
    DatabaseSerializationManager serializationManager,
    EndpointDispatch endpoints,
  ) {
    _dispatch = endpoints;
    _serialization = serializationManager;
  }

  Future<String> trends(TestSessionBuilder builder, String code) =>
      _call(builder, 'trends', code);
  Future<String> collect(TestSessionBuilder builder, String code) =>
      _call(builder, 'collect', code);
  Future<String> _call(
    TestSessionBuilder builder,
    String method,
    String code,
  ) => callAwaitableFunctionAndHandleExceptions(() async {
    final session = (builder as InternalTestSessionBuilder).internalBuild(
      endpoint: 'bond',
      method: method,
    );
    try {
      final context = await _dispatch.getMethodCallContext(
        createSessionCallback: (_) => session,
        endpointPath: 'bond',
        methodName: method,
        parameters: testObjectToJson({'corpCode': code}),
        serializationManager: _serialization,
      );
      return await (context.method.call(session, context.arguments)
          as Future<String>);
    } finally {
      await session.close();
    }
  });
}
