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
import '../../ontology/models/disclosure_link_basis.dart' as _i0btqt1b;
import '../../ontology/models/relation_fact_kind.dart' as _ig5oatxf;
import '../../ontology/models/relation_origin.dart' as _i58iymfp;
import '../../ontology/models/relation_predicate.dart' as _iqv2n0qs;
import '../../ontology/models/relation_status.dart' as _ije7dn2u;

/// 온톨로지 관계(엣지) — 그래프 탐색용 공통 색인.
/// 3단계 관계는 주요정보 타입 층(ShareholderEntry 등)에서 다시 만들 수 있고, 자세한 값은 factKind·factId가 가리키는 행에 있다.
/// 각 기업의 가장 최근 사업보고서 기준으로 만든다.
abstract class OntologyRelation
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  OntologyRelation._({
    this.id,
    required this.predicate,
    this.subjectCompanyId,
    this.subjectPersonId,
    required this.subjectName,
    this.objectCompanyId,
    required this.objectName,
    this.asOf,
    required this.bsnsYear,
    this.weight,
    this.sourceId,
    required this.factKind,
    required this.factId,
    required this.extractedBy,
    required this.status,
    this.subjectBasis,
  });

  factory OntologyRelation({
    int? id,
    required _iqv2n0qs.RelationPredicate predicate,
    int? subjectCompanyId,
    int? subjectPersonId,
    required String subjectName,
    int? objectCompanyId,
    required String objectName,
    DateTime? asOf,
    required int bsnsYear,
    double? weight,
    int? sourceId,
    required _ig5oatxf.RelationFactKind factKind,
    required int factId,
    required _i58iymfp.RelationOrigin extractedBy,
    required _ije7dn2u.RelationStatus status,
    _i0btqt1b.DisclosureLinkBasis? subjectBasis,
  }) = _OntologyRelationImpl;

  factory OntologyRelation.fromJson(Map<String, dynamic> jsonSerialization) {
    return OntologyRelation(
      id: jsonSerialization['id'] as int?,
      predicate: _iqv2n0qs.RelationPredicate.fromJson(
        (jsonSerialization['predicate'] as String),
      ),
      subjectCompanyId: jsonSerialization['subjectCompanyId'] as int?,
      subjectPersonId: jsonSerialization['subjectPersonId'] as int?,
      subjectName: jsonSerialization['subjectName'] as String,
      objectCompanyId: jsonSerialization['objectCompanyId'] as int?,
      objectName: jsonSerialization['objectName'] as String,
      asOf: jsonSerialization['asOf'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['asOf']),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      weight: (jsonSerialization['weight'] as num?)?.toDouble(),
      sourceId: jsonSerialization['sourceId'] as int?,
      factKind: _ig5oatxf.RelationFactKind.fromJson(
        (jsonSerialization['factKind'] as String),
      ),
      factId: jsonSerialization['factId'] as int,
      extractedBy: _i58iymfp.RelationOrigin.fromJson(
        (jsonSerialization['extractedBy'] as String),
      ),
      status: _ije7dn2u.RelationStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      subjectBasis: jsonSerialization['subjectBasis'] == null
          ? null
          : _i0btqt1b.DisclosureLinkBasis.fromJson(
              (jsonSerialization['subjectBasis'] as String),
            ),
    );
  }

  static final t = OntologyRelationTable();

  static const db = OntologyRelationRepository._();

  @override
  int? id;

  _iqv2n0qs.RelationPredicate predicate;

  int? subjectCompanyId;

  int? subjectPersonId;

  /// 주어 이름 (연결되지 않았으면 이 이름뿐인 노드)
  String subjectName;

  int? objectCompanyId;

  String objectName;

  /// 기준일 (결산기준일)
  DateTime? asOf;

  int bsnsYear;

  /// 대표 수치 (지분율 %, 보통주 기준). 없으면 null
  double? weight;

  int? sourceId;

  _ig5oatxf.RelationFactKind factKind;

  int factId;

  _i58iymfp.RelationOrigin extractedBy;

  _ije7dn2u.RelationStatus status;

  /// 주어를 연결한 근거
  _i0btqt1b.DisclosureLinkBasis? subjectBasis;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [OntologyRelation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  OntologyRelation copyWith({
    int? id,
    _iqv2n0qs.RelationPredicate? predicate,
    int? subjectCompanyId,
    int? subjectPersonId,
    String? subjectName,
    int? objectCompanyId,
    String? objectName,
    DateTime? asOf,
    int? bsnsYear,
    double? weight,
    int? sourceId,
    _ig5oatxf.RelationFactKind? factKind,
    int? factId,
    _i58iymfp.RelationOrigin? extractedBy,
    _ije7dn2u.RelationStatus? status,
    _i0btqt1b.DisclosureLinkBasis? subjectBasis,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OntologyRelation',
      if (id != null) 'id': id,
      'predicate': predicate.toJson(),
      if (subjectCompanyId != null) 'subjectCompanyId': subjectCompanyId,
      if (subjectPersonId != null) 'subjectPersonId': subjectPersonId,
      'subjectName': subjectName,
      if (objectCompanyId != null) 'objectCompanyId': objectCompanyId,
      'objectName': objectName,
      if (asOf != null) 'asOf': asOf?.toJson(),
      'bsnsYear': bsnsYear,
      if (weight != null) 'weight': weight,
      if (sourceId != null) 'sourceId': sourceId,
      'factKind': factKind.toJson(),
      'factId': factId,
      'extractedBy': extractedBy.toJson(),
      'status': status.toJson(),
      if (subjectBasis != null) 'subjectBasis': subjectBasis?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OntologyRelation',
      if (id != null) 'id': id,
      'predicate': predicate.toJson(),
      if (subjectCompanyId != null) 'subjectCompanyId': subjectCompanyId,
      if (subjectPersonId != null) 'subjectPersonId': subjectPersonId,
      'subjectName': subjectName,
      if (objectCompanyId != null) 'objectCompanyId': objectCompanyId,
      'objectName': objectName,
      if (asOf != null) 'asOf': asOf?.toJson(),
      'bsnsYear': bsnsYear,
      if (weight != null) 'weight': weight,
      if (sourceId != null) 'sourceId': sourceId,
      'factKind': factKind.toJson(),
      'factId': factId,
      'extractedBy': extractedBy.toJson(),
      'status': status.toJson(),
      if (subjectBasis != null) 'subjectBasis': subjectBasis?.toJson(),
    };
  }

  static OntologyRelationInclude include() {
    return OntologyRelationInclude._();
  }

  static OntologyRelationIncludeList includeList({
    _is.WhereExpressionBuilder<OntologyRelationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OntologyRelationTable>? orderBy,
    _is.OrderByListBuilder<OntologyRelationTable>? orderByList,
    OntologyRelationInclude? include,
  }) {
    return OntologyRelationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OntologyRelation.t),
      orderByList: orderByList?.call(OntologyRelation.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OntologyRelationImpl extends OntologyRelation {
  _OntologyRelationImpl({
    int? id,
    required _iqv2n0qs.RelationPredicate predicate,
    int? subjectCompanyId,
    int? subjectPersonId,
    required String subjectName,
    int? objectCompanyId,
    required String objectName,
    DateTime? asOf,
    required int bsnsYear,
    double? weight,
    int? sourceId,
    required _ig5oatxf.RelationFactKind factKind,
    required int factId,
    required _i58iymfp.RelationOrigin extractedBy,
    required _ije7dn2u.RelationStatus status,
    _i0btqt1b.DisclosureLinkBasis? subjectBasis,
  }) : super._(
         id: id,
         predicate: predicate,
         subjectCompanyId: subjectCompanyId,
         subjectPersonId: subjectPersonId,
         subjectName: subjectName,
         objectCompanyId: objectCompanyId,
         objectName: objectName,
         asOf: asOf,
         bsnsYear: bsnsYear,
         weight: weight,
         sourceId: sourceId,
         factKind: factKind,
         factId: factId,
         extractedBy: extractedBy,
         status: status,
         subjectBasis: subjectBasis,
       );

  /// Returns a shallow copy of this [OntologyRelation]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  OntologyRelation copyWith({
    Object? id = _Undefined,
    _iqv2n0qs.RelationPredicate? predicate,
    Object? subjectCompanyId = _Undefined,
    Object? subjectPersonId = _Undefined,
    String? subjectName,
    Object? objectCompanyId = _Undefined,
    String? objectName,
    Object? asOf = _Undefined,
    int? bsnsYear,
    Object? weight = _Undefined,
    Object? sourceId = _Undefined,
    _ig5oatxf.RelationFactKind? factKind,
    int? factId,
    _i58iymfp.RelationOrigin? extractedBy,
    _ije7dn2u.RelationStatus? status,
    Object? subjectBasis = _Undefined,
  }) {
    return OntologyRelation(
      id: id is int? ? id : this.id,
      predicate: predicate ?? this.predicate,
      subjectCompanyId: subjectCompanyId is int?
          ? subjectCompanyId
          : this.subjectCompanyId,
      subjectPersonId: subjectPersonId is int?
          ? subjectPersonId
          : this.subjectPersonId,
      subjectName: subjectName ?? this.subjectName,
      objectCompanyId: objectCompanyId is int?
          ? objectCompanyId
          : this.objectCompanyId,
      objectName: objectName ?? this.objectName,
      asOf: asOf is DateTime? ? asOf : this.asOf,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      weight: weight is double? ? weight : this.weight,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      factKind: factKind ?? this.factKind,
      factId: factId ?? this.factId,
      extractedBy: extractedBy ?? this.extractedBy,
      status: status ?? this.status,
      subjectBasis: subjectBasis is _i0btqt1b.DisclosureLinkBasis?
          ? subjectBasis
          : this.subjectBasis,
    );
  }
}

class OntologyRelationUpdateTable
    extends _is.UpdateTable<OntologyRelationTable> {
  OntologyRelationUpdateTable(super.table);

  _is.ColumnValue<_iqv2n0qs.RelationPredicate, _iqv2n0qs.RelationPredicate>
  predicate(_iqv2n0qs.RelationPredicate value) => _is.ColumnValue(
    table.predicate,
    value,
  );

  _is.ColumnValue<int, int> subjectCompanyId(int? value) => _is.ColumnValue(
    table.subjectCompanyId,
    value,
  );

  _is.ColumnValue<int, int> subjectPersonId(int? value) => _is.ColumnValue(
    table.subjectPersonId,
    value,
  );

  _is.ColumnValue<String, String> subjectName(String value) => _is.ColumnValue(
    table.subjectName,
    value,
  );

  _is.ColumnValue<int, int> objectCompanyId(int? value) => _is.ColumnValue(
    table.objectCompanyId,
    value,
  );

  _is.ColumnValue<String, String> objectName(String value) => _is.ColumnValue(
    table.objectName,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> asOf(DateTime? value) => _is.ColumnValue(
    table.asOf,
    value,
  );

  _is.ColumnValue<int, int> bsnsYear(int value) => _is.ColumnValue(
    table.bsnsYear,
    value,
  );

  _is.ColumnValue<double, double> weight(double? value) => _is.ColumnValue(
    table.weight,
    value,
  );

  _is.ColumnValue<int, int> sourceId(int? value) => _is.ColumnValue(
    table.sourceId,
    value,
  );

  _is.ColumnValue<_ig5oatxf.RelationFactKind, _ig5oatxf.RelationFactKind>
  factKind(_ig5oatxf.RelationFactKind value) => _is.ColumnValue(
    table.factKind,
    value,
  );

  _is.ColumnValue<int, int> factId(int value) => _is.ColumnValue(
    table.factId,
    value,
  );

  _is.ColumnValue<_i58iymfp.RelationOrigin, _i58iymfp.RelationOrigin>
  extractedBy(_i58iymfp.RelationOrigin value) => _is.ColumnValue(
    table.extractedBy,
    value,
  );

  _is.ColumnValue<_ije7dn2u.RelationStatus, _ije7dn2u.RelationStatus> status(
    _ije7dn2u.RelationStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<_i0btqt1b.DisclosureLinkBasis, _i0btqt1b.DisclosureLinkBasis>
  subjectBasis(_i0btqt1b.DisclosureLinkBasis? value) => _is.ColumnValue(
    table.subjectBasis,
    value,
  );
}

class OntologyRelationTable extends _is.Table<int?> {
  OntologyRelationTable({super.tableRelation})
    : super(tableName: 'ontology_relation') {
    updateTable = OntologyRelationUpdateTable(this);
    predicate = _is.ColumnEnum(
      'predicate',
      this,
      _is.EnumSerialization.byName,
    );
    subjectCompanyId = _is.ColumnInt(
      'subjectCompanyId',
      this,
    );
    subjectPersonId = _is.ColumnInt(
      'subjectPersonId',
      this,
    );
    subjectName = _is.ColumnString(
      'subjectName',
      this,
    );
    objectCompanyId = _is.ColumnInt(
      'objectCompanyId',
      this,
    );
    objectName = _is.ColumnString(
      'objectName',
      this,
    );
    asOf = _is.ColumnDateTime(
      'asOf',
      this,
    );
    bsnsYear = _is.ColumnInt(
      'bsnsYear',
      this,
    );
    weight = _is.ColumnDouble(
      'weight',
      this,
    );
    sourceId = _is.ColumnInt(
      'sourceId',
      this,
    );
    factKind = _is.ColumnEnum(
      'factKind',
      this,
      _is.EnumSerialization.byName,
    );
    factId = _is.ColumnInt(
      'factId',
      this,
    );
    extractedBy = _is.ColumnEnum(
      'extractedBy',
      this,
      _is.EnumSerialization.byName,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    subjectBasis = _is.ColumnEnum(
      'subjectBasis',
      this,
      _is.EnumSerialization.byName,
    );
  }

  late final OntologyRelationUpdateTable updateTable;

  late final _is.ColumnEnum<_iqv2n0qs.RelationPredicate> predicate;

  late final _is.ColumnInt subjectCompanyId;

  late final _is.ColumnInt subjectPersonId;

  /// 주어 이름 (연결되지 않았으면 이 이름뿐인 노드)
  late final _is.ColumnString subjectName;

  late final _is.ColumnInt objectCompanyId;

  late final _is.ColumnString objectName;

  /// 기준일 (결산기준일)
  late final _is.ColumnDateTime asOf;

  late final _is.ColumnInt bsnsYear;

  /// 대표 수치 (지분율 %, 보통주 기준). 없으면 null
  late final _is.ColumnDouble weight;

  late final _is.ColumnInt sourceId;

  late final _is.ColumnEnum<_ig5oatxf.RelationFactKind> factKind;

  late final _is.ColumnInt factId;

  late final _is.ColumnEnum<_i58iymfp.RelationOrigin> extractedBy;

  late final _is.ColumnEnum<_ije7dn2u.RelationStatus> status;

  /// 주어를 연결한 근거
  late final _is.ColumnEnum<_i0btqt1b.DisclosureLinkBasis> subjectBasis;

  @override
  List<_is.Column> get columns => [
    id,
    predicate,
    subjectCompanyId,
    subjectPersonId,
    subjectName,
    objectCompanyId,
    objectName,
    asOf,
    bsnsYear,
    weight,
    sourceId,
    factKind,
    factId,
    extractedBy,
    status,
    subjectBasis,
  ];
}

class OntologyRelationInclude extends _is.IncludeObject {
  OntologyRelationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => OntologyRelation.t;
}

class OntologyRelationIncludeList extends _is.IncludeList {
  OntologyRelationIncludeList._({
    _is.WhereExpressionBuilder<OntologyRelationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(OntologyRelation.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => OntologyRelation.t;
}

class OntologyRelationRepository {
  const OntologyRelationRepository._();

  /// Returns a list of [OntologyRelation]s matching the given query parameters.
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
  Future<List<OntologyRelation>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OntologyRelationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OntologyRelationTable>? orderBy,
    _is.OrderByListBuilder<OntologyRelationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<OntologyRelation>(
      where: where?.call(OntologyRelation.t),
      orderBy: orderBy?.call(OntologyRelation.t),
      orderByList: orderByList?.call(OntologyRelation.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [OntologyRelation] matching the given query parameters.
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
  Future<OntologyRelation?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OntologyRelationTable>? where,
    int? offset,
    _is.OrderByBuilder<OntologyRelationTable>? orderBy,
    _is.OrderByListBuilder<OntologyRelationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<OntologyRelation>(
      where: where?.call(OntologyRelation.t),
      orderBy: orderBy?.call(OntologyRelation.t),
      orderByList: orderByList?.call(OntologyRelation.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [OntologyRelation] by its [id] or null if no such row exists.
  Future<OntologyRelation?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<OntologyRelation>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [OntologyRelation]s in the list and returns the inserted rows.
  ///
  /// The returned [OntologyRelation]s will have their `id` fields set.
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
  Future<List<OntologyRelation>> insert(
    _is.DatabaseSession session,
    List<OntologyRelation> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<OntologyRelation>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [OntologyRelation] and returns the inserted row.
  ///
  /// The returned [OntologyRelation] will have its `id` field set.
  Future<OntologyRelation> insertRow(
    _is.DatabaseSession session,
    OntologyRelation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<OntologyRelation>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [OntologyRelation]s in the list and returns the resulting rows.
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
  /// The returned [OntologyRelation]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OntologyRelation>> upsert(
    _is.DatabaseSession session,
    List<OntologyRelation> rows, {
    required _is.ColumnSelections<OntologyRelationTable> conflictColumns,
    _is.ColumnSelections<OntologyRelationTable>? updateColumns,
    _is.WhereExpressionBuilder<OntologyRelationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<OntologyRelation>(
      rows,
      conflictColumns: conflictColumns(OntologyRelation.t),
      updateColumns: updateColumns?.call(OntologyRelation.t),
      updateWhere: updateWhere?.call(OntologyRelation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [OntologyRelation] and returns the resulting row.
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
  /// The returned [OntologyRelation] will have its `id` field set.
  Future<OntologyRelation?> upsertRow(
    _is.DatabaseSession session,
    OntologyRelation row, {
    required _is.ColumnSelections<OntologyRelationTable> conflictColumns,
    _is.ColumnSelections<OntologyRelationTable>? updateColumns,
    _is.WhereExpressionBuilder<OntologyRelationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<OntologyRelation>(
      row,
      conflictColumns: conflictColumns(OntologyRelation.t),
      updateColumns: updateColumns?.call(OntologyRelation.t),
      updateWhere: updateWhere?.call(OntologyRelation.t),
      transaction: transaction,
    );
  }

  /// Updates all [OntologyRelation]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OntologyRelation>> update(
    _is.DatabaseSession session,
    List<OntologyRelation> rows, {
    _is.ColumnSelections<OntologyRelationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<OntologyRelation>(
      rows,
      columns: columns?.call(OntologyRelation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [OntologyRelation]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<OntologyRelation> updateRow(
    _is.DatabaseSession session,
    OntologyRelation row, {
    _is.ColumnSelections<OntologyRelationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<OntologyRelation>(
      row,
      columns: columns?.call(OntologyRelation.t),
      transaction: transaction,
    );
  }

  /// Updates a single [OntologyRelation] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<OntologyRelation?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<OntologyRelationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<OntologyRelation>(
      id,
      columnValues: columnValues(OntologyRelation.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [OntologyRelation]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<OntologyRelation>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<OntologyRelationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<OntologyRelationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<OntologyRelationTable>? orderBy,
    _is.OrderByListBuilder<OntologyRelationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<OntologyRelation>(
      columnValues: columnValues(OntologyRelation.t.updateTable),
      where: where(OntologyRelation.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(OntologyRelation.t),
      orderByList: orderByList?.call(OntologyRelation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [OntologyRelation]s in the list and returns the deleted rows.
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
  Future<List<OntologyRelation>> delete(
    _is.DatabaseSession session,
    List<OntologyRelation> rows, {
    _is.OrderByBuilder<OntologyRelationTable>? orderBy,
    _is.OrderByListBuilder<OntologyRelationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<OntologyRelation>(
      rows,
      orderBy: orderBy?.call(OntologyRelation.t),
      orderByList: orderByList?.call(OntologyRelation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [OntologyRelation].
  Future<OntologyRelation> deleteRow(
    _is.DatabaseSession session,
    OntologyRelation row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<OntologyRelation>(
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
  Future<List<OntologyRelation>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OntologyRelationTable> where,
    _is.OrderByBuilder<OntologyRelationTable>? orderBy,
    _is.OrderByListBuilder<OntologyRelationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<OntologyRelation>(
      where: where(OntologyRelation.t),
      orderBy: orderBy?.call(OntologyRelation.t),
      orderByList: orderByList?.call(OntologyRelation.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<OntologyRelationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<OntologyRelation>(
      where: where?.call(OntologyRelation.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [OntologyRelation] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<OntologyRelationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<OntologyRelation>(
      where: where(OntologyRelation.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
