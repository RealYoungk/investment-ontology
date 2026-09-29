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
import '../../ontology/models/company_market_cap.dart' as _itup2ouf;
import '../../ontology/models/financial_period.dart' as _idrk0nnp;
import '../../ontology/models/fs_div.dart' as _igqrlzji;

/// 기업 상세의 재무·시세. 파생 지표는 담지 않고 화면에서 원천 값으로 계산한다.
abstract class CompanyFinancials
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CompanyFinancials._({
    required this.corpCode,
    this.fsDiv,
    required this.availableFsDivs,
    required this.periods,
    this.market,
    required this.filingCount,
    required this.pendingFilingCount,
    this.basisReason,
  });

  factory CompanyFinancials({
    required String corpCode,
    _igqrlzji.FsDiv? fsDiv,
    required List<_igqrlzji.FsDiv> availableFsDivs,
    required List<_idrk0nnp.FinancialPeriod> periods,
    _itup2ouf.CompanyMarketCap? market,
    required int filingCount,
    required int pendingFilingCount,
    String? basisReason,
  }) = _CompanyFinancialsImpl;

  factory CompanyFinancials.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyFinancials(
      corpCode: jsonSerialization['corpCode'] as String,
      fsDiv: jsonSerialization['fsDiv'] == null
          ? null
          : _igqrlzji.FsDiv.fromJson((jsonSerialization['fsDiv'] as String)),
      availableFsDivs: _i4yshtjp.Protocol().deserialize<List<_igqrlzji.FsDiv>>(
        jsonSerialization['availableFsDivs'],
      ),
      periods: _i4yshtjp.Protocol()
          .deserialize<List<_idrk0nnp.FinancialPeriod>>(
            jsonSerialization['periods'],
          ),
      market: jsonSerialization['market'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_itup2ouf.CompanyMarketCap>(
              jsonSerialization['market'],
            ),
      filingCount: jsonSerialization['filingCount'] as int,
      pendingFilingCount: jsonSerialization['pendingFilingCount'] as int,
      basisReason: jsonSerialization['basisReason'] as String?,
    );
  }

  String corpCode;

  /// periods의 연결/별도 구분. 재무 자료가 없으면 null
  _igqrlzji.FsDiv? fsDiv;

  List<_igqrlzji.FsDiv> availableFsDivs;

  /// 오래된 기간부터
  List<_idrk0nnp.FinancialPeriod> periods;

  _itup2ouf.CompanyMarketCap? market;

  /// 수집 장부의 이 기업 정기보고서 수와 아직 받지 않은 수
  int filingCount;

  int pendingFilingCount;

  /// 자동 선택 이유 또는 수동 선택
  String? basisReason;

  /// Returns a shallow copy of this [CompanyFinancials]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyFinancials copyWith({
    String? corpCode,
    _igqrlzji.FsDiv? fsDiv,
    List<_igqrlzji.FsDiv>? availableFsDivs,
    List<_idrk0nnp.FinancialPeriod>? periods,
    _itup2ouf.CompanyMarketCap? market,
    int? filingCount,
    int? pendingFilingCount,
    String? basisReason,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyFinancials',
      'corpCode': corpCode,
      if (fsDiv != null) 'fsDiv': fsDiv?.toJson(),
      'availableFsDivs': availableFsDivs.toJson(valueToJson: (v) => v.toJson()),
      'periods': periods.toJson(valueToJson: (v) => v.toJson()),
      if (market != null) 'market': market?.toJson(),
      'filingCount': filingCount,
      'pendingFilingCount': pendingFilingCount,
      if (basisReason != null) 'basisReason': basisReason,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyFinancials',
      'corpCode': corpCode,
      if (fsDiv != null) 'fsDiv': fsDiv?.toJson(),
      'availableFsDivs': availableFsDivs.toJson(valueToJson: (v) => v.toJson()),
      'periods': periods.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (market != null) 'market': market?.toJsonForProtocol(),
      'filingCount': filingCount,
      'pendingFilingCount': pendingFilingCount,
      if (basisReason != null) 'basisReason': basisReason,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyFinancialsImpl extends CompanyFinancials {
  _CompanyFinancialsImpl({
    required String corpCode,
    _igqrlzji.FsDiv? fsDiv,
    required List<_igqrlzji.FsDiv> availableFsDivs,
    required List<_idrk0nnp.FinancialPeriod> periods,
    _itup2ouf.CompanyMarketCap? market,
    required int filingCount,
    required int pendingFilingCount,
    String? basisReason,
  }) : super._(
         corpCode: corpCode,
         fsDiv: fsDiv,
         availableFsDivs: availableFsDivs,
         periods: periods,
         market: market,
         filingCount: filingCount,
         pendingFilingCount: pendingFilingCount,
         basisReason: basisReason,
       );

  /// Returns a shallow copy of this [CompanyFinancials]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyFinancials copyWith({
    String? corpCode,
    Object? fsDiv = _Undefined,
    List<_igqrlzji.FsDiv>? availableFsDivs,
    List<_idrk0nnp.FinancialPeriod>? periods,
    Object? market = _Undefined,
    int? filingCount,
    int? pendingFilingCount,
    Object? basisReason = _Undefined,
  }) {
    return CompanyFinancials(
      corpCode: corpCode ?? this.corpCode,
      fsDiv: fsDiv is _igqrlzji.FsDiv? ? fsDiv : this.fsDiv,
      availableFsDivs:
          availableFsDivs ?? this.availableFsDivs.map((e0) => e0).toList(),
      periods: periods ?? this.periods.map((e0) => e0.copyWith()).toList(),
      market: market is _itup2ouf.CompanyMarketCap?
          ? market
          : this.market?.copyWith(),
      filingCount: filingCount ?? this.filingCount,
      pendingFilingCount: pendingFilingCount ?? this.pendingFilingCount,
      basisReason: basisReason is String? ? basisReason : this.basisReason,
    );
  }
}
