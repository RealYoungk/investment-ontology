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

import '../../ontology/models/company_ref.dart' as _id7z5ov5;

/// 스크리닝 결과 한 줄. 지표는 저장하지 않고 조회할 때 계산하며, 계산에 쓴 값도 함께 준다.
///
/// 손익·현금흐름은 최근 12개월(TTM), 재무상태표는 최근 보고서 기말 값이다.
abstract class ScreenRow
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ScreenRow._({
    required this.company,
    required this.bsnsYear,
    required this.marketCap,
    this.revenue,
    this.operatingIncome,
    this.netIncome,
    this.equity,
    this.liabilities,
    this.totalEquity,
    this.freeCashFlow,
    this.dividendTotal,
    this.per,
    this.pbr,
    this.roe,
    this.operatingMargin,
    this.debtRatio,
    this.fcfYield,
    this.dividendYield,
  });

  factory ScreenRow({
    required _id7z5ov5.CompanyRef company,
    required int bsnsYear,
    required BigInt marketCap,
    BigInt? revenue,
    BigInt? operatingIncome,
    BigInt? netIncome,
    BigInt? equity,
    BigInt? liabilities,
    BigInt? totalEquity,
    BigInt? freeCashFlow,
    BigInt? dividendTotal,
    double? per,
    double? pbr,
    double? roe,
    double? operatingMargin,
    double? debtRatio,
    double? fcfYield,
    double? dividendYield,
  }) = _ScreenRowImpl;

  factory ScreenRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScreenRow(
      company: _i4yshtjp.Protocol().deserialize<_id7z5ov5.CompanyRef>(
        jsonSerialization['company'],
      ),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      marketCap: _is.BigIntJsonExtension.fromJson(
        jsonSerialization['marketCap'],
      ),
      revenue: jsonSerialization['revenue'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['revenue']),
      operatingIncome: jsonSerialization['operatingIncome'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['operatingIncome'],
            ),
      netIncome: jsonSerialization['netIncome'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['netIncome']),
      equity: jsonSerialization['equity'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['equity']),
      liabilities: jsonSerialization['liabilities'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['liabilities']),
      totalEquity: jsonSerialization['totalEquity'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['totalEquity']),
      freeCashFlow: jsonSerialization['freeCashFlow'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(jsonSerialization['freeCashFlow']),
      dividendTotal: jsonSerialization['dividendTotal'] == null
          ? null
          : _is.BigIntJsonExtension.fromJson(
              jsonSerialization['dividendTotal'],
            ),
      per: (jsonSerialization['per'] as num?)?.toDouble(),
      pbr: (jsonSerialization['pbr'] as num?)?.toDouble(),
      roe: (jsonSerialization['roe'] as num?)?.toDouble(),
      operatingMargin: (jsonSerialization['operatingMargin'] as num?)
          ?.toDouble(),
      debtRatio: (jsonSerialization['debtRatio'] as num?)?.toDouble(),
      fcfYield: (jsonSerialization['fcfYield'] as num?)?.toDouble(),
      dividendYield: (jsonSerialization['dividendYield'] as num?)?.toDouble(),
    );
  }

  _id7z5ov5.CompanyRef company;

  /// 지표를 계산한 사업연도 (가장 최근 연결 보고서)
  int bsnsYear;

  BigInt marketCap;

  BigInt? revenue;

  BigInt? operatingIncome;

  BigInt? netIncome;

  BigInt? equity;

  /// 부채총계 (최근 기말)
  BigInt? liabilities;

  /// 자본총계 (최근 기말). 지배주주 자본인 equity와 다르다
  BigInt? totalEquity;

  /// 잉여현금흐름 = 영업활동 현금흐름 − 유형자산의 취득 (최근 12개월)
  BigInt? freeCashFlow;

  /// 최근 사업연도 현금배당금총액 (원)
  BigInt? dividendTotal;

  double? per;

  double? pbr;

  double? roe;

  double? operatingMargin;

  /// 부채총계 ÷ 자본총계 (%)
  double? debtRatio;

  /// 잉여현금흐름 ÷ 시가총액 (%)
  double? fcfYield;

  /// 현금배당금총액 ÷ 시가총액 (%)
  double? dividendYield;

  /// Returns a shallow copy of this [ScreenRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScreenRow copyWith({
    _id7z5ov5.CompanyRef? company,
    int? bsnsYear,
    BigInt? marketCap,
    BigInt? revenue,
    BigInt? operatingIncome,
    BigInt? netIncome,
    BigInt? equity,
    BigInt? liabilities,
    BigInt? totalEquity,
    BigInt? freeCashFlow,
    BigInt? dividendTotal,
    double? per,
    double? pbr,
    double? roe,
    double? operatingMargin,
    double? debtRatio,
    double? fcfYield,
    double? dividendYield,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScreenRow',
      'company': company.toJson(),
      'bsnsYear': bsnsYear,
      'marketCap': marketCap.toJson(),
      if (revenue != null) 'revenue': revenue?.toJson(),
      if (operatingIncome != null) 'operatingIncome': operatingIncome?.toJson(),
      if (netIncome != null) 'netIncome': netIncome?.toJson(),
      if (equity != null) 'equity': equity?.toJson(),
      if (liabilities != null) 'liabilities': liabilities?.toJson(),
      if (totalEquity != null) 'totalEquity': totalEquity?.toJson(),
      if (freeCashFlow != null) 'freeCashFlow': freeCashFlow?.toJson(),
      if (dividendTotal != null) 'dividendTotal': dividendTotal?.toJson(),
      if (per != null) 'per': per,
      if (pbr != null) 'pbr': pbr,
      if (roe != null) 'roe': roe,
      if (operatingMargin != null) 'operatingMargin': operatingMargin,
      if (debtRatio != null) 'debtRatio': debtRatio,
      if (fcfYield != null) 'fcfYield': fcfYield,
      if (dividendYield != null) 'dividendYield': dividendYield,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ScreenRow',
      'company': company.toJsonForProtocol(),
      'bsnsYear': bsnsYear,
      'marketCap': marketCap.toJson(),
      if (revenue != null) 'revenue': revenue?.toJson(),
      if (operatingIncome != null) 'operatingIncome': operatingIncome?.toJson(),
      if (netIncome != null) 'netIncome': netIncome?.toJson(),
      if (equity != null) 'equity': equity?.toJson(),
      if (liabilities != null) 'liabilities': liabilities?.toJson(),
      if (totalEquity != null) 'totalEquity': totalEquity?.toJson(),
      if (freeCashFlow != null) 'freeCashFlow': freeCashFlow?.toJson(),
      if (dividendTotal != null) 'dividendTotal': dividendTotal?.toJson(),
      if (per != null) 'per': per,
      if (pbr != null) 'pbr': pbr,
      if (roe != null) 'roe': roe,
      if (operatingMargin != null) 'operatingMargin': operatingMargin,
      if (debtRatio != null) 'debtRatio': debtRatio,
      if (fcfYield != null) 'fcfYield': fcfYield,
      if (dividendYield != null) 'dividendYield': dividendYield,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScreenRowImpl extends ScreenRow {
  _ScreenRowImpl({
    required _id7z5ov5.CompanyRef company,
    required int bsnsYear,
    required BigInt marketCap,
    BigInt? revenue,
    BigInt? operatingIncome,
    BigInt? netIncome,
    BigInt? equity,
    BigInt? liabilities,
    BigInt? totalEquity,
    BigInt? freeCashFlow,
    BigInt? dividendTotal,
    double? per,
    double? pbr,
    double? roe,
    double? operatingMargin,
    double? debtRatio,
    double? fcfYield,
    double? dividendYield,
  }) : super._(
         company: company,
         bsnsYear: bsnsYear,
         marketCap: marketCap,
         revenue: revenue,
         operatingIncome: operatingIncome,
         netIncome: netIncome,
         equity: equity,
         liabilities: liabilities,
         totalEquity: totalEquity,
         freeCashFlow: freeCashFlow,
         dividendTotal: dividendTotal,
         per: per,
         pbr: pbr,
         roe: roe,
         operatingMargin: operatingMargin,
         debtRatio: debtRatio,
         fcfYield: fcfYield,
         dividendYield: dividendYield,
       );

  /// Returns a shallow copy of this [ScreenRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScreenRow copyWith({
    _id7z5ov5.CompanyRef? company,
    int? bsnsYear,
    BigInt? marketCap,
    Object? revenue = _Undefined,
    Object? operatingIncome = _Undefined,
    Object? netIncome = _Undefined,
    Object? equity = _Undefined,
    Object? liabilities = _Undefined,
    Object? totalEquity = _Undefined,
    Object? freeCashFlow = _Undefined,
    Object? dividendTotal = _Undefined,
    Object? per = _Undefined,
    Object? pbr = _Undefined,
    Object? roe = _Undefined,
    Object? operatingMargin = _Undefined,
    Object? debtRatio = _Undefined,
    Object? fcfYield = _Undefined,
    Object? dividendYield = _Undefined,
  }) {
    return ScreenRow(
      company: company ?? this.company.copyWith(),
      bsnsYear: bsnsYear ?? this.bsnsYear,
      marketCap: marketCap ?? this.marketCap,
      revenue: revenue is BigInt? ? revenue : this.revenue,
      operatingIncome: operatingIncome is BigInt?
          ? operatingIncome
          : this.operatingIncome,
      netIncome: netIncome is BigInt? ? netIncome : this.netIncome,
      equity: equity is BigInt? ? equity : this.equity,
      liabilities: liabilities is BigInt? ? liabilities : this.liabilities,
      totalEquity: totalEquity is BigInt? ? totalEquity : this.totalEquity,
      freeCashFlow: freeCashFlow is BigInt? ? freeCashFlow : this.freeCashFlow,
      dividendTotal: dividendTotal is BigInt?
          ? dividendTotal
          : this.dividendTotal,
      per: per is double? ? per : this.per,
      pbr: pbr is double? ? pbr : this.pbr,
      roe: roe is double? ? roe : this.roe,
      operatingMargin: operatingMargin is double?
          ? operatingMargin
          : this.operatingMargin,
      debtRatio: debtRatio is double? ? debtRatio : this.debtRatio,
      fcfYield: fcfYield is double? ? fcfYield : this.fcfYield,
      dividendYield: dividendYield is double?
          ? dividendYield
          : this.dividendYield,
    );
  }
}
