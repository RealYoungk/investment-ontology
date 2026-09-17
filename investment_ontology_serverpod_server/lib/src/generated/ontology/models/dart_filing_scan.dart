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

/// 수집 장부: 전체 공시 목록(list.json)을 어느 접수일까지 훑었는지. 한 행만 둔다.
/// 기업 하나만 받는 수집은 이 커서를 움직이지 않는다.
abstract class DartFilingScan
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DartFilingScan._({
    this.id,
    required this.scannedThrough,
    required this.updatedAt,
  });

  factory DartFilingScan({
    int? id,
    required DateTime scannedThrough,
    required DateTime updatedAt,
  }) = _DartFilingScanImpl;

  factory DartFilingScan.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartFilingScan(
      id: jsonSerialization['id'] as int?,
      scannedThrough: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['scannedThrough'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = DartFilingScanTable();

  static const db = DartFilingScanRepository._();

  @override
  int? id;

  /// 이 날짜(UTC 자정)까지의 구간을 끝까지 훑었다
  DateTime scannedThrough;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DartFilingScan]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DartFilingScan copyWith({
    int? id,
    DateTime? scannedThrough,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartFilingScan',
      if (id != null) 'id': id,
      'scannedThrough': scannedThrough.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartFilingScan',
      if (id != null) 'id': id,
      'scannedThrough': scannedThrough.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static DartFilingScanInclude include() {
    return DartFilingScanInclude._();
  }

  static DartFilingScanIncludeList includeList({
    _is.WhereExpressionBuilder<DartFilingScanTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingScanTable>? orderBy,
    _is.OrderByListBuilder<DartFilingScanTable>? orderByList,
    DartFilingScanInclude? include,
  }) {
    return DartFilingScanIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartFilingScan.t),
      orderByList: orderByList?.call(DartFilingScan.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartFilingScanImpl extends DartFilingScan {
  _DartFilingScanImpl({
    int? id,
    required DateTime scannedThrough,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         scannedThrough: scannedThrough,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [DartFilingScan]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DartFilingScan copyWith({
    Object? id = _Undefined,
    DateTime? scannedThrough,
    DateTime? updatedAt,
  }) {
    return DartFilingScan(
      id: id is int? ? id : this.id,
      scannedThrough: scannedThrough ?? this.scannedThrough,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DartFilingScanUpdateTable extends _is.UpdateTable<DartFilingScanTable> {
  DartFilingScanUpdateTable(super.table);

  _is.ColumnValue<DateTime, DateTime> scannedThrough(DateTime value) =>
      _is.ColumnValue(
        table.scannedThrough,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class DartFilingScanTable extends _is.Table<int?> {
  DartFilingScanTable({super.tableRelation})
    : super(tableName: 'dart_filing_scan') {
    updateTable = DartFilingScanUpdateTable(this);
    scannedThrough = _is.ColumnDateTime(
      'scannedThrough',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final DartFilingScanUpdateTable updateTable;

  /// 이 날짜(UTC 자정)까지의 구간을 끝까지 훑었다
  late final _is.ColumnDateTime scannedThrough;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    scannedThrough,
    updatedAt,
  ];
}

class DartFilingScanInclude extends _is.IncludeObject {
  DartFilingScanInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DartFilingScan.t;
}

class DartFilingScanIncludeList extends _is.IncludeList {
  DartFilingScanIncludeList._({
    _is.WhereExpressionBuilder<DartFilingScanTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DartFilingScan.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DartFilingScan.t;
}

class DartFilingScanRepository {
  const DartFilingScanRepository._();

  /// Returns a list of [DartFilingScan]s matching the given query parameters.
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
  Future<List<DartFilingScan>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingScanTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingScanTable>? orderBy,
    _is.OrderByListBuilder<DartFilingScanTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DartFilingScan>(
      where: where?.call(DartFilingScan.t),
      orderBy: orderBy?.call(DartFilingScan.t),
      orderByList: orderByList?.call(DartFilingScan.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DartFilingScan] matching the given query parameters.
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
  Future<DartFilingScan?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingScanTable>? where,
    int? offset,
    _is.OrderByBuilder<DartFilingScanTable>? orderBy,
    _is.OrderByListBuilder<DartFilingScanTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DartFilingScan>(
      where: where?.call(DartFilingScan.t),
      orderBy: orderBy?.call(DartFilingScan.t),
      orderByList: orderByList?.call(DartFilingScan.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DartFilingScan] by its [id] or null if no such row exists.
  Future<DartFilingScan?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DartFilingScan>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DartFilingScan]s in the list and returns the inserted rows.
  ///
  /// The returned [DartFilingScan]s will have their `id` fields set.
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
  Future<List<DartFilingScan>> insert(
    _is.DatabaseSession session,
    List<DartFilingScan> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DartFilingScan>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DartFilingScan] and returns the inserted row.
  ///
  /// The returned [DartFilingScan] will have its `id` field set.
  Future<DartFilingScan> insertRow(
    _is.DatabaseSession session,
    DartFilingScan row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DartFilingScan>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DartFilingScan]s in the list and returns the resulting rows.
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
  /// The returned [DartFilingScan]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFilingScan>> upsert(
    _is.DatabaseSession session,
    List<DartFilingScan> rows, {
    required _is.ColumnSelections<DartFilingScanTable> conflictColumns,
    _is.ColumnSelections<DartFilingScanTable>? updateColumns,
    _is.WhereExpressionBuilder<DartFilingScanTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DartFilingScan>(
      rows,
      conflictColumns: conflictColumns(DartFilingScan.t),
      updateColumns: updateColumns?.call(DartFilingScan.t),
      updateWhere: updateWhere?.call(DartFilingScan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DartFilingScan] and returns the resulting row.
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
  /// The returned [DartFilingScan] will have its `id` field set.
  Future<DartFilingScan?> upsertRow(
    _is.DatabaseSession session,
    DartFilingScan row, {
    required _is.ColumnSelections<DartFilingScanTable> conflictColumns,
    _is.ColumnSelections<DartFilingScanTable>? updateColumns,
    _is.WhereExpressionBuilder<DartFilingScanTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DartFilingScan>(
      row,
      conflictColumns: conflictColumns(DartFilingScan.t),
      updateColumns: updateColumns?.call(DartFilingScan.t),
      updateWhere: updateWhere?.call(DartFilingScan.t),
      transaction: transaction,
    );
  }

  /// Updates all [DartFilingScan]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFilingScan>> update(
    _is.DatabaseSession session,
    List<DartFilingScan> rows, {
    _is.ColumnSelections<DartFilingScanTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DartFilingScan>(
      rows,
      columns: columns?.call(DartFilingScan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DartFilingScan]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DartFilingScan> updateRow(
    _is.DatabaseSession session,
    DartFilingScan row, {
    _is.ColumnSelections<DartFilingScanTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DartFilingScan>(
      row,
      columns: columns?.call(DartFilingScan.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DartFilingScan] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DartFilingScan?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DartFilingScanUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DartFilingScan>(
      id,
      columnValues: columnValues(DartFilingScan.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DartFilingScan]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFilingScan>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DartFilingScanUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DartFilingScanTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingScanTable>? orderBy,
    _is.OrderByListBuilder<DartFilingScanTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DartFilingScan>(
      columnValues: columnValues(DartFilingScan.t.updateTable),
      where: where(DartFilingScan.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartFilingScan.t),
      orderByList: orderByList?.call(DartFilingScan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DartFilingScan]s in the list and returns the deleted rows.
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
  Future<List<DartFilingScan>> delete(
    _is.DatabaseSession session,
    List<DartFilingScan> rows, {
    _is.OrderByBuilder<DartFilingScanTable>? orderBy,
    _is.OrderByListBuilder<DartFilingScanTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DartFilingScan>(
      rows,
      orderBy: orderBy?.call(DartFilingScan.t),
      orderByList: orderByList?.call(DartFilingScan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DartFilingScan].
  Future<DartFilingScan> deleteRow(
    _is.DatabaseSession session,
    DartFilingScan row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DartFilingScan>(
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
  Future<List<DartFilingScan>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartFilingScanTable> where,
    _is.OrderByBuilder<DartFilingScanTable>? orderBy,
    _is.OrderByListBuilder<DartFilingScanTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DartFilingScan>(
      where: where(DartFilingScan.t),
      orderBy: orderBy?.call(DartFilingScan.t),
      orderByList: orderByList?.call(DartFilingScan.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingScanTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DartFilingScan>(
      where: where?.call(DartFilingScan.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DartFilingScan] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartFilingScanTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DartFilingScan>(
      where: where(DartFilingScan.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
