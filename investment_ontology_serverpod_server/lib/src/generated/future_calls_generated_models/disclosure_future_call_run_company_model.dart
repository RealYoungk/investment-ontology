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

abstract class DisclosureFutureCallRunCompanyModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DisclosureFutureCallRunCompanyModel._({
    required this.jobId,
    required this.corpCode,
  });

  factory DisclosureFutureCallRunCompanyModel({
    required int jobId,
    required String corpCode,
  }) = _DisclosureFutureCallRunCompanyModelImpl;

  factory DisclosureFutureCallRunCompanyModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DisclosureFutureCallRunCompanyModel(
      jobId: jsonSerialization['jobId'] as int,
      corpCode: jsonSerialization['corpCode'] as String,
    );
  }

  int jobId;

  String corpCode;

  /// Returns a shallow copy of this [DisclosureFutureCallRunCompanyModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DisclosureFutureCallRunCompanyModel copyWith({
    int? jobId,
    String? corpCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureFutureCallRunCompanyModel',
      'jobId': jobId,
      'corpCode': corpCode,
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

class _DisclosureFutureCallRunCompanyModelImpl
    extends DisclosureFutureCallRunCompanyModel {
  _DisclosureFutureCallRunCompanyModelImpl({
    required int jobId,
    required String corpCode,
  }) : super._(
         jobId: jobId,
         corpCode: corpCode,
       );

  /// Returns a shallow copy of this [DisclosureFutureCallRunCompanyModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DisclosureFutureCallRunCompanyModel copyWith({
    int? jobId,
    String? corpCode,
  }) {
    return DisclosureFutureCallRunCompanyModel(
      jobId: jobId ?? this.jobId,
      corpCode: corpCode ?? this.corpCode,
    );
  }
}
