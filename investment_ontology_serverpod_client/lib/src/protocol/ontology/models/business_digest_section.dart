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
import '../../ontology/models/business_digest_kind.dart' as _ir8vruw8;

/// 사업보고서 "사업의 내용"을 절마다 읽기 좋게 녹인 글. 원문을 통째로 보여 주는 대신 이것을 보여 준다.
///
/// AI가 화면 요청 중에 쓰는 것이 아니라 서버 밖에서 미리 읽어 넣는다 (ai.submitDigest).
/// 근거 인용(evidence)은 원문에 글자 그대로 있어야 저장된다 — 관계·값과 같은 규칙.
abstract class BusinessDigestSection
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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

  /// Returns a shallow copy of this [BusinessDigestSection]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
  @_isc.useResult
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
