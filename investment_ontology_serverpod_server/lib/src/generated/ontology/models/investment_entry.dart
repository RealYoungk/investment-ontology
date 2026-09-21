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
import '../../ontology/models/disclosure_link_basis.dart' as _i0btqt1b;

/// 타법인 출자 한 행 (타법인 출자현황 otrCprInvstmntSttus). 금액은 원 단위 (API가 원문 백만원을 원으로 바꿔 준다).
abstract class InvestmentEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  InvestmentEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.investeeName,
    this.purpose,
    this.firstAcquiredOn,
    this.firstAcquiredAmount,
    this.sharesBegin,
    this.ratioBegin,
    this.bookValueBegin,
    this.sharesChange,
    this.amountChange,
    this.valuationChange,
    this.sharesEnd,
    this.ratioEnd,
    this.bookValueEnd,
    this.investeeTotalAssets,
    this.investeeNetIncome,
    required this.isTotal,
    this.investeeCompanyId,
    this.investeeLinkBasis,
  });

  factory InvestmentEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String investeeName,
    String? purpose,
    DateTime? firstAcquiredOn,
    BigInt? firstAcquiredAmount,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? bookValueBegin,
    BigInt? sharesChange,
    BigInt? amountChange,
    BigInt? valuationChange,
    BigInt? sharesEnd,
    double? ratioEnd,
    BigInt? bookValueEnd,
    BigInt? investeeTotalAssets,
    BigInt? investeeNetIncome,
    required bool isTotal,
    int? investeeCompanyId,
    _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis,
  }) = _InvestmentEntryImpl;

  factory InvestmentEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return InvestmentEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      investeeName: jsonSerialization['investeeName'] as String,
      purpose: jsonSerialization['purpose'] as String?,
      firstAcquiredOn: jsonSerialization['firstAcquiredOn'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['firstAcquiredOn'],
            ),
      firstAcquiredAmount: jsonSerialization['firstAcquiredAmount'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['firstAcquiredAmount'],
            ),
      sharesBegin: jsonSerialization['sharesBegin'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['sharesBegin']),
      ratioBegin: (jsonSerialization['ratioBegin'] as num?)?.toDouble(),
      bookValueBegin: jsonSerialization['bookValueBegin'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['bookValueBegin'],
            ),
      sharesChange: jsonSerialization['sharesChange'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['sharesChange']),
      amountChange: jsonSerialization['amountChange'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['amountChange']),
      valuationChange: jsonSerialization['valuationChange'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['valuationChange'],
            ),
      sharesEnd: jsonSerialization['sharesEnd'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['sharesEnd']),
      ratioEnd: (jsonSerialization['ratioEnd'] as num?)?.toDouble(),
      bookValueEnd: jsonSerialization['bookValueEnd'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['bookValueEnd']),
      investeeTotalAssets: jsonSerialization['investeeTotalAssets'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['investeeTotalAssets'],
            ),
      investeeNetIncome: jsonSerialization['investeeNetIncome'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['investeeNetIncome'],
            ),
      isTotal: _is.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
      investeeCompanyId: jsonSerialization['investeeCompanyId'] as int?,
      investeeLinkBasis: jsonSerialization['investeeLinkBasis'] == null
          ? null
          : _i0btqt1b.DisclosureLinkBasis.fromJson(
              (jsonSerialization['investeeLinkBasis'] as String),
            ),
    );
  }

  static final t = InvestmentEntryTable();

  static const db = InvestmentEntryRepository._();

  @override
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 줄바꿈·겹공백을 정리한 출자 대상 이름
  String investeeName;

  /// 출자 목적 원문 (경영참여, 단순투자, 일반투자 …)
  String? purpose;

  DateTime? firstAcquiredOn;

  BigInt? firstAcquiredAmount;

  BigInt? sharesBegin;

  double? ratioBegin;

  BigInt? bookValueBegin;

  /// 증감: 취득(처분) 수량·금액, 평가손익
  BigInt? sharesChange;

  BigInt? amountChange;

  BigInt? valuationChange;

  BigInt? sharesEnd;

  /// 기말 지분율 (%)
  double? ratioEnd;

  BigInt? bookValueEnd;

  /// 출자 대상의 최근 사업연도 총자산·당기순이익
  BigInt? investeeTotalAssets;

  BigInt? investeeNetIncome;

  bool isTotal;

  int? investeeCompanyId;

  _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [InvestmentEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  InvestmentEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? investeeName,
    String? purpose,
    DateTime? firstAcquiredOn,
    BigInt? firstAcquiredAmount,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? bookValueBegin,
    BigInt? sharesChange,
    BigInt? amountChange,
    BigInt? valuationChange,
    BigInt? sharesEnd,
    double? ratioEnd,
    BigInt? bookValueEnd,
    BigInt? investeeTotalAssets,
    BigInt? investeeNetIncome,
    bool? isTotal,
    int? investeeCompanyId,
    _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvestmentEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'investeeName': investeeName,
      if (purpose != null) 'purpose': purpose,
      if (firstAcquiredOn != null) 'firstAcquiredOn': firstAcquiredOn?.toJson(),
      if (firstAcquiredAmount != null)
        'firstAcquiredAmount': firstAcquiredAmount?.toJson(),
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (bookValueBegin != null) 'bookValueBegin': bookValueBegin?.toJson(),
      if (sharesChange != null) 'sharesChange': sharesChange?.toJson(),
      if (amountChange != null) 'amountChange': amountChange?.toJson(),
      if (valuationChange != null) 'valuationChange': valuationChange?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (bookValueEnd != null) 'bookValueEnd': bookValueEnd?.toJson(),
      if (investeeTotalAssets != null)
        'investeeTotalAssets': investeeTotalAssets?.toJson(),
      if (investeeNetIncome != null)
        'investeeNetIncome': investeeNetIncome?.toJson(),
      'isTotal': isTotal,
      if (investeeCompanyId != null) 'investeeCompanyId': investeeCompanyId,
      if (investeeLinkBasis != null)
        'investeeLinkBasis': investeeLinkBasis?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InvestmentEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'investeeName': investeeName,
      if (purpose != null) 'purpose': purpose,
      if (firstAcquiredOn != null) 'firstAcquiredOn': firstAcquiredOn?.toJson(),
      if (firstAcquiredAmount != null)
        'firstAcquiredAmount': firstAcquiredAmount?.toJson(),
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (bookValueBegin != null) 'bookValueBegin': bookValueBegin?.toJson(),
      if (sharesChange != null) 'sharesChange': sharesChange?.toJson(),
      if (amountChange != null) 'amountChange': amountChange?.toJson(),
      if (valuationChange != null) 'valuationChange': valuationChange?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (bookValueEnd != null) 'bookValueEnd': bookValueEnd?.toJson(),
      if (investeeTotalAssets != null)
        'investeeTotalAssets': investeeTotalAssets?.toJson(),
      if (investeeNetIncome != null)
        'investeeNetIncome': investeeNetIncome?.toJson(),
      'isTotal': isTotal,
      if (investeeCompanyId != null) 'investeeCompanyId': investeeCompanyId,
      if (investeeLinkBasis != null)
        'investeeLinkBasis': investeeLinkBasis?.toJson(),
    };
  }

  static InvestmentEntryInclude include() {
    return InvestmentEntryInclude._();
  }

  static InvestmentEntryIncludeList includeList({
    _is.WhereExpressionBuilder<InvestmentEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InvestmentEntryTable>? orderBy,
    _is.OrderByListBuilder<InvestmentEntryTable>? orderByList,
    InvestmentEntryInclude? include,
  }) {
    return InvestmentEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InvestmentEntry.t),
      orderByList: orderByList?.call(InvestmentEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InvestmentEntryImpl extends InvestmentEntry {
  _InvestmentEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String investeeName,
    String? purpose,
    DateTime? firstAcquiredOn,
    BigInt? firstAcquiredAmount,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? bookValueBegin,
    BigInt? sharesChange,
    BigInt? amountChange,
    BigInt? valuationChange,
    BigInt? sharesEnd,
    double? ratioEnd,
    BigInt? bookValueEnd,
    BigInt? investeeTotalAssets,
    BigInt? investeeNetIncome,
    required bool isTotal,
    int? investeeCompanyId,
    _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         investeeName: investeeName,
         purpose: purpose,
         firstAcquiredOn: firstAcquiredOn,
         firstAcquiredAmount: firstAcquiredAmount,
         sharesBegin: sharesBegin,
         ratioBegin: ratioBegin,
         bookValueBegin: bookValueBegin,
         sharesChange: sharesChange,
         amountChange: amountChange,
         valuationChange: valuationChange,
         sharesEnd: sharesEnd,
         ratioEnd: ratioEnd,
         bookValueEnd: bookValueEnd,
         investeeTotalAssets: investeeTotalAssets,
         investeeNetIncome: investeeNetIncome,
         isTotal: isTotal,
         investeeCompanyId: investeeCompanyId,
         investeeLinkBasis: investeeLinkBasis,
       );

  /// Returns a shallow copy of this [InvestmentEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  InvestmentEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? investeeName,
    Object? purpose = _Undefined,
    Object? firstAcquiredOn = _Undefined,
    Object? firstAcquiredAmount = _Undefined,
    Object? sharesBegin = _Undefined,
    Object? ratioBegin = _Undefined,
    Object? bookValueBegin = _Undefined,
    Object? sharesChange = _Undefined,
    Object? amountChange = _Undefined,
    Object? valuationChange = _Undefined,
    Object? sharesEnd = _Undefined,
    Object? ratioEnd = _Undefined,
    Object? bookValueEnd = _Undefined,
    Object? investeeTotalAssets = _Undefined,
    Object? investeeNetIncome = _Undefined,
    bool? isTotal,
    Object? investeeCompanyId = _Undefined,
    Object? investeeLinkBasis = _Undefined,
  }) {
    return InvestmentEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      investeeName: investeeName ?? this.investeeName,
      purpose: purpose is String? ? purpose : this.purpose,
      firstAcquiredOn: firstAcquiredOn is DateTime?
          ? firstAcquiredOn
          : this.firstAcquiredOn,
      firstAcquiredAmount: firstAcquiredAmount is BigInt?
          ? firstAcquiredAmount
          : this.firstAcquiredAmount,
      sharesBegin: sharesBegin is BigInt? ? sharesBegin : this.sharesBegin,
      ratioBegin: ratioBegin is double? ? ratioBegin : this.ratioBegin,
      bookValueBegin: bookValueBegin is BigInt?
          ? bookValueBegin
          : this.bookValueBegin,
      sharesChange: sharesChange is BigInt? ? sharesChange : this.sharesChange,
      amountChange: amountChange is BigInt? ? amountChange : this.amountChange,
      valuationChange: valuationChange is BigInt?
          ? valuationChange
          : this.valuationChange,
      sharesEnd: sharesEnd is BigInt? ? sharesEnd : this.sharesEnd,
      ratioEnd: ratioEnd is double? ? ratioEnd : this.ratioEnd,
      bookValueEnd: bookValueEnd is BigInt? ? bookValueEnd : this.bookValueEnd,
      investeeTotalAssets: investeeTotalAssets is BigInt?
          ? investeeTotalAssets
          : this.investeeTotalAssets,
      investeeNetIncome: investeeNetIncome is BigInt?
          ? investeeNetIncome
          : this.investeeNetIncome,
      isTotal: isTotal ?? this.isTotal,
      investeeCompanyId: investeeCompanyId is int?
          ? investeeCompanyId
          : this.investeeCompanyId,
      investeeLinkBasis: investeeLinkBasis is _i0btqt1b.DisclosureLinkBasis?
          ? investeeLinkBasis
          : this.investeeLinkBasis,
    );
  }
}

class InvestmentEntryUpdateTable extends _is.UpdateTable<InvestmentEntryTable> {
  InvestmentEntryUpdateTable(super.table);

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

  _is.ColumnValue<int, int> ord(int value) => _is.ColumnValue(
    table.ord,
    value,
  );

  _is.ColumnValue<String, String> investeeName(String value) => _is.ColumnValue(
    table.investeeName,
    value,
  );

  _is.ColumnValue<String, String> purpose(String? value) => _is.ColumnValue(
    table.purpose,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> firstAcquiredOn(DateTime? value) =>
      _is.ColumnValue(
        table.firstAcquiredOn,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> firstAcquiredAmount(BigInt? value) =>
      _is.ColumnValue(
        table.firstAcquiredAmount,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> sharesBegin(BigInt? value) => _is.ColumnValue(
    table.sharesBegin,
    value,
  );

  _is.ColumnValue<double, double> ratioBegin(double? value) => _is.ColumnValue(
    table.ratioBegin,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> bookValueBegin(BigInt? value) =>
      _is.ColumnValue(
        table.bookValueBegin,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> sharesChange(BigInt? value) =>
      _is.ColumnValue(
        table.sharesChange,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> amountChange(BigInt? value) =>
      _is.ColumnValue(
        table.amountChange,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> valuationChange(BigInt? value) =>
      _is.ColumnValue(
        table.valuationChange,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> sharesEnd(BigInt? value) => _is.ColumnValue(
    table.sharesEnd,
    value,
  );

  _is.ColumnValue<double, double> ratioEnd(double? value) => _is.ColumnValue(
    table.ratioEnd,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> bookValueEnd(BigInt? value) =>
      _is.ColumnValue(
        table.bookValueEnd,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> investeeTotalAssets(BigInt? value) =>
      _is.ColumnValue(
        table.investeeTotalAssets,
        value,
      );

  _is.ColumnValue<BigInt, BigInt> investeeNetIncome(BigInt? value) =>
      _is.ColumnValue(
        table.investeeNetIncome,
        value,
      );

  _is.ColumnValue<bool, bool> isTotal(bool value) => _is.ColumnValue(
    table.isTotal,
    value,
  );

  _is.ColumnValue<int, int> investeeCompanyId(int? value) => _is.ColumnValue(
    table.investeeCompanyId,
    value,
  );

  _is.ColumnValue<_i0btqt1b.DisclosureLinkBasis, _i0btqt1b.DisclosureLinkBasis>
  investeeLinkBasis(_i0btqt1b.DisclosureLinkBasis? value) => _is.ColumnValue(
    table.investeeLinkBasis,
    value,
  );
}

class InvestmentEntryTable extends _is.Table<int?> {
  InvestmentEntryTable({super.tableRelation})
    : super(tableName: 'investment_entry') {
    updateTable = InvestmentEntryUpdateTable(this);
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
    ord = _is.ColumnInt(
      'ord',
      this,
    );
    investeeName = _is.ColumnString(
      'investeeName',
      this,
    );
    purpose = _is.ColumnString(
      'purpose',
      this,
    );
    firstAcquiredOn = _is.ColumnDateTime(
      'firstAcquiredOn',
      this,
    );
    firstAcquiredAmount = _is.ColumnBigInt(
      'firstAcquiredAmount',
      this,
    );
    sharesBegin = _is.ColumnBigInt(
      'sharesBegin',
      this,
    );
    ratioBegin = _is.ColumnDouble(
      'ratioBegin',
      this,
    );
    bookValueBegin = _is.ColumnBigInt(
      'bookValueBegin',
      this,
    );
    sharesChange = _is.ColumnBigInt(
      'sharesChange',
      this,
    );
    amountChange = _is.ColumnBigInt(
      'amountChange',
      this,
    );
    valuationChange = _is.ColumnBigInt(
      'valuationChange',
      this,
    );
    sharesEnd = _is.ColumnBigInt(
      'sharesEnd',
      this,
    );
    ratioEnd = _is.ColumnDouble(
      'ratioEnd',
      this,
    );
    bookValueEnd = _is.ColumnBigInt(
      'bookValueEnd',
      this,
    );
    investeeTotalAssets = _is.ColumnBigInt(
      'investeeTotalAssets',
      this,
    );
    investeeNetIncome = _is.ColumnBigInt(
      'investeeNetIncome',
      this,
    );
    isTotal = _is.ColumnBool(
      'isTotal',
      this,
    );
    investeeCompanyId = _is.ColumnInt(
      'investeeCompanyId',
      this,
    );
    investeeLinkBasis = _is.ColumnEnum(
      'investeeLinkBasis',
      this,
      _is.EnumSerialization.byName,
    );
  }

  late final InvestmentEntryUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnInt ord;

  /// 줄바꿈·겹공백을 정리한 출자 대상 이름
  late final _is.ColumnString investeeName;

  /// 출자 목적 원문 (경영참여, 단순투자, 일반투자 …)
  late final _is.ColumnString purpose;

  late final _is.ColumnDateTime firstAcquiredOn;

  late final _is.ColumnBigInt firstAcquiredAmount;

  late final _is.ColumnBigInt sharesBegin;

  late final _is.ColumnDouble ratioBegin;

  late final _is.ColumnBigInt bookValueBegin;

  /// 증감: 취득(처분) 수량·금액, 평가손익
  late final _is.ColumnBigInt sharesChange;

  late final _is.ColumnBigInt amountChange;

  late final _is.ColumnBigInt valuationChange;

  late final _is.ColumnBigInt sharesEnd;

  /// 기말 지분율 (%)
  late final _is.ColumnDouble ratioEnd;

  late final _is.ColumnBigInt bookValueEnd;

  /// 출자 대상의 최근 사업연도 총자산·당기순이익
  late final _is.ColumnBigInt investeeTotalAssets;

  late final _is.ColumnBigInt investeeNetIncome;

  late final _is.ColumnBool isTotal;

  late final _is.ColumnInt investeeCompanyId;

  late final _is.ColumnEnum<_i0btqt1b.DisclosureLinkBasis> investeeLinkBasis;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    companyId,
    bsnsYear,
    ord,
    investeeName,
    purpose,
    firstAcquiredOn,
    firstAcquiredAmount,
    sharesBegin,
    ratioBegin,
    bookValueBegin,
    sharesChange,
    amountChange,
    valuationChange,
    sharesEnd,
    ratioEnd,
    bookValueEnd,
    investeeTotalAssets,
    investeeNetIncome,
    isTotal,
    investeeCompanyId,
    investeeLinkBasis,
  ];
}

class InvestmentEntryInclude extends _is.IncludeObject {
  InvestmentEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => InvestmentEntry.t;
}

class InvestmentEntryIncludeList extends _is.IncludeList {
  InvestmentEntryIncludeList._({
    _is.WhereExpressionBuilder<InvestmentEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(InvestmentEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => InvestmentEntry.t;
}

class InvestmentEntryRepository {
  const InvestmentEntryRepository._();

  /// Returns a list of [InvestmentEntry]s matching the given query parameters.
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
  Future<List<InvestmentEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InvestmentEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InvestmentEntryTable>? orderBy,
    _is.OrderByListBuilder<InvestmentEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<InvestmentEntry>(
      where: where?.call(InvestmentEntry.t),
      orderBy: orderBy?.call(InvestmentEntry.t),
      orderByList: orderByList?.call(InvestmentEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [InvestmentEntry] matching the given query parameters.
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
  Future<InvestmentEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InvestmentEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<InvestmentEntryTable>? orderBy,
    _is.OrderByListBuilder<InvestmentEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<InvestmentEntry>(
      where: where?.call(InvestmentEntry.t),
      orderBy: orderBy?.call(InvestmentEntry.t),
      orderByList: orderByList?.call(InvestmentEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [InvestmentEntry] by its [id] or null if no such row exists.
  Future<InvestmentEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<InvestmentEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [InvestmentEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [InvestmentEntry]s will have their `id` fields set.
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
  Future<List<InvestmentEntry>> insert(
    _is.DatabaseSession session,
    List<InvestmentEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<InvestmentEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [InvestmentEntry] and returns the inserted row.
  ///
  /// The returned [InvestmentEntry] will have its `id` field set.
  Future<InvestmentEntry> insertRow(
    _is.DatabaseSession session,
    InvestmentEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<InvestmentEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [InvestmentEntry]s in the list and returns the resulting rows.
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
  /// The returned [InvestmentEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InvestmentEntry>> upsert(
    _is.DatabaseSession session,
    List<InvestmentEntry> rows, {
    required _is.ColumnSelections<InvestmentEntryTable> conflictColumns,
    _is.ColumnSelections<InvestmentEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<InvestmentEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<InvestmentEntry>(
      rows,
      conflictColumns: conflictColumns(InvestmentEntry.t),
      updateColumns: updateColumns?.call(InvestmentEntry.t),
      updateWhere: updateWhere?.call(InvestmentEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [InvestmentEntry] and returns the resulting row.
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
  /// The returned [InvestmentEntry] will have its `id` field set.
  Future<InvestmentEntry?> upsertRow(
    _is.DatabaseSession session,
    InvestmentEntry row, {
    required _is.ColumnSelections<InvestmentEntryTable> conflictColumns,
    _is.ColumnSelections<InvestmentEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<InvestmentEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<InvestmentEntry>(
      row,
      conflictColumns: conflictColumns(InvestmentEntry.t),
      updateColumns: updateColumns?.call(InvestmentEntry.t),
      updateWhere: updateWhere?.call(InvestmentEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [InvestmentEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InvestmentEntry>> update(
    _is.DatabaseSession session,
    List<InvestmentEntry> rows, {
    _is.ColumnSelections<InvestmentEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<InvestmentEntry>(
      rows,
      columns: columns?.call(InvestmentEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [InvestmentEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<InvestmentEntry> updateRow(
    _is.DatabaseSession session,
    InvestmentEntry row, {
    _is.ColumnSelections<InvestmentEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<InvestmentEntry>(
      row,
      columns: columns?.call(InvestmentEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InvestmentEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<InvestmentEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<InvestmentEntryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<InvestmentEntry>(
      id,
      columnValues: columnValues(InvestmentEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [InvestmentEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InvestmentEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<InvestmentEntryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<InvestmentEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InvestmentEntryTable>? orderBy,
    _is.OrderByListBuilder<InvestmentEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<InvestmentEntry>(
      columnValues: columnValues(InvestmentEntry.t.updateTable),
      where: where(InvestmentEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InvestmentEntry.t),
      orderByList: orderByList?.call(InvestmentEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [InvestmentEntry]s in the list and returns the deleted rows.
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
  Future<List<InvestmentEntry>> delete(
    _is.DatabaseSession session,
    List<InvestmentEntry> rows, {
    _is.OrderByBuilder<InvestmentEntryTable>? orderBy,
    _is.OrderByListBuilder<InvestmentEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<InvestmentEntry>(
      rows,
      orderBy: orderBy?.call(InvestmentEntry.t),
      orderByList: orderByList?.call(InvestmentEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [InvestmentEntry].
  Future<InvestmentEntry> deleteRow(
    _is.DatabaseSession session,
    InvestmentEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<InvestmentEntry>(
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
  Future<List<InvestmentEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InvestmentEntryTable> where,
    _is.OrderByBuilder<InvestmentEntryTable>? orderBy,
    _is.OrderByListBuilder<InvestmentEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<InvestmentEntry>(
      where: where(InvestmentEntry.t),
      orderBy: orderBy?.call(InvestmentEntry.t),
      orderByList: orderByList?.call(InvestmentEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InvestmentEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<InvestmentEntry>(
      where: where?.call(InvestmentEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [InvestmentEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InvestmentEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<InvestmentEntry>(
      where: where(InvestmentEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
