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

/// 인물. 출생년월이 있는 임원, 또는 지분으로 이어진 기업 묶음에서 같은 이름으로 나오는 주주(추정)에게서 만든다.
abstract class Person implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Person._({
    this.id,
    required this.name,
    this.birthYear,
    this.birthMonth,
    this.sex,
    required this.personKey,
    required this.estimated,
  });

  factory Person({
    int? id,
    required String name,
    int? birthYear,
    int? birthMonth,
    String? sex,
    required String personKey,
    required bool estimated,
  }) = _PersonImpl;

  factory Person.fromJson(Map<String, dynamic> jsonSerialization) {
    return Person(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      birthYear: jsonSerialization['birthYear'] as int?,
      birthMonth: jsonSerialization['birthMonth'] as int?,
      sex: jsonSerialization['sex'] as String?,
      personKey: jsonSerialization['personKey'] as String,
      estimated: _is.BoolJsonExtension.fromJson(jsonSerialization['estimated']),
    );
  }

  static final t = PersonTable();

  static const db = PersonRepository._();

  @override
  int? id;

  /// 공백을 뗀 이름
  String name;

  int? birthYear;

  int? birthMonth;

  String? sex;

  /// 같은 사람을 찾는 키. 임원 "exec:이름:YYYY-MM", 추정 "cluster:이름:묶음의 첫 corpCode"
  String personKey;

  /// 출생년월 없이 이름과 기업 묶음으로만 정한 인물 (추정)
  bool estimated;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Person]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Person copyWith({
    int? id,
    String? name,
    int? birthYear,
    int? birthMonth,
    String? sex,
    String? personKey,
    bool? estimated,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Person',
      if (id != null) 'id': id,
      'name': name,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (sex != null) 'sex': sex,
      'personKey': personKey,
      'estimated': estimated,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Person',
      if (id != null) 'id': id,
      'name': name,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (sex != null) 'sex': sex,
      'personKey': personKey,
      'estimated': estimated,
    };
  }

  static PersonInclude include() {
    return PersonInclude._();
  }

  static PersonIncludeList includeList({
    _is.WhereExpressionBuilder<PersonTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PersonTable>? orderBy,
    _is.OrderByListBuilder<PersonTable>? orderByList,
    PersonInclude? include,
  }) {
    return PersonIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Person.t),
      orderByList: orderByList?.call(Person.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PersonImpl extends Person {
  _PersonImpl({
    int? id,
    required String name,
    int? birthYear,
    int? birthMonth,
    String? sex,
    required String personKey,
    required bool estimated,
  }) : super._(
         id: id,
         name: name,
         birthYear: birthYear,
         birthMonth: birthMonth,
         sex: sex,
         personKey: personKey,
         estimated: estimated,
       );

  /// Returns a shallow copy of this [Person]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Person copyWith({
    Object? id = _Undefined,
    String? name,
    Object? birthYear = _Undefined,
    Object? birthMonth = _Undefined,
    Object? sex = _Undefined,
    String? personKey,
    bool? estimated,
  }) {
    return Person(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      birthYear: birthYear is int? ? birthYear : this.birthYear,
      birthMonth: birthMonth is int? ? birthMonth : this.birthMonth,
      sex: sex is String? ? sex : this.sex,
      personKey: personKey ?? this.personKey,
      estimated: estimated ?? this.estimated,
    );
  }
}

class PersonUpdateTable extends _is.UpdateTable<PersonTable> {
  PersonUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<int, int> birthYear(int? value) => _is.ColumnValue(
    table.birthYear,
    value,
  );

  _is.ColumnValue<int, int> birthMonth(int? value) => _is.ColumnValue(
    table.birthMonth,
    value,
  );

  _is.ColumnValue<String, String> sex(String? value) => _is.ColumnValue(
    table.sex,
    value,
  );

  _is.ColumnValue<String, String> personKey(String value) => _is.ColumnValue(
    table.personKey,
    value,
  );

  _is.ColumnValue<bool, bool> estimated(bool value) => _is.ColumnValue(
    table.estimated,
    value,
  );
}

class PersonTable extends _is.Table<int?> {
  PersonTable({super.tableRelation}) : super(tableName: 'person') {
    updateTable = PersonUpdateTable(this);
    name = _is.ColumnString(
      'name',
      this,
    );
    birthYear = _is.ColumnInt(
      'birthYear',
      this,
    );
    birthMonth = _is.ColumnInt(
      'birthMonth',
      this,
    );
    sex = _is.ColumnString(
      'sex',
      this,
    );
    personKey = _is.ColumnString(
      'personKey',
      this,
    );
    estimated = _is.ColumnBool(
      'estimated',
      this,
    );
  }

  late final PersonUpdateTable updateTable;

  /// 공백을 뗀 이름
  late final _is.ColumnString name;

  late final _is.ColumnInt birthYear;

  late final _is.ColumnInt birthMonth;

  late final _is.ColumnString sex;

  /// 같은 사람을 찾는 키. 임원 "exec:이름:YYYY-MM", 추정 "cluster:이름:묶음의 첫 corpCode"
  late final _is.ColumnString personKey;

  /// 출생년월 없이 이름과 기업 묶음으로만 정한 인물 (추정)
  late final _is.ColumnBool estimated;

  @override
  List<_is.Column> get columns => [
    id,
    name,
    birthYear,
    birthMonth,
    sex,
    personKey,
    estimated,
  ];
}

class PersonInclude extends _is.IncludeObject {
  PersonInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Person.t;
}

class PersonIncludeList extends _is.IncludeList {
  PersonIncludeList._({
    _is.WhereExpressionBuilder<PersonTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Person.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Person.t;
}

class PersonRepository {
  const PersonRepository._();

  /// Returns a list of [Person]s matching the given query parameters.
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
  Future<List<Person>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PersonTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PersonTable>? orderBy,
    _is.OrderByListBuilder<PersonTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Person>(
      where: where?.call(Person.t),
      orderBy: orderBy?.call(Person.t),
      orderByList: orderByList?.call(Person.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Person] matching the given query parameters.
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
  Future<Person?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PersonTable>? where,
    int? offset,
    _is.OrderByBuilder<PersonTable>? orderBy,
    _is.OrderByListBuilder<PersonTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Person>(
      where: where?.call(Person.t),
      orderBy: orderBy?.call(Person.t),
      orderByList: orderByList?.call(Person.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Person] by its [id] or null if no such row exists.
  Future<Person?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Person>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Person]s in the list and returns the inserted rows.
  ///
  /// The returned [Person]s will have their `id` fields set.
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
  Future<List<Person>> insert(
    _is.DatabaseSession session,
    List<Person> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Person>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Person] and returns the inserted row.
  ///
  /// The returned [Person] will have its `id` field set.
  Future<Person> insertRow(
    _is.DatabaseSession session,
    Person row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Person>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Person]s in the list and returns the resulting rows.
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
  /// The returned [Person]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Person>> upsert(
    _is.DatabaseSession session,
    List<Person> rows, {
    required _is.ColumnSelections<PersonTable> conflictColumns,
    _is.ColumnSelections<PersonTable>? updateColumns,
    _is.WhereExpressionBuilder<PersonTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Person>(
      rows,
      conflictColumns: conflictColumns(Person.t),
      updateColumns: updateColumns?.call(Person.t),
      updateWhere: updateWhere?.call(Person.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Person] and returns the resulting row.
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
  /// The returned [Person] will have its `id` field set.
  Future<Person?> upsertRow(
    _is.DatabaseSession session,
    Person row, {
    required _is.ColumnSelections<PersonTable> conflictColumns,
    _is.ColumnSelections<PersonTable>? updateColumns,
    _is.WhereExpressionBuilder<PersonTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Person>(
      row,
      conflictColumns: conflictColumns(Person.t),
      updateColumns: updateColumns?.call(Person.t),
      updateWhere: updateWhere?.call(Person.t),
      transaction: transaction,
    );
  }

  /// Updates all [Person]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Person>> update(
    _is.DatabaseSession session,
    List<Person> rows, {
    _is.ColumnSelections<PersonTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Person>(
      rows,
      columns: columns?.call(Person.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Person]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Person> updateRow(
    _is.DatabaseSession session,
    Person row, {
    _is.ColumnSelections<PersonTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Person>(
      row,
      columns: columns?.call(Person.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Person] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Person?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PersonUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Person>(
      id,
      columnValues: columnValues(Person.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Person]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Person>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PersonUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PersonTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PersonTable>? orderBy,
    _is.OrderByListBuilder<PersonTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Person>(
      columnValues: columnValues(Person.t.updateTable),
      where: where(Person.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Person.t),
      orderByList: orderByList?.call(Person.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Person]s in the list and returns the deleted rows.
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
  Future<List<Person>> delete(
    _is.DatabaseSession session,
    List<Person> rows, {
    _is.OrderByBuilder<PersonTable>? orderBy,
    _is.OrderByListBuilder<PersonTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Person>(
      rows,
      orderBy: orderBy?.call(Person.t),
      orderByList: orderByList?.call(Person.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Person].
  Future<Person> deleteRow(
    _is.DatabaseSession session,
    Person row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Person>(
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
  Future<List<Person>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PersonTable> where,
    _is.OrderByBuilder<PersonTable>? orderBy,
    _is.OrderByListBuilder<PersonTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Person>(
      where: where(Person.t),
      orderBy: orderBy?.call(Person.t),
      orderByList: orderByList?.call(Person.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PersonTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Person>(
      where: where?.call(Person.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Person] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PersonTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Person>(
      where: where(Person.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
