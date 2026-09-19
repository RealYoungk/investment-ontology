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

/// 타법인 출자 한 행 (타법인 출자현황 otrCprInvstmntSttus). 금액은 원 단위 (API가 원문 백만원을 원으로 바꿔 준다).
abstract class InvestmentEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  InvestmentEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.investeeName,
    this.purpose,
    this.firstAcquiredOn,
    this.firstAcquiredAmount,
    this.sharesBegin,
    this.ratioBegin,
    this.bookValueBegin,
    this.sharesChange,
    this.amountChange,
    this.valuationChange,
    this.sharesEnd,
    this.ratioEnd,
    this.bookValueEnd,
    this.investeeTotalAssets,
    this.investeeNetIncome,
    required this.isTotal,
    this.investeeCompanyId,
    this.investeeLinkBasis,
  });

  factory InvestmentEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String investeeName,
    String? purpose,
    DateTime? firstAcquiredOn,
    BigInt? firstAcquiredAmount,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? bookValueBegin,
    BigInt? sharesChange,
    BigInt? amountChange,
    BigInt? valuationChange,
    BigInt? sharesEnd,
    double? ratioEnd,
    BigInt? bookValueEnd,
    BigInt? investeeTotalAssets,
    BigInt? investeeNetIncome,
    required bool isTotal,
    int? investeeCompanyId,
    _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis,
  }) = _InvestmentEntryImpl;

  factory InvestmentEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return InvestmentEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      investeeName: jsonSerialization['investeeName'] as String,
      purpose: jsonSerialization['purpose'] as String?,
      firstAcquiredOn: jsonSerialization['firstAcquiredOn'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['firstAcquiredOn'],
            ),
      firstAcquiredAmount: jsonSerialization['firstAcquiredAmount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['firstAcquiredAmount'],
            ),
      sharesBegin: jsonSerialization['sharesBegin'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['sharesBegin']),
      ratioBegin: (jsonSerialization['ratioBegin'] as num?)?.toDouble(),
      bookValueBegin: jsonSerialization['bookValueBegin'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['bookValueBegin'],
            ),
      sharesChange: jsonSerialization['sharesChange'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['sharesChange'],
            ),
      amountChange: jsonSerialization['amountChange'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['amountChange'],
            ),
      valuationChange: jsonSerialization['valuationChange'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['valuationChange'],
            ),
      sharesEnd: jsonSerialization['sharesEnd'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['sharesEnd']),
      ratioEnd: (jsonSerialization['ratioEnd'] as num?)?.toDouble(),
      bookValueEnd: jsonSerialization['bookValueEnd'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['bookValueEnd'],
            ),
      investeeTotalAssets: jsonSerialization['investeeTotalAssets'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['investeeTotalAssets'],
            ),
      investeeNetIncome: jsonSerialization['investeeNetIncome'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['investeeNetIncome'],
            ),
      isTotal: _isc.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
      investeeCompanyId: jsonSerialization['investeeCompanyId'] as int?,
      investeeLinkBasis: jsonSerialization['investeeLinkBasis'] == null
          ? null
          : _i0btqt1b.DisclosureLinkBasis.fromJson(
              (jsonSerialization['investeeLinkBasis'] as String),
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

  /// 줄바꿈·겹공백을 정리한 출자 대상 이름
  String investeeName;

  /// 출자 목적 원문 (경영참여, 단순투자, 일반투자 …)
  String? purpose;

  DateTime? firstAcquiredOn;

  BigInt? firstAcquiredAmount;

  BigInt? sharesBegin;

  double? ratioBegin;

  BigInt? bookValueBegin;

  /// 증감: 취득(처분) 수량·금액, 평가손익
  BigInt? sharesChange;

  BigInt? amountChange;

  BigInt? valuationChange;

  BigInt? sharesEnd;

  /// 기말 지분율 (%)
  double? ratioEnd;

  BigInt? bookValueEnd;

  /// 출자 대상의 최근 사업연도 총자산·당기순이익
  BigInt? investeeTotalAssets;

  BigInt? investeeNetIncome;

  bool isTotal;

  int? investeeCompanyId;

  _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis;

  /// Returns a shallow copy of this [InvestmentEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  InvestmentEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? investeeName,
    String? purpose,
    DateTime? firstAcquiredOn,
    BigInt? firstAcquiredAmount,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? bookValueBegin,
    BigInt? sharesChange,
    BigInt? amountChange,
    BigInt? valuationChange,
    BigInt? sharesEnd,
    double? ratioEnd,
    BigInt? bookValueEnd,
    BigInt? investeeTotalAssets,
    BigInt? investeeNetIncome,
    bool? isTotal,
    int? investeeCompanyId,
    _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'InvestmentEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'investeeName': investeeName,
      if (purpose != null) 'purpose': purpose,
      if (firstAcquiredOn != null) 'firstAcquiredOn': firstAcquiredOn?.toJson(),
      if (firstAcquiredAmount != null)
        'firstAcquiredAmount': firstAcquiredAmount?.toJson(),
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (bookValueBegin != null) 'bookValueBegin': bookValueBegin?.toJson(),
      if (sharesChange != null) 'sharesChange': sharesChange?.toJson(),
      if (amountChange != null) 'amountChange': amountChange?.toJson(),
      if (valuationChange != null) 'valuationChange': valuationChange?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (bookValueEnd != null) 'bookValueEnd': bookValueEnd?.toJson(),
      if (investeeTotalAssets != null)
        'investeeTotalAssets': investeeTotalAssets?.toJson(),
      if (investeeNetIncome != null)
        'investeeNetIncome': investeeNetIncome?.toJson(),
      'isTotal': isTotal,
      if (investeeCompanyId != null) 'investeeCompanyId': investeeCompanyId,
      if (investeeLinkBasis != null)
        'investeeLinkBasis': investeeLinkBasis?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'InvestmentEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'investeeName': investeeName,
      if (purpose != null) 'purpose': purpose,
      if (firstAcquiredOn != null) 'firstAcquiredOn': firstAcquiredOn?.toJson(),
      if (firstAcquiredAmount != null)
        'firstAcquiredAmount': firstAcquiredAmount?.toJson(),
      if (sharesBegin != null) 'sharesBegin': sharesBegin?.toJson(),
      if (ratioBegin != null) 'ratioBegin': ratioBegin,
      if (bookValueBegin != null) 'bookValueBegin': bookValueBegin?.toJson(),
      if (sharesChange != null) 'sharesChange': sharesChange?.toJson(),
      if (amountChange != null) 'amountChange': amountChange?.toJson(),
      if (valuationChange != null) 'valuationChange': valuationChange?.toJson(),
      if (sharesEnd != null) 'sharesEnd': sharesEnd?.toJson(),
      if (ratioEnd != null) 'ratioEnd': ratioEnd,
      if (bookValueEnd != null) 'bookValueEnd': bookValueEnd?.toJson(),
      if (investeeTotalAssets != null)
        'investeeTotalAssets': investeeTotalAssets?.toJson(),
      if (investeeNetIncome != null)
        'investeeNetIncome': investeeNetIncome?.toJson(),
      'isTotal': isTotal,
      if (investeeCompanyId != null) 'investeeCompanyId': investeeCompanyId,
      if (investeeLinkBasis != null)
        'investeeLinkBasis': investeeLinkBasis?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _InvestmentEntryImpl extends InvestmentEntry {
  _InvestmentEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String investeeName,
    String? purpose,
    DateTime? firstAcquiredOn,
    BigInt? firstAcquiredAmount,
    BigInt? sharesBegin,
    double? ratioBegin,
    BigInt? bookValueBegin,
    BigInt? sharesChange,
    BigInt? amountChange,
    BigInt? valuationChange,
    BigInt? sharesEnd,
    double? ratioEnd,
    BigInt? bookValueEnd,
    BigInt? investeeTotalAssets,
    BigInt? investeeNetIncome,
    required bool isTotal,
    int? investeeCompanyId,
    _i0btqt1b.DisclosureLinkBasis? investeeLinkBasis,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         investeeName: investeeName,
         purpose: purpose,
         firstAcquiredOn: firstAcquiredOn,
         firstAcquiredAmount: firstAcquiredAmount,
         sharesBegin: sharesBegin,
         ratioBegin: ratioBegin,
         bookValueBegin: bookValueBegin,
         sharesChange: sharesChange,
         amountChange: amountChange,
         valuationChange: valuationChange,
         sharesEnd: sharesEnd,
         ratioEnd: ratioEnd,
         bookValueEnd: bookValueEnd,
         investeeTotalAssets: investeeTotalAssets,
         investeeNetIncome: investeeNetIncome,
         isTotal: isTotal,
         investeeCompanyId: investeeCompanyId,
         investeeLinkBasis: investeeLinkBasis,
       );

  /// Returns a shallow copy of this [InvestmentEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  InvestmentEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? investeeName,
    Object? purpose = _Undefined,
    Object? firstAcquiredOn = _Undefined,
    Object? firstAcquiredAmount = _Undefined,
    Object? sharesBegin = _Undefined,
    Object? ratioBegin = _Undefined,
    Object? bookValueBegin = _Undefined,
    Object? sharesChange = _Undefined,
    Object? amountChange = _Undefined,
    Object? valuationChange = _Undefined,
    Object? sharesEnd = _Undefined,
    Object? ratioEnd = _Undefined,
    Object? bookValueEnd = _Undefined,
    Object? investeeTotalAssets = _Undefined,
    Object? investeeNetIncome = _Undefined,
    bool? isTotal,
    Object? investeeCompanyId = _Undefined,
    Object? investeeLinkBasis = _Undefined,
  }) {
    return InvestmentEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      investeeName: investeeName ?? this.investeeName,
      purpose: purpose is String? ? purpose : this.purpose,
      firstAcquiredOn: firstAcquiredOn is DateTime?
          ? firstAcquiredOn
          : this.firstAcquiredOn,
      firstAcquiredAmount: firstAcquiredAmount is BigInt?
          ? firstAcquiredAmount
          : this.firstAcquiredAmount,
      sharesBegin: sharesBegin is BigInt? ? sharesBegin : this.sharesBegin,
      ratioBegin: ratioBegin is double? ? ratioBegin : this.ratioBegin,
      bookValueBegin: bookValueBegin is BigInt?
          ? bookValueBegin
          : this.bookValueBegin,
      sharesChange: sharesChange is BigInt? ? sharesChange : this.sharesChange,
      amountChange: amountChange is BigInt? ? amountChange : this.amountChange,
      valuationChange: valuationChange is BigInt?
          ? valuationChange
          : this.valuationChange,
      sharesEnd: sharesEnd is BigInt? ? sharesEnd : this.sharesEnd,
      ratioEnd: ratioEnd is double? ? ratioEnd : this.ratioEnd,
      bookValueEnd: bookValueEnd is BigInt? ? bookValueEnd : this.bookValueEnd,
      investeeTotalAssets: investeeTotalAssets is BigInt?
          ? investeeTotalAssets
          : this.investeeTotalAssets,
      investeeNetIncome: investeeNetIncome is BigInt?
          ? investeeNetIncome
          : this.investeeNetIncome,
      isTotal: isTotal ?? this.isTotal,
      investeeCompanyId: investeeCompanyId is int?
          ? investeeCompanyId
          : this.investeeCompanyId,
      investeeLinkBasis: investeeLinkBasis is _i0btqt1b.DisclosureLinkBasis?
          ? investeeLinkBasis
          : this.investeeLinkBasis,
    );
  }
}
