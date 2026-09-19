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
import '../../ontology/models/dart_section.dart' as _iy0bhrwp;
import '../../ontology/models/filing_fetch_status.dart' as _iy9345ub;

/// 수집 장부: 정기보고서(DartFiling) 한 건 × 주요정보 항목 하나의 수집 상태.
/// 항목이 늘어도 스키마를 바꾸지 않도록 항목마다 행으로 둔다.
abstract class DartFilingSection
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DartFilingSection._({
    this.id,
    required this.filingId,
    required this.companyId,
    required this.bsnsYear,
    required this.section,
    required this.tier,
    required this.status,
    int? attempts,
    this.lastError,
    this.fetchedAt,
  }) : attempts = attempts ?? 0;

  factory DartFilingSection({
    int? id,
    required int filingId,
    required int companyId,
    required int bsnsYear,
    required _iy0bhrwp.DartSection section,
    required int tier,
    required _iy9345ub.FilingFetchStatus status,
    int? attempts,
    String? lastError,
    DateTime? fetchedAt,
  }) = _DartFilingSectionImpl;

  factory DartFilingSection.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartFilingSection(
      id: jsonSerialization['id'] as int?,
      filingId: jsonSerialization['filingId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      section: _iy0bhrwp.DartSection.fromJson(
        (jsonSerialization['section'] as String),
      ),
      tier: jsonSerialization['tier'] as int,
      status: _iy9345ub.FilingFetchStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      attempts: jsonSerialization['attempts'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      fetchedAt: jsonSerialization['fetchedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['fetchedAt']),
    );
  }

  static final t = DartFilingSectionTable();

  static const db = DartFilingSectionRepository._();

  @override
  int? id;

  int filingId;

  int companyId;

  int bsnsYear;

  _iy0bhrwp.DartSection section;

  /// 받는 순서. 0 = 핵심 (지배구조·주주환원), 1 = 나머지
  int tier;

  _iy9345ub.FilingFetchStatus status;

  /// 실패한 실행 수
  int attempts;

  String? lastError;

  DateTime? fetchedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DartFilingSection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DartFilingSection copyWith({
    int? id,
    int? filingId,
    int? companyId,
    int? bsnsYear,
    _iy0bhrwp.DartSection? section,
    int? tier,
    _iy9345ub.FilingFetchStatus? status,
    int? attempts,
    String? lastError,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartFilingSection',
      if (id != null) 'id': id,
      'filingId': filingId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'section': section.toJson(),
      'tier': tier,
      'status': status.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      if (fetchedAt != null) 'fetchedAt': fetchedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartFilingSection',
      if (id != null) 'id': id,
      'filingId': filingId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'section': section.toJson(),
      'tier': tier,
      'status': status.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      if (fetchedAt != null) 'fetchedAt': fetchedAt?.toJson(),
    };
  }

  static DartFilingSectionInclude include() {
    return DartFilingSectionInclude._();
  }

  static DartFilingSectionIncludeList includeList({
    _is.WhereExpressionBuilder<DartFilingSectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingSectionTable>? orderBy,
    _is.OrderByListBuilder<DartFilingSectionTable>? orderByList,
    DartFilingSectionInclude? include,
  }) {
    return DartFilingSectionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartFilingSection.t),
      orderByList: orderByList?.call(DartFilingSection.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartFilingSectionImpl extends DartFilingSection {
  _DartFilingSectionImpl({
    int? id,
    required int filingId,
    required int companyId,
    required int bsnsYear,
    required _iy0bhrwp.DartSection section,
    required int tier,
    required _iy9345ub.FilingFetchStatus status,
    int? attempts,
    String? lastError,
    DateTime? fetchedAt,
  }) : super._(
         id: id,
         filingId: filingId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         section: section,
         tier: tier,
         status: status,
         attempts: attempts,
         lastError: lastError,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [DartFilingSection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DartFilingSection copyWith({
    Object? id = _Undefined,
    int? filingId,
    int? companyId,
    int? bsnsYear,
    _iy0bhrwp.DartSection? section,
    int? tier,
    _iy9345ub.FilingFetchStatus? status,
    int? attempts,
    Object? lastError = _Undefined,
    Object? fetchedAt = _Undefined,
  }) {
    return DartFilingSection(
      id: id is int? ? id : this.id,
      filingId: filingId ?? this.filingId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      section: section ?? this.section,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError is String? ? lastError : this.lastError,
      fetchedAt: fetchedAt is DateTime? ? fetchedAt : this.fetchedAt,
    );
  }
}

class DartFilingSectionUpdateTable
    extends _is.UpdateTable<DartFilingSectionTable> {
  DartFilingSectionUpdateTable(super.table);

  _is.ColumnValue<int, int> filingId(int value) => _is.ColumnValue(
    table.filingId,
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

  _is.ColumnValue<_iy0bhrwp.DartSection, _iy0bhrwp.DartSection> section(
    _iy0bhrwp.DartSection value,
  ) => _is.ColumnValue(
    table.section,
    value,
  );

  _is.ColumnValue<int, int> tier(int value) => _is.ColumnValue(
    table.tier,
    value,
  );

  _is.ColumnValue<_iy9345ub.FilingFetchStatus, _iy9345ub.FilingFetchStatus>
  status(_iy9345ub.FilingFetchStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<int, int> attempts(int value) => _is.ColumnValue(
    table.attempts,
    value,
  );

  _is.ColumnValue<String, String> lastError(String? value) => _is.ColumnValue(
    table.lastError,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> fetchedAt(DateTime? value) =>
      _is.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class DartFilingSectionTable extends _is.Table<int?> {
  DartFilingSectionTable({super.tableRelation})
    : super(tableName: 'dart_filing_section') {
    updateTable = DartFilingSectionUpdateTable(this);
    filingId = _is.ColumnInt(
      'filingId',
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
    section = _is.ColumnEnum(
      'section',
      this,
      _is.EnumSerialization.byName,
    );
    tier = _is.ColumnInt(
      'tier',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    attempts = _is.ColumnInt(
      'attempts',
      this,
      hasDefault: true,
    );
    lastError = _is.ColumnString(
      'lastError',
      this,
    );
    fetchedAt = _is.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final DartFilingSectionUpdateTable updateTable;

  late final _is.ColumnInt filingId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnEnum<_iy0bhrwp.DartSection> section;

  /// 받는 순서. 0 = 핵심 (지배구조·주주환원), 1 = 나머지
  late final _is.ColumnInt tier;

  late final _is.ColumnEnum<_iy9345ub.FilingFetchStatus> status;

  /// 실패한 실행 수
  late final _is.ColumnInt attempts;

  late final _is.ColumnString lastError;

  late final _is.ColumnDateTime fetchedAt;

  @override
  List<_is.Column> get columns => [
    id,
    filingId,
    companyId,
    bsnsYear,
    section,
    tier,
    status,
    attempts,
    lastError,
    fetchedAt,
  ];
}

class DartFilingSectionInclude extends _is.IncludeObject {
  DartFilingSectionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DartFilingSection.t;
}

class DartFilingSectionIncludeList extends _is.IncludeList {
  DartFilingSectionIncludeList._({
    _is.WhereExpressionBuilder<DartFilingSectionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DartFilingSection.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DartFilingSection.t;
}

class DartFilingSectionRepository {
  const DartFilingSectionRepository._();

  /// Returns a list of [DartFilingSection]s matching the given query parameters.
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
  Future<List<DartFilingSection>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingSectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingSectionTable>? orderBy,
    _is.OrderByListBuilder<DartFilingSectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DartFilingSection>(
      where: where?.call(DartFilingSection.t),
      orderBy: orderBy?.call(DartFilingSection.t),
      orderByList: orderByList?.call(DartFilingSection.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DartFilingSection] matching the given query parameters.
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
  Future<DartFilingSection?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingSectionTable>? where,
    int? offset,
    _is.OrderByBuilder<DartFilingSectionTable>? orderBy,
    _is.OrderByListBuilder<DartFilingSectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DartFilingSection>(
      where: where?.call(DartFilingSection.t),
      orderBy: orderBy?.call(DartFilingSection.t),
      orderByList: orderByList?.call(DartFilingSection.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DartFilingSection] by its [id] or null if no such row exists.
  Future<DartFilingSection?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DartFilingSection>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DartFilingSection]s in the list and returns the inserted rows.
  ///
  /// The returned [DartFilingSection]s will have their `id` fields set.
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
  Future<List<DartFilingSection>> insert(
    _is.DatabaseSession session,
    List<DartFilingSection> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DartFilingSection>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DartFilingSection] and returns the inserted row.
  ///
  /// The returned [DartFilingSection] will have its `id` field set.
  Future<DartFilingSection> insertRow(
    _is.DatabaseSession session,
    DartFilingSection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DartFilingSection>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DartFilingSection]s in the list and returns the resulting rows.
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
  /// The returned [DartFilingSection]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFilingSection>> upsert(
    _is.DatabaseSession session,
    List<DartFilingSection> rows, {
    required _is.ColumnSelections<DartFilingSectionTable> conflictColumns,
    _is.ColumnSelections<DartFilingSectionTable>? updateColumns,
    _is.WhereExpressionBuilder<DartFilingSectionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DartFilingSection>(
      rows,
      conflictColumns: conflictColumns(DartFilingSection.t),
      updateColumns: updateColumns?.call(DartFilingSection.t),
      updateWhere: updateWhere?.call(DartFilingSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DartFilingSection] and returns the resulting row.
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
  /// The returned [DartFilingSection] will have its `id` field set.
  Future<DartFilingSection?> upsertRow(
    _is.DatabaseSession session,
    DartFilingSection row, {
    required _is.ColumnSelections<DartFilingSectionTable> conflictColumns,
    _is.ColumnSelections<DartFilingSectionTable>? updateColumns,
    _is.WhereExpressionBuilder<DartFilingSectionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DartFilingSection>(
      row,
      conflictColumns: conflictColumns(DartFilingSection.t),
      updateColumns: updateColumns?.call(DartFilingSection.t),
      updateWhere: updateWhere?.call(DartFilingSection.t),
      transaction: transaction,
    );
  }

  /// Updates all [DartFilingSection]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFilingSection>> update(
    _is.DatabaseSession session,
    List<DartFilingSection> rows, {
    _is.ColumnSelections<DartFilingSectionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DartFilingSection>(
      rows,
      columns: columns?.call(DartFilingSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DartFilingSection]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DartFilingSection> updateRow(
    _is.DatabaseSession session,
    DartFilingSection row, {
    _is.ColumnSelections<DartFilingSectionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DartFilingSection>(
      row,
      columns: columns?.call(DartFilingSection.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DartFilingSection] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DartFilingSection?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DartFilingSectionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DartFilingSection>(
      id,
      columnValues: columnValues(DartFilingSection.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DartFilingSection]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DartFilingSection>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DartFilingSectionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<DartFilingSectionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DartFilingSectionTable>? orderBy,
    _is.OrderByListBuilder<DartFilingSectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DartFilingSection>(
      columnValues: columnValues(DartFilingSection.t.updateTable),
      where: where(DartFilingSection.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DartFilingSection.t),
      orderByList: orderByList?.call(DartFilingSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DartFilingSection]s in the list and returns the deleted rows.
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
  Future<List<DartFilingSection>> delete(
    _is.DatabaseSession session,
    List<DartFilingSection> rows, {
    _is.OrderByBuilder<DartFilingSectionTable>? orderBy,
    _is.OrderByListBuilder<DartFilingSectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DartFilingSection>(
      rows,
      orderBy: orderBy?.call(DartFilingSection.t),
      orderByList: orderByList?.call(DartFilingSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DartFilingSection].
  Future<DartFilingSection> deleteRow(
    _is.DatabaseSession session,
    DartFilingSection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DartFilingSection>(
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
  Future<List<DartFilingSection>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartFilingSectionTable> where,
    _is.OrderByBuilder<DartFilingSectionTable>? orderBy,
    _is.OrderByListBuilder<DartFilingSectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DartFilingSection>(
      where: where(DartFilingSection.t),
      orderBy: orderBy?.call(DartFilingSection.t),
      orderByList: orderByList?.call(DartFilingSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DartFilingSectionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DartFilingSection>(
      where: where?.call(DartFilingSection.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DartFilingSection] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DartFilingSectionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DartFilingSection>(
      where: where(DartFilingSection.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
