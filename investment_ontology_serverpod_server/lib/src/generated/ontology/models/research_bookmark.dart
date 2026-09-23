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

abstract class ResearchBookmark
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ResearchBookmark._({
    this.id,
    required this.userId,
    required this.articleId,
  });

  factory ResearchBookmark({
    int? id,
    required String userId,
    required int articleId,
  }) = _ResearchBookmarkImpl;

  factory ResearchBookmark.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchBookmark(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      articleId: jsonSerialization['articleId'] as int,
    );
  }

  static final t = ResearchBookmarkTable();

  static const db = ResearchBookmarkRepository._();

  @override
  int? id;

  String userId;

  int articleId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ResearchBookmark]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ResearchBookmark copyWith({
    int? id,
    String? userId,
    int? articleId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchBookmark',
      if (id != null) 'id': id,
      'userId': userId,
      'articleId': articleId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchBookmark',
      if (id != null) 'id': id,
      'userId': userId,
      'articleId': articleId,
    };
  }

  static ResearchBookmarkInclude include() {
    return ResearchBookmarkInclude._();
  }

  static ResearchBookmarkIncludeList includeList({
    _is.WhereExpressionBuilder<ResearchBookmarkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchBookmarkTable>? orderBy,
    _is.OrderByListBuilder<ResearchBookmarkTable>? orderByList,
    ResearchBookmarkInclude? include,
  }) {
    return ResearchBookmarkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchBookmark.t),
      orderByList: orderByList?.call(ResearchBookmark.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchBookmarkImpl extends ResearchBookmark {
  _ResearchBookmarkImpl({
    int? id,
    required String userId,
    required int articleId,
  }) : super._(
         id: id,
         userId: userId,
         articleId: articleId,
       );

  /// Returns a shallow copy of this [ResearchBookmark]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ResearchBookmark copyWith({
    Object? id = _Undefined,
    String? userId,
    int? articleId,
  }) {
    return ResearchBookmark(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      articleId: articleId ?? this.articleId,
    );
  }
}

class ResearchBookmarkUpdateTable
    extends _is.UpdateTable<ResearchBookmarkTable> {
  ResearchBookmarkUpdateTable(super.table);

  _is.ColumnValue<String, String> userId(String value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<int, int> articleId(int value) => _is.ColumnValue(
    table.articleId,
    value,
  );
}

class ResearchBookmarkTable extends _is.Table<int?> {
  ResearchBookmarkTable({super.tableRelation})
    : super(tableName: 'research_bookmark') {
    updateTable = ResearchBookmarkUpdateTable(this);
    userId = _is.ColumnString(
      'userId',
      this,
    );
    articleId = _is.ColumnInt(
      'articleId',
      this,
    );
  }

  late final ResearchBookmarkUpdateTable updateTable;

  late final _is.ColumnString userId;

  late final _is.ColumnInt articleId;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    articleId,
  ];
}

class ResearchBookmarkInclude extends _is.IncludeObject {
  ResearchBookmarkInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ResearchBookmark.t;
}

class ResearchBookmarkIncludeList extends _is.IncludeList {
  ResearchBookmarkIncludeList._({
    _is.WhereExpressionBuilder<ResearchBookmarkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ResearchBookmark.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ResearchBookmark.t;
}

class ResearchBookmarkRepository {
  const ResearchBookmarkRepository._();

  /// Returns a list of [ResearchBookmark]s matching the given query parameters.
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
  Future<List<ResearchBookmark>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchBookmarkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchBookmarkTable>? orderBy,
    _is.OrderByListBuilder<ResearchBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ResearchBookmark>(
      where: where?.call(ResearchBookmark.t),
      orderBy: orderBy?.call(ResearchBookmark.t),
      orderByList: orderByList?.call(ResearchBookmark.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ResearchBookmark] matching the given query parameters.
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
  Future<ResearchBookmark?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchBookmarkTable>? where,
    int? offset,
    _is.OrderByBuilder<ResearchBookmarkTable>? orderBy,
    _is.OrderByListBuilder<ResearchBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ResearchBookmark>(
      where: where?.call(ResearchBookmark.t),
      orderBy: orderBy?.call(ResearchBookmark.t),
      orderByList: orderByList?.call(ResearchBookmark.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ResearchBookmark] by its [id] or null if no such row exists.
  Future<ResearchBookmark?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ResearchBookmark>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ResearchBookmark]s in the list and returns the inserted rows.
  ///
  /// The returned [ResearchBookmark]s will have their `id` fields set.
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
  Future<List<ResearchBookmark>> insert(
    _is.DatabaseSession session,
    List<ResearchBookmark> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ResearchBookmark>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ResearchBookmark] and returns the inserted row.
  ///
  /// The returned [ResearchBookmark] will have its `id` field set.
  Future<ResearchBookmark> insertRow(
    _is.DatabaseSession session,
    ResearchBookmark row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ResearchBookmark>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ResearchBookmark]s in the list and returns the resulting rows.
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
  /// The returned [ResearchBookmark]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchBookmark>> upsert(
    _is.DatabaseSession session,
    List<ResearchBookmark> rows, {
    required _is.ColumnSelections<ResearchBookmarkTable> conflictColumns,
    _is.ColumnSelections<ResearchBookmarkTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchBookmarkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ResearchBookmark>(
      rows,
      conflictColumns: conflictColumns(ResearchBookmark.t),
      updateColumns: updateColumns?.call(ResearchBookmark.t),
      updateWhere: updateWhere?.call(ResearchBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ResearchBookmark] and returns the resulting row.
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
  /// The returned [ResearchBookmark] will have its `id` field set.
  Future<ResearchBookmark?> upsertRow(
    _is.DatabaseSession session,
    ResearchBookmark row, {
    required _is.ColumnSelections<ResearchBookmarkTable> conflictColumns,
    _is.ColumnSelections<ResearchBookmarkTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchBookmarkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ResearchBookmark>(
      row,
      conflictColumns: conflictColumns(ResearchBookmark.t),
      updateColumns: updateColumns?.call(ResearchBookmark.t),
      updateWhere: updateWhere?.call(ResearchBookmark.t),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchBookmark]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchBookmark>> update(
    _is.DatabaseSession session,
    List<ResearchBookmark> rows, {
    _is.ColumnSelections<ResearchBookmarkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ResearchBookmark>(
      rows,
      columns: columns?.call(ResearchBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ResearchBookmark]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ResearchBookmark> updateRow(
    _is.DatabaseSession session,
    ResearchBookmark row, {
    _is.ColumnSelections<ResearchBookmarkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ResearchBookmark>(
      row,
      columns: columns?.call(ResearchBookmark.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ResearchBookmark] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ResearchBookmark?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ResearchBookmarkUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ResearchBookmark>(
      id,
      columnValues: columnValues(ResearchBookmark.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchBookmark]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchBookmark>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ResearchBookmarkUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ResearchBookmarkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchBookmarkTable>? orderBy,
    _is.OrderByListBuilder<ResearchBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ResearchBookmark>(
      columnValues: columnValues(ResearchBookmark.t.updateTable),
      where: where(ResearchBookmark.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchBookmark.t),
      orderByList: orderByList?.call(ResearchBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ResearchBookmark]s in the list and returns the deleted rows.
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
  Future<List<ResearchBookmark>> delete(
    _is.DatabaseSession session,
    List<ResearchBookmark> rows, {
    _is.OrderByBuilder<ResearchBookmarkTable>? orderBy,
    _is.OrderByListBuilder<ResearchBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ResearchBookmark>(
      rows,
      orderBy: orderBy?.call(ResearchBookmark.t),
      orderByList: orderByList?.call(ResearchBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ResearchBookmark].
  Future<ResearchBookmark> deleteRow(
    _is.DatabaseSession session,
    ResearchBookmark row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ResearchBookmark>(
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
  Future<List<ResearchBookmark>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchBookmarkTable> where,
    _is.OrderByBuilder<ResearchBookmarkTable>? orderBy,
    _is.OrderByListBuilder<ResearchBookmarkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ResearchBookmark>(
      where: where(ResearchBookmark.t),
      orderBy: orderBy?.call(ResearchBookmark.t),
      orderByList: orderByList?.call(ResearchBookmark.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchBookmarkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ResearchBookmark>(
      where: where?.call(ResearchBookmark.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ResearchBookmark] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchBookmarkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ResearchBookmark>(
      where: where(ResearchBookmark.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
