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

/// 사람이 끊은 추정 인물 연결. 연결을 다시 계산해도 이 기업의 이 이름은 묶지 않는다.
abstract class PersonLinkRejection
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PersonLinkRejection._({
    this.id,
    required this.companyId,
    required this.name,
    required this.createdAt,
  });

  factory PersonLinkRejection({
    int? id,
    required int companyId,
    required String name,
    required DateTime createdAt,
  }) = _PersonLinkRejectionImpl;

  factory PersonLinkRejection.fromJson(Map<String, dynamic> jsonSerialization) {
    return PersonLinkRejection(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      name: jsonSerialization['name'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = PersonLinkRejectionTable();

  static const db = PersonLinkRejectionRepository._();

  @override
  int? id;

  int companyId;

  /// 공백을 뗀 이름
  String name;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PersonLinkRejection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PersonLinkRejection copyWith({
    int? id,
    int? companyId,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PersonLinkRejection',
      if (id != null) 'id': id,
      'companyId': companyId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PersonLinkRejection',
      if (id != null) 'id': id,
      'companyId': companyId,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  static PersonLinkRejectionInclude include() {
    return PersonLinkRejectionInclude._();
  }

  static PersonLinkRejectionIncludeList includeList({
    _is.WhereExpressionBuilder<PersonLinkRejectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PersonLinkRejectionTable>? orderBy,
    _is.OrderByListBuilder<PersonLinkRejectionTable>? orderByList,
    PersonLinkRejectionInclude? include,
  }) {
    return PersonLinkRejectionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PersonLinkRejection.t),
      orderByList: orderByList?.call(PersonLinkRejection.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PersonLinkRejectionImpl extends PersonLinkRejection {
  _PersonLinkRejectionImpl({
    int? id,
    required int companyId,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         companyId: companyId,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PersonLinkRejection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PersonLinkRejection copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? name,
    DateTime? createdAt,
  }) {
    return PersonLinkRejection(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PersonLinkRejectionUpdateTable
    extends _is.UpdateTable<PersonLinkRejectionTable> {
  PersonLinkRejectionUpdateTable(super.table);

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class PersonLinkRejectionTable extends _is.Table<int?> {
  PersonLinkRejectionTable({super.tableRelation})
    : super(tableName: 'person_link_rejection') {
    updateTable = PersonLinkRejectionUpdateTable(this);
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final PersonLinkRejectionUpdateTable updateTable;

  late final _is.ColumnInt companyId;

  /// 공백을 뗀 이름
  late final _is.ColumnString name;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    companyId,
    name,
    createdAt,
  ];
}

class PersonLinkRejectionInclude extends _is.IncludeObject {
  PersonLinkRejectionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PersonLinkRejection.t;
}

class PersonLinkRejectionIncludeList extends _is.IncludeList {
  PersonLinkRejectionIncludeList._({
    _is.WhereExpressionBuilder<PersonLinkRejectionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PersonLinkRejection.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PersonLinkRejection.t;
}

class PersonLinkRejectionRepository {
  const PersonLinkRejectionRepository._();

  /// Returns a list of [PersonLinkRejection]s matching the given query parameters.
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
  Future<List<PersonLinkRejection>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PersonLinkRejectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PersonLinkRejectionTable>? orderBy,
    _is.OrderByListBuilder<PersonLinkRejectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PersonLinkRejection>(
      where: where?.call(PersonLinkRejection.t),
      orderBy: orderBy?.call(PersonLinkRejection.t),
      orderByList: orderByList?.call(PersonLinkRejection.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PersonLinkRejection] matching the given query parameters.
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
  Future<PersonLinkRejection?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PersonLinkRejectionTable>? where,
    int? offset,
    _is.OrderByBuilder<PersonLinkRejectionTable>? orderBy,
    _is.OrderByListBuilder<PersonLinkRejectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PersonLinkRejection>(
      where: where?.call(PersonLinkRejection.t),
      orderBy: orderBy?.call(PersonLinkRejection.t),
      orderByList: orderByList?.call(PersonLinkRejection.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PersonLinkRejection] by its [id] or null if no such row exists.
  Future<PersonLinkRejection?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PersonLinkRejection>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PersonLinkRejection]s in the list and returns the inserted rows.
  ///
  /// The returned [PersonLinkRejection]s will have their `id` fields set.
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
  Future<List<PersonLinkRejection>> insert(
    _is.DatabaseSession session,
    List<PersonLinkRejection> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PersonLinkRejection>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PersonLinkRejection] and returns the inserted row.
  ///
  /// The returned [PersonLinkRejection] will have its `id` field set.
  Future<PersonLinkRejection> insertRow(
    _is.DatabaseSession session,
    PersonLinkRejection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PersonLinkRejection>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PersonLinkRejection]s in the list and returns the resulting rows.
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
  /// The returned [PersonLinkRejection]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PersonLinkRejection>> upsert(
    _is.DatabaseSession session,
    List<PersonLinkRejection> rows, {
    required _is.ColumnSelections<PersonLinkRejectionTable> conflictColumns,
    _is.ColumnSelections<PersonLinkRejectionTable>? updateColumns,
    _is.WhereExpressionBuilder<PersonLinkRejectionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PersonLinkRejection>(
      rows,
      conflictColumns: conflictColumns(PersonLinkRejection.t),
      updateColumns: updateColumns?.call(PersonLinkRejection.t),
      updateWhere: updateWhere?.call(PersonLinkRejection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PersonLinkRejection] and returns the resulting row.
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
  /// The returned [PersonLinkRejection] will have its `id` field set.
  Future<PersonLinkRejection?> upsertRow(
    _is.DatabaseSession session,
    PersonLinkRejection row, {
    required _is.ColumnSelections<PersonLinkRejectionTable> conflictColumns,
    _is.ColumnSelections<PersonLinkRejectionTable>? updateColumns,
    _is.WhereExpressionBuilder<PersonLinkRejectionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PersonLinkRejection>(
      row,
      conflictColumns: conflictColumns(PersonLinkRejection.t),
      updateColumns: updateColumns?.call(PersonLinkRejection.t),
      updateWhere: updateWhere?.call(PersonLinkRejection.t),
      transaction: transaction,
    );
  }

  /// Updates all [PersonLinkRejection]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PersonLinkRejection>> update(
    _is.DatabaseSession session,
    List<PersonLinkRejection> rows, {
    _is.ColumnSelections<PersonLinkRejectionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PersonLinkRejection>(
      rows,
      columns: columns?.call(PersonLinkRejection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PersonLinkRejection]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PersonLinkRejection> updateRow(
    _is.DatabaseSession session,
    PersonLinkRejection row, {
    _is.ColumnSelections<PersonLinkRejectionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PersonLinkRejection>(
      row,
      columns: columns?.call(PersonLinkRejection.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PersonLinkRejection] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PersonLinkRejection?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PersonLinkRejectionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PersonLinkRejection>(
      id,
      columnValues: columnValues(PersonLinkRejection.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PersonLinkRejection]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PersonLinkRejection>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PersonLinkRejectionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PersonLinkRejectionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PersonLinkRejectionTable>? orderBy,
    _is.OrderByListBuilder<PersonLinkRejectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PersonLinkRejection>(
      columnValues: columnValues(PersonLinkRejection.t.updateTable),
      where: where(PersonLinkRejection.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PersonLinkRejection.t),
      orderByList: orderByList?.call(PersonLinkRejection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PersonLinkRejection]s in the list and returns the deleted rows.
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
  Future<List<PersonLinkRejection>> delete(
    _is.DatabaseSession session,
    List<PersonLinkRejection> rows, {
    _is.OrderByBuilder<PersonLinkRejectionTable>? orderBy,
    _is.OrderByListBuilder<PersonLinkRejectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PersonLinkRejection>(
      rows,
      orderBy: orderBy?.call(PersonLinkRejection.t),
      orderByList: orderByList?.call(PersonLinkRejection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PersonLinkRejection].
  Future<PersonLinkRejection> deleteRow(
    _is.DatabaseSession session,
    PersonLinkRejection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PersonLinkRejection>(
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
  Future<List<PersonLinkRejection>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PersonLinkRejectionTable> where,
    _is.OrderByBuilder<PersonLinkRejectionTable>? orderBy,
    _is.OrderByListBuilder<PersonLinkRejectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PersonLinkRejection>(
      where: where(PersonLinkRejection.t),
      orderBy: orderBy?.call(PersonLinkRejection.t),
      orderByList: orderByList?.call(PersonLinkRejection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PersonLinkRejectionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PersonLinkRejection>(
      where: where?.call(PersonLinkRejection.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PersonLinkRejection] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PersonLinkRejectionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PersonLinkRejection>(
      where: where(PersonLinkRejection.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
