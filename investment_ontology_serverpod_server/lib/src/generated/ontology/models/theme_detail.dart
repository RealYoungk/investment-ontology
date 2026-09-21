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
import '../../ontology/models/theme_member_view.dart' as _ie10ibqf;

/// 테마 상세: 편입 기업과 시가총액.
abstract class ThemeDetail
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ThemeDetail._({
    required this.theme,
    required this.members,
    this.baseDate,
  });

  factory ThemeDetail({
    required _iyyq5gsr.InvestmentTheme theme,
    required List<_ie10ibqf.ThemeMemberView> members,
    DateTime? baseDate,
  }) = _ThemeDetailImpl;

  factory ThemeDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemeDetail(
      theme: _i4yshtjp.Protocol().deserialize<_iyyq5gsr.InvestmentTheme>(
        jsonSerialization['theme'],
      ),
      members: _i4yshtjp.Protocol()
          .deserialize<List<_ie10ibqf.ThemeMemberView>>(
            jsonSerialization['members'],
          ),
      baseDate: jsonSerialization['baseDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['baseDate']),
    );
  }

  _iyyq5gsr.InvestmentTheme theme;

  List<_ie10ibqf.ThemeMemberView> members;

  /// 시가총액 기준일
  DateTime? baseDate;

  /// Returns a shallow copy of this [ThemeDetail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ThemeDetail copyWith({
    _iyyq5gsr.InvestmentTheme? theme,
    List<_ie10ibqf.ThemeMemberView>? members,
    DateTime? baseDate,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeDetail',
      'theme': theme.toJson(),
      'members': members.toJson(valueToJson: (v) => v.toJson()),
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemeDetail',
      'theme': theme.toJsonForProtocol(),
      'members': members.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemeDetailImpl extends ThemeDetail {
  _ThemeDetailImpl({
    required _iyyq5gsr.InvestmentTheme theme,
    required List<_ie10ibqf.ThemeMemberView> members,
    DateTime? baseDate,
  }) : super._(
         theme: theme,
         members: members,
         baseDate: baseDate,
       );

  /// Returns a shallow copy of this [ThemeDetail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ThemeDetail copyWith({
    _iyyq5gsr.InvestmentTheme? theme,
    List<_ie10ibqf.ThemeMemberView>? members,
    Object? baseDate = _Undefined,
  }) {
    return ThemeDetail(
      theme: theme ?? this.theme.copyWith(),
      members: members ?? this.members.map((e0) => e0.copyWith()).toList(),
      baseDate: baseDate is DateTime? ? baseDate : this.baseDate,
    );
  }
}
