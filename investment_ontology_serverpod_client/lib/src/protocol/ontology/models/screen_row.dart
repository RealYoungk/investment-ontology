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

/// 스크리닝 결과 한 줄. 지표는 저장하지 않고 조회할 때 계산하며, 계산에 쓴 값도 함께 준다.
///
/// 손익·현금흐름은 최근 12개월(TTM), 재무상태표는 최근 보고서 기말 값이다.
abstract class ScreenRow
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    this.revenueGrowth,
    this.operatingIncomeGrowth,
    this.closePrice,
    this.return3m,
    this.return12m,
    this.high52w,
    this.low52w,
    this.bandPosition,
    this.avgTradingValue,
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
    double? revenueGrowth,
    double? operatingIncomeGrowth,
    int? closePrice,
    double? return3m,
    double? return12m,
    int? high52w,
    int? low52w,
    double? bandPosition,
    BigInt? avgTradingValue,
  }) = _ScreenRowImpl;

  factory ScreenRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScreenRow(
      company: _ilkzeueu.Protocol().deserialize<_id7z5ov5.CompanyRef>(
        jsonSerialization['company'],
      ),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      marketCap: _isc.BigIntJsonExtension.fromJson(
        jsonSerialization['marketCap'],
      ),
      revenue: jsonSerialization['revenue'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['revenue']),
      operatingIncome: jsonSerialization['operatingIncome'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['operatingIncome'],
            ),
      netIncome: jsonSerialization['netIncome'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['netIncome']),
      equity: jsonSerialization['equity'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['equity']),
      liabilities: jsonSerialization['liabilities'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['liabilities']),
      totalEquity: jsonSerialization['totalEquity'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['totalEquity']),
      freeCashFlow: jsonSerialization['freeCashFlow'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['freeCashFlow'],
            ),
      dividendTotal: jsonSerialization['dividendTotal'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
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
      revenueGrowth: (jsonSerialization['revenueGrowth'] as num?)?.toDouble(),
      operatingIncomeGrowth:
          (jsonSerialization['operatingIncomeGrowth'] as num?)?.toDouble(),
      closePrice: jsonSerialization['closePrice'] as int?,
      return3m: (jsonSerialization['return3m'] as num?)?.toDouble(),
      return12m: (jsonSerialization['return12m'] as num?)?.toDouble(),
      high52w: jsonSerialization['high52w'] as int?,
      low52w: jsonSerialization['low52w'] as int?,
      bandPosition: (jsonSerialization['bandPosition'] as num?)?.toDouble(),
      avgTradingValue: jsonSerialization['avgTradingValue'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['avgTradingValue'],
            ),
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

  /// 매출액 증감률 (올해 누적 vs 전년 같은 기간, %)
  double? revenueGrowth;

  /// 영업이익 증감률 (올해 누적 vs 전년 같은 기간, %)
  double? operatingIncomeGrowth;

  /// 대표 종목 종가 (최근 거래일, 원). 기업에 종목이 여럿이면 시가총액이 가장 큰 것
  int? closePrice;

  /// 3개월 주가 등락률 (%)
  double? return3m;

  /// 12개월 주가 등락률 (%)
  double? return12m;

  /// 최근 1년 종가의 최고·최저 (원)
  int? high52w;

  int? low52w;

  /// 52주 밴드에서 지금 종가의 자리 (0 = 최저, 100 = 최고)
  double? bandPosition;

  /// 최근 한 달 하루 평균 거래대금 (원). 얼마나 사고팔 수 있는지
  BigInt? avgTradingValue;

  /// Returns a shallow copy of this [ScreenRow]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    double? revenueGrowth,
    double? operatingIncomeGrowth,
    int? closePrice,
    double? return3m,
    double? return12m,
    int? high52w,
    int? low52w,
    double? bandPosition,
    BigInt? avgTradingValue,
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
      if (revenueGrowth != null) 'revenueGrowth': revenueGrowth,
      if (operatingIncomeGrowth != null)
        'operatingIncomeGrowth': operatingIncomeGrowth,
      if (closePrice != null) 'closePrice': closePrice,
      if (return3m != null) 'return3m': return3m,
      if (return12m != null) 'return12m': return12m,
      if (high52w != null) 'high52w': high52w,
      if (low52w != null) 'low52w': low52w,
      if (bandPosition != null) 'bandPosition': bandPosition,
      if (avgTradingValue != null) 'avgTradingValue': avgTradingValue?.toJson(),
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
      if (revenueGrowth != null) 'revenueGrowth': revenueGrowth,
      if (operatingIncomeGrowth != null)
        'operatingIncomeGrowth': operatingIncomeGrowth,
      if (closePrice != null) 'closePrice': closePrice,
      if (return3m != null) 'return3m': return3m,
      if (return12m != null) 'return12m': return12m,
      if (high52w != null) 'high52w': high52w,
      if (low52w != null) 'low52w': low52w,
      if (bandPosition != null) 'bandPosition': bandPosition,
      if (avgTradingValue != null) 'avgTradingValue': avgTradingValue?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
    double? revenueGrowth,
    double? operatingIncomeGrowth,
    int? closePrice,
    double? return3m,
    double? return12m,
    int? high52w,
    int? low52w,
    double? bandPosition,
    BigInt? avgTradingValue,
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
         revenueGrowth: revenueGrowth,
         operatingIncomeGrowth: operatingIncomeGrowth,
         closePrice: closePrice,
         return3m: return3m,
         return12m: return12m,
         high52w: high52w,
         low52w: low52w,
         bandPosition: bandPosition,
         avgTradingValue: avgTradingValue,
       );

  /// Returns a shallow copy of this [ScreenRow]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
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
    Object? revenueGrowth = _Undefined,
    Object? operatingIncomeGrowth = _Undefined,
    Object? closePrice = _Undefined,
    Object? return3m = _Undefined,
    Object? return12m = _Undefined,
    Object? high52w = _Undefined,
    Object? low52w = _Undefined,
    Object? bandPosition = _Undefined,
    Object? avgTradingValue = _Undefined,
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
      revenueGrowth: revenueGrowth is double?
          ? revenueGrowth
          : this.revenueGrowth,
      operatingIncomeGrowth: operatingIncomeGrowth is double?
          ? operatingIncomeGrowth
          : this.operatingIncomeGrowth,
      closePrice: closePrice is int? ? closePrice : this.closePrice,
      return3m: return3m is double? ? return3m : this.return3m,
      return12m: return12m is double? ? return12m : this.return12m,
      high52w: high52w is int? ? high52w : this.high52w,
      low52w: low52w is int? ? low52w : this.low52w,
      bandPosition: bandPosition is double? ? bandPosition : this.bandPosition,
      avgTradingValue: avgTradingValue is BigInt?
          ? avgTradingValue
          : this.avgTradingValue,
    );
  }
}
