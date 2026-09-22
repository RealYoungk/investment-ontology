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

/// 지수 추이의 한 점.
abstract class IndexPoint
    implements _is.SerializableModel, _is.ProtocolSerialization {
  IndexPoint._({
    required this.date,
    required this.value,
  });

  factory IndexPoint({
    required DateTime date,
    required double value,
  }) = _IndexPointImpl;

  factory IndexPoint.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndexPoint(
      date: _is.DateTimeJsonExtension.fromJson(jsonSerialization['date']),
      value: (jsonSerialization['value'] as num).toDouble(),
    );
  }

  DateTime date;

  /// 종가 (지수 값, 원문 소수 그대로)
  double value;

  /// Returns a shallow copy of this [IndexPoint]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  IndexPoint copyWith({
    DateTime? date,
    double? value,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndexPoint',
      'date': date.toJson(),
      'value': value,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndexPoint',
      'date': date.toJson(),
      'value': value,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _IndexPointImpl extends IndexPoint {
  _IndexPointImpl({
    required DateTime date,
    required double value,
  }) : super._(
         date: date,
         value: value,
       );

  /// Returns a shallow copy of this [IndexPoint]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  IndexPoint copyWith({
    DateTime? date,
    double? value,
  }) {
    return IndexPoint(
      date: date ?? this.date,
      value: value ?? this.value,
    );
  }
}
