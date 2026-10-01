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

abstract class WatchlistNotice
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WatchlistNotice._({
    this.id,
    required this.ownerId,
    required this.eventId,
    required this.corpCode,
    DateTime? createdAt,
    this.readAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WatchlistNotice({
    int? id,
    required _is.UuidValue ownerId,
    required int eventId,
    required String corpCode,
    DateTime? createdAt,
    DateTime? readAt,
  }) = _WatchlistNoticeImpl;

  factory WatchlistNotice.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchlistNotice(
      id: jsonSerialization['id'] as int?,
      ownerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      eventId: jsonSerialization['eventId'] as int,
      corpCode: jsonSerialization['corpCode'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      readAt: jsonSerialization['readAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['readAt']),
    );
  }

  static final t = WatchlistNoticeTable();

  static const db = WatchlistNoticeRepository._();

  @override
  int? id;

  _is.UuidValue ownerId;

  int eventId;

  String corpCode;

  DateTime createdAt;

  DateTime? readAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WatchlistNotice]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WatchlistNotice copyWith({
    int? id,
    _is.UuidValue? ownerId,
    int? eventId,
    String? corpCode,
    DateTime? createdAt,
    DateTime? readAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchlistNotice',
      if (id != null) 'id': id,
      'ownerId': ownerId.toJson(),
      'eventId': eventId,
      'corpCode': corpCode,
      'createdAt': createdAt.toJson(),
      if (readAt != null) 'readAt': readAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WatchlistNoticeInclude include() {
    return WatchlistNoticeInclude._();
  }

  static WatchlistNoticeIncludeList includeList({
    _is.WhereExpressionBuilder<WatchlistNoticeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistNoticeTable>? orderBy,
    _is.OrderByListBuilder<WatchlistNoticeTable>? orderByList,
    WatchlistNoticeInclude? include,
  }) {
    return WatchlistNoticeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchlistNotice.t),
      orderByList: orderByList?.call(WatchlistNotice.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchlistNoticeImpl extends WatchlistNotice {
  _WatchlistNoticeImpl({
    int? id,
    required _is.UuidValue ownerId,
    required int eventId,
    required String corpCode,
    DateTime? createdAt,
    DateTime? readAt,
  }) : super._(
         id: id,
         ownerId: ownerId,
         eventId: eventId,
         corpCode: corpCode,
         createdAt: createdAt,
         readAt: readAt,
       );

  /// Returns a shallow copy of this [WatchlistNotice]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WatchlistNotice copyWith({
    Object? id = _Undefined,
    _is.UuidValue? ownerId,
    int? eventId,
    String? corpCode,
    DateTime? createdAt,
    Object? readAt = _Undefined,
  }) {
    return WatchlistNotice(
      id: id is int? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      eventId: eventId ?? this.eventId,
      corpCode: corpCode ?? this.corpCode,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt is DateTime? ? readAt : this.readAt,
    );
  }
}

class WatchlistNoticeUpdateTable extends _is.UpdateTable<WatchlistNoticeTable> {
  WatchlistNoticeUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> ownerId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.ownerId,
        value,
      );

  _is.ColumnValue<int, int> eventId(int value) => _is.ColumnValue(
    table.eventId,
    value,
  );

  _is.ColumnValue<String, String> corpCode(String value) => _is.ColumnValue(
    table.corpCode,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> readAt(DateTime? value) =>
      _is.ColumnValue(
        table.readAt,
        value,
      );
}

class WatchlistNoticeTable extends _is.Table<int?> {
  WatchlistNoticeTable({super.tableRelation})
    : super(tableName: 'watchlist_notice') {
    updateTable = WatchlistNoticeUpdateTable(this);
    ownerId = _is.ColumnUuid(
      'ownerId',
      this,
    );
    eventId = _is.ColumnInt(
      'eventId',
      this,
    );
    corpCode = _is.ColumnString(
      'corpCode',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    readAt = _is.ColumnDateTime(
      'readAt',
      this,
    );
  }

  late final WatchlistNoticeUpdateTable updateTable;

  late final _is.ColumnUuid ownerId;

  late final _is.ColumnInt eventId;

  late final _is.ColumnString corpCode;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime readAt;

  @override
  List<_is.Column> get columns => [
    id,
    ownerId,
    eventId,
    corpCode,
    createdAt,
    readAt,
  ];
}

class WatchlistNoticeInclude extends _is.IncludeObject {
  WatchlistNoticeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WatchlistNotice.t;
}

class WatchlistNoticeIncludeList extends _is.IncludeList {
  WatchlistNoticeIncludeList._({
    _is.WhereExpressionBuilder<WatchlistNoticeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WatchlistNotice.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WatchlistNotice.t;
}

class WatchlistNoticeRepository {
  const WatchlistNoticeRepository._();

  /// Returns a list of [WatchlistNotice]s matching the given query parameters.
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
  Future<List<WatchlistNotice>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistNoticeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistNoticeTable>? orderBy,
    _is.OrderByListBuilder<WatchlistNoticeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WatchlistNotice>(
      where: where?.call(WatchlistNotice.t),
      orderBy: orderBy?.call(WatchlistNotice.t),
      orderByList: orderByList?.call(WatchlistNotice.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WatchlistNotice] matching the given query parameters.
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
  Future<WatchlistNotice?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistNoticeTable>? where,
    int? offset,
    _is.OrderByBuilder<WatchlistNoticeTable>? orderBy,
    _is.OrderByListBuilder<WatchlistNoticeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WatchlistNotice>(
      where: where?.call(WatchlistNotice.t),
      orderBy: orderBy?.call(WatchlistNotice.t),
      orderByList: orderByList?.call(WatchlistNotice.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WatchlistNotice] by its [id] or null if no such row exists.
  Future<WatchlistNotice?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WatchlistNotice>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WatchlistNotice]s in the list and returns the inserted rows.
  ///
  /// The returned [WatchlistNotice]s will have their `id` fields set.
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
  Future<List<WatchlistNotice>> insert(
    _is.DatabaseSession session,
    List<WatchlistNotice> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WatchlistNotice>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WatchlistNotice] and returns the inserted row.
  ///
  /// The returned [WatchlistNotice] will have its `id` field set.
  Future<WatchlistNotice> insertRow(
    _is.DatabaseSession session,
    WatchlistNotice row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WatchlistNotice>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WatchlistNotice]s in the list and returns the resulting rows.
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
  /// The returned [WatchlistNotice]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistNotice>> upsert(
    _is.DatabaseSession session,
    List<WatchlistNotice> rows, {
    required _is.ColumnSelections<WatchlistNoticeTable> conflictColumns,
    _is.ColumnSelections<WatchlistNoticeTable>? updateColumns,
    _is.WhereExpressionBuilder<WatchlistNoticeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WatchlistNotice>(
      rows,
      conflictColumns: conflictColumns(WatchlistNotice.t),
      updateColumns: updateColumns?.call(WatchlistNotice.t),
      updateWhere: updateWhere?.call(WatchlistNotice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WatchlistNotice] and returns the resulting row.
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
  /// The returned [WatchlistNotice] will have its `id` field set.
  Future<WatchlistNotice?> upsertRow(
    _is.DatabaseSession session,
    WatchlistNotice row, {
    required _is.ColumnSelections<WatchlistNoticeTable> conflictColumns,
    _is.ColumnSelections<WatchlistNoticeTable>? updateColumns,
    _is.WhereExpressionBuilder<WatchlistNoticeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WatchlistNotice>(
      row,
      conflictColumns: conflictColumns(WatchlistNotice.t),
      updateColumns: updateColumns?.call(WatchlistNotice.t),
      updateWhere: updateWhere?.call(WatchlistNotice.t),
      transaction: transaction,
    );
  }

  /// Updates all [WatchlistNotice]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistNotice>> update(
    _is.DatabaseSession session,
    List<WatchlistNotice> rows, {
    _is.ColumnSelections<WatchlistNoticeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WatchlistNotice>(
      rows,
      columns: columns?.call(WatchlistNotice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WatchlistNotice]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WatchlistNotice> updateRow(
    _is.DatabaseSession session,
    WatchlistNotice row, {
    _is.ColumnSelections<WatchlistNoticeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WatchlistNotice>(
      row,
      columns: columns?.call(WatchlistNotice.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WatchlistNotice] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WatchlistNotice?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WatchlistNoticeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WatchlistNotice>(
      id,
      columnValues: columnValues(WatchlistNotice.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WatchlistNotice]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistNotice>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WatchlistNoticeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WatchlistNoticeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistNoticeTable>? orderBy,
    _is.OrderByListBuilder<WatchlistNoticeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WatchlistNotice>(
      columnValues: columnValues(WatchlistNotice.t.updateTable),
      where: where(WatchlistNotice.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchlistNotice.t),
      orderByList: orderByList?.call(WatchlistNotice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WatchlistNotice]s in the list and returns the deleted rows.
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
  Future<List<WatchlistNotice>> delete(
    _is.DatabaseSession session,
    List<WatchlistNotice> rows, {
    _is.OrderByBuilder<WatchlistNoticeTable>? orderBy,
    _is.OrderByListBuilder<WatchlistNoticeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WatchlistNotice>(
      rows,
      orderBy: orderBy?.call(WatchlistNotice.t),
      orderByList: orderByList?.call(WatchlistNotice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WatchlistNotice].
  Future<WatchlistNotice> deleteRow(
    _is.DatabaseSession session,
    WatchlistNotice row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WatchlistNotice>(
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
  Future<List<WatchlistNotice>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WatchlistNoticeTable> where,
    _is.OrderByBuilder<WatchlistNoticeTable>? orderBy,
    _is.OrderByListBuilder<WatchlistNoticeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WatchlistNotice>(
      where: where(WatchlistNotice.t),
      orderBy: orderBy?.call(WatchlistNotice.t),
      orderByList: orderByList?.call(WatchlistNotice.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistNoticeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WatchlistNotice>(
      where: where?.call(WatchlistNotice.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WatchlistNotice] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WatchlistNoticeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WatchlistNotice>(
      where: where(WatchlistNotice.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
