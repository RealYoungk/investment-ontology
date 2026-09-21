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

/// AI 관계 추출 실행 기록: 사업보고서 본문 하나를 모델 하나로 읽은 결과.
abstract class AiExtraction
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AiExtraction._({
    this.id,
    required this.documentId,
    required this.companyId,
    required this.model,
    required this.succeeded,
    required this.relationCount,
    required this.droppedCount,
    this.error,
    required this.createdAt,
  });

  factory AiExtraction({
    int? id,
    required int documentId,
    required int companyId,
    required String model,
    required bool succeeded,
    required int relationCount,
    required int droppedCount,
    String? error,
    required DateTime createdAt,
  }) = _AiExtractionImpl;

  factory AiExtraction.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiExtraction(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      model: jsonSerialization['model'] as String,
      succeeded: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['succeeded'],
      ),
      relationCount: jsonSerialization['relationCount'] as int,
      droppedCount: jsonSerialization['droppedCount'] as int,
      error: jsonSerialization['error'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int documentId;

  int companyId;

  String model;

  bool succeeded;

  /// 저장한 관계 수 (draft)
  int relationCount;

  /// 근거 인용이 원문에 없거나 형식이 틀려 버린 수
  int droppedCount;

  String? error;

  DateTime createdAt;

  /// Returns a shallow copy of this [AiExtraction]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AiExtraction copyWith({
    int? id,
    int? documentId,
    int? companyId,
    String? model,
    bool? succeeded,
    int? relationCount,
    int? droppedCount,
    String? error,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiExtraction',
      if (id != null) 'id': id,
      'documentId': documentId,
      'companyId': companyId,
      'model': model,
      'succeeded': succeeded,
      'relationCount': relationCount,
      'droppedCount': droppedCount,
      if (error != null) 'error': error,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiExtraction',
      if (id != null) 'id': id,
      'documentId': documentId,
      'companyId': companyId,
      'model': model,
      'succeeded': succeeded,
      'relationCount': relationCount,
      'droppedCount': droppedCount,
      if (error != null) 'error': error,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiExtractionImpl extends AiExtraction {
  _AiExtractionImpl({
    int? id,
    required int documentId,
    required int companyId,
    required String model,
    required bool succeeded,
    required int relationCount,
    required int droppedCount,
    String? error,
    required DateTime createdAt,
  }) : super._(
         id: id,
         documentId: documentId,
         companyId: companyId,
         model: model,
         succeeded: succeeded,
         relationCount: relationCount,
         droppedCount: droppedCount,
         error: error,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [AiExtraction]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AiExtraction copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? companyId,
    String? model,
    bool? succeeded,
    int? relationCount,
    int? droppedCount,
    Object? error = _Undefined,
    DateTime? createdAt,
  }) {
    return AiExtraction(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      companyId: companyId ?? this.companyId,
      model: model ?? this.model,
      succeeded: succeeded ?? this.succeeded,
      relationCount: relationCount ?? this.relationCount,
      droppedCount: droppedCount ?? this.droppedCount,
      error: error is String? ? error : this.error,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
