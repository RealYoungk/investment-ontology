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

/// 목록 화면용 기업 요약.
abstract class CompanyListItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CompanyListItem._({
    required this.corpCode,
    required this.name,
    this.stockCode,
    this.market,
    this.industryCode,
    this.industryName,
    this.sectionCode,
    this.sectionName,
    this.ceoName,
    this.fiscalMonth,
    this.establishedDate,
  });

  factory CompanyListItem({
    required String corpCode,
    required String name,
    String? stockCode,
    _igwiku5p.Market? market,
    String? industryCode,
    String? industryName,
    String? sectionCode,
    String? sectionName,
    String? ceoName,
    int? fiscalMonth,
    DateTime? establishedDate,
  }) = _CompanyListItemImpl;

  factory CompanyListItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyListItem(
      corpCode: jsonSerialization['corpCode'] as String,
      name: jsonSerialization['name'] as String,
      stockCode: jsonSerialization['stockCode'] as String?,
      market: jsonSerialization['market'] == null
          ? null
          : _igwiku5p.Market.fromJson((jsonSerialization['market'] as String)),
      industryCode: jsonSerialization['industryCode'] as String?,
      industryName: jsonSerialization['industryName'] as String?,
      sectionCode: jsonSerialization['sectionCode'] as String?,
      sectionName: jsonSerialization['sectionName'] as String?,
      ceoName: jsonSerialization['ceoName'] as String?,
      fiscalMonth: jsonSerialization['fiscalMonth'] as int?,
      establishedDate: jsonSerialization['establishedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['establishedDate'],
            ),
    );
  }

  String corpCode;

  String name;

  String? stockCode;

  _igwiku5p.Market? market;

  String? industryCode;

  String? industryName;

  String? sectionCode;

  String? sectionName;

  String? ceoName;

  int? fiscalMonth;

  DateTime? establishedDate;

  /// Returns a shallow copy of this [CompanyListItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CompanyListItem copyWith({
    String? corpCode,
    String? name,
    String? stockCode,
    _igwiku5p.Market? market,
    String? industryCode,
    String? industryName,
    String? sectionCode,
    String? sectionName,
    String? ceoName,
    int? fiscalMonth,
    DateTime? establishedDate,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyListItem',
      'corpCode': corpCode,
      'name': name,
      if (stockCode != null) 'stockCode': stockCode,
      if (market != null) 'market': market?.toJson(),
      if (industryCode != null) 'industryCode': industryCode,
      if (industryName != null) 'industryName': industryName,
      if (sectionCode != null) 'sectionCode': sectionCode,
      if (sectionName != null) 'sectionName': sectionName,
      if (ceoName != null) 'ceoName': ceoName,
      if (fiscalMonth != null) 'fiscalMonth': fiscalMonth,
      if (establishedDate != null) 'establishedDate': establishedDate?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyListItem',
      'corpCode': corpCode,
      'name': name,
      if (stockCode != null) 'stockCode': stockCode,
      if (market != null) 'market': market?.toJson(),
      if (industryCode != null) 'industryCode': industryCode,
      if (industryName != null) 'industryName': industryName,
      if (sectionCode != null) 'sectionCode': sectionCode,
      if (sectionName != null) 'sectionName': sectionName,
      if (ceoName != null) 'ceoName': ceoName,
      if (fiscalMonth != null) 'fiscalMonth': fiscalMonth,
      if (establishedDate != null) 'establishedDate': establishedDate?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyListItemImpl extends CompanyListItem {
  _CompanyListItemImpl({
    required String corpCode,
    required String name,
    String? stockCode,
    _igwiku5p.Market? market,
    String? industryCode,
    String? industryName,
    String? sectionCode,
    String? sectionName,
    String? ceoName,
    int? fiscalMonth,
    DateTime? establishedDate,
  }) : super._(
         corpCode: corpCode,
         name: name,
         stockCode: stockCode,
         market: market,
         industryCode: industryCode,
         industryName: industryName,
         sectionCode: sectionCode,
         sectionName: sectionName,
         ceoName: ceoName,
         fiscalMonth: fiscalMonth,
         establishedDate: establishedDate,
       );

  /// Returns a shallow copy of this [CompanyListItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CompanyListItem copyWith({
    String? corpCode,
    String? name,
    Object? stockCode = _Undefined,
    Object? market = _Undefined,
    Object? industryCode = _Undefined,
    Object? industryName = _Undefined,
    Object? sectionCode = _Undefined,
    Object? sectionName = _Undefined,
    Object? ceoName = _Undefined,
    Object? fiscalMonth = _Undefined,
    Object? establishedDate = _Undefined,
  }) {
    return CompanyListItem(
      corpCode: corpCode ?? this.corpCode,
      name: name ?? this.name,
      stockCode: stockCode is String? ? stockCode : this.stockCode,
      market: market is _igwiku5p.Market? ? market : this.market,
      industryCode: industryCode is String? ? industryCode : this.industryCode,
      industryName: industryName is String? ? industryName : this.industryName,
      sectionCode: sectionCode is String? ? sectionCode : this.sectionCode,
      sectionName: sectionName is String? ? sectionName : this.sectionName,
      ceoName: ceoName is String? ? ceoName : this.ceoName,
      fiscalMonth: fiscalMonth is int? ? fiscalMonth : this.fiscalMonth,
      establishedDate: establishedDate is DateTime?
          ? establishedDate
          : this.establishedDate,
    );
  }
}
