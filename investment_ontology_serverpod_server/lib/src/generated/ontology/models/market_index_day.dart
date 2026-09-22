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

/// 수집 장부: 지수를 받은 기준일. 휴장일(0건)도 기록해 다시 조회하지 않는다.
abstract class MarketIndexDay
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  MarketIndexDay._({
    this.id,
    required this.baseDate,
    required this.rowCount,
    this.sourceId,
    required this.fetchedAt,
  });

  factory MarketIndexDay({
    int? id,
    required DateTime baseDate,
    required int rowCount,
    int? sourceId,
    required DateTime fetchedAt,
  }) = _MarketIndexDayImpl;

  factory MarketIndexDay.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketIndexDay(
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

  static final t = MarketIndexDayTable();

  static const db = MarketIndexDayRepository._();

  @override
  int? id;

  /// 기준일 (UTC 자정)
  DateTime baseDate;

  int rowCount;

  int? sourceId;

  DateTime fetchedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [MarketIndexDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketIndexDay copyWith({
    int? id,
    DateTime? baseDate,
    int? rowCount,
    int? sourceId,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketIndexDay',
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
      '__className__': 'MarketIndexDay',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'rowCount': rowCount,
      if (sourceId != null) 'sourceId': sourceId,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static MarketIndexDayInclude include() {
    return MarketIndexDayInclude._();
  }

  static MarketIndexDayIncludeList includeList({
    _is.WhereExpressionBuilder<MarketIndexDayTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketIndexDayTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexDayTable>? orderByList,
    MarketIndexDayInclude? include,
  }) {
    return MarketIndexDayIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketIndexDay.t),
      orderByList: orderByList?.call(MarketIndexDay.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketIndexDayImpl extends MarketIndexDay {
  _MarketIndexDayImpl({
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

  /// Returns a shallow copy of this [MarketIndexDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketIndexDay copyWith({
    Object? id = _Undefined,
    DateTime? baseDate,
    int? rowCount,
    Object? sourceId = _Undefined,
    DateTime? fetchedAt,
  }) {
    return MarketIndexDay(
      id: id is int? ? id : this.id,
      baseDate: baseDate ?? this.baseDate,
      rowCount: rowCount ?? this.rowCount,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class MarketIndexDayUpdateTable extends _is.UpdateTable<MarketIndexDayTable> {
  MarketIndexDayUpdateTable(super.table);

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

class MarketIndexDayTable extends _is.Table<int?> {
  MarketIndexDayTable({super.tableRelation})
    : super(tableName: 'market_index_day') {
    updateTable = MarketIndexDayUpdateTable(this);
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

  late final MarketIndexDayUpdateTable updateTable;

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

class MarketIndexDayInclude extends _is.IncludeObject {
  MarketIndexDayInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => MarketIndexDay.t;
}

class MarketIndexDayIncludeList extends _is.IncludeList {
  MarketIndexDayIncludeList._({
    _is.WhereExpressionBuilder<MarketIndexDayTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MarketIndexDay.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => MarketIndexDay.t;
}

class MarketIndexDayRepository {
  const MarketIndexDayRepository._();

  /// Returns a list of [MarketIndexDay]s matching the given query parameters.
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
  Future<List<MarketIndexDay>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketIndexDayTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketIndexDayTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexDayTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MarketIndexDay>(
      where: where?.call(MarketIndexDay.t),
      orderBy: orderBy?.call(MarketIndexDay.t),
      orderByList: orderByList?.call(MarketIndexDay.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [MarketIndexDay] matching the given query parameters.
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
  Future<MarketIndexDay?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketIndexDayTable>? where,
    int? offset,
    _is.OrderByBuilder<MarketIndexDayTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexDayTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MarketIndexDay>(
      where: where?.call(MarketIndexDay.t),
      orderBy: orderBy?.call(MarketIndexDay.t),
      orderByList: orderByList?.call(MarketIndexDay.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MarketIndexDay] by its [id] or null if no such row exists.
  Future<MarketIndexDay?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MarketIndexDay>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MarketIndexDay]s in the list and returns the inserted rows.
  ///
  /// The returned [MarketIndexDay]s will have their `id` fields set.
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
  Future<List<MarketIndexDay>> insert(
    _is.DatabaseSession session,
    List<MarketIndexDay> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MarketIndexDay>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MarketIndexDay] and returns the inserted row.
  ///
  /// The returned [MarketIndexDay] will have its `id` field set.
  Future<MarketIndexDay> insertRow(
    _is.DatabaseSession session,
    MarketIndexDay row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MarketIndexDay>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MarketIndexDay]s in the list and returns the resulting rows.
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
  /// The returned [MarketIndexDay]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketIndexDay>> upsert(
    _is.DatabaseSession session,
    List<MarketIndexDay> rows, {
    required _is.ColumnSelections<MarketIndexDayTable> conflictColumns,
    _is.ColumnSelections<MarketIndexDayTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketIndexDayTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MarketIndexDay>(
      rows,
      conflictColumns: conflictColumns(MarketIndexDay.t),
      updateColumns: updateColumns?.call(MarketIndexDay.t),
      updateWhere: updateWhere?.call(MarketIndexDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MarketIndexDay] and returns the resulting row.
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
  /// The returned [MarketIndexDay] will have its `id` field set.
  Future<MarketIndexDay?> upsertRow(
    _is.DatabaseSession session,
    MarketIndexDay row, {
    required _is.ColumnSelections<MarketIndexDayTable> conflictColumns,
    _is.ColumnSelections<MarketIndexDayTable>? updateColumns,
    _is.WhereExpressionBuilder<MarketIndexDayTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MarketIndexDay>(
      row,
      conflictColumns: conflictColumns(MarketIndexDay.t),
      updateColumns: updateColumns?.call(MarketIndexDay.t),
      updateWhere: updateWhere?.call(MarketIndexDay.t),
      transaction: transaction,
    );
  }

  /// Updates all [MarketIndexDay]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketIndexDay>> update(
    _is.DatabaseSession session,
    List<MarketIndexDay> rows, {
    _is.ColumnSelections<MarketIndexDayTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MarketIndexDay>(
      rows,
      columns: columns?.call(MarketIndexDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MarketIndexDay]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MarketIndexDay> updateRow(
    _is.DatabaseSession session,
    MarketIndexDay row, {
    _is.ColumnSelections<MarketIndexDayTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MarketIndexDay>(
      row,
      columns: columns?.call(MarketIndexDay.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MarketIndexDay] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MarketIndexDay?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<MarketIndexDayUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MarketIndexDay>(
      id,
      columnValues: columnValues(MarketIndexDay.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MarketIndexDay]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MarketIndexDay>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MarketIndexDayUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MarketIndexDayTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MarketIndexDayTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MarketIndexDay>(
      columnValues: columnValues(MarketIndexDay.t.updateTable),
      where: where(MarketIndexDay.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MarketIndexDay.t),
      orderByList: orderByList?.call(MarketIndexDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MarketIndexDay]s in the list and returns the deleted rows.
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
  Future<List<MarketIndexDay>> delete(
    _is.DatabaseSession session,
    List<MarketIndexDay> rows, {
    _is.OrderByBuilder<MarketIndexDayTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MarketIndexDay>(
      rows,
      orderBy: orderBy?.call(MarketIndexDay.t),
      orderByList: orderByList?.call(MarketIndexDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MarketIndexDay].
  Future<MarketIndexDay> deleteRow(
    _is.DatabaseSession session,
    MarketIndexDay row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MarketIndexDay>(
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
  Future<List<MarketIndexDay>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketIndexDayTable> where,
    _is.OrderByBuilder<MarketIndexDayTable>? orderBy,
    _is.OrderByListBuilder<MarketIndexDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MarketIndexDay>(
      where: where(MarketIndexDay.t),
      orderBy: orderBy?.call(MarketIndexDay.t),
      orderByList: orderByList?.call(MarketIndexDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MarketIndexDayTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MarketIndexDay>(
      where: where?.call(MarketIndexDay.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MarketIndexDay] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MarketIndexDayTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MarketIndexDay>(
      where: where(MarketIndexDay.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
