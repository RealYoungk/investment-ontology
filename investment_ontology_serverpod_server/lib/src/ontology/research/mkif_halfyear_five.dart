import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One own financial-results appendix, never a regular half-year report.
abstract final class MkifHalfYearFive {
  static const category = 'printedUnauditedHalfYearFundCategories';
  static final profile = jsonDecode(r'''{
  "metadata": {
    "corpCode": "00435297",
    "title": "MKIF 2026년 상반기 비감사 별도 재무실적",
    "documentType": "operatingReport",
    "provider": "officialIR",
    "providerReceipt": null,
    "providerDocumentId": null,
    "periodStart": "2026-01-01",
    "periodEnd": "2026-06-30",
    "publishedAt": "2026-07-29",
    "officialUrl": "https://www.mkif.com/assets/mkif/en/investor-centre/public-filings-and-reports/2026/ir-release-2607-1h-2026-financial-traffic-results-eng.pdf",
    "sha256": "6ca659a9b5f54e2c27fc0359e44babc1e98d1b604ccc78a43269c095d226a87b",
    "issuerQuote": "Macquarie Korea Infrastructure Fund",
    "periodQuote": "For the six months ended 30 June 2026",
    "numericState": "notExtracted",
    "financialValues": null,
    "publicContent": "linkOnly"
  },
  "rawTextSha256": "293699ca24e7c5ae4ae70214918ccd0da8dd8bfb806f9f66701e828808930036",
  "expected": {
    "corpCode": "00435297",
    "documentType": "operatingReport",
    "provider": "officialIR",
    "providerReceipt": null,
    "officialUrl": "https://www.mkif.com/assets/mkif/en/investor-centre/public-filings-and-reports/2026/ir-release-2607-1h-2026-financial-traffic-results-eng.pdf",
    "sha256": "6ca659a9b5f54e2c27fc0359e44babc1e98d1b604ccc78a43269c095d226a87b",
    "periodStart": "2026-01-01",
    "periodEnd": "2026-06-30",
    "categorySchema": "printedUnauditedHalfYearFundCategories",
    "basis": "OFS",
    "periodKind": "ownHalfYear",
    "auditStatus": "unaudited",
    "observationRole": "currentOwn",
    "currency": "KRW",
    "printedUnit": "백만원",
    "precisionUnit": "1000000",
    "numericState": "partialPrintedHalfYearFundFive",
    "publicContent": "sourceLinkAndValues",
    "extractedBy": "fixedPdfTextRule",
    "parserVersion": "mkif-own-halfyear-five-v1",
    "rawTextSha256": "293699ca24e7c5ae4ae70214918ccd0da8dd8bfb806f9f66701e828808930036",
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
        "accountLabel": "Total Assets",
        "pageOrdinal": 4,
        "lineOrdinal": 19,
        "rawLine": "Total Assets                                                                               5,525,392                     5,480,790",
        "printedAmount": "5,525,392",
        "amountInteger": "5525392000000",
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
        "accountLabel": "Total Liabilities",
        "pageOrdinal": 4,
        "lineOrdinal": 25,
        "rawLine": "Total Liabilities                                                                             475,949                      474,406",
        "printedAmount": "475,949",
        "amountInteger": "475949000000",
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
        "metric": "equity",
        "accountLabel": "Total Shareholders’ Equity",
        "pageOrdinal": 4,
        "lineOrdinal": 30,
        "rawLine": "Total Shareholders’ Equity                                                                 5,049,443                     5,006,384",
        "printedAmount": "5,049,443",
        "amountInteger": "5049443000000",
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
        "metric": "fundOperatingIncome",
        "accountLabel": "Revenue",
        "pageOrdinal": 5,
        "lineOrdinal": 6,
        "rawLine": "Revenue                                                                260,021                 276,905                   (6.1%)",
        "printedAmount": "260,021",
        "amountInteger": "260021000000",
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
        "accountLabel": "Net Income",
        "pageOrdinal": 5,
        "lineOrdinal": 15,
        "rawLine": "Net Income                                                             225,050                 243,538                   (7.6%)",
        "printedAmount": "225,050",
        "amountInteger": "225050000000",
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
        "reason": "원문 손익계산서에 영업이익 항목이 인쇄되지 않음"
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
    "completenessNote": "비감사 별도 상반기 재무실적의 인쇄 5계정 · 영업이익·현금흐름표·자본변동표 미확보 · 정기 반기보고서 대체 아님 · TTM 미포함"
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
    if (!pages[0].contains('Macquarie Korea Infrastructure Fund') ||
        !pages[3].contains('As at 30 June 2026 and 31 December 2025') ||
        !pages[3].contains('(Unit: KRW million)') ||
        !pages[3].contains(
          '30 Jun 2026 figures are unaudited, non-consolidated basis',
        ) ||
        !pages[4].contains('For the six months ended 30 June 2026') ||
        !pages[4].contains('Unaudited, non-consolidated')) {
      throw const FormatException(
        'Own issuer/current half-year/basis/unit proof missing',
      );
    }
    final r =
        jsonDecode(jsonEncode(profile['expected'])) as Map<String, dynamic>;
    for (final c in r['accounts'] as List) {
      final line = pages[c['pageOrdinal'] - 1].split(
        '\n',
      )[c['lineOrdinal'] - 1];
      final token = RegExp(r'(?<![\w])\d{1,3}(?:,\d{3})+(?![\w])')
          .firstMatch(line)?[0];
      if (line != c['rawLine'] ||
          token == null ||
          !line.trimLeft().startsWith(c['accountLabel'])) {
        throw const FormatException(
          'Bound printed current account coordinate missing',
        );
      }
      c['printedAmount'] = token;
      c['amountInteger'] =
          (BigInt.parse(token.replaceAll(',', '')) * BigInt.from(1000000))
              .toString();
    }
    final a = r['accounts'] as List;
    BigInt amount(int i) => BigInt.parse(a[i]['amountInteger']);
    final expense = RegExp(r'Expenses\s+(\d{1,3}(?:,\d{3})+)')
        .firstMatch(pages[4].split('\n')[10])?[1];
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
