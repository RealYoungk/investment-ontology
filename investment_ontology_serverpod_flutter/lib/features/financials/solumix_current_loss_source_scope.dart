import 'dart:convert';

/// Exact original own filing; signed losses retain positive printed source cells.
abstract final class SolumixCurrentLossSourceScope {
  static final Map _profile = jsonDecode(
    r'''{"receipt":"20250407004339","sourceReceipt":"20250407004208","corp":"01118643","name":"(주)솔루믹스","year":2024,"basis":"separate","rule":"located-own-printed-loss-current-eight-v1","directory":"assets/financial_source_cache/20250407004339-ofs-located-own-loss-eight","digest":"615bc8f19c7d862d4a94756b632665666d9c225117f009e435adeee7aa8116d9","sourceDigest":"d748fcf7ba86e0755b448d49d969611582c60bd4c3914db93cab8b6c5051e998","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250407004208&dcmNo=10552128&eleId=21&offset=535164&length=43797&dtd=dart4.xsd","statementSHA":"13f346389d0f93f9b5b2abc9d89c2547540afd5a1c595cfcc78471a24a71bfb7","periodStart":"2024-01-01","periodEnd":"2024-12-31","lossMagnitudeKeys":["operatingIncome","netIncome"],"ownCoverActor":"주식회사로보쓰리에이아이","ownIssuerFilingSeriesEvidence":{"policy":"exact-own-filing-series-current-rows-v1","identityScope":"official-DART-filing-series-only","ownCoverActor":"주식회사로보쓰리에이아이","currentName":"(주)솔루믹스","corpCode":"01118643","ownShellCorpProof":"01118643","sourceReceipt":"20250407004208","targetReceipt":"20250407004339","ownShellSource":"https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250407004208","ownShellSha256":"27eb1cab4b657d8a350cadb047e7743ecb47e75244818c9b31491540b954243b","coverSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250407004208&dcmNo=10552128&eleId=1&offset=959&length=4494&dtd=dart4.xsd","coverSha256":"87f8d01b836a114296f1702e109f5665767bfdac20384503c6a48863a40f456e","jurirContinuityVerified":false,"operatingHistoryContinuityVerified":false},"coreCells":[{"table":1,"row":17,"column":2,"label":"자산총계","literal":"6,748,542,446","value":6748542446,"key":"assets","derivedInterpretation":6748542446,"signRule":"none","kind":"BS","signNormalization":"none"},{"table":1,"row":31,"column":2,"label":"부채총계","literal":"5,130,649,389","value":5130649389,"key":"liabilities","derivedInterpretation":5130649389,"signRule":"none","kind":"BS","signNormalization":"none"},{"table":1,"row":37,"column":2,"label":"자본총계","literal":"1,617,893,057","value":1617893057,"key":"equity","derivedInterpretation":1617893057,"signRule":"none","kind":"BS","signNormalization":"none"},{"table":4,"row":1,"column":2,"label":"I.매출액","literal":"579,284,000","value":579284000,"key":"revenue","derivedInterpretation":579284000,"signRule":"none","kind":"CIS","signNormalization":"none"},{"table":4,"row":5,"column":2,"label":"IV.영업손실","literal":"1,541,424,780","value":1541424780,"key":"operatingIncome","derivedInterpretation":-1541424780,"signRule":"explicitLossMagnitudeOnly","kind":"CIS","signNormalization":"explicitPrintedLossMagnitudeCorroborated"},{"table":4,"row":13,"column":2,"label":"VII.당기순손실","literal":"15,048,850,696","value":15048850696,"key":"netIncome","derivedInterpretation":-15048850696,"signRule":"explicitLossMagnitudeOnly","kind":"CIS","signNormalization":"explicitPrintedLossMagnitudeCorroborated"},{"table":10,"row":1,"column":2,"label":"I.영업활동으로인한현금흐름","literal":"(1,615,783,238)","value":-1615783238,"key":"operatingCashFlow","derivedInterpretation":-1615783238,"signRule":"none","kind":"CF","signNormalization":"none"},{"table":10,"row":24,"column":2,"label":"유형자산의취득","literal":"195,994,915","value":195994915,"key":"capex","derivedInterpretation":195994915,"signRule":"none","kind":"CF","signNormalization":"none"}]}''',
  ) as Map;
  static String? message(Map value) {
    final p = _profile;
    if (value['action'] != 'verified-keyless-annual-source-after-api-noData' ||
        value['targetReceipt'] != p['receipt'] ||
        value['sourceReceipt'] != p['sourceReceipt'] ||
        value['corpCode'] != p['corp'] ||
        value['fsDiv'] != 'separate' ||
        value['coreRows'] != 8) {
      return null;
    }
    final rows = value['coreRowProvenance'];
    if (rows is! List || rows.length != 8) {
      return null;
    }
    for (var i = 0; i < 8; i++) {
      final r = rows[i], c = p['coreCells'][i];
      final loss =
          c['signNormalization'] == 'explicitPrintedLossMagnitudeCorroborated';
      final signed =
          (loss ? '-' : '') +
          (c['literal'] as String)
              .replaceAll(',', '')
              .replaceAll('(', '-')
              .replaceAll(')', '');
      if (r is! Map ||
          r['account_nm'] != c['label'] ||
          r['account_id'] != null ||
          r['currency'] != 'KRW' ||
          r['thstrm_amount'] != signed ||
          r['html_provenance'] is! Map) {
        return null;
      }
      final v = r['html_provenance'] as Map;
      if (v['ruleVersion'] != p['rule'] ||
          v['source'] != p['statementURI'] ||
          v['sourceSha256'] != p['statementSHA'] ||
          v['sourceReceipt'] != p['sourceReceipt'] ||
          v['targetReceipt'] != p['receipt'] ||
          v['tableIndex'] != c['table'] ||
          v['rowIndex'] != c['row'] ||
          v['currentColumn'] != c['column'] ||
          v['printedLabel'] != c['label'] ||
          v['printedAmount'] != c['literal'] ||
          v['unit'] != '원' ||
          v['unitMultiplier'] != '1' ||
          v['periodStart'] != p['periodStart'] ||
          v['periodEnd'] != p['periodEnd'] ||
          v['currentCore8'] != true ||
          v['fullStatementVerified'] != false ||
          v['notesVerified'] != false ||
          v['detailEnrichmentApproved'] != false ||
          v['sourceCellRewritten'] != false ||
          v['printedLossSourceOwnOnly'] != true ||
          v['signNormalization'] != c['signNormalization'] ||
          v['derivedSignedAmount'] != signed ||
          v['sourceMainEquationCount'] != 18 ||
          v['printedFxDashIsNumericZero'] != false ||
          jsonEncode(v['ownIssuerFilingSeriesEvidence']) !=
              jsonEncode(p['ownIssuerFilingSeriesEvidence'])) {
        return null;
      }
    }
    return '자체 공식 원문의 당기 핵심 8개 계정만 검증했습니다. 양수로 인쇄된 영업손실·순손실 크기는 손실 라벨과 자체 손익 산식·음수 자본변동표·현금흐름표로 확인해 음수 부호를 적용하고 원문 셀은 보존합니다. 인쇄 회사명 로보쓰리에이아이와 현재명 솔루믹스는 동일 공시 법인코드의 해당 보고서 범위에서만 확인했으며 법인·사업 연혁의 연속성을 주장하지 않습니다. 전기 비교 셀 오기는 수정하지 않았으며 전체 상세 계정·주석 검증은 완료하지 않았습니다.';
  }
}
