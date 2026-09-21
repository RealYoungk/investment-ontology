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
import '../../ontology/models/company_ref.dart' as _id7z5ov5;
import '../../ontology/models/theme_member.dart' as _i97a5amh;

/// 테마 상세의 편입 기업 한 줄.
abstract class ThemeMemberView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ThemeMemberView._({
    required this.member,
    required this.company,
    this.industryName,
    this.marketCap,
  });

  factory ThemeMemberView({
    required _i97a5amh.ThemeMember member,
    required _id7z5ov5.CompanyRef company,
    String? industryName,
    BigInt? marketCap,
  }) = _ThemeMemberViewImpl;

  factory ThemeMemberView.fromJson(Map<String, dynamic> jsonSerialization) {
    return ThemeMemberView(
      member: _i4yshtjp.Protocol().deserialize<_i97a5amh.ThemeMember>(
        jsonSerialization['member'],
      ),
      company: _i4yshtjp.Protocol().deserialize<_id7z5ov5.CompanyRef>(
        jsonSerialization['company'],
      ),
      industryName: jsonSerialization['industryName'] as String?,
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
    );
  }

  _i97a5amh.ThemeMember member;

  _id7z5ov5.CompanyRef company;

  /// KSIC 가장 세부 업종 이름
  String? industryName;

  BigInt? marketCap;

  /// Returns a shallow copy of this [ThemeMemberView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ThemeMemberView copyWith({
    _i97a5amh.ThemeMember? member,
    _id7z5ov5.CompanyRef? company,
    String? industryName,
    BigInt? marketCap,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThemeMemberView',
      'member': member.toJson(),
      'company': company.toJson(),
      if (industryName != null) 'industryName': industryName,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ThemeMemberView',
      'member': member.toJsonForProtocol(),
      'company': company.toJsonForProtocol(),
      if (industryName != null) 'industryName': industryName,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ThemeMemberViewImpl extends ThemeMemberView {
  _ThemeMemberViewImpl({
    required _i97a5amh.ThemeMember member,
    required _id7z5ov5.CompanyRef company,
    String? industryName,
    BigInt? marketCap,
  }) : super._(
         member: member,
         company: company,
         industryName: industryName,
         marketCap: marketCap,
       );

  /// Returns a shallow copy of this [ThemeMemberView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ThemeMemberView copyWith({
    _i97a5amh.ThemeMember? member,
    _id7z5ov5.CompanyRef? company,
    Object? industryName = _Undefined,
    Object? marketCap = _Undefined,
  }) {
    return ThemeMemberView(
      member: member ?? this.member.copyWith(),
      company: company ?? this.company.copyWith(),
      industryName: industryName is String? ? industryName : this.industryName,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
    );
  }
}
