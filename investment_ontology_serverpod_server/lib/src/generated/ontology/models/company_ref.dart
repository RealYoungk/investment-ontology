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
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/market.dart' as _igwiku5p;

/// 화면에서 기업으로 건너가기 위한 최소 정보.
abstract class CompanyRef
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CompanyRef._({
    required this.id,
    required this.corpCode,
    required this.name,
    this.market,
  });

  factory CompanyRef({
    required int id,
    required String corpCode,
    required String name,
    _igwiku5p.Market? market,
  }) = _CompanyRefImpl;

  factory CompanyRef.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyRef(
      id: jsonSerialization['id'] as int,
      corpCode: jsonSerialization['corpCode'] as String,
      name: jsonSerialization['name'] as String,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
    );
  }

  int id;

  String corpCode;

  String name;

  _igwiku5p.Market? market;

  /// Returns a shallow copy of this [CompanyRef]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyRef copyWith({
    int? id,
    String? corpCode,
    String? name,
    _igwiku5p.Market? market,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyRef',
      'id': id,
      'corpCode': corpCode,
      'name': name,
      if (market != null) 'market': market?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyRef',
      'id': id,
      'corpCode': corpCode,
      'name': name,
      if (market != null) 'market': market?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyRefImpl extends CompanyRef {
  _CompanyRefImpl({
    required int id,
    required String corpCode,
    required String name,
    _igwiku5p.Market? market,
  }) : super._(
         id: id,
         corpCode: corpCode,
         name: name,
         market: market,
       );

  /// Returns a shallow copy of this [CompanyRef]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyRef copyWith({
    int? id,
    String? corpCode,
    String? name,
    Object? market = _Undefined,
  }) {
    return CompanyRef(
      id: id ?? this.id,
      corpCode: corpCode ?? this.corpCode,
      name: name ?? this.name,
      market: market is _igwiku5p.Market? ? market : this.market,
    );
  }
}
