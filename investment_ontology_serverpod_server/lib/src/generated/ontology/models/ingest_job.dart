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
import '../../ontology/models/ingest_status.dart' as _i281cs6p;

/// 외부 원천 수집 작업 기록.
abstract class IngestJob
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  IngestJob._({
    this.id,
    required this.kind,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    this.message,
  }) : total = total ?? 0,
       processed = processed ?? 0,
       updated = updated ?? 0,
       failed = failed ?? 0,
       apiCalls = apiCalls ?? 0;

  factory IngestJob({
    int? id,
    required String kind,
    required _i281cs6p.IngestStatus status,
    required DateTime startedAt,
    DateTime? finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    String? message,
  }) = _IngestJobImpl;

  factory IngestJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return IngestJob(
      id: jsonSerialization['id'] as int?,
      kind: jsonSerialization['kind'] as String,
      status: _i281cs6p.IngestStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      startedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      finishedAt: jsonSerialization['finishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['finishedAt']),
      total: jsonSerialization['total'] as int?,
      processed: jsonSerialization['processed'] as int?,
      updated: jsonSerialization['updated'] as int?,
      failed: jsonSerialization['failed'] as int?,
      apiCalls: jsonSerialization['apiCalls'] as int?,
      message: jsonSerialization['message'] as String?,
    );
  }

  static final t = IngestJobTable();

  static const db = IngestJobRepository._();

  @override
  int? id;

  /// 예: "company_master"
  String kind;

  _i281cs6p.IngestStatus status;

  DateTime startedAt;

  DateTime? finishedAt;

  int total;

  int processed;

  int updated;

  int failed;

  int apiCalls;

  String? message;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [IngestJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  IngestJob copyWith({
    int? id,
    String? kind,
    _i281cs6p.IngestStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IngestJob',
      if (id != null) 'id': id,
      'kind': kind,
      'status': status.toJson(),
      'startedAt': startedAt.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      'total': total,
      'processed': processed,
      'updated': updated,
      'failed': failed,
      'apiCalls': apiCalls,
      if (message != null) 'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IngestJob',
      if (id != null) 'id': id,
      'kind': kind,
      'status': status.toJson(),
      'startedAt': startedAt.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      'total': total,
      'processed': processed,
      'updated': updated,
      'failed': failed,
      'apiCalls': apiCalls,
      if (message != null) 'message': message,
    };
  }

  static IngestJobInclude include() {
    return IngestJobInclude._();
  }

  static IngestJobIncludeList includeList({
    _is.WhereExpressionBuilder<IngestJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IngestJobTable>? orderBy,
    _is.OrderByListBuilder<IngestJobTable>? orderByList,
    IngestJobInclude? include,
  }) {
    return IngestJobIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IngestJob.t),
      orderByList: orderByList?.call(IngestJob.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IngestJobImpl extends IngestJob {
  _IngestJobImpl({
    int? id,
    required String kind,
    required _i281cs6p.IngestStatus status,
    required DateTime startedAt,
    DateTime? finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    String? message,
  }) : super._(
         id: id,
         kind: kind,
         status: status,
         startedAt: startedAt,
         finishedAt: finishedAt,
         total: total,
         processed: processed,
         updated: updated,
         failed: failed,
         apiCalls: apiCalls,
         message: message,
       );

  /// Returns a shallow copy of this [IngestJob]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  IngestJob copyWith({
    Object? id = _Undefined,
    String? kind,
    _i281cs6p.IngestStatus? status,
    DateTime? startedAt,
    Object? finishedAt = _Undefined,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    Object? message = _Undefined,
  }) {
    return IngestJob(
      id: id is int? ? id : this.id,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt is DateTime? ? finishedAt : this.finishedAt,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      updated: updated ?? this.updated,
      failed: failed ?? this.failed,
      apiCalls: apiCalls ?? this.apiCalls,
      message: message is String? ? message : this.message,
    );
  }
}

class IngestJobUpdateTable extends _is.UpdateTable<IngestJobTable> {
  IngestJobUpdateTable(super.table);

  _is.ColumnValue<String, String> kind(String value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<_i281cs6p.IngestStatus, _i281cs6p.IngestStatus> status(
    _i281cs6p.IngestStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> finishedAt(DateTime? value) =>
      _is.ColumnValue(
        table.finishedAt,
        value,
      );

  _is.ColumnValue<int, int> total(int value) => _is.ColumnValue(
    table.total,
    value,
  );

  _is.ColumnValue<int, int> processed(int value) => _is.ColumnValue(
    table.processed,
    value,
  );

  _is.ColumnValue<int, int> updated(int value) => _is.ColumnValue(
    table.updated,
    value,
  );

  _is.ColumnValue<int, int> failed(int value) => _is.ColumnValue(
    table.failed,
    value,
  );

  _is.ColumnValue<int, int> apiCalls(int value) => _is.ColumnValue(
    table.apiCalls,
    value,
  );

  _is.ColumnValue<String, String> message(String? value) => _is.ColumnValue(
    table.message,
    value,
  );
}

class IngestJobTable extends _is.Table<int?> {
  IngestJobTable({super.tableRelation}) : super(tableName: 'ingest_job') {
    updateTable = IngestJobUpdateTable(this);
    kind = _is.ColumnString(
      'kind',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    finishedAt = _is.ColumnDateTime(
      'finishedAt',
      this,
    );
    total = _is.ColumnInt(
      'total',
      this,
      hasDefault: true,
    );
    processed = _is.ColumnInt(
      'processed',
      this,
      hasDefault: true,
    );
    updated = _is.ColumnInt(
      'updated',
      this,
      hasDefault: true,
    );
    failed = _is.ColumnInt(
      'failed',
      this,
      hasDefault: true,
    );
    apiCalls = _is.ColumnInt(
      'apiCalls',
      this,
      hasDefault: true,
    );
    message = _is.ColumnString(
      'message',
      this,
    );
  }

  late final IngestJobUpdateTable updateTable;

  /// 예: "company_master"
  late final _is.ColumnString kind;

  late final _is.ColumnEnum<_i281cs6p.IngestStatus> status;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime finishedAt;

  late final _is.ColumnInt total;

  late final _is.ColumnInt processed;

  late final _is.ColumnInt updated;

  late final _is.ColumnInt failed;

  late final _is.ColumnInt apiCalls;

  late final _is.ColumnString message;

  @override
  List<_is.Column> get columns => [
    id,
    kind,
    status,
    startedAt,
    finishedAt,
    total,
    processed,
    updated,
    failed,
    apiCalls,
    message,
  ];
}

class IngestJobInclude extends _is.IncludeObject {
  IngestJobInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => IngestJob.t;
}

class IngestJobIncludeList extends _is.IncludeList {
  IngestJobIncludeList._({
    _is.WhereExpressionBuilder<IngestJobTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(IngestJob.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => IngestJob.t;
}

class IngestJobRepository {
  const IngestJobRepository._();

  /// Returns a list of [IngestJob]s matching the given query parameters.
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
  Future<List<IngestJob>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IngestJobTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IngestJobTable>? orderBy,
    _is.OrderByListBuilder<IngestJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<IngestJob>(
      where: where?.call(IngestJob.t),
      orderBy: orderBy?.call(IngestJob.t),
      orderByList: orderByList?.call(IngestJob.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [IngestJob] matching the given query parameters.
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
  Future<IngestJob?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IngestJobTable>? where,
    int? offset,
    _is.OrderByBuilder<IngestJobTable>? orderBy,
    _is.OrderByListBuilder<IngestJobTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<IngestJob>(
      where: where?.call(IngestJob.t),
      orderBy: orderBy?.call(IngestJob.t),
      orderByList: orderByList?.call(IngestJob.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [IngestJob] by its [id] or null if no such row exists.
  Future<IngestJob?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<IngestJob>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [IngestJob]s in the list and returns the inserted rows.
  ///
  /// The returned [IngestJob]s will have their `id` fields set.
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
  Future<List<IngestJob>> insert(
    _is.DatabaseSession session,
    List<IngestJob> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<IngestJob>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [IngestJob] and returns the inserted row.
  ///
  /// The returned [IngestJob] will have its `id` field set.
  Future<IngestJob> insertRow(
    _is.DatabaseSession session,
    IngestJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<IngestJob>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [IngestJob]s in the list and returns the resulting rows.
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
  /// The returned [IngestJob]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<IngestJob>> upsert(
    _is.DatabaseSession session,
    List<IngestJob> rows, {
    required _is.ColumnSelections<IngestJobTable> conflictColumns,
    _is.ColumnSelections<IngestJobTable>? updateColumns,
    _is.WhereExpressionBuilder<IngestJobTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<IngestJob>(
      rows,
      conflictColumns: conflictColumns(IngestJob.t),
      updateColumns: updateColumns?.call(IngestJob.t),
      updateWhere: updateWhere?.call(IngestJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [IngestJob] and returns the resulting row.
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
  /// The returned [IngestJob] will have its `id` field set.
  Future<IngestJob?> upsertRow(
    _is.DatabaseSession session,
    IngestJob row, {
    required _is.ColumnSelections<IngestJobTable> conflictColumns,
    _is.ColumnSelections<IngestJobTable>? updateColumns,
    _is.WhereExpressionBuilder<IngestJobTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<IngestJob>(
      row,
      conflictColumns: conflictColumns(IngestJob.t),
      updateColumns: updateColumns?.call(IngestJob.t),
      updateWhere: updateWhere?.call(IngestJob.t),
      transaction: transaction,
    );
  }

  /// Updates all [IngestJob]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<IngestJob>> update(
    _is.DatabaseSession session,
    List<IngestJob> rows, {
    _is.ColumnSelections<IngestJobTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<IngestJob>(
      rows,
      columns: columns?.call(IngestJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [IngestJob]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<IngestJob> updateRow(
    _is.DatabaseSession session,
    IngestJob row, {
    _is.ColumnSelections<IngestJobTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<IngestJob>(
      row,
      columns: columns?.call(IngestJob.t),
      transaction: transaction,
    );
  }

  /// Updates a single [IngestJob] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<IngestJob?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<IngestJobUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<IngestJob>(
      id,
      columnValues: columnValues(IngestJob.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [IngestJob]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<IngestJob>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<IngestJobUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<IngestJobTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IngestJobTable>? orderBy,
    _is.OrderByListBuilder<IngestJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<IngestJob>(
      columnValues: columnValues(IngestJob.t.updateTable),
      where: where(IngestJob.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(IngestJob.t),
      orderByList: orderByList?.call(IngestJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [IngestJob]s in the list and returns the deleted rows.
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
  Future<List<IngestJob>> delete(
    _is.DatabaseSession session,
    List<IngestJob> rows, {
    _is.OrderByBuilder<IngestJobTable>? orderBy,
    _is.OrderByListBuilder<IngestJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<IngestJob>(
      rows,
      orderBy: orderBy?.call(IngestJob.t),
      orderByList: orderByList?.call(IngestJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [IngestJob].
  Future<IngestJob> deleteRow(
    _is.DatabaseSession session,
    IngestJob row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<IngestJob>(
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
  Future<List<IngestJob>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<IngestJobTable> where,
    _is.OrderByBuilder<IngestJobTable>? orderBy,
    _is.OrderByListBuilder<IngestJobTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<IngestJob>(
      where: where(IngestJob.t),
      orderBy: orderBy?.call(IngestJob.t),
      orderByList: orderByList?.call(IngestJob.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IngestJobTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<IngestJob>(
      where: where?.call(IngestJob.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [IngestJob] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<IngestJobTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<IngestJob>(
      where: where(IngestJob.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
