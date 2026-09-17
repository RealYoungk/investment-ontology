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

/// 기업 속성 변경 이력. 다시 수집했을 때 값이 바뀐 필드마다 한 행.
abstract class CompanyChange
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  CompanyChange._({
    this.id,
    required this.companyId,
    required this.field,
    this.oldValue,
    this.newValue,
    this.sourceId,
    required this.changedAt,
  });

  factory CompanyChange({
    int? id,
    required int companyId,
    required String field,
    String? oldValue,
    String? newValue,
    int? sourceId,
    required DateTime changedAt,
  }) = _CompanyChangeImpl;

  factory CompanyChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyChange(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      field: jsonSerialization['field'] as String,
      oldValue: jsonSerialization['oldValue'] as String?,
      newValue: jsonSerialization['newValue'] as String?,
      sourceId: jsonSerialization['sourceId'] as int?,
      changedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['changedAt'],
      ),
    );
  }

  static final t = CompanyChangeTable();

  static const db = CompanyChangeRepository._();

  @override
  int? id;

  int companyId;

  /// Company 필드명 (예: ceoName, market)
  String field;

  /// 정규화된 값을 문자열로 (날짜는 YYYY-MM-DD, enum은 이름)
  String? oldValue;

  String? newValue;

  int? sourceId;

  DateTime changedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [CompanyChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyChange copyWith({
    int? id,
    int? companyId,
    String? field,
    String? oldValue,
    String? newValue,
    int? sourceId,
    DateTime? changedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyChange',
      if (id != null) 'id': id,
      'companyId': companyId,
      'field': field,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (sourceId != null) 'sourceId': sourceId,
      'changedAt': changedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyChange',
      if (id != null) 'id': id,
      'companyId': companyId,
      'field': field,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (sourceId != null) 'sourceId': sourceId,
      'changedAt': changedAt.toJson(),
    };
  }

  static CompanyChangeInclude include() {
    return CompanyChangeInclude._();
  }

  static CompanyChangeIncludeList includeList({
    _is.WhereExpressionBuilder<CompanyChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CompanyChangeTable>? orderBy,
    _is.OrderByListBuilder<CompanyChangeTable>? orderByList,
    CompanyChangeInclude? include,
  }) {
    return CompanyChangeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CompanyChange.t),
      orderByList: orderByList?.call(CompanyChange.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyChangeImpl extends CompanyChange {
  _CompanyChangeImpl({
    int? id,
    required int companyId,
    required String field,
    String? oldValue,
    String? newValue,
    int? sourceId,
    required DateTime changedAt,
  }) : super._(
         id: id,
         companyId: companyId,
         field: field,
         oldValue: oldValue,
         newValue: newValue,
         sourceId: sourceId,
         changedAt: changedAt,
       );

  /// Returns a shallow copy of this [CompanyChange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyChange copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? field,
    Object? oldValue = _Undefined,
    Object? newValue = _Undefined,
    Object? sourceId = _Undefined,
    DateTime? changedAt,
  }) {
    return CompanyChange(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      field: field ?? this.field,
      oldValue: oldValue is String? ? oldValue : this.oldValue,
      newValue: newValue is String? ? newValue : this.newValue,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}

class CompanyChangeUpdateTable extends _is.UpdateTable<CompanyChangeTable> {
  CompanyChangeUpdateTable(super.table);

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<String, String> field(String value) => _is.ColumnValue(
    table.field,
    value,
  );

  _is.ColumnValue<String, String> oldValue(String? value) => _is.ColumnValue(
    table.oldValue,
    value,
  );

  _is.ColumnValue<String, String> newValue(String? value) => _is.ColumnValue(
    table.newValue,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> changedAt(DateTime value) =>
      _is.ColumnValue(
        table.changedAt,
        value,
      );
}

class CompanyChangeTable extends _is.Table<int?> {
  CompanyChangeTable({super.tableRelation})
    : super(tableName: 'company_change') {
    updateTable = CompanyChangeUpdateTable(this);
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    field = _is.ColumnString(
      'field',
      this,
    );
    oldValue = _is.ColumnString(
      'oldValue',
      this,
    );
    newValue = _is.ColumnString(
      'newValue',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    changedAt = _is.ColumnDateTime(
      'changedAt',
      this,
    );
  }

  late final CompanyChangeUpdateTable updateTable;

  late final _is.ColumnInt companyId;

  /// Company 필드명 (예: ceoName, market)
  late final _is.ColumnString field;

  /// 정규화된 값을 문자열로 (날짜는 YYYY-MM-DD, enum은 이름)
  late final _is.ColumnString oldValue;

  late final _is.ColumnString newValue;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnDateTime changedAt;

  @override
  List<_is.Column> get columns => [
    id,
    companyId,
    field,
    oldValue,
    newValue,
    sourceId,
    changedAt,
  ];
}

class CompanyChangeInclude extends _is.IncludeObject {
  CompanyChangeInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => CompanyChange.t;
}

class CompanyChangeIncludeList extends _is.IncludeList {
  CompanyChangeIncludeList._({
    _is.WhereExpressionBuilder<CompanyChangeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CompanyChange.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => CompanyChange.t;
}

class CompanyChangeRepository {
  const CompanyChangeRepository._();

  /// Returns a list of [CompanyChange]s matching the given query parameters.
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
  Future<List<CompanyChange>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CompanyChangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CompanyChangeTable>? orderBy,
    _is.OrderByListBuilder<CompanyChangeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CompanyChange>(
      where: where?.call(CompanyChange.t),
      orderBy: orderBy?.call(CompanyChange.t),
      orderByList: orderByList?.call(CompanyChange.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [CompanyChange] matching the given query parameters.
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
  Future<CompanyChange?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CompanyChangeTable>? where,
    int? offset,
    _is.OrderByBuilder<CompanyChangeTable>? orderBy,
    _is.OrderByListBuilder<CompanyChangeTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CompanyChange>(
      where: where?.call(CompanyChange.t),
      orderBy: orderBy?.call(CompanyChange.t),
      orderByList: orderByList?.call(CompanyChange.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CompanyChange] by its [id] or null if no such row exists.
  Future<CompanyChange?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CompanyChange>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CompanyChange]s in the list and returns the inserted rows.
  ///
  /// The returned [CompanyChange]s will have their `id` fields set.
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
  Future<List<CompanyChange>> insert(
    _is.DatabaseSession session,
    List<CompanyChange> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CompanyChange>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CompanyChange] and returns the inserted row.
  ///
  /// The returned [CompanyChange] will have its `id` field set.
  Future<CompanyChange> insertRow(
    _is.DatabaseSession session,
    CompanyChange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<CompanyChange>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CompanyChange]s in the list and returns the resulting rows.
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
  /// The returned [CompanyChange]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CompanyChange>> upsert(
    _is.DatabaseSession session,
    List<CompanyChange> rows, {
    required _is.ColumnSelections<CompanyChangeTable> conflictColumns,
    _is.ColumnSelections<CompanyChangeTable>? updateColumns,
    _is.WhereExpressionBuilder<CompanyChangeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CompanyChange>(
      rows,
      conflictColumns: conflictColumns(CompanyChange.t),
      updateColumns: updateColumns?.call(CompanyChange.t),
      updateWhere: updateWhere?.call(CompanyChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CompanyChange] and returns the resulting row.
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
  /// The returned [CompanyChange] will have its `id` field set.
  Future<CompanyChange?> upsertRow(
    _is.DatabaseSession session,
    CompanyChange row, {
    required _is.ColumnSelections<CompanyChangeTable> conflictColumns,
    _is.ColumnSelections<CompanyChangeTable>? updateColumns,
    _is.WhereExpressionBuilder<CompanyChangeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CompanyChange>(
      row,
      conflictColumns: conflictColumns(CompanyChange.t),
      updateColumns: updateColumns?.call(CompanyChange.t),
      updateWhere: updateWhere?.call(CompanyChange.t),
      transaction: transaction,
    );
  }

  /// Updates all [CompanyChange]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CompanyChange>> update(
    _is.DatabaseSession session,
    List<CompanyChange> rows, {
    _is.ColumnSelections<CompanyChangeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CompanyChange>(
      rows,
      columns: columns?.call(CompanyChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CompanyChange]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CompanyChange> updateRow(
    _is.DatabaseSession session,
    CompanyChange row, {
    _is.ColumnSelections<CompanyChangeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<CompanyChange>(
      row,
      columns: columns?.call(CompanyChange.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CompanyChange] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CompanyChange?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CompanyChangeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<CompanyChange>(
      id,
      columnValues: columnValues(CompanyChange.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CompanyChange]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CompanyChange>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CompanyChangeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CompanyChangeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CompanyChangeTable>? orderBy,
    _is.OrderByListBuilder<CompanyChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CompanyChange>(
      columnValues: columnValues(CompanyChange.t.updateTable),
      where: where(CompanyChange.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CompanyChange.t),
      orderByList: orderByList?.call(CompanyChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CompanyChange]s in the list and returns the deleted rows.
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
  Future<List<CompanyChange>> delete(
    _is.DatabaseSession session,
    List<CompanyChange> rows, {
    _is.OrderByBuilder<CompanyChangeTable>? orderBy,
    _is.OrderByListBuilder<CompanyChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CompanyChange>(
      rows,
      orderBy: orderBy?.call(CompanyChange.t),
      orderByList: orderByList?.call(CompanyChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CompanyChange].
  Future<CompanyChange> deleteRow(
    _is.DatabaseSession session,
    CompanyChange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CompanyChange>(
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
  Future<List<CompanyChange>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CompanyChangeTable> where,
    _is.OrderByBuilder<CompanyChangeTable>? orderBy,
    _is.OrderByListBuilder<CompanyChangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CompanyChange>(
      where: where(CompanyChange.t),
      orderBy: orderBy?.call(CompanyChange.t),
      orderByList: orderByList?.call(CompanyChange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CompanyChangeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CompanyChange>(
      where: where?.call(CompanyChange.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CompanyChange] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CompanyChangeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CompanyChange>(
      where: where(CompanyChange.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
