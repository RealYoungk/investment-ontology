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

/// AI 관계 추출 준비 상태.
abstract class AiStatus
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AiStatus._({
    required this.keyConfigured,
    required this.model,
    required this.documentCompanies,
    required this.extractedCompanies,
    required this.draftCount,
    required this.verifiedCount,
    required this.rejectedCount,
  });

  factory AiStatus({
    required bool keyConfigured,
    required String model,
    required int documentCompanies,
    required int extractedCompanies,
    required int draftCount,
    required int verifiedCount,
    required int rejectedCount,
  }) = _AiStatusImpl;

  factory AiStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiStatus(
      keyConfigured: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['keyConfigured'],
      ),
      model: jsonSerialization['model'] as String,
      documentCompanies: jsonSerialization['documentCompanies'] as int,
      extractedCompanies: jsonSerialization['extractedCompanies'] as int,
      draftCount: jsonSerialization['draftCount'] as int,
      verifiedCount: jsonSerialization['verifiedCount'] as int,
      rejectedCount: jsonSerialization['rejectedCount'] as int,
    );
  }

  bool keyConfigured;

  String model;

  /// 사업의 내용을 받은 기업 수 (가장 최근 보고서 기준)
  int documentCompanies;

  /// 그중 추출한 기업 수
  int extractedCompanies;

  int draftCount;

  int verifiedCount;

  int rejectedCount;

  /// Returns a shallow copy of this [AiStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AiStatus copyWith({
    bool? keyConfigured,
    String? model,
    int? documentCompanies,
    int? extractedCompanies,
    int? draftCount,
    int? verifiedCount,
    int? rejectedCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiStatus',
      'keyConfigured': keyConfigured,
      'model': model,
      'documentCompanies': documentCompanies,
      'extractedCompanies': extractedCompanies,
      'draftCount': draftCount,
      'verifiedCount': verifiedCount,
      'rejectedCount': rejectedCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiStatus',
      'keyConfigured': keyConfigured,
      'model': model,
      'documentCompanies': documentCompanies,
      'extractedCompanies': extractedCompanies,
      'draftCount': draftCount,
      'verifiedCount': verifiedCount,
      'rejectedCount': rejectedCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AiStatusImpl extends AiStatus {
  _AiStatusImpl({
    required bool keyConfigured,
    required String model,
    required int documentCompanies,
    required int extractedCompanies,
    required int draftCount,
    required int verifiedCount,
    required int rejectedCount,
  }) : super._(
         keyConfigured: keyConfigured,
         model: model,
         documentCompanies: documentCompanies,
         extractedCompanies: extractedCompanies,
         draftCount: draftCount,
         verifiedCount: verifiedCount,
         rejectedCount: rejectedCount,
       );

  /// Returns a shallow copy of this [AiStatus]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AiStatus copyWith({
    bool? keyConfigured,
    String? model,
    int? documentCompanies,
    int? extractedCompanies,
    int? draftCount,
    int? verifiedCount,
    int? rejectedCount,
  }) {
    return AiStatus(
      keyConfigured: keyConfigured ?? this.keyConfigured,
      model: model ?? this.model,
      documentCompanies: documentCompanies ?? this.documentCompanies,
      extractedCompanies: extractedCompanies ?? this.extractedCompanies,
      draftCount: draftCount ?? this.draftCount,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
    );
  }
}
