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
import '../../ontology/models/fs_div.dart' as _igqrlzji;

/// 재무 보고서: 공시 1건의 연결 또는 별도 재무제표 한 벌. FinancialFact를 묶는다.
/// 정정공시로 대체되면 지우지 않고 supersededBy로 새 보고서를 가리킨다.
abstract class FinancialReport
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  FinancialReport._({
    this.id,
    required this.companyId,
    required this.rceptNo,
    required this.fsDiv,
    required this.bsnsYear,
    required this.reportCode,
    required this.reportName,
    this.receivedDate,
    required this.factCount,
    int? invalidAmountCount,
    required this.sourceId,
    this.supersededById,
    required this.fetchedAt,
  }) : invalidAmountCount = invalidAmountCount ?? 0;

  factory FinancialReport({
    int? id,
    required int companyId,
    required String rceptNo,
    required _igqrlzji.FsDiv fsDiv,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required String reportName,
    DateTime? receivedDate,
    required int factCount,
    int? invalidAmountCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) = _FinancialReportImpl;

  factory FinancialReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return FinancialReport(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      fsDiv: _igqrlzji.FsDiv.fromJson((jsonSerialization['fsDiv'] as String)),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: jsonSerialization['receivedDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['receivedDate'],
            ),
      factCount: jsonSerialization['factCount'] as int,
      invalidAmountCount: jsonSerialization['invalidAmountCount'] as int?,
      sourceId: jsonSerialization['sourceId'] as int,
      supersededById: jsonSerialization['supersededById'] as int?,
      fetchedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  static final t = FinancialReportTable();

  static const db = FinancialReportRepository._();

  @override
  int? id;

  int companyId;

  /// 재무 API 응답의 접수번호. 이 숫자들이 실린 공시
  String rceptNo;

  _igqrlzji.FsDiv fsDiv;

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  String reportName;

  DateTime? receivedDate;

  int factCount;

  /// 원천 값이 있었지만 원 단위 정수가 아니어서 비워 둔 금액 수
  int invalidAmountCount;

  int sourceId;

  int? supersededById;

  DateTime fetchedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [FinancialReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FinancialReport copyWith({
    int? id,
    int? companyId,
    String? rceptNo,
    _igqrlzji.FsDiv? fsDiv,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    String? reportName,
    DateTime? receivedDate,
    int? factCount,
    int? invalidAmountCount,
    int? sourceId,
    int? supersededById,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'rceptNo': rceptNo,
      'fsDiv': fsDiv.toJson(),
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      'factCount': factCount,
      'invalidAmountCount': invalidAmountCount,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FinancialReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'rceptNo': rceptNo,
      'fsDiv': fsDiv.toJson(),
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      'factCount': factCount,
      'invalidAmountCount': invalidAmountCount,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static FinancialReportInclude include() {
    return FinancialReportInclude._();
  }

  static FinancialReportIncludeList includeList({
    _is.WhereExpressionBuilder<FinancialReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FinancialReportTable>? orderBy,
    _is.OrderByListBuilder<FinancialReportTable>? orderByList,
    FinancialReportInclude? include,
  }) {
    return FinancialReportIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FinancialReport.t),
      orderByList: orderByList?.call(FinancialReport.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FinancialReportImpl extends FinancialReport {
  _FinancialReportImpl({
    int? id,
    required int companyId,
    required String rceptNo,
    required _igqrlzji.FsDiv fsDiv,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    required String reportName,
    DateTime? receivedDate,
    required int factCount,
    int? invalidAmountCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         companyId: companyId,
         rceptNo: rceptNo,
         fsDiv: fsDiv,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         reportName: reportName,
         receivedDate: receivedDate,
         factCount: factCount,
         invalidAmountCount: invalidAmountCount,
         sourceId: sourceId,
         supersededById: supersededById,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [FinancialReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FinancialReport copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? rceptNo,
    _igqrlzji.FsDiv? fsDiv,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    String? reportName,
    Object? receivedDate = _Undefined,
    int? factCount,
    int? invalidAmountCount,
    int? sourceId,
    Object? supersededById = _Undefined,
    DateTime? fetchedAt,
  }) {
    return FinancialReport(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      rceptNo: rceptNo ?? this.rceptNo,
      fsDiv: fsDiv ?? this.fsDiv,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate is DateTime?
          ? receivedDate
          : this.receivedDate,
      factCount: factCount ?? this.factCount,
      invalidAmountCount: invalidAmountCount ?? this.invalidAmountCount,
      sourceId: sourceId ?? this.sourceId,
      supersededById: supersededById is int?
          ? supersededById
          : this.supersededById,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class FinancialReportUpdateTable extends _is.UpdateTable<FinancialReportTable> {
  FinancialReportUpdateTable(super.table);

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<String, String> rceptNo(String value) => _is.ColumnValue(
    table.rceptNo,
    value,
  );

  _is.ColumnValue<_igqrlzji.FsDiv, _igqrlzji.FsDiv> fsDiv(
    _igqrlzji.FsDiv value,
  ) => _is.ColumnValue(
    table.fsDiv,
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

  _is.ColumnValue<String, String> reportName(String value) => _is.ColumnValue(
    table.reportName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> receivedDate(DateTime? value) =>
      _is.ColumnValue(
        table.receivedDate,
        value,
      );

  _is.ColumnValue<int, int> factCount(int value) => _is.ColumnValue(
    table.factCount,
    value,
  );

  _is.ColumnValue<int, int> invalidAmountCount(int value) => _is.ColumnValue(
    table.invalidAmountCount,
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

  _is.ColumnValue<DateTime, DateTime> fetchedAt(DateTime value) =>
      _is.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class FinancialReportTable extends _is.Table<int?> {
  FinancialReportTable({super.tableRelation})
    : super(tableName: 'financial_report') {
    updateTable = FinancialReportUpdateTable(this);
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    rceptNo = _is.ColumnString(
      'rceptNo',
      this,
    );
    fsDiv = _is.ColumnEnum(
      'fsDiv',
      this,
      _is.EnumSerialization.byName,
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
    reportName = _is.ColumnString(
      'reportName',
      this,
    );
    receivedDate = _is.ColumnDateTime(
      'receivedDate',
      this,
    );
    factCount = _is.ColumnInt(
      'factCount',
      this,
    );
    invalidAmountCount = _is.ColumnInt(
      'invalidAmountCount',
      this,
      hasDefault: true,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    supersededById = _is.ColumnInt(
      'supersededById',
      this,
    );
    fetchedAt = _is.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final FinancialReportUpdateTable updateTable;

  late final _is.ColumnInt companyId;

  /// 재무 API 응답의 접수번호. 이 숫자들이 실린 공시
  late final _is.ColumnString rceptNo;

  late final _is.ColumnEnum<_igqrlzji.FsDiv> fsDiv;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnEnum<_i6mbh8k5.FinancialReportCode> reportCode;

  late final _is.ColumnString reportName;

  late final _is.ColumnDateTime receivedDate;

  late final _is.ColumnInt factCount;

  /// 원천 값이 있었지만 원 단위 정수가 아니어서 비워 둔 금액 수
  late final _is.ColumnInt invalidAmountCount;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnInt supersededById;

  late final _is.ColumnDateTime fetchedAt;

  @override
  List<_is.Column> get columns => [
    id,
    companyId,
    rceptNo,
    fsDiv,
    bsnsYear,
    reportCode,
    reportName,
    receivedDate,
    factCount,
    invalidAmountCount,
    sourceId,
    supersededById,
    fetchedAt,
  ];
}

class FinancialReportInclude extends _is.IncludeObject {
  FinancialReportInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => FinancialReport.t;
}

class FinancialReportIncludeList extends _is.IncludeList {
  FinancialReportIncludeList._({
    _is.WhereExpressionBuilder<FinancialReportTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FinancialReport.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => FinancialReport.t;
}

class FinancialReportRepository {
  const FinancialReportRepository._();

  /// Returns a list of [FinancialReport]s matching the given query parameters.
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
  Future<List<FinancialReport>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FinancialReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FinancialReportTable>? orderBy,
    _is.OrderByListBuilder<FinancialReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FinancialReport>(
      where: where?.call(FinancialReport.t),
      orderBy: orderBy?.call(FinancialReport.t),
      orderByList: orderByList?.call(FinancialReport.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [FinancialReport] matching the given query parameters.
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
  Future<FinancialReport?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FinancialReportTable>? where,
    int? offset,
    _is.OrderByBuilder<FinancialReportTable>? orderBy,
    _is.OrderByListBuilder<FinancialReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FinancialReport>(
      where: where?.call(FinancialReport.t),
      orderBy: orderBy?.call(FinancialReport.t),
      orderByList: orderByList?.call(FinancialReport.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FinancialReport] by its [id] or null if no such row exists.
  Future<FinancialReport?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FinancialReport>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FinancialReport]s in the list and returns the inserted rows.
  ///
  /// The returned [FinancialReport]s will have their `id` fields set.
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
  Future<List<FinancialReport>> insert(
    _is.DatabaseSession session,
    List<FinancialReport> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<FinancialReport>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [FinancialReport] and returns the inserted row.
  ///
  /// The returned [FinancialReport] will have its `id` field set.
  Future<FinancialReport> insertRow(
    _is.DatabaseSession session,
    FinancialReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<FinancialReport>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [FinancialReport]s in the list and returns the resulting rows.
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
  /// The returned [FinancialReport]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialReport>> upsert(
    _is.DatabaseSession session,
    List<FinancialReport> rows, {
    required _is.ColumnSelections<FinancialReportTable> conflictColumns,
    _is.ColumnSelections<FinancialReportTable>? updateColumns,
    _is.WhereExpressionBuilder<FinancialReportTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<FinancialReport>(
      rows,
      conflictColumns: conflictColumns(FinancialReport.t),
      updateColumns: updateColumns?.call(FinancialReport.t),
      updateWhere: updateWhere?.call(FinancialReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [FinancialReport] and returns the resulting row.
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
  /// The returned [FinancialReport] will have its `id` field set.
  Future<FinancialReport?> upsertRow(
    _is.DatabaseSession session,
    FinancialReport row, {
    required _is.ColumnSelections<FinancialReportTable> conflictColumns,
    _is.ColumnSelections<FinancialReportTable>? updateColumns,
    _is.WhereExpressionBuilder<FinancialReportTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<FinancialReport>(
      row,
      conflictColumns: conflictColumns(FinancialReport.t),
      updateColumns: updateColumns?.call(FinancialReport.t),
      updateWhere: updateWhere?.call(FinancialReport.t),
      transaction: transaction,
    );
  }

  /// Updates all [FinancialReport]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialReport>> update(
    _is.DatabaseSession session,
    List<FinancialReport> rows, {
    _is.ColumnSelections<FinancialReportTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<FinancialReport>(
      rows,
      columns: columns?.call(FinancialReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [FinancialReport]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FinancialReport> updateRow(
    _is.DatabaseSession session,
    FinancialReport row, {
    _is.ColumnSelections<FinancialReportTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<FinancialReport>(
      row,
      columns: columns?.call(FinancialReport.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FinancialReport] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FinancialReport?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<FinancialReportUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<FinancialReport>(
      id,
      columnValues: columnValues(FinancialReport.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FinancialReport]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FinancialReport>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FinancialReportUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<FinancialReportTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FinancialReportTable>? orderBy,
    _is.OrderByListBuilder<FinancialReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<FinancialReport>(
      columnValues: columnValues(FinancialReport.t.updateTable),
      where: where(FinancialReport.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FinancialReport.t),
      orderByList: orderByList?.call(FinancialReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [FinancialReport]s in the list and returns the deleted rows.
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
  Future<List<FinancialReport>> delete(
    _is.DatabaseSession session,
    List<FinancialReport> rows, {
    _is.OrderByBuilder<FinancialReportTable>? orderBy,
    _is.OrderByListBuilder<FinancialReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<FinancialReport>(
      rows,
      orderBy: orderBy?.call(FinancialReport.t),
      orderByList: orderByList?.call(FinancialReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [FinancialReport].
  Future<FinancialReport> deleteRow(
    _is.DatabaseSession session,
    FinancialReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FinancialReport>(
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
  Future<List<FinancialReport>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FinancialReportTable> where,
    _is.OrderByBuilder<FinancialReportTable>? orderBy,
    _is.OrderByListBuilder<FinancialReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<FinancialReport>(
      where: where(FinancialReport.t),
      orderBy: orderBy?.call(FinancialReport.t),
      orderByList: orderByList?.call(FinancialReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FinancialReportTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<FinancialReport>(
      where: where?.call(FinancialReport.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FinancialReport] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FinancialReportTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FinancialReport>(
      where: where(FinancialReport.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
