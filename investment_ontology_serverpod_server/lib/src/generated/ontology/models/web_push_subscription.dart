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

abstract class WebPushSubscription
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WebPushSubscription._({
    this.id,
    required this.ownerId,
    required this.endpoint,
    required this.p256dh,
    required this.auth,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WebPushSubscription({
    int? id,
    required _is.UuidValue ownerId,
    required String endpoint,
    required String p256dh,
    required String auth,
    DateTime? createdAt,
  }) = _WebPushSubscriptionImpl;

  factory WebPushSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebPushSubscription(
      id: jsonSerialization['id'] as int?,
      ownerId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['ownerId'],
      ),
      endpoint: jsonSerialization['endpoint'] as String,
      p256dh: jsonSerialization['p256dh'] as String,
      auth: jsonSerialization['auth'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = WebPushSubscriptionTable();

  static const db = WebPushSubscriptionRepository._();

  @override
  int? id;

  _is.UuidValue ownerId;

  String endpoint;

  String p256dh;

  String auth;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WebPushSubscription]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WebPushSubscription copyWith({
    int? id,
    _is.UuidValue? ownerId,
    String? endpoint,
    String? p256dh,
    String? auth,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebPushSubscription',
      if (id != null) 'id': id,
      'ownerId': ownerId.toJson(),
      'endpoint': endpoint,
      'p256dh': p256dh,
      'auth': auth,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static WebPushSubscriptionInclude include() {
    return WebPushSubscriptionInclude._();
  }

  static WebPushSubscriptionIncludeList includeList({
    _is.WhereExpressionBuilder<WebPushSubscriptionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WebPushSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<WebPushSubscriptionTable>? orderByList,
    WebPushSubscriptionInclude? include,
  }) {
    return WebPushSubscriptionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WebPushSubscription.t),
      orderByList: orderByList?.call(WebPushSubscription.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WebPushSubscriptionImpl extends WebPushSubscription {
  _WebPushSubscriptionImpl({
    int? id,
    required _is.UuidValue ownerId,
    required String endpoint,
    required String p256dh,
    required String auth,
    DateTime? createdAt,
  }) : super._(
         id: id,
         ownerId: ownerId,
         endpoint: endpoint,
         p256dh: p256dh,
         auth: auth,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WebPushSubscription]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WebPushSubscription copyWith({
    Object? id = _Undefined,
    _is.UuidValue? ownerId,
    String? endpoint,
    String? p256dh,
    String? auth,
    DateTime? createdAt,
  }) {
    return WebPushSubscription(
      id: id is int? ? id : this.id,
      ownerId: ownerId ?? this.ownerId,
      endpoint: endpoint ?? this.endpoint,
      p256dh: p256dh ?? this.p256dh,
      auth: auth ?? this.auth,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WebPushSubscriptionUpdateTable
    extends _is.UpdateTable<WebPushSubscriptionTable> {
  WebPushSubscriptionUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> ownerId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.ownerId,
        value,
      );

  _is.ColumnValue<String, String> endpoint(String value) => _is.ColumnValue(
    table.endpoint,
    value,
  );

  _is.ColumnValue<String, String> p256dh(String value) => _is.ColumnValue(
    table.p256dh,
    value,
  );

  _is.ColumnValue<String, String> auth(String value) => _is.ColumnValue(
    table.auth,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class WebPushSubscriptionTable extends _is.Table<int?> {
  WebPushSubscriptionTable({super.tableRelation})
    : super(tableName: 'web_push_subscription') {
    updateTable = WebPushSubscriptionUpdateTable(this);
    ownerId = _is.ColumnUuid(
      'ownerId',
      this,
    );
    endpoint = _is.ColumnString(
      'endpoint',
      this,
    );
    p256dh = _is.ColumnString(
      'p256dh',
      this,
    );
    auth = _is.ColumnString(
      'auth',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final WebPushSubscriptionUpdateTable updateTable;

  late final _is.ColumnUuid ownerId;

  late final _is.ColumnString endpoint;

  late final _is.ColumnString p256dh;

  late final _is.ColumnString auth;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    ownerId,
    endpoint,
    p256dh,
    auth,
    createdAt,
  ];
}

class WebPushSubscriptionInclude extends _is.IncludeObject {
  WebPushSubscriptionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WebPushSubscription.t;
}

class WebPushSubscriptionIncludeList extends _is.IncludeList {
  WebPushSubscriptionIncludeList._({
    _is.WhereExpressionBuilder<WebPushSubscriptionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WebPushSubscription.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WebPushSubscription.t;
}

class WebPushSubscriptionRepository {
  const WebPushSubscriptionRepository._();

  /// Returns a list of [WebPushSubscription]s matching the given query parameters.
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
  Future<List<WebPushSubscription>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WebPushSubscriptionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WebPushSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<WebPushSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WebPushSubscription>(
      where: where?.call(WebPushSubscription.t),
      orderBy: orderBy?.call(WebPushSubscription.t),
      orderByList: orderByList?.call(WebPushSubscription.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WebPushSubscription] matching the given query parameters.
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
  Future<WebPushSubscription?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WebPushSubscriptionTable>? where,
    int? offset,
    _is.OrderByBuilder<WebPushSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<WebPushSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WebPushSubscription>(
      where: where?.call(WebPushSubscription.t),
      orderBy: orderBy?.call(WebPushSubscription.t),
      orderByList: orderByList?.call(WebPushSubscription.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WebPushSubscription] by its [id] or null if no such row exists.
  Future<WebPushSubscription?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WebPushSubscription>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WebPushSubscription]s in the list and returns the inserted rows.
  ///
  /// The returned [WebPushSubscription]s will have their `id` fields set.
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
  Future<List<WebPushSubscription>> insert(
    _is.DatabaseSession session,
    List<WebPushSubscription> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WebPushSubscription>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WebPushSubscription] and returns the inserted row.
  ///
  /// The returned [WebPushSubscription] will have its `id` field set.
  Future<WebPushSubscription> insertRow(
    _is.DatabaseSession session,
    WebPushSubscription row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WebPushSubscription>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WebPushSubscription]s in the list and returns the resulting rows.
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
  /// The returned [WebPushSubscription]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WebPushSubscription>> upsert(
    _is.DatabaseSession session,
    List<WebPushSubscription> rows, {
    required _is.ColumnSelections<WebPushSubscriptionTable> conflictColumns,
    _is.ColumnSelections<WebPushSubscriptionTable>? updateColumns,
    _is.WhereExpressionBuilder<WebPushSubscriptionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WebPushSubscription>(
      rows,
      conflictColumns: conflictColumns(WebPushSubscription.t),
      updateColumns: updateColumns?.call(WebPushSubscription.t),
      updateWhere: updateWhere?.call(WebPushSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WebPushSubscription] and returns the resulting row.
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
  /// The returned [WebPushSubscription] will have its `id` field set.
  Future<WebPushSubscription?> upsertRow(
    _is.DatabaseSession session,
    WebPushSubscription row, {
    required _is.ColumnSelections<WebPushSubscriptionTable> conflictColumns,
    _is.ColumnSelections<WebPushSubscriptionTable>? updateColumns,
    _is.WhereExpressionBuilder<WebPushSubscriptionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WebPushSubscription>(
      row,
      conflictColumns: conflictColumns(WebPushSubscription.t),
      updateColumns: updateColumns?.call(WebPushSubscription.t),
      updateWhere: updateWhere?.call(WebPushSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates all [WebPushSubscription]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WebPushSubscription>> update(
    _is.DatabaseSession session,
    List<WebPushSubscription> rows, {
    _is.ColumnSelections<WebPushSubscriptionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WebPushSubscription>(
      rows,
      columns: columns?.call(WebPushSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WebPushSubscription]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WebPushSubscription> updateRow(
    _is.DatabaseSession session,
    WebPushSubscription row, {
    _is.ColumnSelections<WebPushSubscriptionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WebPushSubscription>(
      row,
      columns: columns?.call(WebPushSubscription.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WebPushSubscription] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WebPushSubscription?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WebPushSubscriptionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WebPushSubscription>(
      id,
      columnValues: columnValues(WebPushSubscription.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WebPushSubscription]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WebPushSubscription>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WebPushSubscriptionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WebPushSubscriptionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WebPushSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<WebPushSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WebPushSubscription>(
      columnValues: columnValues(WebPushSubscription.t.updateTable),
      where: where(WebPushSubscription.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WebPushSubscription.t),
      orderByList: orderByList?.call(WebPushSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WebPushSubscription]s in the list and returns the deleted rows.
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
  Future<List<WebPushSubscription>> delete(
    _is.DatabaseSession session,
    List<WebPushSubscription> rows, {
    _is.OrderByBuilder<WebPushSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<WebPushSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WebPushSubscription>(
      rows,
      orderBy: orderBy?.call(WebPushSubscription.t),
      orderByList: orderByList?.call(WebPushSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WebPushSubscription].
  Future<WebPushSubscription> deleteRow(
    _is.DatabaseSession session,
    WebPushSubscription row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WebPushSubscription>(
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
  Future<List<WebPushSubscription>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WebPushSubscriptionTable> where,
    _is.OrderByBuilder<WebPushSubscriptionTable>? orderBy,
    _is.OrderByListBuilder<WebPushSubscriptionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WebPushSubscription>(
      where: where(WebPushSubscription.t),
      orderBy: orderBy?.call(WebPushSubscription.t),
      orderByList: orderByList?.call(WebPushSubscription.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WebPushSubscriptionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WebPushSubscription>(
      where: where?.call(WebPushSubscription.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WebPushSubscription] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WebPushSubscriptionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WebPushSubscription>(
      where: where(WebPushSubscription.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
