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

abstract class WebPushDelivery
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WebPushDelivery._({
    this.id,
    required this.noticeId,
    required this.subscriptionId,
    String? status,
    int? attempts,
    DateTime? nextAttemptAt,
  }) : status = status ?? 'pending',
       attempts = attempts ?? 0,
       nextAttemptAt = nextAttemptAt ?? DateTime.now();

  factory WebPushDelivery({
    int? id,
    required int noticeId,
    required int subscriptionId,
    String? status,
    int? attempts,
    DateTime? nextAttemptAt,
  }) = _WebPushDeliveryImpl;

  factory WebPushDelivery.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebPushDelivery(
      id: jsonSerialization['id'] as int?,
      noticeId: jsonSerialization['noticeId'] as int,
      subscriptionId: jsonSerialization['subscriptionId'] as int,
      status: jsonSerialization['status'] as String?,
      attempts: jsonSerialization['attempts'] as int?,
      nextAttemptAt: jsonSerialization['nextAttemptAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['nextAttemptAt'],
            ),
    );
  }

  static final t = WebPushDeliveryTable();

  static const db = WebPushDeliveryRepository._();

  @override
  int? id;

  int noticeId;

  int subscriptionId;

  String status;

  int attempts;

  DateTime nextAttemptAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WebPushDelivery]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WebPushDelivery copyWith({
    int? id,
    int? noticeId,
    int? subscriptionId,
    String? status,
    int? attempts,
    DateTime? nextAttemptAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebPushDelivery',
      if (id != null) 'id': id,
      'noticeId': noticeId,
      'subscriptionId': subscriptionId,
      'status': status,
      'attempts': attempts,
      'nextAttemptAt': nextAttemptAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WebPushDeliveryInclude include() {
    return WebPushDeliveryInclude._();
  }

  static WebPushDeliveryIncludeList includeList({
    _is.WhereExpressionBuilder<WebPushDeliveryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WebPushDeliveryTable>? orderBy,
    _is.OrderByListBuilder<WebPushDeliveryTable>? orderByList,
    WebPushDeliveryInclude? include,
  }) {
    return WebPushDeliveryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WebPushDelivery.t),
      orderByList: orderByList?.call(WebPushDelivery.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WebPushDeliveryImpl extends WebPushDelivery {
  _WebPushDeliveryImpl({
    int? id,
    required int noticeId,
    required int subscriptionId,
    String? status,
    int? attempts,
    DateTime? nextAttemptAt,
  }) : super._(
         id: id,
         noticeId: noticeId,
         subscriptionId: subscriptionId,
         status: status,
         attempts: attempts,
         nextAttemptAt: nextAttemptAt,
       );

  /// Returns a shallow copy of this [WebPushDelivery]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WebPushDelivery copyWith({
    Object? id = _Undefined,
    int? noticeId,
    int? subscriptionId,
    String? status,
    int? attempts,
    DateTime? nextAttemptAt,
  }) {
    return WebPushDelivery(
      id: id is int? ? id : this.id,
      noticeId: noticeId ?? this.noticeId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }
}

class WebPushDeliveryUpdateTable extends _is.UpdateTable<WebPushDeliveryTable> {
  WebPushDeliveryUpdateTable(super.table);

  _is.ColumnValue<int, int> noticeId(int value) => _is.ColumnValue(
    table.noticeId,
    value,
  );

  _is.ColumnValue<int, int> subscriptionId(int value) => _is.ColumnValue(
    table.subscriptionId,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> attempts(int value) => _is.ColumnValue(
    table.attempts,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> nextAttemptAt(DateTime value) =>
      _is.ColumnValue(
        table.nextAttemptAt,
        value,
      );
}

class WebPushDeliveryTable extends _is.Table<int?> {
  WebPushDeliveryTable({super.tableRelation})
    : super(tableName: 'web_push_delivery') {
    updateTable = WebPushDeliveryUpdateTable(this);
    noticeId = _is.ColumnInt(
      'noticeId',
      this,
    );
    subscriptionId = _is.ColumnInt(
      'subscriptionId',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
      hasDefault: true,
    );
    attempts = _is.ColumnInt(
      'attempts',
      this,
      hasDefault: true,
    );
    nextAttemptAt = _is.ColumnDateTime(
      'nextAttemptAt',
      this,
      hasDefault: true,
    );
  }

  late final WebPushDeliveryUpdateTable updateTable;

  late final _is.ColumnInt noticeId;

  late final _is.ColumnInt subscriptionId;

  late final _is.ColumnString status;

  late final _is.ColumnInt attempts;

  late final _is.ColumnDateTime nextAttemptAt;

  @override
  List<_is.Column> get columns => [
    id,
    noticeId,
    subscriptionId,
    status,
    attempts,
    nextAttemptAt,
  ];
}

class WebPushDeliveryInclude extends _is.IncludeObject {
  WebPushDeliveryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WebPushDelivery.t;
}

class WebPushDeliveryIncludeList extends _is.IncludeList {
  WebPushDeliveryIncludeList._({
    _is.WhereExpressionBuilder<WebPushDeliveryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WebPushDelivery.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WebPushDelivery.t;
}

class WebPushDeliveryRepository {
  const WebPushDeliveryRepository._();

  /// Returns a list of [WebPushDelivery]s matching the given query parameters.
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
  Future<List<WebPushDelivery>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WebPushDeliveryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WebPushDeliveryTable>? orderBy,
    _is.OrderByListBuilder<WebPushDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WebPushDelivery>(
      where: where?.call(WebPushDelivery.t),
      orderBy: orderBy?.call(WebPushDelivery.t),
      orderByList: orderByList?.call(WebPushDelivery.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WebPushDelivery] matching the given query parameters.
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
  Future<WebPushDelivery?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WebPushDeliveryTable>? where,
    int? offset,
    _is.OrderByBuilder<WebPushDeliveryTable>? orderBy,
    _is.OrderByListBuilder<WebPushDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WebPushDelivery>(
      where: where?.call(WebPushDelivery.t),
      orderBy: orderBy?.call(WebPushDelivery.t),
      orderByList: orderByList?.call(WebPushDelivery.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WebPushDelivery] by its [id] or null if no such row exists.
  Future<WebPushDelivery?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WebPushDelivery>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WebPushDelivery]s in the list and returns the inserted rows.
  ///
  /// The returned [WebPushDelivery]s will have their `id` fields set.
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
  Future<List<WebPushDelivery>> insert(
    _is.DatabaseSession session,
    List<WebPushDelivery> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WebPushDelivery>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WebPushDelivery] and returns the inserted row.
  ///
  /// The returned [WebPushDelivery] will have its `id` field set.
  Future<WebPushDelivery> insertRow(
    _is.DatabaseSession session,
    WebPushDelivery row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WebPushDelivery>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WebPushDelivery]s in the list and returns the resulting rows.
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
  /// The returned [WebPushDelivery]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WebPushDelivery>> upsert(
    _is.DatabaseSession session,
    List<WebPushDelivery> rows, {
    required _is.ColumnSelections<WebPushDeliveryTable> conflictColumns,
    _is.ColumnSelections<WebPushDeliveryTable>? updateColumns,
    _is.WhereExpressionBuilder<WebPushDeliveryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WebPushDelivery>(
      rows,
      conflictColumns: conflictColumns(WebPushDelivery.t),
      updateColumns: updateColumns?.call(WebPushDelivery.t),
      updateWhere: updateWhere?.call(WebPushDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WebPushDelivery] and returns the resulting row.
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
  /// The returned [WebPushDelivery] will have its `id` field set.
  Future<WebPushDelivery?> upsertRow(
    _is.DatabaseSession session,
    WebPushDelivery row, {
    required _is.ColumnSelections<WebPushDeliveryTable> conflictColumns,
    _is.ColumnSelections<WebPushDeliveryTable>? updateColumns,
    _is.WhereExpressionBuilder<WebPushDeliveryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WebPushDelivery>(
      row,
      conflictColumns: conflictColumns(WebPushDelivery.t),
      updateColumns: updateColumns?.call(WebPushDelivery.t),
      updateWhere: updateWhere?.call(WebPushDelivery.t),
      transaction: transaction,
    );
  }

  /// Updates all [WebPushDelivery]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WebPushDelivery>> update(
    _is.DatabaseSession session,
    List<WebPushDelivery> rows, {
    _is.ColumnSelections<WebPushDeliveryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WebPushDelivery>(
      rows,
      columns: columns?.call(WebPushDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WebPushDelivery]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WebPushDelivery> updateRow(
    _is.DatabaseSession session,
    WebPushDelivery row, {
    _is.ColumnSelections<WebPushDeliveryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WebPushDelivery>(
      row,
      columns: columns?.call(WebPushDelivery.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WebPushDelivery] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WebPushDelivery?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WebPushDeliveryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WebPushDelivery>(
      id,
      columnValues: columnValues(WebPushDelivery.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WebPushDelivery]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WebPushDelivery>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WebPushDeliveryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WebPushDeliveryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WebPushDeliveryTable>? orderBy,
    _is.OrderByListBuilder<WebPushDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WebPushDelivery>(
      columnValues: columnValues(WebPushDelivery.t.updateTable),
      where: where(WebPushDelivery.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WebPushDelivery.t),
      orderByList: orderByList?.call(WebPushDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WebPushDelivery]s in the list and returns the deleted rows.
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
  Future<List<WebPushDelivery>> delete(
    _is.DatabaseSession session,
    List<WebPushDelivery> rows, {
    _is.OrderByBuilder<WebPushDeliveryTable>? orderBy,
    _is.OrderByListBuilder<WebPushDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WebPushDelivery>(
      rows,
      orderBy: orderBy?.call(WebPushDelivery.t),
      orderByList: orderByList?.call(WebPushDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WebPushDelivery].
  Future<WebPushDelivery> deleteRow(
    _is.DatabaseSession session,
    WebPushDelivery row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WebPushDelivery>(
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
  Future<List<WebPushDelivery>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WebPushDeliveryTable> where,
    _is.OrderByBuilder<WebPushDeliveryTable>? orderBy,
    _is.OrderByListBuilder<WebPushDeliveryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WebPushDelivery>(
      where: where(WebPushDelivery.t),
      orderBy: orderBy?.call(WebPushDelivery.t),
      orderByList: orderByList?.call(WebPushDelivery.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WebPushDeliveryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WebPushDelivery>(
      where: where?.call(WebPushDelivery.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WebPushDelivery] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WebPushDeliveryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WebPushDelivery>(
      where: where(WebPushDelivery.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
