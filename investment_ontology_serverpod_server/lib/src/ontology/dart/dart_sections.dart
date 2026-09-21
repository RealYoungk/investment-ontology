import '../../generated/protocol.dart';

/// 정기보고서 주요정보 항목 하나의 API 정보.
class DartSectionInfo {
  const DartSectionInfo(this.api, this.label, this.group, this.tier);

  /// API 경로 (`hyslrSttus` → `hyslrSttus.json`).
  final String api;
  final String label;

  /// 화면 묶음 (지배구조, 주주환원·자본, 사람·보수, 감사, 채무·자금).
  final String group;

  /// 받는 순서. 0 = 핵심(지배구조 그래프·주주환원 화면), 1 = 나머지.
  final int tier;
}

/// DART 정기보고서 주요정보(DS002) 28종과 사업보고서 본문(사업의 내용).
///
/// 2026-09-19 표본(30개사 FY2025 사업보고서)에서 28종 모두 주소를 확인했다. 개인별 보수의
/// Ver 2.0 API 두 종은 같은 항목의 새 판이라 받지 않는다.
abstract final class DartSections {
  static const governance = '지배구조';
  static const capital = '주주환원·자본';
  static const people = '사람·보수';
  static const audit = '감사';
  static const debt = '채무·자금';
  static const business = '사업의 내용';

  static const info = <DartSection, DartSectionInfo>{
    DartSection.largestShareholders: DartSectionInfo(
      'hyslrSttus',
      '최대주주 현황',
      governance,
      0,
    ),
    DartSection.largestShareholderChanges: DartSectionInfo(
      'hyslrChgSttus',
      '최대주주 변동현황',
      governance,
      0,
    ),
    DartSection.minorityShareholders: DartSectionInfo(
      'mrhlSttus',
      '소액주주 현황',
      governance,
      0,
    ),
    DartSection.executives: DartSectionInfo(
      'exctvSttus',
      '임원 현황',
      governance,
      0,
    ),
    DartSection.investments: DartSectionInfo(
      'otrCprInvstmntSttus',
      '타법인 출자현황',
      governance,
      0,
    ),
    DartSection.outsideDirectors: DartSectionInfo(
      'outcmpnyDrctrNdChangeSttus',
      '사외이사 및 그 변동현황',
      governance,
      1,
    ),
    DartSection.dividend: DartSectionInfo(
      'alotMatter',
      '배당에 관한 사항',
      capital,
      0,
    ),
    DartSection.treasuryStock: DartSectionInfo(
      'tesstkAcqsDspsSttus',
      '자기주식 취득 및 처분 현황',
      capital,
      0,
    ),
    DartSection.stockTotal: DartSectionInfo(
      'stockTotqySttus',
      '주식의 총수 현황',
      capital,
      0,
    ),
    DartSection.capitalChange: DartSectionInfo(
      'irdsSttus',
      '증자(감자) 현황',
      capital,
      0,
    ),
    DartSection.employees: DartSectionInfo('empSttus', '직원 현황', people, 1),
    DartSection.unregisteredExecutivePay: DartSectionInfo(
      'unrstExctvMendngSttus',
      '미등기임원 보수현황',
      people,
      1,
    ),
    DartSection.directorPayApproved: DartSectionInfo(
      'drctrAdtAllMendngSttusGmtsckConfmAmount',
      '이사·감사 보수 (주주총회 승인금액)',
      people,
      1,
    ),
    DartSection.directorPayTotal: DartSectionInfo(
      'hmvAuditAllSttus',
      '이사·감사 보수 (지급금액 전체)',
      people,
      1,
    ),
    DartSection.directorPayByType: DartSectionInfo(
      'drctrAdtAllMendngSttusMendngPymntamtTyCl',
      '이사·감사 보수 (지급금액 유형별)',
      people,
      1,
    ),
    DartSection.directorPayIndividual: DartSectionInfo(
      'hmvAuditIndvdlBySttus',
      '이사·감사 개인별 보수 (5억원 이상)',
      people,
      1,
    ),
    DartSection.topFivePay: DartSectionInfo(
      'indvdlByPay',
      '개인별 보수 상위 5인 (5억원 이상)',
      people,
      1,
    ),
    DartSection.auditorOpinion: DartSectionInfo(
      'accnutAdtorNmNdAdtOpinion',
      '회계감사인과 감사의견',
      audit,
      1,
    ),
    DartSection.auditContract: DartSectionInfo(
      'adtServcCnclsSttus',
      '감사용역 체결현황',
      audit,
      1,
    ),
    DartSection.nonAuditContract: DartSectionInfo(
      'accnutAdtorNonAdtServcCnclsSttus',
      '비감사용역 계약체결 현황',
      audit,
      1,
    ),
    DartSection.debtIssuance: DartSectionInfo(
      'detScritsIsuAcmslt',
      '채무증권 발행실적',
      debt,
      1,
    ),
    DartSection.commercialPaperBalance: DartSectionInfo(
      'entrprsBilScritsNrdmpBlce',
      '기업어음증권 미상환 잔액',
      debt,
      1,
    ),
    DartSection.shortTermBondBalance: DartSectionInfo(
      'srtpdPsndbtNrdmpBlce',
      '단기사채 미상환 잔액',
      debt,
      1,
    ),
    DartSection.corporateBondBalance: DartSectionInfo(
      'cprndNrdmpBlce',
      '회사채 미상환 잔액',
      debt,
      1,
    ),
    DartSection.hybridCapitalBalance: DartSectionInfo(
      'newCaplScritsNrdmpBlce',
      '신종자본증권 미상환 잔액',
      debt,
      1,
    ),
    DartSection.contingentCapitalBalance: DartSectionInfo(
      'cndlCaplScritsNrdmpBlce',
      '조건부 자본증권 미상환 잔액',
      debt,
      1,
    ),
    DartSection.publicFundUse: DartSectionInfo(
      'pssrpCptalUseDtls',
      '공모자금의 사용내역',
      debt,
      1,
    ),
    DartSection.privateFundUse: DartSectionInfo(
      'prvsrpCptalUseDtls',
      '사모자금의 사용내역',
      debt,
      1,
    ),
    // 주요정보 API가 아니라 공시 원본 파일(document.xml)에서 본문을 뽑는다. 보고서당 1회.
    DartSection.businessContent: DartSectionInfo(
      'document',
      '사업의 내용',
      business,
      2,
    ),
  };

  static DartSectionInfo of(DartSection s) => info[s]!;

  /// 모든 응답 행에 붙는 공통 필드. 표에는 보여 주지 않는다.
  static const commonFields = {
    'rcept_no',
    'corp_cls',
    'corp_code',
    'corp_name',
    'stlm_dt',
  };

  /// 응답 필드 → 한글 머리글. 없는 필드는 필드 이름 그대로 보여 준다.
  /// 표본 응답의 필드와 OpenDART 개발가이드의 항목명을 따랐다.
  static const fieldLabels = <String, String>{
    // 공통으로 자주 쓰는 필드
    'se': '구분',
    'rm': '비고',
    'nm': '성명',
    'ofcps': '직위',
    'sexdstn': '성별',
    'stock_knd': '주식 종류',
    'bsns_year': '사업연도',
    'fscl_year': '회계연도',
    'nmpr': '인원수',
    'sm': '합계',
    // 주식의 총수
    'isu_stock_totqy': '발행할 주식의 총수',
    'now_to_isu_stock_totqy': '현재까지 발행한 주식의 총수',
    'now_to_dcrs_stock_totqy': '현재까지 감소한 주식의 총수',
    'redc': '감자',
    'profit_incnr': '이익소각',
    'rdmstk_repy': '상환주식의 상환',
    'etc': '기타',
    'istc_totqy': '발행주식의 총수',
    'tesstk_co': '자기주식수',
    'distb_stock_co': '유통주식수',
    // 자기주식
    'acqs_mth1': '취득방법 대분류',
    'acqs_mth2': '취득방법 중분류',
    'acqs_mth3': '취득방법 소분류',
    'bsis_qy': '기초 수량',
    'change_qy_acqs': '취득',
    'change_qy_dsps': '처분',
    'change_qy_incnr': '소각',
    'trmend_qy': '기말 수량',
    // 배당
    'thstrm': '당기',
    'frmtrm': '전기',
    'lwfr': '전전기',
    // 증자(감자)
    'isu_dcrs_de': '주식발행(감소)일자',
    'isu_dcrs_stle': '발행(감소) 형태',
    'isu_dcrs_stock_knd': '주식 종류',
    'isu_dcrs_qy': '수량',
    'isu_dcrs_mstvdv_fval_amount': '주당 액면가액',
    'isu_dcrs_mstvdv_amount': '주당 발행(감소)가액',
    // 채무증권
    'isu_cmpny': '발행회사',
    'scrits_knd_nm': '증권 종류',
    'isu_mth_nm': '발행방법',
    'isu_de': '발행일자',
    'facvalu_totamt': '권면(전자등록) 총액',
    'intrt': '이자율',
    'evl_grad_instt': '평가등급(평가기관)',
    'mtd': '만기일',
    'repy_at': '상환여부',
    'mngt_cmpny': '주관회사',
    // 미상환 잔액
    'remndr_exprtn1': '잔여만기',
    'remndr_exprtn2': '구분',
    'de10_below': '10일 이하',
    'de10_excess_de30_below': '10일~30일',
    'de30_excess_de90_below': '30일~90일',
    'de90_excess_de180_below': '90일~180일',
    'de180_excess_yy1_below': '180일~1년',
    'yy1_below': '1년 이하',
    'yy1_excess_yy2_below': '1년~2년',
    'yy2_excess_yy3_below': '2년~3년',
    'yy3_excess': '3년 초과',
    'yy3_excess_yy4_below': '3년~4년',
    'yy4_excess_yy5_below': '4년~5년',
    'yy1_excess_yy5_below': '1년~5년',
    'yy5_excess_yy10_below': '5년~10년',
    'yy10_excess': '10년 초과',
    'yy10_excess_yy15_below': '10년~15년',
    'yy10_excess_yy20_below': '10년~20년',
    'yy15_excess_yy20_below': '15년~20년',
    'yy20_excess_yy30_below': '20년~30년',
    'yy30_excess': '30년 초과',
    'isu_lmt': '발행 한도',
    'remndr_lmt': '잔여 한도',
    // 자금 사용
    'se_nm': '구분',
    'tm': '회차',
    'pay_de': '납입일',
    'pay_amount': '납입금액',
    'on_dclrt_cptal_use_plan': '신고서상 자금사용 계획',
    'real_cptal_use_sttus': '실제 자금사용 현황',
    'rs_cptal_use_plan_useprps': '증권신고서 등 자금사용 계획 (용도)',
    'rs_cptal_use_plan_prcure_amount': '증권신고서 등 자금사용 계획 (조달금액)',
    'real_cptal_use_dtls_cn': '실제 자금사용 내역 (내용)',
    'real_cptal_use_dtls_amount': '실제 자금사용 내역 (금액)',
    'dffrnc_occrrnc_resn': '차이발생 사유',
    'cptal_use_plan': '자금사용 계획',
    'mtrpt_cptal_use_plan_useprps': '주요사항보고서 자금사용 계획 (용도)',
    'mtrpt_cptal_use_plan_prcure_amount': '주요사항보고서 자금사용 계획 (조달금액)',
    // 감사
    'adtor': '감사인',
    'adt_opinion': '감사의견',
    'adt_reprt_spcmnt_matter': '감사보고서 특기사항',
    'emphs_matter': '강조사항 등',
    'core_adt_matter': '핵심감사사항',
    'cn': '내용',
    'mendng': '보수',
    'tot_reqre_time': '총 소요시간',
    'adt_cntrct_dtls_mendng': '감사계약 보수',
    'adt_cntrct_dtls_time': '감사계약 시간',
    'real_exc_dtls_mendng': '실제수행 보수',
    'real_exc_dtls_time': '실제수행 시간',
    'cntrct_cncls_de': '계약체결일',
    'servc_cn': '용역내용',
    'servc_exc_pd': '용역수행기간',
    'servc_mendng': '용역보수',
    // 사외이사
    'drctr_co': '이사의 수',
    'otcmp_drctr_co': '사외이사 수',
    'apnt': '선임',
    'rlsofc': '해임',
    'mdstrm_resig': '중도퇴임',
    // 최대주주
    'relate': '관계',
    'bsis_posesn_stock_co': '기초 소유주식수',
    'bsis_posesn_stock_qota_rt': '기초 지분율',
    'trmend_posesn_stock_co': '기말 소유주식수',
    'trmend_posesn_stock_qota_rt': '기말 지분율',
    'change_on': '변동일',
    'mxmm_shrholdr_nm': '최대주주명',
    'posesn_stock_co': '소유주식수',
    'qota_rt': '지분율',
    'change_cause': '변동원인',
    // 소액주주
    'shrholdr_co': '소액주주 수',
    'shrholdr_tot_co': '전체 주주 수',
    'shrholdr_rate': '주주 비율',
    'hold_stock_co': '소액주주 보유주식수',
    'stock_tot_co': '총발행주식수',
    'hold_stock_rate': '보유주식 비율',
    // 임원
    'birth_ym': '출생년월',
    'rgist_exctv_at': '등기임원 여부',
    'fte_at': '상근 여부',
    'chrg_job': '담당업무',
    'main_career': '주요경력',
    'mxmm_shrholdr_relate': '최대주주와의 관계',
    'hffc_pd': '재직기간',
    'tenure_end_on': '임기만료일',
    // 직원
    'fo_bbm': '사업부문',
    'reform_bfe_emp_co_rgllbr': '(개정 전) 정규직',
    'reform_bfe_emp_co_cnttk': '(개정 전) 계약직',
    'reform_bfe_emp_co_etc': '(개정 전) 기타',
    'rgllbr_co': '정규직 수',
    'rgllbr_abacpt_labrr_co': '정규직 단시간 근로자',
    'cnttk_co': '계약직 수',
    'cnttk_abacpt_labrr_co': '계약직 단시간 근로자',
    'avrg_cnwk_sdytrn': '평균 근속연수',
    'fyer_salary_totamt': '연간 급여 총액',
    'jan_salary_am': '1인 평균 급여액',
    // 보수
    'gmtsck_confm_amount': '주주총회 승인금액',
    'jan_avrg_mendng_am': '1인 평균 보수액',
    'mendng_totamt': '보수 총액',
    'pymnt_totamt': '보수 총액',
    'psn1_avrg_pymntamt': '1인 평균 보수액',
    'mendng_totamt_ct_incls_mendng': '보수 총액에 포함되지 않는 보수',
    'stk_bsd_pd_mendng_totamt': '주식기준보상 총액',
    'stk_opt_exrcsbl_qty': '주식매수선택권 행사가능 수량',
    'stk_opt_unexrcsbl_qty': '주식매수선택권 행사불가 수량',
    'stk_opt_rmn_blce': '주식매수선택권 잔액',
    'othr_stk_bsd_cmpn_unpyd_qty': '기타 주식기준보상 미지급 수량',
    'othr_stk_bsd_cmpn_mkt_vl': '기타 주식기준보상 시장가치',
    // 타법인 출자
    'inv_prm': '법인명',
    'frst_acqs_de': '최초 취득일자',
    'invstmnt_purps': '출자 목적',
    'frst_acqs_amount': '최초 취득금액',
    'bsis_blce_qy': '기초 수량',
    'bsis_blce_qota_rt': '기초 지분율',
    'bsis_blce_acntbk_amount': '기초 장부가액',
    'incrs_dcrs_acqs_dsps_qy': '증감 취득(처분) 수량',
    'incrs_dcrs_acqs_dsps_amount': '증감 취득(처분) 금액',
    'incrs_dcrs_evl_lstmn': '증감 평가손익',
    'trmend_blce_qy': '기말 수량',
    'trmend_blce_qota_rt': '기말 지분율',
    'trmend_blce_acntbk_amount': '기말 장부가액',
    'recent_bsns_year_fnnr_sttus_tot_assets': '최근 사업연도 총자산',
    'recent_bsns_year_fnnr_sttus_thstrm_ntpf': '최근 사업연도 당기순손익',
  };

  static String fieldLabel(String field) => fieldLabels[field] ?? field;
}
