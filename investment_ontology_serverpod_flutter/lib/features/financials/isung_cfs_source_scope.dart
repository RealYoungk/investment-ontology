import 'dart:convert';

/// Exact own-current partial CFS contracts; no generic loss normalization.
abstract final class IsungCfsSourceScope {
  static final Map<String, dynamic> _contracts = jsonDecode(
    r'''{"20230323000123":{"year":2022,"sha":"6f7333ca4d273d2b0a3806930560a20e52822682c7451862ed69d5708c428336","uri":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000123&dcmNo=9093262&eleId=19&offset=174708&length=65265&dtd=dart3.xsd","digest":"ff67faf44e0d98d6401e4a6557a09dfa3517324a03a552068dc66d8a2f7f0b05","core":[{"table":1,"row":59,"column":1,"kind":"BS","label":"자산총계","printed":"27,658,110,009","physicalOrd":63,"value":"27658110009","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":81,"column":1,"kind":"BS","label":"부채총계","printed":"15,434,598,306","physicalOrd":85,"value":"15434598306","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":98,"column":1,"kind":"BS","label":"자본총계","printed":"12,223,511,703","physicalOrd":102,"value":"12223511703","magnitude":false,"explicitNormalizedLoss":false},{"table":4,"row":1,"column":1,"kind":"IS","label":"I.매출액","printed":"13,829,208,123","physicalOrd":109,"value":"13829208123","magnitude":false,"explicitNormalizedLoss":false},{"table":4,"row":33,"column":1,"kind":"IS","label":"V.영업이익(손실)","printed":"(903,947,084)","physicalOrd":141,"value":"-903947084","magnitude":false,"explicitNormalizedLoss":false},{"table":7,"row":1,"column":1,"kind":"CIS","label":"I.연결당기순손실","printed":"(1,637,586,127)","physicalOrd":171,"value":"-1637586127","magnitude":false,"explicitNormalizedLoss":false},{"table":13,"row":1,"column":1,"kind":"CF","label":"I.영업활동으로인한현금흐름","printed":"2,390,809,230","physicalOrd":195,"value":"2390809230","magnitude":false,"explicitNormalizedLoss":false}],"niMethod":"directSignedCurrentCIS","eqCount":16},"20240321000294":{"year":2023,"sha":"b3213e81b4c49e4d0f216dca1566f1ad803603ee0c53cb88c8bb6ebfc17432df","uri":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20240321000294&dcmNo=9746280&eleId=19&offset=187684&length=91326&dtd=dart4.xsd","digest":"63bd7fe363140b44d478793a2ef495d75157c7bdc0fe588ff1ff548c12011631","core":[{"table":1,"row":60,"column":2,"kind":"BS","label":"자산총계","printed":"32,828,392,275","physicalOrd":64,"value":"32828392275","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":85,"column":2,"kind":"BS","label":"부채총계","printed":"20,359,744,746","physicalOrd":89,"value":"20359744746","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":102,"column":2,"kind":"BS","label":"자본총계","printed":"12,468,647,529","physicalOrd":106,"value":"12468647529","magnitude":false,"explicitNormalizedLoss":false},{"table":4,"row":1,"column":2,"kind":"IS","label":"I.매출액","printed":"16,466,985,397","physicalOrd":113,"value":"16466985397","magnitude":false,"explicitNormalizedLoss":false},{"table":4,"row":33,"column":2,"kind":"IS","label":"V.영업이익(손실)","printed":"(1,076,026,348)","physicalOrd":145,"value":"-1076026348","magnitude":false,"explicitNormalizedLoss":false},{"table":4,"row":57,"column":2,"kind":"IS","label":"X.연결당기순손실","printed":"1,509,318,876","physicalOrd":169,"value":"-1509318876","magnitude":false,"explicitNormalizedLoss":true},{"table":10,"row":1,"column":2,"kind":"CF","label":"I.영업활동으로인한현금흐름","printed":"(1,646,702,373)","physicalOrd":193,"value":"-1646702373","magnitude":false,"explicitNormalizedLoss":false}],"niMethod":"exactPrintedLossLabelMagnitude","eqCount":15}}''',
  );

  static String? message(Map j) {
    final c = _contracts[j['targetReceipt']];
    if (c is! Map ||
        j['action'] != 'verified-keyless-annual-source-after-api-noData' ||
        j['corpCode'] != '01365384' ||
        j['fsDiv'] != 'consolidated' ||
        j['sourceReceipt'] != j['targetReceipt'] ||
        j['coreRows'] != 7 ||
        j['sha256'] != c['digest'] ||
        j['format'] != 'html') {
      return null;
    }
    final rows = j['coreRowProvenance'];
    if (rows is! List || rows.length != 7) {
      return null;
    }
    for (var i = 0; i < 7; i++) {
      final row = rows[i], e = c['core'][i];
      if (row is! Map ||
          row['thstrm_amount'] != e['value'] ||
          row['account_nm'] != e['label'] ||
          row['currency'] != 'KRW' ||
          row['account_id'] != null) {
        return null;
      }
      final p = row['html_provenance'];
      if (p is! Map ||
          p['source'] != c['uri'] ||
          p['sourceSha256'] != c['sha'] ||
          p['sourceReceipt'] != j['targetReceipt'] ||
          p['ruleVersion'] != 'isung-own-cfs-exact-current-seven-v1' ||
          p['physicalOrd'] != e['physicalOrd'] ||
          p['printedLabel'] != e['label'] ||
          p['tableIndex'] != e['table'] ||
          p['rowIndex'] != e['row'] ||
          p['column'] != e['column'] ||
          p['currentCell'] != e['printed'] ||
          p['basis'] != 'CFS' ||
          p['printedUnit'] != '원' ||
          p['unitMultiplier'] != '1' ||
          p['periodStart'] != '${c['year']}-01-01' ||
          p['periodEnd'] != '${c['year']}-12-31' ||
          p['partialCore7'] != true ||
          p['currentCore8'] != false ||
          p['wholeNetIncomeExact'] != true ||
          p['fullStatementCollected'] != false ||
          p['fullStatementVerified'] != false ||
          p['allStatementRowsVerified'] != false ||
          p['notesVerified'] != false ||
          p['FCFSupported'] != false ||
          p['numericCellCorrection'] != false ||
          p['sourceCellRewritten'] != false ||
          p['checkedPrintedEquationCount'] != c['eqCount'] ||
          p['netIncomeSelection'] != c['niMethod'] ||
          p['signNormalization'] !=
              (e['explicitNormalizedLoss'] == true
                  ? 'explicitPrintedLossMagnitudeCorroboratedByCEandCF'
                  : 'none')) {
        return null;
      }
      final optional = p['uncollectedOptionalAccounts'];
      if (optional is! List ||
          optional.length != 1 ||
          optional.single != 'capex') {
        return null;
      }
    }
    return c['year'] == 2023
        ? '연결 당기 핵심 7개 계정을 수집했습니다. 원문의 양수 순손실 크기는 손실 표기와 자본변동표·현금흐름표의 음수 값으로 확인해 부호를 적용했고 원문 값도 보존했습니다. 전체 유형자산 취득액은 미확보이며, FCF와 FCF 수익률은 계산하지 않습니다. 전체 세부 계정과 주석은 검증을 마치지 않았습니다.'
        : '연결 당기 핵심 7개 계정을 수집했습니다. 순손실은 포괄손익계산서에 직접 음수로 인쇄된 값이며 손익계산서의 양수 손실 크기도 출처에 보존했습니다. 전체 유형자산 취득액은 미확보이며, FCF와 FCF 수익률은 계산하지 않습니다. 전체 세부 계정과 주석은 검증을 마치지 않았습니다.';
  }
}
