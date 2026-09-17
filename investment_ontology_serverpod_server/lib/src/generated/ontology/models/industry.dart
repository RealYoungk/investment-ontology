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

/// 한국표준산업분류(KSIC) 항목. 개정 차수마다 따로 둔다.
abstract class Industry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Industry._({
    this.id,
    required this.code,
    required this.name,
    required this.level,
    this.parentCode,
    required this.revision,
    this.sourceId,
  });

  factory Industry({
    int? id,
    required String code,
    required String name,
    required int level,
    String? parentCode,
    required String revision,
    int? sourceId,
  }) = _IndustryImpl;

  factory Industry.fromJson(Map<String, dynamic> jsonSerialization) {
    return Industry(
      id: jsonSerialization['id'] as int?,
      code: jsonSerialization['code'] as String,
      name: jsonSerialization['name'] as String,
      level: jsonSerialization['level'] as int,
      parentCode: jsonSerialization['parentCode'] as String?,
      revision: jsonSerialization['revision'] as String,
      sourceId: jsonSerialization['sourceId'] as int?,
    );
  }

  static final t = IndustryTable();

  static const db = IndustryRepository._();

  @override
  int? id;

  /// A~U (대분류) 또는 2~5자리 숫자
  String code;

  String name;

  /// 1 대분류, 2 중분류, 3 소분류, 4 세분류, 5 세세분류
  int level;

  String? parentCode;

  /// 예: "KSIC 11"
  String revision;

  /// 통계청 고시 자료
  int? sourceId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Industry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Industry copyWith({
    int? id,
    String? code,
    String? name,
    int? level,
    String? parentCode,
    String? revision,
    int? sourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Industry',
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'level': level,
      if (parentCode != null) 'parentCode': parentCode,
      'revision': revision,
      if (sourceId != null) 'sourceId': sourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Industry',
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'level': level,
      if (parentCode != null) 'parentCode': parentCode,
      'revision': revision,
      if (sourceId != null) 'sourceId': sourceId,
    };
  }

  static IndustryInclude include() {
    return IndustryInclude._();
  }

  static IndustryIncludeList includeList({
    _is.WhereExpressionBuilder<IndustryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IndustryTable>? orderBy,
    _is.OrderByListBuilder<IndustryTable>? orderByList,
    IndustryInclude? include,
  }) {
    return IndustryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Industry.t),
      orderByList: orderByList?.call(Industry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndustryImpl extends Industry {
  _IndustryImpl({
    int? id,
    required String code,
    required String name,
    required int level,
    String? parentCode,
    required String revision,
    int? sourceId,
  }) : super._(
         id: id,
         code: code,
         name: name,
         level: level,
         parentCode: parentCode,
         revision: revision,
         sourceId: sourceId,
       );

  /// Returns a shallow copy of this [Industry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Industry copyWith({
    Object? id = _Undefined,
    String? code,
    String? name,
    int? level,
    Object? parentCode = _Undefined,
    String? revision,
    Object? sourceId = _Undefined,
  }) {
    return Industry(
      id: id is int? ? id : this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      level: level ?? this.level,
      parentCode: parentCode is String? ? parentCode : this.parentCode,
      revision: revision ?? this.revision,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
    );
  }
}

class IndustryUpdateTable extends _is.UpdateTable<IndustryTable> {
  IndustryUpdateTable(super.table);

  _is.ColumnValue<String, String> code(String value) => _is.ColumnValue(
    table.code,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<int, int> level(int value) => _is.ColumnValue(
    table.level,
    value,
  );

  _is.ColumnValue<String, String> parentCode(String? value) => _is.ColumnValue(
    table.parentCode,
    value,
  );

  _is.ColumnValue<String, String> revision(String value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );
}

class IndustryTable extends _is.Table<int?> {
  IndustryTable({super.tableRelation}) : super(tableName: 'industry') {
    updateTable = IndustryUpdateTable(this);
    code = _is.ColumnString(
      'code',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    level = _is.ColumnInt(
      'level',
      this,
    );
    parentCode = _is.ColumnString(
      'parentCode',
      this,
    );
    revision = _is.ColumnString(
      'revision',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
  }

  late final IndustryUpdateTable updateTable;

  /// A~U (대분류) 또는 2~5자리 숫자
  late final _is.ColumnString code;

  late final _is.ColumnString name;

  /// 1 대분류, 2 중분류, 3 소분류, 4 세분류, 5 세세분류
  late final _is.ColumnInt level;

  late final _is.ColumnString parentCode;

  /// 예: "KSIC 11"
  late final _is.ColumnString revision;

  /// 통계청 고시 자료
  late final _is.ColumnInt sourceId;

  @override
  List<_is.Column> get columns => [
    id,
    code,
    name,
    level,
    parentCode,
    revision,
    sourceId,
  ];
}

class IndustryInclude extends _is.IncludeObject {
  IndustryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Industry.t;
}

class IndustryIncludeList extends _is.IncludeList {
  IndustryIncludeList._({
    _is.WhereExpressionBuilder<IndustryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Industry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Industry.t;
}

class IndustryRepository {
  const IndustryRepository._();

  /// Returns a list of [Industry]s matching the given query parameters.
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
  Future<List<Industry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IndustryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IndustryTable>? orderBy,
    _is.OrderByListBuilder<IndustryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Industry>(
      where: where?.call(Industry.t),
      orderBy: orderBy?.call(Industry.t),
      orderByList: orderByList?.call(Industry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Industry] matching the given query parameters.
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
  Future<Industry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IndustryTable>? where,
    int? offset,
    _is.OrderByBuilder<IndustryTable>? orderBy,
    _is.OrderByListBuilder<IndustryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Industry>(
      where: where?.call(Industry.t),
      orderBy: orderBy?.call(Industry.t),
      orderByList: orderByList?.call(Industry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Industry] by its [id] or null if no such row exists.
  Future<Industry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Industry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Industry]s in the list and returns the inserted rows.
  ///
  /// The returned [Industry]s will have their `id` fields set.
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
  Future<List<Industry>> insert(
    _is.DatabaseSession session,
    List<Industry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Industry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Industry] and returns the inserted row.
  ///
  /// The returned [Industry] will have its `id` field set.
  Future<Industry> insertRow(
    _is.DatabaseSession session,
    Industry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Industry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Industry]s in the list and returns the resulting rows.
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
  /// The returned [Industry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Industry>> upsert(
    _is.DatabaseSession session,
    List<Industry> rows, {
    required _is.ColumnSelections<IndustryTable> conflictColumns,
    _is.ColumnSelections<IndustryTable>? updateColumns,
    _is.WhereExpressionBuilder<IndustryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Industry>(
      rows,
      conflictColumns: conflictColumns(Industry.t),
      updateColumns: updateColumns?.call(Industry.t),
      updateWhere: updateWhere?.call(Industry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Industry] and returns the resulting row.
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
  /// The returned [Industry] will have its `id` field set.
  Future<Industry?> upsertRow(
    _is.DatabaseSession session,
    Industry row, {
    required _is.ColumnSelections<IndustryTable> conflictColumns,
    _is.ColumnSelections<IndustryTable>? updateColumns,
    _is.WhereExpressionBuilder<IndustryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Industry>(
      row,
      conflictColumns: conflictColumns(Industry.t),
      updateColumns: updateColumns?.call(Industry.t),
      updateWhere: updateWhere?.call(Industry.t),
      transaction: transaction,
    );
  }

  /// Updates all [Industry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Industry>> update(
    _is.DatabaseSession session,
    List<Industry> rows, {
    _is.ColumnSelections<IndustryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Industry>(
      rows,
      columns: columns?.call(Industry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Industry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Industry> updateRow(
    _is.DatabaseSession session,
    Industry row, {
    _is.ColumnSelections<IndustryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Industry>(
      row,
      columns: columns?.call(Industry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Industry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Industry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<IndustryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Industry>(
      id,
      columnValues: columnValues(Industry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Industry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Industry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<IndustryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<IndustryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<IndustryTable>? orderBy,
    _is.OrderByListBuilder<IndustryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Industry>(
      columnValues: columnValues(Industry.t.updateTable),
      where: where(Industry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Industry.t),
      orderByList: orderByList?.call(Industry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Industry]s in the list and returns the deleted rows.
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
  Future<List<Industry>> delete(
    _is.DatabaseSession session,
    List<Industry> rows, {
    _is.OrderByBuilder<IndustryTable>? orderBy,
    _is.OrderByListBuilder<IndustryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Industry>(
      rows,
      orderBy: orderBy?.call(Industry.t),
      orderByList: orderByList?.call(Industry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Industry].
  Future<Industry> deleteRow(
    _is.DatabaseSession session,
    Industry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Industry>(
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
  Future<List<Industry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<IndustryTable> where,
    _is.OrderByBuilder<IndustryTable>? orderBy,
    _is.OrderByListBuilder<IndustryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Industry>(
      where: where(Industry.t),
      orderBy: orderBy?.call(Industry.t),
      orderByList: orderByList?.call(Industry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<IndustryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Industry>(
      where: where?.call(Industry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Industry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<IndustryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Industry>(
      where: where(Industry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
