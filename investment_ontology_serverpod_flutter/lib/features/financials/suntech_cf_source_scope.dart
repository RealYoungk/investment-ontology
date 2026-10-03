import 'dart:convert';

/// Exact original CF selection, never a general statement/account alias.
abstract final class SuntechCfSourceScope {
  static final Map _contract = jsonDecode(
    r'''{"digest":"1ba5d38ebc216716dfd94b3ecd34a9e2ce4e31010d5c11682ecf79ba24a2a57e","sha":"6bd9bfe052c4008bde313b8696ef8627f433f785694875583206202c82e199a1","uri":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250317000968&dcmNo=10416653&eleId=21&offset=313848&length=112976&dtd=dart4.xsd","core":[{"table":1,"row":52,"column":2,"kind":"BS","key":"assets","label":"자산총계","printed":"17,141,610,062","physicalOrd":55,"value":"17141610062","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":68,"column":2,"kind":"BS","key":"liabilities","label":"부채총계","printed":"14,371,882,302","physicalOrd":71,"value":"14371882302","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":85,"column":2,"kind":"BS","key":"equity","label":"자본총계","printed":"2,769,727,760","physicalOrd":88,"value":"2769727760","magnitude":false,"explicitNormalizedLoss":false},{"table":3,"row":1,"column":2,"kind":"IS","key":"revenue","label":"Ⅰ.매출액","printed":"25,779,164,428","physicalOrd":93,"value":"25779164428","magnitude":false,"explicitNormalizedLoss":false},{"table":3,"row":35,"column":2,"kind":"IS","key":"operatingIncome","label":"영업이익(손실)","printed":"(519,426,404)","physicalOrd":127,"value":"-519426404","magnitude":false,"explicitNormalizedLoss":false},{"table":7,"row":2,"column":1,"kind":"CF","key":"netIncome","label":"1.당기순이익","printed":"(1,288,353,219)","physicalOrd":172,"value":"-1288353219","magnitude":false,"explicitNormalizedLoss":false},{"table":7,"row":1,"column":2,"kind":"CF","key":"operatingCashFlow","label":"Ⅰ.영업활동으로인한현금흐름","printed":"(3,070,619,002)","physicalOrd":171,"value":"-3070619002","magnitude":false,"explicitNormalizedLoss":false},{"table":7,"row":37,"column":1,"kind":"CF","key":"capex","label":"유형자산의증가","printed":"93,377,336","physicalOrd":207,"value":"93377336","magnitude":false,"explicitNormalizedLoss":false}]}''',
  );

  static String? message(Map j) {
    if (j['action'] !=
            'verified-exact-own-consolidated-cf-net-income-and-ppe' ||
        j['receipt'] != '20250317000968' ||
        j['corpCode'] != '00963000' ||
        j['year'] != 2024 ||
        j['fsDiv'] != 'consolidated' ||
        j['source'] != _contract['uri'] ||
        j['sha256'] != _contract['digest'] ||
        j['coreRows'] != 8 ||
        j['ruleVersion'] != 'suntech-2024-own-cfs-source-aware-eight-v1' ||
        j['wholePLNISynthesized'] != false ||
        j['CEUnitPrinted'] != false ||
        j['CECurrencyVerified'] != false ||
        j['fullStatementCollected'] != false ||
        j['allStatementRowsVerified'] != false ||
        j['notesVerified'] != false ||
        j['netIncomeSourceStatement'] != 'cashFlow' ||
        j['netIncomeRawLabel'] != '1.당기순이익' ||
        j['netIncomeAmount'] != '-1288353219' ||
        j['capexRawLabel'] != '유형자산의증가' ||
        j['capexAmount'] != '93377336' ||
        j['storedAccountId'] != null) {
      return null;
    }
    final rows = j['coreRowProvenance'];
    if (rows is! List || rows.length != 8) {
      return null;
    }
    for (var i = 0; i < 8; i++) {
      final row = rows[i], e = _contract['core'][i];
      if (row is! Map ||
          row['account_nm'] != e['label'] ||
          row['sj_div'] != e['kind'] ||
          row['thstrm_amount'] != e['value'] ||
          row['account_id'] != null ||
          row['rcept_no'] != '20250317000968' ||
          row['corp_code'] != '00963000' ||
          row['fs_div'] != 'CFS' ||
          row['bsns_year'] != '2024' ||
          row['ord'] != '${e['physicalOrd']}') {
        return null;
      }
      final p = row['html_provenance'];
      if (p is! Map ||
          p['source'] != _contract['uri'] ||
          p['sourceSha256'] != _contract['sha'] ||
          p['ruleVersion'] != 'suntech-2024-own-cfs-source-aware-eight-v1' ||
          p['tableIndex'] != e['table'] ||
          p['rowIndex'] != e['row'] ||
          p['column'] != e['column'] ||
          p['currentCell'] != e['printed'] ||
          p['printedUnit'] != '원' ||
          p['unitMultiplier'] != '1' ||
          p['periodStart'] != '2024-01-01' ||
          p['periodEnd'] != '2024-12-31' ||
          p['basis'] != 'CFS' ||
          p['currentCore8'] != true ||
          p['netIncomeSourceStatement'] != 'CF' ||
          p['netIncomeSelection'] != 'directOwnConsolidatedCFNetIncome' ||
          p['CEUnitPrinted'] != false ||
          p['CECurrencyVerified'] != false ||
          p['CECurrencyCrosschecksClaim'] != false ||
          p['wholePLNISynthesized'] != false ||
          p['fullStatementCollected'] != false ||
          p['allStatementRowsVerified'] != false ||
          p['notesVerified'] != false ||
          p['numericCellCorrection'] != false ||
          p['sourceCellRewritten'] != false ||
          p['signNormalization'] != 'none') {
        return null;
      }
      if (e['key'] == 'capex' && p['cashDirection'] != 'outflow') {
        return null;
      }
    }
    return '연결 당기 핵심 8개 계정을 수집했습니다. 연결 순이익은 현금흐름표에 직접 인쇄된 값을 사용하며 원래 재무제표 종류·계정명·금액을 보존합니다. 유형자산 지출도 투자활동 현금유출에 인쇄된 전체 항목입니다. 자본변동표의 단위는 인쇄되지 않아 통화 검산을 완료했다고 표시하지 않습니다. 전체 세부 계정과 주석은 검증을 마치지 않았습니다.';
  }
}
