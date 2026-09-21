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

/// AI 관계 추출 실행 기록: 사업보고서 본문 하나를 모델 하나로 읽은 결과.
abstract class AiExtraction
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AiExtraction._({
    this.id,
    required this.documentId,
    required this.companyId,
    required this.model,
    required this.succeeded,
    required this.relationCount,
    required this.droppedCount,
    this.error,
    required this.createdAt,
  });

  factory AiExtraction({
    int? id,
    required int documentId,
    required int companyId,
    required String model,
    required bool succeeded,
    required int relationCount,
    required int droppedCount,
    String? error,
    required DateTime createdAt,
  }) = _AiExtractionImpl;

  factory AiExtraction.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiExtraction(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      model: jsonSerialization['model'] as String,
      succeeded: _is.BoolJsonExtension.fromJson(jsonSerialization['succeeded']),
      relationCount: jsonSerialization['relationCount'] as int,
      droppedCount: jsonSerialization['droppedCount'] as int,
      error: jsonSerialization['error'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = AiExtractionTable();

  static const db = AiExtractionRepository._();

  @override
  int? id;

  int documentId;

  int companyId;

  String model;

  bool succeeded;

  /// 저장한 관계 수 (draft)
  int relationCount;

  /// 근거 인용이 원문에 없거나 형식이 틀려 버린 수
  int droppedCount;

  String? error;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AiExtraction]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AiExtraction copyWith({
    int? id,
    int? documentId,
    int? companyId,
    String? model,
    bool? succeeded,
    int? relationCount,
    int? droppedCount,
    String? error,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiExtraction',
      if (id != null) 'id': id,
      'documentId': documentId,
      'companyId': companyId,
      'model': model,
      'succeeded': succeeded,
      'relationCount': relationCount,
      'droppedCount': droppedCount,
      if (error != null) 'error': error,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiExtraction',
      if (id != null) 'id': id,
      'documentId': documentId,
      'companyId': companyId,
      'model': model,
      'succeeded': succeeded,
      'relationCount': relationCount,
      'droppedCount': droppedCount,
      if (error != null) 'error': error,
      'createdAt': createdAt.toJson(),
    };
  }

  static AiExtractionInclude include() {
    return AiExtractionInclude._();
  }

  static AiExtractionIncludeList includeList({
    _is.WhereExpressionBuilder<AiExtractionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiExtractionTable>? orderBy,
    _is.OrderByListBuilder<AiExtractionTable>? orderByList,
    AiExtractionInclude? include,
  }) {
    return AiExtractionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiExtraction.t),
      orderByList: orderByList?.call(AiExtraction.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiExtractionImpl extends AiExtraction {
  _AiExtractionImpl({
    int? id,
    required int documentId,
    required int companyId,
    required String model,
    required bool succeeded,
    required int relationCount,
    required int droppedCount,
    String? error,
    required DateTime createdAt,
  }) : super._(
         id: id,
         documentId: documentId,
         companyId: companyId,
         model: model,
         succeeded: succeeded,
         relationCount: relationCount,
         droppedCount: droppedCount,
         error: error,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AiExtraction]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AiExtraction copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? companyId,
    String? model,
    bool? succeeded,
    int? relationCount,
    int? droppedCount,
    Object? error = _Undefined,
    DateTime? createdAt,
  }) {
    return AiExtraction(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      companyId: companyId ?? this.companyId,
      model: model ?? this.model,
      succeeded: succeeded ?? this.succeeded,
      relationCount: relationCount ?? this.relationCount,
      droppedCount: droppedCount ?? this.droppedCount,
      error: error is String? ? error : this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AiExtractionUpdateTable extends _is.UpdateTable<AiExtractionTable> {
  AiExtractionUpdateTable(super.table);

  _is.ColumnValue<int, int> documentId(int value) => _is.ColumnValue(
    table.documentId,
    value,
  );

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<String, String> model(String value) => _is.ColumnValue(
    table.model,
    value,
  );

  _is.ColumnValue<bool, bool> succeeded(bool value) => _is.ColumnValue(
    table.succeeded,
    value,
  );

  _is.ColumnValue<int, int> relationCount(int value) => _is.ColumnValue(
    table.relationCount,
    value,
  );

  _is.ColumnValue<int, int> droppedCount(int value) => _is.ColumnValue(
    table.droppedCount,
    value,
  );

  _is.ColumnValue<String, String> error(String? value) => _is.ColumnValue(
    table.error,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class AiExtractionTable extends _is.Table<int?> {
  AiExtractionTable({super.tableRelation}) : super(tableName: 'ai_extraction') {
    updateTable = AiExtractionUpdateTable(this);
    documentId = _is.ColumnInt(
      'documentId',
      this,
    );
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    model = _is.ColumnString(
      'model',
      this,
    );
    succeeded = _is.ColumnBool(
      'succeeded',
      this,
    );
    relationCount = _is.ColumnInt(
      'relationCount',
      this,
    );
    droppedCount = _is.ColumnInt(
      'droppedCount',
      this,
    );
    error = _is.ColumnString(
      'error',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final AiExtractionUpdateTable updateTable;

  late final _is.ColumnInt documentId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnString model;

  late final _is.ColumnBool succeeded;

  /// 저장한 관계 수 (draft)
  late final _is.ColumnInt relationCount;

  /// 근거 인용이 원문에 없거나 형식이 틀려 버린 수
  late final _is.ColumnInt droppedCount;

  late final _is.ColumnString error;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    documentId,
    companyId,
    model,
    succeeded,
    relationCount,
    droppedCount,
    error,
    createdAt,
  ];
}

class AiExtractionInclude extends _is.IncludeObject {
  AiExtractionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AiExtraction.t;
}

class AiExtractionIncludeList extends _is.IncludeList {
  AiExtractionIncludeList._({
    _is.WhereExpressionBuilder<AiExtractionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AiExtraction.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AiExtraction.t;
}

class AiExtractionRepository {
  const AiExtractionRepository._();

  /// Returns a list of [AiExtraction]s matching the given query parameters.
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
  Future<List<AiExtraction>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiExtractionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiExtractionTable>? orderBy,
    _is.OrderByListBuilder<AiExtractionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AiExtraction>(
      where: where?.call(AiExtraction.t),
      orderBy: orderBy?.call(AiExtraction.t),
      orderByList: orderByList?.call(AiExtraction.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AiExtraction] matching the given query parameters.
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
  Future<AiExtraction?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiExtractionTable>? where,
    int? offset,
    _is.OrderByBuilder<AiExtractionTable>? orderBy,
    _is.OrderByListBuilder<AiExtractionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AiExtraction>(
      where: where?.call(AiExtraction.t),
      orderBy: orderBy?.call(AiExtraction.t),
      orderByList: orderByList?.call(AiExtraction.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AiExtraction] by its [id] or null if no such row exists.
  Future<AiExtraction?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AiExtraction>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AiExtraction]s in the list and returns the inserted rows.
  ///
  /// The returned [AiExtraction]s will have their `id` fields set.
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
  Future<List<AiExtraction>> insert(
    _is.DatabaseSession session,
    List<AiExtraction> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AiExtraction>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AiExtraction] and returns the inserted row.
  ///
  /// The returned [AiExtraction] will have its `id` field set.
  Future<AiExtraction> insertRow(
    _is.DatabaseSession session,
    AiExtraction row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AiExtraction>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AiExtraction]s in the list and returns the resulting rows.
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
  /// The returned [AiExtraction]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiExtraction>> upsert(
    _is.DatabaseSession session,
    List<AiExtraction> rows, {
    required _is.ColumnSelections<AiExtractionTable> conflictColumns,
    _is.ColumnSelections<AiExtractionTable>? updateColumns,
    _is.WhereExpressionBuilder<AiExtractionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AiExtraction>(
      rows,
      conflictColumns: conflictColumns(AiExtraction.t),
      updateColumns: updateColumns?.call(AiExtraction.t),
      updateWhere: updateWhere?.call(AiExtraction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AiExtraction] and returns the resulting row.
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
  /// The returned [AiExtraction] will have its `id` field set.
  Future<AiExtraction?> upsertRow(
    _is.DatabaseSession session,
    AiExtraction row, {
    required _is.ColumnSelections<AiExtractionTable> conflictColumns,
    _is.ColumnSelections<AiExtractionTable>? updateColumns,
    _is.WhereExpressionBuilder<AiExtractionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AiExtraction>(
      row,
      conflictColumns: conflictColumns(AiExtraction.t),
      updateColumns: updateColumns?.call(AiExtraction.t),
      updateWhere: updateWhere?.call(AiExtraction.t),
      transaction: transaction,
    );
  }

  /// Updates all [AiExtraction]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiExtraction>> update(
    _is.DatabaseSession session,
    List<AiExtraction> rows, {
    _is.ColumnSelections<AiExtractionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AiExtraction>(
      rows,
      columns: columns?.call(AiExtraction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AiExtraction]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AiExtraction> updateRow(
    _is.DatabaseSession session,
    AiExtraction row, {
    _is.ColumnSelections<AiExtractionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AiExtraction>(
      row,
      columns: columns?.call(AiExtraction.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiExtraction] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AiExtraction?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AiExtractionUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AiExtraction>(
      id,
      columnValues: columnValues(AiExtraction.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AiExtraction]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiExtraction>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AiExtractionUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AiExtractionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiExtractionTable>? orderBy,
    _is.OrderByListBuilder<AiExtractionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AiExtraction>(
      columnValues: columnValues(AiExtraction.t.updateTable),
      where: where(AiExtraction.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiExtraction.t),
      orderByList: orderByList?.call(AiExtraction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AiExtraction]s in the list and returns the deleted rows.
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
  Future<List<AiExtraction>> delete(
    _is.DatabaseSession session,
    List<AiExtraction> rows, {
    _is.OrderByBuilder<AiExtractionTable>? orderBy,
    _is.OrderByListBuilder<AiExtractionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AiExtraction>(
      rows,
      orderBy: orderBy?.call(AiExtraction.t),
      orderByList: orderByList?.call(AiExtraction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AiExtraction].
  Future<AiExtraction> deleteRow(
    _is.DatabaseSession session,
    AiExtraction row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AiExtraction>(
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
  Future<List<AiExtraction>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiExtractionTable> where,
    _is.OrderByBuilder<AiExtractionTable>? orderBy,
    _is.OrderByListBuilder<AiExtractionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AiExtraction>(
      where: where(AiExtraction.t),
      orderBy: orderBy?.call(AiExtraction.t),
      orderByList: orderByList?.call(AiExtraction.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiExtractionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AiExtraction>(
      where: where?.call(AiExtraction.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AiExtraction] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiExtractionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AiExtraction>(
      where: where(AiExtraction.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
