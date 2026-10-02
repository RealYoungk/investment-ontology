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

abstract class WatchlistEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WatchlistEntry._({
    this.id,
    required this.ownerId,
    required this.corpCode,
    DateTime? createdAt,
    this.baselineAt,
    bool? muted,
    int? position,
  }) : createdAt = createdAt ?? DateTime.now(),
       muted = muted ?? false,
       position = position ?? 0;

  factory WatchlistEntry({
    int? id,
    required _is.UuidValue ownerId,
    required String corpCode,
    DateTime? createdAt,
    DateTime? baselineAt,
    bool? muted,
    int? position,
  }) = _WatchlistEntryImpl;

  factory WatchlistEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchlistEntry(
      id: jsonSerialization['id'] as int?,
      ownerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      corpCode: jsonSerialization['corpCode'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      baselineAt: jsonSerialization['baselineAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['baselineAt']),
      muted: jsonSerialization['muted'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['muted']),
      position: jsonSerialization['position'] as int?,
    );
  }

  static final t = WatchlistEntryTable();

  static const db = WatchlistEntryRepository._();

  @override
  int? id;

  _is.UuidValue ownerId;

  String corpCode;

  DateTime createdAt;

  DateTime? baselineAt;

  bool muted;

  int position;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WatchlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WatchlistEntry copyWith({
    int? id,
    _is.UuidValue? ownerId,
    String? corpCode,
    DateTime? createdAt,
    DateTime? baselineAt,
    bool? muted,
    int? position,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchlistEntry',
      if (id != null) 'id': id,
      'ownerId': ownerId.toJson(),
      'corpCode': corpCode,
      'createdAt': createdAt.toJson(),
      if (baselineAt != null) 'baselineAt': baselineAt?.toJson(),
      'muted': muted,
      'position': position,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WatchlistEntryInclude include() {
    return WatchlistEntryInclude._();
  }

  static WatchlistEntryIncludeList includeList({
    _is.WhereExpressionBuilder<WatchlistEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WatchlistEntryTable>? orderByList,
    WatchlistEntryInclude? include,
  }) {
    return WatchlistEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchlistEntry.t),
      orderByList: orderByList?.call(WatchlistEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchlistEntryImpl extends WatchlistEntry {
  _WatchlistEntryImpl({
    int? id,
    required _is.UuidValue ownerId,
    required String corpCode,
    DateTime? createdAt,
    DateTime? baselineAt,
    bool? muted,
    int? position,
  }) : super._(
         id: id,
         ownerId: ownerId,
         corpCode: corpCode,
         createdAt: createdAt,
         baselineAt: baselineAt,
         muted: muted,
         position: position,
       );

  /// Returns a shallow copy of this [WatchlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WatchlistEntry copyWith({
    Object? id = _Undefined,
    _is.UuidValue? ownerId,
    String? corpCode,
    DateTime? createdAt,
    Object? baselineAt = _Undefined,
    bool? muted,
    int? position,
  }) {
    return WatchlistEntry(
      id: id is int? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      corpCode: corpCode ?? this.corpCode,
      createdAt: createdAt ?? this.createdAt,
      baselineAt: baselineAt is DateTime? ? baselineAt : this.baselineAt,
      muted: muted ?? this.muted,
      position: position ?? this.position,
    );
  }
}

class WatchlistEntryUpdateTable extends _is.UpdateTable<WatchlistEntryTable> {
  WatchlistEntryUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> ownerId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.ownerId,
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

  _is.ColumnValue<DateTime, DateTime> baselineAt(DateTime? value) =>
      _is.ColumnValue(
        table.baselineAt,
        value,
      );

  _is.ColumnValue<bool, bool> muted(bool value) => _is.ColumnValue(
    table.muted,
    value,
  );

  _is.ColumnValue<int, int> position(int value) => _is.ColumnValue(
    table.position,
    value,
  );
}

class WatchlistEntryTable extends _is.Table<int?> {
  WatchlistEntryTable({super.tableRelation})
    : super(tableName: 'watchlist_entry') {
    updateTable = WatchlistEntryUpdateTable(this);
    ownerId = _is.ColumnUuid(
      'ownerId',
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
    baselineAt = _is.ColumnDateTime(
      'baselineAt',
      this,
    );
    muted = _is.ColumnBool(
      'muted',
      this,
      hasDefault: true,
    );
    position = _is.ColumnInt(
      'position',
      this,
      hasDefault: true,
    );
  }

  late final WatchlistEntryUpdateTable updateTable;

  late final _is.ColumnUuid ownerId;

  late final _is.ColumnString corpCode;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime baselineAt;

  late final _is.ColumnBool muted;

  late final _is.ColumnInt position;

  @override
  List<_is.Column> get columns => [
    id,
    ownerId,
    corpCode,
    createdAt,
    baselineAt,
    muted,
    position,
  ];
}

class WatchlistEntryInclude extends _is.IncludeObject {
  WatchlistEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WatchlistEntry.t;
}

class WatchlistEntryIncludeList extends _is.IncludeList {
  WatchlistEntryIncludeList._({
    _is.WhereExpressionBuilder<WatchlistEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WatchlistEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WatchlistEntry.t;
}

class WatchlistEntryRepository {
  const WatchlistEntryRepository._();

  /// Returns a list of [WatchlistEntry]s matching the given query parameters.
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
  Future<List<WatchlistEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WatchlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WatchlistEntry>(
      where: where?.call(WatchlistEntry.t),
      orderBy: orderBy?.call(WatchlistEntry.t),
      orderByList: orderByList?.call(WatchlistEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WatchlistEntry] matching the given query parameters.
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
  Future<WatchlistEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<WatchlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WatchlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WatchlistEntry>(
      where: where?.call(WatchlistEntry.t),
      orderBy: orderBy?.call(WatchlistEntry.t),
      orderByList: orderByList?.call(WatchlistEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WatchlistEntry] by its [id] or null if no such row exists.
  Future<WatchlistEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WatchlistEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WatchlistEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [WatchlistEntry]s will have their `id` fields set.
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
  Future<List<WatchlistEntry>> insert(
    _is.DatabaseSession session,
    List<WatchlistEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WatchlistEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WatchlistEntry] and returns the inserted row.
  ///
  /// The returned [WatchlistEntry] will have its `id` field set.
  Future<WatchlistEntry> insertRow(
    _is.DatabaseSession session,
    WatchlistEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WatchlistEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WatchlistEntry]s in the list and returns the resulting rows.
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
  /// The returned [WatchlistEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistEntry>> upsert(
    _is.DatabaseSession session,
    List<WatchlistEntry> rows, {
    required _is.ColumnSelections<WatchlistEntryTable> conflictColumns,
    _is.ColumnSelections<WatchlistEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<WatchlistEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WatchlistEntry>(
      rows,
      conflictColumns: conflictColumns(WatchlistEntry.t),
      updateColumns: updateColumns?.call(WatchlistEntry.t),
      updateWhere: updateWhere?.call(WatchlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WatchlistEntry] and returns the resulting row.
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
  /// The returned [WatchlistEntry] will have its `id` field set.
  Future<WatchlistEntry?> upsertRow(
    _is.DatabaseSession session,
    WatchlistEntry row, {
    required _is.ColumnSelections<WatchlistEntryTable> conflictColumns,
    _is.ColumnSelections<WatchlistEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<WatchlistEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WatchlistEntry>(
      row,
      conflictColumns: conflictColumns(WatchlistEntry.t),
      updateColumns: updateColumns?.call(WatchlistEntry.t),
      updateWhere: updateWhere?.call(WatchlistEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [WatchlistEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistEntry>> update(
    _is.DatabaseSession session,
    List<WatchlistEntry> rows, {
    _is.ColumnSelections<WatchlistEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WatchlistEntry>(
      rows,
      columns: columns?.call(WatchlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WatchlistEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WatchlistEntry> updateRow(
    _is.DatabaseSession session,
    WatchlistEntry row, {
    _is.ColumnSelections<WatchlistEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WatchlistEntry>(
      row,
      columns: columns?.call(WatchlistEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WatchlistEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WatchlistEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WatchlistEntryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WatchlistEntry>(
      id,
      columnValues: columnValues(WatchlistEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WatchlistEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WatchlistEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WatchlistEntryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<WatchlistEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WatchlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WatchlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WatchlistEntry>(
      columnValues: columnValues(WatchlistEntry.t.updateTable),
      where: where(WatchlistEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WatchlistEntry.t),
      orderByList: orderByList?.call(WatchlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WatchlistEntry]s in the list and returns the deleted rows.
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
  Future<List<WatchlistEntry>> delete(
    _is.DatabaseSession session,
    List<WatchlistEntry> rows, {
    _is.OrderByBuilder<WatchlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WatchlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WatchlistEntry>(
      rows,
      orderBy: orderBy?.call(WatchlistEntry.t),
      orderByList: orderByList?.call(WatchlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WatchlistEntry].
  Future<WatchlistEntry> deleteRow(
    _is.DatabaseSession session,
    WatchlistEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WatchlistEntry>(
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
  Future<List<WatchlistEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WatchlistEntryTable> where,
    _is.OrderByBuilder<WatchlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WatchlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WatchlistEntry>(
      where: where(WatchlistEntry.t),
      orderBy: orderBy?.call(WatchlistEntry.t),
      orderByList: orderByList?.call(WatchlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WatchlistEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WatchlistEntry>(
      where: where?.call(WatchlistEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WatchlistEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WatchlistEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WatchlistEntry>(
      where: where(WatchlistEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
