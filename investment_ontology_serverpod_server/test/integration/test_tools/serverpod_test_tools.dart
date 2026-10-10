/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: no_leading_underscores_for_local_identifiers

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'dart:io' as _idi;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls.dart'
    as _i4o8e4lj;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/ai_extraction_future_call_run_model.dart'
    as _i7nmjhom;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/company_master_future_call_run_model.dart'
    as _i5djsspn;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/disclosure_future_call_run_business_model.dart'
    as _imre8mrn;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/disclosure_future_call_run_company_model.dart'
    as _iwtdffgy;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/disclosure_future_call_run_model.dart'
    as _iiylg3o5;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/financial_facts_future_call_run_company_model.dart'
    as _iks5abhc;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/financial_facts_future_call_run_model.dart'
    as _iqf3b55q;
import 'package:investment_ontology_serverpod_server/src/generated/future_calls_generated_models/market_snapshot_future_call_run_model.dart'
    as _i0e4uq1b;
import 'package:investment_ontology_serverpod_server/src/generated/greetings/greeting.dart'
    as _isd101g2;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/billing/billing_checkout_view.dart'
    as _i9ji3lii;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/billing/billing_payment_view.dart'
    as _iw7zbyvm;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/billing/membership_view.dart'
    as _irqqq4jy;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/account_view.dart'
    as _ig2zry29;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/ai_extraction.dart'
    as _i5zcz6ng;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/ai_status.dart'
    as _iabynv8u;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/business_document_ref.dart'
    as _i9fapywb;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/company_financials.dart'
    as _imylp7bk;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/company_group.dart'
    as _i4udlom4;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/document_fact.dart'
    as _ihq2wng4;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/document_fact_kind.dart'
    as _i1rhjzgf;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/fact_page.dart'
    as _i43txb4s;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/financial_report_detail.dart'
    as _ip1nebyh;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/fs_div.dart'
    as _i69nddnn;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/industry_discovery.dart'
    as _iqqk20wh;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/ingest_coverage.dart'
    as _ixl8qyld;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/ingest_job.dart'
    as _idt86amb;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/ingest_schedule_entry.dart'
    as _irm0258u;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/macro_series_view.dart'
    as _ikb4l1o7;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/ontology_relation.dart'
    as _i5x2f28w;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/relation_predicate.dart'
    as _iw7mt1ku;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/relation_status.dart'
    as _iy39k7od;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/review_check.dart'
    as _iwp9ei5l;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/review_context.dart'
    as _icjfwfa9;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/review_item.dart'
    as _ip1s5ejx;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/review_page.dart'
    as _icif05qz;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/watchlist_view.dart'
    as _i3b3h5jl;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_test/serverpod_test.dart' as _ist;
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/generated/endpoints.dart';
export 'package:serverpod_test/serverpod_test_public_exports.dart';

/// Creates a new test group that takes a callback that can be used to write tests.
/// The callback has two parameters: `sessionBuilder` and `endpoints`.
/// `sessionBuilder` is used to build a `Session` object that represents the server state during an endpoint call and is used to set up scenarios.
/// `endpoints` contains all your Serverpod endpoints and lets you call them:
/// ```dart
/// withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
///   test('when calling `hello` then should return greeting', () async {
///     final greeting = await endpoints.example.hello(sessionBuilder, 'Michael');
///     expect(greeting, 'Hello Michael');
///   });
/// });
/// ```
///
/// **Configuration options**
///
/// [applyMigrations] Whether pending migrations should be applied when starting Serverpod. Defaults to `true`
///
/// [enableSessionLogging] Whether session logging should be enabled. Defaults to `false`
///
/// [ephemeralDatabase] Whether this group gets its own empty database, created when the group starts and dropped when it finishes. Defaults to `true`.
/// Set this to `false` to use the database configured for [runMode], including a previously seeded database. [configOverride] can still replace that database. The configured database is not created or dropped, so groups that share it cannot run in parallel. [rollbackDatabase] still controls whether writes inside the group are rolled back.
///
/// [rollbackDatabase] Options for when to rollback the database during the test lifecycle.
/// By default `withServerpod` does all database operations inside a transaction that is rolled back after each `test` case.
/// Just like the following enum describes, the behavior of the automatic rollbacks can be configured:
/// ```dart
/// /// Options for when to rollback the database during the test lifecycle.
/// enum RollbackDatabase {
///   /// After each test. This is the default.
///   afterEach,
///
///   /// After all tests.
///   afterAll,
///
///   /// Disable rolling back the database.
///   disabled,
/// }
/// ```
///
/// [runMode] The run mode that Serverpod should be running in. Defaults to `test`.
///
/// [serverpodLoggingMode] The logging mode used when creating Serverpod. Defaults to `ServerpodLoggingMode.normal`
///
/// [serverpodStartTimeout] The timeout to use when starting Serverpod, which connects to the database among other things. Defaults to `Duration(seconds: 120)`.
///
/// [testServerOutputMode] Options for controlling test server output during test execution. Defaults to `TestServerOutputMode.normal`.
/// ```dart
/// /// Options for controlling test server output during test execution.
/// enum TestServerOutputMode {
///   /// Default mode - only stderr is printed (stdout suppressed).
///   /// This hides normal startup/shutdown logs while preserving error messages.
///   normal,
///
///   /// All logging - both stdout and stderr are printed.
///   /// Useful for debugging when you need to see all server output.
///   verbose,
///
///   /// No logging - both stdout and stderr are suppressed.
///   /// Completely silent mode, useful when you don't want any server output.
///   silent,
/// }
/// ```
///
/// [configOverride] A function to override the server configuration. This function is called with
/// the default server configuration after it is loaded from the config/ directory
/// and before it is used to start the server. Use this to override particular
/// settings in the server configuration.
///
/// [databaseInterceptor] Optional interceptor that replaces the default database for each session.
/// See [Serverpod.databaseInterceptor] for more information.
///
/// [testGroupTagsOverride] By default Serverpod test tools tags the `withServerpod` test group with `"integration"`.
/// This is to provide a simple way to only run unit or integration tests.
/// This property allows this tag to be overridden to something else. Defaults to `['integration']`.
///
/// [experimentalFeatures] Optionally specify experimental features. See [Serverpod] for more information.
///
/// [serverDirectory] The server package directory `config/<runMode>.yaml`, `config/passwords.yaml`,
/// and `migrations/<module>/...` are resolved against. Defaults to
/// [Directory.current] at the time the test boots. Pass this when the test
/// isolate's cwd is not the server package root (e.g. running tests from a
/// workspace parent directory) so config and migrations are still loaded
/// from the right place.
@_ist.isTestGroup
void withServerpod(
  String testGroupName,
  _ist.TestClosure<TestEndpoints> testClosure, {
  bool? applyMigrations,
  _is.ServerpodConfig Function(_is.ServerpodConfig)? configOverride,
  _is.DatabaseInterceptor? databaseInterceptor,
  bool? enableSessionLogging,
  bool? ephemeralDatabase,
  _is.ExperimentalFeatures? experimentalFeatures,
  _ist.RollbackDatabase? rollbackDatabase,
  String? runMode,
  _is.RuntimeParametersListBuilder? runtimeParametersBuilder,
  _idi.Directory? serverDirectory,
  _is.ServerpodLoggingMode? serverpodLoggingMode,
  Duration? serverpodStartTimeout,
  List<String>? testGroupTagsOverride,
  _ist.TestServerOutputMode? testServerOutputMode,
}) {
  _ist.buildWithServerpod<_InternalTestEndpoints>(
    testGroupName,
    _ist.TestServerpod(
      testEndpoints: _InternalTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: runMode,
      applyMigrations: applyMigrations,
      ephemeralDatabase: ephemeralDatabase,
      isDatabaseEnabled: true,
      serverpodLoggingMode: serverpodLoggingMode,
      testServerOutputMode: testServerOutputMode,
      serverDirectory: serverDirectory,
      experimentalFeatures: experimentalFeatures,
      configOverride: configOverride,
      runtimeParametersBuilder: runtimeParametersBuilder,
      databaseInterceptor: databaseInterceptor,
    ),
    maybeRollbackDatabase: rollbackDatabase,
    maybeEnableSessionLogging: enableSessionLogging,
    maybeTestGroupTagsOverride: testGroupTagsOverride,
    maybeServerpodStartTimeout: serverpodStartTimeout,
    maybeTestServerOutputMode: testServerOutputMode,
  )(testClosure);
}

class TestEndpoints {
  late final futureCalls = _FutureCalls();

  late final _EmailIdpEndpoint emailIdp;

  late final _JwtRefreshEndpoint jwtRefresh;

  late final _GreetingEndpoint greeting;

  late final _AccountEndpoint account;

  late final _AiEndpoint ai;

  late final _BondEndpoint bond;

  late final _CapitalEndpoint capital;

  late final _CharterEndpoint charter;

  late final _ResearchEndpoint research;

  late final _FinancialEndpoint financial;

  late final _GroupEndpoint group;

  late final _IndustryEndpoint industry;

  late final _IngestEndpoint ingest;

  late final _InvestmentNotesEndpoint investmentNotes;

  late final _MacroEndpoint macro;

  late final _MembershipEndpoint membership;

  late final _MembershipOfferEndpoint membershipOffer;

  late final _ReviewEndpoint review;

  late final _WatchlistEndpoint watchlist;
}

class _InternalTestEndpoints extends TestEndpoints
    implements _ist.InternalTestEndpoints {
  @override
  void initialize(
    _is.SerializationManager serializationManager,
    _is.EndpointDispatch endpoints,
  ) {
    emailIdp = _EmailIdpEndpoint(
      endpoints,
      serializationManager,
    );
    jwtRefresh = _JwtRefreshEndpoint(
      endpoints,
      serializationManager,
    );
    greeting = _GreetingEndpoint(
      endpoints,
      serializationManager,
    );
    account = _AccountEndpoint(
      endpoints,
      serializationManager,
    );
    ai = _AiEndpoint(
      endpoints,
      serializationManager,
    );
    bond = _BondEndpoint(
      endpoints,
      serializationManager,
    );
    capital = _CapitalEndpoint(
      endpoints,
      serializationManager,
    );
    charter = _CharterEndpoint(
      endpoints,
      serializationManager,
    );
    research = _ResearchEndpoint(
      endpoints,
      serializationManager,
    );
    financial = _FinancialEndpoint(
      endpoints,
      serializationManager,
    );
    group = _GroupEndpoint(
      endpoints,
      serializationManager,
    );
    industry = _IndustryEndpoint(
      endpoints,
      serializationManager,
    );
    ingest = _IngestEndpoint(
      endpoints,
      serializationManager,
    );
    investmentNotes = _InvestmentNotesEndpoint(
      endpoints,
      serializationManager,
    );
    macro = _MacroEndpoint(
      endpoints,
      serializationManager,
    );
    membership = _MembershipEndpoint(
      endpoints,
      serializationManager,
    );
    membershipOffer = _MembershipOfferEndpoint(
      endpoints,
      serializationManager,
    );
    review = _ReviewEndpoint(
      endpoints,
      serializationManager,
    );
    watchlist = _WatchlistEndpoint(
      endpoints,
      serializationManager,
    );
  }
}

class _FutureCalls {
  late final aiExtraction = _AiExtractionFutureCall();

  late final billing = _BillingFutureCall();

  late final charter = _CharterFutureCall();

  late final companyMaster = _CompanyMasterFutureCall();

  late final disclosure = _DisclosureFutureCall();

  late final financialFacts = _FinancialFactsFutureCall();

  late final marketSnapshot = _MarketSnapshotFutureCall();

  late final watchlist = _WatchlistFutureCall();
}

class _EmailIdpEndpoint {
  _EmailIdpEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> login(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
    required String password,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'login',
          parameters: _ist.testObjectToJson({
            'email': email,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_is.UuidValue> startRegistration(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startRegistration',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_is.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> verifyRegistrationCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue accountRequestId,
    required String verificationCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyRegistrationCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyRegistrationCode',
          parameters: _ist.testObjectToJson({
            'accountRequestId': accountRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iacs.AuthSuccess> finishRegistration(
    _ist.TestSessionBuilder sessionBuilder, {
    required String registrationToken,
    required String password,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishRegistration',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishRegistration',
          parameters: _ist.testObjectToJson({
            'registrationToken': registrationToken,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_is.UuidValue> startPasswordReset(
    _ist.TestSessionBuilder sessionBuilder, {
    required String email,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'startPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'startPasswordReset',
          parameters: _ist.testObjectToJson({'email': email}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_is.UuidValue>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> verifyPasswordResetCode(
    _ist.TestSessionBuilder sessionBuilder, {
    required _is.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'verifyPasswordResetCode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'verifyPasswordResetCode',
          parameters: _ist.testObjectToJson({
            'passwordResetRequestId': passwordResetRequestId,
            'verificationCode': verificationCode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> finishPasswordReset(
    _ist.TestSessionBuilder sessionBuilder, {
    required String finishPasswordResetToken,
    required String newPassword,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'finishPasswordReset',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'finishPasswordReset',
          parameters: _ist.testObjectToJson({
            'finishPasswordResetToken': finishPasswordResetToken,
            'newPassword': newPassword,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<bool> hasAccount(_ist.TestSessionBuilder sessionBuilder) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'emailIdp',
            method: 'hasAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'emailIdp',
          methodName: 'hasAccount',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _JwtRefreshEndpoint {
  _JwtRefreshEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iacs.AuthSuccess> refreshAccessToken(
    _ist.TestSessionBuilder sessionBuilder, {
    String? refreshToken,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'jwtRefresh',
            method: 'refreshAccessToken',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'jwtRefresh',
          methodName: 'refreshAccessToken',
          parameters: _ist.testObjectToJson({'refreshToken': refreshToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iacs.AuthSuccess>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _GreetingEndpoint {
  _GreetingEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_isd101g2.Greeting> hello(
    _ist.TestSessionBuilder sessionBuilder,
    String name,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'greeting',
            method: 'hello',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'greeting',
          methodName: 'hello',
          parameters: _ist.testObjectToJson({'name': name}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_isd101g2.Greeting>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AccountEndpoint {
  _AccountEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<bool> mailConfigured(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'account',
            method: 'mailConfigured',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'account',
          methodName: 'mailConfigured',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ig2zry29.AccountView> me(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'account',
            method: 'me',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'account',
          methodName: 'me',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ig2zry29.AccountView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ig2zry29.AccountView>> list(
    _ist.TestSessionBuilder sessionBuilder, {
    required int offset,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'account',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'account',
          methodName: 'list',
          parameters: _ist.testObjectToJson({'offset': offset}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ig2zry29.AccountView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> updateAccess(
    _ist.TestSessionBuilder sessionBuilder,
    String userId, {
    required bool isAdmin,
    required bool blocked,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'account',
            method: 'updateAccess',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'account',
          methodName: 'updateAccess',
          parameters: _ist.testObjectToJson({
            'userId': userId,
            'isAdmin': isAdmin,
            'blocked': blocked,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> revokeSessions(
    _ist.TestSessionBuilder sessionBuilder, {
    String? userId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'account',
            method: 'revokeSessions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'account',
          methodName: 'revokeSessions',
          parameters: _ist.testObjectToJson({'userId': userId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> deleteMe(
    _ist.TestSessionBuilder sessionBuilder,
    String password,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'account',
            method: 'deleteMe',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'account',
          methodName: 'deleteMe',
          parameters: _ist.testObjectToJson({'password': password}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AiEndpoint {
  _AiEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iabynv8u.AiStatus> status(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'status',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'status',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iabynv8u.AiStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i5zcz6ng.AiExtraction> extractCompany(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'extractCompany',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'extractCompany',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i5zcz6ng.AiExtraction>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob> startBatch(
    _ist.TestSessionBuilder sessionBuilder, {
    int? limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'startBatch',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'startBatch',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_i9fapywb.BusinessDocumentRef>> pending(
    _ist.TestSessionBuilder sessionBuilder, {
    int? limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'pending',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'pending',
          parameters: _ist.testObjectToJson({'limit': limit}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i9fapywb.BusinessDocumentRef>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> documentText(
    _ist.TestSessionBuilder sessionBuilder,
    int documentId, {
    int? maxChars,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'documentText',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'documentText',
          parameters: _ist.testObjectToJson({
            'documentId': documentId,
            'maxChars': maxChars,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> documentTexts(
    _ist.TestSessionBuilder sessionBuilder, {
    int? limit,
    int? maxChars,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'documentTexts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'documentTexts',
          parameters: _ist.testObjectToJson({
            'limit': limit,
            'maxChars': maxChars,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i5zcz6ng.AiExtraction> submit(
    _ist.TestSessionBuilder sessionBuilder,
    int documentId,
    String answer, {
    String? model,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'submit',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'submit',
          parameters: _ist.testObjectToJson({
            'documentId': documentId,
            'answer': answer,
            'model': model,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i5zcz6ng.AiExtraction>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> submitDigest(
    _ist.TestSessionBuilder sessionBuilder,
    int documentId,
    String answer, {
    String? model,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'submitDigest',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'submitDigest',
          parameters: _ist.testObjectToJson({
            'documentId': documentId,
            'answer': answer,
            'model': model,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> submitFacts(
    _ist.TestSessionBuilder sessionBuilder,
    int documentId,
    String answer, {
    String? model,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ai',
            method: 'submitFacts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ai',
          methodName: 'submitFacts',
          parameters: _ist.testObjectToJson({
            'documentId': documentId,
            'answer': answer,
            'model': model,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _BondEndpoint {
  _BondEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String> trends(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bond',
            method: 'trends',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bond',
          methodName: 'trends',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> collect(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bond',
            method: 'collect',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bond',
          methodName: 'collect',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _CapitalEndpoint {
  _CapitalEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String> summary(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'capital',
            method: 'summary',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'capital',
          methodName: 'summary',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> collect(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'capital',
            method: 'collect',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'capital',
          methodName: 'collect',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _CharterEndpoint {
  _CharterEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_idt86amb.IngestJob> startCollection(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'charter',
            method: 'startCollection',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'charter',
          methodName: 'startCollection',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob?> advanceCollection(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'charter',
            method: 'advanceCollection',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'charter',
          methodName: 'advanceCollection',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob?> collectionStatus(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'charter',
            method: 'collectionStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'charter',
          methodName: 'collectionStatus',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> collectionCoverage(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'charter',
            method: 'collectionCoverage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'charter',
          methodName: 'collectionCoverage',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> summary(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'charter',
            method: 'summary',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'charter',
          methodName: 'summary',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ResearchEndpoint {
  _ResearchEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String> data(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
    String kind,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'research',
            method: 'data',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'research',
          methodName: 'data',
          parameters: _ist.testObjectToJson({
            'corpCode': corpCode,
            'kind': kind,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> preview(
    _ist.TestSessionBuilder sessionBuilder,
    String kind,
    String payload,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'research',
            method: 'preview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'research',
          methodName: 'preview',
          parameters: _ist.testObjectToJson({
            'kind': kind,
            'payload': payload,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> importFeed(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
    String kind,
    String payload,
    String provider,
    String sourceUrl,
    String rightsReference,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'research',
            method: 'importFeed',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'research',
          methodName: 'importFeed',
          parameters: _ist.testObjectToJson({
            'corpCode': corpCode,
            'kind': kind,
            'payload': payload,
            'provider': provider,
            'sourceUrl': sourceUrl,
            'rightsReference': rightsReference,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> collectBatch(
    _ist.TestSessionBuilder sessionBuilder,
    String kind, {
    required String afterCorpCode,
    required int limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'research',
            method: 'collectBatch',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'research',
          methodName: 'collectBatch',
          parameters: _ist.testObjectToJson({
            'kind': kind,
            'afterCorpCode': afterCorpCode,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> connectionStatus(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'research',
            method: 'connectionStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'research',
          methodName: 'connectionStatus',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> collect(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
    String kind,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'research',
            method: 'collect',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'research',
          methodName: 'collect',
          parameters: _ist.testObjectToJson({
            'corpCode': corpCode,
            'kind': kind,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _FinancialEndpoint {
  _FinancialEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_imylp7bk.CompanyFinancials?> summary(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode, {
    _i69nddnn.FsDiv? fsDiv,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'financial',
            method: 'summary',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'financial',
          methodName: 'summary',
          parameters: _ist.testObjectToJson({
            'corpCode': corpCode,
            'fsDiv': fsDiv,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_imylp7bk.CompanyFinancials?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ip1nebyh.FinancialReportDetail?> report(
    _ist.TestSessionBuilder sessionBuilder,
    int reportId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'financial',
            method: 'report',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'financial',
          methodName: 'report',
          parameters: _ist.testObjectToJson({'reportId': reportId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ip1nebyh.FinancialReportDetail?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _GroupEndpoint {
  _GroupEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_i4udlom4.CompanyGroup>> list(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'group',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'group',
          methodName: 'list',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_i4udlom4.CompanyGroup>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i4udlom4.CompanyGroup?> of(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'group',
            method: 'of',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'group',
          methodName: 'of',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i4udlom4.CompanyGroup?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _IndustryEndpoint {
  _IndustryEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_iqqk20wh.IndustryDiscovery> browse(
    _ist.TestSessionBuilder sessionBuilder, {
    String? industry,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'industry',
            method: 'browse',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'industry',
          methodName: 'browse',
          parameters: _ist.testObjectToJson({'industry': industry}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iqqk20wh.IndustryDiscovery>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iqqk20wh.IndustryDiscovery> discover(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'industry',
            method: 'discover',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'industry',
          methodName: 'discover',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iqqk20wh.IndustryDiscovery>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iqqk20wh.IndustryDiscovery> rebuild(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'industry',
            method: 'rebuild',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'industry',
          methodName: 'rebuild',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iqqk20wh.IndustryDiscovery>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _IngestEndpoint {
  _IngestEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_idt86amb.IngestJob> startCompanyMaster(
    _ist.TestSessionBuilder sessionBuilder, {
    bool? force,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'startCompanyMaster',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'startCompanyMaster',
          parameters: _ist.testObjectToJson({'force': force}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob> startFinancials(
    _ist.TestSessionBuilder sessionBuilder, {
    String? corpCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'startFinancials',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'startFinancials',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob> startDisclosures(
    _ist.TestSessionBuilder sessionBuilder, {
    String? corpCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'startDisclosures',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'startDisclosures',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob> startBusinessDocuments(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'startBusinessDocuments',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'startBusinessDocuments',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> rebuildDisclosureLinks(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'rebuildDisclosureLinks',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'rebuildDisclosureLinks',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob> startMarketSnapshot(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'startMarketSnapshot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'startMarketSnapshot',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob?> cancel(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'cancel',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'cancel',
          parameters: _ist.testObjectToJson({'jobId': jobId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ixl8qyld.IngestCoverage> coverage(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'coverage',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'coverage',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ixl8qyld.IngestCoverage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob?> latest(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'latest',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'latest',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_idt86amb.IngestJob?> latestOf(
    _ist.TestSessionBuilder sessionBuilder,
    String kind,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'latestOf',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'latestOf',
          parameters: _ist.testObjectToJson({'kind': kind}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_idt86amb.IngestJob?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_irm0258u.IngestScheduleEntry>> schedule(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'schedule',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'schedule',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_irm0258u.IngestScheduleEntry>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_idt86amb.IngestJob>> latestOfKinds(
    _ist.TestSessionBuilder sessionBuilder,
    List<String> kinds,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'latestOfKinds',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'latestOfKinds',
          parameters: _ist.testObjectToJson({'kinds': kinds}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_idt86amb.IngestJob>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> rebuildProductionFacts(
    _ist.TestSessionBuilder sessionBuilder, {
    String? corpCode,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ingest',
            method: 'rebuildProductionFacts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ingest',
          methodName: 'rebuildProductionFacts',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _InvestmentNotesEndpoint {
  _InvestmentNotesEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<String> list(
    _ist.TestSessionBuilder sessionBuilder, {
    String? corpCode,
    required int offset,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'investmentNotes',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'investmentNotes',
          methodName: 'list',
          parameters: _ist.testObjectToJson({
            'corpCode': corpCode,
            'offset': offset,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> detail(
    _ist.TestSessionBuilder sessionBuilder,
    int articleId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'investmentNotes',
            method: 'detail',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'investmentNotes',
          methodName: 'detail',
          parameters: _ist.testObjectToJson({'articleId': articleId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> importDraft(
    _ist.TestSessionBuilder sessionBuilder,
    String payload, {
    int? articleId,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'investmentNotes',
            method: 'importDraft',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'investmentNotes',
          methodName: 'importDraft',
          parameters: _ist.testObjectToJson({
            'payload': payload,
            'articleId': articleId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<String> preview(
    _ist.TestSessionBuilder sessionBuilder,
    int articleId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'investmentNotes',
            method: 'preview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'investmentNotes',
          methodName: 'preview',
          parameters: _ist.testObjectToJson({'articleId': articleId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> publish(
    _ist.TestSessionBuilder sessionBuilder,
    int articleId,
    String approvedDigest,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'investmentNotes',
            method: 'publish',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'investmentNotes',
          methodName: 'publish',
          parameters: _ist.testObjectToJson({
            'articleId': articleId,
            'approvedDigest': approvedDigest,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _MacroEndpoint {
  _MacroEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_ikb4l1o7.MacroSeriesView>> overview(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'macro',
            method: 'overview',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'macro',
          methodName: 'overview',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ikb4l1o7.MacroSeriesView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _MembershipEndpoint {
  _MembershipEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<List<_iw7zbyvm.BillingPaymentView>> paymentsForAccount(
    _ist.TestSessionBuilder sessionBuilder,
    String userId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'paymentsForAccount',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'paymentsForAccount',
          parameters: _ist.testObjectToJson({'userId': userId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iw7zbyvm.BillingPaymentView>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> refundPayment(
    _ist.TestSessionBuilder sessionBuilder,
    int attemptId,
    String expectedOrderId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'refundPayment',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'refundPayment',
          parameters: _ist.testObjectToJson({
            'attemptId': attemptId,
            'expectedOrderId': expectedOrderId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_irqqq4jy.MembershipView> status(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'status',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'status',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_irqqq4jy.MembershipView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i9ji3lii.BillingCheckoutView> beginCheckout(
    _ist.TestSessionBuilder sessionBuilder,
    String acceptedTestTerms, {
    int? expectedAmountKrw,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'beginCheckout',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'beginCheckout',
          parameters: _ist.testObjectToJson({
            'acceptedTestTerms': acceptedTestTerms,
            'expectedAmountKrw': expectedAmountKrw,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i9ji3lii.BillingCheckoutView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i9ji3lii.BillingCheckoutView> beginCardReplacement(
    _ist.TestSessionBuilder sessionBuilder,
    String acceptedTestTerms,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'beginCardReplacement',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'beginCardReplacement',
          parameters: _ist.testObjectToJson({
            'acceptedTestTerms': acceptedTestTerms,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i9ji3lii.BillingCheckoutView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> resumeRenewal(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'resumeRenewal',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'resumeRenewal',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_irqqq4jy.MembershipView> completeCheckout(
    _ist.TestSessionBuilder sessionBuilder,
    String state,
    String authKey,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'completeCheckout',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'completeCheckout',
          parameters: _ist.testObjectToJson({
            'state': state,
            'authKey': authKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_irqqq4jy.MembershipView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> abortCheckout(
    _ist.TestSessionBuilder sessionBuilder,
    String state,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'abortCheckout',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'abortCheckout',
          parameters: _ist.testObjectToJson({'state': state}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> cancelRenewal(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membership',
            method: 'cancelRenewal',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membership',
          methodName: 'cancelRenewal',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _MembershipOfferEndpoint {
  _MembershipOfferEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_irqqq4jy.MembershipView> offer(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'membershipOffer',
            method: 'offer',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'membershipOffer',
          methodName: 'offer',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_irqqq4jy.MembershipView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ReviewEndpoint {
  _ReviewEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_icif05qz.ReviewPage> list(
    _ist.TestSessionBuilder sessionBuilder, {
    _iy39k7od.RelationStatus? status,
    _iw7mt1ku.RelationPredicate? predicate,
    int? offset,
    int? limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'list',
          parameters: _ist.testObjectToJson({
            'status': status,
            'predicate': predicate,
            'offset': offset,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_icif05qz.ReviewPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i5x2f28w.OntologyRelation?> decide(
    _ist.TestSessionBuilder sessionBuilder,
    int relationId,
    bool approve, {
    String? by,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'decide',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'decide',
          parameters: _ist.testObjectToJson({
            'relationId': relationId,
            'approve': approve,
            'by': by,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i5x2f28w.OntologyRelation?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> decideMany(
    _ist.TestSessionBuilder sessionBuilder,
    List<int> relationIds,
    bool approve, {
    String? by,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'decideMany',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'decideMany',
          parameters: _ist.testObjectToJson({
            'relationIds': relationIds,
            'approve': approve,
            'by': by,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> decideFactsMany(
    _ist.TestSessionBuilder sessionBuilder,
    List<int> factIds,
    bool approve, {
    String? by,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'decideFactsMany',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'decideFactsMany',
          parameters: _ist.testObjectToJson({
            'factIds': factIds,
            'approve': approve,
            'by': by,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_icjfwfa9.ReviewContext?> context(
    _ist.TestSessionBuilder sessionBuilder,
    String scope,
    int id, {
    required int around,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'context',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'context',
          parameters: _ist.testObjectToJson({
            'scope': scope,
            'id': id,
            'around': around,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_icjfwfa9.ReviewContext?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> recommend(
    _ist.TestSessionBuilder sessionBuilder,
    String scope,
    List<int> ids,
    _iy39k7od.RelationStatus recommendation,
    String note,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'recommend',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'recommend',
          parameters: _ist.testObjectToJson({
            'scope': scope,
            'ids': ids,
            'recommendation': recommendation,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<int> applyRecommended(
    _ist.TestSessionBuilder sessionBuilder,
    String scope,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'applyRecommended',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'applyRecommended',
          parameters: _ist.testObjectToJson({'scope': scope}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<int>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_iwp9ei5l.ReviewCheck> recordCheck(
    _ist.TestSessionBuilder sessionBuilder,
    String scope,
    int checked,
    int correct,
    int leftToPerson,
    String checkedBy, {
    String? note,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'recordCheck',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'recordCheck',
          parameters: _ist.testObjectToJson({
            'scope': scope,
            'checked': checked,
            'correct': correct,
            'leftToPerson': leftToPerson,
            'checkedBy': checkedBy,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_iwp9ei5l.ReviewCheck>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_iwp9ei5l.ReviewCheck>> checks(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'checks',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'checks',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_iwp9ei5l.ReviewCheck>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_i43txb4s.FactPage> facts(
    _ist.TestSessionBuilder sessionBuilder, {
    _iy39k7od.RelationStatus? status,
    _i1rhjzgf.DocumentFactKind? kind,
    int? offset,
    int? limit,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'facts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'facts',
          parameters: _ist.testObjectToJson({
            'status': status,
            'kind': kind,
            'offset': offset,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i43txb4s.FactPage>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<_ihq2wng4.DocumentFact?> decideFact(
    _ist.TestSessionBuilder sessionBuilder,
    int factId,
    bool approve, {
    String? by,
  }) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'decideFact',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'decideFact',
          parameters: _ist.testObjectToJson({
            'factId': factId,
            'approve': approve,
            'by': by,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_ihq2wng4.DocumentFact?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<List<_ip1s5ejx.ReviewItem>> forCompany(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'review',
            method: 'forCompany',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'review',
          methodName: 'forCompany',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<List<_ip1s5ejx.ReviewItem>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WatchlistEndpoint {
  _WatchlistEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _is.EndpointDispatch _endpointDispatch;

  final _is.SerializationManager _serializationManager;

  _ida.Future<_i3b3h5jl.WatchlistView> mine(
    _ist.TestSessionBuilder sessionBuilder,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'mine',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'mine',
          parameters: _ist.testObjectToJson({}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<_i3b3h5jl.WatchlistView>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> add(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'add',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'add',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> remove(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'remove',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'remove',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> mute(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
    bool muted,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'mute',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'mute',
          parameters: _ist.testObjectToJson({
            'corpCode': corpCode,
            'muted': muted,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> prioritize(
    _ist.TestSessionBuilder sessionBuilder,
    String corpCode,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'prioritize',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'prioritize',
          parameters: _ist.testObjectToJson({'corpCode': corpCode}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> markRead(
    _ist.TestSessionBuilder sessionBuilder,
    int noticeId,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'markRead',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'markRead',
          parameters: _ist.testObjectToJson({'noticeId': noticeId}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> subscribePush(
    _ist.TestSessionBuilder sessionBuilder,
    String endpoint,
    String p256dh,
    String auth,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'subscribePush',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'subscribePush',
          parameters: _ist.testObjectToJson({
            'endpoint': endpoint,
            'p256dh': p256dh,
            'auth': auth,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _ida.Future<void> unsubscribePush(
    _ist.TestSessionBuilder sessionBuilder,
    String endpoint,
  ) async {
    return _ist.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild(
            endpoint: 'watchlist',
            method: 'unsubscribePush',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'watchlist',
          methodName: 'unsubscribePush',
          parameters: _ist.testObjectToJson({'endpoint': endpoint}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _ida.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AiExtractionFutureCall {
  Future<void> run(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
    int limit,
  ) async {
    var object = _i7nmjhom.AiExtractionFutureCallRunModel(
      jobId: jobId,
      limit: limit,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.AiExtractionRunFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _BillingFutureCall {
  Future<void> run(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.BillingRunFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> scan(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.BillingScanFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _CharterFutureCall {
  Future<void> run(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.CharterRunFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _CompanyMasterFutureCall {
  Future<void> resume(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.CompanyMasterResumeFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> retry(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.CompanyMasterRetryFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> run(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
    bool force,
  ) async {
    var object = _i5djsspn.CompanyMasterFutureCallRunModel(
      jobId: jobId,
      force: force,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.CompanyMasterRunFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _DisclosureFutureCall {
  Future<void> run(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
  ) async {
    var object = _iiylg3o5.DisclosureFutureCallRunModel(jobId: jobId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.DisclosureRunFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> runBusiness(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
  ) async {
    var object = _imre8mrn.DisclosureFutureCallRunBusinessModel(jobId: jobId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.DisclosureRunBusinessFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> resumeBusiness(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.DisclosureResumeBusinessFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> runCompany(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
    String corpCode,
  ) async {
    var object = _iwtdffgy.DisclosureFutureCallRunCompanyModel(
      jobId: jobId,
      corpCode: corpCode,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.DisclosureRunCompanyFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> resume(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.DisclosureResumeFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _FinancialFactsFutureCall {
  Future<void> run(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
  ) async {
    var object = _iqf3b55q.FinancialFactsFutureCallRunModel(jobId: jobId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.FinancialFactsRunFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> runCompany(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
    String corpCode,
  ) async {
    var object = _iks5abhc.FinancialFactsFutureCallRunCompanyModel(
      jobId: jobId,
      corpCode: corpCode,
    );
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.FinancialFactsRunCompanyFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> resume(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.FinancialFactsResumeFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _MarketSnapshotFutureCall {
  Future<void> run(
    _ist.TestSessionBuilder sessionBuilder,
    int jobId,
  ) async {
    var object = _i0e4uq1b.MarketSnapshotFutureCallRunModel(jobId: jobId);
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.MarketSnapshotRunFutureCall().invoke(
        _localUniqueSession,
        object,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> resume(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.MarketSnapshotResumeFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}

class _WatchlistFutureCall {
  Future<void> run(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.WatchlistRunFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> scan(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.WatchlistScanFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }

  Future<void> deliver(_ist.TestSessionBuilder sessionBuilder) async {
    var _localUniqueSession =
        (sessionBuilder as _ist.InternalTestSessionBuilder).internalBuild();
    try {
      await _i4o8e4lj.WatchlistDeliverFutureCall().invoke(
        _localUniqueSession,
        null,
      );
    } finally {
      await _localUniqueSession.close();
    }
  }
}
