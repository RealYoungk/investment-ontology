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
import '../../ontology/models/group_edge.dart' as _iezrztoe;
import '../../ontology/models/group_member.dart' as _ihu5nxx9;
import '../../ontology/models/group_person.dart' as _idccp4ei;

/// 지분으로 이어진 상장사 묶음. 최대주주 명단의 법인 주주와 경영참여 목적 15% 이상 출자로 잇는다
/// (각 기업의 가장 최근 사업보고서 기준). 공정위 기업집단 지정과는 다른, 공시에서 계산한 묶음이다.
abstract class CompanyGroup
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CompanyGroup._({
    required this.anchor,
    required this.members,
    required this.edges,
    this.totalMarketCap,
    this.baseDate,
    required this.sharedPersons,
  });

  factory CompanyGroup({
    required _id7z5ov5.CompanyRef anchor,
    required List<_ihu5nxx9.GroupMember> members,
    required List<_iezrztoe.GroupEdge> edges,
    BigInt? totalMarketCap,
    DateTime? baseDate,
    required List<_idccp4ei.GroupPerson> sharedPersons,
  }) = _CompanyGroupImpl;

  factory CompanyGroup.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyGroup(
      anchor: _i4yshtjp.Protocol().deserialize<_id7z5ov5.CompanyRef>(
        jsonSerialization['anchor'],
      ),
      members: _i4yshtjp.Protocol().deserialize<List<_ihu5nxx9.GroupMember>>(
        jsonSerialization['members'],
      ),
      edges: _i4yshtjp.Protocol().deserialize<List<_iezrztoe.GroupEdge>>(
        jsonSerialization['edges'],
      ),
      totalMarketCap: jsonSerialization['totalMarketCap'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['totalMarketCap'],
            ),
      baseDate: jsonSerialization['baseDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['baseDate']),
      sharedPersons: _i4yshtjp.Protocol()
          .deserialize<List<_idccp4ei.GroupPerson>>(
            jsonSerialization['sharedPersons'],
          ),
    );
  }

  /// 시가총액이 가장 큰 기업 (묶음 이름)
  _id7z5ov5.CompanyRef anchor;

  List<_ihu5nxx9.GroupMember> members;

  List<_iezrztoe.GroupEdge> edges;

  BigInt? totalMarketCap;

  DateTime? baseDate;

  /// 묶음 안 두 곳 이상의 최대주주 명단에 나오는 인물
  List<_idccp4ei.GroupPerson> sharedPersons;

  /// Returns a shallow copy of this [CompanyGroup]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyGroup copyWith({
    _id7z5ov5.CompanyRef? anchor,
    List<_ihu5nxx9.GroupMember>? members,
    List<_iezrztoe.GroupEdge>? edges,
    BigInt? totalMarketCap,
    DateTime? baseDate,
    List<_idccp4ei.GroupPerson>? sharedPersons,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyGroup',
      'anchor': anchor.toJson(),
      'members': members.toJson(valueToJson: (v) => v.toJson()),
      'edges': edges.toJson(valueToJson: (v) => v.toJson()),
      if (totalMarketCap != null) 'totalMarketCap': totalMarketCap?.toJson(),
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
      'sharedPersons': sharedPersons.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyGroup',
      'anchor': anchor.toJsonForProtocol(),
      'members': members.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'edges': edges.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (totalMarketCap != null) 'totalMarketCap': totalMarketCap?.toJson(),
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
      'sharedPersons': sharedPersons.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyGroupImpl extends CompanyGroup {
  _CompanyGroupImpl({
    required _id7z5ov5.CompanyRef anchor,
    required List<_ihu5nxx9.GroupMember> members,
    required List<_iezrztoe.GroupEdge> edges,
    BigInt? totalMarketCap,
    DateTime? baseDate,
    required List<_idccp4ei.GroupPerson> sharedPersons,
  }) : super._(
         anchor: anchor,
         members: members,
         edges: edges,
         totalMarketCap: totalMarketCap,
         baseDate: baseDate,
         sharedPersons: sharedPersons,
       );

  /// Returns a shallow copy of this [CompanyGroup]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyGroup copyWith({
    _id7z5ov5.CompanyRef? anchor,
    List<_ihu5nxx9.GroupMember>? members,
    List<_iezrztoe.GroupEdge>? edges,
    Object? totalMarketCap = _Undefined,
    Object? baseDate = _Undefined,
    List<_idccp4ei.GroupPerson>? sharedPersons,
  }) {
    return CompanyGroup(
      anchor: anchor ?? this.anchor.copyWith(),
      members: members ?? this.members.map((e0) => e0.copyWith()).toList(),
      edges: edges ?? this.edges.map((e0) => e0.copyWith()).toList(),
      totalMarketCap: totalMarketCap is BigInt?
          ? totalMarketCap
          : this.totalMarketCap,
      baseDate: baseDate is DateTime? ? baseDate : this.baseDate,
      sharedPersons:
          sharedPersons ??
          this.sharedPersons.map((e0) => e0.copyWith()).toList(),
    );
  }
}
