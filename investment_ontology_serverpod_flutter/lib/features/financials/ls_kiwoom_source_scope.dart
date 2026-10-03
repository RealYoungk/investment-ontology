import 'dart:convert';

/// Five fixed current own-source contracts. Unknown provenance never implies
/// whole statements, a cross-precision equality or a historical issuer alias.
abstract final class LsKiwoomSourceScope {
  static final Map _contracts = jsonDecode(
    r'''{"20220324000600:consolidated": {"corp": "00296290", "year": 2021, "rule": "kiwoom-2021-own-cfs-current-eight-v1", "uri": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220324000600&dcmNo=8502035&eleId=19&offset=912123&length=103978&dtd=dart3.xsd", "sha": "ae5d0f8cbff86058ceb9819c801e302b06eed5b7b221834ac7caadba14a32cf1", "noteURI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220324000600&dcmNo=8502035&eleId=20&offset=1016105&length=1084531&dtd=dart3.xsd", "noteSHA": "0e6e482426b7eccb96b8fc5736312d17207368ddfb7673e90ca4089066f9e201", "count": 8}, "20230316001115:consolidated": {"corp": "00330424", "year": 2022, "rule": "ls-ebest-2022-own-cfs-current-seven-v1", "uri": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=17&offset=317594&length=51185&dtd=dart3.xsd", "sha": "8d44e40d162128bc586cb5eaaa9a3b265b9fefc9ec314d2fc32c1e1373ba4092", "noteURI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=18&offset=368783&length=1182206&dtd=dart3.xsd", "noteSHA": "4fa8d600d687caa71f84eb26c55b40b3377113f332eb058662f16cb90d1f5f35", "count": 7}, "20230316001115:separate": {"corp": "00330424", "year": 2022, "rule": "ls-ebest-2022-own-ofs-current-seven-v1", "uri": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=19&offset=1550993&length=49562&dtd=dart3.xsd", "sha": "9ddb6225c54b8354c06f53beff0d1a079ccff0552b7a7baeeb226555e4cf2ba3", "noteURI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=20&offset=1600559&length=1297367&dtd=dart3.xsd", "noteSHA": "9f4ec1b943d03c1a950386a406db341344a65e4296e401c899805c77355d362a", "count": 7}, "20220317000673:consolidated": {"corp": "00330424", "year": 2021, "rule": "ls-ebest-2021-own-cfs-current-seven-v1", "uri": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=17&offset=310337&length=50806&dtd=dart3.xsd", "sha": "d25c41ed9b04442c369574587e0ada0284289a519999d2906af66a68ae42aa8d", "noteURI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=18&offset=361147&length=1067963&dtd=dart3.xsd", "noteSHA": "435949050d81ff2a6678b428b6c021efe42417d6122ef308067e8dd91f7b9824", "count": 7}, "20220317000673:separate": {"corp": "00330424", "year": 2021, "rule": "ls-ebest-2021-own-ofs-current-seven-v1", "uri": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=19&offset=1429114&length=55332&dtd=dart3.xsd", "sha": "d84d32f7cc81af284c23b00448bcdbd944f1d4479469250c3338784d9e2b5107", "noteURI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=20&offset=1484450&length=1164331&dtd=dart3.xsd", "noteSHA": "b77eae291dad4095e6a8d0cf252dc152db86355e2c8ac98589cd6312d44a04db", "count": 7}}''',
  );

  static String? message(Map j) {
    final c = _contracts['${j['targetReceipt']}:${j['fsDiv']}'];
    if (c is! Map ||
        j['action'] != 'verified-keyless-annual-source-after-api-noData' ||
        j['corpCode'] != c['corp'] ||
        j['sourceReceipt'] != j['targetReceipt'] ||
        j['coreRows'] != c['count']) {
      return null;
    }
    final rows = j['coreRowProvenance'];
    if (rows is! List || rows.length != c['count']) return null;
    final eight = c['count'] == 8;
    for (final row in rows) {
      if (row is! Map) return null;
      final p = row['html_provenance'];
      if (p is! Map ||
          p['ruleVersion'] != c['rule'] ||
          p['source'] != c['uri'] ||
          p['sourceSha256'] != c['sha'] ||
          p['unit'] != '원' ||
          p['unitMultiplier'] != '1' ||
          p['periodStart'] != '${c['year']}-01-01' ||
          p['periodEnd'] != '${c['year']}-12-31' ||
          p['basis'] != (j['fsDiv'] == 'consolidated' ? 'CFS' : 'OFS') ||
          p['partialCore7'] != !eight ||
          p['currentCore8'] != eight ||
          p['wholeNetIncomeExact'] != true ||
          p['numericCellCorrection'] != false ||
          p['genericRoundingTolerance'] != false ||
          p['priorNumericPeriodsCollected'] != false ||
          p['fullStatementCollected'] != false ||
          p['fullStatementVerified'] != false ||
          p['allStatementRowsVerified'] != false ||
          p['notesVerified'] != false) {
        return null;
      }
      final optional = p['uncollectedOptionalAccounts'];
      if (optional is! List ||
          (eight
              ? optional.isNotEmpty
              : optional.length != 1 || optional.single != 'capex')) {
        return null;
      }
      final n = p['cashScopeEvidence'];
      if (n is! Map ||
          n['source'] != c['noteURI'] ||
          n['sha256'] != c['noteSHA'] ||
          n['receipt'] != j['targetReceipt'] ||
          n['corpCode'] != c['corp'] ||
          n['periodEnd'] != '${c['year']}-12-31' ||
          n['basis'] != p['basis'] ||
          n['printedUnit'] != '천원' ||
          n['statementUnit'] != '원' ||
          n['combinedSubtotalResidual'] != '0' ||
          n['depositDetailResidual'] != '0' ||
          n['cashDetailResidual'] != (eight ? '-1' : '0') ||
          n['crossPrecisionEqualityClaim'] != false ||
          n['roundingCauseClaim'] != false ||
          n['allNotesVerified'] != false) {
        return null;
      }
    }
    return eight
        ? '당기 핵심 8개 계정을 검증해 수집했습니다. 현금 주석은 천원, 재무제표는 원 단위이며 서로 정확히 같다고 주장하지 않습니다. 현금 주석의 세부 합계 차이 -1천원을 보존했습니다. 전체 세부 계정과 주석은 검증을 마치지 않았습니다.'
        : '당기 핵심 7개 계정을 검증해 수집했습니다. 전체 유형자산 취득액은 미확보이며 일부 자산 취득액으로 대신하지 않습니다. FCF와 FCF 수익률은 계산하지 않습니다. 현금 주석과 재무제표의 인쇄 단위 차이를 보존했고 전체 세부 계정과 주석은 검증을 마치지 않았습니다.';
  }
}
