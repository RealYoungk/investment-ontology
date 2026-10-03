import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Four immutable own sources with actual printed contradictions, no amounts stored.
abstract final class LandTrustOwnSourceConflicts {
  static final profiles = jsonDecode(
    r'''{"20220316000546:CFS":{"receipt":"20220316000546","corpCode":"00233653","year":2021,"basis":"CFS","sourceURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220316000546&dcmNo=8464476&eleId=17&offset=211472&length=93970&dtd=dart3.xsd","sourceSHA":"48ccfccc4770ad6a4c3271541c10fd53712906eba6e00612fc17cf27cb202404","printedUnit":"백만원","currentHeaders":[[["연결재무상태표"],["제26기2021년12월31일현재"],["제25기2020년12월31일현재"],["제24기2019년12월31일현재"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]],[["연결포괄손익계산서"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["제24기2019년1월1일부터2019년12월31일까지"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]],[["연결자본변동표"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["제24기2019년1월1일부터2019년12월31일까지"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]],[["연결현금흐름표"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["제24기2019년1월1일부터2019년12월31일까지"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]]],"ownStatementsVsTrustAccount":"OFS table1/5/9/11 have actual issuer; table3/7 explicitly 신탁계정 and are excluded","classification":"unresolvedSourceConflict","approved":false,"fullStatementCollected":false,"checks":[{"label":"currentCE_malformed","leftCoordinate":[5,28,8],"leftRaw":"(8,4730","rightCoordinate":null,"rightRaw":null,"residualPrintedMillion":null,"policy":"No source correction, rounded tolerance or transplant accepted"},{"label":"currentBSCE_parent","leftCoordinate":[1,60,1],"leftRaw":"1,020,551","rightCoordinate":[5,34,6],"rightRaw":"1,020,552","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted"},{"label":"currentBSCE_NCI","leftCoordinate":[1,66,1],"leftRaw":"4,265","rightCoordinate":[5,34,7],"rightRaw":"4,264","residualPrintedMillion":1,"policy":"No source correction, rounded tolerance or transplant accepted"}],"coverURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220316000546&dcmNo=8464476&eleId=1&offset=798&length=4057&dtd=dart3.xsd","coverSHA":"b89e6fca1bacd91fa9277469ca7937e41a48a3b58946c1b404a4412dc83cc766","flatChecks":[{"label":"currentCE_malformed","leftCoordinate":[5,28,8],"leftRaw":"(8,4730","rightCoordinate":null,"rightRaw":null,"residualPrintedMillion":null,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[208,8],"rightFlat":null},{"label":"currentBSCE_parent","leftCoordinate":[1,60,1],"leftRaw":"1,020,551","rightCoordinate":[5,34,6],"rightRaw":"1,020,552","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[65,1],"rightFlat":[214,6]},{"label":"currentBSCE_NCI","leftCoordinate":[1,66,1],"leftRaw":"4,265","rightCoordinate":[5,34,7],"rightRaw":"4,264","residualPrintedMillion":1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[71,1],"rightFlat":[214,7]}]},"20220316000546:OFS":{"receipt":"20220316000546","corpCode":"00233653","year":2021,"basis":"OFS","sourceURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220316000546&dcmNo=8464476&eleId=19&offset=877906&length=115793&dtd=dart3.xsd","sourceSHA":"0db9a581dad9341761daed84b87b74865c006f7ee39d148f0020f0597da13da2","printedUnit":"백만원","currentHeaders":[[["재무상태표"],["제26기2021년12월31일현재"],["제25기2020년12월31일현재"],["제24기2019년12월31일현재"],["주식회사한국토지신탁","(단위:백만원)"]],[["포괄손익계산서"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["제24기2019년1월1일부터2019년12월31일까지"],["주식회사한국토지신탁","(단위:백만원)"]],[["자본변동표"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["제24기2019년1월1일부터2019년12월31일까지"],["주식회사한국토지신탁","(단위:백만원)"]],[["현금흐름표"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["제24기2019년1월1일부터2019년12월31일까지"],["주식회사한국토지신탁","(단위:백만원)"]]],"ownStatementsVsTrustAccount":"OFS table1/5/9/11 have actual issuer; table3/7 explicitly 신탁계정 and are excluded","classification":"unresolvedSourceConflict","approved":false,"fullStatementCollected":false,"checks":[{"label":"currentCashBSCF","leftCoordinate":[1,3,1],"leftRaw":"338,185","rightCoordinate":[11,83,1],"rightRaw":"338,186","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted"},{"label":"currentCE_adjustments","leftCoordinate":[1,52,1],"leftRaw":"(46,444)","rightCoordinate":[9,27,3],"rightRaw":"(46,445)","residualPrintedMillion":1,"policy":"No source correction, rounded tolerance or transplant accepted"},{"label":"currentCE_OCI","leftCoordinate":[1,53,1],"leftRaw":"(7,801)","rightCoordinate":[9,27,4],"rightRaw":"(7,800)","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted"}],"coverURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220316000546&dcmNo=8464476&eleId=1&offset=798&length=4057&dtd=dart3.xsd","coverSHA":"b89e6fca1bacd91fa9277469ca7937e41a48a3b58946c1b404a4412dc83cc766","flatChecks":[{"label":"currentCashBSCF","leftCoordinate":[1,3,1],"leftRaw":"338,185","rightCoordinate":[11,83,1],"rightRaw":"338,186","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[8,1],"rightFlat":[402,1]},{"label":"currentCE_adjustments","leftCoordinate":[1,52,1],"leftRaw":"(46,444)","rightCoordinate":[9,27,3],"rightRaw":"(46,445)","residualPrintedMillion":1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[57,1],"rightFlat":[313,3]},{"label":"currentCE_OCI","leftCoordinate":[1,53,1],"leftRaw":"(7,801)","rightCoordinate":[9,27,4],"rightRaw":"(7,800)","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[58,1],"rightFlat":[313,4]}]},"20230323000917:CFS":{"receipt":"20230323000917","corpCode":"00233653","year":2022,"basis":"CFS","sourceURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000917&dcmNo=9096507&eleId=17&offset=210253&length=95515&dtd=dart3.xsd","sourceSHA":"ae0c5a76ea7ca152e477ade0671ff792394218480d03b8a9e8ce8c06ea53c381","printedUnit":"백만원","currentHeaders":[[["연결재무상태표"],["제27기2022년12월31일현재"],["제26기2021년12월31일현재"],["제25기2020년12월31일현재"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]],[["연결포괄손익계산서"],["제27기2022년1월1일부터2022년12월31일까지"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]],[["연결자본변동표"],["제27기2022년1월1일부터2022년12월31일까지"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]],[["연결현금흐름표"],["제27기2022년1월1일부터2022년12월31일까지"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["주식회사한국토지신탁과그종속기업","(단위:백만원)"]]],"ownStatementsVsTrustAccount":"OFS table1/5/9/11 have actual issuer; table3/7 explicitly 신탁계정 and are excluded","classification":"unresolvedSourceConflict","approved":false,"fullStatementCollected":false,"checks":[{"label":"currentCashBSCF","leftCoordinate":[1,3,1],"leftRaw":"271,373","rightCoordinate":[7,94,1],"rightRaw":"271,374","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted"},{"label":"currentWholeEquityBSCE","leftCoordinate":[1,64,1],"leftRaw":"1,024,933","rightCoordinate":[5,37,8],"rightRaw":"1,024,932","residualPrintedMillion":1,"policy":"No source correction, rounded tolerance or transplant accepted"}],"coverURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000917&dcmNo=9096507&eleId=1&offset=812&length=4060&dtd=dart3.xsd","coverSHA":"bb0ba718d8a9777cbfb2c827e6a5d466437ba6d54fdbb1da09bcab12fa740f70","flatChecks":[{"label":"currentCashBSCF","leftCoordinate":[1,3,1],"leftRaw":"271,373","rightCoordinate":[7,94,1],"rightRaw":"271,374","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[8,1],"rightFlat":[314,1]},{"label":"currentWholeEquityBSCE","leftCoordinate":[1,64,1],"leftRaw":"1,024,933","rightCoordinate":[5,37,8],"rightRaw":"1,024,932","residualPrintedMillion":1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[69,1],"rightFlat":[214,8]}]},"20230323000917:OFS":{"receipt":"20230323000917","corpCode":"00233653","year":2022,"basis":"OFS","sourceURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000917&dcmNo=9096507&eleId=19&offset=880946&length=114117&dtd=dart3.xsd","sourceSHA":"ec5eb32389c0d94bb3f16e27c569cf34c8e1894211bf201377dc5bf2d02bb992","printedUnit":"백만원","currentHeaders":[[["재무상태표"],["제27기2022년12월31일현재"],["제26기2021년12월31일현재"],["제25기2020년12월31일현재"],["주식회사한국토지신탁","(단위:백만원)"]],[["포괄손익계산서"],["제27기2022년1월1일부터2022년12월31일까지"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["주식회사한국토지신탁","(단위:백만원)"]],[["자본변동표"],["제27기2022년1월1일부터2022년12월31일까지"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["주식회사한국토지신탁","(단위:백만원)"]],[["현금흐름표"],["제27기2022년1월1일부터2022년12월31일까지"],["제26기2021년1월1일부터2021년12월31일까지"],["제25기2020년1월1일부터2020년12월31일까지"],["주식회사한국토지신탁","(단위:백만원)"]]],"ownStatementsVsTrustAccount":"OFS table1/5/9/11 have actual issuer; table3/7 explicitly 신탁계정 and are excluded","classification":"unresolvedSourceConflict","approved":false,"fullStatementCollected":false,"checks":[{"label":"currentCashBSCF","leftCoordinate":[1,3,1],"leftRaw":"250,347","rightCoordinate":[11,80,1],"rightRaw":"250,348","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted"},{"label":"ownPriorCashBSCF","leftCoordinate":[1,3,2],"leftRaw":"338,185","rightCoordinate":[11,79,1],"rightRaw":"338,186","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted"}],"coverURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230323000917&dcmNo=9096507&eleId=1&offset=812&length=4060&dtd=dart3.xsd","coverSHA":"bb0ba718d8a9777cbfb2c827e6a5d466437ba6d54fdbb1da09bcab12fa740f70","flatChecks":[{"label":"currentCashBSCF","leftCoordinate":[1,3,1],"leftRaw":"250,347","rightCoordinate":[11,80,1],"rightRaw":"250,348","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[8,1],"rightFlat":[396,1]},{"label":"ownPriorCashBSCF","leftCoordinate":[1,3,2],"leftRaw":"338,185","rightCoordinate":[11,79,1],"rightRaw":"338,186","residualPrintedMillion":-1,"policy":"No source correction, rounded tolerance or transplant accepted","leftFlat":[8,2],"rightFlat":[395,1]}]}}''',
  ) as Map<String, dynamic>;
  static Map<String, Object>? evidence({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required Uri statementSource,
    required String coverHtml,
    required String statementHtml,
  }) {
    final p = profiles['$receipt:${consolidated ? 'CFS' : 'OFS'}'];
    if (p is! Map ||
        corpCode != p['corpCode'] ||
        start != DateTime.utc(p['year'] as int) ||
        end != DateTime.utc(p['year'] as int, 12, 31) ||
        coverSource.toString() != p['coverURI'] ||
        statementSource.toString() != p['sourceURI'] ||
        sha256.convert(utf8.encode(coverHtml)).toString() != p['coverSHA'] ||
        sha256.convert(utf8.encode(statementHtml)).toString() !=
            p['sourceSHA']) {
      return null;
    }
    String compact(String x) => x
        .replaceAll(RegExp(r'<[^>]*>', dotAll: true), '')
        .replaceAll('&nbsp;', '')
        .replaceAll(RegExp(r'\s+'), '');
    final rows = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
        .allMatches(statementHtml)
        .map(
          (r) => RegExp(
            r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
            caseSensitive: false,
          ).allMatches(r[1]!).map((c) => compact(c[1]!)).toList(),
        )
        .toList();
    for (final c in p['flatChecks'] as List) {
      final left = c['leftFlat'] as List;
      if (rows[left[0] as int][left[1] as int] != c['leftRaw']) {
        throw const FormatException(
          'LandTrust pinned current left cell changed',
        );
      }
      final right = c['rightFlat'];
      if (right != null &&
          rows[right[0] as int][right[1] as int] != c['rightRaw']) {
        throw const FormatException(
          'LandTrust pinned current right cell changed',
        );
      }
    }
    return <String, Object>{
      ...Map<String, Object>.from(p),
      'receipt': receipt,
      'reason': '한국토지신탁 자체 현재 재무제표 인쇄 현금·자본·숫자표기 불일치; 임의 수정 또는 반올림 허용 없이 보류',
      'periodStart': '${start.year}-01-01',
      'periodEnd': '${end.year}-12-31',
      'financialFactsStored': false,
      'numericCellCorrection': false,
      'noData': false,
    };
  }
}
