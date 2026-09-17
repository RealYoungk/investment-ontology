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

abstract class MarketSnapshotFutureCallRunModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MarketSnapshotFutureCallRunModel._({required this.jobId});

  factory MarketSnapshotFutureCallRunModel({required int jobId}) =
      _MarketSnapshotFutureCallRunModelImpl;

  factory MarketSnapshotFutureCallRunModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MarketSnapshotFutureCallRunModel(
      jobId: jsonSerialization['jobId'] as int,
    );
  }

  int jobId;

  /// Returns a shallow copy of this [MarketSnapshotFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketSnapshotFutureCallRunModel copyWith({int? jobId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketSnapshotFutureCallRunModel',
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

class _MarketSnapshotFutureCallRunModelImpl
    extends MarketSnapshotFutureCallRunModel {
  _MarketSnapshotFutureCallRunModelImpl({required int jobId})
    : super._(jobId: jobId);

  /// Returns a shallow copy of this [MarketSnapshotFutureCallRunModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketSnapshotFutureCallRunModel copyWith({int? jobId}) {
    return MarketSnapshotFutureCallRunModel(jobId: jobId ?? this.jobId);
  }
}
