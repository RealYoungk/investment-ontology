import 'dart:convert';

/// Three immutable own filing contracts; seven values do not imply whole coverage.
abstract final class LocatedOwnSevenSourceScope {
  static final List _profiles = jsonDecode(
    r'''[{"receipt":"20220322000802","corp":"01116344","name":"이비테크(주)","year":2021,"basis":"separate","sourceReceipt":"20220322000802","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20220322000802-ofs-located-own-seven","digest":"2485e6e119aa1b2a9d17bb177d2b33d5246ac0cef4aa3d6c7bb392c8684f344d","sourceDigest":"84d3e9dca89dfbb45b0b7ea3ddf31c5d5b7f63264c65007cdcd8382461cd7c62","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220322000802&dcmNo=8491700&eleId=21&offset=104211&length=61838&dtd=dart3.xsd","statementSHA":"461d7461a17ce3eae8b2af6347c9a524831a727e4249b75e3b0d972b80cc4167","periodStart":"2021-01-01","periodEnd":"2021-12-31","coverPeriodTokens":["2021년01월01일","2021년12월31일"],"coreCells":[{"table":1,"row":43,"column":2,"label":"자산총계","literal":"13,640,640,446","value":13640640446,"key":"assets","kind":"BS"},{"table":1,"row":57,"column":2,"label":"부채총계","literal":"1,932,480,266","value":1932480266,"key":"liabilities","kind":"BS"},{"table":1,"row":65,"column":2,"label":"자본총계","literal":"11,708,160,180","value":11708160180,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":2,"label":"Ⅰ.매출액","literal":"5,442,616,873","value":5442616873,"key":"revenue","kind":"CIS"},{"table":3,"row":35,"column":2,"label":"Ⅴ.영업이익","literal":"980,641,199","value":980641199,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":50,"column":2,"label":"Ⅹ.당기순이익","literal":"1,252,122,946","value":1252122946,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":2,"label":"Ⅰ.영업활동으로인한현금흐름","literal":"1,108,524,316","value":1108524316,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20250429000919","corp":"01366824","name":"(주)제이엠멀티","year":2024,"basis":"separate","sourceReceipt":"20250429000919","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20250429000919-ofs-located-own-seven","digest":"de0e64e1faf02a7dc3b8c48f4ae8e914cb2609daef747f712b60fab643ced49f","sourceDigest":"71dbd5715f71f7d9f2bd634ea79e09275deb361f3d9fccea0ad4b0a7bf9ea142","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250429000919&dcmNo=10622174&eleId=23&offset=497606&length=92172&dtd=dart4.xsd","statementSHA":"f8d6476b43a84323bc9819bf4e269b5a0d141a97c0334f1917f1e83e53c59a75","periodStart":"2024-01-01","periodEnd":"2024-12-31","coverPeriodTokens":["2024년01월01일","2024년12월31일"],"coreCells":[{"table":1,"row":42,"column":1,"label":"자산총계","literal":"16,084,409,690","value":16084409690,"key":"assets","kind":"BS"},{"table":1,"row":62,"column":1,"label":"부채총계","literal":"11,039,082,612","value":11039082612,"key":"liabilities","kind":"BS"},{"table":1,"row":73,"column":1,"label":"자본총계","literal":"5,045,327,078","value":5045327078,"key":"equity","kind":"BS"},{"table":3,"row":3,"column":1,"label":"Ⅰ.매출액","literal":"5,905,964,916","value":5905964916,"key":"revenue","kind":"CIS"},{"table":3,"row":42,"column":1,"label":"Ⅴ.영업이익","literal":"631,071,070","value":631071070,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":66,"column":1,"label":"Ⅹ.당기순이익","literal":"110,592,403","value":110592403,"key":"netIncome","kind":"CIS"},{"table":7,"row":3,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"282,402,537","value":282402537,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20240424000570","corp":"01366824","name":"(주)제이엠멀티","year":2023,"basis":"consolidated","sourceReceipt":"20240424000570","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20240424000570-cfs-located-own-seven","digest":"c29444e8944b07fc0c821a63ff93967082ccf6cd25c1a50a13b19d696dff1d58","sourceDigest":"2a0f6b6f09037d78664769f82e78bbb79bf3432333e0d809d689bb51b843f675","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20240424000570&dcmNo=9915137&eleId=21&offset=207959&length=83860&dtd=dart4.xsd","statementSHA":"76c36c8f05076f229c560f48334e1f1841904bdc5e3b8d6d814d9931c9af83b4","periodStart":"2023-01-01","periodEnd":"2023-12-31","coverPeriodTokens":["2023년01월01일","2023년12월31일"],"coreCells":[{"table":1,"row":52,"column":1,"label":"자산총계","literal":"27,090,759,677","value":27090759677,"key":"assets","kind":"BS"},{"table":1,"row":73,"column":1,"label":"부채총계","literal":"21,955,237,924","value":21955237924,"key":"liabilities","kind":"BS"},{"table":1,"row":89,"column":1,"label":"자본총계","literal":"5,135,521,753","value":5135521753,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":1,"label":"I.매출액","literal":"27,566,621,076","value":27566621076,"key":"revenue","kind":"CIS"},{"table":3,"row":47,"column":1,"label":"V.영업이익","literal":"(1,134,271,491)","value":-1134271491,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":73,"column":1,"label":"X.당기순이익(손실)","literal":"(1,965,491,271)","value":-1965491271,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"848,887,238","value":848887238,"key":"operatingCashFlow","kind":"CF"}]}]''',
  ) as List;
  static String? message(Map value) {
    final found = _profiles
        .where(
          (p) =>
              p['receipt'] == value['targetReceipt'] &&
              p['corp'] == value['corpCode'] &&
              p['basis'] == value['fsDiv'],
        )
        .toList();
    if (found.length != 1) return null;
    final p = found.single;
    if (value['action'] != 'verified-keyless-annual-source-after-api-noData' ||
        value['sourceReceipt'] != p['sourceReceipt'] ||
        value['coreRows'] != 7) {
      return null;
    }
    final rows = value['coreRowProvenance'];
    if (rows is! List || rows.length != 7) return null;
    for (var i = 0; i < 7; i++) {
      final r = rows[i], c = p['coreCells'][i];
      if (r is! Map ||
          r['html_provenance'] is! Map ||
          r['account_nm'] != c['label'] ||
          r['account_id'] != null ||
          r['thstrm_amount'] !=
              (c['literal'] as String)
                  .replaceAll(',', '')
                  .replaceAll('(', '-')
                  .replaceAll(')', '')) {
        return null;
      }
      final v = r['html_provenance'] as Map;
      if (v['ruleVersion'] != 'located-own-current-seven-v1' ||
          v['sourceReceipt'] != p['sourceReceipt'] ||
          v['targetReceipt'] != p['receipt'] ||
          v['sourceSha256'] != p['statementSHA'] ||
          v['source'] != p['statementURI'] ||
          v['tableIndex'] != c['table'] ||
          v['rowIndex'] != c['row'] ||
          v['currentColumn'] != c['column'] ||
          v['printedLabel'] != c['label'] ||
          v['printedAmount'] != c['literal'] ||
          v['unit'] != '원' ||
          v['unitMultiplier'] != '1' ||
          v['periodStart'] != p['periodStart'] ||
          v['periodEnd'] != p['periodEnd'] ||
          v['partialCore7'] != true ||
          v['currentCore8'] != false ||
          v['coreAccountsProvided'] != 7 ||
          v['fullStatementVerified'] != false ||
          v['notesVerified'] != false ||
          v['detailEnrichmentApproved'] != false ||
          v['syntheticCapex'] != false ||
          v['missingAccountReasons'] is! Map ||
          (v['missingAccountReasons'] as Map)['capex'] !=
              'No printed whole PPE acquisition total; printed acquisition components are not the total.') {
        return null;
      }
    }
    return '공식 자체 원문에서 핵심 7개 계정을 검증했습니다. 유형자산 취득 총액은 미확보입니다. 개별 취득액을 합성하지 않으며 FCF와 FCF 수익률은 계산하지 않습니다. 세부 계층·전체 재무제표·주석은 검증을 마치지 않았습니다.';
  }
}
