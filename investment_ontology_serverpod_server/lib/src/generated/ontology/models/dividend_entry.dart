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

/// 배당에 관한 사항 한 행 (alotMatter). 값의 단위는 행 이름에 있어(unit) 원으로 바꾸지 않는다.
abstract class DividendEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DividendEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.item,
    this.unit,
    this.stockKind,
    this.current,
    this.prior,
    this.beforePrior,
  });

  factory DividendEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String item,
    String? unit,
    String? stockKind,
    double? current,
    double? prior,
    double? beforePrior,
  }) = _DividendEntryImpl;

  factory DividendEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return DividendEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      item: jsonSerialization['item'] as String,
      unit: jsonSerialization['unit'] as String?,
      stockKind: jsonSerialization['stockKind'] as String?,
      current: (jsonSerialization['current'] as num?)?.toDouble(),
      prior: (jsonSerialization['prior'] as num?)?.toDouble(),
      beforePrior: (jsonSerialization['beforePrior'] as num?)?.toDouble(),
    );
  }

  static final t = DividendEntryTable();

  static const db = DividendEntryRepository._();

  @override
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 항목 원문 (주당액면가액(원), (연결)당기순이익(백만원), 현금배당성향(%) …)
  String item;

  /// 항목 이름 끝의 단위 (원, 백만원, %, 주 …). 없으면 null
  String? unit;

  String? stockKind;

  /// 당기·전기·전전기 값
  double? current;

  double? prior;

  double? beforePrior;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DividendEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DividendEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? item,
    String? unit,
    String? stockKind,
    double? current,
    double? prior,
    double? beforePrior,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DividendEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'item': item,
      if (unit != null) 'unit': unit,
      if (stockKind != null) 'stockKind': stockKind,
      if (current != null) 'current': current,
      if (prior != null) 'prior': prior,
      if (beforePrior != null) 'beforePrior': beforePrior,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DividendEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'item': item,
      if (unit != null) 'unit': unit,
      if (stockKind != null) 'stockKind': stockKind,
      if (current != null) 'current': current,
      if (prior != null) 'prior': prior,
      if (beforePrior != null) 'beforePrior': beforePrior,
    };
  }

  static DividendEntryInclude include() {
    return DividendEntryInclude._();
  }

  static DividendEntryIncludeList includeList({
    _is.WhereExpressionBuilder<DividendEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DividendEntryTable>? orderBy,
    _is.OrderByListBuilder<DividendEntryTable>? orderByList,
    DividendEntryInclude? include,
  }) {
    return DividendEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DividendEntry.t),
      orderByList: orderByList?.call(DividendEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DividendEntryImpl extends DividendEntry {
  _DividendEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String item,
    String? unit,
    String? stockKind,
    double? current,
    double? prior,
    double? beforePrior,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         item: item,
         unit: unit,
         stockKind: stockKind,
         current: current,
         prior: prior,
         beforePrior: beforePrior,
       );

  /// Returns a shallow copy of this [DividendEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DividendEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? item,
    Object? unit = _Undefined,
    Object? stockKind = _Undefined,
    Object? current = _Undefined,
    Object? prior = _Undefined,
    Object? beforePrior = _Undefined,
  }) {
    return DividendEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      item: item ?? this.item,
      unit: unit is String? ? unit : this.unit,
      stockKind: stockKind is String? ? stockKind : this.stockKind,
      current: current is double? ? current : this.current,
      prior: prior is double? ? prior : this.prior,
      beforePrior: beforePrior is double? ? beforePrior : this.beforePrior,
    );
  }
}

class DividendEntryUpdateTable extends _is.UpdateTable<DividendEntryTable> {
  DividendEntryUpdateTable(super.table);

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

  _is.ColumnValue<String, String> item(String value) => _is.ColumnValue(
    table.item,
    value,
  );

  _is.ColumnValue<String, String> unit(String? value) => _is.ColumnValue(
    table.unit,
    value,
  );

  _is.ColumnValue<String, String> stockKind(String? value) => _is.ColumnValue(
    table.stockKind,
    value,
  );

  _is.ColumnValue<double, double> current(double? value) => _is.ColumnValue(
    table.current,
    value,
  );

  _is.ColumnValue<double, double> prior(double? value) => _is.ColumnValue(
    table.prior,
    value,
  );

  _is.ColumnValue<double, double> beforePrior(double? value) => _is.ColumnValue(
    table.beforePrior,
    value,
  );
}

class DividendEntryTable extends _is.Table<int?> {
  DividendEntryTable({super.tableRelation})
    : super(tableName: 'dividend_entry') {
    updateTable = DividendEntryUpdateTable(this);
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
    item = _is.ColumnString(
      'item',
      this,
    );
    unit = _is.ColumnString(
      'unit',
      this,
    );
    stockKind = _is.ColumnString(
      'stockKind',
      this,
    );
    current = _is.ColumnDouble(
      'current',
      this,
    );
    prior = _is.ColumnDouble(
      'prior',
      this,
    );
    beforePrior = _is.ColumnDouble(
      'beforePrior',
      this,
    );
  }

  late final DividendEntryUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnInt ord;

  /// 항목 원문 (주당액면가액(원), (연결)당기순이익(백만원), 현금배당성향(%) …)
  late final _is.ColumnString item;

  /// 항목 이름 끝의 단위 (원, 백만원, %, 주 …). 없으면 null
  late final _is.ColumnString unit;

  late final _is.ColumnString stockKind;

  /// 당기·전기·전전기 값
  late final _is.ColumnDouble current;

  late final _is.ColumnDouble prior;

  late final _is.ColumnDouble beforePrior;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    companyId,
    bsnsYear,
    ord,
    item,
    unit,
    stockKind,
    current,
    prior,
    beforePrior,
  ];
}

class DividendEntryInclude extends _is.IncludeObject {
  DividendEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DividendEntry.t;
}

class DividendEntryIncludeList extends _is.IncludeList {
  DividendEntryIncludeList._({
    _is.WhereExpressionBuilder<DividendEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DividendEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DividendEntry.t;
}

class DividendEntryRepository {
  const DividendEntryRepository._();

  /// Returns a list of [DividendEntry]s matching the given query parameters.
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
  Future<List<DividendEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DividendEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DividendEntryTable>? orderBy,
    _is.OrderByListBuilder<DividendEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DividendEntry>(
      where: where?.call(DividendEntry.t),
      orderBy: orderBy?.call(DividendEntry.t),
      orderByList: orderByList?.call(DividendEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DividendEntry] matching the given query parameters.
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
  Future<DividendEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DividendEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<DividendEntryTable>? orderBy,
    _is.OrderByListBuilder<DividendEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DividendEntry>(
      where: where?.call(DividendEntry.t),
      orderBy: orderBy?.call(DividendEntry.t),
      orderByList: orderByList?.call(DividendEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DividendEntry] by its [id] or null if no such row exists.
  Future<DividendEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DividendEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DividendEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [DividendEntry]s will have their `id` fields set.
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
  Future<List<DividendEntry>> insert(
    _is.DatabaseSession session,
    List<DividendEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DividendEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DividendEntry] and returns the inserted row.
  ///
  /// The returned [DividendEntry] will have its `id` field set.
  Future<DividendEntry> insertRow(
    _is.DatabaseSession session,
    DividendEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DividendEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DividendEntry]s in the list and returns the resulting rows.
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
  /// The returned [DividendEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DividendEntry>> upsert(
    _is.DatabaseSession session,
    List<DividendEntry> rows, {
    required _is.ColumnSelections<DividendEntryTable> conflictColumns,
    _is.ColumnSelections<DividendEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<DividendEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DividendEntry>(
      rows,
      conflictColumns: conflictColumns(DividendEntry.t),
      updateColumns: updateColumns?.call(DividendEntry.t),
      updateWhere: updateWhere?.call(DividendEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DividendEntry] and returns the resulting row.
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
  /// The returned [DividendEntry] will have its `id` field set.
  Future<DividendEntry?> upsertRow(
    _is.DatabaseSession session,
    DividendEntry row, {
    required _is.ColumnSelections<DividendEntryTable> conflictColumns,
    _is.ColumnSelections<DividendEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<DividendEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DividendEntry>(
      row,
      conflictColumns: conflictColumns(DividendEntry.t),
      updateColumns: updateColumns?.call(DividendEntry.t),
      updateWhere: updateWhere?.call(DividendEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [DividendEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DividendEntry>> update(
    _is.DatabaseSession session,
    List<DividendEntry> rows, {
    _is.ColumnSelections<DividendEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DividendEntry>(
      rows,
      columns: columns?.call(DividendEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DividendEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DividendEntry> updateRow(
    _is.DatabaseSession session,
    DividendEntry row, {
    _is.ColumnSelections<DividendEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DividendEntry>(
      row,
      columns: columns?.call(DividendEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DividendEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DividendEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DividendEntryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DividendEntry>(
      id,
      columnValues: columnValues(DividendEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DividendEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DividendEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DividendEntryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DividendEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DividendEntryTable>? orderBy,
    _is.OrderByListBuilder<DividendEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DividendEntry>(
      columnValues: columnValues(DividendEntry.t.updateTable),
      where: where(DividendEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DividendEntry.t),
      orderByList: orderByList?.call(DividendEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DividendEntry]s in the list and returns the deleted rows.
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
  Future<List<DividendEntry>> delete(
    _is.DatabaseSession session,
    List<DividendEntry> rows, {
    _is.OrderByBuilder<DividendEntryTable>? orderBy,
    _is.OrderByListBuilder<DividendEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DividendEntry>(
      rows,
      orderBy: orderBy?.call(DividendEntry.t),
      orderByList: orderByList?.call(DividendEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DividendEntry].
  Future<DividendEntry> deleteRow(
    _is.DatabaseSession session,
    DividendEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DividendEntry>(
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
  Future<List<DividendEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DividendEntryTable> where,
    _is.OrderByBuilder<DividendEntryTable>? orderBy,
    _is.OrderByListBuilder<DividendEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DividendEntry>(
      where: where(DividendEntry.t),
      orderBy: orderBy?.call(DividendEntry.t),
      orderByList: orderByList?.call(DividendEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DividendEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DividendEntry>(
      where: where?.call(DividendEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DividendEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DividendEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DividendEntry>(
      where: where(DividendEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
