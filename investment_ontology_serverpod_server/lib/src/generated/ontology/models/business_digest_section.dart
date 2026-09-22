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
import '../../ontology/models/business_digest_kind.dart' as _ir8vruw8;

/// 사업보고서 "사업의 내용"을 절마다 읽기 좋게 녹인 글. 원문을 통째로 보여 주는 대신 이것을 보여 준다.
///
/// AI가 화면 요청 중에 쓰는 것이 아니라 서버 밖에서 미리 읽어 넣는다 (ai.submitDigest).
/// 근거 인용(evidence)은 원문에 글자 그대로 있어야 저장된다 — 관계·값과 같은 규칙.
abstract class BusinessDigestSection
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  BusinessDigestSection._({
    this.id,
    required this.companyId,
    required this.documentId,
    required this.bsnsYear,
    required this.ord,
    required this.kind,
    required this.title,
    required this.summary,
    required this.evidence,
    required this.extractorModel,
    this.sourceId,
    required this.createdAt,
  });

  factory BusinessDigestSection({
    int? id,
    required int companyId,
    required int documentId,
    required int bsnsYear,
    required int ord,
    required _ir8vruw8.BusinessDigestKind kind,
    required String title,
    required String summary,
    required String evidence,
    required String extractorModel,
    int? sourceId,
    required DateTime createdAt,
  }) = _BusinessDigestSectionImpl;

  factory BusinessDigestSection.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BusinessDigestSection(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      documentId: jsonSerialization['documentId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      kind: _ir8vruw8.BusinessDigestKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      title: jsonSerialization['title'] as String,
      summary: jsonSerialization['summary'] as String,
      evidence: jsonSerialization['evidence'] as String,
      extractorModel: jsonSerialization['extractorModel'] as String,
      sourceId: jsonSerialization['sourceId'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = BusinessDigestSectionTable();

  static const db = BusinessDigestSectionRepository._();

  @override
  int? id;

  int companyId;

  int documentId;

  int bsnsYear;

  /// 화면 순서
  int ord;

  _ir8vruw8.BusinessDigestKind kind;

  String title;

  /// 요약 글 (몇 문장, 줄바꿈으로 문단)
  String summary;

  /// 원문에서 그대로 옮긴 근거 인용 (가장 중요한 문장·표 줄)
  String evidence;

  /// 누가 읽었는지 (모델·세션)
  String extractorModel;

  int? sourceId;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BusinessDigestSection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessDigestSection copyWith({
    int? id,
    int? companyId,
    int? documentId,
    int? bsnsYear,
    int? ord,
    _ir8vruw8.BusinessDigestKind? kind,
    String? title,
    String? summary,
    String? evidence,
    String? extractorModel,
    int? sourceId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessDigestSection',
      if (id != null) 'id': id,
      'companyId': companyId,
      'documentId': documentId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'kind': kind.toJson(),
      'title': title,
      'summary': summary,
      'evidence': evidence,
      'extractorModel': extractorModel,
      if (sourceId != null) 'sourceId': sourceId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessDigestSection',
      if (id != null) 'id': id,
      'companyId': companyId,
      'documentId': documentId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'kind': kind.toJson(),
      'title': title,
      'summary': summary,
      'evidence': evidence,
      'extractorModel': extractorModel,
      if (sourceId != null) 'sourceId': sourceId,
      'createdAt': createdAt.toJson(),
    };
  }

  static BusinessDigestSectionInclude include() {
    return BusinessDigestSectionInclude._();
  }

  static BusinessDigestSectionIncludeList includeList({
    _is.WhereExpressionBuilder<BusinessDigestSectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessDigestSectionTable>? orderBy,
    _is.OrderByListBuilder<BusinessDigestSectionTable>? orderByList,
    BusinessDigestSectionInclude? include,
  }) {
    return BusinessDigestSectionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BusinessDigestSection.t),
      orderByList: orderByList?.call(BusinessDigestSection.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessDigestSectionImpl extends BusinessDigestSection {
  _BusinessDigestSectionImpl({
    int? id,
    required int companyId,
    required int documentId,
    required int bsnsYear,
    required int ord,
    required _ir8vruw8.BusinessDigestKind kind,
    required String title,
    required String summary,
    required String evidence,
    required String extractorModel,
    int? sourceId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         companyId: companyId,
         documentId: documentId,
         bsnsYear: bsnsYear,
         ord: ord,
         kind: kind,
         title: title,
         summary: summary,
         evidence: evidence,
         extractorModel: extractorModel,
         sourceId: sourceId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [BusinessDigestSection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessDigestSection copyWith({
    Object? id = _Undefined,
    int? companyId,
    int? documentId,
    int? bsnsYear,
    int? ord,
    _ir8vruw8.BusinessDigestKind? kind,
    String? title,
    String? summary,
    String? evidence,
    String? extractorModel,
    Object? sourceId = _Undefined,
    DateTime? createdAt,
  }) {
    return BusinessDigestSection(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      documentId: documentId ?? this.documentId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      evidence: evidence ?? this.evidence,
      extractorModel: extractorModel ?? this.extractorModel,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BusinessDigestSectionUpdateTable
    extends _is.UpdateTable<BusinessDigestSectionTable> {
  BusinessDigestSectionUpdateTable(super.table);

  _is.ColumnValue<int, int> companyId(int value) => _is.ColumnValue(
    table.companyId,
    value,
  );

  _is.ColumnValue<int, int> documentId(int value) => _is.ColumnValue(
    table.documentId,
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

  _is.ColumnValue<_ir8vruw8.BusinessDigestKind, _ir8vruw8.BusinessDigestKind>
  kind(_ir8vruw8.BusinessDigestKind value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> summary(String value) => _is.ColumnValue(
    table.summary,
    value,
  );

  _is.ColumnValue<String, String> evidence(String value) => _is.ColumnValue(
    table.evidence,
    value,
  );

  _is.ColumnValue<String, String> extractorModel(String value) =>
      _is.ColumnValue(
        table.extractorModel,
        value,
      );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class BusinessDigestSectionTable extends _is.Table<int?> {
  BusinessDigestSectionTable({super.tableRelation})
    : super(tableName: 'business_digest_section') {
    updateTable = BusinessDigestSectionUpdateTable(this);
    companyId = _is.ColumnInt(
      'companyId',
      this,
    );
    documentId = _is.ColumnInt(
      'documentId',
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
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    summary = _is.ColumnString(
      'summary',
      this,
    );
    evidence = _is.ColumnString(
      'evidence',
      this,
    );
    extractorModel = _is.ColumnString(
      'extractorModel',
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

  late final BusinessDigestSectionUpdateTable updateTable;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt documentId;

  late final _is.ColumnInt bsnsYear;

  /// 화면 순서
  late final _is.ColumnInt ord;

  late final _is.ColumnEnum<_ir8vruw8.BusinessDigestKind> kind;

  late final _is.ColumnString title;

  /// 요약 글 (몇 문장, 줄바꿈으로 문단)
  late final _is.ColumnString summary;

  /// 원문에서 그대로 옮긴 근거 인용 (가장 중요한 문장·표 줄)
  late final _is.ColumnString evidence;

  /// 누가 읽었는지 (모델·세션)
  late final _is.ColumnString extractorModel;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    companyId,
    documentId,
    bsnsYear,
    ord,
    kind,
    title,
    summary,
    evidence,
    extractorModel,
    sourceId,
    createdAt,
  ];
}

class BusinessDigestSectionInclude extends _is.IncludeObject {
  BusinessDigestSectionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BusinessDigestSection.t;
}

class BusinessDigestSectionIncludeList extends _is.IncludeList {
  BusinessDigestSectionIncludeList._({
    _is.WhereExpressionBuilder<BusinessDigestSectionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BusinessDigestSection.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BusinessDigestSection.t;
}

class BusinessDigestSectionRepository {
  const BusinessDigestSectionRepository._();

  /// Returns a list of [BusinessDigestSection]s matching the given query parameters.
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
  Future<List<BusinessDigestSection>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessDigestSectionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessDigestSectionTable>? orderBy,
    _is.OrderByListBuilder<BusinessDigestSectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BusinessDigestSection>(
      where: where?.call(BusinessDigestSection.t),
      orderBy: orderBy?.call(BusinessDigestSection.t),
      orderByList: orderByList?.call(BusinessDigestSection.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [BusinessDigestSection] matching the given query parameters.
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
  Future<BusinessDigestSection?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessDigestSectionTable>? where,
    int? offset,
    _is.OrderByBuilder<BusinessDigestSectionTable>? orderBy,
    _is.OrderByListBuilder<BusinessDigestSectionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BusinessDigestSection>(
      where: where?.call(BusinessDigestSection.t),
      orderBy: orderBy?.call(BusinessDigestSection.t),
      orderByList: orderByList?.call(BusinessDigestSection.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BusinessDigestSection] by its [id] or null if no such row exists.
  Future<BusinessDigestSection?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BusinessDigestSection>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BusinessDigestSection]s in the list and returns the inserted rows.
  ///
  /// The returned [BusinessDigestSection]s will have their `id` fields set.
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
  Future<List<BusinessDigestSection>> insert(
    _is.DatabaseSession session,
    List<BusinessDigestSection> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BusinessDigestSection>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BusinessDigestSection] and returns the inserted row.
  ///
  /// The returned [BusinessDigestSection] will have its `id` field set.
  Future<BusinessDigestSection> insertRow(
    _is.DatabaseSession session,
    BusinessDigestSection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BusinessDigestSection>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BusinessDigestSection]s in the list and returns the resulting rows.
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
  /// The returned [BusinessDigestSection]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessDigestSection>> upsert(
    _is.DatabaseSession session,
    List<BusinessDigestSection> rows, {
    required _is.ColumnSelections<BusinessDigestSectionTable> conflictColumns,
    _is.ColumnSelections<BusinessDigestSectionTable>? updateColumns,
    _is.WhereExpressionBuilder<BusinessDigestSectionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BusinessDigestSection>(
      rows,
      conflictColumns: conflictColumns(BusinessDigestSection.t),
      updateColumns: updateColumns?.call(BusinessDigestSection.t),
      updateWhere: updateWhere?.call(BusinessDigestSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BusinessDigestSection] and returns the resulting row.
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
  /// The returned [BusinessDigestSection] will have its `id` field set.
  Future<BusinessDigestSection?> upsertRow(
    _is.DatabaseSession session,
    BusinessDigestSection row, {
    required _is.ColumnSelections<BusinessDigestSectionTable> conflictColumns,
    _is.ColumnSelections<BusinessDigestSectionTable>? updateColumns,
    _is.WhereExpressionBuilder<BusinessDigestSectionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BusinessDigestSection>(
      row,
      conflictColumns: conflictColumns(BusinessDigestSection.t),
      updateColumns: updateColumns?.call(BusinessDigestSection.t),
      updateWhere: updateWhere?.call(BusinessDigestSection.t),
      transaction: transaction,
    );
  }

  /// Updates all [BusinessDigestSection]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessDigestSection>> update(
    _is.DatabaseSession session,
    List<BusinessDigestSection> rows, {
    _is.ColumnSelections<BusinessDigestSectionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BusinessDigestSection>(
      rows,
      columns: columns?.call(BusinessDigestSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BusinessDigestSection]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BusinessDigestSection> updateRow(
    _is.DatabaseSession session,
    BusinessDigestSection row, {
    _is.ColumnSelections<BusinessDigestSectionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BusinessDigestSection>(
      row,
      columns: columns?.call(BusinessDigestSection.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BusinessDigestSection] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BusinessDigestSection?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BusinessDigestSectionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BusinessDigestSection>(
      id,
      columnValues: columnValues(BusinessDigestSection.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BusinessDigestSection]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BusinessDigestSection>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BusinessDigestSectionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<BusinessDigestSectionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BusinessDigestSectionTable>? orderBy,
    _is.OrderByListBuilder<BusinessDigestSectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BusinessDigestSection>(
      columnValues: columnValues(BusinessDigestSection.t.updateTable),
      where: where(BusinessDigestSection.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BusinessDigestSection.t),
      orderByList: orderByList?.call(BusinessDigestSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BusinessDigestSection]s in the list and returns the deleted rows.
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
  Future<List<BusinessDigestSection>> delete(
    _is.DatabaseSession session,
    List<BusinessDigestSection> rows, {
    _is.OrderByBuilder<BusinessDigestSectionTable>? orderBy,
    _is.OrderByListBuilder<BusinessDigestSectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BusinessDigestSection>(
      rows,
      orderBy: orderBy?.call(BusinessDigestSection.t),
      orderByList: orderByList?.call(BusinessDigestSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BusinessDigestSection].
  Future<BusinessDigestSection> deleteRow(
    _is.DatabaseSession session,
    BusinessDigestSection row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BusinessDigestSection>(
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
  Future<List<BusinessDigestSection>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BusinessDigestSectionTable> where,
    _is.OrderByBuilder<BusinessDigestSectionTable>? orderBy,
    _is.OrderByListBuilder<BusinessDigestSectionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BusinessDigestSection>(
      where: where(BusinessDigestSection.t),
      orderBy: orderBy?.call(BusinessDigestSection.t),
      orderByList: orderByList?.call(BusinessDigestSection.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BusinessDigestSectionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BusinessDigestSection>(
      where: where?.call(BusinessDigestSection.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BusinessDigestSection] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BusinessDigestSectionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BusinessDigestSection>(
      where: where(BusinessDigestSection.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
