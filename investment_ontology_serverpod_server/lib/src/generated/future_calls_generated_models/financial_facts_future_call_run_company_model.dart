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

abstract class FinancialFactsFutureCallRunCompanyModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FinancialFactsFutureCallRunCompanyModel._({
    required this.jobId,
    required this.corpCode,
  });

  factory FinancialFactsFutureCallRunCompanyModel({
    required int jobId,
    required String corpCode,
  }) = _FinancialFactsFutureCallRunCompanyModelImpl;

  factory FinancialFactsFutureCallRunCompanyModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return FinancialFactsFutureCallRunCompanyModel(
      jobId: jsonSerialization['jobId'] as int,
      corpCode: jsonSerialization['corpCode'] as String,
    );
  }

  int jobId;

  String corpCode;

  /// Returns a shallow copy of this [FinancialFactsFutureCallRunCompanyModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FinancialFactsFutureCallRunCompanyModel copyWith({
    int? jobId,
    String? corpCode,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialFactsFutureCallRunCompanyModel',
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

class _FinancialFactsFutureCallRunCompanyModelImpl
    extends FinancialFactsFutureCallRunCompanyModel {
  _FinancialFactsFutureCallRunCompanyModelImpl({
    required int jobId,
    required String corpCode,
  }) : super._(
         jobId: jobId,
         corpCode: corpCode,
       );

  /// Returns a shallow copy of this [FinancialFactsFutureCallRunCompanyModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FinancialFactsFutureCallRunCompanyModel copyWith({
    int? jobId,
    String? corpCode,
  }) {
    return FinancialFactsFutureCallRunCompanyModel(
      jobId: jobId ?? this.jobId,
      corpCode: corpCode ?? this.corpCode,
    );
  }
}
