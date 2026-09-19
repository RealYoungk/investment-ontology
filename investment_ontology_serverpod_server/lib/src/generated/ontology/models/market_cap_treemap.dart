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
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 업종별 시가총액 트리맵.
abstract class MarketCapTreemap
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MarketCapTreemap._({
    this.baseDate,
    this.source,
    this.sectionCode,
    this.sectionName,
    this.market,
    required this.total,
    required this.nodes,
    required this.unlinkedSecurityCount,
    required this.unlinkedMarketCap,
    required this.industryRevision,
  });

  factory MarketCapTreemap({
    DateTime? baseDate,
    _i5ra8lvy.Source? source,
    String? sectionCode,
    String? sectionName,
    _igwiku5p.Market? market,
    required BigInt total,
    required List<_iipimotn.MarketCapNode> nodes,
    required int unlinkedSecurityCount,
    required BigInt unlinkedMarketCap,
    required String industryRevision,
  }) = _MarketCapTreemapImpl;

  factory MarketCapTreemap.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketCapTreemap(
      baseDate: jsonSerialization['baseDate'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['baseDate']),
      source: jsonSerialization['source'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
      sectionCode: jsonSerialization['sectionCode'] as String?,
      sectionName: jsonSerialization['sectionName'] as String?,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
      total: _is.BigIntJsonExtension.fromJson(jsonSerialization['total']),
      nodes: _i4yshtjp.Protocol().deserialize<List<_iipimotn.MarketCapNode>>(
        jsonSerialization['nodes'],
      ),
      unlinkedSecurityCount: jsonSerialization['unlinkedSecurityCount'] as int,
      unlinkedMarketCap: _is.BigIntJsonExtension.fromJson(
        jsonSerialization['unlinkedMarketCap'],
      ),
      industryRevision: jsonSerialization['industryRevision'] as String,
    );
  }

  /// 시세 기준일. 시세가 없으면 null
  DateTime? baseDate;

  _i5ra8lvy.Source? source;

  /// 지정하면 이 대분류 안의 중분류 → 기업, 아니면 대분류 → 중분류
  String? sectionCode;

  String? sectionName;

  _igwiku5p.Market? market;

  BigInt total;

  List<_iipimotn.MarketCapNode> nodes;

  /// 기업(상장사 원장)에 연결되지 않아 합계에서 뺀 종목
  int unlinkedSecurityCount;

  BigInt unlinkedMarketCap;

  /// 업종명에 쓴 KSIC 차수
  String industryRevision;

  /// Returns a shallow copy of this [MarketCapTreemap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MarketCapTreemap copyWith({
    DateTime? baseDate,
    _i5ra8lvy.Source? source,
    String? sectionCode,
    String? sectionName,
    _igwiku5p.Market? market,
    BigInt? total,
    List<_iipimotn.MarketCapNode>? nodes,
    int? unlinkedSecurityCount,
    BigInt? unlinkedMarketCap,
    String? industryRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketCapTreemap',
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
      if (source != null) 'source': source?.toJson(),
      if (sectionCode != null) 'sectionCode': sectionCode,
      if (sectionName != null) 'sectionName': sectionName,
      if (market != null) 'market': market?.toJson(),
      'total': total.toJson(),
      'nodes': nodes.toJson(valueToJson: (v) => v.toJson()),
      'unlinkedSecurityCount': unlinkedSecurityCount,
      'unlinkedMarketCap': unlinkedMarketCap.toJson(),
      'industryRevision': industryRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketCapTreemap',
      if (baseDate != null) 'baseDate': baseDate?.toJson(),
      if (source != null) 'source': source?.toJsonForProtocol(),
      if (sectionCode != null) 'sectionCode': sectionCode,
      if (sectionName != null) 'sectionName': sectionName,
      if (market != null) 'market': market?.toJson(),
      'total': total.toJson(),
      'nodes': nodes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'unlinkedSecurityCount': unlinkedSecurityCount,
      'unlinkedMarketCap': unlinkedMarketCap.toJson(),
      'industryRevision': industryRevision,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketCapTreemapImpl extends MarketCapTreemap {
  _MarketCapTreemapImpl({
    DateTime? baseDate,
    _i5ra8lvy.Source? source,
    String? sectionCode,
    String? sectionName,
    _igwiku5p.Market? market,
    required BigInt total,
    required List<_iipimotn.MarketCapNode> nodes,
    required int unlinkedSecurityCount,
    required BigInt unlinkedMarketCap,
    required String industryRevision,
  }) : super._(
         baseDate: baseDate,
         source: source,
         sectionCode: sectionCode,
         sectionName: sectionName,
         market: market,
         total: total,
         nodes: nodes,
         unlinkedSecurityCount: unlinkedSecurityCount,
         unlinkedMarketCap: unlinkedMarketCap,
         industryRevision: industryRevision,
       );

  /// Returns a shallow copy of this [MarketCapTreemap]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MarketCapTreemap copyWith({
    Object? baseDate = _Undefined,
    Object? source = _Undefined,
    Object? sectionCode = _Undefined,
    Object? sectionName = _Undefined,
    Object? market = _Undefined,
    BigInt? total,
    List<_iipimotn.MarketCapNode>? nodes,
    int? unlinkedSecurityCount,
    BigInt? unlinkedMarketCap,
    String? industryRevision,
  }) {
    return MarketCapTreemap(
      baseDate: baseDate is DateTime? ? baseDate : this.baseDate,
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
      sectionCode: sectionCode is String? ? sectionCode : this.sectionCode,
      sectionName: sectionName is String? ? sectionName : this.sectionName,
      market: market is _igwiku5p.Market? ? market : this.market,
      total: total ?? this.total,
      nodes: nodes ?? this.nodes.map((e0) => e0.copyWith()).toList(),
      unlinkedSecurityCount:
          unlinkedSecurityCount ?? this.unlinkedSecurityCount,
      unlinkedMarketCap: unlinkedMarketCap ?? this.unlinkedMarketCap,
      industryRevision: industryRevision ?? this.industryRevision,
    );
  }
}
