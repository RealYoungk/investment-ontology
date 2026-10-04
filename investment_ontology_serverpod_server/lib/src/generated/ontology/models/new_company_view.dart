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
import '../../ontology/models/source.dart' as _i5ra8lvy;

abstract class NewCompanyView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  NewCompanyView._({
    required this.corpCode,
    required this.name,
    this.stockCode,
    this.market,
    required this.observedDate,
    required this.source,
  });

  factory NewCompanyView({
    required String corpCode,
    required String name,
    String? stockCode,
    _igwiku5p.Market? market,
    required DateTime observedDate,
    required _i5ra8lvy.Source source,
  }) = _NewCompanyViewImpl;

  factory NewCompanyView.fromJson(Map<String, dynamic> jsonSerialization) {
    return NewCompanyView(
      corpCode: jsonSerialization['corpCode'] as String,
      name: jsonSerialization['name'] as String,
      stockCode: jsonSerialization['stockCode'] as String?,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
      observedDate: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['observedDate'],
      ),
      source: _i4yshtjp.Protocol().deserialize<_i5ra8lvy.Source>(
        jsonSerialization['source'],
      ),
    );
  }

  String corpCode;

  String name;

  String? stockCode;

  _igwiku5p.Market? market;

  DateTime observedDate;

  _i5ra8lvy.Source source;

  /// Returns a shallow copy of this [NewCompanyView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  NewCompanyView copyWith({
    String? corpCode,
    String? name,
    String? stockCode,
    _igwiku5p.Market? market,
    DateTime? observedDate,
    _i5ra8lvy.Source? source,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NewCompanyView',
      'corpCode': corpCode,
      'name': name,
      if (stockCode != null) 'stockCode': stockCode,
      if (market != null) 'market': market?.toJson(),
      'observedDate': observedDate.toJson(),
      'source': source.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NewCompanyView',
      'corpCode': corpCode,
      'name': name,
      if (stockCode != null) 'stockCode': stockCode,
      if (market != null) 'market': market?.toJson(),
      'observedDate': observedDate.toJson(),
      'source': source.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NewCompanyViewImpl extends NewCompanyView {
  _NewCompanyViewImpl({
    required String corpCode,
    required String name,
    String? stockCode,
    _igwiku5p.Market? market,
    required DateTime observedDate,
    required _i5ra8lvy.Source source,
  }) : super._(
         corpCode: corpCode,
         name: name,
         stockCode: stockCode,
         market: market,
         observedDate: observedDate,
         source: source,
       );

  /// Returns a shallow copy of this [NewCompanyView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  NewCompanyView copyWith({
    String? corpCode,
    String? name,
    Object? stockCode = _Undefined,
    Object? market = _Undefined,
    DateTime? observedDate,
    _i5ra8lvy.Source? source,
  }) {
    return NewCompanyView(
      corpCode: corpCode ?? this.corpCode,
      name: name ?? this.name,
      stockCode: stockCode is String? ? stockCode : this.stockCode,
      market: market is _igwiku5p.Market? ? market : this.market,
      observedDate: observedDate ?? this.observedDate,
      source: source ?? this.source.copyWith(),
    );
  }
}
