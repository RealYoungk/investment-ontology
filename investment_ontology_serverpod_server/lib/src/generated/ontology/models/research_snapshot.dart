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

/// Validated immutable research feed batches. Ratios remain computed at read time.
abstract class ResearchSnapshot
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ResearchSnapshot._({
    this.id,
    required this.companyId,
    required this.kind,
    required this.provider,
    required this.payload,
    required this.sourceId,
    required this.digest,
    required this.createdAt,
  });

  factory ResearchSnapshot({
    int? id,
    required int companyId,
    required String kind,
    required String provider,
    required String payload,
    required int sourceId,
    required String digest,
    required DateTime createdAt,
  }) = _ResearchSnapshotImpl;

  factory ResearchSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchSnapshot(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      kind: jsonSerialization['kind'] as String,
      provider: jsonSerialization['provider'] as String,
      payload: jsonSerialization['payload'] as String,
      sourceId: jsonSerialization['sourceId'] as int,
      digest: jsonSerialization['digest'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ResearchSnapshotTable();

  static const db = ResearchSnapshotRepository._();

  @override
  int? id;

  int companyId;

  String kind;

  String provider;

  String payload;

  int sourceId;

  String digest;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ResearchSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ResearchSnapshot copyWith({
    int? id,
    int? companyId,
    String? kind,
    String? provider,
    String? payload,
    int? sourceId,
    String? digest,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchSnapshot',
      if (id != null) 'id': id,
      'companyId': companyId,
      'kind': kind,
      'provider': provider,
      'payload': payload,
      'sourceId': sourceId,
      'digest': digest,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchSnapshot',
      if (id != null) 'id': id,
      'companyId': companyId,
      'kind': kind,
      'provider': provider,
      'payload': payload,
      'sourceId': sourceId,
      'digest': digest,
      'createdAt': createdAt.toJson(),
    };
  }

  static ResearchSnapshotInclude include() {
    return ResearchSnapshotInclude._();
  }

  static ResearchSnapshotIncludeList includeList({
    _is.WhereExpressionBuilder<ResearchSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchSnapshotTable>? orderBy,
    _is.OrderByListBuilder<ResearchSnapshotTable>? orderByList,
    ResearchSnapshotInclude? include,
  }) {
    return ResearchSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchSnapshot.t),
      orderByList: orderByList?.call(ResearchSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchSnapshotImpl extends ResearchSnapshot {
  _ResearchSnapshotImpl({
    int? id,
    required int companyId,
    required String kind,
    required String provider,
    required String payload,
    required int sourceId,
    required String digest,
    required DateTime createdAt,
  }) : super._(
         id: id,
         companyId: companyId,
         kind: kind,
         provider: provider,
         payload: payload,
         sourceId: sourceId,
         digest: digest,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ResearchSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ResearchSnapshot copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? kind,
    String? provider,
    String? payload,
    int? sourceId,
    String? digest,
    DateTime? createdAt,
  }) {
    return ResearchSnapshot(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      kind: kind ?? this.kind,
      provider: provider ?? this.provider,
      payload: payload ?? this.payload,
      sourceId: sourceId ?? this.sourceId,
      digest: digest ?? this.digest,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ResearchSnapshotUpdateTable
    extends _is.UpdateTable<ResearchSnapshotTable> {
  ResearchSnapshotUpdateTable(super.table);

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<String, String> kind(String value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> provider(String value) => _is.ColumnValue(
    table.provider,
    value,
  );

  _is.ColumnValue<String, String> payload(String value) => _is.ColumnValue(
    table.payload,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<String, String> digest(String value) => _is.ColumnValue(
    table.digest,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ResearchSnapshotTable extends _is.Table<int?> {
  ResearchSnapshotTable({super.tableRelation})
    : super(tableName: 'research_snapshot') {
    updateTable = ResearchSnapshotUpdateTable(this);
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    kind = _is.ColumnString(
      'kind',
      this,
    );
    provider = _is.ColumnString(
      'provider',
      this,
    );
    payload = _is.ColumnString(
      'payload',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    digest = _is.ColumnString(
      'digest',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ResearchSnapshotUpdateTable updateTable;

  late final _is.ColumnInt companyId;

  late final _is.ColumnString kind;

  late final _is.ColumnString provider;

  late final _is.ColumnString payload;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnString digest;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    companyId,
    kind,
    provider,
    payload,
    sourceId,
    digest,
    createdAt,
  ];
}

class ResearchSnapshotInclude extends _is.IncludeObject {
  ResearchSnapshotInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ResearchSnapshot.t;
}

class ResearchSnapshotIncludeList extends _is.IncludeList {
  ResearchSnapshotIncludeList._({
    _is.WhereExpressionBuilder<ResearchSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ResearchSnapshot.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ResearchSnapshot.t;
}

class ResearchSnapshotRepository {
  const ResearchSnapshotRepository._();

  /// Returns a list of [ResearchSnapshot]s matching the given query parameters.
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
  Future<List<ResearchSnapshot>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchSnapshotTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchSnapshotTable>? orderBy,
    _is.OrderByListBuilder<ResearchSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ResearchSnapshot>(
      where: where?.call(ResearchSnapshot.t),
      orderBy: orderBy?.call(ResearchSnapshot.t),
      orderByList: orderByList?.call(ResearchSnapshot.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ResearchSnapshot] matching the given query parameters.
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
  Future<ResearchSnapshot?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchSnapshotTable>? where,
    int? offset,
    _is.OrderByBuilder<ResearchSnapshotTable>? orderBy,
    _is.OrderByListBuilder<ResearchSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ResearchSnapshot>(
      where: where?.call(ResearchSnapshot.t),
      orderBy: orderBy?.call(ResearchSnapshot.t),
      orderByList: orderByList?.call(ResearchSnapshot.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ResearchSnapshot] by its [id] or null if no such row exists.
  Future<ResearchSnapshot?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ResearchSnapshot>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ResearchSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [ResearchSnapshot]s will have their `id` fields set.
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
  Future<List<ResearchSnapshot>> insert(
    _is.DatabaseSession session,
    List<ResearchSnapshot> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ResearchSnapshot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ResearchSnapshot] and returns the inserted row.
  ///
  /// The returned [ResearchSnapshot] will have its `id` field set.
  Future<ResearchSnapshot> insertRow(
    _is.DatabaseSession session,
    ResearchSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ResearchSnapshot>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ResearchSnapshot]s in the list and returns the resulting rows.
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
  /// The returned [ResearchSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchSnapshot>> upsert(
    _is.DatabaseSession session,
    List<ResearchSnapshot> rows, {
    required _is.ColumnSelections<ResearchSnapshotTable> conflictColumns,
    _is.ColumnSelections<ResearchSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ResearchSnapshot>(
      rows,
      conflictColumns: conflictColumns(ResearchSnapshot.t),
      updateColumns: updateColumns?.call(ResearchSnapshot.t),
      updateWhere: updateWhere?.call(ResearchSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ResearchSnapshot] and returns the resulting row.
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
  /// The returned [ResearchSnapshot] will have its `id` field set.
  Future<ResearchSnapshot?> upsertRow(
    _is.DatabaseSession session,
    ResearchSnapshot row, {
    required _is.ColumnSelections<ResearchSnapshotTable> conflictColumns,
    _is.ColumnSelections<ResearchSnapshotTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchSnapshotTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ResearchSnapshot>(
      row,
      conflictColumns: conflictColumns(ResearchSnapshot.t),
      updateColumns: updateColumns?.call(ResearchSnapshot.t),
      updateWhere: updateWhere?.call(ResearchSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchSnapshot>> update(
    _is.DatabaseSession session,
    List<ResearchSnapshot> rows, {
    _is.ColumnSelections<ResearchSnapshotTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ResearchSnapshot>(
      rows,
      columns: columns?.call(ResearchSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ResearchSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ResearchSnapshot> updateRow(
    _is.DatabaseSession session,
    ResearchSnapshot row, {
    _is.ColumnSelections<ResearchSnapshotTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ResearchSnapshot>(
      row,
      columns: columns?.call(ResearchSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ResearchSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ResearchSnapshot?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ResearchSnapshotUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ResearchSnapshot>(
      id,
      columnValues: columnValues(ResearchSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchSnapshot>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ResearchSnapshotUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ResearchSnapshotTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchSnapshotTable>? orderBy,
    _is.OrderByListBuilder<ResearchSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ResearchSnapshot>(
      columnValues: columnValues(ResearchSnapshot.t.updateTable),
      where: where(ResearchSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchSnapshot.t),
      orderByList: orderByList?.call(ResearchSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ResearchSnapshot]s in the list and returns the deleted rows.
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
  Future<List<ResearchSnapshot>> delete(
    _is.DatabaseSession session,
    List<ResearchSnapshot> rows, {
    _is.OrderByBuilder<ResearchSnapshotTable>? orderBy,
    _is.OrderByListBuilder<ResearchSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ResearchSnapshot>(
      rows,
      orderBy: orderBy?.call(ResearchSnapshot.t),
      orderByList: orderByList?.call(ResearchSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ResearchSnapshot].
  Future<ResearchSnapshot> deleteRow(
    _is.DatabaseSession session,
    ResearchSnapshot row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ResearchSnapshot>(
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
  Future<List<ResearchSnapshot>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchSnapshotTable> where,
    _is.OrderByBuilder<ResearchSnapshotTable>? orderBy,
    _is.OrderByListBuilder<ResearchSnapshotTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ResearchSnapshot>(
      where: where(ResearchSnapshot.t),
      orderBy: orderBy?.call(ResearchSnapshot.t),
      orderByList: orderByList?.call(ResearchSnapshot.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchSnapshotTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ResearchSnapshot>(
      where: where?.call(ResearchSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ResearchSnapshot] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchSnapshotTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ResearchSnapshot>(
      where: where(ResearchSnapshot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
