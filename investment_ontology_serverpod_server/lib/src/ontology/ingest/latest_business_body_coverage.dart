/// 최신접수 본문 또는 공식 가족목록으로 확인한 원접수 본문의 읽기 지표.
/// 원접수/본문/Source를 변경하지 않으며, 임의 동일기간 재사용은 허용하지 않는다.
abstract final class LatestBusinessBodyCoverage {
  static const verifiedFamilies = '''
    VALUES
      ('20260814003889','20260814002623','00123772','2026.06',2026,'halfYear'),
      ('20260814004068','20260814002334','00583026','2026.06',2026,'halfYear'),
      ('20260929000169','20260814002367','00858124','2026.06',2026,'halfYear'),
      ('20260324000715','20260323000900','00929228','2025.12',2025,'annual'),
      ('20260318000344','20260317000808','00963000','2025.12',2025,'annual'),
      ('20260323001059','20260323000299','00978075','2025.12',2025,'annual'),
      ('20260820000112','20260814003090','01021949','2026.06',2026,'halfYear'),
      ('20260429001010','20260429000962','01188749','2025.12',2025,'annual'),
      ('20260323000764','20260323000737','01229240','2025.12',2025,'annual'),
      ('20260324000268','20260318001150','01328170','2025.12',2025,'annual')
  ''';

  /// [filing]은 coverage의 latest DartFiling 별칭이다.
  static String existsSql(String filing) =>
      '''
    EXISTS (
      SELECT 1 FROM dart_filing_section s
      JOIN disclosure_report d ON d."companyId"=s."companyId"
        AND d."bsnsYear"=s."bsnsYear" AND d."reportCode"=$filing."reportCode"
        AND d.section='businessContent'
      JOIN business_document b ON b."reportId"=d.id AND d."rceptNo"=b."rceptNo"
      JOIN company bc ON bc.id=b."companyId" AND bc."corpCode"=$filing."corpCode"
      JOIN source src ON src.id=d."sourceId" AND src.kind='dartReport'
        AND src.reference=b."rceptNo"
        AND (src.url='https://dart.fss.or.kr/dsaf001/main.do?rcpNo='||b."rceptNo"
          OR src.url ~ ('^https://dart[.]fss[.]or[.]kr/report/viewer[.]do[?]rcpNo='||b."rceptNo"||
            '&dcmNo=[0-9]+&eleId=[0-9]+&offset=[0-9]+&length=[1-9][0-9]*&dtd=dart[34][.]xsd' || chr(36)))
      JOIN dart_filing sf ON sf."rceptNo"=b."rceptNo"
        AND sf."companyId"=$filing."companyId" AND sf."corpCode"=$filing."corpCode"
        AND sf."bsnsYear"=$filing."bsnsYear" AND sf."reportCode"=$filing."reportCode"
      WHERE s."filingId"=$filing.id AND s.section='businessContent' AND s.status='stored'
        AND s."companyId"=$filing."companyId" AND s."bsnsYear"=$filing."bsnsYear"
        AND b."companyId"=$filing."companyId" AND b."bsnsYear"=$filing."bsnsYear"
        AND b."charCount">0 AND length(trim(b.text))>0
        AND substring(sf."reportName" from '[0-9]{4}[.][0-9]{2}')=
          substring($filing."reportName" from '[0-9]{4}[.][0-9]{2}')
        AND CASE $filing."reportCode"
          WHEN 'annual' THEN sf."reportName" LIKE '%사업보고서 (%' AND $filing."reportName" LIKE '%사업보고서 (%'
          WHEN 'halfYear' THEN sf."reportName" LIKE '%반기보고서 (%' AND $filing."reportName" LIKE '%반기보고서 (%'
          ELSE sf."reportName" LIKE '%분기보고서 (%' AND $filing."reportName" LIKE '%분기보고서 (%' END
        AND (b."rceptNo"=$filing."rceptNo" OR
          ($filing."reportName" LIKE '%첨부정정%' AND EXISTS (
            SELECT 1 FROM ($verifiedFamilies)
              AS p(target_receipt,source_receipt,corp,period,year,code)
            WHERE p.target_receipt=$filing."rceptNo" AND p.source_receipt=b."rceptNo"
              AND p.corp=$filing."corpCode" AND p.year=$filing."bsnsYear"
              AND p.code=$filing."reportCode"
              AND p.period=substring($filing."reportName" from '[0-9]{4}[.][0-9]{2}')
              AND b."rceptNo"<$filing."rceptNo"
          )))
    )
  ''';
}
