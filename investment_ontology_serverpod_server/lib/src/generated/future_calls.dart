/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: depend_on_referenced_packages

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:clock/clock.dart' as _io0w16m8;
import 'package:serverpod/serverpod.dart' as _is;
import '../ontology/ingest/company_master_future_call.dart' as _iouuus1c;
import '../ontology/ingest/financial_facts_future_call.dart' as _iqtu3y45;
import '../ontology/ingest/market_snapshot_future_call.dart' as _i3rk8q0z;
import 'future_calls_generated_models/company_master_future_call_run_model.dart'
    as _i8298vau;
import 'future_calls_generated_models/financial_facts_future_call_run_model.dart'
    as _ijwdvc26;
import 'future_calls_generated_models/market_snapshot_future_call_run_model.dart'
    as _i7jjkv72;

/// Invokes a future call.
typedef _InvokeFutureCall =
    Future<void> Function(String name, _is.SerializableModel? object);

extension ServerpodFutureCallsGetter on _is.Serverpod {
  /// Generated future calls.
  FutureCalls get futureCalls => FutureCalls();
}

class FutureCalls extends _is.FutureCallDispatch<_FutureCallRef> {
  FutureCalls._();

  factory FutureCalls() {
    return _instance;
  }

  static final FutureCalls _instance = FutureCalls._();

  _is.FutureCallManager? _futureCallManager;

  String? _serverId;

  String get _effectiveServerId {
    if (_serverId == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _serverId!;
  }

  _is.FutureCallManager get _effectiveFutureCallManager {
    if (_futureCallManager == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _futureCallManager!;
  }

  @override
  void initialize(
    _is.FutureCallManager futureCallManager,
    String serverId,
  ) {
    var registeredFutureCalls = <String, _is.InvokableFutureCall>{
      'CompanyMasterRunFutureCall': CompanyMasterRunFutureCall(),
      'FinancialFactsRunFutureCall': FinancialFactsRunFutureCall(),
      'FinancialFactsResumeFutureCall': FinancialFactsResumeFutureCall(),
      'MarketSnapshotRunFutureCall': MarketSnapshotRunFutureCall(),
      'MarketSnapshotResumeFutureCall': MarketSnapshotResumeFutureCall(),
    };
    _futureCallManager = futureCallManager;
    _serverId = serverId;
    for (final entry in registeredFutureCalls.entries) {
      _futureCallManager?.registerFutureCall(entry.value, entry.key);
    }
  }

  @override
  _FutureCallRef callAtTime(
    DateTime time, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          time,
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _FutureCallRef callWithDelay(
    Duration delay, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          DateTime.now().toUtc().add(delay),
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _is.RecurringFutureCallDispatch<_FutureCallRef> callRecurring({
    String? identifier,
  }) {
    return _RecurringFutureCallDispatchImpl(
      _effectiveFutureCallManager,
      _effectiveServerId,
      identifier,
    );
  }

  @override
  Future<void> cancel(String identifier) async {
    await _effectiveFutureCallManager.cancelFutureCall(identifier);
  }
}

class _RecurringFutureCallDispatchImpl
    extends _is.RecurringFutureCallDispatch<_FutureCallRef> {
  _RecurringFutureCallDispatchImpl(
    this._futureCallManager,
    this._serverId,
    this._identifier,
  );

  final _is.FutureCallManager _futureCallManager;

  final String _serverId;

  final String? _identifier;

  @override
  _FutureCallRef cron(String cronExpression) {
    return _FutureCallRef(
      (name, object) {
        return _futureCallManager.scheduleFutureCall(
          name,
          object,
          _is.Cron.parse(cronExpression).nextTime(),
          _serverId,
          _identifier,
          scheduling: _is.CronFutureCallScheduling(cron: cronExpression),
        );
      },
    );
  }

  @override
  _FutureCallRef every(
    Duration interval, {
    DateTime? start,
  }) {
    final now = _io0w16m8.clock.now().toUtc();
    return _FutureCallRef(
      (name, object) {
        return _futureCallManager.scheduleFutureCall(
          name,
          object,
          start ?? now.add(interval),
          _serverId,
          _identifier,
          scheduling: _is.IntervalFutureCallScheduling(
            interval: interval,
            start: start,
          ),
        );
      },
    );
  }
}

class _FutureCallRef {
  _FutureCallRef(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  late final companyMaster = _CompanyMasterFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final financialFacts = _FinancialFactsFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final marketSnapshot = _MarketSnapshotFutureCallDispatcher(
    _invokeFutureCall,
  );
}

class _CompanyMasterFutureCallDispatcher {
  _CompanyMasterFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(
    int jobId,
    bool force,
  ) {
    var object = _i8298vau.CompanyMasterFutureCallRunModel(
      jobId: jobId,
      force: force,
    );
    return _invokeFutureCall(
      'CompanyMasterRunFutureCall',
      object,
    );
  }
}

class _FinancialFactsFutureCallDispatcher {
  _FinancialFactsFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(int jobId) {
    var object = _ijwdvc26.FinancialFactsFutureCallRunModel(jobId: jobId);
    return _invokeFutureCall(
      'FinancialFactsRunFutureCall',
      object,
    );
  }

  Future<void> resume() {
    return _invokeFutureCall(
      'FinancialFactsResumeFutureCall',
      null,
    );
  }
}

class _MarketSnapshotFutureCallDispatcher {
  _MarketSnapshotFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(int jobId) {
    var object = _i7jjkv72.MarketSnapshotFutureCallRunModel(jobId: jobId);
    return _invokeFutureCall(
      'MarketSnapshotRunFutureCall',
      object,
    );
  }

  Future<void> resume() {
    return _invokeFutureCall(
      'MarketSnapshotResumeFutureCall',
      null,
    );
  }
}

class CompanyMasterRunFutureCall
    extends _is.FutureCall<_i8298vau.CompanyMasterFutureCallRunModel>
    implements
        _is.InvokableFutureCall<_i8298vau.CompanyMasterFutureCallRunModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _i8298vau.CompanyMasterFutureCallRunModel? object,
  ) async {
    if (object != null) {
      await _iouuus1c.CompanyMasterFutureCall().run(
        session,
        object.jobId,
        object.force,
      );
    }
  }
}

class FinancialFactsRunFutureCall
    extends _is.FutureCall<_ijwdvc26.FinancialFactsFutureCallRunModel>
    implements
        _is.InvokableFutureCall<_ijwdvc26.FinancialFactsFutureCallRunModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ijwdvc26.FinancialFactsFutureCallRunModel? object,
  ) async {
    if (object != null) {
      await _iqtu3y45.FinancialFactsFutureCall().run(
        session,
        object.jobId,
      );
    }
  }
}

/// 일일 호출 예산을 다 써서 멈춘 수집을 이어서 받는다.
class FinancialFactsResumeFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _iqtu3y45.FinancialFactsFutureCall().resume(session);
  }
}

class MarketSnapshotRunFutureCall
    extends _is.FutureCall<_i7jjkv72.MarketSnapshotFutureCallRunModel>
    implements
        _is.InvokableFutureCall<_i7jjkv72.MarketSnapshotFutureCallRunModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _i7jjkv72.MarketSnapshotFutureCallRunModel? object,
  ) async {
    if (object != null) {
      await _i3rk8q0z.MarketSnapshotFutureCall().run(
        session,
        object.jobId,
      );
    }
  }
}

/// 일일 호출 예산을 다 써서 멈춘 수집을 이어서 받는다.
class MarketSnapshotResumeFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _i3rk8q0z.MarketSnapshotFutureCall().resume(session);
  }
}
