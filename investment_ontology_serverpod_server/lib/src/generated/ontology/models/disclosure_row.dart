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

/// 주요정보 응답 한 행을 원문 그대로. 항목 28종 모두 이 형식으로 보관한다.
/// 타입 층(ShareholderEntry 등)은 이 행에서 호출 없이 다시 만들 수 있다.
abstract class DisclosureRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DisclosureRow._({
    this.id,
    required this.reportId,
    required this.ord,
    required this.isTotal,
    required this.rowJson,
  });

  factory DisclosureRow({
    int? id,
    required int reportId,
    required int ord,
    required bool isTotal,
    required String rowJson,
  }) = _DisclosureRowImpl;

  factory DisclosureRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return DisclosureRow(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      ord: jsonSerialization['ord'] as int,
      isTotal: _is.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
      rowJson: jsonSerialization['rowJson'] as String,
    );
  }

  static final t = DisclosureRowTable();

  static const db = DisclosureRowRepository._();

  @override
  int? id;

  int reportId;

  /// 응답 순서 (0부터)
  int ord;

  /// 합계·소계 행 (계, 합계, 소계, 총계)
  bool isTotal;

  /// 응답 행 JSON 원문 (공통 필드 rcept_no·corp_code 등 포함)
  String rowJson;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DisclosureRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DisclosureRow copyWith({
    int? id,
    int? reportId,
    int? ord,
    bool? isTotal,
    String? rowJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureRow',
      if (id != null) 'id': id,
      'reportId': reportId,
      'ord': ord,
      'isTotal': isTotal,
      'rowJson': rowJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DisclosureRow',
      if (id != null) 'id': id,
      'reportId': reportId,
      'ord': ord,
      'isTotal': isTotal,
      'rowJson': rowJson,
    };
  }

  static DisclosureRowInclude include() {
    return DisclosureRowInclude._();
  }

  static DisclosureRowIncludeList includeList({
    _is.WhereExpressionBuilder<DisclosureRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DisclosureRowTable>? orderBy,
    _is.OrderByListBuilder<DisclosureRowTable>? orderByList,
    DisclosureRowInclude? include,
  }) {
    return DisclosureRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DisclosureRow.t),
      orderByList: orderByList?.call(DisclosureRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DisclosureRowImpl extends DisclosureRow {
  _DisclosureRowImpl({
    int? id,
    required int reportId,
    required int ord,
    required bool isTotal,
    required String rowJson,
  }) : super._(
         id: id,
         reportId: reportId,
         ord: ord,
         isTotal: isTotal,
         rowJson: rowJson,
       );

  /// Returns a shallow copy of this [DisclosureRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DisclosureRow copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? ord,
    bool? isTotal,
    String? rowJson,
  }) {
    return DisclosureRow(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      ord: ord ?? this.ord,
      isTotal: isTotal ?? this.isTotal,
      rowJson: rowJson ?? this.rowJson,
    );
  }
}

class DisclosureRowUpdateTable extends _is.UpdateTable<DisclosureRowTable> {
  DisclosureRowUpdateTable(super.table);

  _is.ColumnValue<int, int> reportId(int value) => _is.ColumnValue(
    table.reportId,
    value,
  );

  _is.ColumnValue<int, int> ord(int value) => _is.ColumnValue(
    table.ord,
    value,
  );

  _is.ColumnValue<bool, bool> isTotal(bool value) => _is.ColumnValue(
    table.isTotal,
    value,
  );

  _is.ColumnValue<String, String> rowJson(String value) => _is.ColumnValue(
    table.rowJson,
    value,
  );
}

class DisclosureRowTable extends _is.Table<int?> {
  DisclosureRowTable({super.tableRelation})
    : super(tableName: 'disclosure_row') {
    updateTable = DisclosureRowUpdateTable(this);
    reportId = _is.ColumnInt(
      'reportId',
      this,
    );
    ord = _is.ColumnInt(
      'ord',
      this,
    );
    isTotal = _is.ColumnBool(
      'isTotal',
      this,
    );
    rowJson = _is.ColumnString(
      'rowJson',
      this,
    );
  }

  late final DisclosureRowUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  /// 응답 순서 (0부터)
  late final _is.ColumnInt ord;

  /// 합계·소계 행 (계, 합계, 소계, 총계)
  late final _is.ColumnBool isTotal;

  /// 응답 행 JSON 원문 (공통 필드 rcept_no·corp_code 등 포함)
  late final _is.ColumnString rowJson;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    ord,
    isTotal,
    rowJson,
  ];
}

class DisclosureRowInclude extends _is.IncludeObject {
  DisclosureRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DisclosureRow.t;
}

class DisclosureRowIncludeList extends _is.IncludeList {
  DisclosureRowIncludeList._({
    _is.WhereExpressionBuilder<DisclosureRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DisclosureRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DisclosureRow.t;
}

class DisclosureRowRepository {
  const DisclosureRowRepository._();

  /// Returns a list of [DisclosureRow]s matching the given query parameters.
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
  Future<List<DisclosureRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DisclosureRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DisclosureRowTable>? orderBy,
    _is.OrderByListBuilder<DisclosureRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DisclosureRow>(
      where: where?.call(DisclosureRow.t),
      orderBy: orderBy?.call(DisclosureRow.t),
      orderByList: orderByList?.call(DisclosureRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DisclosureRow] matching the given query parameters.
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
  Future<DisclosureRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DisclosureRowTable>? where,
    int? offset,
    _is.OrderByBuilder<DisclosureRowTable>? orderBy,
    _is.OrderByListBuilder<DisclosureRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DisclosureRow>(
      where: where?.call(DisclosureRow.t),
      orderBy: orderBy?.call(DisclosureRow.t),
      orderByList: orderByList?.call(DisclosureRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DisclosureRow] by its [id] or null if no such row exists.
  Future<DisclosureRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DisclosureRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DisclosureRow]s in the list and returns the inserted rows.
  ///
  /// The returned [DisclosureRow]s will have their `id` fields set.
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
  Future<List<DisclosureRow>> insert(
    _is.DatabaseSession session,
    List<DisclosureRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DisclosureRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DisclosureRow] and returns the inserted row.
  ///
  /// The returned [DisclosureRow] will have its `id` field set.
  Future<DisclosureRow> insertRow(
    _is.DatabaseSession session,
    DisclosureRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DisclosureRow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DisclosureRow]s in the list and returns the resulting rows.
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
  /// The returned [DisclosureRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DisclosureRow>> upsert(
    _is.DatabaseSession session,
    List<DisclosureRow> rows, {
    required _is.ColumnSelections<DisclosureRowTable> conflictColumns,
    _is.ColumnSelections<DisclosureRowTable>? updateColumns,
    _is.WhereExpressionBuilder<DisclosureRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DisclosureRow>(
      rows,
      conflictColumns: conflictColumns(DisclosureRow.t),
      updateColumns: updateColumns?.call(DisclosureRow.t),
      updateWhere: updateWhere?.call(DisclosureRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DisclosureRow] and returns the resulting row.
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
  /// The returned [DisclosureRow] will have its `id` field set.
  Future<DisclosureRow?> upsertRow(
    _is.DatabaseSession session,
    DisclosureRow row, {
    required _is.ColumnSelections<DisclosureRowTable> conflictColumns,
    _is.ColumnSelections<DisclosureRowTable>? updateColumns,
    _is.WhereExpressionBuilder<DisclosureRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DisclosureRow>(
      row,
      conflictColumns: conflictColumns(DisclosureRow.t),
      updateColumns: updateColumns?.call(DisclosureRow.t),
      updateWhere: updateWhere?.call(DisclosureRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [DisclosureRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DisclosureRow>> update(
    _is.DatabaseSession session,
    List<DisclosureRow> rows, {
    _is.ColumnSelections<DisclosureRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DisclosureRow>(
      rows,
      columns: columns?.call(DisclosureRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DisclosureRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DisclosureRow> updateRow(
    _is.DatabaseSession session,
    DisclosureRow row, {
    _is.ColumnSelections<DisclosureRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DisclosureRow>(
      row,
      columns: columns?.call(DisclosureRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DisclosureRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DisclosureRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DisclosureRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DisclosureRow>(
      id,
      columnValues: columnValues(DisclosureRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DisclosureRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DisclosureRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DisclosureRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DisclosureRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DisclosureRowTable>? orderBy,
    _is.OrderByListBuilder<DisclosureRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DisclosureRow>(
      columnValues: columnValues(DisclosureRow.t.updateTable),
      where: where(DisclosureRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DisclosureRow.t),
      orderByList: orderByList?.call(DisclosureRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DisclosureRow]s in the list and returns the deleted rows.
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
  Future<List<DisclosureRow>> delete(
    _is.DatabaseSession session,
    List<DisclosureRow> rows, {
    _is.OrderByBuilder<DisclosureRowTable>? orderBy,
    _is.OrderByListBuilder<DisclosureRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DisclosureRow>(
      rows,
      orderBy: orderBy?.call(DisclosureRow.t),
      orderByList: orderByList?.call(DisclosureRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DisclosureRow].
  Future<DisclosureRow> deleteRow(
    _is.DatabaseSession session,
    DisclosureRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DisclosureRow>(
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
  Future<List<DisclosureRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DisclosureRowTable> where,
    _is.OrderByBuilder<DisclosureRowTable>? orderBy,
    _is.OrderByListBuilder<DisclosureRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DisclosureRow>(
      where: where(DisclosureRow.t),
      orderBy: orderBy?.call(DisclosureRow.t),
      orderByList: orderByList?.call(DisclosureRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DisclosureRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DisclosureRow>(
      where: where?.call(DisclosureRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DisclosureRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DisclosureRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DisclosureRow>(
      where: where(DisclosureRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
