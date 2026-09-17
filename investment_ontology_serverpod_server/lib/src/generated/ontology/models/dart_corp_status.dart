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

/// 수집 장부: 종목코드를 가진 DART 고유번호마다 마지막으로 확인한 상장 구분.
/// 온톨로지 엔티티가 아니라, 상장폐지 기업을 매번 다시 조회하지 않기 위한 기록이다.
abstract class DartCorpStatus
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DartCorpStatus._({
    this.id,
    required this.corpCode,
    required this.corpCls,
    this.modifiedDate,
    required this.checkedAt,
  });

  factory DartCorpStatus({
    int? id,
    required String corpCode,
    required String corpCls,
    DateTime? modifiedDate,
    required DateTime checkedAt,
  }) = _DartCorpStatusImpl;

  factory DartCorpStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartCorpStatus(
      id: jsonSerialization['id'] as int?,
      corpCode: jsonSerialization['corpCode'] as String,
      corpCls: jsonSerialization['corpCls'] as String,
      modifiedDate: jsonSerialization['modifiedDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['modifiedDate'],
            ),
      checkedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['checkedAt'],
      ),
    );
  }

  static final t = DartCorpStatusTable();

  static const db = DartCorpStatusRepository._();

  @override
  int? id;

  String corpCode;

  /// company.json의 corp_cls (Y/K/N/E)
  String corpCls;

  DateTime? modifiedDate;

  DateTime checkedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DartCorpStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DartCorpStatus copyWith({
    int? id,
    String? corpCode,
    String? corpCls,
    DateTime? modifiedDate,
    DateTime? checkedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartCorpStatus',
      if (id != null) 'id': id,
      'corpCode': corpCode,
      'corpCls': corpCls,
      if (modifiedDate != null) 'modifiedDate': modifiedDate?.toJson(),
      'checkedAt': checkedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartCorpStatus',
      if (id != null) 'id': id,
      'corpCode': corpCode,
      'corpCls': corpCls,
      if (modifiedDate != null) 'modifiedDate': modifiedDate?.toJson(),
      'checkedAt': checkedAt.toJson(),
    };
  }

  static DartCorpStatusInclude include() {
    return DartCorpStatusInclude._();
  }

  static DartCorpStatusIncludeList includeList({
    _is.WhereExpressionBuilder<DartCorpStatusTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartCorpStatusTable>? orderBy,
    _is.OrderByListBuilder<DartCorpStatusTable>? orderByList,
    DartCorpStatusInclude? include,
  }) {
    return DartCorpStatusIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartCorpStatus.t),
      orderByList: orderByList?.call(DartCorpStatus.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartCorpStatusImpl extends DartCorpStatus {
  _DartCorpStatusImpl({
    int? id,
    required String corpCode,
    required String corpCls,
    DateTime? modifiedDate,
    required DateTime checkedAt,
  }) : super._(
         id: id,
         corpCode: corpCode,
         corpCls: corpCls,
         modifiedDate: modifiedDate,
         checkedAt: checkedAt,
       );

  /// Returns a shallow copy of this [DartCorpStatus]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DartCorpStatus copyWith({
    Object? id = _Undefined,
    String? corpCode,
    String? corpCls,
    Object? modifiedDate = _Undefined,
    DateTime? checkedAt,
  }) {
    return DartCorpStatus(
      id: id is int? ? id : this.id,
      corpCode: corpCode ?? this.corpCode,
      corpCls: corpCls ?? this.corpCls,
      modifiedDate: modifiedDate is DateTime?
          ? modifiedDate
          : this.modifiedDate,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}

class DartCorpStatusUpdateTable extends _is.UpdateTable<DartCorpStatusTable> {
  DartCorpStatusUpdateTable(super.table);

  _is.ColumnValue<String, String> corpCode(String value) => _is.ColumnValue(
    table.corpCode,
    value,
  );

  _is.ColumnValue<String, String> corpCls(String value) => _is.ColumnValue(
    table.corpCls,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> modifiedDate(DateTime? value) =>
      _is.ColumnValue(
        table.modifiedDate,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> checkedAt(DateTime value) =>
      _is.ColumnValue(
        table.checkedAt,
        value,
      );
}

class DartCorpStatusTable extends _is.Table<int?> {
  DartCorpStatusTable({super.tableRelation})
    : super(tableName: 'dart_corp_status') {
    updateTable = DartCorpStatusUpdateTable(this);
    corpCode = _is.ColumnString(
      'corpCode',
      this,
    );
    corpCls = _is.ColumnString(
      'corpCls',
      this,
    );
    modifiedDate = _is.ColumnDateTime(
      'modifiedDate',
      this,
    );
    checkedAt = _is.ColumnDateTime(
      'checkedAt',
      this,
    );
  }

  late final DartCorpStatusUpdateTable updateTable;

  late final _is.ColumnString corpCode;

  /// company.json의 corp_cls (Y/K/N/E)
  late final _is.ColumnString corpCls;

  late final _is.ColumnDateTime modifiedDate;

  late final _is.ColumnDateTime checkedAt;

  @override
  List<_is.Column> get columns => [
    id,
    corpCode,
    corpCls,
    modifiedDate,
    checkedAt,
  ];
}

class DartCorpStatusInclude extends _is.IncludeObject {
  DartCorpStatusInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DartCorpStatus.t;
}

class DartCorpStatusIncludeList extends _is.IncludeList {
  DartCorpStatusIncludeList._({
    _is.WhereExpressionBuilder<DartCorpStatusTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DartCorpStatus.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DartCorpStatus.t;
}

class DartCorpStatusRepository {
  const DartCorpStatusRepository._();

  /// Returns a list of [DartCorpStatus]s matching the given query parameters.
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
  Future<List<DartCorpStatus>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartCorpStatusTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartCorpStatusTable>? orderBy,
    _is.OrderByListBuilder<DartCorpStatusTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DartCorpStatus>(
      where: where?.call(DartCorpStatus.t),
      orderBy: orderBy?.call(DartCorpStatus.t),
      orderByList: orderByList?.call(DartCorpStatus.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DartCorpStatus] matching the given query parameters.
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
  Future<DartCorpStatus?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartCorpStatusTable>? where,
    int? offset,
    _is.OrderByBuilder<DartCorpStatusTable>? orderBy,
    _is.OrderByListBuilder<DartCorpStatusTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DartCorpStatus>(
      where: where?.call(DartCorpStatus.t),
      orderBy: orderBy?.call(DartCorpStatus.t),
      orderByList: orderByList?.call(DartCorpStatus.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DartCorpStatus] by its [id] or null if no such row exists.
  Future<DartCorpStatus?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DartCorpStatus>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DartCorpStatus]s in the list and returns the inserted rows.
  ///
  /// The returned [DartCorpStatus]s will have their `id` fields set.
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
  Future<List<DartCorpStatus>> insert(
    _is.DatabaseSession session,
    List<DartCorpStatus> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DartCorpStatus>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DartCorpStatus] and returns the inserted row.
  ///
  /// The returned [DartCorpStatus] will have its `id` field set.
  Future<DartCorpStatus> insertRow(
    _is.DatabaseSession session,
    DartCorpStatus row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DartCorpStatus>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DartCorpStatus]s in the list and returns the resulting rows.
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
  /// The returned [DartCorpStatus]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartCorpStatus>> upsert(
    _is.DatabaseSession session,
    List<DartCorpStatus> rows, {
    required _is.ColumnSelections<DartCorpStatusTable> conflictColumns,
    _is.ColumnSelections<DartCorpStatusTable>? updateColumns,
    _is.WhereExpressionBuilder<DartCorpStatusTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DartCorpStatus>(
      rows,
      conflictColumns: conflictColumns(DartCorpStatus.t),
      updateColumns: updateColumns?.call(DartCorpStatus.t),
      updateWhere: updateWhere?.call(DartCorpStatus.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DartCorpStatus] and returns the resulting row.
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
  /// The returned [DartCorpStatus] will have its `id` field set.
  Future<DartCorpStatus?> upsertRow(
    _is.DatabaseSession session,
    DartCorpStatus row, {
    required _is.ColumnSelections<DartCorpStatusTable> conflictColumns,
    _is.ColumnSelections<DartCorpStatusTable>? updateColumns,
    _is.WhereExpressionBuilder<DartCorpStatusTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DartCorpStatus>(
      row,
      conflictColumns: conflictColumns(DartCorpStatus.t),
      updateColumns: updateColumns?.call(DartCorpStatus.t),
      updateWhere: updateWhere?.call(DartCorpStatus.t),
      transaction: transaction,
    );
  }

  /// Updates all [DartCorpStatus]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartCorpStatus>> update(
    _is.DatabaseSession session,
    List<DartCorpStatus> rows, {
    _is.ColumnSelections<DartCorpStatusTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DartCorpStatus>(
      rows,
      columns: columns?.call(DartCorpStatus.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DartCorpStatus]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DartCorpStatus> updateRow(
    _is.DatabaseSession session,
    DartCorpStatus row, {
    _is.ColumnSelections<DartCorpStatusTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DartCorpStatus>(
      row,
      columns: columns?.call(DartCorpStatus.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DartCorpStatus] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DartCorpStatus?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DartCorpStatusUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DartCorpStatus>(
      id,
      columnValues: columnValues(DartCorpStatus.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DartCorpStatus]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartCorpStatus>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DartCorpStatusUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DartCorpStatusTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartCorpStatusTable>? orderBy,
    _is.OrderByListBuilder<DartCorpStatusTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DartCorpStatus>(
      columnValues: columnValues(DartCorpStatus.t.updateTable),
      where: where(DartCorpStatus.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartCorpStatus.t),
      orderByList: orderByList?.call(DartCorpStatus.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DartCorpStatus]s in the list and returns the deleted rows.
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
  Future<List<DartCorpStatus>> delete(
    _is.DatabaseSession session,
    List<DartCorpStatus> rows, {
    _is.OrderByBuilder<DartCorpStatusTable>? orderBy,
    _is.OrderByListBuilder<DartCorpStatusTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DartCorpStatus>(
      rows,
      orderBy: orderBy?.call(DartCorpStatus.t),
      orderByList: orderByList?.call(DartCorpStatus.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DartCorpStatus].
  Future<DartCorpStatus> deleteRow(
    _is.DatabaseSession session,
    DartCorpStatus row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DartCorpStatus>(
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
  Future<List<DartCorpStatus>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartCorpStatusTable> where,
    _is.OrderByBuilder<DartCorpStatusTable>? orderBy,
    _is.OrderByListBuilder<DartCorpStatusTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DartCorpStatus>(
      where: where(DartCorpStatus.t),
      orderBy: orderBy?.call(DartCorpStatus.t),
      orderByList: orderByList?.call(DartCorpStatus.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartCorpStatusTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DartCorpStatus>(
      where: where?.call(DartCorpStatus.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DartCorpStatus] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartCorpStatusTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DartCorpStatus>(
      where: where(DartCorpStatus.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
