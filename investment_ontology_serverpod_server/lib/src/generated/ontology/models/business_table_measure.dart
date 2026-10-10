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

abstract class BusinessTableMeasure
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BusinessTableMeasure._({
    required this.label,
    required this.metric,
    required this.period,
    required this.value,
    required this.unit,
  });

  factory BusinessTableMeasure({
    required String label,
    required String metric,
    required String period,
    required double value,
    required String unit,
  }) = _BusinessTableMeasureImpl;

  factory BusinessTableMeasure.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BusinessTableMeasure(
      label: jsonSerialization['label'] as String,
      metric: jsonSerialization['metric'] as String,
      period: jsonSerialization['period'] as String,
      value: (jsonSerialization['value'] as num).toDouble(),
      unit: jsonSerialization['unit'] as String,
    );
  }

  String label;

  String metric;

  String period;

  double value;

  String unit;

  /// Returns a shallow copy of this [BusinessTableMeasure]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessTableMeasure copyWith({
    String? label,
    String? metric,
    String? period,
    double? value,
    String? unit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessTableMeasure',
      'label': label,
      'metric': metric,
      'period': period,
      'value': value,
      'unit': unit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessTableMeasure',
      'label': label,
      'metric': metric,
      'period': period,
      'value': value,
      'unit': unit,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _BusinessTableMeasureImpl extends BusinessTableMeasure {
  _BusinessTableMeasureImpl({
    required String label,
    required String metric,
    required String period,
    required double value,
    required String unit,
  }) : super._(
         label: label,
         metric: metric,
         period: period,
         value: value,
         unit: unit,
       );

  /// Returns a shallow copy of this [BusinessTableMeasure]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessTableMeasure copyWith({
    String? label,
    String? metric,
    String? period,
    double? value,
    String? unit,
  }) {
    return BusinessTableMeasure(
      label: label ?? this.label,
      metric: metric ?? this.metric,
      period: period ?? this.period,
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }
}
