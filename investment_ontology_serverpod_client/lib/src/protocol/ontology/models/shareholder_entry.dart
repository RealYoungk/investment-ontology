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
import '../../ontology/models/disclosure_link_basis.dart' as _i0btqt1b;

/// 최대주주 및 특수관계인 한 행 (최대주주 현황 hyslrSttus).
abstract class ShareholderEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ShareholderEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.holderName,
    this.relationText,
    this.stockKind,
    this.sharesBegin,
    this.ratioBegin,
    this.sharesEnd,
    this.ratioEnd,
    this.remark,
    required this.isTotal,
    this.holderCompanyId,
    this.holderPersonId,
    this.holderLinkBasis,
  });

  factory ShareholderEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String holderName,
    String? relationText,
    String? stockKind,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? sharesEnd,
    double? ratioEnd,
    String? remark,
    required bool isTotal,
    int? holderCompanyId,
    int? holderPersonId,
    _i0btqt1b.DisclosureLinkBasis? holderLinkBasis,
  }) = _ShareholderEntryImpl;

  factory ShareholderEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShareholderEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      holderName: jsonSerialization['holderName'] as String,
      relationText: jsonSerialization['relationText'] as String?,
      stockKind: jsonSerialization['stockKind'] as String?,
      sharesBegin: jsonSerialization['sharesBegin'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['sharesBegin']),
      ratioBegin: (jsonSerialization['ratioBegin'] as num?)?.toDouble(),
      sharesEnd: jsonSerialization['sharesEnd'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['sharesEnd']),
      ratioEnd: (jsonSerialization['ratioEnd'] as num?)?.toDouble(),
      remark: jsonSerialization['remark'] as String?,
      isTotal: _isc.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
      holderCompanyId: jsonSerialization['holderCompanyId'] as int?,
      holderPersonId: jsonSerialization['holderPersonId'] as int?,
      holderLinkBasis: jsonSerialization['holderLinkBasis'] == null
          ? null
          : _i0btqt1b.DisclosureLinkBasis.fromJson(
              (jsonSerialization['holderLinkBasis'] as String),
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 줄바꿈·겹공백을 정리한 이름 (원문 nm)
  String holderName;

  /// 관계 원문 (최대주주 본인, 최대주주의 특수관계인, 계열회사, 친인척 …)
  String? relationText;

  /// 주식 종류 원문 (보통주, 우선주 …)
  String? stockKind;

  BigInt? sharesBegin;

  /// 기초 지분율 (%)
  double? ratioBegin;

  BigInt? sharesEnd;

  /// 기말 지분율 (%)
  double? ratioEnd;

  String? remark;

  bool isTotal;

  int? holderCompanyId;

  int? holderPersonId;

  _i0btqt1b.DisclosureLinkBasis? holderLinkBasis;

  /// Returns a shallow copy of this [ShareholderEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ShareholderEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? holderName,
    String? relationText,
    String? stockKind,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? sharesEnd,
    double? ratioEnd,
    String? remark,
    bool? isTotal,
    int? holderCompanyId,
    int? holderPersonId,
    _i0btqt1b.DisclosureLinkBasis? holderLinkBasis,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShareholderEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'holderName': holderName,
      if (relationText != null) 'relationText': relationText,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
      if (holderCompanyId != null) 'holderCompanyId': holderCompanyId,
      if (holderPersonId != null) 'holderPersonId': holderPersonId,
      if (holderLinkBasis != null) 'holderLinkBasis': holderLinkBasis?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ShareholderEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'holderName': holderName,
      if (relationText != null) 'relationText': relationText,
      if (stockKind != null) 'stockKind': stockKind,
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (remark != null) 'remark': remark,
      'isTotal': isTotal,
      if (holderCompanyId != null) 'holderCompanyId': holderCompanyId,
      if (holderPersonId != null) 'holderPersonId': holderPersonId,
      if (holderLinkBasis != null) 'holderLinkBasis': holderLinkBasis?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShareholderEntryImpl extends ShareholderEntry {
  _ShareholderEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String holderName,
    String? relationText,
    String? stockKind,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? sharesEnd,
    double? ratioEnd,
    String? remark,
    required bool isTotal,
    int? holderCompanyId,
    int? holderPersonId,
    _i0btqt1b.DisclosureLinkBasis? holderLinkBasis,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         holderName: holderName,
         relationText: relationText,
         stockKind: stockKind,
         sharesBegin: sharesBegin,
         ratioBegin: ratioBegin,
         sharesEnd: sharesEnd,
         ratioEnd: ratioEnd,
         remark: remark,
         isTotal: isTotal,
         holderCompanyId: holderCompanyId,
         holderPersonId: holderPersonId,
         holderLinkBasis: holderLinkBasis,
       );

  /// Returns a shallow copy of this [ShareholderEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ShareholderEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? holderName,
    Object? relationText = _Undefined,
    Object? stockKind = _Undefined,
    Object? sharesBegin = _Undefined,
    Object? ratioBegin = _Undefined,
    Object? sharesEnd = _Undefined,
    Object? ratioEnd = _Undefined,
    Object? remark = _Undefined,
    bool? isTotal,
    Object? holderCompanyId = _Undefined,
    Object? holderPersonId = _Undefined,
    Object? holderLinkBasis = _Undefined,
  }) {
    return ShareholderEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      holderName: holderName ?? this.holderName,
      relationText: relationText is String? ? relationText : this.relationText,
      stockKind: stockKind is String? ? stockKind : this.stockKind,
      sharesBegin: sharesBegin is BigInt? ? sharesBegin : this.sharesBegin,
      ratioBegin: ratioBegin is double? ? ratioBegin : this.ratioBegin,
      sharesEnd: sharesEnd is BigInt? ? sharesEnd : this.sharesEnd,
      ratioEnd: ratioEnd is double? ? ratioEnd : this.ratioEnd,
      remark: remark is String? ? remark : this.remark,
      isTotal: isTotal ?? this.isTotal,
      holderCompanyId: holderCompanyId is int?
          ? holderCompanyId
          : this.holderCompanyId,
      holderPersonId: holderPersonId is int?
          ? holderPersonId
          : this.holderPersonId,
      holderLinkBasis: holderLinkBasis is _i0btqt1b.DisclosureLinkBasis?
          ? holderLinkBasis
          : this.holderLinkBasis,
    );
  }
}
