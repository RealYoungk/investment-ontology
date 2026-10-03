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
import '../ontology/ai/ai_extraction_future_call.dart' as _ifdlgs52;
import '../ontology/billing/billing_future_call.dart' as _ih3pebim;
import '../ontology/ingest/charter_future_call.dart' as _iywhlupy;
import '../ontology/ingest/company_master_future_call.dart' as _iouuus1c;
import '../ontology/ingest/disclosure_future_call.dart' as _itvp2mss;
import '../ontology/ingest/financial_facts_future_call.dart' as _iqtu3y45;
import '../ontology/ingest/market_snapshot_future_call.dart' as _i3rk8q0z;
import '../ontology/watchlist/watchlist_future_call.dart' as _iwo2pqlf;
import 'future_calls_generated_models/ai_extraction_future_call_run_model.dart'
    as _iskveedf;
import 'future_calls_generated_models/company_master_future_call_run_model.dart'
    as _i8298vau;
import 'future_calls_generated_models/disclosure_future_call_run_business_model.dart'
    as _ip76fxv0;
import 'future_calls_generated_models/disclosure_future_call_run_company_model.dart'
    as _iln8mnkp;
import 'future_calls_generated_models/disclosure_future_call_run_model.dart'
    as _i9swl9ej;
import 'future_calls_generated_models/financial_facts_future_call_run_company_model.dart'
    as _in9ocduk;
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
      'AiExtractionRunFutureCall': AiExtractionRunFutureCall(),
      'BillingRunFutureCall': BillingRunFutureCall(),
      'BillingScanFutureCall': BillingScanFutureCall(),
      'CharterRunFutureCall': CharterRunFutureCall(),
      'CompanyMasterResumeFutureCall': CompanyMasterResumeFutureCall(),
      'CompanyMasterRetryFutureCall': CompanyMasterRetryFutureCall(),
      'CompanyMasterRunFutureCall': CompanyMasterRunFutureCall(),
      'DisclosureRunFutureCall': DisclosureRunFutureCall(),
      'DisclosureRunBusinessFutureCall': DisclosureRunBusinessFutureCall(),
      'DisclosureResumeBusinessFutureCall':
          DisclosureResumeBusinessFutureCall(),
      'DisclosureRunCompanyFutureCall': DisclosureRunCompanyFutureCall(),
      'DisclosureResumeFutureCall': DisclosureResumeFutureCall(),
      'FinancialFactsRunFutureCall': FinancialFactsRunFutureCall(),
      'FinancialFactsRunCompanyFutureCall':
          FinancialFactsRunCompanyFutureCall(),
      'FinancialFactsResumeFutureCall': FinancialFactsResumeFutureCall(),
      'MarketSnapshotRunFutureCall': MarketSnapshotRunFutureCall(),
      'MarketSnapshotResumeFutureCall': MarketSnapshotResumeFutureCall(),
      'WatchlistRunFutureCall': WatchlistRunFutureCall(),
      'WatchlistScanFutureCall': WatchlistScanFutureCall(),
      'WatchlistDeliverFutureCall': WatchlistDeliverFutureCall(),
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

  late final aiExtraction = _AiExtractionFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final billing = _BillingFutureCallDispatcher(_invokeFutureCall);

  late final charter = _CharterFutureCallDispatcher(_invokeFutureCall);

  late final companyMaster = _CompanyMasterFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final disclosure = _DisclosureFutureCallDispatcher(_invokeFutureCall);

  late final financialFacts = _FinancialFactsFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final marketSnapshot = _MarketSnapshotFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final watchlist = _WatchlistFutureCallDispatcher(_invokeFutureCall);
}

class _AiExtractionFutureCallDispatcher {
  _AiExtractionFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(
    int jobId,
    int limit,
  ) {
    var object = _iskveedf.AiExtractionFutureCallRunModel(
      jobId: jobId,
      limit: limit,
    );
    return _invokeFutureCall(
      'AiExtractionRunFutureCall',
      object,
    );
  }
}

class _BillingFutureCallDispatcher {
  _BillingFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run() {
    return _invokeFutureCall(
      'BillingRunFutureCall',
      null,
    );
  }

  Future<void> scan() {
    return _invokeFutureCall(
      'BillingScanFutureCall',
      null,
    );
  }
}

class _CharterFutureCallDispatcher {
  _CharterFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run() {
    return _invokeFutureCall(
      'CharterRunFutureCall',
      null,
    );
  }
}

class _CompanyMasterFutureCallDispatcher {
  _CompanyMasterFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> resume() {
    return _invokeFutureCall(
      'CompanyMasterResumeFutureCall',
      null,
    );
  }

  Future<void> retry() {
    return _invokeFutureCall(
      'CompanyMasterRetryFutureCall',
      null,
    );
  }

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

class _DisclosureFutureCallDispatcher {
  _DisclosureFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(int jobId) {
    var object = _i9swl9ej.DisclosureFutureCallRunModel(jobId: jobId);
    return _invokeFutureCall(
      'DisclosureRunFutureCall',
      object,
    );
  }

  Future<void> runBusiness(int jobId) {
    var object = _ip76fxv0.DisclosureFutureCallRunBusinessModel(jobId: jobId);
    return _invokeFutureCall(
      'DisclosureRunBusinessFutureCall',
      object,
    );
  }

  Future<void> resumeBusiness() {
    return _invokeFutureCall(
      'DisclosureResumeBusinessFutureCall',
      null,
    );
  }

  Future<void> runCompany(
    int jobId,
    String corpCode,
  ) {
    var object = _iln8mnkp.DisclosureFutureCallRunCompanyModel(
      jobId: jobId,
      corpCode: corpCode,
    );
    return _invokeFutureCall(
      'DisclosureRunCompanyFutureCall',
      object,
    );
  }

  Future<void> resume() {
    return _invokeFutureCall(
      'DisclosureResumeFutureCall',
      null,
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

  Future<void> runCompany(
    int jobId,
    String corpCode,
  ) {
    var object = _in9ocduk.FinancialFactsFutureCallRunCompanyModel(
      jobId: jobId,
      corpCode: corpCode,
    );
    return _invokeFutureCall(
      'FinancialFactsRunCompanyFutureCall',
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

class _WatchlistFutureCallDispatcher {
  _WatchlistFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run() {
    return _invokeFutureCall(
      'WatchlistRunFutureCall',
      null,
    );
  }

  Future<void> scan() {
    return _invokeFutureCall(
      'WatchlistScanFutureCall',
      null,
    );
  }

  Future<void> deliver() {
    return _invokeFutureCall(
      'WatchlistDeliverFutureCall',
      null,
    );
  }
}

class AiExtractionRunFutureCall
    extends _is.FutureCall<_iskveedf.AiExtractionFutureCallRunModel>
    implements
        _is.InvokableFutureCall<_iskveedf.AiExtractionFutureCallRunModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iskveedf.AiExtractionFutureCallRunModel? object,
  ) async {
    if (object != null) {
      await _ifdlgs52.AiExtractionFutureCall().run(
        session,
        object.jobId,
        object.limit,
      );
    }
  }
}

class BillingRunFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _ih3pebim.BillingFutureCall().run(session);
  }
}

class BillingScanFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _ih3pebim.BillingFutureCall().scan(session);
  }
}

class CharterRunFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _iywhlupy.CharterFutureCall().run(session);
  }
}

/// 매일 기업 마스터 갱신. 같은 종류의 실행 중 작업이 있으면 중복하지 않는다.
class CompanyMasterResumeFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _iouuus1c.CompanyMasterFutureCall().resume(session);
  }
}

/// 부분 실패 재시도는 성공한 기업을 다시 받지 않는 변경분만 처리한다.
class CompanyMasterRetryFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _iouuus1c.CompanyMasterFutureCall().retry(session);
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

class DisclosureRunFutureCall
    extends _is.FutureCall<_i9swl9ej.DisclosureFutureCallRunModel>
    implements _is.InvokableFutureCall<_i9swl9ej.DisclosureFutureCallRunModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _i9swl9ej.DisclosureFutureCallRunModel? object,
  ) async {
    if (object != null) {
      await _itvp2mss.DisclosureFutureCall().run(
        session,
        object.jobId,
      );
    }
  }
}

class DisclosureRunBusinessFutureCall
    extends _is.FutureCall<_ip76fxv0.DisclosureFutureCallRunBusinessModel>
    implements
        _is.InvokableFutureCall<
          _ip76fxv0.DisclosureFutureCallRunBusinessModel
        > {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _ip76fxv0.DisclosureFutureCallRunBusinessModel? object,
  ) async {
    if (object != null) {
      await _itvp2mss.DisclosureFutureCall().runBusiness(
        session,
        object.jobId,
      );
    }
  }
}

class DisclosureResumeBusinessFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _itvp2mss.DisclosureFutureCall().resumeBusiness(session);
  }
}

/// 기업 하나의 사업보고서 주요정보만 받는다.
class DisclosureRunCompanyFutureCall
    extends _is.FutureCall<_iln8mnkp.DisclosureFutureCallRunCompanyModel>
    implements
        _is.InvokableFutureCall<_iln8mnkp.DisclosureFutureCallRunCompanyModel> {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _iln8mnkp.DisclosureFutureCallRunCompanyModel? object,
  ) async {
    if (object != null) {
      await _itvp2mss.DisclosureFutureCall().runCompany(
        session,
        object.jobId,
        object.corpCode,
      );
    }
  }
}

/// 매일 예약·이어받기. 같은 수집이 돌고 있으면 건너뛴다.
class DisclosureResumeFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _itvp2mss.DisclosureFutureCall().resume(session);
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

/// 기업 하나의 정기보고서만 찾아 받는다.
class FinancialFactsRunCompanyFutureCall
    extends _is.FutureCall<_in9ocduk.FinancialFactsFutureCallRunCompanyModel>
    implements
        _is.InvokableFutureCall<
          _in9ocduk.FinancialFactsFutureCallRunCompanyModel
        > {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _in9ocduk.FinancialFactsFutureCallRunCompanyModel? object,
  ) async {
    if (object != null) {
      await _iqtu3y45.FinancialFactsFutureCall().runCompany(
        session,
        object.jobId,
        object.corpCode,
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

class WatchlistRunFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _iwo2pqlf.WatchlistFutureCall().run(session);
  }
}

class WatchlistScanFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _iwo2pqlf.WatchlistFutureCall().scan(session);
  }
}

class WatchlistDeliverFutureCall extends _is.FutureCall
    implements _is.InvokableFutureCall {
  @override
  _ida.Future<void> invoke(
    _is.Session session,
    _is.SerializableModel? object,
  ) async {
    await _iwo2pqlf.WatchlistFutureCall().deliver(session);
  }
}
