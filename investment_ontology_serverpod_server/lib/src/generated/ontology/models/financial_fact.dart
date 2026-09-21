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
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;
import '../../ontology/models/financial_statement_kind.dart' as _ibg3jdoa;
import '../../ontology/models/fs_div.dart' as _igqrlzji;

/// 재무 수치 한 칸. DART fnlttSinglAcntAll 응답 한 행의 금액 열을 모두 담는다.
/// 금액은 원 단위 정수. 비교 기간 값(전기·전전기)도 같은 공시에 실린 값이다.
abstract class FinancialFact
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['amount']),
      cumulativeAmount: jsonSerialization['cumulativeAmount'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['cumulativeAmount'],
            ),
      priorPeriodName: jsonSerialization['priorPeriodName'] as String?,
      priorAmount: jsonSerialization['priorAmount'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['priorAmount']),
      priorCumulativeAmount: jsonSerialization['priorCumulativeAmount'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['priorCumulativeAmount'],
            ),
      priorQuarterName: jsonSerialization['priorQuarterName'] as String?,
      priorQuarterAmount: jsonSerialization['priorQuarterAmount'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['priorQuarterAmount'],
            ),
      beforePriorPeriodName:
          jsonSerialization['beforePriorPeriodName'] as String?,
      beforePriorAmount: jsonSerialization['beforePriorAmount'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['beforePriorAmount'],
            ),
      currency: jsonSerialization['currency'] as String?,
      sourceId: jsonSerialization['sourceId'] as int,
      supersededById: jsonSerialization['supersededById'] as int?,
    );
  }

  static final t = FinancialFactTable();

  static const db = FinancialFactRepository._();

  @override
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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [FinancialFact]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
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

  static FinancialFactInclude include() {
    return FinancialFactInclude._();
  }

  static FinancialFactIncludeList includeList({
    _is.WhereExpressionBuilder<FinancialFactTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FinancialFactTable>? orderBy,
    _is.OrderByListBuilder<FinancialFactTable>? orderByList,
    FinancialFactInclude? include,
  }) {
    return FinancialFactIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FinancialFact.t),
      orderByList: orderByList?.call(FinancialFact.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
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

class FinancialFactUpdateTable extends _is.UpdateTable<FinancialFactTable> {
  FinancialFactUpdateTable(super.table);

  _is.ColumnValue<int, int> reportId(int value) => _is.ColumnValue(
    table.reportId,
    value,
  );

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<int, int> bsnsYear(int value) => _is.ColumnValue(
    table.bsnsYear,
    value,
  );

  _is.ColumnValue<_i6mbh8k5.FinancialReportCode, _i6mbh8k5.FinancialReportCode>
  reportCode(_i6mbh8k5.FinancialReportCode value) => _is.ColumnValue(
    table.reportCode,
    value,
  );

  _is.ColumnValue<_igqrlzji.FsDiv, _igqrlzji.FsDiv> fsDiv(
    _igqrlzji.FsDiv value,
  ) => _is.ColumnValue(
    table.fsDiv,
    value,
  );

  _is.ColumnValue<
    _ibg3jdoa.FinancialStatementKind,
    _ibg3jdoa.FinancialStatementKind
  >
  statement(_ibg3jdoa.FinancialStatementKind value) => _is.ColumnValue(
    table.statement,
    value,
  );

  _is.ColumnValue<String, String> accountId(String? value) => _is.ColumnValue(
    table.accountId,
    value,
  );

  _is.ColumnValue<String, String> accountName(String value) => _is.ColumnValue(
    table.accountName,
    value,
  );

  _is.ColumnValue<String, String> accountDetail(String? value) =>
      _is.ColumnValue(
        table.accountDetail,
        value,
      );

  _is.ColumnValue<int, int> ord(int? value) => _is.ColumnValue(
    table.ord,
    value,
  );

  _is.ColumnValue<String, String> periodName(String? value) => _is.ColumnValue(
    table.periodName,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> amount(BigInt? value) => _is.ColumnValue(
    table.amount,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> cumulativeAmount(BigInt? value) =>
      _is.ColumnValue(
        table.cumulativeAmount,
        value,
      );

  _is.ColumnValue<String, String> priorPeriodName(String? value) =>
      _is.ColumnValue(
        table.priorPeriodName,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> priorAmount(BigInt? value) => _is.ColumnValue(
    table.priorAmount,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> priorCumulativeAmount(BigInt? value) =>
      _is.ColumnValue(
        table.priorCumulativeAmount,
        value,
      );

  _is.ColumnValue<String, String> priorQuarterName(String? value) =>
      _is.ColumnValue(
        table.priorQuarterName,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> priorQuarterAmount(BigInt? value) =>
      _is.ColumnValue(
        table.priorQuarterAmount,
        value,
      );

  _is.ColumnValue<String, String> beforePriorPeriodName(String? value) =>
      _is.ColumnValue(
        table.beforePriorPeriodName,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> beforePriorAmount(BigInt? value) =>
      _is.ColumnValue(
        table.beforePriorAmount,
        value,
      );

  _is.ColumnValue<String, String> currency(String? value) => _is.ColumnValue(
    table.currency,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<int, int> supersededById(int? value) => _is.ColumnValue(
    table.supersededById,
    value,
  );
}

class FinancialFactTable extends _is.Table<int?> {
  FinancialFactTable({super.tableRelation})
    : super(tableName: 'financial_fact') {
    updateTable = FinancialFactUpdateTable(this);
    reportId = _is.ColumnInt(
      'reportId',
      this,
    );
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    bsnsYear = _is.ColumnInt(
      'bsnsYear',
      this,
    );
    reportCode = _is.ColumnEnum(
      'reportCode',
      this,
      _is.EnumSerialization.byName,
    );
    fsDiv = _is.ColumnEnum(
      'fsDiv',
      this,
      _is.EnumSerialization.byName,
    );
    statement = _is.ColumnEnum(
      'statement',
      this,
      _is.EnumSerialization.byName,
    );
    accountId = _is.ColumnString(
      'accountId',
      this,
    );
    accountName = _is.ColumnString(
      'accountName',
      this,
    );
    accountDetail = _is.ColumnString(
      'accountDetail',
      this,
    );
    ord = _is.ColumnInt(
      'ord',
      this,
    );
    periodName = _is.ColumnString(
      'periodName',
      this,
    );
    amount = _is.ColumnBigInt(
      'amount',
      this,
    );
    cumulativeAmount = _is.ColumnBigInt(
      'cumulativeAmount',
      this,
    );
    priorPeriodName = _is.ColumnString(
      'priorPeriodName',
      this,
    );
    priorAmount = _is.ColumnBigInt(
      'priorAmount',
      this,
    );
    priorCumulativeAmount = _is.ColumnBigInt(
      'priorCumulativeAmount',
      this,
    );
    priorQuarterName = _is.ColumnString(
      'priorQuarterName',
      this,
    );
    priorQuarterAmount = _is.ColumnBigInt(
      'priorQuarterAmount',
      this,
    );
    beforePriorPeriodName = _is.ColumnString(
      'beforePriorPeriodName',
      this,
    );
    beforePriorAmount = _is.ColumnBigInt(
      'beforePriorAmount',
      this,
    );
    currency = _is.ColumnString(
      'currency',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    supersededById = _is.ColumnInt(
      'supersededById',
      this,
    );
  }

  late final FinancialFactUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnEnum<_i6mbh8k5.FinancialReportCode> reportCode;

  late final _is.ColumnEnum<_igqrlzji.FsDiv> fsDiv;

  late final _is.ColumnEnum<_ibg3jdoa.FinancialStatementKind> statement;

  /// XBRL 계정 ID (예: ifrs-full_Revenue). 표준계정코드를 쓰지 않은 계정은 null
  late final _is.ColumnString accountId;

  late final _is.ColumnString accountName;

  /// 자본변동표의 자본 구성요소 등 (원문 그대로)
  late final _is.ColumnString accountDetail;

  late final _is.ColumnInt ord;

  /// 당기 (thstrm_nm / thstrm_amount / thstrm_add_amount)
  late final _is.ColumnString periodName;

  late final _is.ColumnBigInt amount;

  late final _is.ColumnBigInt cumulativeAmount;

  /// 전기 (frmtrm_nm / frmtrm_amount / frmtrm_add_amount)
  late final _is.ColumnString priorPeriodName;

  late final _is.ColumnBigInt priorAmount;

  late final _is.ColumnBigInt priorCumulativeAmount;

  /// 전기 동분기 (frmtrm_q_nm / frmtrm_q_amount)
  late final _is.ColumnString priorQuarterName;

  late final _is.ColumnBigInt priorQuarterAmount;

  /// 전전기 (bfefrmtrm_nm / bfefrmtrm_amount)
  late final _is.ColumnString beforePriorPeriodName;

  late final _is.ColumnBigInt beforePriorAmount;

  late final _is.ColumnString currency;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnInt supersededById;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    companyId,
    bsnsYear,
    reportCode,
    fsDiv,
    statement,
    accountId,
    accountName,
    accountDetail,
    ord,
    periodName,
    amount,
    cumulativeAmount,
    priorPeriodName,
    priorAmount,
    priorCumulativeAmount,
    priorQuarterName,
    priorQuarterAmount,
    beforePriorPeriodName,
    beforePriorAmount,
    currency,
    sourceId,
    supersededById,
  ];
}

class FinancialFactInclude extends _is.IncludeObject {
  FinancialFactInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => FinancialFact.t;
}

class FinancialFactIncludeList extends _is.IncludeList {
  FinancialFactIncludeList._({
    _is.WhereExpressionBuilder<FinancialFactTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FinancialFact.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => FinancialFact.t;
}

class FinancialFactRepository {
  const FinancialFactRepository._();

  /// Returns a list of [FinancialFact]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<FinancialFact>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FinancialFactTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FinancialFactTable>? orderBy,
    _is.OrderByListBuilder<FinancialFactTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FinancialFact>(
      where: where?.call(FinancialFact.t),
      orderBy: orderBy?.call(FinancialFact.t),
      orderByList: orderByList?.call(FinancialFact.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [FinancialFact] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<FinancialFact?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FinancialFactTable>? where,
    int? offset,
    _is.OrderByBuilder<FinancialFactTable>? orderBy,
    _is.OrderByListBuilder<FinancialFactTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FinancialFact>(
      where: where?.call(FinancialFact.t),
      orderBy: orderBy?.call(FinancialFact.t),
      orderByList: orderByList?.call(FinancialFact.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FinancialFact] by its [id] or null if no such row exists.
  Future<FinancialFact?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FinancialFact>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FinancialFact]s in the list and returns the inserted rows.
  ///
  /// The returned [FinancialFact]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialFact>> insert(
    _is.DatabaseSession session,
    List<FinancialFact> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<FinancialFact>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [FinancialFact] and returns the inserted row.
  ///
  /// The returned [FinancialFact] will have its `id` field set.
  Future<FinancialFact> insertRow(
    _is.DatabaseSession session,
    FinancialFact row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<FinancialFact>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [FinancialFact]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [FinancialFact]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialFact>> upsert(
    _is.DatabaseSession session,
    List<FinancialFact> rows, {
    required _is.ColumnSelections<FinancialFactTable> conflictColumns,
    _is.ColumnSelections<FinancialFactTable>? updateColumns,
    _is.WhereExpressionBuilder<FinancialFactTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<FinancialFact>(
      rows,
      conflictColumns: conflictColumns(FinancialFact.t),
      updateColumns: updateColumns?.call(FinancialFact.t),
      updateWhere: updateWhere?.call(FinancialFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [FinancialFact] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [FinancialFact] will have its `id` field set.
  Future<FinancialFact?> upsertRow(
    _is.DatabaseSession session,
    FinancialFact row, {
    required _is.ColumnSelections<FinancialFactTable> conflictColumns,
    _is.ColumnSelections<FinancialFactTable>? updateColumns,
    _is.WhereExpressionBuilder<FinancialFactTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<FinancialFact>(
      row,
      conflictColumns: conflictColumns(FinancialFact.t),
      updateColumns: updateColumns?.call(FinancialFact.t),
      updateWhere: updateWhere?.call(FinancialFact.t),
      transaction: transaction,
    );
  }

  /// Updates all [FinancialFact]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialFact>> update(
    _is.DatabaseSession session,
    List<FinancialFact> rows, {
    _is.ColumnSelections<FinancialFactTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<FinancialFact>(
      rows,
      columns: columns?.call(FinancialFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [FinancialFact]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FinancialFact> updateRow(
    _is.DatabaseSession session,
    FinancialFact row, {
    _is.ColumnSelections<FinancialFactTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<FinancialFact>(
      row,
      columns: columns?.call(FinancialFact.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FinancialFact] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FinancialFact?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<FinancialFactUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<FinancialFact>(
      id,
      columnValues: columnValues(FinancialFact.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FinancialFact]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialFact>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FinancialFactUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<FinancialFactTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FinancialFactTable>? orderBy,
    _is.OrderByListBuilder<FinancialFactTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<FinancialFact>(
      columnValues: columnValues(FinancialFact.t.updateTable),
      where: where(FinancialFact.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FinancialFact.t),
      orderByList: orderByList?.call(FinancialFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [FinancialFact]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialFact>> delete(
    _is.DatabaseSession session,
    List<FinancialFact> rows, {
    _is.OrderByBuilder<FinancialFactTable>? orderBy,
    _is.OrderByListBuilder<FinancialFactTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<FinancialFact>(
      rows,
      orderBy: orderBy?.call(FinancialFact.t),
      orderByList: orderByList?.call(FinancialFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [FinancialFact].
  Future<FinancialFact> deleteRow(
    _is.DatabaseSession session,
    FinancialFact row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FinancialFact>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialFact>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FinancialFactTable> where,
    _is.OrderByBuilder<FinancialFactTable>? orderBy,
    _is.OrderByListBuilder<FinancialFactTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<FinancialFact>(
      where: where(FinancialFact.t),
      orderBy: orderBy?.call(FinancialFact.t),
      orderByList: orderByList?.call(FinancialFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FinancialFactTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<FinancialFact>(
      where: where?.call(FinancialFact.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FinancialFact] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FinancialFactTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FinancialFact>(
      where: where(FinancialFact.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
