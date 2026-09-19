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

/// 테마: 사용자가 직접 정의하는 투자 주제 (예: 2차전지, AI 반도체). 5단계.
abstract class InvestmentTheme
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  InvestmentTheme._({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestmentTheme({
    int? id,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InvestmentThemeImpl;

  factory InvestmentTheme.fromJson(Map<String, dynamic> jsonSerialization) {
    return InvestmentTheme(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = InvestmentThemeTable();

  static const db = InvestmentThemeRepository._();

  @override
  int? id;

  String name;

  String? description;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [InvestmentTheme]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  InvestmentTheme copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvestmentTheme',
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InvestmentTheme',
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static InvestmentThemeInclude include() {
    return InvestmentThemeInclude._();
  }

  static InvestmentThemeIncludeList includeList({
    _is.WhereExpressionBuilder<InvestmentThemeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InvestmentThemeTable>? orderBy,
    _is.OrderByListBuilder<InvestmentThemeTable>? orderByList,
    InvestmentThemeInclude? include,
  }) {
    return InvestmentThemeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InvestmentTheme.t),
      orderByList: orderByList?.call(InvestmentTheme.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InvestmentThemeImpl extends InvestmentTheme {
  _InvestmentThemeImpl({
    int? id,
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         description: description,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [InvestmentTheme]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  InvestmentTheme copyWith({
    Object? id = _Undefined,
    String? name,
    Object? description = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentTheme(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InvestmentThemeUpdateTable extends _is.UpdateTable<InvestmentThemeTable> {
  InvestmentThemeUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> description(String? value) => _is.ColumnValue(
    table.description,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class InvestmentThemeTable extends _is.Table<int?> {
  InvestmentThemeTable({super.tableRelation}) : super(tableName: 'theme') {
    updateTable = InvestmentThemeUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    description = _is.ColumnString(
      'description',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final InvestmentThemeUpdateTable updateTable;

  late final _is.ColumnString name;

  late final _is.ColumnString description;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
}

class InvestmentThemeInclude extends _is.IncludeObject {
  InvestmentThemeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => InvestmentTheme.t;
}

class InvestmentThemeIncludeList extends _is.IncludeList {
  InvestmentThemeIncludeList._({
    _is.WhereExpressionBuilder<InvestmentThemeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(InvestmentTheme.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => InvestmentTheme.t;
}

class InvestmentThemeRepository {
  const InvestmentThemeRepository._();

  /// Returns a list of [InvestmentTheme]s matching the given query parameters.
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
  Future<List<InvestmentTheme>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InvestmentThemeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InvestmentThemeTable>? orderBy,
    _is.OrderByListBuilder<InvestmentThemeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<InvestmentTheme>(
      where: where?.call(InvestmentTheme.t),
      orderBy: orderBy?.call(InvestmentTheme.t),
      orderByList: orderByList?.call(InvestmentTheme.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [InvestmentTheme] matching the given query parameters.
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
  Future<InvestmentTheme?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InvestmentThemeTable>? where,
    int? offset,
    _is.OrderByBuilder<InvestmentThemeTable>? orderBy,
    _is.OrderByListBuilder<InvestmentThemeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<InvestmentTheme>(
      where: where?.call(InvestmentTheme.t),
      orderBy: orderBy?.call(InvestmentTheme.t),
      orderByList: orderByList?.call(InvestmentTheme.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [InvestmentTheme] by its [id] or null if no such row exists.
  Future<InvestmentTheme?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<InvestmentTheme>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [InvestmentTheme]s in the list and returns the inserted rows.
  ///
  /// The returned [InvestmentTheme]s will have their `id` fields set.
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
  Future<List<InvestmentTheme>> insert(
    _is.DatabaseSession session,
    List<InvestmentTheme> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<InvestmentTheme>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [InvestmentTheme] and returns the inserted row.
  ///
  /// The returned [InvestmentTheme] will have its `id` field set.
  Future<InvestmentTheme> insertRow(
    _is.DatabaseSession session,
    InvestmentTheme row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<InvestmentTheme>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [InvestmentTheme]s in the list and returns the resulting rows.
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
  /// The returned [InvestmentTheme]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InvestmentTheme>> upsert(
    _is.DatabaseSession session,
    List<InvestmentTheme> rows, {
    required _is.ColumnSelections<InvestmentThemeTable> conflictColumns,
    _is.ColumnSelections<InvestmentThemeTable>? updateColumns,
    _is.WhereExpressionBuilder<InvestmentThemeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<InvestmentTheme>(
      rows,
      conflictColumns: conflictColumns(InvestmentTheme.t),
      updateColumns: updateColumns?.call(InvestmentTheme.t),
      updateWhere: updateWhere?.call(InvestmentTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [InvestmentTheme] and returns the resulting row.
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
  /// The returned [InvestmentTheme] will have its `id` field set.
  Future<InvestmentTheme?> upsertRow(
    _is.DatabaseSession session,
    InvestmentTheme row, {
    required _is.ColumnSelections<InvestmentThemeTable> conflictColumns,
    _is.ColumnSelections<InvestmentThemeTable>? updateColumns,
    _is.WhereExpressionBuilder<InvestmentThemeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<InvestmentTheme>(
      row,
      conflictColumns: conflictColumns(InvestmentTheme.t),
      updateColumns: updateColumns?.call(InvestmentTheme.t),
      updateWhere: updateWhere?.call(InvestmentTheme.t),
      transaction: transaction,
    );
  }

  /// Updates all [InvestmentTheme]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InvestmentTheme>> update(
    _is.DatabaseSession session,
    List<InvestmentTheme> rows, {
    _is.ColumnSelections<InvestmentThemeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<InvestmentTheme>(
      rows,
      columns: columns?.call(InvestmentTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [InvestmentTheme]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<InvestmentTheme> updateRow(
    _is.DatabaseSession session,
    InvestmentTheme row, {
    _is.ColumnSelections<InvestmentThemeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<InvestmentTheme>(
      row,
      columns: columns?.call(InvestmentTheme.t),
      transaction: transaction,
    );
  }

  /// Updates a single [InvestmentTheme] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<InvestmentTheme?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<InvestmentThemeUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<InvestmentTheme>(
      id,
      columnValues: columnValues(InvestmentTheme.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [InvestmentTheme]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<InvestmentTheme>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<InvestmentThemeUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<InvestmentThemeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<InvestmentThemeTable>? orderBy,
    _is.OrderByListBuilder<InvestmentThemeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<InvestmentTheme>(
      columnValues: columnValues(InvestmentTheme.t.updateTable),
      where: where(InvestmentTheme.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(InvestmentTheme.t),
      orderByList: orderByList?.call(InvestmentTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [InvestmentTheme]s in the list and returns the deleted rows.
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
  Future<List<InvestmentTheme>> delete(
    _is.DatabaseSession session,
    List<InvestmentTheme> rows, {
    _is.OrderByBuilder<InvestmentThemeTable>? orderBy,
    _is.OrderByListBuilder<InvestmentThemeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<InvestmentTheme>(
      rows,
      orderBy: orderBy?.call(InvestmentTheme.t),
      orderByList: orderByList?.call(InvestmentTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [InvestmentTheme].
  Future<InvestmentTheme> deleteRow(
    _is.DatabaseSession session,
    InvestmentTheme row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<InvestmentTheme>(
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
  Future<List<InvestmentTheme>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InvestmentThemeTable> where,
    _is.OrderByBuilder<InvestmentThemeTable>? orderBy,
    _is.OrderByListBuilder<InvestmentThemeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<InvestmentTheme>(
      where: where(InvestmentTheme.t),
      orderBy: orderBy?.call(InvestmentTheme.t),
      orderByList: orderByList?.call(InvestmentTheme.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<InvestmentThemeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<InvestmentTheme>(
      where: where?.call(InvestmentTheme.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [InvestmentTheme] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<InvestmentThemeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<InvestmentTheme>(
      where: where(InvestmentTheme.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
