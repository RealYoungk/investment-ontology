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

/// 사업보고서 본문 "II. 사업의 내용" (공시 원본 파일 document.xml에서 뽑은 글). 4단계 AI 관계 추출의 원천.
abstract class BusinessDocument
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BusinessDocument._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.rceptNo,
    required this.title,
    required this.text,
    required this.charCount,
  });

  factory BusinessDocument({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required String rceptNo,
    required String title,
    required String text,
    required int charCount,
  }) = _BusinessDocumentImpl;

  factory BusinessDocument.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessDocument(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      title: jsonSerialization['title'] as String,
      text: jsonSerialization['text'] as String,
      charCount: jsonSerialization['charCount'] as int,
    );
  }

  static final t = BusinessDocumentTable();

  static const db = BusinessDocumentRepository._();

  @override
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  String rceptNo;

  /// 원문 제목 (예: II. 사업의 내용)
  String title;

  /// 표는 칸을 ' | '로 이은 줄로, 하위 절 제목은 '## '로 시작하는 줄로 바꾼 글
  String text;

  int charCount;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BusinessDocument]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessDocument copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    String? rceptNo,
    String? title,
    String? text,
    int? charCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessDocument',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      'title': title,
      'text': text,
      'charCount': charCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessDocument',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      'title': title,
      'text': text,
      'charCount': charCount,
    };
  }

  static BusinessDocumentInclude include() {
    return BusinessDocumentInclude._();
  }

  static BusinessDocumentIncludeList includeList({
    _is.WhereExpressionBuilder<BusinessDocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessDocumentTable>? orderBy,
    _is.OrderByListBuilder<BusinessDocumentTable>? orderByList,
    BusinessDocumentInclude? include,
  }) {
    return BusinessDocumentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BusinessDocument.t),
      orderByList: orderByList?.call(BusinessDocument.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessDocumentImpl extends BusinessDocument {
  _BusinessDocumentImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required String rceptNo,
    required String title,
    required String text,
    required int charCount,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         title: title,
         text: text,
         charCount: charCount,
       );

  /// Returns a shallow copy of this [BusinessDocument]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessDocument copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    String? rceptNo,
    String? title,
    String? text,
    int? charCount,
  }) {
    return BusinessDocument(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      rceptNo: rceptNo ?? this.rceptNo,
      title: title ?? this.title,
      text: text ?? this.text,
      charCount: charCount ?? this.charCount,
    );
  }
}

class BusinessDocumentUpdateTable
    extends _is.UpdateTable<BusinessDocumentTable> {
  BusinessDocumentUpdateTable(super.table);

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

  _is.ColumnValue<String, String> rceptNo(String value) => _is.ColumnValue(
    table.rceptNo,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> text(String value) => _is.ColumnValue(
    table.text,
    value,
  );

  _is.ColumnValue<int, int> charCount(int value) => _is.ColumnValue(
    table.charCount,
    value,
  );
}

class BusinessDocumentTable extends _is.Table<int?> {
  BusinessDocumentTable({super.tableRelation})
    : super(tableName: 'business_document') {
    updateTable = BusinessDocumentUpdateTable(this);
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
    rceptNo = _is.ColumnString(
      'rceptNo',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    text = _is.ColumnString(
      'text',
      this,
    );
    charCount = _is.ColumnInt(
      'charCount',
      this,
    );
  }

  late final BusinessDocumentUpdateTable updateTable;

  late final _is.ColumnInt reportId;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnString rceptNo;

  /// 원문 제목 (예: II. 사업의 내용)
  late final _is.ColumnString title;

  /// 표는 칸을 ' | '로 이은 줄로, 하위 절 제목은 '## '로 시작하는 줄로 바꾼 글
  late final _is.ColumnString text;

  late final _is.ColumnInt charCount;

  @override
  List<_is.Column> get columns => [
    id,
    reportId,
    companyId,
    bsnsYear,
    rceptNo,
    title,
    text,
    charCount,
  ];
}

class BusinessDocumentInclude extends _is.IncludeObject {
  BusinessDocumentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BusinessDocument.t;
}

class BusinessDocumentIncludeList extends _is.IncludeList {
  BusinessDocumentIncludeList._({
    _is.WhereExpressionBuilder<BusinessDocumentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BusinessDocument.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BusinessDocument.t;
}

class BusinessDocumentRepository {
  const BusinessDocumentRepository._();

  /// Returns a list of [BusinessDocument]s matching the given query parameters.
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
  Future<List<BusinessDocument>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessDocumentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessDocumentTable>? orderBy,
    _is.OrderByListBuilder<BusinessDocumentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BusinessDocument>(
      where: where?.call(BusinessDocument.t),
      orderBy: orderBy?.call(BusinessDocument.t),
      orderByList: orderByList?.call(BusinessDocument.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BusinessDocument] matching the given query parameters.
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
  Future<BusinessDocument?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessDocumentTable>? where,
    int? offset,
    _is.OrderByBuilder<BusinessDocumentTable>? orderBy,
    _is.OrderByListBuilder<BusinessDocumentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BusinessDocument>(
      where: where?.call(BusinessDocument.t),
      orderBy: orderBy?.call(BusinessDocument.t),
      orderByList: orderByList?.call(BusinessDocument.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BusinessDocument] by its [id] or null if no such row exists.
  Future<BusinessDocument?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BusinessDocument>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BusinessDocument]s in the list and returns the inserted rows.
  ///
  /// The returned [BusinessDocument]s will have their `id` fields set.
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
  Future<List<BusinessDocument>> insert(
    _is.DatabaseSession session,
    List<BusinessDocument> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BusinessDocument>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BusinessDocument] and returns the inserted row.
  ///
  /// The returned [BusinessDocument] will have its `id` field set.
  Future<BusinessDocument> insertRow(
    _is.DatabaseSession session,
    BusinessDocument row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BusinessDocument>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BusinessDocument]s in the list and returns the resulting rows.
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
  /// The returned [BusinessDocument]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessDocument>> upsert(
    _is.DatabaseSession session,
    List<BusinessDocument> rows, {
    required _is.ColumnSelections<BusinessDocumentTable> conflictColumns,
    _is.ColumnSelections<BusinessDocumentTable>? updateColumns,
    _is.WhereExpressionBuilder<BusinessDocumentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BusinessDocument>(
      rows,
      conflictColumns: conflictColumns(BusinessDocument.t),
      updateColumns: updateColumns?.call(BusinessDocument.t),
      updateWhere: updateWhere?.call(BusinessDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BusinessDocument] and returns the resulting row.
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
  /// The returned [BusinessDocument] will have its `id` field set.
  Future<BusinessDocument?> upsertRow(
    _is.DatabaseSession session,
    BusinessDocument row, {
    required _is.ColumnSelections<BusinessDocumentTable> conflictColumns,
    _is.ColumnSelections<BusinessDocumentTable>? updateColumns,
    _is.WhereExpressionBuilder<BusinessDocumentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BusinessDocument>(
      row,
      conflictColumns: conflictColumns(BusinessDocument.t),
      updateColumns: updateColumns?.call(BusinessDocument.t),
      updateWhere: updateWhere?.call(BusinessDocument.t),
      transaction: transaction,
    );
  }

  /// Updates all [BusinessDocument]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessDocument>> update(
    _is.DatabaseSession session,
    List<BusinessDocument> rows, {
    _is.ColumnSelections<BusinessDocumentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BusinessDocument>(
      rows,
      columns: columns?.call(BusinessDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BusinessDocument]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BusinessDocument> updateRow(
    _is.DatabaseSession session,
    BusinessDocument row, {
    _is.ColumnSelections<BusinessDocumentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BusinessDocument>(
      row,
      columns: columns?.call(BusinessDocument.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BusinessDocument] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BusinessDocument?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BusinessDocumentUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BusinessDocument>(
      id,
      columnValues: columnValues(BusinessDocument.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BusinessDocument]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessDocument>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BusinessDocumentUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<BusinessDocumentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessDocumentTable>? orderBy,
    _is.OrderByListBuilder<BusinessDocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BusinessDocument>(
      columnValues: columnValues(BusinessDocument.t.updateTable),
      where: where(BusinessDocument.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BusinessDocument.t),
      orderByList: orderByList?.call(BusinessDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BusinessDocument]s in the list and returns the deleted rows.
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
  Future<List<BusinessDocument>> delete(
    _is.DatabaseSession session,
    List<BusinessDocument> rows, {
    _is.OrderByBuilder<BusinessDocumentTable>? orderBy,
    _is.OrderByListBuilder<BusinessDocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BusinessDocument>(
      rows,
      orderBy: orderBy?.call(BusinessDocument.t),
      orderByList: orderByList?.call(BusinessDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BusinessDocument].
  Future<BusinessDocument> deleteRow(
    _is.DatabaseSession session,
    BusinessDocument row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BusinessDocument>(
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
  Future<List<BusinessDocument>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BusinessDocumentTable> where,
    _is.OrderByBuilder<BusinessDocumentTable>? orderBy,
    _is.OrderByListBuilder<BusinessDocumentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BusinessDocument>(
      where: where(BusinessDocument.t),
      orderBy: orderBy?.call(BusinessDocument.t),
      orderByList: orderByList?.call(BusinessDocument.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessDocumentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BusinessDocument>(
      where: where?.call(BusinessDocument.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BusinessDocument] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BusinessDocumentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BusinessDocument>(
      where: where(BusinessDocument.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
