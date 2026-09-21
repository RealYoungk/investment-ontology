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

/// 아직 읽지 않은 사업보고서 본문 한 건 (밖에서 미리 뽑을 때 고르는 용도).
abstract class BusinessDocumentRef
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BusinessDocumentRef._({
    required this.documentId,
    required this.corpCode,
    required this.companyName,
    required this.bsnsYear,
    required this.chars,
  });

  factory BusinessDocumentRef({
    required int documentId,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required int chars,
  }) = _BusinessDocumentRefImpl;

  factory BusinessDocumentRef.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessDocumentRef(
      documentId: jsonSerialization['documentId'] as int,
      corpCode: jsonSerialization['corpCode'] as String,
      companyName: jsonSerialization['companyName'] as String,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      chars: jsonSerialization['chars'] as int,
    );
  }

  int documentId;

  String corpCode;

  String companyName;

  int bsnsYear;

  /// 본문 글자 수
  int chars;

  /// Returns a shallow copy of this [BusinessDocumentRef]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BusinessDocumentRef copyWith({
    int? documentId,
    String? corpCode,
    String? companyName,
    int? bsnsYear,
    int? chars,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessDocumentRef',
      'documentId': documentId,
      'corpCode': corpCode,
      'companyName': companyName,
      'bsnsYear': bsnsYear,
      'chars': chars,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessDocumentRef',
      'documentId': documentId,
      'corpCode': corpCode,
      'companyName': companyName,
      'bsnsYear': bsnsYear,
      'chars': chars,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _BusinessDocumentRefImpl extends BusinessDocumentRef {
  _BusinessDocumentRefImpl({
    required int documentId,
    required String corpCode,
    required String companyName,
    required int bsnsYear,
    required int chars,
  }) : super._(
         documentId: documentId,
         corpCode: corpCode,
         companyName: companyName,
         bsnsYear: bsnsYear,
         chars: chars,
       );

  /// Returns a shallow copy of this [BusinessDocumentRef]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BusinessDocumentRef copyWith({
    int? documentId,
    String? corpCode,
    String? companyName,
    int? bsnsYear,
    int? chars,
  }) {
    return BusinessDocumentRef(
      documentId: documentId ?? this.documentId,
      corpCode: corpCode ?? this.corpCode,
      companyName: companyName ?? this.companyName,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      chars: chars ?? this.chars,
    );
  }
}
