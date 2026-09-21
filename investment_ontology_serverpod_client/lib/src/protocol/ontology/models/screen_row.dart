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
    this.per,
    this.pbr,
    this.roe,
    this.operatingMargin,
  });

  factory ScreenRow({
    required _id7z5ov5.CompanyRef company,
    required int bsnsYear,
    required BigInt marketCap,
    BigInt? revenue,
    BigInt? operatingIncome,
    BigInt? netIncome,
    BigInt? equity,
    double? per,
    double? pbr,
    double? roe,
    double? operatingMargin,
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
      per: (jsonSerialization['per'] as num?)?.toDouble(),
      pbr: (jsonSerialization['pbr'] as num?)?.toDouble(),
      roe: (jsonSerialization['roe'] as num?)?.toDouble(),
      operatingMargin: (jsonSerialization['operatingMargin'] as num?)
          ?.toDouble(),
    );
  }

  _id7z5ov5.CompanyRef company;

  /// 지표를 계산한 사업연도 (가장 최근 연결 사업보고서)
  int bsnsYear;

  BigInt marketCap;

  BigInt? revenue;

  BigInt? operatingIncome;

  BigInt? netIncome;

  BigInt? equity;

  double? per;

  double? pbr;

  double? roe;

  double? operatingMargin;

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
    double? per,
    double? pbr,
    double? roe,
    double? operatingMargin,
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
      if (per != null) 'per': per,
      if (pbr != null) 'pbr': pbr,
      if (roe != null) 'roe': roe,
      if (operatingMargin != null) 'operatingMargin': operatingMargin,
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
      if (per != null) 'per': per,
      if (pbr != null) 'pbr': pbr,
      if (roe != null) 'roe': roe,
      if (operatingMargin != null) 'operatingMargin': operatingMargin,
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
    double? per,
    double? pbr,
    double? roe,
    double? operatingMargin,
  }) : super._(
         company: company,
         bsnsYear: bsnsYear,
         marketCap: marketCap,
         revenue: revenue,
         operatingIncome: operatingIncome,
         netIncome: netIncome,
         equity: equity,
         per: per,
         pbr: pbr,
         roe: roe,
         operatingMargin: operatingMargin,
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
    Object? per = _Undefined,
    Object? pbr = _Undefined,
    Object? roe = _Undefined,
    Object? operatingMargin = _Undefined,
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
      per: per is double? ? per : this.per,
      pbr: pbr is double? ? pbr : this.pbr,
      roe: roe is double? ? roe : this.roe,
      operatingMargin: operatingMargin is double?
          ? operatingMargin
          : this.operatingMargin,
    );
  }
}
