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

/// DART에 올라온 공시 하나 (종류 가리지 않음). 기업 화면의 "최근 공시"에 쓴다.
///
/// 정기보고서는 [DartFiling]이 따로 관리한다. 이 표는 계약·증자·주요사항 등
/// 무슨 일이 있었는지 훑어보는 용도라 목록만 담는다.
abstract class DartDisclosure
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DartDisclosure._({
    this.id,
    required this.rceptNo,
    required this.corpCode,
    this.companyId,
    required this.corpName,
    required this.reportName,
    required this.receivedDate,
    this.filerName,
    required this.discoveredAt,
  });

  factory DartDisclosure({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String corpName,
    required String reportName,
    required DateTime receivedDate,
    String? filerName,
    required DateTime discoveredAt,
  }) = _DartDisclosureImpl;

  factory DartDisclosure.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartDisclosure(
      id: jsonSerialization['id'] as int?,
      rceptNo: jsonSerialization['rceptNo'] as String,
      corpCode: jsonSerialization['corpCode'] as String,
      companyId: jsonSerialization['companyId'] as int?,
      corpName: jsonSerialization['corpName'] as String,
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['receivedDate'],
      ),
      filerName: jsonSerialization['filerName'] as String?,
      discoveredAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['discoveredAt'],
      ),
    );
  }

  static final t = DartDisclosureTable();

  static const db = DartDisclosureRepository._();

  @override
  int? id;

  String rceptNo;

  String corpCode;

  int? companyId;

  String corpName;

  String reportName;

  DateTime receivedDate;

  /// 제출인 (회사가 아닌 경우도 있다 — 주주의 대량보유 보고 등)
  String? filerName;

  DateTime discoveredAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DartDisclosure]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DartDisclosure copyWith({
    int? id,
    String? rceptNo,
    String? corpCode,
    int? companyId,
    String? corpName,
    String? reportName,
    DateTime? receivedDate,
    String? filerName,
    DateTime? discoveredAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartDisclosure',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'corpName': corpName,
      'reportName': reportName,
      'receivedDate': receivedDate.toJson(),
      if (filerName != null) 'filerName': filerName,
      'discoveredAt': discoveredAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartDisclosure',
      if (id != null) 'id': id,
      'rceptNo': rceptNo,
      'corpCode': corpCode,
      if (companyId != null) 'companyId': companyId,
      'corpName': corpName,
      'reportName': reportName,
      'receivedDate': receivedDate.toJson(),
      if (filerName != null) 'filerName': filerName,
      'discoveredAt': discoveredAt.toJson(),
    };
  }

  static DartDisclosureInclude include() {
    return DartDisclosureInclude._();
  }

  static DartDisclosureIncludeList includeList({
    _is.WhereExpressionBuilder<DartDisclosureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartDisclosureTable>? orderBy,
    _is.OrderByListBuilder<DartDisclosureTable>? orderByList,
    DartDisclosureInclude? include,
  }) {
    return DartDisclosureIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartDisclosure.t),
      orderByList: orderByList?.call(DartDisclosure.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartDisclosureImpl extends DartDisclosure {
  _DartDisclosureImpl({
    int? id,
    required String rceptNo,
    required String corpCode,
    int? companyId,
    required String corpName,
    required String reportName,
    required DateTime receivedDate,
    String? filerName,
    required DateTime discoveredAt,
  }) : super._(
         id: id,
         rceptNo: rceptNo,
         corpCode: corpCode,
         companyId: companyId,
         corpName: corpName,
         reportName: reportName,
         receivedDate: receivedDate,
         filerName: filerName,
         discoveredAt: discoveredAt,
       );

  /// Returns a shallow copy of this [DartDisclosure]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DartDisclosure copyWith({
    Object? id = _Undefined,
    String? rceptNo,
    String? corpCode,
    Object? companyId = _Undefined,
    String? corpName,
    String? reportName,
    DateTime? receivedDate,
    Object? filerName = _Undefined,
    DateTime? discoveredAt,
  }) {
    return DartDisclosure(
      id: id is int? ? id : this.id,
      rceptNo: rceptNo ?? this.rceptNo,
      corpCode: corpCode ?? this.corpCode,
      companyId: companyId is int? ? companyId : this.companyId,
      corpName: corpName ?? this.corpName,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate ?? this.receivedDate,
      filerName: filerName is String? ? filerName : this.filerName,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }
}

class DartDisclosureUpdateTable extends _is.UpdateTable<DartDisclosureTable> {
  DartDisclosureUpdateTable(super.table);

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

  _is.ColumnValue<String, String> corpName(String value) => _is.ColumnValue(
    table.corpName,
    value,
  );

  _is.ColumnValue<String, String> reportName(String value) => _is.ColumnValue(
    table.reportName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> receivedDate(DateTime value) =>
      _is.ColumnValue(
        table.receivedDate,
        value,
      );

  _is.ColumnValue<String, String> filerName(String? value) => _is.ColumnValue(
    table.filerName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> discoveredAt(DateTime value) =>
      _is.ColumnValue(
        table.discoveredAt,
        value,
      );
}

class DartDisclosureTable extends _is.Table<int?> {
  DartDisclosureTable({super.tableRelation})
    : super(tableName: 'dart_disclosure') {
    updateTable = DartDisclosureUpdateTable(this);
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
    corpName = _is.ColumnString(
      'corpName',
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
    filerName = _is.ColumnString(
      'filerName',
      this,
    );
    discoveredAt = _is.ColumnDateTime(
      'discoveredAt',
      this,
    );
  }

  late final DartDisclosureUpdateTable updateTable;

  late final _is.ColumnString rceptNo;

  late final _is.ColumnString corpCode;

  late final _is.ColumnInt companyId;

  late final _is.ColumnString corpName;

  late final _is.ColumnString reportName;

  late final _is.ColumnDateTime receivedDate;

  /// 제출인 (회사가 아닌 경우도 있다 — 주주의 대량보유 보고 등)
  late final _is.ColumnString filerName;

  late final _is.ColumnDateTime discoveredAt;

  @override
  List<_is.Column> get columns => [
    id,
    rceptNo,
    corpCode,
    companyId,
    corpName,
    reportName,
    receivedDate,
    filerName,
    discoveredAt,
  ];
}

class DartDisclosureInclude extends _is.IncludeObject {
  DartDisclosureInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DartDisclosure.t;
}

class DartDisclosureIncludeList extends _is.IncludeList {
  DartDisclosureIncludeList._({
    _is.WhereExpressionBuilder<DartDisclosureTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DartDisclosure.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DartDisclosure.t;
}

class DartDisclosureRepository {
  const DartDisclosureRepository._();

  /// Returns a list of [DartDisclosure]s matching the given query parameters.
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
  Future<List<DartDisclosure>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartDisclosureTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartDisclosureTable>? orderBy,
    _is.OrderByListBuilder<DartDisclosureTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DartDisclosure>(
      where: where?.call(DartDisclosure.t),
      orderBy: orderBy?.call(DartDisclosure.t),
      orderByList: orderByList?.call(DartDisclosure.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DartDisclosure] matching the given query parameters.
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
  Future<DartDisclosure?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartDisclosureTable>? where,
    int? offset,
    _is.OrderByBuilder<DartDisclosureTable>? orderBy,
    _is.OrderByListBuilder<DartDisclosureTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DartDisclosure>(
      where: where?.call(DartDisclosure.t),
      orderBy: orderBy?.call(DartDisclosure.t),
      orderByList: orderByList?.call(DartDisclosure.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DartDisclosure] by its [id] or null if no such row exists.
  Future<DartDisclosure?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DartDisclosure>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DartDisclosure]s in the list and returns the inserted rows.
  ///
  /// The returned [DartDisclosure]s will have their `id` fields set.
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
  Future<List<DartDisclosure>> insert(
    _is.DatabaseSession session,
    List<DartDisclosure> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DartDisclosure>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DartDisclosure] and returns the inserted row.
  ///
  /// The returned [DartDisclosure] will have its `id` field set.
  Future<DartDisclosure> insertRow(
    _is.DatabaseSession session,
    DartDisclosure row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DartDisclosure>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DartDisclosure]s in the list and returns the resulting rows.
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
  /// The returned [DartDisclosure]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartDisclosure>> upsert(
    _is.DatabaseSession session,
    List<DartDisclosure> rows, {
    required _is.ColumnSelections<DartDisclosureTable> conflictColumns,
    _is.ColumnSelections<DartDisclosureTable>? updateColumns,
    _is.WhereExpressionBuilder<DartDisclosureTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DartDisclosure>(
      rows,
      conflictColumns: conflictColumns(DartDisclosure.t),
      updateColumns: updateColumns?.call(DartDisclosure.t),
      updateWhere: updateWhere?.call(DartDisclosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DartDisclosure] and returns the resulting row.
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
  /// The returned [DartDisclosure] will have its `id` field set.
  Future<DartDisclosure?> upsertRow(
    _is.DatabaseSession session,
    DartDisclosure row, {
    required _is.ColumnSelections<DartDisclosureTable> conflictColumns,
    _is.ColumnSelections<DartDisclosureTable>? updateColumns,
    _is.WhereExpressionBuilder<DartDisclosureTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DartDisclosure>(
      row,
      conflictColumns: conflictColumns(DartDisclosure.t),
      updateColumns: updateColumns?.call(DartDisclosure.t),
      updateWhere: updateWhere?.call(DartDisclosure.t),
      transaction: transaction,
    );
  }

  /// Updates all [DartDisclosure]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartDisclosure>> update(
    _is.DatabaseSession session,
    List<DartDisclosure> rows, {
    _is.ColumnSelections<DartDisclosureTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DartDisclosure>(
      rows,
      columns: columns?.call(DartDisclosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DartDisclosure]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DartDisclosure> updateRow(
    _is.DatabaseSession session,
    DartDisclosure row, {
    _is.ColumnSelections<DartDisclosureTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DartDisclosure>(
      row,
      columns: columns?.call(DartDisclosure.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DartDisclosure] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DartDisclosure?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DartDisclosureUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DartDisclosure>(
      id,
      columnValues: columnValues(DartDisclosure.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DartDisclosure]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartDisclosure>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DartDisclosureUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DartDisclosureTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartDisclosureTable>? orderBy,
    _is.OrderByListBuilder<DartDisclosureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DartDisclosure>(
      columnValues: columnValues(DartDisclosure.t.updateTable),
      where: where(DartDisclosure.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartDisclosure.t),
      orderByList: orderByList?.call(DartDisclosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DartDisclosure]s in the list and returns the deleted rows.
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
  Future<List<DartDisclosure>> delete(
    _is.DatabaseSession session,
    List<DartDisclosure> rows, {
    _is.OrderByBuilder<DartDisclosureTable>? orderBy,
    _is.OrderByListBuilder<DartDisclosureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DartDisclosure>(
      rows,
      orderBy: orderBy?.call(DartDisclosure.t),
      orderByList: orderByList?.call(DartDisclosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DartDisclosure].
  Future<DartDisclosure> deleteRow(
    _is.DatabaseSession session,
    DartDisclosure row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DartDisclosure>(
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
  Future<List<DartDisclosure>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartDisclosureTable> where,
    _is.OrderByBuilder<DartDisclosureTable>? orderBy,
    _is.OrderByListBuilder<DartDisclosureTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DartDisclosure>(
      where: where(DartDisclosure.t),
      orderBy: orderBy?.call(DartDisclosure.t),
      orderByList: orderByList?.call(DartDisclosure.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartDisclosureTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DartDisclosure>(
      where: where?.call(DartDisclosure.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DartDisclosure] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartDisclosureTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DartDisclosure>(
      where: where(DartDisclosure.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
