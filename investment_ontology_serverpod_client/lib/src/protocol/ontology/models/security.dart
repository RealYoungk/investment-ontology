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
import '../../ontology/models/security_link_basis.dart' as _ipb681z0;

/// 종목. 식별자는 ISIN. 발행 기업은 법인등록번호 → DART 종목코드 → ISIN 발행체 코드 순서로 잇는다.
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
    this.linkBasis,
    required this.lastSeenDate,
    this.firstObservedDate,
    this.firstObservedSourceId,
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
    _ipb681z0.SecurityLinkBasis? linkBasis,
    required DateTime lastSeenDate,
    DateTime? firstObservedDate,
    int? firstObservedSourceId,
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
      linkBasis: jsonSerialization['linkBasis'] == null
          ? null
          : _ipb681z0.SecurityLinkBasis.fromJson(
              (jsonSerialization['linkBasis'] as String),
            ),
      lastSeenDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenDate'],
      ),
      firstObservedDate: jsonSerialization['firstObservedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['firstObservedDate'],
            ),
      firstObservedSourceId: jsonSerialization['firstObservedSourceId'] as int?,
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

  /// companyId를 정한 근거
  _ipb681z0.SecurityLinkBasis? linkBasis;

  /// 시세나 상장종목 목록에서 마지막으로 확인한 기준일 (UTC 자정)
  DateTime lastSeenDate;

  /// 정상 수집에서 새 종목을 처음 확인한 기준일. 공식 상장일이 아니며 초기/복구 수집은 null.
  DateTime? firstObservedDate;

  int? firstObservedSourceId;

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
    _ipb681z0.SecurityLinkBasis? linkBasis,
    DateTime? lastSeenDate,
    DateTime? firstObservedDate,
    int? firstObservedSourceId,
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
      if (linkBasis != null) 'linkBasis': linkBasis?.toJson(),
      'lastSeenDate': lastSeenDate.toJson(),
      if (firstObservedDate != null)
        'firstObservedDate': firstObservedDate?.toJson(),
      if (firstObservedSourceId != null)
        'firstObservedSourceId': firstObservedSourceId,
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
      if (linkBasis != null) 'linkBasis': linkBasis?.toJson(),
      'lastSeenDate': lastSeenDate.toJson(),
      if (firstObservedDate != null)
        'firstObservedDate': firstObservedDate?.toJson(),
      if (firstObservedSourceId != null)
        'firstObservedSourceId': firstObservedSourceId,
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
    _ipb681z0.SecurityLinkBasis? linkBasis,
    required DateTime lastSeenDate,
    DateTime? firstObservedDate,
    int? firstObservedSourceId,
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
         linkBasis: linkBasis,
         lastSeenDate: lastSeenDate,
         firstObservedDate: firstObservedDate,
         firstObservedSourceId: firstObservedSourceId,
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
    Object? linkBasis = _Undefined,
    DateTime? lastSeenDate,
    Object? firstObservedDate = _Undefined,
    Object? firstObservedSourceId = _Undefined,
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
      linkBasis: linkBasis is _ipb681z0.SecurityLinkBasis?
          ? linkBasis
          : this.linkBasis,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      firstObservedDate: firstObservedDate is DateTime?
          ? firstObservedDate
          : this.firstObservedDate,
      firstObservedSourceId: firstObservedSourceId is int?
          ? firstObservedSourceId
          : this.firstObservedSourceId,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
    );
  }
}
