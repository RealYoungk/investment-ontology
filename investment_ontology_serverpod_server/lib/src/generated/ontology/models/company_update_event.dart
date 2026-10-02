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

abstract class CompanyUpdateEvent
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  CompanyUpdateEvent._({
    this.id,
    required this.corpCode,
    required this.receipt,
    required this.title,
    required this.url,
    required this.publishedAt,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  factory CompanyUpdateEvent({
    int? id,
    required String corpCode,
    required String receipt,
    required String title,
    required String url,
    required DateTime publishedAt,
    DateTime? discoveredAt,
  }) = _CompanyUpdateEventImpl;

  factory CompanyUpdateEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyUpdateEvent(
      id: jsonSerialization['id'] as int?,
      corpCode: jsonSerialization['corpCode'] as String,
      receipt: jsonSerialization['receipt'] as String,
      title: jsonSerialization['title'] as String,
      url: jsonSerialization['url'] as String,
      publishedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['publishedAt'],
      ),
      discoveredAt: jsonSerialization['discoveredAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['discoveredAt'],
            ),
    );
  }

  static final t = CompanyUpdateEventTable();

  static const db = CompanyUpdateEventRepository._();

  @override
  int? id;

  String corpCode;

  String receipt;

  String title;

  String url;

  DateTime publishedAt;

  DateTime discoveredAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [CompanyUpdateEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyUpdateEvent copyWith({
    int? id,
    String? corpCode,
    String? receipt,
    String? title,
    String? url,
    DateTime? publishedAt,
    DateTime? discoveredAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyUpdateEvent',
      if (id != null) 'id': id,
      'corpCode': corpCode,
      'receipt': receipt,
      'title': title,
      'url': url,
      'publishedAt': publishedAt.toJson(),
      'discoveredAt': discoveredAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static CompanyUpdateEventInclude include() {
    return CompanyUpdateEventInclude._();
  }

  static CompanyUpdateEventIncludeList includeList({
    _is.WhereExpressionBuilder<CompanyUpdateEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CompanyUpdateEventTable>? orderBy,
    _is.OrderByListBuilder<CompanyUpdateEventTable>? orderByList,
    CompanyUpdateEventInclude? include,
  }) {
    return CompanyUpdateEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CompanyUpdateEvent.t),
      orderByList: orderByList?.call(CompanyUpdateEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyUpdateEventImpl extends CompanyUpdateEvent {
  _CompanyUpdateEventImpl({
    int? id,
    required String corpCode,
    required String receipt,
    required String title,
    required String url,
    required DateTime publishedAt,
    DateTime? discoveredAt,
  }) : super._(
         id: id,
         corpCode: corpCode,
         receipt: receipt,
         title: title,
         url: url,
         publishedAt: publishedAt,
         discoveredAt: discoveredAt,
       );

  /// Returns a shallow copy of this [CompanyUpdateEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyUpdateEvent copyWith({
    Object? id = _Undefined,
    String? corpCode,
    String? receipt,
    String? title,
    String? url,
    DateTime? publishedAt,
    DateTime? discoveredAt,
  }) {
    return CompanyUpdateEvent(
      id: id is int? ? id : this.id,
      corpCode: corpCode ?? this.corpCode,
      receipt: receipt ?? this.receipt,
      title: title ?? this.title,
      url: url ?? this.url,
      publishedAt: publishedAt ?? this.publishedAt,
      discoveredAt: discoveredAt ?? this.discoveredAt,
    );
  }
}

class CompanyUpdateEventUpdateTable
    extends _is.UpdateTable<CompanyUpdateEventTable> {
  CompanyUpdateEventUpdateTable(super.table);

  _is.ColumnValue<String, String> corpCode(String value) => _is.ColumnValue(
    table.corpCode,
    value,
  );

  _is.ColumnValue<String, String> receipt(String value) => _is.ColumnValue(
    table.receipt,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> url(String value) => _is.ColumnValue(
    table.url,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> publishedAt(DateTime value) =>
      _is.ColumnValue(
        table.publishedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> discoveredAt(DateTime value) =>
      _is.ColumnValue(
        table.discoveredAt,
        value,
      );
}

class CompanyUpdateEventTable extends _is.Table<int?> {
  CompanyUpdateEventTable({super.tableRelation})
    : super(tableName: 'company_update_event') {
    updateTable = CompanyUpdateEventUpdateTable(this);
    corpCode = _is.ColumnString(
      'corpCode',
      this,
    );
    receipt = _is.ColumnString(
      'receipt',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    url = _is.ColumnString(
      'url',
      this,
    );
    publishedAt = _is.ColumnDateTime(
      'publishedAt',
      this,
    );
    discoveredAt = _is.ColumnDateTime(
      'discoveredAt',
      this,
      hasDefault: true,
    );
  }

  late final CompanyUpdateEventUpdateTable updateTable;

  late final _is.ColumnString corpCode;

  late final _is.ColumnString receipt;

  late final _is.ColumnString title;

  late final _is.ColumnString url;

  late final _is.ColumnDateTime publishedAt;

  late final _is.ColumnDateTime discoveredAt;

  @override
  List<_is.Column> get columns => [
    id,
    corpCode,
    receipt,
    title,
    url,
    publishedAt,
    discoveredAt,
  ];
}

class CompanyUpdateEventInclude extends _is.IncludeObject {
  CompanyUpdateEventInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => CompanyUpdateEvent.t;
}

class CompanyUpdateEventIncludeList extends _is.IncludeList {
  CompanyUpdateEventIncludeList._({
    _is.WhereExpressionBuilder<CompanyUpdateEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CompanyUpdateEvent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => CompanyUpdateEvent.t;
}

class CompanyUpdateEventRepository {
  const CompanyUpdateEventRepository._();

  /// Returns a list of [CompanyUpdateEvent]s matching the given query parameters.
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
  Future<List<CompanyUpdateEvent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CompanyUpdateEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CompanyUpdateEventTable>? orderBy,
    _is.OrderByListBuilder<CompanyUpdateEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CompanyUpdateEvent>(
      where: where?.call(CompanyUpdateEvent.t),
      orderBy: orderBy?.call(CompanyUpdateEvent.t),
      orderByList: orderByList?.call(CompanyUpdateEvent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CompanyUpdateEvent] matching the given query parameters.
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
  Future<CompanyUpdateEvent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CompanyUpdateEventTable>? where,
    int? offset,
    _is.OrderByBuilder<CompanyUpdateEventTable>? orderBy,
    _is.OrderByListBuilder<CompanyUpdateEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CompanyUpdateEvent>(
      where: where?.call(CompanyUpdateEvent.t),
      orderBy: orderBy?.call(CompanyUpdateEvent.t),
      orderByList: orderByList?.call(CompanyUpdateEvent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CompanyUpdateEvent] by its [id] or null if no such row exists.
  Future<CompanyUpdateEvent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CompanyUpdateEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CompanyUpdateEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [CompanyUpdateEvent]s will have their `id` fields set.
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
  Future<List<CompanyUpdateEvent>> insert(
    _is.DatabaseSession session,
    List<CompanyUpdateEvent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CompanyUpdateEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CompanyUpdateEvent] and returns the inserted row.
  ///
  /// The returned [CompanyUpdateEvent] will have its `id` field set.
  Future<CompanyUpdateEvent> insertRow(
    _is.DatabaseSession session,
    CompanyUpdateEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<CompanyUpdateEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CompanyUpdateEvent]s in the list and returns the resulting rows.
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
  /// The returned [CompanyUpdateEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CompanyUpdateEvent>> upsert(
    _is.DatabaseSession session,
    List<CompanyUpdateEvent> rows, {
    required _is.ColumnSelections<CompanyUpdateEventTable> conflictColumns,
    _is.ColumnSelections<CompanyUpdateEventTable>? updateColumns,
    _is.WhereExpressionBuilder<CompanyUpdateEventTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CompanyUpdateEvent>(
      rows,
      conflictColumns: conflictColumns(CompanyUpdateEvent.t),
      updateColumns: updateColumns?.call(CompanyUpdateEvent.t),
      updateWhere: updateWhere?.call(CompanyUpdateEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CompanyUpdateEvent] and returns the resulting row.
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
  /// The returned [CompanyUpdateEvent] will have its `id` field set.
  Future<CompanyUpdateEvent?> upsertRow(
    _is.DatabaseSession session,
    CompanyUpdateEvent row, {
    required _is.ColumnSelections<CompanyUpdateEventTable> conflictColumns,
    _is.ColumnSelections<CompanyUpdateEventTable>? updateColumns,
    _is.WhereExpressionBuilder<CompanyUpdateEventTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CompanyUpdateEvent>(
      row,
      conflictColumns: conflictColumns(CompanyUpdateEvent.t),
      updateColumns: updateColumns?.call(CompanyUpdateEvent.t),
      updateWhere: updateWhere?.call(CompanyUpdateEvent.t),
      transaction: transaction,
    );
  }

  /// Updates all [CompanyUpdateEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CompanyUpdateEvent>> update(
    _is.DatabaseSession session,
    List<CompanyUpdateEvent> rows, {
    _is.ColumnSelections<CompanyUpdateEventTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CompanyUpdateEvent>(
      rows,
      columns: columns?.call(CompanyUpdateEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CompanyUpdateEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CompanyUpdateEvent> updateRow(
    _is.DatabaseSession session,
    CompanyUpdateEvent row, {
    _is.ColumnSelections<CompanyUpdateEventTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<CompanyUpdateEvent>(
      row,
      columns: columns?.call(CompanyUpdateEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CompanyUpdateEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CompanyUpdateEvent?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CompanyUpdateEventUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<CompanyUpdateEvent>(
      id,
      columnValues: columnValues(CompanyUpdateEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CompanyUpdateEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CompanyUpdateEvent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CompanyUpdateEventUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<CompanyUpdateEventTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CompanyUpdateEventTable>? orderBy,
    _is.OrderByListBuilder<CompanyUpdateEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CompanyUpdateEvent>(
      columnValues: columnValues(CompanyUpdateEvent.t.updateTable),
      where: where(CompanyUpdateEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CompanyUpdateEvent.t),
      orderByList: orderByList?.call(CompanyUpdateEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CompanyUpdateEvent]s in the list and returns the deleted rows.
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
  Future<List<CompanyUpdateEvent>> delete(
    _is.DatabaseSession session,
    List<CompanyUpdateEvent> rows, {
    _is.OrderByBuilder<CompanyUpdateEventTable>? orderBy,
    _is.OrderByListBuilder<CompanyUpdateEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CompanyUpdateEvent>(
      rows,
      orderBy: orderBy?.call(CompanyUpdateEvent.t),
      orderByList: orderByList?.call(CompanyUpdateEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CompanyUpdateEvent].
  Future<CompanyUpdateEvent> deleteRow(
    _is.DatabaseSession session,
    CompanyUpdateEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CompanyUpdateEvent>(
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
  Future<List<CompanyUpdateEvent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CompanyUpdateEventTable> where,
    _is.OrderByBuilder<CompanyUpdateEventTable>? orderBy,
    _is.OrderByListBuilder<CompanyUpdateEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CompanyUpdateEvent>(
      where: where(CompanyUpdateEvent.t),
      orderBy: orderBy?.call(CompanyUpdateEvent.t),
      orderByList: orderByList?.call(CompanyUpdateEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CompanyUpdateEventTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CompanyUpdateEvent>(
      where: where?.call(CompanyUpdateEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CompanyUpdateEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CompanyUpdateEventTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CompanyUpdateEvent>(
      where: where(CompanyUpdateEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
