import 'dart:convert';

abstract final class SplitPlanSourceRegistry {
  static const rows = <Map<String, dynamic>>[
    {
      "corpCode": "02038566",
      "targetPrintedName": "주식회사 네오뷰",
      "filingActorCorpCode": "00390365",
      "filingActorPrintedName": "주식회사 토비스",
      "documentType": "splitSecuritiesRegistrationStatement",
      "provider": "KIND",
      "providerReceipt": "20260421001384",
      "officialUrl": "https://kind.krx.co.kr/external/2026/04/21/000420/20260421001384/10085.htm",
      "sha256":
          "f7ebfd0b1b0b7cfbabd8bfb3e57cec6dabb7c0dded7cf6e7aa8bf48e34e27f44",
      "byteLength": 3344163,
      "filingDate": "2026-04-21",
      "actualEstablishedDate": "2026-07-01",
      "establishmentProfileUrl":
          "https://opendart.fss.or.kr/api/company.json?corp_code=02038566",
      "establishmentProfileRetrievedAt": "2026-09-17T14:14:39.413453Z",
      "plannedSplitDate": "2026-07-01",
      "plannedSplitDateQuote": "분할회사는 2026년 07월 01일을 분할기일로하여 인적분할을 추진하고 있습니다.",
      "issuerRole": "proposedSplitEntity",
      "delegatedFiler": true,
      "delegationQuote": "본 증권신고서 및 투자설명서의 제출의무자는 분할신설회사인 주식회사 네오뷰(가칭)이나 제출일 현재 분할절차가 완료되지 아니하여 분할회사가 분할신설회사인 주식회사 네오뷰(가칭)를 대신하여 본 증권신고서 및 투자설명서를 제출합니다.",
      "numericState": "notExtracted",
      "financialValues": null,
      "publicContent": "linkOnly",
      "wholeFinancialStatementsComplete": false,
      "regularApiCompletion": false,
      "annualPeriodCount": 0,
      "preincorporationFiveYearAbsence": "unconfirmed",
      "readScope": "cover filer identity and delegation section only; full financial statements not reviewed",
    },
    {
      "corpCode": "02042949",
      "targetPrintedName": "한화머시너리앤서비스홀딩스 주식회사",
      "filingActorCorpCode": "00160588",
      "filingActorPrintedName": "주식회사 한화",
      "documentType": "splitSecuritiesRegistrationStatement",
      "provider": "KIND",
      "providerReceipt": "20260514003206",
      "officialUrl": "https://kind.krx.co.kr/external/2026/05/14/001476/20260514003206/10085.htm",
      "sha256":
          "70773f106087e267c96b2ed3ea7459a7256ee4aae4bc0d8d63ea37d9c078dbe8",
      "byteLength": 14500668,
      "filingDate": "2026-05-14",
      "actualEstablishedDate": "2026-08-03",
      "establishmentProfileUrl":
          "https://opendart.fss.or.kr/api/company.json?corp_code=02042949",
      "establishmentProfileRetrievedAt": "2026-09-17T14:13:14.979058Z",
      "plannedSplitDate": "2026-08-01",
      "plannedSplitDateQuote": "분할신설회사는 2026년 08월 01일을 분할기일로 하여 독점규제 및 공정거래에 관한 법률상 지주회사로 설립될 예정입니다.",
      "issuerRole": "proposedSplitEntity",
      "delegatedFiler": true,
      "delegationQuote": "본 증권신고서 및 투자설명서의 제출의무자는 분할신설회사인 한화머시너리앤서비스홀딩스 주식회사(가칭)이나 제출일 현재 분할절차가 완료되지 아니하여 분할회사가 분할신설회사인 한화머시너리앤서비스홀딩스 주식회사(가칭)를 대신하여 본 증권신고서 및 투자설명서를 제출합니다.",
      "numericState": "notExtracted",
      "financialValues": null,
      "publicContent": "linkOnly",
      "wholeFinancialStatementsComplete": false,
      "regularApiCompletion": false,
      "annualPeriodCount": 0,
      "preincorporationFiveYearAbsence": "unconfirmed",
      "readScope": "cover filer identity and delegation section only; full financial statements not reviewed",
    },
  ];
  static bool supports(String code) => rows.any((r) => r['corpCode'] == code);
  static Map<String, dynamic> validate(String corp, dynamic value) {
    if (value is! Map ||
        value['state'] != 'ready' ||
        value['provider'] != 'verified-delegated-split-plan') {
      throw const FormatException('Split provider mismatch');
    }
    final source = value['source'];
    final received = value['rows'];
    final expected = rows.singleWhere((r) => r['corpCode'] == corp);
    if (source is! Map ||
        source['kind'] != 'officialFile' ||
        source['url'] != 'https://kind.krx.co.kr' ||
        source['reference'] !=
            'parent-submitted-split-plan;link-only;no-own-period-or-numeric-assertion' ||
        received is! List ||
        received.length != 1 ||
        jsonEncode(received.single) != jsonEncode(expected)) {
      throw const FormatException('Split target/source metadata mismatch');
    }
    return Map<String, dynamic>.from(received.single as Map);
  }
}
