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

abstract class WatchlistScanState
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WatchlistScanState._({
    this.id,
    required this.key,
    this.lastSuccessAt,
    this.scanDay,
    int? nextPage,
    this.leaseUntil,
    String? status,
  }) : nextPage = nextPage ?? 1,
       status = status ?? 'waiting';

  factory WatchlistScanState({
    int? id,
    required String key,
    DateTime? lastSuccessAt,
    DateTime? scanDay,
    int? nextPage,
    DateTime? leaseUntil,
    String? status,
  }) = _WatchlistScanStateImpl;

  factory WatchlistScanState.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchlistScanState(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
      lastSuccessAt: jsonSerialization['lastSuccessAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSuccessAt'],
            ),
      scanDay: jsonSerialization['scanDay'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['scanDay']),
      nextPage: jsonSerialization['nextPage'] as int?,
      leaseUntil: jsonSerialization['leaseUntil'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['leaseUntil']),
      status: jsonSerialization['status'] as String?,
    );
  }

  static final t = WatchlistScanStateTable();

  static const db = WatchlistScanStateRepository._();

  @override
  int? id;

  String key;

  DateTime? lastSuccessAt;

  DateTime? scanDay;

  int nextPage;

  DateTime? leaseUntil;

  String status;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WatchlistScanState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WatchlistScanState copyWith({
    int? id,
    String? key,
    DateTime? lastSuccessAt,
    DateTime? scanDay,
    int? nextPage,
    DateTime? leaseUntil,
    String? status,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchlistScanState',
      if (id != null) 'id': id,
      'key': key,
      if (lastSuccessAt != null) 'lastSuccessAt': lastSuccessAt?.toJson(),
      if (scanDay != null) 'scanDay': scanDay?.toJson(),
      'nextPage': nextPage,
      if (leaseUntil != null) 'leaseUntil': leaseUntil?.toJson(),
      'status': status,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WatchlistScanStateInclude include() {
    return WatchlistScanStateInclude._();
  }

  static WatchlistScanStateIncludeList includeList({
    _is.WhereExpressionBuilder<WatchlistScanStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistScanStateTable>? orderBy,
    _is.OrderByListBuilder<WatchlistScanStateTable>? orderByList,
    WatchlistScanStateInclude? include,
  }) {
    return WatchlistScanStateIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchlistScanState.t),
      orderByList: orderByList?.call(WatchlistScanState.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchlistScanStateImpl extends WatchlistScanState {
  _WatchlistScanStateImpl({
    int? id,
    required String key,
    DateTime? lastSuccessAt,
    DateTime? scanDay,
    int? nextPage,
    DateTime? leaseUntil,
    String? status,
  }) : super._(
         id: id,
         key: key,
         lastSuccessAt: lastSuccessAt,
         scanDay: scanDay,
         nextPage: nextPage,
         leaseUntil: leaseUntil,
         status: status,
       );

  /// Returns a shallow copy of this [WatchlistScanState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WatchlistScanState copyWith({
    Object? id = _Undefined,
    String? key,
    Object? lastSuccessAt = _Undefined,
    Object? scanDay = _Undefined,
    int? nextPage,
    Object? leaseUntil = _Undefined,
    String? status,
  }) {
    return WatchlistScanState(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
      lastSuccessAt: lastSuccessAt is DateTime?
          ? lastSuccessAt
          : this.lastSuccessAt,
      scanDay: scanDay is DateTime? ? scanDay : this.scanDay,
      nextPage: nextPage ?? this.nextPage,
      leaseUntil: leaseUntil is DateTime? ? leaseUntil : this.leaseUntil,
      status: status ?? this.status,
    );
  }
}

class WatchlistScanStateUpdateTable
    extends _is.UpdateTable<WatchlistScanStateTable> {
  WatchlistScanStateUpdateTable(super.table);

  _is.ColumnValue<String, String> key(String value) => _is.ColumnValue(
    table.key,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> lastSuccessAt(DateTime? value) =>
      _is.ColumnValue(
        table.lastSuccessAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> scanDay(DateTime? value) =>
      _is.ColumnValue(
        table.scanDay,
        value,
      );

  _is.ColumnValue<int, int> nextPage(int value) => _is.ColumnValue(
    table.nextPage,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> leaseUntil(DateTime? value) =>
      _is.ColumnValue(
        table.leaseUntil,
        value,
      );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );
}

class WatchlistScanStateTable extends _is.Table<int?> {
  WatchlistScanStateTable({super.tableRelation})
    : super(tableName: 'watchlist_scan_state') {
    updateTable = WatchlistScanStateUpdateTable(this);
    key = _is.ColumnString(
      'key',
      this,
    );
    lastSuccessAt = _is.ColumnDateTime(
      'lastSuccessAt',
      this,
    );
    scanDay = _is.ColumnDateTime(
      'scanDay',
      this,
    );
    nextPage = _is.ColumnInt(
      'nextPage',
      this,
      hasDefault: true,
    );
    leaseUntil = _is.ColumnDateTime(
      'leaseUntil',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
      hasDefault: true,
    );
  }

  late final WatchlistScanStateUpdateTable updateTable;

  late final _is.ColumnString key;

  late final _is.ColumnDateTime lastSuccessAt;

  late final _is.ColumnDateTime scanDay;

  late final _is.ColumnInt nextPage;

  late final _is.ColumnDateTime leaseUntil;

  late final _is.ColumnString status;

  @override
  List<_is.Column> get columns => [
    id,
    key,
    lastSuccessAt,
    scanDay,
    nextPage,
    leaseUntil,
    status,
  ];
}

class WatchlistScanStateInclude extends _is.IncludeObject {
  WatchlistScanStateInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WatchlistScanState.t;
}

class WatchlistScanStateIncludeList extends _is.IncludeList {
  WatchlistScanStateIncludeList._({
    _is.WhereExpressionBuilder<WatchlistScanStateTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WatchlistScanState.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WatchlistScanState.t;
}

class WatchlistScanStateRepository {
  const WatchlistScanStateRepository._();

  /// Returns a list of [WatchlistScanState]s matching the given query parameters.
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
  Future<List<WatchlistScanState>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistScanStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistScanStateTable>? orderBy,
    _is.OrderByListBuilder<WatchlistScanStateTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WatchlistScanState>(
      where: where?.call(WatchlistScanState.t),
      orderBy: orderBy?.call(WatchlistScanState.t),
      orderByList: orderByList?.call(WatchlistScanState.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WatchlistScanState] matching the given query parameters.
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
  Future<WatchlistScanState?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistScanStateTable>? where,
    int? offset,
    _is.OrderByBuilder<WatchlistScanStateTable>? orderBy,
    _is.OrderByListBuilder<WatchlistScanStateTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WatchlistScanState>(
      where: where?.call(WatchlistScanState.t),
      orderBy: orderBy?.call(WatchlistScanState.t),
      orderByList: orderByList?.call(WatchlistScanState.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WatchlistScanState] by its [id] or null if no such row exists.
  Future<WatchlistScanState?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WatchlistScanState>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WatchlistScanState]s in the list and returns the inserted rows.
  ///
  /// The returned [WatchlistScanState]s will have their `id` fields set.
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
  Future<List<WatchlistScanState>> insert(
    _is.DatabaseSession session,
    List<WatchlistScanState> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WatchlistScanState>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WatchlistScanState] and returns the inserted row.
  ///
  /// The returned [WatchlistScanState] will have its `id` field set.
  Future<WatchlistScanState> insertRow(
    _is.DatabaseSession session,
    WatchlistScanState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WatchlistScanState>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WatchlistScanState]s in the list and returns the resulting rows.
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
  /// The returned [WatchlistScanState]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistScanState>> upsert(
    _is.DatabaseSession session,
    List<WatchlistScanState> rows, {
    required _is.ColumnSelections<WatchlistScanStateTable> conflictColumns,
    _is.ColumnSelections<WatchlistScanStateTable>? updateColumns,
    _is.WhereExpressionBuilder<WatchlistScanStateTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WatchlistScanState>(
      rows,
      conflictColumns: conflictColumns(WatchlistScanState.t),
      updateColumns: updateColumns?.call(WatchlistScanState.t),
      updateWhere: updateWhere?.call(WatchlistScanState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WatchlistScanState] and returns the resulting row.
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
  /// The returned [WatchlistScanState] will have its `id` field set.
  Future<WatchlistScanState?> upsertRow(
    _is.DatabaseSession session,
    WatchlistScanState row, {
    required _is.ColumnSelections<WatchlistScanStateTable> conflictColumns,
    _is.ColumnSelections<WatchlistScanStateTable>? updateColumns,
    _is.WhereExpressionBuilder<WatchlistScanStateTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WatchlistScanState>(
      row,
      conflictColumns: conflictColumns(WatchlistScanState.t),
      updateColumns: updateColumns?.call(WatchlistScanState.t),
      updateWhere: updateWhere?.call(WatchlistScanState.t),
      transaction: transaction,
    );
  }

  /// Updates all [WatchlistScanState]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistScanState>> update(
    _is.DatabaseSession session,
    List<WatchlistScanState> rows, {
    _is.ColumnSelections<WatchlistScanStateTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WatchlistScanState>(
      rows,
      columns: columns?.call(WatchlistScanState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WatchlistScanState]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WatchlistScanState> updateRow(
    _is.DatabaseSession session,
    WatchlistScanState row, {
    _is.ColumnSelections<WatchlistScanStateTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WatchlistScanState>(
      row,
      columns: columns?.call(WatchlistScanState.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WatchlistScanState] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WatchlistScanState?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WatchlistScanStateUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WatchlistScanState>(
      id,
      columnValues: columnValues(WatchlistScanState.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WatchlistScanState]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistScanState>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WatchlistScanStateUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WatchlistScanStateTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistScanStateTable>? orderBy,
    _is.OrderByListBuilder<WatchlistScanStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WatchlistScanState>(
      columnValues: columnValues(WatchlistScanState.t.updateTable),
      where: where(WatchlistScanState.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchlistScanState.t),
      orderByList: orderByList?.call(WatchlistScanState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WatchlistScanState]s in the list and returns the deleted rows.
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
  Future<List<WatchlistScanState>> delete(
    _is.DatabaseSession session,
    List<WatchlistScanState> rows, {
    _is.OrderByBuilder<WatchlistScanStateTable>? orderBy,
    _is.OrderByListBuilder<WatchlistScanStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WatchlistScanState>(
      rows,
      orderBy: orderBy?.call(WatchlistScanState.t),
      orderByList: orderByList?.call(WatchlistScanState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WatchlistScanState].
  Future<WatchlistScanState> deleteRow(
    _is.DatabaseSession session,
    WatchlistScanState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WatchlistScanState>(
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
  Future<List<WatchlistScanState>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WatchlistScanStateTable> where,
    _is.OrderByBuilder<WatchlistScanStateTable>? orderBy,
    _is.OrderByListBuilder<WatchlistScanStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WatchlistScanState>(
      where: where(WatchlistScanState.t),
      orderBy: orderBy?.call(WatchlistScanState.t),
      orderByList: orderByList?.call(WatchlistScanState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistScanStateTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WatchlistScanState>(
      where: where?.call(WatchlistScanState.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WatchlistScanState] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WatchlistScanStateTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WatchlistScanState>(
      where: where(WatchlistScanState.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
