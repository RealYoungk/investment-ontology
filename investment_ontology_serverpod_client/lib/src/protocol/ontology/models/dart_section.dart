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

/// DART 정기보고서 주요정보(DS002) 항목. 항목마다 API 하나다 (주소·이름·우선순위는 DartSections).
enum DartSection implements _isc.SerializableModel {
  /// 주식의 총수 현황 (stockTotqySttus)
  stockTotal,

  /// 자기주식 취득 및 처분 현황 (tesstkAcqsDspsSttus)
  treasuryStock,

  /// 배당에 관한 사항 (alotMatter)
  dividend,

  /// 증자(감자) 현황 (irdsSttus)
  capitalChange,

  /// 채무증권 발행실적 (detScritsIsuAcmslt)
  debtIssuance,

  /// 기업어음증권 미상환 잔액 (entrprsBilScritsNrdmpBlce)
  commercialPaperBalance,

  /// 단기사채 미상환 잔액 (srtpdPsndbtNrdmpBlce)
  shortTermBondBalance,

  /// 회사채 미상환 잔액 (cprndNrdmpBlce)
  corporateBondBalance,

  /// 신종자본증권 미상환 잔액 (newCaplScritsNrdmpBlce)
  hybridCapitalBalance,

  /// 조건부 자본증권 미상환 잔액 (cndlCaplScritsNrdmpBlce)
  contingentCapitalBalance,

  /// 공모자금의 사용내역 (pssrpCptalUseDtls)
  publicFundUse,

  /// 사모자금의 사용내역 (prvsrpCptalUseDtls)
  privateFundUse,

  /// 회계감사인의 명칭 및 감사의견 (accnutAdtorNmNdAdtOpinion)
  auditorOpinion,

  /// 감사용역체결현황 (adtServcCnclsSttus)
  auditContract,

  /// 회계감사인과의 비감사용역 계약체결 현황 (accnutAdtorNonAdtServcCnclsSttus)
  nonAuditContract,

  /// 사외이사 및 그 변동현황 (outcmpnyDrctrNdChangeSttus)
  outsideDirectors,

  /// 최대주주 현황 (hyslrSttus)
  largestShareholders,

  /// 최대주주 변동현황 (hyslrChgSttus)
  largestShareholderChanges,

  /// 소액주주 현황 (mrhlSttus)
  minorityShareholders,

  /// 임원 현황 (exctvSttus)
  executives,

  /// 직원 현황 (empSttus)
  employees,

  /// 미등기임원 보수현황 (unrstExctvMendngSttus)
  unregisteredExecutivePay,

  /// 이사·감사 전체의 보수현황 - 주주총회 승인금액 (drctrAdtAllMendngSttusGmtsckConfmAmount)
  directorPayApproved,

  /// 이사·감사 전체의 보수현황 - 보수지급금액 전체 (hmvAuditAllSttus)
  directorPayTotal,

  /// 이사·감사 전체의 보수현황 - 보수지급금액 유형별 (drctrAdtAllMendngSttusMendngPymntamtTyCl)
  directorPayByType,

  /// 이사·감사의 개인별 보수현황 5억원 이상 (hmvAuditIndvdlBySttus)
  directorPayIndividual,

  /// 개인별 보수지급 금액 5억 이상 상위 5인 (indvdlByPay)
  topFivePay,

  /// 타법인 출자현황 (otrCprInvstmntSttus)
  investments;

  static DartSection fromJson(String name) {
    switch (name) {
      case 'stockTotal':
        return DartSection.stockTotal;
      case 'treasuryStock':
        return DartSection.treasuryStock;
      case 'dividend':
        return DartSection.dividend;
      case 'capitalChange':
        return DartSection.capitalChange;
      case 'debtIssuance':
        return DartSection.debtIssuance;
      case 'commercialPaperBalance':
        return DartSection.commercialPaperBalance;
      case 'shortTermBondBalance':
        return DartSection.shortTermBondBalance;
      case 'corporateBondBalance':
        return DartSection.corporateBondBalance;
      case 'hybridCapitalBalance':
        return DartSection.hybridCapitalBalance;
      case 'contingentCapitalBalance':
        return DartSection.contingentCapitalBalance;
      case 'publicFundUse':
        return DartSection.publicFundUse;
      case 'privateFundUse':
        return DartSection.privateFundUse;
      case 'auditorOpinion':
        return DartSection.auditorOpinion;
      case 'auditContract':
        return DartSection.auditContract;
      case 'nonAuditContract':
        return DartSection.nonAuditContract;
      case 'outsideDirectors':
        return DartSection.outsideDirectors;
      case 'largestShareholders':
        return DartSection.largestShareholders;
      case 'largestShareholderChanges':
        return DartSection.largestShareholderChanges;
      case 'minorityShareholders':
        return DartSection.minorityShareholders;
      case 'executives':
        return DartSection.executives;
      case 'employees':
        return DartSection.employees;
      case 'unregisteredExecutivePay':
        return DartSection.unregisteredExecutivePay;
      case 'directorPayApproved':
        return DartSection.directorPayApproved;
      case 'directorPayTotal':
        return DartSection.directorPayTotal;
      case 'directorPayByType':
        return DartSection.directorPayByType;
      case 'directorPayIndividual':
        return DartSection.directorPayIndividual;
      case 'topFivePay':
        return DartSection.topFivePay;
      case 'investments':
        return DartSection.investments;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DartSection"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
