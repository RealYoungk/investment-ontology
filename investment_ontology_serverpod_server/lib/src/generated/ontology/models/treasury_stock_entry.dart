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

/// 자기주식 취득 및 처분 한 행 (tesstkAcqsDspsSttus). 수량은 주.
abstract class TreasuryStockEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TreasuryStockEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    this.method1,
    this.method2,
    this.method3,
    this.stockKind,
    this.sharesBegin,
    this.acquired,
    this.disposed,
    this.retired,
    this.sharesEnd,
    this.remark,
    required this.isTotal,
  });

  factory TreasuryStockEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    String? method1,
    String? method2,
    String? method3,
    String? stockKind,
    BigInt? sharesBegin,
    BigInt? acquired,
    BigInt? disposed,
    BigInt? retired,
    BigInt? sharesEnd,
    String? remark,
    required bool isTotal,
  }) = _TreasuryStockEntryImpl;

  factory TreasuryStockEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return TreasuryStockEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      method1: jsonSerialization['method1'] as String?,
      method2: jsonSerialization['method2'] as String?,
      method3: jsonSerialization['method3'] as String?,
      stockKind: jsonSerialization['stockKind'] as String?,
      sharesBegin: jsonSerialization['sharesBegin'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['sharesBegin']),
      acquired: jsonSerialization['acquired'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['acquired']),
      disposed: jsonSerialization['disposed'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['disposed']),
      retired: jsonSerialization['retired'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['retired']),
      sharesEnd: jsonSerialization['sharesEnd'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['sharesEnd']),
      remark: jsonSerialization['remark'] as String?,
      isTotal: _is.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
    );
  }

  static final t = TreasuryStockEntryTable();

  static const db = TreasuryStockEntryRepository._();

  @override
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 취득 방법 원문 (대·중·소분류)
  String? method1;

  String? method2;

  String? method3;

  String? stockKind;

  BigInt? sharesBegin;

  BigInt? acquired;

  BigInt? disposed;

  BigInt? retired;

  BigInt? sharesEnd;

  String? remark;

  /// 총계·소계 행
  bool isTotal;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TreasuryStockEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TreasuryStockEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? method1,
    String? method2,
    String? method3,
    String? stockKind,
    BigInt? sharesBegin,
    BigInt? acquired,
    BigInt? disposed,
    BigInt? retired,
    BigInt? sharesEnd,
    String? remark,
    bool? isTotal,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TreasuryStockEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      if (method1 != null) 'method1': method1,
      if (method2 != null) 'method2': method2,
      if (method3 != null) 'method3': method3,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (acquired != null) 'acquired': acquired?.toJson(),
      if (disposed != null) 'disposed': disposed?.toJson(),
      if (retired != null) 'retired': retired?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TreasuryStockEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      if (method1 != null) 'method1': method1,
      if (method2 != null) 'method2': method2,
      if (method3 != null) 'method3': method3,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (acquired != null) 'acquired': acquired?.toJson(),
      if (disposed != null) 'disposed': disposed?.toJson(),
      if (retired != null) 'retired': retired?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
    };
  }

  static TreasuryStockEntryInclude include() {
    return TreasuryStockEntryInclude._();
  }

  static TreasuryStockEntryIncludeList includeList({
    _is.WhereExpressionBuilder<TreasuryStockEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TreasuryStockEntryTable>? orderBy,
    _is.OrderByListBuilder<TreasuryStockEntryTable>? orderByList,
    TreasuryStockEntryInclude? include,
  }) {
    return TreasuryStockEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TreasuryStockEntry.t),
      orderByList: orderByList?.call(TreasuryStockEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TreasuryStockEntryImpl extends TreasuryStockEntry {
  _TreasuryStockEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    String? method1,
    String? method2,
    String? method3,
    String? stockKind,
    BigInt? sharesBegin,
    BigInt? acquired,
    BigInt? disposed,
    BigInt? retired,
    BigInt? sharesEnd,
    String? remark,
    required bool isTotal,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         method1: method1,
         method2: method2,
         method3: method3,
         stockKind: stockKind,
         sharesBegin: sharesBegin,
         acquired: acquired,
         disposed: disposed,
         retired: retired,
         sharesEnd: sharesEnd,
         remark: remark,
         isTotal: isTotal,
       );

  /// Returns a shallow copy of this [TreasuryStockEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TreasuryStockEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    Object? method1 = _Undefined,
    Object? method2 = _Undefined,
    Object? method3 = _Undefined,
    Object? stockKind = _Undefined,
    Object? sharesBegin = _Undefined,
    Object? acquired = _Undefined,
    Object? disposed = _Undefined,
    Object? retired = _Undefined,
    Object? sharesEnd = _Undefined,
    Object? remark = _Undefined,
    bool? isTotal,
  }) {
    return TreasuryStockEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      method1: method1 is String? ? method1 : this.method1,
      method2: method2 is String? ? method2 : this.method2,
      method3: method3 is String? ? method3 : this.method3,
      stockKind: stockKind is String? ? stockKind : this.stockKind,
      sharesBegin: sharesBegin is BigInt? ? sharesBegin : this.sharesBegin,
      acquired: acquired is BigInt? ? acquired : this.acquired,
      disposed: disposed is BigInt? ? disposed : this.disposed,
      retired: retired is BigInt? ? retired : this.retired,
      sharesEnd: sharesEnd is BigInt? ? sharesEnd : this.sharesEnd,
      remark: remark is String? ? remark : this.remark,
      isTotal: isTotal ?? this.isTotal,
    );
  }
}

class TreasuryStockEntryUpdateTable
    extends _is.UpdateTable<TreasuryStockEntryTable> {
  TreasuryStockEntryUpdateTable(super.table);

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

  _is.ColumnValue<String, String> method1(String? value) => _is.ColumnValue(
    table.method1,
    value,
  );

  _is.ColumnValue<String, String> method2(String? value) => _is.ColumnValue(
    table.method2,
    value,
  );

  _is.ColumnValue<String, String> method3(String? value) => _is.ColumnValue(
    table.method3,
    value,
  );

  _is.ColumnValue<String, String> stockKind(String? value) => _is.ColumnValue(
    table.stockKind,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> sharesBegin(BigInt? value) => _is.ColumnValue(
    table.sharesBegin,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> acquired(BigInt? value) => _is.ColumnValue(
    table.acquired,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> disposed(BigInt? value) => _is.ColumnValue(
    table.disposed,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> retired(BigInt? value) => _is.ColumnValue(
    table.retired,
    value,
  );

  _is.ColumnValue<BigInt, BigInt> sharesEnd(BigInt? value) => _is.ColumnValue(
    table.sharesEnd,
    value,
  );

  _is.ColumnValue<String, String> remark(String? value) => _is.ColumnValue(
    table.remark,
    value,
  );

  _is.ColumnValue<bool, bool> isTotal(bool value) => _is.ColumnValue(
    table.isTotal,
    value,
  );
}

class TreasuryStockEntryTable extends _is.Table<int?> {
  TreasuryStockEntryTable({super.tableRelation})
    : super(tableName: 'treasury_stock_entry') {
    updateTable = TreasuryStockEntryUpdateTable(this);
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
    method1 = _is.ColumnString(
      'method1',
      this,
    );
    method2 = _is.ColumnString(
      'method2',
      this,
    );
    method3 = _is.ColumnString(
      'method3',
      this,
    );
    stockKind = _is.ColumnString(
      'stockKind',
      this,
    );
    sharesBegin = _is.ColumnBigInt(
      'sharesBegin',
      this,
    );
    acquired = _is.ColumnBigInt(
      'acquired',
      this,
    );
    disposed = _is.ColumnBigInt(
      'disposed',
      this,
    );
    retired = _is.ColumnBigInt(
      'retired',
      this,
    );
    sharesEnd = _is.ColumnBigInt(
      'sharesEnd',
      this,
    );
    remark = _is.ColumnString(
      'remark',
      this,
    );
    isTotal = _is.ColumnBool(
      'isTotal',
      this,
    );
  }

  late final TreasuryStockEntryUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnInt ord;

  /// 취득 방법 원문 (대·중·소분류)
  late final _is.ColumnString method1;

  late final _is.ColumnString method2;

  late final _is.ColumnString method3;

  late final _is.ColumnString stockKind;

  late final _is.ColumnBigInt sharesBegin;

  late final _is.ColumnBigInt acquired;

  late final _is.ColumnBigInt disposed;

  late final _is.ColumnBigInt retired;

  late final _is.ColumnBigInt sharesEnd;

  late final _is.ColumnString remark;

  /// 총계·소계 행
  late final _is.ColumnBool isTotal;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    companyId,
    bsnsYear,
    ord,
    method1,
    method2,
    method3,
    stockKind,
    sharesBegin,
    acquired,
    disposed,
    retired,
    sharesEnd,
    remark,
    isTotal,
  ];
}

class TreasuryStockEntryInclude extends _is.IncludeObject {
  TreasuryStockEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TreasuryStockEntry.t;
}

class TreasuryStockEntryIncludeList extends _is.IncludeList {
  TreasuryStockEntryIncludeList._({
    _is.WhereExpressionBuilder<TreasuryStockEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TreasuryStockEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TreasuryStockEntry.t;
}

class TreasuryStockEntryRepository {
  const TreasuryStockEntryRepository._();

  /// Returns a list of [TreasuryStockEntry]s matching the given query parameters.
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
  Future<List<TreasuryStockEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TreasuryStockEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TreasuryStockEntryTable>? orderBy,
    _is.OrderByListBuilder<TreasuryStockEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TreasuryStockEntry>(
      where: where?.call(TreasuryStockEntry.t),
      orderBy: orderBy?.call(TreasuryStockEntry.t),
      orderByList: orderByList?.call(TreasuryStockEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TreasuryStockEntry] matching the given query parameters.
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
  Future<TreasuryStockEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TreasuryStockEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<TreasuryStockEntryTable>? orderBy,
    _is.OrderByListBuilder<TreasuryStockEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TreasuryStockEntry>(
      where: where?.call(TreasuryStockEntry.t),
      orderBy: orderBy?.call(TreasuryStockEntry.t),
      orderByList: orderByList?.call(TreasuryStockEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TreasuryStockEntry] by its [id] or null if no such row exists.
  Future<TreasuryStockEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TreasuryStockEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TreasuryStockEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [TreasuryStockEntry]s will have their `id` fields set.
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
  Future<List<TreasuryStockEntry>> insert(
    _is.DatabaseSession session,
    List<TreasuryStockEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TreasuryStockEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TreasuryStockEntry] and returns the inserted row.
  ///
  /// The returned [TreasuryStockEntry] will have its `id` field set.
  Future<TreasuryStockEntry> insertRow(
    _is.DatabaseSession session,
    TreasuryStockEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TreasuryStockEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TreasuryStockEntry]s in the list and returns the resulting rows.
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
  /// The returned [TreasuryStockEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TreasuryStockEntry>> upsert(
    _is.DatabaseSession session,
    List<TreasuryStockEntry> rows, {
    required _is.ColumnSelections<TreasuryStockEntryTable> conflictColumns,
    _is.ColumnSelections<TreasuryStockEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<TreasuryStockEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TreasuryStockEntry>(
      rows,
      conflictColumns: conflictColumns(TreasuryStockEntry.t),
      updateColumns: updateColumns?.call(TreasuryStockEntry.t),
      updateWhere: updateWhere?.call(TreasuryStockEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TreasuryStockEntry] and returns the resulting row.
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
  /// The returned [TreasuryStockEntry] will have its `id` field set.
  Future<TreasuryStockEntry?> upsertRow(
    _is.DatabaseSession session,
    TreasuryStockEntry row, {
    required _is.ColumnSelections<TreasuryStockEntryTable> conflictColumns,
    _is.ColumnSelections<TreasuryStockEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<TreasuryStockEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TreasuryStockEntry>(
      row,
      conflictColumns: conflictColumns(TreasuryStockEntry.t),
      updateColumns: updateColumns?.call(TreasuryStockEntry.t),
      updateWhere: updateWhere?.call(TreasuryStockEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [TreasuryStockEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TreasuryStockEntry>> update(
    _is.DatabaseSession session,
    List<TreasuryStockEntry> rows, {
    _is.ColumnSelections<TreasuryStockEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TreasuryStockEntry>(
      rows,
      columns: columns?.call(TreasuryStockEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TreasuryStockEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TreasuryStockEntry> updateRow(
    _is.DatabaseSession session,
    TreasuryStockEntry row, {
    _is.ColumnSelections<TreasuryStockEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TreasuryStockEntry>(
      row,
      columns: columns?.call(TreasuryStockEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TreasuryStockEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TreasuryStockEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TreasuryStockEntryUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TreasuryStockEntry>(
      id,
      columnValues: columnValues(TreasuryStockEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TreasuryStockEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TreasuryStockEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TreasuryStockEntryUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<TreasuryStockEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TreasuryStockEntryTable>? orderBy,
    _is.OrderByListBuilder<TreasuryStockEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TreasuryStockEntry>(
      columnValues: columnValues(TreasuryStockEntry.t.updateTable),
      where: where(TreasuryStockEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TreasuryStockEntry.t),
      orderByList: orderByList?.call(TreasuryStockEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TreasuryStockEntry]s in the list and returns the deleted rows.
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
  Future<List<TreasuryStockEntry>> delete(
    _is.DatabaseSession session,
    List<TreasuryStockEntry> rows, {
    _is.OrderByBuilder<TreasuryStockEntryTable>? orderBy,
    _is.OrderByListBuilder<TreasuryStockEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TreasuryStockEntry>(
      rows,
      orderBy: orderBy?.call(TreasuryStockEntry.t),
      orderByList: orderByList?.call(TreasuryStockEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TreasuryStockEntry].
  Future<TreasuryStockEntry> deleteRow(
    _is.DatabaseSession session,
    TreasuryStockEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TreasuryStockEntry>(
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
  Future<List<TreasuryStockEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TreasuryStockEntryTable> where,
    _is.OrderByBuilder<TreasuryStockEntryTable>? orderBy,
    _is.OrderByListBuilder<TreasuryStockEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TreasuryStockEntry>(
      where: where(TreasuryStockEntry.t),
      orderBy: orderBy?.call(TreasuryStockEntry.t),
      orderByList: orderByList?.call(TreasuryStockEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TreasuryStockEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TreasuryStockEntry>(
      where: where?.call(TreasuryStockEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TreasuryStockEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TreasuryStockEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TreasuryStockEntry>(
      where: where(TreasuryStockEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
