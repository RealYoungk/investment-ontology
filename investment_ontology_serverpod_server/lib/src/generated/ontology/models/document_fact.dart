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
import '../../ontology/models/document_fact_kind.dart' as _izbt83zi;
import '../../ontology/models/relation_origin.dart' as _i58iymfp;
import '../../ontology/models/relation_status.dart' as _ije7dn2u;

/// 사업보고서 본문에서 뽑은 값 하나 (수주잔고·가동률·점유율 등).
///
/// 숫자는 원문에 적힌 단위 그대로 둔다 (바꾸지 않는다). 근거 문장이 원문에 그대로 있어야
/// 하고, 사람이 승인해야 확정이다 — AI 관계([OntologyRelation])와 같은 규칙이다.
abstract class DocumentFact
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DocumentFact._({
    this.id,
    required this.companyId,
    required this.documentId,
    required this.bsnsYear,
    required this.kind,
    required this.label,
    required this.value,
    required this.unit,
    this.asOf,
    required this.evidence,
    this.sourceId,
    required this.extractedBy,
    this.extractorModel,
    this.confidence,
    required this.status,
    this.reviewedAt,
    this.reviewedBy,
    required this.createdAt,
  });

  factory DocumentFact({
    int? id,
    required int companyId,
    required int documentId,
    required int bsnsYear,
    required _izbt83zi.DocumentFactKind kind,
    required String label,
    required double value,
    required String unit,
    DateTime? asOf,
    required String evidence,
    int? sourceId,
    required _i58iymfp.RelationOrigin extractedBy,
    String? extractorModel,
    double? confidence,
    required _ije7dn2u.RelationStatus status,
    DateTime? reviewedAt,
    String? reviewedBy,
    required DateTime createdAt,
  }) = _DocumentFactImpl;

  factory DocumentFact.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentFact(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      documentId: jsonSerialization['documentId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      kind: _izbt83zi.DocumentFactKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      label: jsonSerialization['label'] as String,
      value: (jsonSerialization['value'] as num).toDouble(),
      unit: jsonSerialization['unit'] as String,
      asOf: jsonSerialization['asOf'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['asOf']),
      evidence: jsonSerialization['evidence'] as String,
      sourceId: jsonSerialization['sourceId'] as int?,
      extractedBy: _i58iymfp.RelationOrigin.fromJson(
        (jsonSerialization['extractedBy'] as String),
      ),
      extractorModel: jsonSerialization['extractorModel'] as String?,
      confidence: (jsonSerialization['confidence'] as num?)?.toDouble(),
      status: _ije7dn2u.RelationStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      reviewedAt: jsonSerialization['reviewedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['reviewedAt']),
      reviewedBy: jsonSerialization['reviewedBy'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = DocumentFactTable();

  static const db = DocumentFactRepository._();

  @override
  int? id;

  int companyId;

  int documentId;

  int bsnsYear;

  _izbt83zi.DocumentFactKind kind;

  /// 어느 부문·품목의 값인지 (예: 건설사업, 항공, 합계)
  String label;

  /// 값. 공시에 적힌 단위 그대로
  double value;

  /// 단위 표기 (백만원, 억원, 백만 달러, %, 대 등)
  String unit;

  /// 기준일 (본문에 있으면)
  DateTime? asOf;

  /// 원문에 그대로 있는 근거 문장
  String evidence;

  int? sourceId;

  _i58iymfp.RelationOrigin extractedBy;

  String? extractorModel;

  double? confidence;

  _ije7dn2u.RelationStatus status;

  DateTime? reviewedAt;

  /// 누가 결정했는지 (사람이면 null, AI가 원문과 대조했으면 그 이름)
  String? reviewedBy;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DocumentFact]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocumentFact copyWith({
    int? id,
    int? companyId,
    int? documentId,
    int? bsnsYear,
    _izbt83zi.DocumentFactKind? kind,
    String? label,
    double? value,
    String? unit,
    DateTime? asOf,
    String? evidence,
    int? sourceId,
    _i58iymfp.RelationOrigin? extractedBy,
    String? extractorModel,
    double? confidence,
    _ije7dn2u.RelationStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentFact',
      if (id != null) 'id': id,
      'companyId': companyId,
      'documentId': documentId,
      'bsnsYear': bsnsYear,
      'kind': kind.toJson(),
      'label': label,
      'value': value,
      'unit': unit,
      if (asOf != null) 'asOf': asOf?.toJson(),
      'evidence': evidence,
      if (sourceId != null) 'sourceId': sourceId,
      'extractedBy': extractedBy.toJson(),
      if (extractorModel != null) 'extractorModel': extractorModel,
      if (confidence != null) 'confidence': confidence,
      'status': status.toJson(),
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentFact',
      if (id != null) 'id': id,
      'companyId': companyId,
      'documentId': documentId,
      'bsnsYear': bsnsYear,
      'kind': kind.toJson(),
      'label': label,
      'value': value,
      'unit': unit,
      if (asOf != null) 'asOf': asOf?.toJson(),
      'evidence': evidence,
      if (sourceId != null) 'sourceId': sourceId,
      'extractedBy': extractedBy.toJson(),
      if (extractorModel != null) 'extractorModel': extractorModel,
      if (confidence != null) 'confidence': confidence,
      'status': status.toJson(),
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      'createdAt': createdAt.toJson(),
    };
  }

  static DocumentFactInclude include() {
    return DocumentFactInclude._();
  }

  static DocumentFactIncludeList includeList({
    _is.WhereExpressionBuilder<DocumentFactTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentFactTable>? orderBy,
    _is.OrderByListBuilder<DocumentFactTable>? orderByList,
    DocumentFactInclude? include,
  }) {
    return DocumentFactIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentFact.t),
      orderByList: orderByList?.call(DocumentFact.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentFactImpl extends DocumentFact {
  _DocumentFactImpl({
    int? id,
    required int companyId,
    required int documentId,
    required int bsnsYear,
    required _izbt83zi.DocumentFactKind kind,
    required String label,
    required double value,
    required String unit,
    DateTime? asOf,
    required String evidence,
    int? sourceId,
    required _i58iymfp.RelationOrigin extractedBy,
    String? extractorModel,
    double? confidence,
    required _ije7dn2u.RelationStatus status,
    DateTime? reviewedAt,
    String? reviewedBy,
    required DateTime createdAt,
  }) : super._(
         id: id,
         companyId: companyId,
         documentId: documentId,
         bsnsYear: bsnsYear,
         kind: kind,
         label: label,
         value: value,
         unit: unit,
         asOf: asOf,
         evidence: evidence,
         sourceId: sourceId,
         extractedBy: extractedBy,
         extractorModel: extractorModel,
         confidence: confidence,
         status: status,
         reviewedAt: reviewedAt,
         reviewedBy: reviewedBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DocumentFact]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocumentFact copyWith({
    Object? id = _Undefined,
    int? companyId,
    int? documentId,
    int? bsnsYear,
    _izbt83zi.DocumentFactKind? kind,
    String? label,
    double? value,
    String? unit,
    Object? asOf = _Undefined,
    String? evidence,
    Object? sourceId = _Undefined,
    _i58iymfp.RelationOrigin? extractedBy,
    Object? extractorModel = _Undefined,
    Object? confidence = _Undefined,
    _ije7dn2u.RelationStatus? status,
    Object? reviewedAt = _Undefined,
    Object? reviewedBy = _Undefined,
    DateTime? createdAt,
  }) {
    return DocumentFact(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      documentId: documentId ?? this.documentId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      asOf: asOf is DateTime? ? asOf : this.asOf,
      evidence: evidence ?? this.evidence,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      extractedBy: extractedBy ?? this.extractedBy,
      extractorModel: extractorModel is String?
          ? extractorModel
          : this.extractorModel,
      confidence: confidence is double? ? confidence : this.confidence,
      status: status ?? this.status,
      reviewedAt: reviewedAt is DateTime? ? reviewedAt : this.reviewedAt,
      reviewedBy: reviewedBy is String? ? reviewedBy : this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DocumentFactUpdateTable extends _is.UpdateTable<DocumentFactTable> {
  DocumentFactUpdateTable(super.table);

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

  _is.ColumnValue<_izbt83zi.DocumentFactKind, _izbt83zi.DocumentFactKind> kind(
    _izbt83zi.DocumentFactKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<double, double> value(double value) => _is.ColumnValue(
    table.value,
    value,
  );

  _is.ColumnValue<String, String> unit(String value) => _is.ColumnValue(
    table.unit,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> asOf(DateTime? value) => _is.ColumnValue(
    table.asOf,
    value,
  );

  _is.ColumnValue<String, String> evidence(String value) => _is.ColumnValue(
    table.evidence,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<_i58iymfp.RelationOrigin, _i58iymfp.RelationOrigin>
  extractedBy(_i58iymfp.RelationOrigin value) => _is.ColumnValue(
    table.extractedBy,
    value,
  );

  _is.ColumnValue<String, String> extractorModel(String? value) =>
      _is.ColumnValue(
        table.extractorModel,
        value,
      );

  _is.ColumnValue<double, double> confidence(double? value) => _is.ColumnValue(
    table.confidence,
    value,
  );

  _is.ColumnValue<_ije7dn2u.RelationStatus, _ije7dn2u.RelationStatus> status(
    _ije7dn2u.RelationStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> reviewedAt(DateTime? value) =>
      _is.ColumnValue(
        table.reviewedAt,
        value,
      );

  _is.ColumnValue<String, String> reviewedBy(String? value) => _is.ColumnValue(
    table.reviewedBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DocumentFactTable extends _is.Table<int?> {
  DocumentFactTable({super.tableRelation}) : super(tableName: 'document_fact') {
    updateTable = DocumentFactUpdateTable(this);
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
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    value = _is.ColumnDouble(
      'value',
      this,
    );
    unit = _is.ColumnString(
      'unit',
      this,
    );
    asOf = _is.ColumnDateTime(
      'asOf',
      this,
    );
    evidence = _is.ColumnString(
      'evidence',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    extractedBy = _is.ColumnEnum(
      'extractedBy',
      this,
      _is.EnumSerialization.byName,
    );
    extractorModel = _is.ColumnString(
      'extractorModel',
      this,
    );
    confidence = _is.ColumnDouble(
      'confidence',
      this,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    reviewedAt = _is.ColumnDateTime(
      'reviewedAt',
      this,
    );
    reviewedBy = _is.ColumnString(
      'reviewedBy',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DocumentFactUpdateTable updateTable;

  late final _is.ColumnInt companyId;

  late final _is.ColumnInt documentId;

  late final _is.ColumnInt bsnsYear;

  late final _is.ColumnEnum<_izbt83zi.DocumentFactKind> kind;

  /// 어느 부문·품목의 값인지 (예: 건설사업, 항공, 합계)
  late final _is.ColumnString label;

  /// 값. 공시에 적힌 단위 그대로
  late final _is.ColumnDouble value;

  /// 단위 표기 (백만원, 억원, 백만 달러, %, 대 등)
  late final _is.ColumnString unit;

  /// 기준일 (본문에 있으면)
  late final _is.ColumnDateTime asOf;

  /// 원문에 그대로 있는 근거 문장
  late final _is.ColumnString evidence;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnEnum<_i58iymfp.RelationOrigin> extractedBy;

  late final _is.ColumnString extractorModel;

  late final _is.ColumnDouble confidence;

  late final _is.ColumnEnum<_ije7dn2u.RelationStatus> status;

  late final _is.ColumnDateTime reviewedAt;

  /// 누가 결정했는지 (사람이면 null, AI가 원문과 대조했으면 그 이름)
  late final _is.ColumnString reviewedBy;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    companyId,
    documentId,
    bsnsYear,
    kind,
    label,
    value,
    unit,
    asOf,
    evidence,
    sourceId,
    extractedBy,
    extractorModel,
    confidence,
    status,
    reviewedAt,
    reviewedBy,
    createdAt,
  ];
}

class DocumentFactInclude extends _is.IncludeObject {
  DocumentFactInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DocumentFact.t;
}

class DocumentFactIncludeList extends _is.IncludeList {
  DocumentFactIncludeList._({
    _is.WhereExpressionBuilder<DocumentFactTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DocumentFact.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DocumentFact.t;
}

class DocumentFactRepository {
  const DocumentFactRepository._();

  /// Returns a list of [DocumentFact]s matching the given query parameters.
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
  Future<List<DocumentFact>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentFactTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentFactTable>? orderBy,
    _is.OrderByListBuilder<DocumentFactTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DocumentFact>(
      where: where?.call(DocumentFact.t),
      orderBy: orderBy?.call(DocumentFact.t),
      orderByList: orderByList?.call(DocumentFact.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [DocumentFact] matching the given query parameters.
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
  Future<DocumentFact?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentFactTable>? where,
    int? offset,
    _is.OrderByBuilder<DocumentFactTable>? orderBy,
    _is.OrderByListBuilder<DocumentFactTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DocumentFact>(
      where: where?.call(DocumentFact.t),
      orderBy: orderBy?.call(DocumentFact.t),
      orderByList: orderByList?.call(DocumentFact.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DocumentFact] by its [id] or null if no such row exists.
  Future<DocumentFact?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DocumentFact>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DocumentFact]s in the list and returns the inserted rows.
  ///
  /// The returned [DocumentFact]s will have their `id` fields set.
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
  Future<List<DocumentFact>> insert(
    _is.DatabaseSession session,
    List<DocumentFact> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DocumentFact>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DocumentFact] and returns the inserted row.
  ///
  /// The returned [DocumentFact] will have its `id` field set.
  Future<DocumentFact> insertRow(
    _is.DatabaseSession session,
    DocumentFact row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DocumentFact>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DocumentFact]s in the list and returns the resulting rows.
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
  /// The returned [DocumentFact]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentFact>> upsert(
    _is.DatabaseSession session,
    List<DocumentFact> rows, {
    required _is.ColumnSelections<DocumentFactTable> conflictColumns,
    _is.ColumnSelections<DocumentFactTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentFactTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DocumentFact>(
      rows,
      conflictColumns: conflictColumns(DocumentFact.t),
      updateColumns: updateColumns?.call(DocumentFact.t),
      updateWhere: updateWhere?.call(DocumentFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DocumentFact] and returns the resulting row.
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
  /// The returned [DocumentFact] will have its `id` field set.
  Future<DocumentFact?> upsertRow(
    _is.DatabaseSession session,
    DocumentFact row, {
    required _is.ColumnSelections<DocumentFactTable> conflictColumns,
    _is.ColumnSelections<DocumentFactTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentFactTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DocumentFact>(
      row,
      conflictColumns: conflictColumns(DocumentFact.t),
      updateColumns: updateColumns?.call(DocumentFact.t),
      updateWhere: updateWhere?.call(DocumentFact.t),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentFact]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentFact>> update(
    _is.DatabaseSession session,
    List<DocumentFact> rows, {
    _is.ColumnSelections<DocumentFactTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DocumentFact>(
      rows,
      columns: columns?.call(DocumentFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DocumentFact]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DocumentFact> updateRow(
    _is.DatabaseSession session,
    DocumentFact row, {
    _is.ColumnSelections<DocumentFactTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DocumentFact>(
      row,
      columns: columns?.call(DocumentFact.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DocumentFact] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DocumentFact?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DocumentFactUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DocumentFact>(
      id,
      columnValues: columnValues(DocumentFact.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentFact]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentFact>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DocumentFactUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DocumentFactTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentFactTable>? orderBy,
    _is.OrderByListBuilder<DocumentFactTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DocumentFact>(
      columnValues: columnValues(DocumentFact.t.updateTable),
      where: where(DocumentFact.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentFact.t),
      orderByList: orderByList?.call(DocumentFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DocumentFact]s in the list and returns the deleted rows.
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
  Future<List<DocumentFact>> delete(
    _is.DatabaseSession session,
    List<DocumentFact> rows, {
    _is.OrderByBuilder<DocumentFactTable>? orderBy,
    _is.OrderByListBuilder<DocumentFactTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DocumentFact>(
      rows,
      orderBy: orderBy?.call(DocumentFact.t),
      orderByList: orderByList?.call(DocumentFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DocumentFact].
  Future<DocumentFact> deleteRow(
    _is.DatabaseSession session,
    DocumentFact row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DocumentFact>(
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
  Future<List<DocumentFact>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentFactTable> where,
    _is.OrderByBuilder<DocumentFactTable>? orderBy,
    _is.OrderByListBuilder<DocumentFactTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DocumentFact>(
      where: where(DocumentFact.t),
      orderBy: orderBy?.call(DocumentFact.t),
      orderByList: orderByList?.call(DocumentFact.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentFactTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DocumentFact>(
      where: where?.call(DocumentFact.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DocumentFact] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentFactTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DocumentFact>(
      where: where(DocumentFact.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
