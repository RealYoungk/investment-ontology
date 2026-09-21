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

import '../../ontology/models/executive_registration.dart' as _i5x1kqvd;

/// 임원 한 행 (임원 현황 exctvSttus). 회사마다 미등기 임원을 내는지가 다르다.
abstract class ExecutiveEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ExecutiveEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.name,
    this.sex,
    this.birthYear,
    this.birthMonth,
    this.position,
    required this.registration,
    this.registrationRaw,
    this.fullTime,
    this.duties,
    this.career,
    this.relationToLargestHolder,
    this.tenureMonths,
    this.termEndDate,
    this.personId,
  });

  factory ExecutiveEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String name,
    String? sex,
    int? birthYear,
    int? birthMonth,
    String? position,
    required _i5x1kqvd.ExecutiveRegistration registration,
    String? registrationRaw,
    bool? fullTime,
    String? duties,
    String? career,
    String? relationToLargestHolder,
    int? tenureMonths,
    DateTime? termEndDate,
    int? personId,
  }) = _ExecutiveEntryImpl;

  factory ExecutiveEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return ExecutiveEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      name: jsonSerialization['name'] as String,
      sex: jsonSerialization['sex'] as String?,
      birthYear: jsonSerialization['birthYear'] as int?,
      birthMonth: jsonSerialization['birthMonth'] as int?,
      position: jsonSerialization['position'] as String?,
      registration: _i5x1kqvd.ExecutiveRegistration.fromJson(
        (jsonSerialization['registration'] as String),
      ),
      registrationRaw: jsonSerialization['registrationRaw'] as String?,
      fullTime: jsonSerialization['fullTime'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['fullTime']),
      duties: jsonSerialization['duties'] as String?,
      career: jsonSerialization['career'] as String?,
      relationToLargestHolder:
          jsonSerialization['relationToLargestHolder'] as String?,
      tenureMonths: jsonSerialization['tenureMonths'] as int?,
      termEndDate: jsonSerialization['termEndDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['termEndDate'],
            ),
      personId: jsonSerialization['personId'] as int?,
    );
  }

  static final t = ExecutiveEntryTable();

  static const db = ExecutiveEntryRepository._();

  @override
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 줄바꿈·겹공백을 정리한 이름
  String name;

  String? sex;

  int? birthYear;

  int? birthMonth;

  /// 직위 원문
  String? position;

  _i5x1kqvd.ExecutiveRegistration registration;

  String? registrationRaw;

  /// 상근 여부
  bool? fullTime;

  String? duties;

  String? career;

  String? relationToLargestHolder;

  /// 재직기간 (개월)
  int? tenureMonths;

  DateTime? termEndDate;

  int? personId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ExecutiveEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ExecutiveEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? name,
    String? sex,
    int? birthYear,
    int? birthMonth,
    String? position,
    _i5x1kqvd.ExecutiveRegistration? registration,
    String? registrationRaw,
    bool? fullTime,
    String? duties,
    String? career,
    String? relationToLargestHolder,
    int? tenureMonths,
    DateTime? termEndDate,
    int? personId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ExecutiveEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'name': name,
      if (sex != null) 'sex': sex,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (position != null) 'position': position,
      'registration': registration.toJson(),
      if (registrationRaw != null) 'registrationRaw': registrationRaw,
      if (fullTime != null) 'fullTime': fullTime,
      if (duties != null) 'duties': duties,
      if (career != null) 'career': career,
      if (relationToLargestHolder != null)
        'relationToLargestHolder': relationToLargestHolder,
      if (tenureMonths != null) 'tenureMonths': tenureMonths,
      if (termEndDate != null) 'termEndDate': termEndDate?.toJson(),
      if (personId != null) 'personId': personId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ExecutiveEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'name': name,
      if (sex != null) 'sex': sex,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (position != null) 'position': position,
      'registration': registration.toJson(),
      if (registrationRaw != null) 'registrationRaw': registrationRaw,
      if (fullTime != null) 'fullTime': fullTime,
      if (duties != null) 'duties': duties,
      if (career != null) 'career': career,
      if (relationToLargestHolder != null)
        'relationToLargestHolder': relationToLargestHolder,
      if (tenureMonths != null) 'tenureMonths': tenureMonths,
      if (termEndDate != null) 'termEndDate': termEndDate?.toJson(),
      if (personId != null) 'personId': personId,
    };
  }

  static ExecutiveEntryInclude include() {
    return ExecutiveEntryInclude._();
  }

  static ExecutiveEntryIncludeList includeList({
    _is.WhereExpressionBuilder<ExecutiveEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ExecutiveEntryTable>? orderBy,
    _is.OrderByListBuilder<ExecutiveEntryTable>? orderByList,
    ExecutiveEntryInclude? include,
  }) {
    return ExecutiveEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ExecutiveEntry.t),
      orderByList: orderByList?.call(ExecutiveEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ExecutiveEntryImpl extends ExecutiveEntry {
  _ExecutiveEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String name,
    String? sex,
    int? birthYear,
    int? birthMonth,
    String? position,
    required _i5x1kqvd.ExecutiveRegistration registration,
    String? registrationRaw,
    bool? fullTime,
    String? duties,
    String? career,
    String? relationToLargestHolder,
    int? tenureMonths,
    DateTime? termEndDate,
    int? personId,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         name: name,
         sex: sex,
         birthYear: birthYear,
         birthMonth: birthMonth,
         position: position,
         registration: registration,
         registrationRaw: registrationRaw,
         fullTime: fullTime,
         duties: duties,
         career: career,
         relationToLargestHolder: relationToLargestHolder,
         tenureMonths: tenureMonths,
         termEndDate: termEndDate,
         personId: personId,
       );

  /// Returns a shallow copy of this [ExecutiveEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ExecutiveEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? name,
    Object? sex = _Undefined,
    Object? birthYear = _Undefined,
    Object? birthMonth = _Undefined,
    Object? position = _Undefined,
    _i5x1kqvd.ExecutiveRegistration? registration,
    Object? registrationRaw = _Undefined,
    Object? fullTime = _Undefined,
    Object? duties = _Undefined,
    Object? career = _Undefined,
    Object? relationToLargestHolder = _Undefined,
    Object? tenureMonths = _Undefined,
    Object? termEndDate = _Undefined,
    Object? personId = _Undefined,
  }) {
    return ExecutiveEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      name: name ?? this.name,
      sex: sex is String? ? sex : this.sex,
      birthYear: birthYear is int? ? birthYear : this.birthYear,
      birthMonth: birthMonth is int? ? birthMonth : this.birthMonth,
      position: position is String? ? position : this.position,
      registration: registration ?? this.registration,
      registrationRaw: registrationRaw is String?
          ? registrationRaw
          : this.registrationRaw,
      fullTime: fullTime is bool? ? fullTime : this.fullTime,
      duties: duties is String? ? duties : this.duties,
      career: career is String? ? career : this.career,
      relationToLargestHolder: relationToLargestHolder is String?
          ? relationToLargestHolder
          : this.relationToLargestHolder,
      tenureMonths: tenureMonths is int? ? tenureMonths : this.tenureMonths,
      termEndDate: termEndDate is DateTime? ? termEndDate : this.termEndDate,
      personId: personId is int? ? personId : this.personId,
    );
  }
}

class ExecutiveEntryUpdateTable extends _is.UpdateTable<ExecutiveEntryTable> {
  ExecutiveEntryUpdateTable(super.table);

  _is.ColumnValue<int, int> reportId(int value) => _is.ColumnValue(
    table.reportId,
    value,
  );

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<int, int> bsnsYear(int value) => _is.ColumnValue(
    table.bsnsYear,
    value,
  );

  _is.ColumnValue<int, int> ord(int value) => _is.ColumnValue(
    table.ord,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> sex(String? value) => _is.ColumnValue(
    table.sex,
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

  _is.ColumnValue<String, String> position(String? value) => _is.ColumnValue(
    table.position,
    value,
  );

  _is.ColumnValue<
    _i5x1kqvd.ExecutiveRegistration,
    _i5x1kqvd.ExecutiveRegistration
  >
  registration(_i5x1kqvd.ExecutiveRegistration value) => _is.ColumnValue(
    table.registration,
    value,
  );

  _is.ColumnValue<String, String> registrationRaw(String? value) =>
      _is.ColumnValue(
        table.registrationRaw,
        value,
      );

  _is.ColumnValue<bool, bool> fullTime(bool? value) => _is.ColumnValue(
    table.fullTime,
    value,
  );

  _is.ColumnValue<String, String> duties(String? value) => _is.ColumnValue(
    table.duties,
    value,
  );

  _is.ColumnValue<String, String> career(String? value) => _is.ColumnValue(
    table.career,
    value,
  );

  _is.ColumnValue<String, String> relationToLargestHolder(String? value) =>
      _is.ColumnValue(
        table.relationToLargestHolder,
        value,
      );

  _is.ColumnValue<int, int> tenureMonths(int? value) => _is.ColumnValue(
    table.tenureMonths,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> termEndDate(DateTime? value) =>
      _is.ColumnValue(
        table.termEndDate,
        value,
      );

  _is.ColumnValue<int, int> personId(int? value) => _is.ColumnValue(
    table.personId,
    value,
  );
}

class ExecutiveEntryTable extends _is.Table<int?> {
  ExecutiveEntryTable({super.tableRelation})
    : super(tableName: 'executive_entry') {
    updateTable = ExecutiveEntryUpdateTable(this);
    reportId = _is.ColumnInt(
      'reportId',
      this,
    );
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    bsnsYear = _is.ColumnInt(
      'bsnsYear',
      this,
    );
    ord = _is.ColumnInt(
      'ord',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    sex = _is.ColumnString(
      'sex',
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
    position = _is.ColumnString(
      'position',
      this,
    );
    registration = _is.ColumnEnum(
      'registration',
      this,
      _is.EnumSerialization.byName,
    );
    registrationRaw = _is.ColumnString(
      'registrationRaw',
      this,
    );
    fullTime = _is.ColumnBool(
      'fullTime',
      this,
    );
    duties = _is.ColumnString(
      'duties',
      this,
    );
    career = _is.ColumnString(
      'career',
      this,
    );
    relationToLargestHolder = _is.ColumnString(
      'relationToLargestHolder',
      this,
    );
    tenureMonths = _is.ColumnInt(
      'tenureMonths',
      this,
    );
    termEndDate = _is.ColumnDateTime(
      'termEndDate',
      this,
    );
    personId = _is.ColumnInt(
      'personId',
      this,
    );
  }

  late final ExecutiveEntryUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnInt ord;

  /// 줄바꿈·겹공백을 정리한 이름
  late final _is.ColumnString name;

  late final _is.ColumnString sex;

  late final _is.ColumnInt birthYear;

  late final _is.ColumnInt birthMonth;

  /// 직위 원문
  late final _is.ColumnString position;

  late final _is.ColumnEnum<_i5x1kqvd.ExecutiveRegistration> registration;

  late final _is.ColumnString registrationRaw;

  /// 상근 여부
  late final _is.ColumnBool fullTime;

  late final _is.ColumnString duties;

  late final _is.ColumnString career;

  late final _is.ColumnString relationToLargestHolder;

  /// 재직기간 (개월)
  late final _is.ColumnInt tenureMonths;

  late final _is.ColumnDateTime termEndDate;

  late final _is.ColumnInt personId;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    companyId,
    bsnsYear,
    ord,
    name,
    sex,
    birthYear,
    birthMonth,
    position,
    registration,
    registrationRaw,
    fullTime,
    duties,
    career,
    relationToLargestHolder,
    tenureMonths,
    termEndDate,
    personId,
  ];
}

class ExecutiveEntryInclude extends _is.IncludeObject {
  ExecutiveEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ExecutiveEntry.t;
}

class ExecutiveEntryIncludeList extends _is.IncludeList {
  ExecutiveEntryIncludeList._({
    _is.WhereExpressionBuilder<ExecutiveEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ExecutiveEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ExecutiveEntry.t;
}

class ExecutiveEntryRepository {
  const ExecutiveEntryRepository._();

  /// Returns a list of [ExecutiveEntry]s matching the given query parameters.
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
  Future<List<ExecutiveEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ExecutiveEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ExecutiveEntryTable>? orderBy,
    _is.OrderByListBuilder<ExecutiveEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ExecutiveEntry>(
      where: where?.call(ExecutiveEntry.t),
      orderBy: orderBy?.call(ExecutiveEntry.t),
      orderByList: orderByList?.call(ExecutiveEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ExecutiveEntry] matching the given query parameters.
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
  Future<ExecutiveEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ExecutiveEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<ExecutiveEntryTable>? orderBy,
    _is.OrderByListBuilder<ExecutiveEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ExecutiveEntry>(
      where: where?.call(ExecutiveEntry.t),
      orderBy: orderBy?.call(ExecutiveEntry.t),
      orderByList: orderByList?.call(ExecutiveEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ExecutiveEntry] by its [id] or null if no such row exists.
  Future<ExecutiveEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ExecutiveEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ExecutiveEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [ExecutiveEntry]s will have their `id` fields set.
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
  Future<List<ExecutiveEntry>> insert(
    _is.DatabaseSession session,
    List<ExecutiveEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ExecutiveEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ExecutiveEntry] and returns the inserted row.
  ///
  /// The returned [ExecutiveEntry] will have its `id` field set.
  Future<ExecutiveEntry> insertRow(
    _is.DatabaseSession session,
    ExecutiveEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ExecutiveEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ExecutiveEntry]s in the list and returns the resulting rows.
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
  /// The returned [ExecutiveEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ExecutiveEntry>> upsert(
    _is.DatabaseSession session,
    List<ExecutiveEntry> rows, {
    required _is.ColumnSelections<ExecutiveEntryTable> conflictColumns,
    _is.ColumnSelections<ExecutiveEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<ExecutiveEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ExecutiveEntry>(
      rows,
      conflictColumns: conflictColumns(ExecutiveEntry.t),
      updateColumns: updateColumns?.call(ExecutiveEntry.t),
      updateWhere: updateWhere?.call(ExecutiveEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ExecutiveEntry] and returns the resulting row.
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
  /// The returned [ExecutiveEntry] will have its `id` field set.
  Future<ExecutiveEntry?> upsertRow(
    _is.DatabaseSession session,
    ExecutiveEntry row, {
    required _is.ColumnSelections<ExecutiveEntryTable> conflictColumns,
    _is.ColumnSelections<ExecutiveEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<ExecutiveEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ExecutiveEntry>(
      row,
      conflictColumns: conflictColumns(ExecutiveEntry.t),
      updateColumns: updateColumns?.call(ExecutiveEntry.t),
      updateWhere: updateWhere?.call(ExecutiveEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [ExecutiveEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ExecutiveEntry>> update(
    _is.DatabaseSession session,
    List<ExecutiveEntry> rows, {
    _is.ColumnSelections<ExecutiveEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ExecutiveEntry>(
      rows,
      columns: columns?.call(ExecutiveEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ExecutiveEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ExecutiveEntry> updateRow(
    _is.DatabaseSession session,
    ExecutiveEntry row, {
    _is.ColumnSelections<ExecutiveEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ExecutiveEntry>(
      row,
      columns: columns?.call(ExecutiveEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ExecutiveEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ExecutiveEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ExecutiveEntryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ExecutiveEntry>(
      id,
      columnValues: columnValues(ExecutiveEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ExecutiveEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ExecutiveEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ExecutiveEntryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ExecutiveEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ExecutiveEntryTable>? orderBy,
    _is.OrderByListBuilder<ExecutiveEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ExecutiveEntry>(
      columnValues: columnValues(ExecutiveEntry.t.updateTable),
      where: where(ExecutiveEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ExecutiveEntry.t),
      orderByList: orderByList?.call(ExecutiveEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ExecutiveEntry]s in the list and returns the deleted rows.
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
  Future<List<ExecutiveEntry>> delete(
    _is.DatabaseSession session,
    List<ExecutiveEntry> rows, {
    _is.OrderByBuilder<ExecutiveEntryTable>? orderBy,
    _is.OrderByListBuilder<ExecutiveEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ExecutiveEntry>(
      rows,
      orderBy: orderBy?.call(ExecutiveEntry.t),
      orderByList: orderByList?.call(ExecutiveEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ExecutiveEntry].
  Future<ExecutiveEntry> deleteRow(
    _is.DatabaseSession session,
    ExecutiveEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ExecutiveEntry>(
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
  Future<List<ExecutiveEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ExecutiveEntryTable> where,
    _is.OrderByBuilder<ExecutiveEntryTable>? orderBy,
    _is.OrderByListBuilder<ExecutiveEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ExecutiveEntry>(
      where: where(ExecutiveEntry.t),
      orderBy: orderBy?.call(ExecutiveEntry.t),
      orderByList: orderByList?.call(ExecutiveEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ExecutiveEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ExecutiveEntry>(
      where: where?.call(ExecutiveEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ExecutiveEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ExecutiveEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ExecutiveEntry>(
      where: where(ExecutiveEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
