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

/// 기업 묶음의 한 기업.
abstract class GroupMember
    implements _is.SerializableModel, _is.ProtocolSerialization {
  GroupMember._({
    required this.company,
    this.marketCap,
  });

  factory GroupMember({
    required _id7z5ov5.CompanyRef company,
    BigInt? marketCap,
  }) = _GroupMemberImpl;

  factory GroupMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return GroupMember(
      company: _i4yshtjp.Protocol().deserialize<_id7z5ov5.CompanyRef>(
        jsonSerialization['company'],
      ),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
    );
  }

  _id7z5ov5.CompanyRef company;

  BigInt? marketCap;

  /// Returns a shallow copy of this [GroupMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  GroupMember copyWith({
    _id7z5ov5.CompanyRef? company,
    BigInt? marketCap,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GroupMember',
      'company': company.toJson(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GroupMember',
      'company': company.toJsonForProtocol(),
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GroupMemberImpl extends GroupMember {
  _GroupMemberImpl({
    required _id7z5ov5.CompanyRef company,
    BigInt? marketCap,
  }) : super._(
         company: company,
         marketCap: marketCap,
       );

  /// Returns a shallow copy of this [GroupMember]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  GroupMember copyWith({
    _id7z5ov5.CompanyRef? company,
    Object? marketCap = _Undefined,
  }) {
    return GroupMember(
      company: company ?? this.company.copyWith(),
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
    );
  }
}
