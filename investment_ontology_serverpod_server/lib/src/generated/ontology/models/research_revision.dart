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

abstract class ResearchRevision
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ResearchRevision._({
    this.id,
    required this.articleId,
    required this.version,
    required this.title,
    required this.summary,
    required this.ticker,
    required this.market,
    required this.content,
    required this.format,
    required this.searchText,
    required this.dataAsOf,
    this.publishedAt,
    required this.createdAt,
    required this.note,
    required this.legacy,
  });

  factory ResearchRevision({
    int? id,
    required int articleId,
    required int version,
    required String title,
    required String summary,
    required String ticker,
    required String market,
    required String content,
    required String format,
    required String searchText,
    required DateTime dataAsOf,
    DateTime? publishedAt,
    required DateTime createdAt,
    required String note,
    required bool legacy,
  }) = _ResearchRevisionImpl;

  factory ResearchRevision.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchRevision(
      id: jsonSerialization['id'] as int?,
      articleId: jsonSerialization['articleId'] as int,
      version: jsonSerialization['version'] as int,
      title: jsonSerialization['title'] as String,
      summary: jsonSerialization['summary'] as String,
      ticker: jsonSerialization['ticker'] as String,
      market: jsonSerialization['market'] as String,
      content: jsonSerialization['content'] as String,
      format: jsonSerialization['format'] as String,
      searchText: jsonSerialization['searchText'] as String,
      dataAsOf: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['dataAsOf'],
      ),
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      note: jsonSerialization['note'] as String,
      legacy: _is.BoolJsonExtension.fromJson(jsonSerialization['legacy']),
    );
  }

  static final t = ResearchRevisionTable();

  static const db = ResearchRevisionRepository._();

  @override
  int? id;

  int articleId;

  int version;

  String title;

  String summary;

  String ticker;

  String market;

  String content;

  String format;

  String searchText;

  DateTime dataAsOf;

  DateTime? publishedAt;

  DateTime createdAt;

  String note;

  bool legacy;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ResearchRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ResearchRevision copyWith({
    int? id,
    int? articleId,
    int? version,
    String? title,
    String? summary,
    String? ticker,
    String? market,
    String? content,
    String? format,
    String? searchText,
    DateTime? dataAsOf,
    DateTime? publishedAt,
    DateTime? createdAt,
    String? note,
    bool? legacy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchRevision',
      if (id != null) 'id': id,
      'articleId': articleId,
      'version': version,
      'title': title,
      'summary': summary,
      'ticker': ticker,
      'market': market,
      'content': content,
      'format': format,
      'searchText': searchText,
      'dataAsOf': dataAsOf.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'note': note,
      'legacy': legacy,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchRevision',
      if (id != null) 'id': id,
      'articleId': articleId,
      'version': version,
      'title': title,
      'summary': summary,
      'ticker': ticker,
      'market': market,
      'content': content,
      'format': format,
      'searchText': searchText,
      'dataAsOf': dataAsOf.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'note': note,
      'legacy': legacy,
    };
  }

  static ResearchRevisionInclude include() {
    return ResearchRevisionInclude._();
  }

  static ResearchRevisionIncludeList includeList({
    _is.WhereExpressionBuilder<ResearchRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchRevisionTable>? orderBy,
    _is.OrderByListBuilder<ResearchRevisionTable>? orderByList,
    ResearchRevisionInclude? include,
  }) {
    return ResearchRevisionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchRevision.t),
      orderByList: orderByList?.call(ResearchRevision.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchRevisionImpl extends ResearchRevision {
  _ResearchRevisionImpl({
    int? id,
    required int articleId,
    required int version,
    required String title,
    required String summary,
    required String ticker,
    required String market,
    required String content,
    required String format,
    required String searchText,
    required DateTime dataAsOf,
    DateTime? publishedAt,
    required DateTime createdAt,
    required String note,
    required bool legacy,
  }) : super._(
         id: id,
         articleId: articleId,
         version: version,
         title: title,
         summary: summary,
         ticker: ticker,
         market: market,
         content: content,
         format: format,
         searchText: searchText,
         dataAsOf: dataAsOf,
         publishedAt: publishedAt,
         createdAt: createdAt,
         note: note,
         legacy: legacy,
       );

  /// Returns a shallow copy of this [ResearchRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ResearchRevision copyWith({
    Object? id = _Undefined,
    int? articleId,
    int? version,
    String? title,
    String? summary,
    String? ticker,
    String? market,
    String? content,
    String? format,
    String? searchText,
    DateTime? dataAsOf,
    Object? publishedAt = _Undefined,
    DateTime? createdAt,
    String? note,
    bool? legacy,
  }) {
    return ResearchRevision(
      id: id is int? ? id : this.id,
      articleId: articleId ?? this.articleId,
      version: version ?? this.version,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      ticker: ticker ?? this.ticker,
      market: market ?? this.market,
      content: content ?? this.content,
      format: format ?? this.format,
      searchText: searchText ?? this.searchText,
      dataAsOf: dataAsOf ?? this.dataAsOf,
      publishedAt: publishedAt is DateTime? ? publishedAt : this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      legacy: legacy ?? this.legacy,
    );
  }
}

class ResearchRevisionUpdateTable
    extends _is.UpdateTable<ResearchRevisionTable> {
  ResearchRevisionUpdateTable(super.table);

  _is.ColumnValue<int, int> articleId(int value) => _is.ColumnValue(
    table.articleId,
    value,
  );

  _is.ColumnValue<int, int> version(int value) => _is.ColumnValue(
    table.version,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> summary(String value) => _is.ColumnValue(
    table.summary,
    value,
  );

  _is.ColumnValue<String, String> ticker(String value) => _is.ColumnValue(
    table.ticker,
    value,
  );

  _is.ColumnValue<String, String> market(String value) => _is.ColumnValue(
    table.market,
    value,
  );

  _is.ColumnValue<String, String> content(String value) => _is.ColumnValue(
    table.content,
    value,
  );

  _is.ColumnValue<String, String> format(String value) => _is.ColumnValue(
    table.format,
    value,
  );

  _is.ColumnValue<String, String> searchText(String value) => _is.ColumnValue(
    table.searchText,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> dataAsOf(DateTime value) =>
      _is.ColumnValue(
        table.dataAsOf,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> publishedAt(DateTime? value) =>
      _is.ColumnValue(
        table.publishedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<String, String> note(String value) => _is.ColumnValue(
    table.note,
    value,
  );

  _is.ColumnValue<bool, bool> legacy(bool value) => _is.ColumnValue(
    table.legacy,
    value,
  );
}

class ResearchRevisionTable extends _is.Table<int?> {
  ResearchRevisionTable({super.tableRelation})
    : super(tableName: 'research_revision') {
    updateTable = ResearchRevisionUpdateTable(this);
    articleId = _is.ColumnInt(
      'articleId',
      this,
    );
    version = _is.ColumnInt(
      'version',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    summary = _is.ColumnString(
      'summary',
      this,
    );
    ticker = _is.ColumnString(
      'ticker',
      this,
    );
    market = _is.ColumnString(
      'market',
      this,
    );
    content = _is.ColumnString(
      'content',
      this,
    );
    format = _is.ColumnString(
      'format',
      this,
    );
    searchText = _is.ColumnString(
      'searchText',
      this,
    );
    dataAsOf = _is.ColumnDateTime(
      'dataAsOf',
      this,
    );
    publishedAt = _is.ColumnDateTime(
      'publishedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    note = _is.ColumnString(
      'note',
      this,
    );
    legacy = _is.ColumnBool(
      'legacy',
      this,
    );
  }

  late final ResearchRevisionUpdateTable updateTable;

  late final _is.ColumnInt articleId;

  late final _is.ColumnInt version;

  late final _is.ColumnString title;

  late final _is.ColumnString summary;

  late final _is.ColumnString ticker;

  late final _is.ColumnString market;

  late final _is.ColumnString content;

  late final _is.ColumnString format;

  late final _is.ColumnString searchText;

  late final _is.ColumnDateTime dataAsOf;

  late final _is.ColumnDateTime publishedAt;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnString note;

  late final _is.ColumnBool legacy;

  @override
  List<_is.Column> get columns => [
    id,
    articleId,
    version,
    title,
    summary,
    ticker,
    market,
    content,
    format,
    searchText,
    dataAsOf,
    publishedAt,
    createdAt,
    note,
    legacy,
  ];
}

class ResearchRevisionInclude extends _is.IncludeObject {
  ResearchRevisionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ResearchRevision.t;
}

class ResearchRevisionIncludeList extends _is.IncludeList {
  ResearchRevisionIncludeList._({
    _is.WhereExpressionBuilder<ResearchRevisionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ResearchRevision.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ResearchRevision.t;
}

class ResearchRevisionRepository {
  const ResearchRevisionRepository._();

  /// Returns a list of [ResearchRevision]s matching the given query parameters.
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
  Future<List<ResearchRevision>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchRevisionTable>? orderBy,
    _is.OrderByListBuilder<ResearchRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ResearchRevision>(
      where: where?.call(ResearchRevision.t),
      orderBy: orderBy?.call(ResearchRevision.t),
      orderByList: orderByList?.call(ResearchRevision.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ResearchRevision] matching the given query parameters.
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
  Future<ResearchRevision?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchRevisionTable>? where,
    int? offset,
    _is.OrderByBuilder<ResearchRevisionTable>? orderBy,
    _is.OrderByListBuilder<ResearchRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ResearchRevision>(
      where: where?.call(ResearchRevision.t),
      orderBy: orderBy?.call(ResearchRevision.t),
      orderByList: orderByList?.call(ResearchRevision.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ResearchRevision] by its [id] or null if no such row exists.
  Future<ResearchRevision?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ResearchRevision>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ResearchRevision]s in the list and returns the inserted rows.
  ///
  /// The returned [ResearchRevision]s will have their `id` fields set.
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
  Future<List<ResearchRevision>> insert(
    _is.DatabaseSession session,
    List<ResearchRevision> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ResearchRevision>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ResearchRevision] and returns the inserted row.
  ///
  /// The returned [ResearchRevision] will have its `id` field set.
  Future<ResearchRevision> insertRow(
    _is.DatabaseSession session,
    ResearchRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ResearchRevision>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ResearchRevision]s in the list and returns the resulting rows.
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
  /// The returned [ResearchRevision]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchRevision>> upsert(
    _is.DatabaseSession session,
    List<ResearchRevision> rows, {
    required _is.ColumnSelections<ResearchRevisionTable> conflictColumns,
    _is.ColumnSelections<ResearchRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchRevisionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ResearchRevision>(
      rows,
      conflictColumns: conflictColumns(ResearchRevision.t),
      updateColumns: updateColumns?.call(ResearchRevision.t),
      updateWhere: updateWhere?.call(ResearchRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ResearchRevision] and returns the resulting row.
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
  /// The returned [ResearchRevision] will have its `id` field set.
  Future<ResearchRevision?> upsertRow(
    _is.DatabaseSession session,
    ResearchRevision row, {
    required _is.ColumnSelections<ResearchRevisionTable> conflictColumns,
    _is.ColumnSelections<ResearchRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<ResearchRevisionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ResearchRevision>(
      row,
      conflictColumns: conflictColumns(ResearchRevision.t),
      updateColumns: updateColumns?.call(ResearchRevision.t),
      updateWhere: updateWhere?.call(ResearchRevision.t),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchRevision]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchRevision>> update(
    _is.DatabaseSession session,
    List<ResearchRevision> rows, {
    _is.ColumnSelections<ResearchRevisionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ResearchRevision>(
      rows,
      columns: columns?.call(ResearchRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ResearchRevision]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ResearchRevision> updateRow(
    _is.DatabaseSession session,
    ResearchRevision row, {
    _is.ColumnSelections<ResearchRevisionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ResearchRevision>(
      row,
      columns: columns?.call(ResearchRevision.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ResearchRevision] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ResearchRevision?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ResearchRevisionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ResearchRevision>(
      id,
      columnValues: columnValues(ResearchRevision.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ResearchRevision]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ResearchRevision>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ResearchRevisionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ResearchRevisionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ResearchRevisionTable>? orderBy,
    _is.OrderByListBuilder<ResearchRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ResearchRevision>(
      columnValues: columnValues(ResearchRevision.t.updateTable),
      where: where(ResearchRevision.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ResearchRevision.t),
      orderByList: orderByList?.call(ResearchRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ResearchRevision]s in the list and returns the deleted rows.
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
  Future<List<ResearchRevision>> delete(
    _is.DatabaseSession session,
    List<ResearchRevision> rows, {
    _is.OrderByBuilder<ResearchRevisionTable>? orderBy,
    _is.OrderByListBuilder<ResearchRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ResearchRevision>(
      rows,
      orderBy: orderBy?.call(ResearchRevision.t),
      orderByList: orderByList?.call(ResearchRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ResearchRevision].
  Future<ResearchRevision> deleteRow(
    _is.DatabaseSession session,
    ResearchRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ResearchRevision>(
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
  Future<List<ResearchRevision>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchRevisionTable> where,
    _is.OrderByBuilder<ResearchRevisionTable>? orderBy,
    _is.OrderByListBuilder<ResearchRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ResearchRevision>(
      where: where(ResearchRevision.t),
      orderBy: orderBy?.call(ResearchRevision.t),
      orderByList: orderByList?.call(ResearchRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ResearchRevisionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ResearchRevision>(
      where: where?.call(ResearchRevision.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ResearchRevision] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ResearchRevisionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ResearchRevision>(
      where: where(ResearchRevision.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
