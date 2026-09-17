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

abstract class CompanyMasterFutureCallRunModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CompanyMasterFutureCallRunModel._({
    required this.jobId,
    required this.force,
  });

  factory CompanyMasterFutureCallRunModel({
    required int jobId,
    required bool force,
  }) = _CompanyMasterFutureCallRunModelImpl;

  factory CompanyMasterFutureCallRunModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CompanyMasterFutureCallRunModel(
      jobId: jsonSerialization['jobId'] as int,
      force: _is.BoolJsonExtension.fromJson(jsonSerialization['force']),
    );
  }

  int jobId;

  bool force;

  /// Returns a shallow copy of this [CompanyMasterFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyMasterFutureCallRunModel copyWith({
    int? jobId,
    bool? force,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyMasterFutureCallRunModel',
      'jobId': jobId,
      'force': force,
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

class _CompanyMasterFutureCallRunModelImpl
    extends CompanyMasterFutureCallRunModel {
  _CompanyMasterFutureCallRunModelImpl({
    required int jobId,
    required bool force,
  }) : super._(
         jobId: jobId,
         force: force,
       );

  /// Returns a shallow copy of this [CompanyMasterFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyMasterFutureCallRunModel copyWith({
    int? jobId,
    bool? force,
  }) {
    return CompanyMasterFutureCallRunModel(
      jobId: jobId ?? this.jobId,
      force: force ?? this.force,
    );
  }
}
