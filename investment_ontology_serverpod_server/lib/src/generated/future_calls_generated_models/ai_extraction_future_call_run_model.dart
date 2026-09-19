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

abstract class AiExtractionFutureCallRunModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  AiExtractionFutureCallRunModel._({
    required this.jobId,
    required this.limit,
  });

  factory AiExtractionFutureCallRunModel({
    required int jobId,
    required int limit,
  }) = _AiExtractionFutureCallRunModelImpl;

  factory AiExtractionFutureCallRunModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return AiExtractionFutureCallRunModel(
      jobId: jsonSerialization['jobId'] as int,
      limit: jsonSerialization['limit'] as int,
    );
  }

  int jobId;

  int limit;

  /// Returns a shallow copy of this [AiExtractionFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AiExtractionFutureCallRunModel copyWith({
    int? jobId,
    int? limit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiExtractionFutureCallRunModel',
      'jobId': jobId,
      'limit': limit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _AiExtractionFutureCallRunModelImpl
    extends AiExtractionFutureCallRunModel {
  _AiExtractionFutureCallRunModelImpl({
    required int jobId,
    required int limit,
  }) : super._(
         jobId: jobId,
         limit: limit,
       );

  /// Returns a shallow copy of this [AiExtractionFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AiExtractionFutureCallRunModel copyWith({
    int? jobId,
    int? limit,
  }) {
    return AiExtractionFutureCallRunModel(
      jobId: jobId ?? this.jobId,
      limit: limit ?? this.limit,
    );
  }
}
