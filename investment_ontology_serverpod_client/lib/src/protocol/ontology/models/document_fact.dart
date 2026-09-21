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
import '../../ontology/models/document_fact_kind.dart' as _izbt83zi;
import '../../ontology/models/relation_origin.dart' as _i58iymfp;
import '../../ontology/models/relation_status.dart' as _ije7dn2u;

/// 사업보고서 본문에서 뽑은 값 하나 (수주잔고·가동률·점유율 등).
///
/// 숫자는 원문에 적힌 단위 그대로 둔다 (바꾸지 않는다). 근거 문장이 원문에 그대로 있어야
/// 하고, 사람이 승인해야 확정이다 — AI 관계([OntologyRelation])와 같은 규칙이다.
abstract class DocumentFact
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['asOf']),
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
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['reviewedAt'],
            ),
      reviewedBy: jsonSerialization['reviewedBy'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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

  /// Returns a shallow copy of this [DocumentFact]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
  @_isc.useResult
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
