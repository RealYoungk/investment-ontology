import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable primary-source contradiction; no numerical correction is made.
class KnownAnnualSourceConflict extends FormatException {
  final Map<String, Object> evidence;
  KnownAnnualSourceConflict(Map<String, Object> evidence)
    : evidence = Map.unmodifiable(evidence),
      super(evidence['reason'] as String);
}

abstract final class KnownAnnualSourceConflicts {
  static void verify({
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
    final profile = _profiles[receipt];
    if (profile == null ||
        profile['corpCode'] != corpCode ||
        profile['consolidated'] != consolidated ||
        start != DateTime.utc(profile['year'] as int, 1, 1) ||
        end != DateTime.utc(profile['year'] as int, 12, 31) ||
        coverSource.toString() != profile['coverSource'] ||
        statementSource.toString() != profile['statementSource'] ||
        sha256.convert(utf8.encode(coverHtml)).toString() !=
            profile['coverSha256'] ||
        sha256.convert(utf8.encode(statementHtml)).toString() !=
            profile['statementSha256']) {
      return;
    }
    // Read the exact printed rows independently of the ordinary primary parser.
    final rows = RegExp(r'<TR\b[^>]*>([\s\S]*?)</TR>', caseSensitive: false)
        .allMatches(statementHtml)
        .map(
          (r) =>
              RegExp(r'<T[DH]\b[^>]*>([\s\S]*?)</T[DH]>', caseSensitive: false)
                  .allMatches(r[1]!)
                  .map(
                    (c) => c[1]!
                        .replaceAll(RegExp(r'<[^>]+>'), '')
                        .replaceAll('&nbsp;', ' ')
                        .trim(),
                  )
                  .toList(),
        )
        .toList();
    Map<String, Object> conflict;
    if (!consolidated) {
      final bs = rows.singleWhere(
        (r) => r.isNotEmpty && r.first.replaceAll(RegExp(r'\s'), '') == '자본총계',
      );
      final ce = rows.singleWhere(
        (r) =>
            r.isNotEmpty &&
            r.first.replaceAll(RegExp(r'\s'), '') == '2024.12.31(당기말)',
      );
      final bsAmount = BigInt.parse(bs[3].replaceAll(',', ''));
      final ceAmount = BigInt.parse(ce.last.replaceAll(',', ''));
      if (bsAmount == ceAmount) {
        return;
      }
      conflict = {
        'reason': '독립 자본변동표 기말 총자본과 재무상태표 총자본이 원 단위로 불일치',
        'balanceEquity': bsAmount.toString(),
        'balanceCurrentColumn': 3,
        'equityWholeColumn': 5,
        'unit': '원',
        'printedBalanceLabel': bs.first,
        'equityStatementClosing': ceAmount.toString(),
        'printedClosingLabel': ce.first,
      };
    } else {
      final ce = rows.singleWhere(
        (r) =>
            r.isNotEmpty &&
            r.first.replaceAll(RegExp(r'\s'), '') == '202.12.31(당기말)',
      );
      conflict = {
        'reason': '독립 연결 자본변동표 당기말의 인쇄 연도 202는 보고기간 2021을 증명하지 못함',
        'printedClosingLabel': ce.first,
        'wholeEquity': ce.last,
        'unit': '원',
        'parentColumn': 5,
        'nonControllingColumn': 6,
        'wholeColumn': 7,
      };
    }
    throw KnownAnnualSourceConflict({
      ...profile,
      ...conflict,
      'receipt': receipt,
      'periodStart': '${start.year}-01-01',
      'periodEnd': '${end.year}-12-31',
      'financialFactsStored': false,
    });
  }

  static const _profiles = <String, Map<String, Object>>{
    '20250324000541': {
      'corpCode': "01109690",
      'consolidated': false,
      'year': 2024,
      'coverSource': "https://dart.fss.or.kr/report/viewer.do?rcpNo=20250324000541&dcmNo=10453838&eleId=1&offset=955&length=4572&dtd=dart4.xsd",
      'statementSource': "https://dart.fss.or.kr/report/viewer.do?rcpNo=20250324000541&dcmNo=10453838&eleId=21&offset=542179&length=62162&dtd=dart4.xsd",
      'coverSha256':
          "d1ce204fe71edcbaf822117d9d2d52b103d9559004ac9c2d2385d0b54f379b82",
      'statementSha256':
          "7e8d331b085aa3df62ded276a617b80d456085d77c0ab32c6df3da653de67e6a",
    },
    '20220322000964': {
      'corpCode': "01185867",
      'consolidated': true,
      'year': 2021,
      'coverSource': "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220322000964&dcmNo=8492716&eleId=1&offset=794&length=4087&dtd=dart3.xsd",
      'statementSource': "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220322000964&dcmNo=8492716&eleId=19&offset=213973&length=47229&dtd=dart3.xsd",
      'coverSha256':
          "e2c871b9d537eb40220ce7df44a37b06234cff699cee77f23013dd2a81d0c7f6",
      'statementSha256':
          "8add3792568e83399c5ca5f41a10efbcd840ecd1b0f51252a4421b7feaa48d87",
    },
  };
}
