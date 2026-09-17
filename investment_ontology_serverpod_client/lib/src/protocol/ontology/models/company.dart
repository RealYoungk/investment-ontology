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

/// 기업. 식별자는 DART 고유번호(corp_code, 8자리).
abstract class Company
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Company._({
    this.id,
    required this.corpCode,
    required this.name,
    this.nameEng,
    this.stockName,
    this.stockCode,
    this.market,
    this.ceoName,
    this.jurirNo,
    this.bizrNo,
    this.address,
    this.homepageUrl,
    this.irUrl,
    this.phone,
    this.industryCode,
    this.sectionCode,
    this.divisionCode,
    this.establishedDate,
    this.fiscalMonth,
    this.dartModifiedDate,
    this.profileSourceId,
    this.profileUpdatedAt,
  });

  factory Company({
    int? id,
    required String corpCode,
    required String name,
    String? nameEng,
    String? stockName,
    String? stockCode,
    _igwiku5p.Market? market,
    String? ceoName,
    String? jurirNo,
    String? bizrNo,
    String? address,
    String? homepageUrl,
    String? irUrl,
    String? phone,
    String? industryCode,
    String? sectionCode,
    String? divisionCode,
    DateTime? establishedDate,
    int? fiscalMonth,
    DateTime? dartModifiedDate,
    int? profileSourceId,
    DateTime? profileUpdatedAt,
  }) = _CompanyImpl;

  factory Company.fromJson(Map<String, dynamic> jsonSerialization) {
    return Company(
      id: jsonSerialization['id'] as int?,
      corpCode: jsonSerialization['corpCode'] as String,
      name: jsonSerialization['name'] as String,
      nameEng: jsonSerialization['nameEng'] as String?,
      stockName: jsonSerialization['stockName'] as String?,
      stockCode: jsonSerialization['stockCode'] as String?,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
      ceoName: jsonSerialization['ceoName'] as String?,
      jurirNo: jsonSerialization['jurirNo'] as String?,
      bizrNo: jsonSerialization['bizrNo'] as String?,
      address: jsonSerialization['address'] as String?,
      homepageUrl: jsonSerialization['homepageUrl'] as String?,
      irUrl: jsonSerialization['irUrl'] as String?,
      phone: jsonSerialization['phone'] as String?,
      industryCode: jsonSerialization['industryCode'] as String?,
      sectionCode: jsonSerialization['sectionCode'] as String?,
      divisionCode: jsonSerialization['divisionCode'] as String?,
      establishedDate: jsonSerialization['establishedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['establishedDate'],
            ),
      fiscalMonth: jsonSerialization['fiscalMonth'] as int?,
      dartModifiedDate: jsonSerialization['dartModifiedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['dartModifiedDate'],
            ),
      profileSourceId: jsonSerialization['profileSourceId'] as int?,
      profileUpdatedAt: jsonSerialization['profileUpdatedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['profileUpdatedAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String corpCode;

  String name;

  String? nameEng;

  String? stockName;

  /// 단축 종목코드 (6자리)
  String? stockCode;

  _igwiku5p.Market? market;

  String? ceoName;

  /// 법인등록번호
  String? jurirNo;

  /// 사업자등록번호
  String? bizrNo;

  String? address;

  String? homepageUrl;

  String? irUrl;

  String? phone;

  /// KSIC 코드 (DART induty_code 원문)
  String? industryCode;

  /// KSIC 대분류 (A~U), industryCode에서 파생
  String? sectionCode;

  /// KSIC 중분류 (2자리), industryCode에서 파생
  String? divisionCode;

  /// 설립일 (UTC 자정). 원천 값이 유효한 날짜가 아니면 null
  DateTime? establishedDate;

  /// 결산월 (1~12)
  int? fiscalMonth;

  /// corpCode.xml의 modify_date (UTC 자정)
  DateTime? dartModifiedDate;

  int? profileSourceId;

  DateTime? profileUpdatedAt;

  /// Returns a shallow copy of this [Company]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Company copyWith({
    int? id,
    String? corpCode,
    String? name,
    String? nameEng,
    String? stockName,
    String? stockCode,
    _igwiku5p.Market? market,
    String? ceoName,
    String? jurirNo,
    String? bizrNo,
    String? address,
    String? homepageUrl,
    String? irUrl,
    String? phone,
    String? industryCode,
    String? sectionCode,
    String? divisionCode,
    DateTime? establishedDate,
    int? fiscalMonth,
    DateTime? dartModifiedDate,
    int? profileSourceId,
    DateTime? profileUpdatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Company',
      if (id != null) 'id': id,
      'corpCode': corpCode,
      'name': name,
      if (nameEng != null) 'nameEng': nameEng,
      if (stockName != null) 'stockName': stockName,
      if (stockCode != null) 'stockCode': stockCode,
      if (market != null) 'market': market?.toJson(),
      if (ceoName != null) 'ceoName': ceoName,
      if (jurirNo != null) 'jurirNo': jurirNo,
      if (bizrNo != null) 'bizrNo': bizrNo,
      if (address != null) 'address': address,
      if (homepageUrl != null) 'homepageUrl': homepageUrl,
      if (irUrl != null) 'irUrl': irUrl,
      if (phone != null) 'phone': phone,
      if (industryCode != null) 'industryCode': industryCode,
      if (sectionCode != null) 'sectionCode': sectionCode,
      if (divisionCode != null) 'divisionCode': divisionCode,
      if (establishedDate != null) 'establishedDate': establishedDate?.toJson(),
      if (fiscalMonth != null) 'fiscalMonth': fiscalMonth,
      if (dartModifiedDate != null)
        'dartModifiedDate': dartModifiedDate?.toJson(),
      if (profileSourceId != null) 'profileSourceId': profileSourceId,
      if (profileUpdatedAt != null)
        'profileUpdatedAt': profileUpdatedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Company',
      if (id != null) 'id': id,
      'corpCode': corpCode,
      'name': name,
      if (nameEng != null) 'nameEng': nameEng,
      if (stockName != null) 'stockName': stockName,
      if (stockCode != null) 'stockCode': stockCode,
      if (market != null) 'market': market?.toJson(),
      if (ceoName != null) 'ceoName': ceoName,
      if (jurirNo != null) 'jurirNo': jurirNo,
      if (bizrNo != null) 'bizrNo': bizrNo,
      if (address != null) 'address': address,
      if (homepageUrl != null) 'homepageUrl': homepageUrl,
      if (irUrl != null) 'irUrl': irUrl,
      if (phone != null) 'phone': phone,
      if (industryCode != null) 'industryCode': industryCode,
      if (sectionCode != null) 'sectionCode': sectionCode,
      if (divisionCode != null) 'divisionCode': divisionCode,
      if (establishedDate != null) 'establishedDate': establishedDate?.toJson(),
      if (fiscalMonth != null) 'fiscalMonth': fiscalMonth,
      if (dartModifiedDate != null)
        'dartModifiedDate': dartModifiedDate?.toJson(),
      if (profileSourceId != null) 'profileSourceId': profileSourceId,
      if (profileUpdatedAt != null)
        'profileUpdatedAt': profileUpdatedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyImpl extends Company {
  _CompanyImpl({
    int? id,
    required String corpCode,
    required String name,
    String? nameEng,
    String? stockName,
    String? stockCode,
    _igwiku5p.Market? market,
    String? ceoName,
    String? jurirNo,
    String? bizrNo,
    String? address,
    String? homepageUrl,
    String? irUrl,
    String? phone,
    String? industryCode,
    String? sectionCode,
    String? divisionCode,
    DateTime? establishedDate,
    int? fiscalMonth,
    DateTime? dartModifiedDate,
    int? profileSourceId,
    DateTime? profileUpdatedAt,
  }) : super._(
         id: id,
         corpCode: corpCode,
         name: name,
         nameEng: nameEng,
         stockName: stockName,
         stockCode: stockCode,
         market: market,
         ceoName: ceoName,
         jurirNo: jurirNo,
         bizrNo: bizrNo,
         address: address,
         homepageUrl: homepageUrl,
         irUrl: irUrl,
         phone: phone,
         industryCode: industryCode,
         sectionCode: sectionCode,
         divisionCode: divisionCode,
         establishedDate: establishedDate,
         fiscalMonth: fiscalMonth,
         dartModifiedDate: dartModifiedDate,
         profileSourceId: profileSourceId,
         profileUpdatedAt: profileUpdatedAt,
       );

  /// Returns a shallow copy of this [Company]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Company copyWith({
    Object? id = _Undefined,
    String? corpCode,
    String? name,
    Object? nameEng = _Undefined,
    Object? stockName = _Undefined,
    Object? stockCode = _Undefined,
    Object? market = _Undefined,
    Object? ceoName = _Undefined,
    Object? jurirNo = _Undefined,
    Object? bizrNo = _Undefined,
    Object? address = _Undefined,
    Object? homepageUrl = _Undefined,
    Object? irUrl = _Undefined,
    Object? phone = _Undefined,
    Object? industryCode = _Undefined,
    Object? sectionCode = _Undefined,
    Object? divisionCode = _Undefined,
    Object? establishedDate = _Undefined,
    Object? fiscalMonth = _Undefined,
    Object? dartModifiedDate = _Undefined,
    Object? profileSourceId = _Undefined,
    Object? profileUpdatedAt = _Undefined,
  }) {
    return Company(
      id: id is int? ? id : this.id,
      corpCode: corpCode ?? this.corpCode,
      name: name ?? this.name,
      nameEng: nameEng is String? ? nameEng : this.nameEng,
      stockName: stockName is String? ? stockName : this.stockName,
      stockCode: stockCode is String? ? stockCode : this.stockCode,
      market: market is _igwiku5p.Market? ? market : this.market,
      ceoName: ceoName is String? ? ceoName : this.ceoName,
      jurirNo: jurirNo is String? ? jurirNo : this.jurirNo,
      bizrNo: bizrNo is String? ? bizrNo : this.bizrNo,
      address: address is String? ? address : this.address,
      homepageUrl: homepageUrl is String? ? homepageUrl : this.homepageUrl,
      irUrl: irUrl is String? ? irUrl : this.irUrl,
      phone: phone is String? ? phone : this.phone,
      industryCode: industryCode is String? ? industryCode : this.industryCode,
      sectionCode: sectionCode is String? ? sectionCode : this.sectionCode,
      divisionCode: divisionCode is String? ? divisionCode : this.divisionCode,
      establishedDate: establishedDate is DateTime?
          ? establishedDate
          : this.establishedDate,
      fiscalMonth: fiscalMonth is int? ? fiscalMonth : this.fiscalMonth,
      dartModifiedDate: dartModifiedDate is DateTime?
          ? dartModifiedDate
          : this.dartModifiedDate,
      profileSourceId: profileSourceId is int?
          ? profileSourceId
          : this.profileSourceId,
      profileUpdatedAt: profileUpdatedAt is DateTime?
          ? profileUpdatedAt
          : this.profileUpdatedAt,
    );
  }
}
