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
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart'
    as _i4yshtjp;
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/business_table_measure.dart' as _if9wz8zy;
import '../../ontology/models/business_table_record.dart' as _il2pp0a4;

/// 저장된 정기보고서의 명시적 표 헤더로 구조화한 정보. 숫자를 추론하거나 단위를 변환하지 않는다.
abstract class BusinessTableInsight
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BusinessTableInsight._({
    required this.topic,
    required this.title,
    required this.columns,
    required this.rows,
    required this.measures,
    required this.evidence,
    required this.validation,
    this.scope,
  });

  factory BusinessTableInsight({
    required String topic,
    required String title,
    required List<String> columns,
    required List<_il2pp0a4.BusinessTableRecord> rows,
    required List<_if9wz8zy.BusinessTableMeasure> measures,
    required String evidence,
    required String validation,
    String? scope,
  }) = _BusinessTableInsightImpl;

  factory BusinessTableInsight.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BusinessTableInsight(
      topic: jsonSerialization['topic'] as String,
      title: jsonSerialization['title'] as String,
      columns: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['columns'],
      ),
      rows: _i4yshtjp.Protocol()
          .deserialize<List<_il2pp0a4.BusinessTableRecord>>(
            jsonSerialization['rows'],
          ),
      measures: _i4yshtjp.Protocol()
          .deserialize<List<_if9wz8zy.BusinessTableMeasure>>(
            jsonSerialization['measures'],
          ),
      evidence: jsonSerialization['evidence'] as String,
      validation: jsonSerialization['validation'] as String,
      scope: jsonSerialization['scope'] as String?,
    );
  }

  String topic;

  String title;

  List<String> columns;

  List<_il2pp0a4.BusinessTableRecord> rows;

  List<_if9wz8zy.BusinessTableMeasure> measures;

  String evidence;

  String validation;

  String? scope;

  /// Returns a shallow copy of this [BusinessTableInsight]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessTableInsight copyWith({
    String? topic,
    String? title,
    List<String>? columns,
    List<_il2pp0a4.BusinessTableRecord>? rows,
    List<_if9wz8zy.BusinessTableMeasure>? measures,
    String? evidence,
    String? validation,
    String? scope,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessTableInsight',
      'topic': topic,
      'title': title,
      'columns': columns.toJson(),
      'rows': rows.toJson(valueToJson: (v) => v.toJson()),
      'measures': measures.toJson(valueToJson: (v) => v.toJson()),
      'evidence': evidence,
      'validation': validation,
      if (scope != null) 'scope': scope,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessTableInsight',
      'topic': topic,
      'title': title,
      'columns': columns.toJson(),
      'rows': rows.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'measures': measures.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'evidence': evidence,
      'validation': validation,
      if (scope != null) 'scope': scope,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessTableInsightImpl extends BusinessTableInsight {
  _BusinessTableInsightImpl({
    required String topic,
    required String title,
    required List<String> columns,
    required List<_il2pp0a4.BusinessTableRecord> rows,
    required List<_if9wz8zy.BusinessTableMeasure> measures,
    required String evidence,
    required String validation,
    String? scope,
  }) : super._(
         topic: topic,
         title: title,
         columns: columns,
         rows: rows,
         measures: measures,
         evidence: evidence,
         validation: validation,
         scope: scope,
       );

  /// Returns a shallow copy of this [BusinessTableInsight]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessTableInsight copyWith({
    String? topic,
    String? title,
    List<String>? columns,
    List<_il2pp0a4.BusinessTableRecord>? rows,
    List<_if9wz8zy.BusinessTableMeasure>? measures,
    String? evidence,
    String? validation,
    Object? scope = _Undefined,
  }) {
    return BusinessTableInsight(
      topic: topic ?? this.topic,
      title: title ?? this.title,
      columns: columns ?? this.columns.map((e0) => e0).toList(),
      rows: rows ?? this.rows.map((e0) => e0.copyWith()).toList(),
      measures: measures ?? this.measures.map((e0) => e0.copyWith()).toList(),
      evidence: evidence ?? this.evidence,
      validation: validation ?? this.validation,
      scope: scope is String? ? scope : this.scope,
    );
  }
}
