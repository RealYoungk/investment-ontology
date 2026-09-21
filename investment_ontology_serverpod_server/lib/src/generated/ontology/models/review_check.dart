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

/// 검수 정확률 기록: 뽑아 둔 것을 원문과 하나씩 대조하고 그 결과를 숫자로 남긴다.
///
/// 모델이 스스로 매긴 확신도(confidence)와 다르다. 이건 실제로 몇 건이 맞았는지다.
abstract class ReviewCheck
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ReviewCheck._({
    this.id,
    required this.scope,
    required this.checked,
    required this.correct,
    required this.leftToPerson,
    required this.checkedBy,
    this.note,
    required this.createdAt,
  });

  factory ReviewCheck({
    int? id,
    required String scope,
    required int checked,
    required int correct,
    required int leftToPerson,
    required String checkedBy,
    String? note,
    required DateTime createdAt,
  }) = _ReviewCheckImpl;

  factory ReviewCheck.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewCheck(
      id: jsonSerialization['id'] as int?,
      scope: jsonSerialization['scope'] as String,
      checked: jsonSerialization['checked'] as int,
      correct: jsonSerialization['correct'] as int,
      leftToPerson: jsonSerialization['leftToPerson'] as int,
      checkedBy: jsonSerialization['checkedBy'] as String,
      note: jsonSerialization['note'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = ReviewCheckTable();

  static const db = ReviewCheckRepository._();

  @override
  int? id;

  /// relation · fact
  String scope;

  /// 대조한 건수
  int checked;

  /// 원문과 맞았던 건수
  int correct;

  /// 사람 판단으로 남긴 건수 (애매해서 넘긴 것)
  int leftToPerson;

  /// 누가 대조했는지
  String checkedBy;

  String? note;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ReviewCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReviewCheck copyWith({
    int? id,
    String? scope,
    int? checked,
    int? correct,
    int? leftToPerson,
    String? checkedBy,
    String? note,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewCheck',
      if (id != null) 'id': id,
      'scope': scope,
      'checked': checked,
      'correct': correct,
      'leftToPerson': leftToPerson,
      'checkedBy': checkedBy,
      if (note != null) 'note': note,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewCheck',
      if (id != null) 'id': id,
      'scope': scope,
      'checked': checked,
      'correct': correct,
      'leftToPerson': leftToPerson,
      'checkedBy': checkedBy,
      if (note != null) 'note': note,
      'createdAt': createdAt.toJson(),
    };
  }

  static ReviewCheckInclude include() {
    return ReviewCheckInclude._();
  }

  static ReviewCheckIncludeList includeList({
    _is.WhereExpressionBuilder<ReviewCheckTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReviewCheckTable>? orderBy,
    _is.OrderByListBuilder<ReviewCheckTable>? orderByList,
    ReviewCheckInclude? include,
  }) {
    return ReviewCheckIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReviewCheck.t),
      orderByList: orderByList?.call(ReviewCheck.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReviewCheckImpl extends ReviewCheck {
  _ReviewCheckImpl({
    int? id,
    required String scope,
    required int checked,
    required int correct,
    required int leftToPerson,
    required String checkedBy,
    String? note,
    required DateTime createdAt,
  }) : super._(
         id: id,
         scope: scope,
         checked: checked,
         correct: correct,
         leftToPerson: leftToPerson,
         checkedBy: checkedBy,
         note: note,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ReviewCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReviewCheck copyWith({
    Object? id = _Undefined,
    String? scope,
    int? checked,
    int? correct,
    int? leftToPerson,
    String? checkedBy,
    Object? note = _Undefined,
    DateTime? createdAt,
  }) {
    return ReviewCheck(
      id: id is int? ? id : this.id,
      scope: scope ?? this.scope,
      checked: checked ?? this.checked,
      correct: correct ?? this.correct,
      leftToPerson: leftToPerson ?? this.leftToPerson,
      checkedBy: checkedBy ?? this.checkedBy,
      note: note is String? ? note : this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReviewCheckUpdateTable extends _is.UpdateTable<ReviewCheckTable> {
  ReviewCheckUpdateTable(super.table);

  _is.ColumnValue<String, String> scope(String value) => _is.ColumnValue(
    table.scope,
    value,
  );

  _is.ColumnValue<int, int> checked(int value) => _is.ColumnValue(
    table.checked,
    value,
  );

  _is.ColumnValue<int, int> correct(int value) => _is.ColumnValue(
    table.correct,
    value,
  );

  _is.ColumnValue<int, int> leftToPerson(int value) => _is.ColumnValue(
    table.leftToPerson,
    value,
  );

  _is.ColumnValue<String, String> checkedBy(String value) => _is.ColumnValue(
    table.checkedBy,
    value,
  );

  _is.ColumnValue<String, String> note(String? value) => _is.ColumnValue(
    table.note,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ReviewCheckTable extends _is.Table<int?> {
  ReviewCheckTable({super.tableRelation}) : super(tableName: 'review_check') {
    updateTable = ReviewCheckUpdateTable(this);
    scope = _is.ColumnString(
      'scope',
      this,
    );
    checked = _is.ColumnInt(
      'checked',
      this,
    );
    correct = _is.ColumnInt(
      'correct',
      this,
    );
    leftToPerson = _is.ColumnInt(
      'leftToPerson',
      this,
    );
    checkedBy = _is.ColumnString(
      'checkedBy',
      this,
    );
    note = _is.ColumnString(
      'note',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ReviewCheckUpdateTable updateTable;

  /// relation · fact
  late final _is.ColumnString scope;

  /// 대조한 건수
  late final _is.ColumnInt checked;

  /// 원문과 맞았던 건수
  late final _is.ColumnInt correct;

  /// 사람 판단으로 남긴 건수 (애매해서 넘긴 것)
  late final _is.ColumnInt leftToPerson;

  /// 누가 대조했는지
  late final _is.ColumnString checkedBy;

  late final _is.ColumnString note;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    scope,
    checked,
    correct,
    leftToPerson,
    checkedBy,
    note,
    createdAt,
  ];
}

class ReviewCheckInclude extends _is.IncludeObject {
  ReviewCheckInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ReviewCheck.t;
}

class ReviewCheckIncludeList extends _is.IncludeList {
  ReviewCheckIncludeList._({
    _is.WhereExpressionBuilder<ReviewCheckTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ReviewCheck.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ReviewCheck.t;
}

class ReviewCheckRepository {
  const ReviewCheckRepository._();

  /// Returns a list of [ReviewCheck]s matching the given query parameters.
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
  Future<List<ReviewCheck>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReviewCheckTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReviewCheckTable>? orderBy,
    _is.OrderByListBuilder<ReviewCheckTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ReviewCheck>(
      where: where?.call(ReviewCheck.t),
      orderBy: orderBy?.call(ReviewCheck.t),
      orderByList: orderByList?.call(ReviewCheck.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ReviewCheck] matching the given query parameters.
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
  Future<ReviewCheck?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReviewCheckTable>? where,
    int? offset,
    _is.OrderByBuilder<ReviewCheckTable>? orderBy,
    _is.OrderByListBuilder<ReviewCheckTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ReviewCheck>(
      where: where?.call(ReviewCheck.t),
      orderBy: orderBy?.call(ReviewCheck.t),
      orderByList: orderByList?.call(ReviewCheck.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ReviewCheck] by its [id] or null if no such row exists.
  Future<ReviewCheck?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ReviewCheck>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ReviewCheck]s in the list and returns the inserted rows.
  ///
  /// The returned [ReviewCheck]s will have their `id` fields set.
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
  Future<List<ReviewCheck>> insert(
    _is.DatabaseSession session,
    List<ReviewCheck> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ReviewCheck>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ReviewCheck] and returns the inserted row.
  ///
  /// The returned [ReviewCheck] will have its `id` field set.
  Future<ReviewCheck> insertRow(
    _is.DatabaseSession session,
    ReviewCheck row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ReviewCheck>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ReviewCheck]s in the list and returns the resulting rows.
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
  /// The returned [ReviewCheck]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReviewCheck>> upsert(
    _is.DatabaseSession session,
    List<ReviewCheck> rows, {
    required _is.ColumnSelections<ReviewCheckTable> conflictColumns,
    _is.ColumnSelections<ReviewCheckTable>? updateColumns,
    _is.WhereExpressionBuilder<ReviewCheckTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ReviewCheck>(
      rows,
      conflictColumns: conflictColumns(ReviewCheck.t),
      updateColumns: updateColumns?.call(ReviewCheck.t),
      updateWhere: updateWhere?.call(ReviewCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ReviewCheck] and returns the resulting row.
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
  /// The returned [ReviewCheck] will have its `id` field set.
  Future<ReviewCheck?> upsertRow(
    _is.DatabaseSession session,
    ReviewCheck row, {
    required _is.ColumnSelections<ReviewCheckTable> conflictColumns,
    _is.ColumnSelections<ReviewCheckTable>? updateColumns,
    _is.WhereExpressionBuilder<ReviewCheckTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ReviewCheck>(
      row,
      conflictColumns: conflictColumns(ReviewCheck.t),
      updateColumns: updateColumns?.call(ReviewCheck.t),
      updateWhere: updateWhere?.call(ReviewCheck.t),
      transaction: transaction,
    );
  }

  /// Updates all [ReviewCheck]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReviewCheck>> update(
    _is.DatabaseSession session,
    List<ReviewCheck> rows, {
    _is.ColumnSelections<ReviewCheckTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ReviewCheck>(
      rows,
      columns: columns?.call(ReviewCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ReviewCheck]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ReviewCheck> updateRow(
    _is.DatabaseSession session,
    ReviewCheck row, {
    _is.ColumnSelections<ReviewCheckTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ReviewCheck>(
      row,
      columns: columns?.call(ReviewCheck.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ReviewCheck] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ReviewCheck?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ReviewCheckUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ReviewCheck>(
      id,
      columnValues: columnValues(ReviewCheck.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ReviewCheck]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ReviewCheck>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ReviewCheckUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ReviewCheckTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ReviewCheckTable>? orderBy,
    _is.OrderByListBuilder<ReviewCheckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ReviewCheck>(
      columnValues: columnValues(ReviewCheck.t.updateTable),
      where: where(ReviewCheck.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ReviewCheck.t),
      orderByList: orderByList?.call(ReviewCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ReviewCheck]s in the list and returns the deleted rows.
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
  Future<List<ReviewCheck>> delete(
    _is.DatabaseSession session,
    List<ReviewCheck> rows, {
    _is.OrderByBuilder<ReviewCheckTable>? orderBy,
    _is.OrderByListBuilder<ReviewCheckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ReviewCheck>(
      rows,
      orderBy: orderBy?.call(ReviewCheck.t),
      orderByList: orderByList?.call(ReviewCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ReviewCheck].
  Future<ReviewCheck> deleteRow(
    _is.DatabaseSession session,
    ReviewCheck row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ReviewCheck>(
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
  Future<List<ReviewCheck>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ReviewCheckTable> where,
    _is.OrderByBuilder<ReviewCheckTable>? orderBy,
    _is.OrderByListBuilder<ReviewCheckTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ReviewCheck>(
      where: where(ReviewCheck.t),
      orderBy: orderBy?.call(ReviewCheck.t),
      orderByList: orderByList?.call(ReviewCheck.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ReviewCheckTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ReviewCheck>(
      where: where?.call(ReviewCheck.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ReviewCheck] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ReviewCheckTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ReviewCheck>(
      where: where(ReviewCheck.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
