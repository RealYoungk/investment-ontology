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
import 'package:investment_ontology_serverpod_client/src/protocol/protocol.dart'
    as _ilkzeueu;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/company_ref.dart' as _id7z5ov5;

/// 최근 올라온 정기보고서 한 건.
abstract class FilingFeedItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FilingFeedItem._({
    required this.company,
    required this.rceptNo,
    required this.reportName,
    this.receivedDate,
    this.bsnsYear,
    required this.financialStored,
    this.marketCap,
  });

  factory FilingFeedItem({
    required _id7z5ov5.CompanyRef company,
    required String rceptNo,
    required String reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    required bool financialStored,
    BigInt? marketCap,
  }) = _FilingFeedItemImpl;

  factory FilingFeedItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return FilingFeedItem(
      company: _ilkzeueu.Protocol().deserialize<_id7z5ov5.CompanyRef>(
        jsonSerialization['company'],
      ),
      rceptNo: jsonSerialization['rceptNo'] as String,
      reportName: jsonSerialization['reportName'] as String,
      receivedDate: jsonSerialization['receivedDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['receivedDate'],
            ),
      bsnsYear: jsonSerialization['bsnsYear'] as int?,
      financialStored: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['financialStored'],
      ),
      marketCap: jsonSerialization['marketCap'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['marketCap']),
    );
  }

  _id7z5ov5.CompanyRef company;

  String rceptNo;

  String reportName;

  DateTime? receivedDate;

  int? bsnsYear;

  /// 이 보고서의 재무제표를 받아 뒀는지
  bool financialStored;

  /// 시가총액 (최근 기준일)
  BigInt? marketCap;

  /// Returns a shallow copy of this [FilingFeedItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FilingFeedItem copyWith({
    _id7z5ov5.CompanyRef? company,
    String? rceptNo,
    String? reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    bool? financialStored,
    BigInt? marketCap,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FilingFeedItem',
      'company': company.toJson(),
      'rceptNo': rceptNo,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      'financialStored': financialStored,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FilingFeedItem',
      'company': company.toJsonForProtocol(),
      'rceptNo': rceptNo,
      'reportName': reportName,
      if (receivedDate != null) 'receivedDate': receivedDate?.toJson(),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      'financialStored': financialStored,
      if (marketCap != null) 'marketCap': marketCap?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FilingFeedItemImpl extends FilingFeedItem {
  _FilingFeedItemImpl({
    required _id7z5ov5.CompanyRef company,
    required String rceptNo,
    required String reportName,
    DateTime? receivedDate,
    int? bsnsYear,
    required bool financialStored,
    BigInt? marketCap,
  }) : super._(
         company: company,
         rceptNo: rceptNo,
         reportName: reportName,
         receivedDate: receivedDate,
         bsnsYear: bsnsYear,
         financialStored: financialStored,
         marketCap: marketCap,
       );

  /// Returns a shallow copy of this [FilingFeedItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FilingFeedItem copyWith({
    _id7z5ov5.CompanyRef? company,
    String? rceptNo,
    String? reportName,
    Object? receivedDate = _Undefined,
    Object? bsnsYear = _Undefined,
    bool? financialStored,
    Object? marketCap = _Undefined,
  }) {
    return FilingFeedItem(
      company: company ?? this.company.copyWith(),
      rceptNo: rceptNo ?? this.rceptNo,
      reportName: reportName ?? this.reportName,
      receivedDate: receivedDate is DateTime?
          ? receivedDate
          : this.receivedDate,
      bsnsYear: bsnsYear is int? ? bsnsYear : this.bsnsYear,
      financialStored: financialStored ?? this.financialStored,
      marketCap: marketCap is BigInt? ? marketCap : this.marketCap,
    );
  }
}
