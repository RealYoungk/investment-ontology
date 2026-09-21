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

import '../../ontology/models/market.dart' as _igwiku5p;
import '../../ontology/models/market_cap_node.dart' as _iipimotn;

/// 시가총액 트리맵 노드: 업종(대·중분류) 또는 기업.
abstract class MarketCapNode
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MarketCapNode._({
    required this.code,
    required this.name,
    required this.marketCap,
    required this.companyCount,
    this.market,
    required this.children,
  });

  factory MarketCapNode({
    required String code,
    required String name,
    required BigInt marketCap,
    required int companyCount,
    _igwiku5p.Market? market,
    required List<_iipimotn.MarketCapNode> children,
  }) = _MarketCapNodeImpl;

  factory MarketCapNode.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketCapNode(
      code: jsonSerialization['code'] as String,
      name: jsonSerialization['name'] as String,
      marketCap: _is.BigIntJsonExtension.fromJson(
        jsonSerialization['marketCap'],
      ),
      companyCount: jsonSerialization['companyCount'] as int,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
      children: _i4yshtjp.Protocol().deserialize<List<_iipimotn.MarketCapNode>>(
        jsonSerialization['children'],
      ),
    );
  }

  /// KSIC 코드 또는 기업 corpCode
  String code;

  String name;

  BigInt marketCap;

  int companyCount;

  /// 기업 노드의 시장
  _igwiku5p.Market? market;

  List<_iipimotn.MarketCapNode> children;

  /// Returns a shallow copy of this [MarketCapNode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketCapNode copyWith({
    String? code,
    String? name,
    BigInt? marketCap,
    int? companyCount,
    _igwiku5p.Market? market,
    List<_iipimotn.MarketCapNode>? children,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketCapNode',
      'code': code,
      'name': name,
      'marketCap': marketCap.toJson(),
      'companyCount': companyCount,
      if (market != null) 'market': market?.toJson(),
      'children': children.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketCapNode',
      'code': code,
      'name': name,
      'marketCap': marketCap.toJson(),
      'companyCount': companyCount,
      if (market != null) 'market': market?.toJson(),
      'children': children.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketCapNodeImpl extends MarketCapNode {
  _MarketCapNodeImpl({
    required String code,
    required String name,
    required BigInt marketCap,
    required int companyCount,
    _igwiku5p.Market? market,
    required List<_iipimotn.MarketCapNode> children,
  }) : super._(
         code: code,
         name: name,
         marketCap: marketCap,
         companyCount: companyCount,
         market: market,
         children: children,
       );

  /// Returns a shallow copy of this [MarketCapNode]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketCapNode copyWith({
    String? code,
    String? name,
    BigInt? marketCap,
    int? companyCount,
    Object? market = _Undefined,
    List<_iipimotn.MarketCapNode>? children,
  }) {
    return MarketCapNode(
      code: code ?? this.code,
      name: name ?? this.name,
      marketCap: marketCap ?? this.marketCap,
      companyCount: companyCount ?? this.companyCount,
      market: market is _igwiku5p.Market? ? market : this.market,
      children: children ?? this.children.map((e0) => e0.copyWith()).toList(),
    );
  }
}
