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

import '../../ontology/models/filing_fetch_status.dart' as _iy9345ub;
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;

/// 수집 장부: DART 공시 목록(list.json)에서 찾은 상장사 정기보고서.
/// 온톨로지 엔티티가 아니라, 어떤 보고서를 받았고 받을지 기록한다.
abstract class DartFiling
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DartFiling._({
    this.id,
    required this.rceptNo,
    required this.corpCode,
    this.companyId,
    required this.reportName,
    this.receivedDate,
    this.bsnsYear,
    this.reportCode,
    required this.consolidatedStatus,
    required this.separateStatus,
    int? attempts,
    this.lastError,
    required this.discoveredAt,
    this.checkedAt,
  }) : attempts = attempts ?? 0;

  factory DartFiling({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    required _iy9345ub.FilingFetchStatus consolidatedStatus,
    required _iy9345ub.FilingFetchStatus separateStatus,
    int? attempts,
    String? lastError,
    required DateTime discoveredAt,
    DateTime? checkedAt,
  }) = _DartFilingImpl;

  factory DartFiling.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartFiling(
      id: jsonSerialization['id'] as int?,
      rceptNo: jsonSerialization['rceptNo'] as String,
      corpCode: jsonSerialization['corpCode'] as String,
      companyId: jsonSerialization['companyId'] as int?,
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: jsonSerialization['receivedDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['receivedDate'],
            ),
      bsnsYear: jsonSerialization['bsnsYear'] as int?,
      reportCode: jsonSerialization['reportCode'] == null
          ? null
          : _i6mbh8k5.FinancialReportCode.fromJson(
              (jsonSerialization['reportCode'] as String),
            ),
      consolidatedStatus: _iy9345ub.FilingFetchStatus.fromJson(
        (jsonSerialization['consolidatedStatus'] as String),
      ),
      separateStatus: _iy9345ub.FilingFetchStatus.fromJson(
        (jsonSerialization['separateStatus'] as String),
      ),
      attempts: jsonSerialization['attempts'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      discoveredAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['discoveredAt'],
      ),
      checkedAt: jsonSerialization['checkedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['checkedAt']),
    );
  }

  static final t = DartFilingTable();

  static const db = DartFilingRepository._();

  @override
  int? id;

  /// 공시 접수번호 (14자리)
  String rceptNo;

  String corpCode;

  int? companyId;

  /// 예: "[기재정정]사업보고서 (2025.12)"
  String reportName;

  /// 접수일 (UTC 자정)
  DateTime? receivedDate;

  int? bsnsYear;

  _i6mbh8k5.FinancialReportCode? reportCode;

  _iy9345ub.FilingFetchStatus consolidatedStatus;

  _iy9345ub.FilingFetchStatus separateStatus;

  /// 실패한 호출 수 (연결·별도 합산)
  int attempts;

  String? lastError;

  DateTime discoveredAt;

  DateTime? checkedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DartFiling]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DartFiling copyWith({
    int? id,
    String? rceptNo,
    String? corpCode,
    int? companyId,
    String? reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    _iy9345ub.FilingFetchStatus? consolidatedStatus,
    _iy9345ub.FilingFetchStatus? separateStatus,
    int? attempts,
    String? lastError,
    DateTime? discoveredAt,
    DateTime? checkedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartFiling',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (reportCode != null) 'reportCode': reportCode?.toJson(),
      'consolidatedStatus': consolidatedStatus.toJson(),
      'separateStatus': separateStatus.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      'discoveredAt': discoveredAt.toJson(),
      if (checkedAt != null) 'checkedAt': checkedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartFiling',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (reportCode != null) 'reportCode': reportCode?.toJson(),
      'consolidatedStatus': consolidatedStatus.toJson(),
      'separateStatus': separateStatus.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      'discoveredAt': discoveredAt.toJson(),
      if (checkedAt != null) 'checkedAt': checkedAt?.toJson(),
    };
  }

  static DartFilingInclude include() {
    return DartFilingInclude._();
  }

  static DartFilingIncludeList includeList({
    _is.WhereExpressionBuilder<DartFilingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingTable>? orderBy,
    _is.OrderByListBuilder<DartFilingTable>? orderByList,
    DartFilingInclude? include,
  }) {
    return DartFilingIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartFiling.t),
      orderByList: orderByList?.call(DartFiling.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartFilingImpl extends DartFiling {
  _DartFilingImpl({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    required _iy9345ub.FilingFetchStatus consolidatedStatus,
    required _iy9345ub.FilingFetchStatus separateStatus,
    int? attempts,
    String? lastError,
    required DateTime discoveredAt,
    DateTime? checkedAt,
  }) : super._(
         id: id,
         rceptNo: rceptNo,
         corpCode: corpCode,
         companyId: companyId,
         reportName: reportName,
         receivedDate: receivedDate,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         consolidatedStatus: consolidatedStatus,
         separateStatus: separateStatus,
         attempts: attempts,
         lastError: lastError,
         discoveredAt: discoveredAt,
         checkedAt: checkedAt,
       );

  /// Returns a shallow copy of this [DartFiling]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DartFiling copyWith({
    Object? id = _Undefined,
    String? rceptNo,
    String? corpCode,
    Object? companyId = _Undefined,
    String? reportName,
    Object? receivedDate = _Undefined,
    Object? bsnsYear = _Undefined,
    Object? reportCode = _Undefined,
    _iy9345ub.FilingFetchStatus? consolidatedStatus,
    _iy9345ub.FilingFetchStatus? separateStatus,
    int? attempts,
    Object? lastError = _Undefined,
    DateTime? discoveredAt,
    Object? checkedAt = _Undefined,
  }) {
    return DartFiling(
      id: id is int? ? id : this.id,
      rceptNo: rceptNo ?? this.rceptNo,
      corpCode: corpCode ?? this.corpCode,
      companyId: companyId is int? ? companyId : this.companyId,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate is DateTime?
          ? receivedDate
          : this.receivedDate,
      bsnsYear: bsnsYear is int? ? bsnsYear : this.bsnsYear,
      reportCode: reportCode is _i6mbh8k5.FinancialReportCode?
          ? reportCode
          : this.reportCode,
      consolidatedStatus: consolidatedStatus ?? this.consolidatedStatus,
      separateStatus: separateStatus ?? this.separateStatus,
      attempts: attempts ?? this.attempts,
      lastError: lastError is String? ? lastError : this.lastError,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      checkedAt: checkedAt is DateTime? ? checkedAt : this.checkedAt,
    );
  }
}

class DartFilingUpdateTable extends _is.UpdateTable<DartFilingTable> {
  DartFilingUpdateTable(super.table);

  _is.ColumnValue<String, String> rceptNo(String value) => _is.ColumnValue(
    table.rceptNo,
    value,
  );

  _is.ColumnValue<String, String> corpCode(String value) => _is.ColumnValue(
    table.corpCode,
    value,
  );

  _is.ColumnValue<int, int> companyId(int? value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<String, String> reportName(String value) => _is.ColumnValue(
    table.reportName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> receivedDate(DateTime? value) =>
      _is.ColumnValue(
        table.receivedDate,
        value,
      );

  _is.ColumnValue<int, int> bsnsYear(int? value) => _is.ColumnValue(
    table.bsnsYear,
    value,
  );

  _is.ColumnValue<_i6mbh8k5.FinancialReportCode, _i6mbh8k5.FinancialReportCode>
  reportCode(_i6mbh8k5.FinancialReportCode? value) => _is.ColumnValue(
    table.reportCode,
    value,
  );

  _is.ColumnValue<_iy9345ub.FilingFetchStatus, _iy9345ub.FilingFetchStatus>
  consolidatedStatus(_iy9345ub.FilingFetchStatus value) => _is.ColumnValue(
    table.consolidatedStatus,
    value,
  );

  _is.ColumnValue<_iy9345ub.FilingFetchStatus, _iy9345ub.FilingFetchStatus>
  separateStatus(_iy9345ub.FilingFetchStatus value) => _is.ColumnValue(
    table.separateStatus,
    value,
  );

  _is.ColumnValue<int, int> attempts(int value) => _is.ColumnValue(
    table.attempts,
    value,
  );

  _is.ColumnValue<String, String> lastError(String? value) => _is.ColumnValue(
    table.lastError,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> discoveredAt(DateTime value) =>
      _is.ColumnValue(
        table.discoveredAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> checkedAt(DateTime? value) =>
      _is.ColumnValue(
        table.checkedAt,
        value,
      );
}

class DartFilingTable extends _is.Table<int?> {
  DartFilingTable({super.tableRelation}) : super(tableName: 'dart_filing') {
    updateTable = DartFilingUpdateTable(this);
    rceptNo = _is.ColumnString(
      'rceptNo',
      this,
    );
    corpCode = _is.ColumnString(
      'corpCode',
      this,
    );
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    reportName = _is.ColumnString(
      'reportName',
      this,
    );
    receivedDate = _is.ColumnDateTime(
      'receivedDate',
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
    consolidatedStatus = _is.ColumnEnum(
      'consolidatedStatus',
      this,
      _is.EnumSerialization.byName,
    );
    separateStatus = _is.ColumnEnum(
      'separateStatus',
      this,
      _is.EnumSerialization.byName,
    );
    attempts = _is.ColumnInt(
      'attempts',
      this,
      hasDefault: true,
    );
    lastError = _is.ColumnString(
      'lastError',
      this,
    );
    discoveredAt = _is.ColumnDateTime(
      'discoveredAt',
      this,
    );
    checkedAt = _is.ColumnDateTime(
      'checkedAt',
      this,
    );
  }

  late final DartFilingUpdateTable updateTable;

  /// 공시 접수번호 (14자리)
  late final _is.ColumnString rceptNo;

  late final _is.ColumnString corpCode;

  late final _is.ColumnInt companyId;

  /// 예: "[기재정정]사업보고서 (2025.12)"
  late final _is.ColumnString reportName;

  /// 접수일 (UTC 자정)
  late final _is.ColumnDateTime receivedDate;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnEnum<_i6mbh8k5.FinancialReportCode> reportCode;

  late final _is.ColumnEnum<_iy9345ub.FilingFetchStatus> consolidatedStatus;

  late final _is.ColumnEnum<_iy9345ub.FilingFetchStatus> separateStatus;

  /// 실패한 호출 수 (연결·별도 합산)
  late final _is.ColumnInt attempts;

  late final _is.ColumnString lastError;

  late final _is.ColumnDateTime discoveredAt;

  late final _is.ColumnDateTime checkedAt;

  @override
  List<_is.Column> get columns => [
    id,
    rceptNo,
    corpCode,
    companyId,
    reportName,
    receivedDate,
    bsnsYear,
    reportCode,
    consolidatedStatus,
    separateStatus,
    attempts,
    lastError,
    discoveredAt,
    checkedAt,
  ];
}

class DartFilingInclude extends _is.IncludeObject {
  DartFilingInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DartFiling.t;
}

class DartFilingIncludeList extends _is.IncludeList {
  DartFilingIncludeList._({
    _is.WhereExpressionBuilder<DartFilingTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DartFiling.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DartFiling.t;
}

class DartFilingRepository {
  const DartFilingRepository._();

  /// Returns a list of [DartFiling]s matching the given query parameters.
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
  Future<List<DartFiling>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingTable>? orderBy,
    _is.OrderByListBuilder<DartFilingTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DartFiling>(
      where: where?.call(DartFiling.t),
      orderBy: orderBy?.call(DartFiling.t),
      orderByList: orderByList?.call(DartFiling.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DartFiling] matching the given query parameters.
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
  Future<DartFiling?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingTable>? where,
    int? offset,
    _is.OrderByBuilder<DartFilingTable>? orderBy,
    _is.OrderByListBuilder<DartFilingTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DartFiling>(
      where: where?.call(DartFiling.t),
      orderBy: orderBy?.call(DartFiling.t),
      orderByList: orderByList?.call(DartFiling.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DartFiling] by its [id] or null if no such row exists.
  Future<DartFiling?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DartFiling>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DartFiling]s in the list and returns the inserted rows.
  ///
  /// The returned [DartFiling]s will have their `id` fields set.
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
  Future<List<DartFiling>> insert(
    _is.DatabaseSession session,
    List<DartFiling> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DartFiling>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DartFiling] and returns the inserted row.
  ///
  /// The returned [DartFiling] will have its `id` field set.
  Future<DartFiling> insertRow(
    _is.DatabaseSession session,
    DartFiling row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DartFiling>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DartFiling]s in the list and returns the resulting rows.
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
  /// The returned [DartFiling]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFiling>> upsert(
    _is.DatabaseSession session,
    List<DartFiling> rows, {
    required _is.ColumnSelections<DartFilingTable> conflictColumns,
    _is.ColumnSelections<DartFilingTable>? updateColumns,
    _is.WhereExpressionBuilder<DartFilingTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DartFiling>(
      rows,
      conflictColumns: conflictColumns(DartFiling.t),
      updateColumns: updateColumns?.call(DartFiling.t),
      updateWhere: updateWhere?.call(DartFiling.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DartFiling] and returns the resulting row.
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
  /// The returned [DartFiling] will have its `id` field set.
  Future<DartFiling?> upsertRow(
    _is.DatabaseSession session,
    DartFiling row, {
    required _is.ColumnSelections<DartFilingTable> conflictColumns,
    _is.ColumnSelections<DartFilingTable>? updateColumns,
    _is.WhereExpressionBuilder<DartFilingTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DartFiling>(
      row,
      conflictColumns: conflictColumns(DartFiling.t),
      updateColumns: updateColumns?.call(DartFiling.t),
      updateWhere: updateWhere?.call(DartFiling.t),
      transaction: transaction,
    );
  }

  /// Updates all [DartFiling]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFiling>> update(
    _is.DatabaseSession session,
    List<DartFiling> rows, {
    _is.ColumnSelections<DartFilingTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DartFiling>(
      rows,
      columns: columns?.call(DartFiling.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DartFiling]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DartFiling> updateRow(
    _is.DatabaseSession session,
    DartFiling row, {
    _is.ColumnSelections<DartFilingTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DartFiling>(
      row,
      columns: columns?.call(DartFiling.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DartFiling] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DartFiling?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DartFilingUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DartFiling>(
      id,
      columnValues: columnValues(DartFiling.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DartFiling]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFiling>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DartFilingUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DartFilingTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingTable>? orderBy,
    _is.OrderByListBuilder<DartFilingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DartFiling>(
      columnValues: columnValues(DartFiling.t.updateTable),
      where: where(DartFiling.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartFiling.t),
      orderByList: orderByList?.call(DartFiling.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DartFiling]s in the list and returns the deleted rows.
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
  Future<List<DartFiling>> delete(
    _is.DatabaseSession session,
    List<DartFiling> rows, {
    _is.OrderByBuilder<DartFilingTable>? orderBy,
    _is.OrderByListBuilder<DartFilingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DartFiling>(
      rows,
      orderBy: orderBy?.call(DartFiling.t),
      orderByList: orderByList?.call(DartFiling.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DartFiling].
  Future<DartFiling> deleteRow(
    _is.DatabaseSession session,
    DartFiling row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DartFiling>(
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
  Future<List<DartFiling>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartFilingTable> where,
    _is.OrderByBuilder<DartFilingTable>? orderBy,
    _is.OrderByListBuilder<DartFilingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DartFiling>(
      where: where(DartFiling.t),
      orderBy: orderBy?.call(DartFiling.t),
      orderByList: orderByList?.call(DartFiling.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DartFiling>(
      where: where?.call(DartFiling.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DartFiling] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartFilingTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DartFiling>(
      where: where(DartFiling.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
