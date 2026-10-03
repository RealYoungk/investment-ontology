import 'land_trust_own_source_conflicts.dart';

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
  /// Finite independently audited conflict profiles; not numerical fallbacks.
  static Map<String, Map<String, Object>> get profiles =>
      Map<String, Map<String, Object>>.unmodifiable({
        for (final e in _profiles.entries)
          e.key: Map<String, Object>.unmodifiable(e.value),
      });

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
    final landEvidence = LandTrustOwnSourceConflicts.evidence(
      receipt: receipt,
      corpCode: corpCode,
      consolidated: consolidated,
      start: start,
      end: end,
      coverSource: coverSource,
      statementSource: statementSource,
      coverHtml: coverHtml,
      statementHtml: statementHtml,
    );
    if (landEvidence != null) {
      throw KnownAnnualSourceConflict(landEvidence);
    }
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
    if (receipt == '20240320001438') {
      String compact(String x) => x.replaceAll(RegExp(r'\s+'), '');
      if (rows.length != 229 ||
          compact(rows[153].single) != '제28기2023년01월01일부터2023년12월31일까지' ||
          compact(rows[158].first) != '2023.01.01(당기초)' ||
          compact(rows[164].first) != '2022.12.31(당기말)' ||
          compact(rows[155].join('|')) !=
              '과목|자본금|자본잉여금|자본조정|기타포괄손익누계액|이익잉여금|총계') {
        throw const FormatException(
          'Pinned Suntech whole CE row/date structure changed',
        );
      }
      BigInt money(String x) => BigInt.parse(
        x.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
      final opening = money(rows[158].last), closing = money(rows[164].last);
      final changes = [for (var i = 159; i <= 163; i++) money(rows[i].last)];
      final roll = opening + changes.fold(BigInt.zero, (a, b) => a + b);
      final difference = roll - closing;
      if (difference != BigInt.from(-50000000) ||
          money(rows[90][2]) != closing ||
          money(rows[163].last) != money(rows[152][2]) ||
          money(rows[169][1]) != money(rows[152][2])) {
        throw const FormatException(
          'Pinned Suntech current CE conflict proof changed',
        );
      }
      conflict = {
        'reason': '자체 2023 연결 원문 CE 기초와 인쇄 변동합계가 기말 총계와 50000000 raw 숫자 차이; CE 기말 인쇄연도 2022 및 단위 미인쇄 보존',
        'openingRow': 158,
        'closingRow': 164,
        'printedOpeningLabel': rows[158].first,
        'printedClosingLabel': rows[164].first,
        'wholeColumn': 6,
        'openingRaw': rows[158].last,
        'closingRaw': rows[164].last,
        'rawWholeEquityRoll': roll.toString(),
        'rawWholeEquityRollDifference': difference.toString(),
        'printedChangeRows': [
          for (var i = 159; i <= 163; i++)
            {'row': i, 'label': rows[i].first, 'wholeRaw': rows[i].last},
        ],
        'ceUnitPrinted': false,
        'ceCurrencyAssigned': false,
        'ceAmountScaleAssigned': false,
        'closingMatchesOwnBalanceRaw': true,
        'printedOwnPLAndCENIAndCFNIEqual': true,
        'numericCellCorrection': false,
        'noLaterComparativeSubstitution': true,
      };
    } else if (!consolidated) {
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
    '20240320001438': {
      'corpCode': '00963000',
      'consolidated': true,
      'year': 2023,
      'coverSource': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001438&dcmNo=9740410&eleId=1&offset=954&length=4592&dtd=dart4.xsd',
      'statementSource': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001438&dcmNo=9740410&eleId=19&offset=329275&length=109490&dtd=dart4.xsd',
      'coverSha256':
          '779a3a6cff8c09e3ed3660cd48e812803e0ecc623fc20736c8c4887e30734363',
      'statementSha256':
          '8a55352ab6ab28b50e276f0e70fee937a739cedf33ddbac8fbd9d09844503a65',
    },

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
