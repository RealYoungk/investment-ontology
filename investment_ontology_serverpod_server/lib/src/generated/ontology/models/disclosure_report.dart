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
import '../../ontology/models/financial_report_code.dart' as _i6mbh8k5;

/// 정기보고서 한 건의 주요정보 항목 하나. 응답 행(DisclosureRow)을 묶는다.
/// 정정공시로 대체되면 지우지 않고 supersededBy로 새 보고서를 가리킨다.
abstract class DisclosureReport
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DisclosureReport._({
    this.id,
    required this.companyId,
    required this.section,
    required this.rceptNo,
    required this.bsnsYear,
    required this.reportCode,
    this.settlementDate,
    required this.rowCount,
    int? emptyRowCount,
    required this.sourceId,
    this.supersededById,
    required this.fetchedAt,
  }) : emptyRowCount = emptyRowCount ?? 0;

  factory DisclosureReport({
    int? id,
    required int companyId,
    required _iy0bhrwp.DartSection section,
    required String rceptNo,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    DateTime? settlementDate,
    required int rowCount,
    int? emptyRowCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) = _DisclosureReportImpl;

  factory DisclosureReport.fromJson(Map<String, dynamic> jsonSerialization) {
    return DisclosureReport(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      section: _iy0bhrwp.DartSection.fromJson(
        (jsonSerialization['section'] as String),
      ),
      rceptNo: jsonSerialization['rceptNo'] as String,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      reportCode: _i6mbh8k5.FinancialReportCode.fromJson(
        (jsonSerialization['reportCode'] as String),
      ),
      settlementDate: jsonSerialization['settlementDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['settlementDate'],
            ),
      rowCount: jsonSerialization['rowCount'] as int,
      emptyRowCount: jsonSerialization['emptyRowCount'] as int?,
      sourceId: jsonSerialization['sourceId'] as int,
      supersededById: jsonSerialization['supersededById'] as int?,
      fetchedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  static final t = DisclosureReportTable();

  static const db = DisclosureReportRepository._();

  @override
  int? id;

  int companyId;

  _iy0bhrwp.DartSection section;

  /// 응답의 접수번호. 이 값들이 실린 공시
  String rceptNo;

  int bsnsYear;

  _i6mbh8k5.FinancialReportCode reportCode;

  /// 응답의 결산기준일 (stlm_dt, UTC 자정) — 관계의 기준일
  DateTime? settlementDate;

  /// 저장한 행 수 (값이 모두 '-'인 빈 줄 제외)
  int rowCount;

  /// 값이 모두 '-'여서 저장하지 않은 빈 줄 수
  int emptyRowCount;

  int sourceId;

  int? supersededById;

  DateTime fetchedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DisclosureReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DisclosureReport copyWith({
    int? id,
    int? companyId,
    _iy0bhrwp.DartSection? section,
    String? rceptNo,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    DateTime? settlementDate,
    int? rowCount,
    int? emptyRowCount,
    int? sourceId,
    int? supersededById,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'section': section.toJson(),
      'rceptNo': rceptNo,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'rowCount': rowCount,
      'emptyRowCount': emptyRowCount,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DisclosureReport',
      if (id != null) 'id': id,
      'companyId': companyId,
      'section': section.toJson(),
      'rceptNo': rceptNo,
      'bsnsYear': bsnsYear,
      'reportCode': reportCode.toJson(),
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'rowCount': rowCount,
      'emptyRowCount': emptyRowCount,
      'sourceId': sourceId,
      if (supersededById != null) 'supersededById': supersededById,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  static DisclosureReportInclude include() {
    return DisclosureReportInclude._();
  }

  static DisclosureReportIncludeList includeList({
    _is.WhereExpressionBuilder<DisclosureReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DisclosureReportTable>? orderBy,
    _is.OrderByListBuilder<DisclosureReportTable>? orderByList,
    DisclosureReportInclude? include,
  }) {
    return DisclosureReportIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DisclosureReport.t),
      orderByList: orderByList?.call(DisclosureReport.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DisclosureReportImpl extends DisclosureReport {
  _DisclosureReportImpl({
    int? id,
    required int companyId,
    required _iy0bhrwp.DartSection section,
    required String rceptNo,
    required int bsnsYear,
    required _i6mbh8k5.FinancialReportCode reportCode,
    DateTime? settlementDate,
    required int rowCount,
    int? emptyRowCount,
    required int sourceId,
    int? supersededById,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         companyId: companyId,
         section: section,
         rceptNo: rceptNo,
         bsnsYear: bsnsYear,
         reportCode: reportCode,
         settlementDate: settlementDate,
         rowCount: rowCount,
         emptyRowCount: emptyRowCount,
         sourceId: sourceId,
         supersededById: supersededById,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [DisclosureReport]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DisclosureReport copyWith({
    Object? id = _Undefined,
    int? companyId,
    _iy0bhrwp.DartSection? section,
    String? rceptNo,
    int? bsnsYear,
    _i6mbh8k5.FinancialReportCode? reportCode,
    Object? settlementDate = _Undefined,
    int? rowCount,
    int? emptyRowCount,
    int? sourceId,
    Object? supersededById = _Undefined,
    DateTime? fetchedAt,
  }) {
    return DisclosureReport(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      section: section ?? this.section,
      rceptNo: rceptNo ?? this.rceptNo,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      reportCode: reportCode ?? this.reportCode,
      settlementDate: settlementDate is DateTime?
          ? settlementDate
          : this.settlementDate,
      rowCount: rowCount ?? this.rowCount,
      emptyRowCount: emptyRowCount ?? this.emptyRowCount,
      sourceId: sourceId ?? this.sourceId,
      supersededById: supersededById is int?
          ? supersededById
          : this.supersededById,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class DisclosureReportUpdateTable
    extends _is.UpdateTable<DisclosureReportTable> {
  DisclosureReportUpdateTable(super.table);

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<_iy0bhrwp.DartSection, _iy0bhrwp.DartSection> section(
    _iy0bhrwp.DartSection value,
  ) => _is.ColumnValue(
    table.section,
    value,
  );

  _is.ColumnValue<String, String> rceptNo(String value) => _is.ColumnValue(
    table.rceptNo,
    value,
  );

  _is.ColumnValue<int, int> bsnsYear(int value) => _is.ColumnValue(
    table.bsnsYear,
    value,
  );

  _is.ColumnValue<_i6mbh8k5.FinancialReportCode, _i6mbh8k5.FinancialReportCode>
  reportCode(_i6mbh8k5.FinancialReportCode value) => _is.ColumnValue(
    table.reportCode,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> settlementDate(DateTime? value) =>
      _is.ColumnValue(
        table.settlementDate,
        value,
      );

  _is.ColumnValue<int, int> rowCount(int value) => _is.ColumnValue(
    table.rowCount,
    value,
  );

  _is.ColumnValue<int, int> emptyRowCount(int value) => _is.ColumnValue(
    table.emptyRowCount,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<int, int> supersededById(int? value) => _is.ColumnValue(
    table.supersededById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> fetchedAt(DateTime value) =>
      _is.ColumnValue(
        table.fetchedAt,
        value,
      );
}

class DisclosureReportTable extends _is.Table<int?> {
  DisclosureReportTable({super.tableRelation})
    : super(tableName: 'disclosure_report') {
    updateTable = DisclosureReportUpdateTable(this);
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    section = _is.ColumnEnum(
      'section',
      this,
      _is.EnumSerialization.byName,
    );
    rceptNo = _is.ColumnString(
      'rceptNo',
      this,
    );
    bsnsYear = _is.ColumnInt(
      'bsnsYear',
      this,
    );
    reportCode = _is.ColumnEnum(
      'reportCode',
      this,
      _is.EnumSerialization.byName,
    );
    settlementDate = _is.ColumnDateTime(
      'settlementDate',
      this,
    );
    rowCount = _is.ColumnInt(
      'rowCount',
      this,
    );
    emptyRowCount = _is.ColumnInt(
      'emptyRowCount',
      this,
      hasDefault: true,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    supersededById = _is.ColumnInt(
      'supersededById',
      this,
    );
    fetchedAt = _is.ColumnDateTime(
      'fetchedAt',
      this,
    );
  }

  late final DisclosureReportUpdateTable updateTable;

  late final _is.ColumnInt companyId;

  late final _is.ColumnEnum<_iy0bhrwp.DartSection> section;

  /// 응답의 접수번호. 이 값들이 실린 공시
  late final _is.ColumnString rceptNo;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnEnum<_i6mbh8k5.FinancialReportCode> reportCode;

  /// 응답의 결산기준일 (stlm_dt, UTC 자정) — 관계의 기준일
  late final _is.ColumnDateTime settlementDate;

  /// 저장한 행 수 (값이 모두 '-'인 빈 줄 제외)
  late final _is.ColumnInt rowCount;

  /// 값이 모두 '-'여서 저장하지 않은 빈 줄 수
  late final _is.ColumnInt emptyRowCount;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnInt supersededById;

  late final _is.ColumnDateTime fetchedAt;

  @override
  List<_is.Column> get columns => [
    id,
    companyId,
    section,
    rceptNo,
    bsnsYear,
    reportCode,
    settlementDate,
    rowCount,
    emptyRowCount,
    sourceId,
    supersededById,
    fetchedAt,
  ];
}

class DisclosureReportInclude extends _is.IncludeObject {
  DisclosureReportInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DisclosureReport.t;
}

class DisclosureReportIncludeList extends _is.IncludeList {
  DisclosureReportIncludeList._({
    _is.WhereExpressionBuilder<DisclosureReportTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DisclosureReport.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DisclosureReport.t;
}

class DisclosureReportRepository {
  const DisclosureReportRepository._();

  /// Returns a list of [DisclosureReport]s matching the given query parameters.
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
  Future<List<DisclosureReport>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DisclosureReportTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DisclosureReportTable>? orderBy,
    _is.OrderByListBuilder<DisclosureReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DisclosureReport>(
      where: where?.call(DisclosureReport.t),
      orderBy: orderBy?.call(DisclosureReport.t),
      orderByList: orderByList?.call(DisclosureReport.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DisclosureReport] matching the given query parameters.
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
  Future<DisclosureReport?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DisclosureReportTable>? where,
    int? offset,
    _is.OrderByBuilder<DisclosureReportTable>? orderBy,
    _is.OrderByListBuilder<DisclosureReportTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DisclosureReport>(
      where: where?.call(DisclosureReport.t),
      orderBy: orderBy?.call(DisclosureReport.t),
      orderByList: orderByList?.call(DisclosureReport.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DisclosureReport] by its [id] or null if no such row exists.
  Future<DisclosureReport?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DisclosureReport>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DisclosureReport]s in the list and returns the inserted rows.
  ///
  /// The returned [DisclosureReport]s will have their `id` fields set.
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
  Future<List<DisclosureReport>> insert(
    _is.DatabaseSession session,
    List<DisclosureReport> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DisclosureReport>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DisclosureReport] and returns the inserted row.
  ///
  /// The returned [DisclosureReport] will have its `id` field set.
  Future<DisclosureReport> insertRow(
    _is.DatabaseSession session,
    DisclosureReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DisclosureReport>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DisclosureReport]s in the list and returns the resulting rows.
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
  /// The returned [DisclosureReport]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DisclosureReport>> upsert(
    _is.DatabaseSession session,
    List<DisclosureReport> rows, {
    required _is.ColumnSelections<DisclosureReportTable> conflictColumns,
    _is.ColumnSelections<DisclosureReportTable>? updateColumns,
    _is.WhereExpressionBuilder<DisclosureReportTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DisclosureReport>(
      rows,
      conflictColumns: conflictColumns(DisclosureReport.t),
      updateColumns: updateColumns?.call(DisclosureReport.t),
      updateWhere: updateWhere?.call(DisclosureReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DisclosureReport] and returns the resulting row.
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
  /// The returned [DisclosureReport] will have its `id` field set.
  Future<DisclosureReport?> upsertRow(
    _is.DatabaseSession session,
    DisclosureReport row, {
    required _is.ColumnSelections<DisclosureReportTable> conflictColumns,
    _is.ColumnSelections<DisclosureReportTable>? updateColumns,
    _is.WhereExpressionBuilder<DisclosureReportTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DisclosureReport>(
      row,
      conflictColumns: conflictColumns(DisclosureReport.t),
      updateColumns: updateColumns?.call(DisclosureReport.t),
      updateWhere: updateWhere?.call(DisclosureReport.t),
      transaction: transaction,
    );
  }

  /// Updates all [DisclosureReport]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DisclosureReport>> update(
    _is.DatabaseSession session,
    List<DisclosureReport> rows, {
    _is.ColumnSelections<DisclosureReportTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DisclosureReport>(
      rows,
      columns: columns?.call(DisclosureReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DisclosureReport]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DisclosureReport> updateRow(
    _is.DatabaseSession session,
    DisclosureReport row, {
    _is.ColumnSelections<DisclosureReportTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DisclosureReport>(
      row,
      columns: columns?.call(DisclosureReport.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DisclosureReport] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DisclosureReport?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DisclosureReportUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DisclosureReport>(
      id,
      columnValues: columnValues(DisclosureReport.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DisclosureReport]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DisclosureReport>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DisclosureReportUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<DisclosureReportTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DisclosureReportTable>? orderBy,
    _is.OrderByListBuilder<DisclosureReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DisclosureReport>(
      columnValues: columnValues(DisclosureReport.t.updateTable),
      where: where(DisclosureReport.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DisclosureReport.t),
      orderByList: orderByList?.call(DisclosureReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DisclosureReport]s in the list and returns the deleted rows.
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
  Future<List<DisclosureReport>> delete(
    _is.DatabaseSession session,
    List<DisclosureReport> rows, {
    _is.OrderByBuilder<DisclosureReportTable>? orderBy,
    _is.OrderByListBuilder<DisclosureReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DisclosureReport>(
      rows,
      orderBy: orderBy?.call(DisclosureReport.t),
      orderByList: orderByList?.call(DisclosureReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DisclosureReport].
  Future<DisclosureReport> deleteRow(
    _is.DatabaseSession session,
    DisclosureReport row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DisclosureReport>(
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
  Future<List<DisclosureReport>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DisclosureReportTable> where,
    _is.OrderByBuilder<DisclosureReportTable>? orderBy,
    _is.OrderByListBuilder<DisclosureReportTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DisclosureReport>(
      where: where(DisclosureReport.t),
      orderBy: orderBy?.call(DisclosureReport.t),
      orderByList: orderByList?.call(DisclosureReport.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DisclosureReportTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DisclosureReport>(
      where: where?.call(DisclosureReport.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DisclosureReport] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DisclosureReportTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DisclosureReport>(
      where: where(DisclosureReport.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
