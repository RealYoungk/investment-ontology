import 'dart:convert';

import '../../generated/protocol.dart';
import '../dart/located_own_current_source.dart';

/// Exact own annotated PL net income, independently matching own CE and CF.
/// No stored name/ID rewriting and no global product-revenue alias.
abstract final class HanwhaOwnNetIncomeScope {
  static const receipt = '20230314000604';
  static const corp = '00148610';
  static const year = 2022;
  static const label =
      "VIII.당기순손익(대손준비금반영후조정손익당기:-26,558,393,256원전기:139,504,588,566원전전기:55,820,612,484원)";
  static final amount = BigInt.from(-23530284903);
  static Map<String, dynamic> get profile => Map<String, dynamic>.from(
    LocatedOwnCurrentSource.profiles.singleWhere(
      (p) => p['receipt'] == receipt && p['basis'] == 'separate',
    ) as Map,
  );
  static String get url => profile['statementURI'] as String;
  static String get digest => profile['sourceDigest'] as String;
  static List<Map<String, dynamic>> get expectedRows => (jsonDecode(
    r'''[{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"BS","account_id":null,"account_nm":"자산총계","ord":"20","thstrm_nm":"당기","thstrm_dt":"2022-12-31","thstrm_amount":"11109693898660","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"자산총계","printedAmount":"11,109,693,898,660","htmlTrIndex":19,"tableIndex":1,"rowIndex":14,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}},{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"BS","account_id":null,"account_nm":"부채총계","ord":"34","thstrm_nm":"당기","thstrm_dt":"2022-12-31","thstrm_amount":"9524691995176","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"부채총계","printedAmount":"9,524,691,995,176","htmlTrIndex":33,"tableIndex":1,"rowIndex":28,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}},{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"BS","account_id":null,"account_nm":"자본총계","ord":"41","thstrm_nm":"당기","thstrm_dt":"2022-12-31","thstrm_amount":"1585001903484","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"자본총계","printedAmount":"1,585,001,903,484","htmlTrIndex":40,"tableIndex":1,"rowIndex":35,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}},{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"CIS","account_id":null,"account_nm":"I.영업수익","ord":"49","thstrm_nm":"당기","thstrm_dt":"2022-01-01~2022-12-31","thstrm_amount":"2059136420659","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"I.영업수익","printedAmount":"2,059,136,420,659","htmlTrIndex":48,"tableIndex":3,"rowIndex":1,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}},{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"CIS","account_id":null,"account_nm":"III.영업손익","ord":"67","thstrm_nm":"당기","thstrm_dt":"2022-01-01~2022-12-31","thstrm_amount":"53860324418","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"III.영업손익","printedAmount":"53,860,324,418","htmlTrIndex":66,"tableIndex":3,"rowIndex":19,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}},{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"CIS","account_id":null,"account_nm":"VIII.당기순손익(대손준비금반영후조정손익당기:-26,558,393,256원전기:139,504,588,566원전전기:55,820,612,484원)","ord":"72","thstrm_nm":"당기","thstrm_dt":"2022-01-01~2022-12-31","thstrm_amount":"-23530284903","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"VIII.당기순손익(대손준비금반영후조정손익당기:-26,558,393,256원전기:139,504,588,566원전전기:55,820,612,484원)","printedAmount":"-23,530,284,903","htmlTrIndex":71,"tableIndex":3,"rowIndex":24,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}},{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"CF","account_id":null,"account_nm":"I.영업활동으로인한현금흐름","ord":"119","thstrm_nm":"당기","thstrm_dt":"2022-01-01~2022-12-31","thstrm_amount":"287695588326","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"I.영업활동으로인한현금흐름","printedAmount":"287,695,588,326","htmlTrIndex":118,"tableIndex":7,"rowIndex":1,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}},{"rcept_no":"20230314000604","corp_code":"00148610","bsns_year":"2022","reprt_code":"11011","fs_div":"OFS","sj_div":"CF","account_id":null,"account_nm":"유형자산의취득","ord":"196","thstrm_nm":"당기","thstrm_dt":"2022-01-01~2022-12-31","thstrm_amount":"-9379614884","currency":"KRW","html_provenance":{"ruleVersion":"located-own-current-eight-v1","source":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","sourceReceipt":"20230314000604","targetReceipt":"20230314000604","sourceSha256":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","printedLabel":"유형자산의취득","printedAmount":"-9,379,614,884","htmlTrIndex":195,"tableIndex":7,"rowIndex":78,"currentColumn":1,"unit":"원","unitMultiplier":"1","basis":"OFS","periodStart":"2022-01-01","periodEnd":"2022-12-31","currentCore8":true,"wholeNetIncomeExact":true,"sameUnitCurrentMainEquationsExact":true,"printedEquationCount":6,"ceRollFullyNumericVerified":false,"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}],"fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"notesVerified":false,"detailEnrichmentApproved":false,"detailHierarchyVerified":false,"sourceDetailAnomalies":[],"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"summaryPrecisionSourceNotUsed":true,"supportingNoteSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=20&offset=1666966&length=881286&dtd=dart3.xsd","supportingNoteSha256":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","supportingNoteScope":"Own note cash/deposits current/prior subtotal bridges only in printed thousand-won; main KRW literal remainders retained; CE current movement two dash total cells unverified, never zero.","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"sourceCaptionDifference":null,"crossPrecisionEqualityClaim":false,"roundingCauseInferred":false,"sourceScopeNotice":"당기 핵심 8개 계정과 주요 검산 6개, 해당 공시 현금 주석의 당기·전기 천원 소계만 검증했습니다. 원·천원 금액 차이와 자본변동표의 인쇄 대시를 그대로 보존하며 반올림 원인·전체 자본변동 검산을 추정하지 않습니다. 전체 계정·주석 수집 완료가 아닙니다."}}]''',
  ) as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
  static const reportNames = ['사업보고서 (2022.12)', '[기재정정]사업보고서 (2022.12)'];
  static Map<String, dynamic> get proof => {
    'action': 'verified-exact-filing-series-whole-annotated-net-income',
    'receipt': receipt,
    'targetReceipt': receipt,
    'sourceReceipt': receipt,
    'corpCode': corp,
    'year': year,
    'fsDiv': 'separate',
    'source': url,
    'sha256': digest,
    'ruleVersion': LocatedOwnCurrentSource.rule,
    'coreRows': 8,
    'coreRowProvenance': expectedRows,
    'wholeNetIncomeLabel': label,
    'wholeNetIncomeAmount': amount.toString(),
    'fullyNumericMainEquationCount': 6,
    'CErollFullyNumericVerified': false,
    'CEMissingTotalCells':
        expectedRows.first['html_provenance']['ceMissingCurrentTotalCells'],
    'crossPrecisionLiteralRemainders': [-747, -393, -40, -78],
    'crossPrecisionEqualityClaim': false,
    'roundingCauseInferred': false,
    'fullStatementCollected': false,
    'notesVerified': false,
  };
  static String sourceTitle(String reportName) =>
      'DART 원문 HTML 부분 핵심계정(실제 인쇄 계정명, XBRL 계정 ID 미제공) · $reportName · 별도 · SHA256:$digest · ${jsonEncode(proof)}';

  static Map<String, dynamic>? storedScope({
    required List<Map<String, dynamic>> rows,
    required String receipt,
    required String corp,
    required String companyName,
    required bool consolidated,
    required Uri? source,
    required String? digest,
    required String reportName,
  }) {
    if (receipt != HanwhaOwnNetIncomeScope.receipt ||
        corp != HanwhaOwnNetIncomeScope.corp ||
        companyName != profile['name'] ||
        consolidated ||
        source?.toString() != url ||
        digest != HanwhaOwnNetIncomeScope.digest ||
        !reportNames.contains(reportName) ||
        jsonEncode(rows) != jsonEncode(expectedRows)) {
      return null;
    }
    return proof;
  }

  static bool validSource(Company c, FinancialReport r, Source s) =>
      c.id != null &&
      r.id != null &&
      s.id != null &&
      c.corpCode == corp &&
      c.name == profile['name'] &&
      r.companyId == c.id &&
      r.rceptNo == receipt &&
      r.bsnsYear == year &&
      r.reportCode == FinancialReportCode.annual &&
      r.fsDiv == FsDiv.separate &&
      r.factCount == 8 &&
      r.supersededById == null &&
      r.sourceId == s.id &&
      s.kind == SourceKind.dartReport &&
      s.reference == receipt &&
      s.url == url &&
      reportNames.contains(r.reportName) &&
      s.title == sourceTitle(r.reportName);
  static bool candidate(FinancialFact f, Company c, FinancialReport r) =>
      f.reportId == r.id &&
      f.companyId == c.id &&
      f.sourceId == r.sourceId &&
      f.bsnsYear == r.bsnsYear &&
      f.reportCode == r.reportCode &&
      f.fsDiv == r.fsDiv &&
      f.accountId == null &&
      f.accountName == label &&
      f.statement == FinancialStatementKind.comprehensiveIncome &&
      f.accountDetail == null &&
      f.supersededById == null;

  static bool validFact(
    FinancialFact f,
    Company c,
    FinancialReport r,
    Source s,
  ) =>
      validSource(c, r, s) &&
      f.id != null &&
      f.reportId == r.id &&
      f.companyId == c.id &&
      f.sourceId == s.id &&
      f.bsnsYear == year &&
      f.reportCode == FinancialReportCode.annual &&
      f.fsDiv == FsDiv.separate &&
      f.statement == FinancialStatementKind.comprehensiveIncome &&
      f.accountId == null &&
      f.accountDetail == null &&
      f.supersededById == null &&
      f.currency == 'KRW' &&
      f.accountName == label &&
      f.amount == amount &&
      f.cumulativeAmount == null &&
      f.priorAmount == null &&
      f.priorCumulativeAmount == null &&
      f.priorQuarterAmount == null &&
      f.beforePriorAmount == null &&
      f.ord == 72 &&
      f.periodName == '2022-01-01~2022-12-31';

  static bool validStandardApiSource(Company c, FinancialReport r, Source s) =>
      c.id != null &&
      r.id != null &&
      s.id != null &&
      c.corpCode == corp &&
      c.name == profile['name'] &&
      r.companyId == c.id &&
      r.rceptNo == receipt &&
      r.bsnsYear == year &&
      r.reportCode == FinancialReportCode.annual &&
      r.fsDiv == FsDiv.separate &&
      r.supersededById == null &&
      r.sourceId == s.id &&
      s.kind == SourceKind.dartReport &&
      s.reference == receipt &&
      s.url == 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt' &&
      reportNames.contains(r.reportName) &&
      s.title == 'DART 전체 재무제표 (fnlttSinglAcntAll) · ${r.reportName} · 별도';
  static String boundReportSql(String f) =>
      "EXISTS (SELECT 1 FROM financial_report hb WHERE hb.id=$f.\"reportId\" AND hb.\"rceptNo\"='$receipt' AND hb.\"fsDiv\"='separate')";
  static String standardApiSql(String f) {
    final titles = reportNames
        .map(
          (n) =>
              "(hr.\"reportName\"=${_quote(n)} AND hs.title=${_quote('DART 전체 재무제표 (fnlttSinglAcntAll) · $n · 별도')})",
        )
        .join(' OR ');
    return "EXISTS (SELECT 1 FROM financial_report hr JOIN company hc ON hc.id=hr.\"companyId\" JOIN source hs ON hs.id=hr.\"sourceId\" WHERE hr.id=$f.\"reportId\" AND hc.id=$f.\"companyId\" AND hr.\"sourceId\"=$f.\"sourceId\" AND hc.\"corpCode\"='$corp' AND hc.name=${_quote(profile['name'] as String)} AND hr.\"rceptNo\"='$receipt' AND hr.\"bsnsYear\"=$year AND hr.\"reportCode\"='annual' AND hr.\"fsDiv\"='separate' AND hr.\"supersededById\" IS NULL AND hs.kind='dartReport' AND hs.reference='$receipt' AND hs.url='https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt' AND ($titles))";
  }

  static String _quote(String s) => "'${s.replaceAll("'", "''")}'";

  /// Shares all stable Source title/owner pins with the public read selector.
  static String sqlCondition(String f) {
    final names = reportNames.map(_quote).join(',');
    final titles = reportNames
        .map(
          (n) =>
              "(r.\"reportName\"=${_quote(n)} AND s.title=${_quote(sourceTitle(n))})",
        )
        .join(' OR ');
    return '''$f."accountId" IS NULL AND $f."accountName"=${_quote(label)} AND $f.statement='comprehensiveIncome' AND $f.amount::numeric=-23530284903 AND $f.ord=72 AND $f.currency='KRW' AND $f."accountDetail" IS NULL AND $f."supersededById" IS NULL AND $f."bsnsYear"=2022 AND $f."reportCode"='annual' AND $f."fsDiv"='separate' AND $f."cumulativeAmount" IS NULL AND $f."priorAmount" IS NULL AND $f."priorCumulativeAmount" IS NULL AND $f."priorQuarterAmount" IS NULL AND $f."beforePriorAmount" IS NULL AND $f."periodName"='2022-01-01~2022-12-31'
      AND EXISTS (SELECT 1 FROM financial_report r JOIN company c ON c.id=r."companyId" JOIN source s ON s.id=r."sourceId" WHERE r.id=$f."reportId" AND c.id=$f."companyId" AND c."corpCode"=${_quote(corp)} AND c.name=${_quote(profile['name'] as String)} AND r."rceptNo"=${_quote(receipt)} AND r."bsnsYear"=2022 AND r."reportCode"='annual' AND r."fsDiv"='separate' AND r."factCount"=8 AND r."supersededById" IS NULL AND r."sourceId"=$f."sourceId" AND s.kind='dartReport' AND s.reference=${_quote(receipt)} AND s.url=${_quote(url)} AND r."reportName" IN ($names) AND ($titles)
        AND (SELECT count(*) FROM financial_fact d WHERE d."reportId"=r.id AND d."sourceId"=s.id AND d."companyId"=c.id AND d."bsnsYear"=r."bsnsYear" AND d."reportCode"=r."reportCode" AND d."fsDiv"=r."fsDiv" AND d."accountId" IS NULL AND d."accountName"=${_quote(label)} AND d.statement='comprehensiveIncome' AND d."accountDetail" IS NULL AND d."supersededById" IS NULL)=1)''';
  }
}
