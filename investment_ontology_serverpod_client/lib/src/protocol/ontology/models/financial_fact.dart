/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;
import '../../ontology/models/financial_statement_kind.dart' as _ibg3jdoa;
import '../../ontology/models/fs_div.dart' as _igqrlzji;

/// 재무 수치 한 칸. DART fnlttSinglAcntAll 응답 한 행의 금액 열을 모두 담는다.
/// 금액은 원 단위 정수. 비교 기간 값(전기·전전기)도 같은 공시에 실린 값이다.
abstract class FinancialFact
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FinancialFact._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.reportCode,
    required this.fsDiv,
    required this.statement,
    this.accountId,
    required this.accountName,
    this.accountDetail,
    this.ord,
    this.periodName,
    this.amount,
    this.cumulativeAmount,
    this.priorPeriodName,
    this.priorAmount,
    this.priorCumulativeAmount,
    this.priorQuarterName,
    this.priorQuarterAmount,
    this.beforePriorPeriodName,
    this.beforePriorAmount,
    this.currency,
    required this.sourceId,
    this.supersededById,
  });

  factory FinancialFact({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required _igqrlzji.FsDiv fsDiv,
    required _ibg3jdoa.FinancialStatementKind statement,
    String? accountId,
    required String accountName,
    String? accountDetail,
    int? ord,
    String? periodName,
    BigInt? amount,
    BigInt? cumulativeAmount,
    String? priorPeriodName,
    BigInt? priorAmount,
    BigInt? priorCumulativeAmount,
    String? priorQuarterName,
    BigInt? priorQuarterAmount,
    String? beforePriorPeriodName,
    BigInt? beforePriorAmount,
    String? currency,
    required int sourceId,
    int? supersededById,
  }) = _FinancialFactImpl;

  factory FinancialFact.fromJson(Map<String, dynamic> jsonSerialization) {
    return FinancialFact(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      fsDiv: _igqrlzji.FsDiv.fromJson((jsonSerialization['fsDiv'] as String)),
      statement: _ibg3jdoa.FinancialStatementKind.fromJson(
        (jsonSerialization['statement'] as String),
      ),
      accountId: jsonSerialization['accountId'] as String?,
      accountName: jsonSerialization['accountName'] as String,
      accountDetail: jsonSerialization['accountDetail'] as String?,
      ord: jsonSerialization['ord'] as int?,
      periodName: jsonSerialization['periodName'] as String?,
      amount: jsonSerialization['amount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['amount']),
      cumulativeAmount: jsonSerialization['cumulativeAmount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['cumulativeAmount'],
            ),
      priorPeriodName: jsonSerialization['priorPeriodName'] as String?,
      priorAmount: jsonSerialization['priorAmount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['priorAmount']),
      priorCumulativeAmount: jsonSerialization['priorCumulativeAmount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['priorCumulativeAmount'],
            ),
      priorQuarterName: jsonSerialization['priorQuarterName'] as String?,
      priorQuarterAmount: jsonSerialization['priorQuarterAmount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['priorQuarterAmount'],
            ),
      beforePriorPeriodName:
          jsonSerialization['beforePriorPeriodName'] as String?,
      beforePriorAmount: jsonSerialization['beforePriorAmount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['beforePriorAmount'],
            ),
      currency: jsonSerialization['currency'] as String?,
      sourceId: jsonSerialization['sourceId'] as int,
      supersededById: jsonSerialization['supersededById'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  _igqrlzji.FsDiv fsDiv;

  _ibg3jdoa.FinancialStatementKind statement;

  /// XBRL 계정 ID (예: ifrs-full_Revenue). 표준계정코드를 쓰지 않은 계정은 null
  String? accountId;

  String accountName;

  /// 자본변동표의 자본 구성요소 등 (원문 그대로)
  String? accountDetail;

  int? ord;

  /// 당기 (thstrm_nm / thstrm_amount / thstrm_add_amount)
  String? periodName;

  BigInt? amount;

  BigInt? cumulativeAmount;

  /// 전기 (frmtrm_nm / frmtrm_amount / frmtrm_add_amount)
  String? priorPeriodName;

  BigInt? priorAmount;

  BigInt? priorCumulativeAmount;

  /// 전기 동분기 (frmtrm_q_nm / frmtrm_q_amount)
  String? priorQuarterName;

  BigInt? priorQuarterAmount;

  /// 전전기 (bfefrmtrm_nm / bfefrmtrm_amount)
  String? beforePriorPeriodName;

  BigInt? beforePriorAmount;

  String? currency;

  int sourceId;

  int? supersededById;

  /// Returns a shallow copy of this [FinancialFact]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FinancialFact copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    _igqrlzji.FsDiv? fsDiv,
    _ibg3jdoa.FinancialStatementKind? statement,
    String? accountId,
    String? accountName,
    String? accountDetail,
    int? ord,
    String? periodName,
    BigInt? amount,
    BigInt? cumulativeAmount,
    String? priorPeriodName,
    BigInt? priorAmount,
    BigInt? priorCumulativeAmount,
    String? priorQuarterName,
    BigInt? priorQuarterAmount,
    String? beforePriorPeriodName,
    BigInt? beforePriorAmount,
    String? currency,
    int? sourceId,
    int? supersededById,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialFact',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'fsDiv': fsDiv.toJson(),
      'statement': statement.toJson(),
      if (accountId != null) 'accountId': accountId,
      'accountName': accountName,
      if (accountDetail != null) 'accountDetail': accountDetail,
      if (ord != null) 'ord': ord,
      if (periodName != null) 'periodName': periodName,
      if (amount != null) 'amount': amount?.toJson(),
      if (cumulativeAmount != null)
        'cumulativeAmount': cumulativeAmount?.toJson(),
      if (priorPeriodName != null) 'priorPeriodName': priorPeriodName,
      if (priorAmount != null) 'priorAmount': priorAmount?.toJson(),
      if (priorCumulativeAmount != null)
        'priorCumulativeAmount': priorCumulativeAmount?.toJson(),
      if (priorQuarterName != null) 'priorQuarterName': priorQuarterName,
      if (priorQuarterAmount != null)
        'priorQuarterAmount': priorQuarterAmount?.toJson(),
      if (beforePriorPeriodName != null)
        'beforePriorPeriodName': beforePriorPeriodName,
      if (beforePriorAmount != null)
        'beforePriorAmount': beforePriorAmount?.toJson(),
      if (currency != null) 'currency': currency,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FinancialFact',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'fsDiv': fsDiv.toJson(),
      'statement': statement.toJson(),
      if (accountId != null) 'accountId': accountId,
      'accountName': accountName,
      if (accountDetail != null) 'accountDetail': accountDetail,
      if (ord != null) 'ord': ord,
      if (periodName != null) 'periodName': periodName,
      if (amount != null) 'amount': amount?.toJson(),
      if (cumulativeAmount != null)
        'cumulativeAmount': cumulativeAmount?.toJson(),
      if (priorPeriodName != null) 'priorPeriodName': priorPeriodName,
      if (priorAmount != null) 'priorAmount': priorAmount?.toJson(),
      if (priorCumulativeAmount != null)
        'priorCumulativeAmount': priorCumulativeAmount?.toJson(),
      if (priorQuarterName != null) 'priorQuarterName': priorQuarterName,
      if (priorQuarterAmount != null)
        'priorQuarterAmount': priorQuarterAmount?.toJson(),
      if (beforePriorPeriodName != null)
        'beforePriorPeriodName': beforePriorPeriodName,
      if (beforePriorAmount != null)
        'beforePriorAmount': beforePriorAmount?.toJson(),
      if (currency != null) 'currency': currency,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FinancialFactImpl extends FinancialFact {
  _FinancialFactImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required _igqrlzji.FsDiv fsDiv,
    required _ibg3jdoa.FinancialStatementKind statement,
    String? accountId,
    required String accountName,
    String? accountDetail,
    int? ord,
    String? periodName,
    BigInt? amount,
    BigInt? cumulativeAmount,
    String? priorPeriodName,
    BigInt? priorAmount,
    BigInt? priorCumulativeAmount,
    String? priorQuarterName,
    BigInt? priorQuarterAmount,
    String? beforePriorPeriodName,
    BigInt? beforePriorAmount,
    String? currency,
    required int sourceId,
    int? supersededById,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         fsDiv: fsDiv,
         statement: statement,
         accountId: accountId,
         accountName: accountName,
         accountDetail: accountDetail,
         ord: ord,
         periodName: periodName,
         amount: amount,
         cumulativeAmount: cumulativeAmount,
         priorPeriodName: priorPeriodName,
         priorAmount: priorAmount,
         priorCumulativeAmount: priorCumulativeAmount,
         priorQuarterName: priorQuarterName,
         priorQuarterAmount: priorQuarterAmount,
         beforePriorPeriodName: beforePriorPeriodName,
         beforePriorAmount: beforePriorAmount,
         currency: currency,
         sourceId: sourceId,
         supersededById: supersededById,
       );

  /// Returns a shallow copy of this [FinancialFact]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FinancialFact copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    _igqrlzji.FsDiv? fsDiv,
    _ibg3jdoa.FinancialStatementKind? statement,
    Object? accountId = _Undefined,
    String? accountName,
    Object? accountDetail = _Undefined,
    Object? ord = _Undefined,
    Object? periodName = _Undefined,
    Object? amount = _Undefined,
    Object? cumulativeAmount = _Undefined,
    Object? priorPeriodName = _Undefined,
    Object? priorAmount = _Undefined,
    Object? priorCumulativeAmount = _Undefined,
    Object? priorQuarterName = _Undefined,
    Object? priorQuarterAmount = _Undefined,
    Object? beforePriorPeriodName = _Undefined,
    Object? beforePriorAmount = _Undefined,
    Object? currency = _Undefined,
    int? sourceId,
    Object? supersededById = _Undefined,
  }) {
    return FinancialFact(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      fsDiv: fsDiv ?? this.fsDiv,
      statement: statement ?? this.statement,
      accountId: accountId is String? ? accountId : this.accountId,
      accountName: accountName ?? this.accountName,
      accountDetail: accountDetail is String?
          ? accountDetail
          : this.accountDetail,
      ord: ord is int? ? ord : this.ord,
      periodName: periodName is String? ? periodName : this.periodName,
      amount: amount is BigInt? ? amount : this.amount,
      cumulativeAmount: cumulativeAmount is BigInt?
          ? cumulativeAmount
          : this.cumulativeAmount,
      priorPeriodName: priorPeriodName is String?
          ? priorPeriodName
          : this.priorPeriodName,
      priorAmount: priorAmount is BigInt? ? priorAmount : this.priorAmount,
      priorCumulativeAmount: priorCumulativeAmount is BigInt?
          ? priorCumulativeAmount
          : this.priorCumulativeAmount,
      priorQuarterName: priorQuarterName is String?
          ? priorQuarterName
          : this.priorQuarterName,
      priorQuarterAmount: priorQuarterAmount is BigInt?
          ? priorQuarterAmount
          : this.priorQuarterAmount,
      beforePriorPeriodName: beforePriorPeriodName is String?
          ? beforePriorPeriodName
          : this.beforePriorPeriodName,
      beforePriorAmount: beforePriorAmount is BigInt?
          ? beforePriorAmount
          : this.beforePriorAmount,
      currency: currency is String? ? currency : this.currency,
      sourceId: sourceId ?? this.sourceId,
      supersededById: supersededById is int?
          ? supersededById
          : this.supersededById,
    );
  }
}
