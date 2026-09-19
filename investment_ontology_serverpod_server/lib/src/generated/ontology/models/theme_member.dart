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

/// 기업의 테마 편입 (EXPOSED_TO). 사람의 판단이라 출처는 manual이고, 왜 넣었는지 메모를 남긴다.
abstract class ThemeMember
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ThemeMember._({
    this.id,
    required this.themeId,
    required this.companyId,
    this.note,
    required this.sourceId,
    required this.createdAt,
  });

  factory ThemeMember({
    int? id,
    required int themeId,
    required int companyId,
    String? note,
    required int sourceId,
    required DateTime createdAt,
  }) = _ThemeMemberImpl;

  factory ThemeMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemeMember(
      id: jsonSerialization['id'] as int?,
      themeId: jsonSerialization['themeId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      note: jsonSerialization['note'] as String?,
      sourceId: jsonSerialization['sourceId'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ThemeMemberTable();

  static const db = ThemeMemberRepository._();

  @override
  int? id;

  int themeId;

  int companyId;

  /// 노출도 메모 (왜 이 테마인지)
  String? note;

  int sourceId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ThemeMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ThemeMember copyWith({
    int? id,
    int? themeId,
    int? companyId,
    String? note,
    int? sourceId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeMember',
      if (id != null) 'id': id,
      'themeId': themeId,
      'companyId': companyId,
      if (note != null) 'note': note,
      'sourceId': sourceId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemeMember',
      if (id != null) 'id': id,
      'themeId': themeId,
      'companyId': companyId,
      if (note != null) 'note': note,
      'sourceId': sourceId,
      'createdAt': createdAt.toJson(),
    };
  }

  static ThemeMemberInclude include() {
    return ThemeMemberInclude._();
  }

  static ThemeMemberIncludeList includeList({
    _is.WhereExpressionBuilder<ThemeMemberTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ThemeMemberTable>? orderBy,
    _is.OrderByListBuilder<ThemeMemberTable>? orderByList,
    ThemeMemberInclude? include,
  }) {
    return ThemeMemberIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ThemeMember.t),
      orderByList: orderByList?.call(ThemeMember.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemeMemberImpl extends ThemeMember {
  _ThemeMemberImpl({
    int? id,
    required int themeId,
    required int companyId,
    String? note,
    required int sourceId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         themeId: themeId,
         companyId: companyId,
         note: note,
         sourceId: sourceId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ThemeMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ThemeMember copyWith({
    Object? id = _Undefined,
    int? themeId,
    int? companyId,
    Object? note = _Undefined,
    int? sourceId,
    DateTime? createdAt,
  }) {
    return ThemeMember(
      id: id is int? ? id : this.id,
      themeId: themeId ?? this.themeId,
      companyId: companyId ?? this.companyId,
      note: note is String? ? note : this.note,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ThemeMemberUpdateTable extends _is.UpdateTable<ThemeMemberTable> {
  ThemeMemberUpdateTable(super.table);

  _is.ColumnValue<int, int> themeId(int value) => _is.ColumnValue(
    table.themeId,
    value,
  );

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<String, String> note(String? value) => _is.ColumnValue(
    table.note,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ThemeMemberTable extends _is.Table<int?> {
  ThemeMemberTable({super.tableRelation}) : super(tableName: 'theme_member') {
    updateTable = ThemeMemberUpdateTable(this);
    themeId = _is.ColumnInt(
      'themeId',
      this,
    );
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    note = _is.ColumnString(
      'note',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ThemeMemberUpdateTable updateTable;

  late final _is.ColumnInt themeId;

  late final _is.ColumnInt companyId;

  /// 노출도 메모 (왜 이 테마인지)
  late final _is.ColumnString note;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    themeId,
    companyId,
    note,
    sourceId,
    createdAt,
  ];
}

class ThemeMemberInclude extends _is.IncludeObject {
  ThemeMemberInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ThemeMember.t;
}

class ThemeMemberIncludeList extends _is.IncludeList {
  ThemeMemberIncludeList._({
    _is.WhereExpressionBuilder<ThemeMemberTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ThemeMember.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ThemeMember.t;
}

class ThemeMemberRepository {
  const ThemeMemberRepository._();

  /// Returns a list of [ThemeMember]s matching the given query parameters.
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
  Future<List<ThemeMember>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ThemeMemberTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ThemeMemberTable>? orderBy,
    _is.OrderByListBuilder<ThemeMemberTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ThemeMember>(
      where: where?.call(ThemeMember.t),
      orderBy: orderBy?.call(ThemeMember.t),
      orderByList: orderByList?.call(ThemeMember.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ThemeMember] matching the given query parameters.
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
  Future<ThemeMember?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ThemeMemberTable>? where,
    int? offset,
    _is.OrderByBuilder<ThemeMemberTable>? orderBy,
    _is.OrderByListBuilder<ThemeMemberTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ThemeMember>(
      where: where?.call(ThemeMember.t),
      orderBy: orderBy?.call(ThemeMember.t),
      orderByList: orderByList?.call(ThemeMember.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ThemeMember] by its [id] or null if no such row exists.
  Future<ThemeMember?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ThemeMember>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ThemeMember]s in the list and returns the inserted rows.
  ///
  /// The returned [ThemeMember]s will have their `id` fields set.
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
  Future<List<ThemeMember>> insert(
    _is.DatabaseSession session,
    List<ThemeMember> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ThemeMember>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ThemeMember] and returns the inserted row.
  ///
  /// The returned [ThemeMember] will have its `id` field set.
  Future<ThemeMember> insertRow(
    _is.DatabaseSession session,
    ThemeMember row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ThemeMember>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ThemeMember]s in the list and returns the resulting rows.
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
  /// The returned [ThemeMember]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ThemeMember>> upsert(
    _is.DatabaseSession session,
    List<ThemeMember> rows, {
    required _is.ColumnSelections<ThemeMemberTable> conflictColumns,
    _is.ColumnSelections<ThemeMemberTable>? updateColumns,
    _is.WhereExpressionBuilder<ThemeMemberTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ThemeMember>(
      rows,
      conflictColumns: conflictColumns(ThemeMember.t),
      updateColumns: updateColumns?.call(ThemeMember.t),
      updateWhere: updateWhere?.call(ThemeMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ThemeMember] and returns the resulting row.
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
  /// The returned [ThemeMember] will have its `id` field set.
  Future<ThemeMember?> upsertRow(
    _is.DatabaseSession session,
    ThemeMember row, {
    required _is.ColumnSelections<ThemeMemberTable> conflictColumns,
    _is.ColumnSelections<ThemeMemberTable>? updateColumns,
    _is.WhereExpressionBuilder<ThemeMemberTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ThemeMember>(
      row,
      conflictColumns: conflictColumns(ThemeMember.t),
      updateColumns: updateColumns?.call(ThemeMember.t),
      updateWhere: updateWhere?.call(ThemeMember.t),
      transaction: transaction,
    );
  }

  /// Updates all [ThemeMember]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ThemeMember>> update(
    _is.DatabaseSession session,
    List<ThemeMember> rows, {
    _is.ColumnSelections<ThemeMemberTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ThemeMember>(
      rows,
      columns: columns?.call(ThemeMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ThemeMember]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ThemeMember> updateRow(
    _is.DatabaseSession session,
    ThemeMember row, {
    _is.ColumnSelections<ThemeMemberTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ThemeMember>(
      row,
      columns: columns?.call(ThemeMember.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ThemeMember] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ThemeMember?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ThemeMemberUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ThemeMember>(
      id,
      columnValues: columnValues(ThemeMember.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ThemeMember]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ThemeMember>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ThemeMemberUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ThemeMemberTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ThemeMemberTable>? orderBy,
    _is.OrderByListBuilder<ThemeMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ThemeMember>(
      columnValues: columnValues(ThemeMember.t.updateTable),
      where: where(ThemeMember.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ThemeMember.t),
      orderByList: orderByList?.call(ThemeMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ThemeMember]s in the list and returns the deleted rows.
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
  Future<List<ThemeMember>> delete(
    _is.DatabaseSession session,
    List<ThemeMember> rows, {
    _is.OrderByBuilder<ThemeMemberTable>? orderBy,
    _is.OrderByListBuilder<ThemeMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ThemeMember>(
      rows,
      orderBy: orderBy?.call(ThemeMember.t),
      orderByList: orderByList?.call(ThemeMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ThemeMember].
  Future<ThemeMember> deleteRow(
    _is.DatabaseSession session,
    ThemeMember row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ThemeMember>(
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
  Future<List<ThemeMember>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ThemeMemberTable> where,
    _is.OrderByBuilder<ThemeMemberTable>? orderBy,
    _is.OrderByListBuilder<ThemeMemberTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ThemeMember>(
      where: where(ThemeMember.t),
      orderBy: orderBy?.call(ThemeMember.t),
      orderByList: orderByList?.call(ThemeMember.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ThemeMemberTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ThemeMember>(
      where: where?.call(ThemeMember.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ThemeMember] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ThemeMemberTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ThemeMember>(
      where: where(ThemeMember.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
