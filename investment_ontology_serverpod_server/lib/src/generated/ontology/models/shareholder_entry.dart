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

/// 최대주주 및 특수관계인 한 행 (최대주주 현황 hyslrSttus).
abstract class ShareholderEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ShareholderEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.holderName,
    this.relationText,
    this.stockKind,
    this.sharesBegin,
    this.ratioBegin,
    this.sharesEnd,
    this.ratioEnd,
    this.remark,
    required this.isTotal,
    this.holderCompanyId,
    this.holderPersonId,
    this.holderLinkBasis,
  });

  factory ShareholderEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String holderName,
    String? relationText,
    String? stockKind,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? sharesEnd,
    double? ratioEnd,
    String? remark,
    required bool isTotal,
    int? holderCompanyId,
    int? holderPersonId,
    _i0btqt1b.DisclosureLinkBasis? holderLinkBasis,
  }) = _ShareholderEntryImpl;

  factory ShareholderEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShareholderEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      holderName: jsonSerialization['holderName'] as String,
      relationText: jsonSerialization['relationText'] as String?,
      stockKind: jsonSerialization['stockKind'] as String?,
      sharesBegin: jsonSerialization['sharesBegin'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['sharesBegin']),
      ratioBegin: (jsonSerialization['ratioBegin'] as num?)?.toDouble(),
      sharesEnd: jsonSerialization['sharesEnd'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['sharesEnd']),
      ratioEnd: (jsonSerialization['ratioEnd'] as num?)?.toDouble(),
      remark: jsonSerialization['remark'] as String?,
      isTotal: _is.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
      holderCompanyId: jsonSerialization['holderCompanyId'] as int?,
      holderPersonId: jsonSerialization['holderPersonId'] as int?,
      holderLinkBasis: jsonSerialization['holderLinkBasis'] == null
          ? null
          : _i0btqt1b.DisclosureLinkBasis.fromJson(
              (jsonSerialization['holderLinkBasis'] as String),
            ),
    );
  }

  static final t = ShareholderEntryTable();

  static const db = ShareholderEntryRepository._();

  @override
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 줄바꿈·겹공백을 정리한 이름 (원문 nm)
  String holderName;

  /// 관계 원문 (최대주주 본인, 최대주주의 특수관계인, 계열회사, 친인척 …)
  String? relationText;

  /// 주식 종류 원문 (보통주, 우선주 …)
  String? stockKind;

  BigInt? sharesBegin;

  /// 기초 지분율 (%)
  double? ratioBegin;

  BigInt? sharesEnd;

  /// 기말 지분율 (%)
  double? ratioEnd;

  String? remark;

  bool isTotal;

  int? holderCompanyId;

  int? holderPersonId;

  _i0btqt1b.DisclosureLinkBasis? holderLinkBasis;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ShareholderEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ShareholderEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? holderName,
    String? relationText,
    String? stockKind,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? sharesEnd,
    double? ratioEnd,
    String? remark,
    bool? isTotal,
    int? holderCompanyId,
    int? holderPersonId,
    _i0btqt1b.DisclosureLinkBasis? holderLinkBasis,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShareholderEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'holderName': holderName,
      if (relationText != null) 'relationText': relationText,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
      if (holderCompanyId != null) 'holderCompanyId': holderCompanyId,
      if (holderPersonId != null) 'holderPersonId': holderPersonId,
      if (holderLinkBasis != null) 'holderLinkBasis': holderLinkBasis?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ShareholderEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'holderName': holderName,
      if (relationText != null) 'relationText': relationText,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
      if (holderCompanyId != null) 'holderCompanyId': holderCompanyId,
      if (holderPersonId != null) 'holderPersonId': holderPersonId,
      if (holderLinkBasis != null) 'holderLinkBasis': holderLinkBasis?.toJson(),
    };
  }

  static ShareholderEntryInclude include() {
    return ShareholderEntryInclude._();
  }

  static ShareholderEntryIncludeList includeList({
    _is.WhereExpressionBuilder<ShareholderEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ShareholderEntryTable>? orderBy,
    _is.OrderByListBuilder<ShareholderEntryTable>? orderByList,
    ShareholderEntryInclude? include,
  }) {
    return ShareholderEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ShareholderEntry.t),
      orderByList: orderByList?.call(ShareholderEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShareholderEntryImpl extends ShareholderEntry {
  _ShareholderEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String holderName,
    String? relationText,
    String? stockKind,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? sharesEnd,
    double? ratioEnd,
    String? remark,
    required bool isTotal,
    int? holderCompanyId,
    int? holderPersonId,
    _i0btqt1b.DisclosureLinkBasis? holderLinkBasis,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         holderName: holderName,
         relationText: relationText,
         stockKind: stockKind,
         sharesBegin: sharesBegin,
         ratioBegin: ratioBegin,
         sharesEnd: sharesEnd,
         ratioEnd: ratioEnd,
         remark: remark,
         isTotal: isTotal,
         holderCompanyId: holderCompanyId,
         holderPersonId: holderPersonId,
         holderLinkBasis: holderLinkBasis,
       );

  /// Returns a shallow copy of this [ShareholderEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ShareholderEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? holderName,
    Object? relationText = _Undefined,
    Object? stockKind = _Undefined,
    Object? sharesBegin = _Undefined,
    Object? ratioBegin = _Undefined,
    Object? sharesEnd = _Undefined,
    Object? ratioEnd = _Undefined,
    Object? remark = _Undefined,
    bool? isTotal,
    Object? holderCompanyId = _Undefined,
    Object? holderPersonId = _Undefined,
    Object? holderLinkBasis = _Undefined,
  }) {
    return ShareholderEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      holderName: holderName ?? this.holderName,
      relationText: relationText is String? ? relationText : this.relationText,
      stockKind: stockKind is String? ? stockKind : this.stockKind,
      sharesBegin: sharesBegin is BigInt? ? sharesBegin : this.sharesBegin,
      ratioBegin: ratioBegin is double? ? ratioBegin : this.ratioBegin,
      sharesEnd: sharesEnd is BigInt? ? sharesEnd : this.sharesEnd,
      ratioEnd: ratioEnd is double? ? ratioEnd : this.ratioEnd,
      remark: remark is String? ? remark : this.remark,
      isTotal: isTotal ?? this.isTotal,
      holderCompanyId: holderCompanyId is int?
          ? holderCompanyId
          : this.holderCompanyId,
      holderPersonId: holderPersonId is int?
          ? holderPersonId
          : this.holderPersonId,
      holderLinkBasis: holderLinkBasis is _i0btqt1b.DisclosureLinkBasis?
          ? holderLinkBasis
          : this.holderLinkBasis,
    );
  }
}

class ShareholderEntryUpdateTable
    extends _is.UpdateTable<ShareholderEntryTable> {
  ShareholderEntryUpdateTable(super.table);

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

  _is.ColumnValue<String, String> holderName(String value) => _is.ColumnValue(
    table.holderName,
    value,
  );

  _is.ColumnValue<String, String> relationText(String? value) =>
      _is.ColumnValue(
        table.relationText,
        value,
      );

  _is.ColumnValue<String, String> stockKind(String? value) => _is.ColumnValue(
    table.stockKind,
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

  _is.ColumnValue<BigInt, BigInt> sharesEnd(BigInt? value) => _is.ColumnValue(
    table.sharesEnd,
    value,
  );

  _is.ColumnValue<double, double> ratioEnd(double? value) => _is.ColumnValue(
    table.ratioEnd,
    value,
  );

  _is.ColumnValue<String, String> remark(String? value) => _is.ColumnValue(
    table.remark,
    value,
  );

  _is.ColumnValue<bool, bool> isTotal(bool value) => _is.ColumnValue(
    table.isTotal,
    value,
  );

  _is.ColumnValue<int, int> holderCompanyId(int? value) => _is.ColumnValue(
    table.holderCompanyId,
    value,
  );

  _is.ColumnValue<int, int> holderPersonId(int? value) => _is.ColumnValue(
    table.holderPersonId,
    value,
  );

  _is.ColumnValue<_i0btqt1b.DisclosureLinkBasis, _i0btqt1b.DisclosureLinkBasis>
  holderLinkBasis(_i0btqt1b.DisclosureLinkBasis? value) => _is.ColumnValue(
    table.holderLinkBasis,
    value,
  );
}

class ShareholderEntryTable extends _is.Table<int?> {
  ShareholderEntryTable({super.tableRelation})
    : super(tableName: 'shareholder_entry') {
    updateTable = ShareholderEntryUpdateTable(this);
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
    holderName = _is.ColumnString(
      'holderName',
      this,
    );
    relationText = _is.ColumnString(
      'relationText',
      this,
    );
    stockKind = _is.ColumnString(
      'stockKind',
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
    sharesEnd = _is.ColumnBigInt(
      'sharesEnd',
      this,
    );
    ratioEnd = _is.ColumnDouble(
      'ratioEnd',
      this,
    );
    remark = _is.ColumnString(
      'remark',
      this,
    );
    isTotal = _is.ColumnBool(
      'isTotal',
      this,
    );
    holderCompanyId = _is.ColumnInt(
      'holderCompanyId',
      this,
    );
    holderPersonId = _is.ColumnInt(
      'holderPersonId',
      this,
    );
    holderLinkBasis = _is.ColumnEnum(
      'holderLinkBasis',
      this,
      _is.EnumSerialization.byName,
    );
  }

  late final ShareholderEntryUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnInt ord;

  /// 줄바꿈·겹공백을 정리한 이름 (원문 nm)
  late final _is.ColumnString holderName;

  /// 관계 원문 (최대주주 본인, 최대주주의 특수관계인, 계열회사, 친인척 …)
  late final _is.ColumnString relationText;

  /// 주식 종류 원문 (보통주, 우선주 …)
  late final _is.ColumnString stockKind;

  late final _is.ColumnBigInt sharesBegin;

  /// 기초 지분율 (%)
  late final _is.ColumnDouble ratioBegin;

  late final _is.ColumnBigInt sharesEnd;

  /// 기말 지분율 (%)
  late final _is.ColumnDouble ratioEnd;

  late final _is.ColumnString remark;

  late final _is.ColumnBool isTotal;

  late final _is.ColumnInt holderCompanyId;

  late final _is.ColumnInt holderPersonId;

  late final _is.ColumnEnum<_i0btqt1b.DisclosureLinkBasis> holderLinkBasis;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    companyId,
    bsnsYear,
    ord,
    holderName,
    relationText,
    stockKind,
    sharesBegin,
    ratioBegin,
    sharesEnd,
    ratioEnd,
    remark,
    isTotal,
    holderCompanyId,
    holderPersonId,
    holderLinkBasis,
  ];
}

class ShareholderEntryInclude extends _is.IncludeObject {
  ShareholderEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ShareholderEntry.t;
}

class ShareholderEntryIncludeList extends _is.IncludeList {
  ShareholderEntryIncludeList._({
    _is.WhereExpressionBuilder<ShareholderEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ShareholderEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ShareholderEntry.t;
}

class ShareholderEntryRepository {
  const ShareholderEntryRepository._();

  /// Returns a list of [ShareholderEntry]s matching the given query parameters.
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
  Future<List<ShareholderEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ShareholderEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ShareholderEntryTable>? orderBy,
    _is.OrderByListBuilder<ShareholderEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ShareholderEntry>(
      where: where?.call(ShareholderEntry.t),
      orderBy: orderBy?.call(ShareholderEntry.t),
      orderByList: orderByList?.call(ShareholderEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ShareholderEntry] matching the given query parameters.
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
  Future<ShareholderEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ShareholderEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<ShareholderEntryTable>? orderBy,
    _is.OrderByListBuilder<ShareholderEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ShareholderEntry>(
      where: where?.call(ShareholderEntry.t),
      orderBy: orderBy?.call(ShareholderEntry.t),
      orderByList: orderByList?.call(ShareholderEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ShareholderEntry] by its [id] or null if no such row exists.
  Future<ShareholderEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ShareholderEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ShareholderEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [ShareholderEntry]s will have their `id` fields set.
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
  Future<List<ShareholderEntry>> insert(
    _is.DatabaseSession session,
    List<ShareholderEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ShareholderEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ShareholderEntry] and returns the inserted row.
  ///
  /// The returned [ShareholderEntry] will have its `id` field set.
  Future<ShareholderEntry> insertRow(
    _is.DatabaseSession session,
    ShareholderEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ShareholderEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ShareholderEntry]s in the list and returns the resulting rows.
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
  /// The returned [ShareholderEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ShareholderEntry>> upsert(
    _is.DatabaseSession session,
    List<ShareholderEntry> rows, {
    required _is.ColumnSelections<ShareholderEntryTable> conflictColumns,
    _is.ColumnSelections<ShareholderEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<ShareholderEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ShareholderEntry>(
      rows,
      conflictColumns: conflictColumns(ShareholderEntry.t),
      updateColumns: updateColumns?.call(ShareholderEntry.t),
      updateWhere: updateWhere?.call(ShareholderEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ShareholderEntry] and returns the resulting row.
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
  /// The returned [ShareholderEntry] will have its `id` field set.
  Future<ShareholderEntry?> upsertRow(
    _is.DatabaseSession session,
    ShareholderEntry row, {
    required _is.ColumnSelections<ShareholderEntryTable> conflictColumns,
    _is.ColumnSelections<ShareholderEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<ShareholderEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ShareholderEntry>(
      row,
      conflictColumns: conflictColumns(ShareholderEntry.t),
      updateColumns: updateColumns?.call(ShareholderEntry.t),
      updateWhere: updateWhere?.call(ShareholderEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [ShareholderEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ShareholderEntry>> update(
    _is.DatabaseSession session,
    List<ShareholderEntry> rows, {
    _is.ColumnSelections<ShareholderEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ShareholderEntry>(
      rows,
      columns: columns?.call(ShareholderEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ShareholderEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ShareholderEntry> updateRow(
    _is.DatabaseSession session,
    ShareholderEntry row, {
    _is.ColumnSelections<ShareholderEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ShareholderEntry>(
      row,
      columns: columns?.call(ShareholderEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ShareholderEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ShareholderEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ShareholderEntryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ShareholderEntry>(
      id,
      columnValues: columnValues(ShareholderEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ShareholderEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ShareholderEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ShareholderEntryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ShareholderEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ShareholderEntryTable>? orderBy,
    _is.OrderByListBuilder<ShareholderEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ShareholderEntry>(
      columnValues: columnValues(ShareholderEntry.t.updateTable),
      where: where(ShareholderEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ShareholderEntry.t),
      orderByList: orderByList?.call(ShareholderEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ShareholderEntry]s in the list and returns the deleted rows.
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
  Future<List<ShareholderEntry>> delete(
    _is.DatabaseSession session,
    List<ShareholderEntry> rows, {
    _is.OrderByBuilder<ShareholderEntryTable>? orderBy,
    _is.OrderByListBuilder<ShareholderEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ShareholderEntry>(
      rows,
      orderBy: orderBy?.call(ShareholderEntry.t),
      orderByList: orderByList?.call(ShareholderEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ShareholderEntry].
  Future<ShareholderEntry> deleteRow(
    _is.DatabaseSession session,
    ShareholderEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ShareholderEntry>(
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
  Future<List<ShareholderEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ShareholderEntryTable> where,
    _is.OrderByBuilder<ShareholderEntryTable>? orderBy,
    _is.OrderByListBuilder<ShareholderEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ShareholderEntry>(
      where: where(ShareholderEntry.t),
      orderBy: orderBy?.call(ShareholderEntry.t),
      orderByList: orderByList?.call(ShareholderEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ShareholderEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ShareholderEntry>(
      where: where?.call(ShareholderEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ShareholderEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ShareholderEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ShareholderEntry>(
      where: where(ShareholderEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
