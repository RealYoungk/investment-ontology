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
import '../../ontology/models/api_provider.dart' as _ihrpaigz;

/// 수집 장부: 제공자별·날짜별 API 호출 수.
/// 여러 수집 작업이 같은 일일 한도를 나눠 쓰므로 작업(IngestJob)과 따로 날짜 기준으로 합산한다.
abstract class ApiCallUsage
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ApiCallUsage._({
    this.id,
    required this.provider,
    required this.day,
    int? calls,
  }) : calls = calls ?? 0;

  factory ApiCallUsage({
    int? id,
    required _ihrpaigz.ApiProvider provider,
    required String day,
    int? calls,
  }) = _ApiCallUsageImpl;

  factory ApiCallUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiCallUsage(
      id: jsonSerialization['id'] as int?,
      provider: _ihrpaigz.ApiProvider.fromJson(
        (jsonSerialization['provider'] as String),
      ),
      day: jsonSerialization['day'] as String,
      calls: jsonSerialization['calls'] as int?,
    );
  }

  static final t = ApiCallUsageTable();

  static const db = ApiCallUsageRepository._();

  @override
  int? id;

  _ihrpaigz.ApiProvider provider;

  /// 한도가 초기화되는 기준 날짜 (KST, YYYY-MM-DD)
  String day;

  int calls;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ApiCallUsage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ApiCallUsage copyWith({
    int? id,
    _ihrpaigz.ApiProvider? provider,
    String? day,
    int? calls,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiCallUsage',
      if (id != null) 'id': id,
      'provider': provider.toJson(),
      'day': day,
      'calls': calls,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ApiCallUsage',
      if (id != null) 'id': id,
      'provider': provider.toJson(),
      'day': day,
      'calls': calls,
    };
  }

  static ApiCallUsageInclude include() {
    return ApiCallUsageInclude._();
  }

  static ApiCallUsageIncludeList includeList({
    _is.WhereExpressionBuilder<ApiCallUsageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiCallUsageTable>? orderBy,
    _is.OrderByListBuilder<ApiCallUsageTable>? orderByList,
    ApiCallUsageInclude? include,
  }) {
    return ApiCallUsageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiCallUsage.t),
      orderByList: orderByList?.call(ApiCallUsage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiCallUsageImpl extends ApiCallUsage {
  _ApiCallUsageImpl({
    int? id,
    required _ihrpaigz.ApiProvider provider,
    required String day,
    int? calls,
  }) : super._(
         id: id,
         provider: provider,
         day: day,
         calls: calls,
       );

  /// Returns a shallow copy of this [ApiCallUsage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ApiCallUsage copyWith({
    Object? id = _Undefined,
    _ihrpaigz.ApiProvider? provider,
    String? day,
    int? calls,
  }) {
    return ApiCallUsage(
      id: id is int? ? id : this.id,
      provider: provider ?? this.provider,
      day: day ?? this.day,
      calls: calls ?? this.calls,
    );
  }
}

class ApiCallUsageUpdateTable extends _is.UpdateTable<ApiCallUsageTable> {
  ApiCallUsageUpdateTable(super.table);

  _is.ColumnValue<_ihrpaigz.ApiProvider, _ihrpaigz.ApiProvider> provider(
    _ihrpaigz.ApiProvider value,
  ) => _is.ColumnValue(
    table.provider,
    value,
  );

  _is.ColumnValue<String, String> day(String value) => _is.ColumnValue(
    table.day,
    value,
  );

  _is.ColumnValue<int, int> calls(int value) => _is.ColumnValue(
    table.calls,
    value,
  );
}

class ApiCallUsageTable extends _is.Table<int?> {
  ApiCallUsageTable({super.tableRelation})
    : super(tableName: 'api_call_usage') {
    updateTable = ApiCallUsageUpdateTable(this);
    provider = _is.ColumnEnum(
      'provider',
      this,
      _is.EnumSerialization.byName,
    );
    day = _is.ColumnString(
      'day',
      this,
    );
    calls = _is.ColumnInt(
      'calls',
      this,
      hasDefault: true,
    );
  }

  late final ApiCallUsageUpdateTable updateTable;

  late final _is.ColumnEnum<_ihrpaigz.ApiProvider> provider;

  /// 한도가 초기화되는 기준 날짜 (KST, YYYY-MM-DD)
  late final _is.ColumnString day;

  late final _is.ColumnInt calls;

  @override
  List<_is.Column> get columns => [
    id,
    provider,
    day,
    calls,
  ];
}

class ApiCallUsageInclude extends _is.IncludeObject {
  ApiCallUsageInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ApiCallUsage.t;
}

class ApiCallUsageIncludeList extends _is.IncludeList {
  ApiCallUsageIncludeList._({
    _is.WhereExpressionBuilder<ApiCallUsageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ApiCallUsage.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ApiCallUsage.t;
}

class ApiCallUsageRepository {
  const ApiCallUsageRepository._();

  /// Returns a list of [ApiCallUsage]s matching the given query parameters.
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
  Future<List<ApiCallUsage>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiCallUsageTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiCallUsageTable>? orderBy,
    _is.OrderByListBuilder<ApiCallUsageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ApiCallUsage>(
      where: where?.call(ApiCallUsage.t),
      orderBy: orderBy?.call(ApiCallUsage.t),
      orderByList: orderByList?.call(ApiCallUsage.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ApiCallUsage] matching the given query parameters.
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
  Future<ApiCallUsage?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiCallUsageTable>? where,
    int? offset,
    _is.OrderByBuilder<ApiCallUsageTable>? orderBy,
    _is.OrderByListBuilder<ApiCallUsageTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ApiCallUsage>(
      where: where?.call(ApiCallUsage.t),
      orderBy: orderBy?.call(ApiCallUsage.t),
      orderByList: orderByList?.call(ApiCallUsage.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ApiCallUsage] by its [id] or null if no such row exists.
  Future<ApiCallUsage?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ApiCallUsage>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ApiCallUsage]s in the list and returns the inserted rows.
  ///
  /// The returned [ApiCallUsage]s will have their `id` fields set.
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
  Future<List<ApiCallUsage>> insert(
    _is.DatabaseSession session,
    List<ApiCallUsage> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ApiCallUsage>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ApiCallUsage] and returns the inserted row.
  ///
  /// The returned [ApiCallUsage] will have its `id` field set.
  Future<ApiCallUsage> insertRow(
    _is.DatabaseSession session,
    ApiCallUsage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ApiCallUsage>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ApiCallUsage]s in the list and returns the resulting rows.
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
  /// The returned [ApiCallUsage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiCallUsage>> upsert(
    _is.DatabaseSession session,
    List<ApiCallUsage> rows, {
    required _is.ColumnSelections<ApiCallUsageTable> conflictColumns,
    _is.ColumnSelections<ApiCallUsageTable>? updateColumns,
    _is.WhereExpressionBuilder<ApiCallUsageTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ApiCallUsage>(
      rows,
      conflictColumns: conflictColumns(ApiCallUsage.t),
      updateColumns: updateColumns?.call(ApiCallUsage.t),
      updateWhere: updateWhere?.call(ApiCallUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ApiCallUsage] and returns the resulting row.
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
  /// The returned [ApiCallUsage] will have its `id` field set.
  Future<ApiCallUsage?> upsertRow(
    _is.DatabaseSession session,
    ApiCallUsage row, {
    required _is.ColumnSelections<ApiCallUsageTable> conflictColumns,
    _is.ColumnSelections<ApiCallUsageTable>? updateColumns,
    _is.WhereExpressionBuilder<ApiCallUsageTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ApiCallUsage>(
      row,
      conflictColumns: conflictColumns(ApiCallUsage.t),
      updateColumns: updateColumns?.call(ApiCallUsage.t),
      updateWhere: updateWhere?.call(ApiCallUsage.t),
      transaction: transaction,
    );
  }

  /// Updates all [ApiCallUsage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiCallUsage>> update(
    _is.DatabaseSession session,
    List<ApiCallUsage> rows, {
    _is.ColumnSelections<ApiCallUsageTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ApiCallUsage>(
      rows,
      columns: columns?.call(ApiCallUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ApiCallUsage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ApiCallUsage> updateRow(
    _is.DatabaseSession session,
    ApiCallUsage row, {
    _is.ColumnSelections<ApiCallUsageTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ApiCallUsage>(
      row,
      columns: columns?.call(ApiCallUsage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ApiCallUsage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ApiCallUsage?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ApiCallUsageUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ApiCallUsage>(
      id,
      columnValues: columnValues(ApiCallUsage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ApiCallUsage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ApiCallUsage>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ApiCallUsageUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ApiCallUsageTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ApiCallUsageTable>? orderBy,
    _is.OrderByListBuilder<ApiCallUsageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ApiCallUsage>(
      columnValues: columnValues(ApiCallUsage.t.updateTable),
      where: where(ApiCallUsage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ApiCallUsage.t),
      orderByList: orderByList?.call(ApiCallUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ApiCallUsage]s in the list and returns the deleted rows.
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
  Future<List<ApiCallUsage>> delete(
    _is.DatabaseSession session,
    List<ApiCallUsage> rows, {
    _is.OrderByBuilder<ApiCallUsageTable>? orderBy,
    _is.OrderByListBuilder<ApiCallUsageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ApiCallUsage>(
      rows,
      orderBy: orderBy?.call(ApiCallUsage.t),
      orderByList: orderByList?.call(ApiCallUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ApiCallUsage].
  Future<ApiCallUsage> deleteRow(
    _is.DatabaseSession session,
    ApiCallUsage row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ApiCallUsage>(
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
  Future<List<ApiCallUsage>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ApiCallUsageTable> where,
    _is.OrderByBuilder<ApiCallUsageTable>? orderBy,
    _is.OrderByListBuilder<ApiCallUsageTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ApiCallUsage>(
      where: where(ApiCallUsage.t),
      orderBy: orderBy?.call(ApiCallUsage.t),
      orderByList: orderByList?.call(ApiCallUsage.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ApiCallUsageTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ApiCallUsage>(
      where: where?.call(ApiCallUsage.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ApiCallUsage] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ApiCallUsageTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ApiCallUsage>(
      where: where(ApiCallUsage.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
