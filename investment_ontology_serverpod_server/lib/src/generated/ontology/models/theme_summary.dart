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

import '../../ontology/models/investment_theme.dart' as _iyyq5gsr;

/// 테마 목록 한 줄.
abstract class ThemeSummary
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ThemeSummary._({
    required this.theme,
    required this.memberCount,
    this.marketCap,
    required this.topNames,
  });

  factory ThemeSummary({
    required _iyyq5gsr.InvestmentTheme theme,
    required int memberCount,
    BigInt? marketCap,
    required List<String> topNames,
  }) = _ThemeSummaryImpl;

  factory ThemeSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemeSummary(
      theme: _i4yshtjp.Protocol().deserialize<_iyyq5gsr.InvestmentTheme>(
        jsonSerialization['theme'],
      ),
      memberCount: jsonSerialization['memberCount'] as int,
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
      topNames: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['topNames'],
      ),
    );
  }

  _iyyq5gsr.InvestmentTheme theme;

  int memberCount;

  /// 편입 기업 시가총액 합 (가장 최근 기준일). 시세가 없으면 null
  BigInt? marketCap;

  /// 시가총액이 큰 기업 이름 몇 개
  List<String> topNames;

  /// Returns a shallow copy of this [ThemeSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ThemeSummary copyWith({
    _iyyq5gsr.InvestmentTheme? theme,
    int? memberCount,
    BigInt? marketCap,
    List<String>? topNames,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeSummary',
      'theme': theme.toJson(),
      'memberCount': memberCount,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'topNames': topNames.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemeSummary',
      'theme': theme.toJsonForProtocol(),
      'memberCount': memberCount,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
      'topNames': topNames.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemeSummaryImpl extends ThemeSummary {
  _ThemeSummaryImpl({
    required _iyyq5gsr.InvestmentTheme theme,
    required int memberCount,
    BigInt? marketCap,
    required List<String> topNames,
  }) : super._(
         theme: theme,
         memberCount: memberCount,
         marketCap: marketCap,
         topNames: topNames,
       );

  /// Returns a shallow copy of this [ThemeSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ThemeSummary copyWith({
    _iyyq5gsr.InvestmentTheme? theme,
    int? memberCount,
    Object? marketCap = _Undefined,
    List<String>? topNames,
  }) {
    return ThemeSummary(
      theme: theme ?? this.theme.copyWith(),
      memberCount: memberCount ?? this.memberCount,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
      topNames: topNames ?? this.topNames.map((e0) => e0).toList(),
    );
  }
}
