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

abstract class FinancialFactsFutureCallRunModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FinancialFactsFutureCallRunModel._({required this.jobId});

  factory FinancialFactsFutureCallRunModel({required int jobId}) =
      _FinancialFactsFutureCallRunModelImpl;

  factory FinancialFactsFutureCallRunModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return FinancialFactsFutureCallRunModel(
      jobId: jsonSerialization['jobId'] as int,
    );
  }

  int jobId;

  /// Returns a shallow copy of this [FinancialFactsFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FinancialFactsFutureCallRunModel copyWith({int? jobId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialFactsFutureCallRunModel',
      'jobId': jobId,
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

class _FinancialFactsFutureCallRunModelImpl
    extends FinancialFactsFutureCallRunModel {
  _FinancialFactsFutureCallRunModelImpl({required int jobId})
    : super._(jobId: jobId);

  /// Returns a shallow copy of this [FinancialFactsFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FinancialFactsFutureCallRunModel copyWith({int? jobId}) {
    return FinancialFactsFutureCallRunModel(jobId: jobId ?? this.jobId);
  }
}
