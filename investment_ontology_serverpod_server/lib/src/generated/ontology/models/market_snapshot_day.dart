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

/// 수집 장부: 시세를 받은 기준일. 휴장일(0건)도 기록해 다시 조회하지 않는다.
abstract class MarketSnapshotDay
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MarketSnapshotDay._({
    this.id,
    required this.baseDate,
    required this.rowCount,
    this.sourceId,
    required this.fetchedAt,
  });

  factory MarketSnapshotDay({
    int? id,
    required DateTime baseDate,
    required int rowCount,
    int? sourceId,
    required DateTime fetchedAt,
  }) = _MarketSnapshotDayImpl;

  factory MarketSnapshotDay.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketSnapshotDay(
      id: jsonSerialization['id'] as int?,
      baseDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['baseDate'],
      ),
      rowCount: jsonSerialization['rowCount'] as int,
      sourceId: jsonSerialization['sourceId'] as int?,
      fetchedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  static final t = MarketSnapshotDayTable();

  static const db = MarketSnapshotDayRepository._();

  @override
  int? id;

  /// 기준일 (UTC 자정)
  DateTime baseDate;

  int rowCount;

  int? sourceId;

  DateTime fetchedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MarketSnapshotDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketSnapshotDay copyWith({
    int? id,
    DateTime? baseDate,
    int? rowCount,
    int? sourceId,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketSnapshotDay',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'rowCount': rowCount,
      if (sourceId != null) 'sourceId': sourceId,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketSnapshotDay',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'rowCount': rowCount,
      if (sourceId != null) 'sourceId': sourceId,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static MarketSnapshotDayInclude include() {
    return MarketSnapshotDayInclude._();
  }

  static MarketSnapshotDayIncludeList includeList({
    _is.WhereExpressionBuilder<MarketSnapshotDayTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotDayTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotDayTable>? orderByList,
    MarketSnapshotDayInclude? include,
  }) {
    return MarketSnapshotDayIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketSnapshotDay.t),
      orderByList: orderByList?.call(MarketSnapshotDay.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketSnapshotDayImpl extends MarketSnapshotDay {
  _MarketSnapshotDayImpl({
    int? id,
    required DateTime baseDate,
    required int rowCount,
    int? sourceId,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         baseDate: baseDate,
         rowCount: rowCount,
         sourceId: sourceId,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [MarketSnapshotDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketSnapshotDay copyWith({
    Object? id = _Undefined,
    DateTime? baseDate,
    int? rowCount,
    Object? sourceId = _Undefined,
    DateTime? fetchedAt,
  }) {
    return MarketSnapshotDay(
      id: id is int? ? id : this.id,
      baseDate: baseDate ?? this.baseDate,
      rowCount: rowCount ?? this.rowCount,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class MarketSnapshotDayUpdateTable
    extends _is.UpdateTable<MarketSnapshotDayTable> {
  MarketSnapshotDayUpdateTable(super.table);

  _is.ColumnValue<DateTime, DateTime> baseDate(DateTime value) =>
      _is.ColumnValue(
        table.baseDate,
        value,
      );

  _is.ColumnValue<int, int> rowCount(int value) => _is.ColumnValue(
    table.rowCount,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> fetchedAt(DateTime value) =>
      _is.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class MarketSnapshotDayTable extends _is.Table<int?> {
  MarketSnapshotDayTable({super.tableRelation})
    : super(tableName: 'market_snapshot_day') {
    updateTable = MarketSnapshotDayUpdateTable(this);
    baseDate = _is.ColumnDateTime(
      'baseDate',
      this,
    );
    rowCount = _is.ColumnInt(
      'rowCount',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    fetchedAt = _is.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final MarketSnapshotDayUpdateTable updateTable;

  /// 기준일 (UTC 자정)
  late final _is.ColumnDateTime baseDate;

  late final _is.ColumnInt rowCount;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnDateTime fetchedAt;

  @override
  List<_is.Column> get columns => [
    id,
    baseDate,
    rowCount,
    sourceId,
    fetchedAt,
  ];
}

class MarketSnapshotDayInclude extends _is.IncludeObject {
  MarketSnapshotDayInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MarketSnapshotDay.t;
}

class MarketSnapshotDayIncludeList extends _is.IncludeList {
  MarketSnapshotDayIncludeList._({
    _is.WhereExpressionBuilder<MarketSnapshotDayTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MarketSnapshotDay.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MarketSnapshotDay.t;
}

class MarketSnapshotDayRepository {
  const MarketSnapshotDayRepository._();

  /// Returns a list of [MarketSnapshotDay]s matching the given query parameters.
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
  Future<List<MarketSnapshotDay>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketSnapshotDayTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotDayTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotDayTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MarketSnapshotDay>(
      where: where?.call(MarketSnapshotDay.t),
      orderBy: orderBy?.call(MarketSnapshotDay.t),
      orderByList: orderByList?.call(MarketSnapshotDay.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MarketSnapshotDay] matching the given query parameters.
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
  Future<MarketSnapshotDay?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketSnapshotDayTable>? where,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotDayTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotDayTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MarketSnapshotDay>(
      where: where?.call(MarketSnapshotDay.t),
      orderBy: orderBy?.call(MarketSnapshotDay.t),
      orderByList: orderByList?.call(MarketSnapshotDay.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MarketSnapshotDay] by its [id] or null if no such row exists.
  Future<MarketSnapshotDay?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MarketSnapshotDay>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MarketSnapshotDay]s in the list and returns the inserted rows.
  ///
  /// The returned [MarketSnapshotDay]s will have their `id` fields set.
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
  Future<List<MarketSnapshotDay>> insert(
    _is.DatabaseSession session,
    List<MarketSnapshotDay> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MarketSnapshotDay>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MarketSnapshotDay] and returns the inserted row.
  ///
  /// The returned [MarketSnapshotDay] will have its `id` field set.
  Future<MarketSnapshotDay> insertRow(
    _is.DatabaseSession session,
    MarketSnapshotDay row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MarketSnapshotDay>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MarketSnapshotDay]s in the list and returns the resulting rows.
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
  /// The returned [MarketSnapshotDay]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketSnapshotDay>> upsert(
    _is.DatabaseSession session,
    List<MarketSnapshotDay> rows, {
    required _is.ColumnSelections<MarketSnapshotDayTable> conflictColumns,
    _is.ColumnSelections<MarketSnapshotDayTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketSnapshotDayTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MarketSnapshotDay>(
      rows,
      conflictColumns: conflictColumns(MarketSnapshotDay.t),
      updateColumns: updateColumns?.call(MarketSnapshotDay.t),
      updateWhere: updateWhere?.call(MarketSnapshotDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MarketSnapshotDay] and returns the resulting row.
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
  /// The returned [MarketSnapshotDay] will have its `id` field set.
  Future<MarketSnapshotDay?> upsertRow(
    _is.DatabaseSession session,
    MarketSnapshotDay row, {
    required _is.ColumnSelections<MarketSnapshotDayTable> conflictColumns,
    _is.ColumnSelections<MarketSnapshotDayTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketSnapshotDayTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MarketSnapshotDay>(
      row,
      conflictColumns: conflictColumns(MarketSnapshotDay.t),
      updateColumns: updateColumns?.call(MarketSnapshotDay.t),
      updateWhere: updateWhere?.call(MarketSnapshotDay.t),
      transaction: transaction,
    );
  }

  /// Updates all [MarketSnapshotDay]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketSnapshotDay>> update(
    _is.DatabaseSession session,
    List<MarketSnapshotDay> rows, {
    _is.ColumnSelections<MarketSnapshotDayTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MarketSnapshotDay>(
      rows,
      columns: columns?.call(MarketSnapshotDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MarketSnapshotDay]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MarketSnapshotDay> updateRow(
    _is.DatabaseSession session,
    MarketSnapshotDay row, {
    _is.ColumnSelections<MarketSnapshotDayTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MarketSnapshotDay>(
      row,
      columns: columns?.call(MarketSnapshotDay.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MarketSnapshotDay] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MarketSnapshotDay?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MarketSnapshotDayUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MarketSnapshotDay>(
      id,
      columnValues: columnValues(MarketSnapshotDay.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MarketSnapshotDay]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketSnapshotDay>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MarketSnapshotDayUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<MarketSnapshotDayTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketSnapshotDayTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MarketSnapshotDay>(
      columnValues: columnValues(MarketSnapshotDay.t.updateTable),
      where: where(MarketSnapshotDay.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketSnapshotDay.t),
      orderByList: orderByList?.call(MarketSnapshotDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MarketSnapshotDay]s in the list and returns the deleted rows.
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
  Future<List<MarketSnapshotDay>> delete(
    _is.DatabaseSession session,
    List<MarketSnapshotDay> rows, {
    _is.OrderByBuilder<MarketSnapshotDayTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MarketSnapshotDay>(
      rows,
      orderBy: orderBy?.call(MarketSnapshotDay.t),
      orderByList: orderByList?.call(MarketSnapshotDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MarketSnapshotDay].
  Future<MarketSnapshotDay> deleteRow(
    _is.DatabaseSession session,
    MarketSnapshotDay row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MarketSnapshotDay>(
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
  Future<List<MarketSnapshotDay>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketSnapshotDayTable> where,
    _is.OrderByBuilder<MarketSnapshotDayTable>? orderBy,
    _is.OrderByListBuilder<MarketSnapshotDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MarketSnapshotDay>(
      where: where(MarketSnapshotDay.t),
      orderBy: orderBy?.call(MarketSnapshotDay.t),
      orderByList: orderByList?.call(MarketSnapshotDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketSnapshotDayTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MarketSnapshotDay>(
      where: where?.call(MarketSnapshotDay.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MarketSnapshotDay] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketSnapshotDayTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MarketSnapshotDay>(
      where: where(MarketSnapshotDay.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
