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

abstract class ResearchArticle
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ResearchArticle._({
    this.id,
    required this.slug,
    required this.latestVersion,
    this.publishedVersion,
  });

  factory ResearchArticle({
    int? id,
    required String slug,
    required int latestVersion,
    int? publishedVersion,
  }) = _ResearchArticleImpl;

  factory ResearchArticle.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchArticle(
      id: jsonSerialization['id'] as int?,
      slug: jsonSerialization['slug'] as String,
      latestVersion: jsonSerialization['latestVersion'] as int,
      publishedVersion: jsonSerialization['publishedVersion'] as int?,
    );
  }

  static final t = ResearchArticleTable();

  static const db = ResearchArticleRepository._();

  @override
  int? id;

  String slug;

  int latestVersion;

  int? publishedVersion;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ResearchArticle]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ResearchArticle copyWith({
    int? id,
    String? slug,
    int? latestVersion,
    int? publishedVersion,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchArticle',
      if (id != null) 'id': id,
      'slug': slug,
      'latestVersion': latestVersion,
      if (publishedVersion != null) 'publishedVersion': publishedVersion,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchArticle',
      if (id != null) 'id': id,
      'slug': slug,
      'latestVersion': latestVersion,
      if (publishedVersion != null) 'publishedVersion': publishedVersion,
    };
  }

  static ResearchArticleInclude include() {
    return ResearchArticleInclude._();
  }

  static ResearchArticleIncludeList includeList({
    _is.WhereExpressionBuilder<ResearchArticleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchArticleTable>? orderBy,
    _is.OrderByListBuilder<ResearchArticleTable>? orderByList,
    ResearchArticleInclude? include,
  }) {
    return ResearchArticleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchArticle.t),
      orderByList: orderByList?.call(ResearchArticle.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchArticleImpl extends ResearchArticle {
  _ResearchArticleImpl({
    int? id,
    required String slug,
    required int latestVersion,
    int? publishedVersion,
  }) : super._(
         id: id,
         slug: slug,
         latestVersion: latestVersion,
         publishedVersion: publishedVersion,
       );

  /// Returns a shallow copy of this [ResearchArticle]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ResearchArticle copyWith({
    Object? id = _Undefined,
    String? slug,
    int? latestVersion,
    Object? publishedVersion = _Undefined,
  }) {
    return ResearchArticle(
      id: id is int? ? id : this.id,
      slug: slug ?? this.slug,
      latestVersion: latestVersion ?? this.latestVersion,
      publishedVersion: publishedVersion is int?
          ? publishedVersion
          : this.publishedVersion,
    );
  }
}

class ResearchArticleUpdateTable extends _is.UpdateTable<ResearchArticleTable> {
  ResearchArticleUpdateTable(super.table);

  _is.ColumnValue<String, String> slug(String value) => _is.ColumnValue(
    table.slug,
    value,
  );

  _is.ColumnValue<int, int> latestVersion(int value) => _is.ColumnValue(
    table.latestVersion,
    value,
  );

  _is.ColumnValue<int, int> publishedVersion(int? value) => _is.ColumnValue(
    table.publishedVersion,
    value,
  );
}

class ResearchArticleTable extends _is.Table<int?> {
  ResearchArticleTable({super.tableRelation})
    : super(tableName: 'research_article') {
    updateTable = ResearchArticleUpdateTable(this);
    slug = _is.ColumnString(
      'slug',
      this,
    );
    latestVersion = _is.ColumnInt(
      'latestVersion',
      this,
    );
    publishedVersion = _is.ColumnInt(
      'publishedVersion',
      this,
    );
  }

  late final ResearchArticleUpdateTable updateTable;

  late final _is.ColumnString slug;

  late final _is.ColumnInt latestVersion;

  late final _is.ColumnInt publishedVersion;

  @override
  List<_is.Column> get columns => [
    id,
    slug,
    latestVersion,
    publishedVersion,
  ];
}

class ResearchArticleInclude extends _is.IncludeObject {
  ResearchArticleInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ResearchArticle.t;
}

class ResearchArticleIncludeList extends _is.IncludeList {
  ResearchArticleIncludeList._({
    _is.WhereExpressionBuilder<ResearchArticleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ResearchArticle.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ResearchArticle.t;
}

class ResearchArticleRepository {
  const ResearchArticleRepository._();

  /// Returns a list of [ResearchArticle]s matching the given query parameters.
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
  Future<List<ResearchArticle>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchArticleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchArticleTable>? orderBy,
    _is.OrderByListBuilder<ResearchArticleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ResearchArticle>(
      where: where?.call(ResearchArticle.t),
      orderBy: orderBy?.call(ResearchArticle.t),
      orderByList: orderByList?.call(ResearchArticle.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ResearchArticle] matching the given query parameters.
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
  Future<ResearchArticle?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchArticleTable>? where,
    int? offset,
    _is.OrderByBuilder<ResearchArticleTable>? orderBy,
    _is.OrderByListBuilder<ResearchArticleTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ResearchArticle>(
      where: where?.call(ResearchArticle.t),
      orderBy: orderBy?.call(ResearchArticle.t),
      orderByList: orderByList?.call(ResearchArticle.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ResearchArticle] by its [id] or null if no such row exists.
  Future<ResearchArticle?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ResearchArticle>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ResearchArticle]s in the list and returns the inserted rows.
  ///
  /// The returned [ResearchArticle]s will have their `id` fields set.
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
  Future<List<ResearchArticle>> insert(
    _is.DatabaseSession session,
    List<ResearchArticle> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ResearchArticle>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ResearchArticle] and returns the inserted row.
  ///
  /// The returned [ResearchArticle] will have its `id` field set.
  Future<ResearchArticle> insertRow(
    _is.DatabaseSession session,
    ResearchArticle row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ResearchArticle>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ResearchArticle]s in the list and returns the resulting rows.
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
  /// The returned [ResearchArticle]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchArticle>> upsert(
    _is.DatabaseSession session,
    List<ResearchArticle> rows, {
    required _is.ColumnSelections<ResearchArticleTable> conflictColumns,
    _is.ColumnSelections<ResearchArticleTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchArticleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ResearchArticle>(
      rows,
      conflictColumns: conflictColumns(ResearchArticle.t),
      updateColumns: updateColumns?.call(ResearchArticle.t),
      updateWhere: updateWhere?.call(ResearchArticle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ResearchArticle] and returns the resulting row.
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
  /// The returned [ResearchArticle] will have its `id` field set.
  Future<ResearchArticle?> upsertRow(
    _is.DatabaseSession session,
    ResearchArticle row, {
    required _is.ColumnSelections<ResearchArticleTable> conflictColumns,
    _is.ColumnSelections<ResearchArticleTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchArticleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ResearchArticle>(
      row,
      conflictColumns: conflictColumns(ResearchArticle.t),
      updateColumns: updateColumns?.call(ResearchArticle.t),
      updateWhere: updateWhere?.call(ResearchArticle.t),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchArticle]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchArticle>> update(
    _is.DatabaseSession session,
    List<ResearchArticle> rows, {
    _is.ColumnSelections<ResearchArticleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ResearchArticle>(
      rows,
      columns: columns?.call(ResearchArticle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ResearchArticle]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ResearchArticle> updateRow(
    _is.DatabaseSession session,
    ResearchArticle row, {
    _is.ColumnSelections<ResearchArticleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ResearchArticle>(
      row,
      columns: columns?.call(ResearchArticle.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ResearchArticle] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ResearchArticle?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ResearchArticleUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ResearchArticle>(
      id,
      columnValues: columnValues(ResearchArticle.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchArticle]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchArticle>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ResearchArticleUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ResearchArticleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchArticleTable>? orderBy,
    _is.OrderByListBuilder<ResearchArticleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ResearchArticle>(
      columnValues: columnValues(ResearchArticle.t.updateTable),
      where: where(ResearchArticle.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchArticle.t),
      orderByList: orderByList?.call(ResearchArticle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ResearchArticle]s in the list and returns the deleted rows.
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
  Future<List<ResearchArticle>> delete(
    _is.DatabaseSession session,
    List<ResearchArticle> rows, {
    _is.OrderByBuilder<ResearchArticleTable>? orderBy,
    _is.OrderByListBuilder<ResearchArticleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ResearchArticle>(
      rows,
      orderBy: orderBy?.call(ResearchArticle.t),
      orderByList: orderByList?.call(ResearchArticle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ResearchArticle].
  Future<ResearchArticle> deleteRow(
    _is.DatabaseSession session,
    ResearchArticle row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ResearchArticle>(
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
  Future<List<ResearchArticle>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchArticleTable> where,
    _is.OrderByBuilder<ResearchArticleTable>? orderBy,
    _is.OrderByListBuilder<ResearchArticleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ResearchArticle>(
      where: where(ResearchArticle.t),
      orderBy: orderBy?.call(ResearchArticle.t),
      orderByList: orderByList?.call(ResearchArticle.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchArticleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ResearchArticle>(
      where: where?.call(ResearchArticle.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ResearchArticle] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchArticleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ResearchArticle>(
      where: where(ResearchArticle.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
