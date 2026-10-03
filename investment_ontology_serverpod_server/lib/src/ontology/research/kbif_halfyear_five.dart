import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One own financial-results appendix, never a regular half-year report.
abstract final class KbifHalfYearFive {
  static const category = 'printedAuditUnverifiedHalfYearFundCategories';
  static final profile = jsonDecode(r'''{
  "metadata": {
    "corpCode": "01880801",
    "title": "KB발해인프라 2026년 상반기 회계상 재무실적",
    "documentType": "operatingReport",
    "provider": "officialIR",
    "providerReceipt": null,
    "providerDocumentId": null,
    "periodStart": "2026-01-01",
    "periodEnd": "2026-06-30",
    "publishedAt": "2026-07-31",
    "officialUrl": "https://kbif.co.kr/upload/2026/7/20260731043629001933.pdf",
    "sha256": "a96534db3ab73fd7145cd8c05b7f8194edd885e4547417cc57fb59dbe651da61",
    "issuerQuote": "KB발해인프라투융자회사",
    "periodQuote": "2026년 상반기",
    "numericState": "notExtracted",
    "financialValues": null,
    "publicContent": "linkOnly"
  },
  "rawTextSha256": "0583387d91b94e30b60f7cb1a5c780a5569867762fd2e5b7af939ac8aba4f843",
  "expected": {
    "corpCode": "01880801",
    "documentType": "operatingReport",
    "provider": "officialIR",
    "providerReceipt": null,
    "officialUrl": "https://kbif.co.kr/upload/2026/7/20260731043629001933.pdf",
    "sha256": "a96534db3ab73fd7145cd8c05b7f8194edd885e4547417cc57fb59dbe651da61",
    "periodStart": "2026-01-01",
    "periodEnd": "2026-06-30",
    "categorySchema": "printedAuditUnverifiedHalfYearFundCategories",
    "basis": "ownFund",
    "periodKind": "ownHalfYear",
    "auditStatus": "notExtracted",
    "observationRole": "currentOwn",
    "currency": "KRW",
    "printedUnit": "백만원",
    "precisionUnit": "1000000",
    "numericState": "partialPrintedHalfYearFundFive",
    "publicContent": "sourceLinkAndValues",
    "extractedBy": "fixedPdfTextRule",
    "parserVersion": "kbif-own-halfyear-five-v1",
    "rawTextSha256": "0583387d91b94e30b60f7cb1a5c780a5569867762fd2e5b7af939ac8aba4f843",
    "extractionTool": "pdftotext -layout",
    "regularReportCode": null,
    "xbrlAccountId": null,
    "fullStatementCollected": false,
    "notesDecodedOrVerified": false,
    "regularApiCompletion": false,
    "includeInTtm": false,
    "accounts": [
      {
        "metric": "assets",
        "accountLabel": "자산총계",
        "pageOrdinal": 13,
        "lineOrdinal": 39,
        "rawLine": " 자산총계                             1,008,537            960,332     부채 및 자본총계                        1,008,537            960,332",
        "printedAmount": "1,008,537",
        "amountInteger": "1008537000000",
        "amountScope": "stockAtPeriodEnd",
        "periodStart": "2026-06-30",
        "periodEnd": "2026-06-30",
        "currency": "KRW",
        "printedUnit": "백만원",
        "precisionUnit": "1000000",
        "currentTokenIndex": 0,
        "cashDirection": null,
        "printedSign": "positive"
      },
      {
        "metric": "liabilities",
        "accountLabel": "부채총계",
        "pageOrdinal": 13,
        "lineOrdinal": 33,
        "rawLine": "      미수이자수익                            964               954      부채총계                               167,166             91,709",
        "printedAmount": "167,166",
        "amountInteger": "167166000000",
        "amountScope": "stockAtPeriodEnd",
        "periodStart": "2026-06-30",
        "periodEnd": "2026-06-30",
        "currency": "KRW",
        "printedUnit": "백만원",
        "precisionUnit": "1000000",
        "currentTokenIndex": 2,
        "cashDirection": null,
        "printedSign": "positive"
      },
      {
        "metric": "equity",
        "accountLabel": "자본총계",
        "pageOrdinal": 13,
        "lineOrdinal": 36,
        "rawLine": "      선급이자 등                           1,437             1,078     자본총계                               841,371            868,623",
        "printedAmount": "841,371",
        "amountInteger": "841371000000",
        "amountScope": "stockAtPeriodEnd",
        "periodStart": "2026-06-30",
        "periodEnd": "2026-06-30",
        "currency": "KRW",
        "printedUnit": "백만원",
        "precisionUnit": "1000000",
        "currentTokenIndex": 2,
        "cashDirection": null,
        "printedSign": "positive"
      },
      {
        "metric": "fundOperatingIncome",
        "accountLabel": "운용수익 총계",
        "pageOrdinal": 15,
        "lineOrdinal": 24,
        "rawLine": " 운용수익 총계                      34,397             32,382     운용수익 총계                   47,556              45,449",
        "printedAmount": "34,397",
        "amountInteger": "34397000000",
        "amountScope": "ownFiscalDuration",
        "periodStart": "2026-01-01",
        "periodEnd": "2026-06-30",
        "currency": "KRW",
        "printedUnit": "백만원",
        "precisionUnit": "1000000",
        "currentTokenIndex": 0,
        "cashDirection": null,
        "printedSign": "positive"
      },
      {
        "metric": "netProfit",
        "accountLabel": "회계적 당기순이익",
        "pageOrdinal": 15,
        "lineOrdinal": 36,
        "rawLine": " 회계적 당기순이익                    26,771             27,276     세무상 분배가능이익                39,930              40,344",
        "printedAmount": "26,771",
        "amountInteger": "26771000000",
        "amountScope": "ownFiscalDuration",
        "periodStart": "2026-01-01",
        "periodEnd": "2026-06-30",
        "currency": "KRW",
        "printedUnit": "백만원",
        "precisionUnit": "1000000",
        "currentTokenIndex": 0,
        "cashDirection": null,
        "printedSign": "positive"
      }
    ],
    "unextractedMetrics": [
      {
        "metric": "operatingProfit",
        "reason": "원문 회계상 운용손익표에 영업이익 항목이 인쇄되지 않음"
      },
      {
        "metric": "assetManagementCashFlow",
        "reason": "이 재무실적 발표 원문에 현금흐름표 미인쇄"
      },
      {
        "metric": "ppeAcquisition",
        "reason": "유형자산 취득 총액 미인쇄"
      },
      {
        "metric": "equityChanges",
        "reason": "이 재무실적 발표 원문에 자본변동표 미인쇄"
      }
    ],
    "validation": {
      "balanceResidualMillion": "0",
      "incomeResidualMillion": "0",
      "currentSourceAmountCount": 5,
      "detailHierarchyComplete": false
    },
    "completenessNote": "감사상태 미확인 단일 펀드 상반기 회계상 인쇄 5계정 · 세무상 분배가능이익과 구분 · 영업이익·현금흐름표·자본변동표 미확보 · 정기 반기보고서 대체 아님 · TTM 미포함",
    "sourceDiscrepancies": [
      {
        "pageOrdinal": 15,
        "lineOrdinal": 8,
        "rawLine": "• 2026년 상반기 및 전년 동기 손익 비교(분기 비교)",
        "reason": "상반기 설명·현재 열과 달리 괄호는 분기 비교로 인쇄됨. 원문을 수정하지 않고 명시 2026년 상반기 현재 열만 추출"
      },
      {
        "pageOrdinal": 13,
        "lineOrdinals": [
          18,
          21,
          30,
          39
        ],
        "rawLines": [
          "   현금 및 예치금                          49,699             47,043        사채                               10,000             10,000",
          "   운용자산                             956,438            911,257        차입금                             155,000             80,000",
          "   기타자산                                2,401             2,032        기타부채                                 48                    6",
          " 자산총계                             1,008,537            960,332     부채 및 자본총계                        1,008,537            960,332"
        ],
        "printedDetailSumMillion": "1008538",
        "printedTotalMillion": "1008537",
        "residualMillion": "1",
        "reason": "원문 자산 세부합 1,008,538과 자산총계 1,008,537 사이 1백만원 잔차 미해결. 추정 조정금액·반올림 허용을 적용하지 않으며 세부계층과 전체표는 미검증"
      }
    ],
    "excludedComparatives": [
      {
        "pageOrdinal": 14,
        "reason": "2026년 2분기 값은 상반기 누적값이 아니므로 추출하지 않음"
      },
      {
        "pageOrdinal": 15,
        "lineOrdinal": 36,
        "currentTokenIndex": 2,
        "printedAmount": "39,930",
        "reason": "세무상 분배가능이익은 회계적 당기순이익 26,771과 다른 개념이며 대체하지 않음"
      }
    ],
    "supportingCurrentIdentityWitness": {
      "pageOrdinal": 15,
      "lineOrdinal": 34,
      "rawLine": " 운용비용 총계                          7,626           5,105     운용비용 총계                       7,626            5,105",
      "accountLabel": "운용비용 총계",
      "currentTokenIndex": 0,
      "printedAmount": "7,626",
      "printedUnit": "백만원",
      "role": "printed expense identity witness only; not additional stored metric"
    }
  }
}''') as Map<String, dynamic>;
  static bool supports(Map document) =>
      document['metadata'] is Map &&
      jsonEncode(document['metadata']) == jsonEncode(profile['metadata']);
  static void verifyPdf(Map metadata, List<int> bytes) {
    if (jsonEncode(metadata) != jsonEncode(profile['metadata']) ||
        bytes.length > 20 * 1024 * 1024 ||
        sha256.convert(bytes).toString() != metadata['sha256']) {
      throw const FormatException('Exact own half-year results PDF required');
    }
  }

  static Map<String, dynamic> parseRaw(Map metadata, List<int> bytes) {
    if (jsonEncode(metadata) != jsonEncode(profile['metadata']) ||
        bytes.length > 4 * 1024 * 1024 ||
        sha256.convert(bytes).toString() != profile['rawTextSha256']) {
      throw const FormatException('Exact own half-year complete text required');
    }
    final text = utf8.decode(bytes), pages = text.split('\f');
    if (!pages[0].contains('KB발해인프라투융자회사') ||
        !pages[12].contains('2026년 상반기 및 전년 동기 재무상태표 비교') ||
        !pages[12].contains('(단위:백만원)') ||
        !pages[12].contains('2026년 상반기               2025년 상반기') ||
        !pages[14].contains('<회계상 운용손익>') ||
        !pages[14].contains('2026년 상반기           2025년 상반기') ||
        !pages[14].contains('(단위:백만원)')) {
      throw const FormatException(
        'Own issuer/current H1/accounting column/unit proof missing',
      );
    }
    final r =
        jsonDecode(jsonEncode(profile['expected'])) as Map<String, dynamic>;
    for (final c in r['accounts'] as List) {
      final line = pages[c['pageOrdinal'] - 1].split(
        '\n',
      )[c['lineOrdinal'] - 1];
      final tokens = RegExp(r'(?<![\w,])(?:\d{1,3}(?:,\d{3})+|\d+)(?![\w,])')
          .allMatches(line)
          .map((v) => v[0]!)
          .toList();
      final index = c['currentTokenIndex'] as int;
      if (line != c['rawLine'] ||
          index >= tokens.length ||
          !line.contains(c['accountLabel'])) {
        throw const FormatException(
          'Bound own current accounting coordinate missing',
        );
      }
      final token = tokens[index];
      c['printedAmount'] = token;
      c['amountInteger'] =
          (BigInt.parse(token.replaceAll(',', '')) * BigInt.from(1000000))
              .toString();
    }
    final a = r['accounts'] as List;
    BigInt amount(int i) => BigInt.parse(a[i]['amountInteger']);
    final expense = RegExp(r'운용비용 총계\s+(\d{1,3}(?:,\d{3})+)')
        .firstMatch(pages[14].split('\n')[33])?[1];
    if (expense == null ||
        amount(0) - amount(1) - amount(2) != BigInt.zero ||
        amount(3) -
                BigInt.parse(expense.replaceAll(',', '')) *
                    BigInt.from(1000000) -
                amount(4) !=
            BigInt.zero) {
      throw const FormatException('Current printed BS/PL identity failed');
    }
    return validateRows([r]).single;
  }

  static List<Map<String, dynamic>> validateRows(dynamic input) {
    if (input is! List ||
        input.length != 1 ||
        jsonEncode(input.single) != jsonEncode(profile['expected'])) {
      throw const FormatException(
        'Exact partial own half-year source contract required',
      );
    }
    return [Map<String, dynamic>.from(input.single)];
  }
}
