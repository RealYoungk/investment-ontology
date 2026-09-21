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
import '../../ontology/models/screen_row.dart' as _ibpsq3i8;

/// 스크리닝 결과.
abstract class ScreenPage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ScreenPage._({
    required this.items,
    required this.total,
    this.baseDate,
    required this.universe,
  });

  factory ScreenPage({
    required List<_ibpsq3i8.ScreenRow> items,
    required int total,
    DateTime? baseDate,
    required int universe,
  }) = _ScreenPageImpl;

  factory ScreenPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScreenPage(
      items: _i4yshtjp.Protocol().deserialize<List<_ibpsq3i8.ScreenRow>>(
        jsonSerialization['items'],
      ),
      total: jsonSerialization['total'] as int,
      baseDate: jsonSerialization['baseDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['baseDate']),
      universe: jsonSerialization['universe'] as int,
    );
  }

  List<_ibpsq3i8.ScreenRow> items;

  int total;

  /// 시세 기준일
  DateTime? baseDate;

  /// 지표를 계산할 재무가 있는 상장사 수 (거르기 전)
  int universe;

  /// Returns a shallow copy of this [ScreenPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScreenPage copyWith({
    List<_ibpsq3i8.ScreenRow>? items,
    int? total,
    DateTime? baseDate,
    int? universe,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScreenPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'total': total,
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
      'universe': universe,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ScreenPage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'total': total,
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
      'universe': universe,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScreenPageImpl extends ScreenPage {
  _ScreenPageImpl({
    required List<_ibpsq3i8.ScreenRow> items,
    required int total,
    DateTime? baseDate,
    required int universe,
  }) : super._(
         items: items,
         total: total,
         baseDate: baseDate,
         universe: universe,
       );

  /// Returns a shallow copy of this [ScreenPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScreenPage copyWith({
    List<_ibpsq3i8.ScreenRow>? items,
    int? total,
    Object? baseDate = _Undefined,
    int? universe,
  }) {
    return ScreenPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      total: total ?? this.total,
      baseDate: baseDate is DateTime? ? baseDate : this.baseDate,
      universe: universe ?? this.universe,
    );
  }
}
