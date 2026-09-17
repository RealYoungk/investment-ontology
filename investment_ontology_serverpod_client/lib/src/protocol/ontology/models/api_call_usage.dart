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
import '../../ontology/models/api_provider.dart' as _ihrpaigz;

/// 수집 장부: 제공자별·날짜별 API 호출 수.
/// 여러 수집 작업이 같은 일일 한도를 나눠 쓰므로 작업(IngestJob)과 따로 날짜 기준으로 합산한다.
abstract class ApiCallUsage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ApiCallUsage._({
    this.id,
    required this.provider,
    required this.day,
    int? calls,
  }) : calls = calls ?? 0;

  factory ApiCallUsage({
    int? id,
    required _ihrpaigz.ApiProvider provider,
    required String day,
    int? calls,
  }) = _ApiCallUsageImpl;

  factory ApiCallUsage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiCallUsage(
      id: jsonSerialization['id'] as int?,
      provider: _ihrpaigz.ApiProvider.fromJson(
        (jsonSerialization['provider'] as String),
      ),
      day: jsonSerialization['day'] as String,
      calls: jsonSerialization['calls'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _ihrpaigz.ApiProvider provider;

  /// 한도가 초기화되는 기준 날짜 (KST, YYYY-MM-DD)
  String day;

  int calls;

  /// Returns a shallow copy of this [ApiCallUsage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ApiCallUsage copyWith({
    int? id,
    _ihrpaigz.ApiProvider? provider,
    String? day,
    int? calls,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiCallUsage',
      if (id != null) 'id': id,
      'provider': provider.toJson(),
      'day': day,
      'calls': calls,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ApiCallUsage',
      if (id != null) 'id': id,
      'provider': provider.toJson(),
      'day': day,
      'calls': calls,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ApiCallUsageImpl extends ApiCallUsage {
  _ApiCallUsageImpl({
    int? id,
    required _ihrpaigz.ApiProvider provider,
    required String day,
    int? calls,
  }) : super._(
         id: id,
         provider: provider,
         day: day,
         calls: calls,
       );

  /// Returns a shallow copy of this [ApiCallUsage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ApiCallUsage copyWith({
    Object? id = _Undefined,
    _ihrpaigz.ApiProvider? provider,
    String? day,
    int? calls,
  }) {
    return ApiCallUsage(
      id: id is int? ? id : this.id,
      provider: provider ?? this.provider,
      day: day ?? this.day,
      calls: calls ?? this.calls,
    );
  }
}
