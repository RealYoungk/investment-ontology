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
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/market.dart' as _igwiku5p;

/// 종목. 식별자는 ISIN. 발행 기업은 KRX상장종목정보의 법인등록번호(crno)로 Company.jurirNo와 잇는다.
abstract class Security
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Security._({
    this.id,
    required this.isinCode,
    required this.shortCode,
    required this.name,
    this.market,
    this.crno,
    this.corpName,
    this.companyId,
    required this.lastSeenDate,
    this.sourceId,
  });

  factory Security({
    int? id,
    required String isinCode,
    required String shortCode,
    required String name,
    _igwiku5p.Market? market,
    String? crno,
    String? corpName,
    int? companyId,
    required DateTime lastSeenDate,
    int? sourceId,
  }) = _SecurityImpl;

  factory Security.fromJson(Map<String, dynamic> jsonSerialization) {
    return Security(
      id: jsonSerialization['id'] as int?,
      isinCode: jsonSerialization['isinCode'] as String,
      shortCode: jsonSerialization['shortCode'] as String,
      name: jsonSerialization['name'] as String,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
      crno: jsonSerialization['crno'] as String?,
      corpName: jsonSerialization['corpName'] as String?,
      companyId: jsonSerialization['companyId'] as int?,
      lastSeenDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenDate'],
      ),
      sourceId: jsonSerialization['sourceId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String isinCode;

  /// 단축코드 (6자리)
  String shortCode;

  String name;

  _igwiku5p.Market? market;

  /// 법인등록번호 (13자리, 숫자만)
  String? crno;

  /// KRX상장종목정보의 법인명
  String? corpName;

  int? companyId;

  /// 시세나 상장종목 목록에서 마지막으로 확인한 기준일 (UTC 자정)
  DateTime lastSeenDate;

  /// 종목 정보(이름·시장·법인)의 마지막 출처
  int? sourceId;

  /// Returns a shallow copy of this [Security]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Security copyWith({
    int? id,
    String? isinCode,
    String? shortCode,
    String? name,
    _igwiku5p.Market? market,
    String? crno,
    String? corpName,
    int? companyId,
    DateTime? lastSeenDate,
    int? sourceId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Security',
      if (id != null) 'id': id,
      'isinCode': isinCode,
      'shortCode': shortCode,
      'name': name,
      if (market != null) 'market': market?.toJson(),
      if (crno != null) 'crno': crno,
      if (corpName != null) 'corpName': corpName,
      if (companyId != null) 'companyId': companyId,
      'lastSeenDate': lastSeenDate.toJson(),
      if (sourceId != null) 'sourceId': sourceId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Security',
      if (id != null) 'id': id,
      'isinCode': isinCode,
      'shortCode': shortCode,
      'name': name,
      if (market != null) 'market': market?.toJson(),
      if (crno != null) 'crno': crno,
      if (corpName != null) 'corpName': corpName,
      if (companyId != null) 'companyId': companyId,
      'lastSeenDate': lastSeenDate.toJson(),
      if (sourceId != null) 'sourceId': sourceId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SecurityImpl extends Security {
  _SecurityImpl({
    int? id,
    required String isinCode,
    required String shortCode,
    required String name,
    _igwiku5p.Market? market,
    String? crno,
    String? corpName,
    int? companyId,
    required DateTime lastSeenDate,
    int? sourceId,
  }) : super._(
         id: id,
         isinCode: isinCode,
         shortCode: shortCode,
         name: name,
         market: market,
         crno: crno,
         corpName: corpName,
         companyId: companyId,
         lastSeenDate: lastSeenDate,
         sourceId: sourceId,
       );

  /// Returns a shallow copy of this [Security]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Security copyWith({
    Object? id = _Undefined,
    String? isinCode,
    String? shortCode,
    String? name,
    Object? market = _Undefined,
    Object? crno = _Undefined,
    Object? corpName = _Undefined,
    Object? companyId = _Undefined,
    DateTime? lastSeenDate,
    Object? sourceId = _Undefined,
  }) {
    return Security(
      id: id is int? ? id : this.id,
      isinCode: isinCode ?? this.isinCode,
      shortCode: shortCode ?? this.shortCode,
      name: name ?? this.name,
      market: market is _igwiku5p.Market? ? market : this.market,
      crno: crno is String? ? crno : this.crno,
      corpName: corpName is String? ? corpName : this.corpName,
      companyId: companyId is int? ? companyId : this.companyId,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
    );
  }
}
