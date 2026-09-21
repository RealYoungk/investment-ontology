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
import 'package:investment_ontology_serverpod_client/src/protocol/protocol.dart'
    as _ilkzeueu;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/ontology_relation.dart' as _isp34kug;

/// 검수 큐의 관계 하나와 화면에 필요한 기업 정보.
abstract class ReviewItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ReviewItem._({
    required this.relation,
    required this.companyCorpCode,
    required this.companyName,
    this.subjectCorpCode,
    this.objectCorpCode,
  });

  factory ReviewItem({
    required _isp34kug.OntologyRelation relation,
    required String companyCorpCode,
    required String companyName,
    String? subjectCorpCode,
    String? objectCorpCode,
  }) = _ReviewItemImpl;

  factory ReviewItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewItem(
      relation: _ilkzeueu.Protocol().deserialize<_isp34kug.OntologyRelation>(
        jsonSerialization['relation'],
      ),
      companyCorpCode: jsonSerialization['companyCorpCode'] as String,
      companyName: jsonSerialization['companyName'] as String,
      subjectCorpCode: jsonSerialization['subjectCorpCode'] as String?,
      objectCorpCode: jsonSerialization['objectCorpCode'] as String?,
    );
  }

  _isp34kug.OntologyRelation relation;

  /// 원문(사업보고서)을 낸 기업
  String companyCorpCode;

  String companyName;

  String? subjectCorpCode;

  String? objectCorpCode;

  /// Returns a shallow copy of this [ReviewItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ReviewItem copyWith({
    _isp34kug.OntologyRelation? relation,
    String? companyCorpCode,
    String? companyName,
    String? subjectCorpCode,
    String? objectCorpCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewItem',
      'relation': relation.toJson(),
      'companyCorpCode': companyCorpCode,
      'companyName': companyName,
      if (subjectCorpCode != null) 'subjectCorpCode': subjectCorpCode,
      if (objectCorpCode != null) 'objectCorpCode': objectCorpCode,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewItem',
      'relation': relation.toJsonForProtocol(),
      'companyCorpCode': companyCorpCode,
      'companyName': companyName,
      if (subjectCorpCode != null) 'subjectCorpCode': subjectCorpCode,
      if (objectCorpCode != null) 'objectCorpCode': objectCorpCode,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReviewItemImpl extends ReviewItem {
  _ReviewItemImpl({
    required _isp34kug.OntologyRelation relation,
    required String companyCorpCode,
    required String companyName,
    String? subjectCorpCode,
    String? objectCorpCode,
  }) : super._(
         relation: relation,
         companyCorpCode: companyCorpCode,
         companyName: companyName,
         subjectCorpCode: subjectCorpCode,
         objectCorpCode: objectCorpCode,
       );

  /// Returns a shallow copy of this [ReviewItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ReviewItem copyWith({
    _isp34kug.OntologyRelation? relation,
    String? companyCorpCode,
    String? companyName,
    Object? subjectCorpCode = _Undefined,
    Object? objectCorpCode = _Undefined,
  }) {
    return ReviewItem(
      relation: relation ?? this.relation.copyWith(),
      companyCorpCode: companyCorpCode ?? this.companyCorpCode,
      companyName: companyName ?? this.companyName,
      subjectCorpCode: subjectCorpCode is String?
          ? subjectCorpCode
          : this.subjectCorpCode,
      objectCorpCode: objectCorpCode is String?
          ? objectCorpCode
          : this.objectCorpCode,
    );
  }
}
