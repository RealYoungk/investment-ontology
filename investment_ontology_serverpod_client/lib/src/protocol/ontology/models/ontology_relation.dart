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
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/disclosure_link_basis.dart' as _i0btqt1b;
import '../../ontology/models/relation_fact_kind.dart' as _ig5oatxf;
import '../../ontology/models/relation_origin.dart' as _i58iymfp;
import '../../ontology/models/relation_predicate.dart' as _iqv2n0qs;
import '../../ontology/models/relation_status.dart' as _ije7dn2u;

/// 온톨로지 관계(엣지) — 그래프 탐색용 공통 색인.
/// 3단계 관계는 주요정보 타입 층(ShareholderEntry 등)에서 다시 만들 수 있고, 자세한 값은 factKind·factId가 가리키는 행에 있다.
/// 각 기업의 가장 최근 사업보고서 기준으로 만든다.
abstract class OntologyRelation
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    this.evidence,
    this.confidence,
    this.extractorModel,
    this.reviewedAt,
    this.reviewedBy,
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
    String? evidence,
    double? confidence,
    String? extractorModel,
    DateTime? reviewedAt,
    String? reviewedBy,
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
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['asOf']),
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
      evidence: jsonSerialization['evidence'] as String?,
      confidence: (jsonSerialization['confidence'] as num?)?.toDouble(),
      extractorModel: jsonSerialization['extractorModel'] as String?,
      reviewedAt: jsonSerialization['reviewedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['reviewedAt'],
            ),
      reviewedBy: jsonSerialization['reviewedBy'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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

  /// AI 추출: 원문 그대로의 인용 (원문에 없으면 저장하지 않는다)
  String? evidence;

  /// AI 추출: 모델이 매긴 확신도 (0~1)
  double? confidence;

  /// AI 추출: 모델 이름
  String? extractorModel;

  /// 사람이 승인·거절한 시각
  DateTime? reviewedAt;

  /// 누가 결정했는지 (사람이면 null, AI가 원문과 대조했으면 그 이름)
  String? reviewedBy;

  /// Returns a shallow copy of this [OntologyRelation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    String? evidence,
    double? confidence,
    String? extractorModel,
    DateTime? reviewedAt,
    String? reviewedBy,
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
      if (evidence != null) 'evidence': evidence,
      if (confidence != null) 'confidence': confidence,
      if (extractorModel != null) 'extractorModel': extractorModel,
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
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
      if (evidence != null) 'evidence': evidence,
      if (confidence != null) 'confidence': confidence,
      if (extractorModel != null) 'extractorModel': extractorModel,
      if (reviewedAt != null) 'reviewedAt': reviewedAt?.toJson(),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
    String? evidence,
    double? confidence,
    String? extractorModel,
    DateTime? reviewedAt,
    String? reviewedBy,
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
         evidence: evidence,
         confidence: confidence,
         extractorModel: extractorModel,
         reviewedAt: reviewedAt,
         reviewedBy: reviewedBy,
       );

  /// Returns a shallow copy of this [OntologyRelation]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    Object? evidence = _Undefined,
    Object? confidence = _Undefined,
    Object? extractorModel = _Undefined,
    Object? reviewedAt = _Undefined,
    Object? reviewedBy = _Undefined,
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
      evidence: evidence is String? ? evidence : this.evidence,
      confidence: confidence is double? ? confidence : this.confidence,
      extractorModel: extractorModel is String?
          ? extractorModel
          : this.extractorModel,
      reviewedAt: reviewedAt is DateTime? ? reviewedAt : this.reviewedAt,
      reviewedBy: reviewedBy is String? ? reviewedBy : this.reviewedBy,
    );
  }
}
