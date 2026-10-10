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
import '../../ontology/models/dividend_entry.dart' as _i2wevjp3;
import '../../ontology/models/source.dart' as _i5ra8lvy;
import '../../ontology/models/stock_total_row.dart' as _iujsfq9w;
import '../../ontology/models/treasury_stock_entry.dart' as _i48r0cud;

/// 기업 상세의 주주환원: 배당 · 자기주식 · 주식 총수.
abstract class ShareholderReturn
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ShareholderReturn._({
    required this.corpCode,
    required this.dividends,
    this.treasuryYear,
    required this.treasury,
    this.stockTotalYear,
    required this.stockTotals,
    required this.sources,
    this.interimDividends,
    this.interimReportName,
    this.treasuryReportName,
    this.stockTotalReportName,
    this.latestReportName,
    this.latestYear,
    this.annualEndYear,
    this.availableYears,
    this.latestDividendStatus,
    this.latestTreasuryStatus,
    this.latestStockTotalStatus,
  });

  factory ShareholderReturn({
    required String corpCode,
    required List<_i2wevjp3.DividendEntry> dividends,
    int? treasuryYear,
    required List<_i48r0cud.TreasuryStockEntry> treasury,
    int? stockTotalYear,
    required List<_iujsfq9w.StockTotalRow> stockTotals,
    required List<_i5ra8lvy.Source> sources,
    List<_i2wevjp3.DividendEntry>? interimDividends,
    String? interimReportName,
    String? treasuryReportName,
    String? stockTotalReportName,
    String? latestReportName,
    int? latestYear,
    int? annualEndYear,
    List<int>? availableYears,
    String? latestDividendStatus,
    String? latestTreasuryStatus,
    String? latestStockTotalStatus,
  }) = _ShareholderReturnImpl;

  factory ShareholderReturn.fromJson(Map<String, dynamic> jsonSerialization) {
    return ShareholderReturn(
      corpCode: jsonSerialization['corpCode'] as String,
      dividends: _ilkzeueu.Protocol()
          .deserialize<List<_i2wevjp3.DividendEntry>>(
            jsonSerialization['dividends'],
          ),
      treasuryYear: jsonSerialization['treasuryYear'] as int?,
      treasury: _ilkzeueu.Protocol()
          .deserialize<List<_i48r0cud.TreasuryStockEntry>>(
            jsonSerialization['treasury'],
          ),
      stockTotalYear: jsonSerialization['stockTotalYear'] as int?,
      stockTotals: _ilkzeueu.Protocol()
          .deserialize<List<_iujsfq9w.StockTotalRow>>(
            jsonSerialization['stockTotals'],
          ),
      sources: _ilkzeueu.Protocol().deserialize<List<_i5ra8lvy.Source>>(
        jsonSerialization['sources'],
      ),
      interimDividends: jsonSerialization['interimDividends'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<List<_i2wevjp3.DividendEntry>>(
              jsonSerialization['interimDividends'],
            ),
      interimReportName: jsonSerialization['interimReportName'] as String?,
      treasuryReportName: jsonSerialization['treasuryReportName'] as String?,
      stockTotalReportName:
          jsonSerialization['stockTotalReportName'] as String?,
      latestReportName: jsonSerialization['latestReportName'] as String?,
      latestYear: jsonSerialization['latestYear'] as int?,
      annualEndYear: jsonSerialization['annualEndYear'] as int?,
      availableYears: jsonSerialization['availableYears'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<List<int>>(
              jsonSerialization['availableYears'],
            ),
      latestDividendStatus:
          jsonSerialization['latestDividendStatus'] as String?,
      latestTreasuryStatus:
          jsonSerialization['latestTreasuryStatus'] as String?,
      latestStockTotalStatus:
          jsonSerialization['latestStockTotalStatus'] as String?,
    );
  }

  String corpCode;

  /// 배당 행 (사업보고서마다 당기·전기·전전기가 있어 연도별로 모은다, 최근 보고서부터)
  List<_i2wevjp3.DividendEntry> dividends;

  int? treasuryYear;

  List<_i48r0cud.TreasuryStockEntry> treasury;

  int? stockTotalYear;

  List<_iujsfq9w.StockTotalRow> stockTotals;

  List<_i5ra8lvy.Source> sources;

  /// 최신 중간보고서 배당 행. 연간 배당 추이에 합치지 않는다.
  List<_i2wevjp3.DividendEntry>? interimDividends;

  String? interimReportName;

  String? treasuryReportName;

  String? stockTotalReportName;

  String? latestReportName;

  int? latestYear;

  int? annualEndYear;

  List<int>? availableYears;

  String? latestDividendStatus;

  String? latestTreasuryStatus;

  String? latestStockTotalStatus;

  /// Returns a shallow copy of this [ShareholderReturn]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ShareholderReturn copyWith({
    String? corpCode,
    List<_i2wevjp3.DividendEntry>? dividends,
    int? treasuryYear,
    List<_i48r0cud.TreasuryStockEntry>? treasury,
    int? stockTotalYear,
    List<_iujsfq9w.StockTotalRow>? stockTotals,
    List<_i5ra8lvy.Source>? sources,
    List<_i2wevjp3.DividendEntry>? interimDividends,
    String? interimReportName,
    String? treasuryReportName,
    String? stockTotalReportName,
    String? latestReportName,
    int? latestYear,
    int? annualEndYear,
    List<int>? availableYears,
    String? latestDividendStatus,
    String? latestTreasuryStatus,
    String? latestStockTotalStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShareholderReturn',
      'corpCode': corpCode,
      'dividends': dividends.toJson(valueToJson: (v) => v.toJson()),
      if (treasuryYear != null) 'treasuryYear': treasuryYear,
      'treasury': treasury.toJson(valueToJson: (v) => v.toJson()),
      if (stockTotalYear != null) 'stockTotalYear': stockTotalYear,
      'stockTotals': stockTotals.toJson(valueToJson: (v) => v.toJson()),
      'sources': sources.toJson(valueToJson: (v) => v.toJson()),
      if (interimDividends != null)
        'interimDividends': interimDividends?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
      if (interimReportName != null) 'interimReportName': interimReportName,
      if (treasuryReportName != null) 'treasuryReportName': treasuryReportName,
      if (stockTotalReportName != null)
        'stockTotalReportName': stockTotalReportName,
      if (latestReportName != null) 'latestReportName': latestReportName,
      if (latestYear != null) 'latestYear': latestYear,
      if (annualEndYear != null) 'annualEndYear': annualEndYear,
      if (availableYears != null) 'availableYears': availableYears?.toJson(),
      if (latestDividendStatus != null)
        'latestDividendStatus': latestDividendStatus,
      if (latestTreasuryStatus != null)
        'latestTreasuryStatus': latestTreasuryStatus,
      if (latestStockTotalStatus != null)
        'latestStockTotalStatus': latestStockTotalStatus,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ShareholderReturn',
      'corpCode': corpCode,
      'dividends': dividends.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (treasuryYear != null) 'treasuryYear': treasuryYear,
      'treasury': treasury.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (stockTotalYear != null) 'stockTotalYear': stockTotalYear,
      'stockTotals': stockTotals.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'sources': sources.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (interimDividends != null)
        'interimDividends': interimDividends?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (interimReportName != null) 'interimReportName': interimReportName,
      if (treasuryReportName != null) 'treasuryReportName': treasuryReportName,
      if (stockTotalReportName != null)
        'stockTotalReportName': stockTotalReportName,
      if (latestReportName != null) 'latestReportName': latestReportName,
      if (latestYear != null) 'latestYear': latestYear,
      if (annualEndYear != null) 'annualEndYear': annualEndYear,
      if (availableYears != null) 'availableYears': availableYears?.toJson(),
      if (latestDividendStatus != null)
        'latestDividendStatus': latestDividendStatus,
      if (latestTreasuryStatus != null)
        'latestTreasuryStatus': latestTreasuryStatus,
      if (latestStockTotalStatus != null)
        'latestStockTotalStatus': latestStockTotalStatus,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShareholderReturnImpl extends ShareholderReturn {
  _ShareholderReturnImpl({
    required String corpCode,
    required List<_i2wevjp3.DividendEntry> dividends,
    int? treasuryYear,
    required List<_i48r0cud.TreasuryStockEntry> treasury,
    int? stockTotalYear,
    required List<_iujsfq9w.StockTotalRow> stockTotals,
    required List<_i5ra8lvy.Source> sources,
    List<_i2wevjp3.DividendEntry>? interimDividends,
    String? interimReportName,
    String? treasuryReportName,
    String? stockTotalReportName,
    String? latestReportName,
    int? latestYear,
    int? annualEndYear,
    List<int>? availableYears,
    String? latestDividendStatus,
    String? latestTreasuryStatus,
    String? latestStockTotalStatus,
  }) : super._(
         corpCode: corpCode,
         dividends: dividends,
         treasuryYear: treasuryYear,
         treasury: treasury,
         stockTotalYear: stockTotalYear,
         stockTotals: stockTotals,
         sources: sources,
         interimDividends: interimDividends,
         interimReportName: interimReportName,
         treasuryReportName: treasuryReportName,
         stockTotalReportName: stockTotalReportName,
         latestReportName: latestReportName,
         latestYear: latestYear,
         annualEndYear: annualEndYear,
         availableYears: availableYears,
         latestDividendStatus: latestDividendStatus,
         latestTreasuryStatus: latestTreasuryStatus,
         latestStockTotalStatus: latestStockTotalStatus,
       );

  /// Returns a shallow copy of this [ShareholderReturn]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ShareholderReturn copyWith({
    String? corpCode,
    List<_i2wevjp3.DividendEntry>? dividends,
    Object? treasuryYear = _Undefined,
    List<_i48r0cud.TreasuryStockEntry>? treasury,
    Object? stockTotalYear = _Undefined,
    List<_iujsfq9w.StockTotalRow>? stockTotals,
    List<_i5ra8lvy.Source>? sources,
    Object? interimDividends = _Undefined,
    Object? interimReportName = _Undefined,
    Object? treasuryReportName = _Undefined,
    Object? stockTotalReportName = _Undefined,
    Object? latestReportName = _Undefined,
    Object? latestYear = _Undefined,
    Object? annualEndYear = _Undefined,
    Object? availableYears = _Undefined,
    Object? latestDividendStatus = _Undefined,
    Object? latestTreasuryStatus = _Undefined,
    Object? latestStockTotalStatus = _Undefined,
  }) {
    return ShareholderReturn(
      corpCode: corpCode ?? this.corpCode,
      dividends:
          dividends ?? this.dividends.map((e0) => e0.copyWith()).toList(),
      treasuryYear: treasuryYear is int? ? treasuryYear : this.treasuryYear,
      treasury: treasury ?? this.treasury.map((e0) => e0.copyWith()).toList(),
      stockTotalYear: stockTotalYear is int?
          ? stockTotalYear
          : this.stockTotalYear,
      stockTotals:
          stockTotals ?? this.stockTotals.map((e0) => e0.copyWith()).toList(),
      sources: sources ?? this.sources.map((e0) => e0.copyWith()).toList(),
      interimDividends: interimDividends is List<_i2wevjp3.DividendEntry>?
          ? interimDividends
          : this.interimDividends?.map((e0) => e0.copyWith()).toList(),
      interimReportName: interimReportName is String?
          ? interimReportName
          : this.interimReportName,
      treasuryReportName: treasuryReportName is String?
          ? treasuryReportName
          : this.treasuryReportName,
      stockTotalReportName: stockTotalReportName is String?
          ? stockTotalReportName
          : this.stockTotalReportName,
      latestReportName: latestReportName is String?
          ? latestReportName
          : this.latestReportName,
      latestYear: latestYear is int? ? latestYear : this.latestYear,
      annualEndYear: annualEndYear is int? ? annualEndYear : this.annualEndYear,
      availableYears: availableYears is List<int>?
          ? availableYears
          : this.availableYears?.map((e0) => e0).toList(),
      latestDividendStatus: latestDividendStatus is String?
          ? latestDividendStatus
          : this.latestDividendStatus,
      latestTreasuryStatus: latestTreasuryStatus is String?
          ? latestTreasuryStatus
          : this.latestTreasuryStatus,
      latestStockTotalStatus: latestStockTotalStatus is String?
          ? latestStockTotalStatus
          : this.latestStockTotalStatus,
    );
  }
}
