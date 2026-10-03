// Six exact own-primary and explicitly linked audit witness sources.
const anymediAuditPeriodProfileJson = r'''{
  "receipt": "20230103000440",
  "corpCode": "01507810",
  "name": "애니메디솔루션(주)",
  "bsnsYear": 2021,
  "basis": "separate",
  "reportName": "[기재정정]사업보고서 (2021.12)",
  "classification": "검산·신원·기간 원인 미확정(공유 실패메시지만 확인)",
  "final27": false,
  "numericAccepted": false,
  "fullOriginalIndependentReview": false,
  "primarySource": {
    "path": "/Users/realyoungk/investment-ontology/outputs/filing-collection-priority/rare-shape-source-corpus/20230103000440/ofs.html",
    "exists": true,
    "sha256": "3facf96c38b2918f37a05d084b05ebe146e9fc1b07f312c2b4d770dbae9546d6",
    "ledgerSHAMatch": true,
    "bytes": 54033,
    "sourceURI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230103000440&dcmNo=8931786&eleId=23&offset=320451&length=61445&dtd=dart3.xsd",
    "coverURI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230103000440&dcmNo=8931786&eleId=3&offset=68797&length=4037&dtd=dart3.xsd",
    "coverPath": "/Users/realyoungk/investment-ontology/outputs/filing-collection-priority/rare-shape-source-corpus/20230103000440/cover.html",
    "shellPath": "/Users/realyoungk/investment-ontology/outputs/filing-collection-priority/rare-shape-source-corpus/20230103000440/shell.html",
    "metadataSHA": "3facf96c38b2918f37a05d084b05ebe146e9fc1b07f312c2b4d770dbae9546d6",
    "units": [
      "원",
      "원",
      "원",
      "원"
    ],
    "hasNumericTable": true,
    "printedNonApplicableLiteral": null,
    "candidateRowsNotValidated": [
      [
        "자산총계",
        "",
        "11,732,753,599",
        "",
        "14,934,645,548",
        "",
        "4,182,524,283"
      ],
      [
        "부채총계",
        "",
        "5,050,666,711",
        "",
        "13,422,250,361",
        "",
        "8,717,382,036"
      ],
      [
        "자본총계",
        "",
        "6,682,086,888",
        "",
        "1,512,395,187",
        "",
        "(4,534,857,753)"
      ],
      [
        "부채와자본총계",
        "",
        "11,732,753,599",
        "",
        "14,934,645,548",
        "",
        "4,182,524,283"
      ],
      [
        "매출액",
        "",
        "334,339,638",
        "",
        "131,746,309",
        "",
        "83,507,602"
      ],
      [
        "영업손실",
        "",
        "(7,870,683,519)",
        "",
        "(3,739,473,096)",
        "",
        "(2,325,893,499)"
      ],
      [
        "당기순손실",
        "",
        "(11,157,925,382)",
        "",
        "(4,555,457,899)",
        "",
        "(3,097,620,083)"
      ],
      [
        "당기순손실",
        "-",
        "-",
        "-",
        "(3,097,620,083)",
        "(3,097,620,083)"
      ],
      [
        "당기순손실",
        "-",
        "-",
        "-",
        "(4,555,457,899)",
        "(4,555,457,899)"
      ],
      [
        "당기순손실",
        "-",
        "-",
        "-",
        "(11,157,925,382)",
        "(11,157,925,382)"
      ],
      [
        "영업활동으로인한현금흐름",
        "",
        "(6,340,522,116)",
        "",
        "(3,081,788,417)",
        "",
        "(2,003,404,950)"
      ],
      [
        "기초현금및현금성자산",
        "",
        "7,734,470,873",
        "",
        "2,723,557,238",
        "",
        "85,095,932"
      ],
      [
        "기말현금및현금성자산",
        "",
        "3,077,502,802",
        "",
        "7,734,470,873",
        "",
        "2,723,557,238"
      ]
    ]
  },
  "auditSource": [
    {
      "label": "opinion",
      "observedTitle": "독립된 감사인의 감사보고서",
      "coords": {
        "rcpNo": "20221226000436",
        "dcmNo": "8921665",
        "eleId": "2",
        "offset": "7045",
        "length": "4554",
        "dtd": "dart3.xsd"
      },
      "URI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20221226000436&dcmNo=8921665&eleId=2&offset=7045&length=4554&dtd=dart3.xsd",
      "SHA": "c888bfea3ba196afd485945f3f3e5f6ab40f67bf08d403192e9ef7eb4e0df7cf",
      "httpStatus": 200,
      "bytes": 8747,
      "newGET": 1,
      "API": 0,
      "DB": 0
    },
    {
      "label": "statement",
      "observedTitle": "(첨부)재 무 제 표",
      "coords": {
        "rcpNo": "20221226000436",
        "dcmNo": "8921665",
        "eleId": "3",
        "offset": "11629",
        "length": "344915",
        "dtd": "dart3.xsd"
      },
      "URI": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20221226000436&dcmNo=8921665&eleId=3&offset=11629&length=344915&dtd=dart3.xsd",
      "SHA": "a12df57a4c0d27828bddeba057170b51a4a159ffb99c65450138da7fc40df20c",
      "httpStatus": 200,
      "bytes": 345610,
      "newGET": 1,
      "API": 0,
      "DB": 0
    }
  ],
  "auditShell": {
    "URI": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20221226000436&dcmNo=8921665",
    "responseURI": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20221226000436&dcmNo=8921665",
    "httpStatus": 200,
    "bytes": 42685,
    "SHA": "4a2a6c19e0094bd379e82dd8454b99419275081a7aff46bbc9a6ef93bf66a1d4",
    "newGET": 1,
    "API": 0,
    "DB": 0,
    "observedLinkFromTargetReceipt": "20230103000440",
    "sourceReceipt": "20221226000436",
    "observedDocumentNumber": "8921665"
  },
  "currentPeriodStart": "2021-01-01",
  "currentPeriodEnd": "2021-12-31",
  "coverPrintedEndConflict": "2021-12-21",
  "coverConflictNotRewritten": true,
  "sourceNumbersFrom": "own target main annual OFS body, not audit transplant",
  "auditVerbatimPeriodQuote": "해당 재무제표는 2021년 12월 31일 현재의 재무상태표, 동일로 종료되는 보고기간의 포괄손익계산서, 자본변동표, 현금흐름표",
  "core8": [
    {
      "role": "assets",
      "mainRowIndex": 19,
      "mainColumn": 2,
      "mainRawRow": [
        "자산 총계",
        "",
        "11,732,753,599",
        "",
        "14,934,645,548",
        "",
        "4,182,524,283"
      ],
      "auditRowIndex": 29,
      "auditColumn": 3,
      "auditRawRow": [
        "자산 총계",
        "",
        "",
        "11,732,753,599",
        "",
        "14,934,645,548"
      ],
      "amountKRW": "11732753599"
    },
    {
      "role": "liabilities",
      "mainRowIndex": 37,
      "mainColumn": 2,
      "mainRawRow": [
        "부채 총계",
        "",
        "5,050,666,711",
        "",
        "13,422,250,361",
        "",
        "8,717,382,036"
      ],
      "auditRowIndex": 47,
      "auditColumn": 3,
      "auditRawRow": [
        "부채 총계",
        "",
        "",
        "5,050,666,711",
        "",
        "13,422,250,361"
      ],
      "amountKRW": "5050666711"
    },
    {
      "role": "equity",
      "mainRowIndex": 43,
      "mainColumn": 2,
      "mainRawRow": [
        "자본 총계",
        "",
        "6,682,086,888",
        "",
        "1,512,395,187",
        "",
        "(4,534,857,753)"
      ],
      "auditRowIndex": 53,
      "auditColumn": 3,
      "auditRawRow": [
        "자본 총계",
        "",
        "",
        "6,682,086,888",
        "",
        "1,512,395,187"
      ],
      "amountKRW": "6682086888"
    },
    {
      "role": "revenue",
      "mainRowIndex": 51,
      "mainColumn": 2,
      "mainRawRow": [
        "매출액",
        "",
        "334,339,638",
        "",
        "131,746,309",
        "",
        "83,507,602"
      ],
      "auditRowIndex": 61,
      "auditColumn": 3,
      "auditRawRow": [
        "매출액",
        "24",
        "",
        "334,339,638",
        "",
        "131,746,309"
      ],
      "amountKRW": "334339638"
    },
    {
      "role": "operating",
      "mainRowIndex": 55,
      "mainColumn": 2,
      "mainRawRow": [
        "영업손실",
        "",
        "(7,870,683,519)",
        "",
        "(3,739,473,096)",
        "",
        "(2,325,893,499)"
      ],
      "auditRowIndex": 65,
      "auditColumn": 3,
      "auditRawRow": [
        "영업손실",
        "",
        "",
        "(7,870,683,519)",
        "",
        "(3,739,473,096)"
      ],
      "amountKRW": "-7870683519"
    },
    {
      "role": "netIncome",
      "mainRowIndex": 62,
      "mainColumn": 2,
      "mainRawRow": [
        "당기순손실",
        "",
        "(11,157,925,382)",
        "",
        "(4,555,457,899)",
        "",
        "(3,097,620,083)"
      ],
      "auditRowIndex": 72,
      "auditColumn": 3,
      "auditRawRow": [
        "당기순손실",
        "",
        "",
        "(11,157,925,382)",
        "",
        "(4,555,457,899)"
      ],
      "amountKRW": "-11157925382"
    },
    {
      "role": "cfo",
      "mainRowIndex": 104,
      "mainColumn": 2,
      "mainRawRow": [
        "영업활동으로 인한 현금흐름",
        "",
        "(6,340,522,116)",
        "",
        "(3,081,788,417)",
        "",
        "(2,003,404,950)"
      ],
      "auditRowIndex": 108,
      "auditColumn": 3,
      "auditRawRow": [
        "영업활동으로 인한 현금흐름",
        "",
        "",
        "(6,340,522,116)",
        "",
        "(3,081,788,417)"
      ],
      "amountKRW": "-6340522116"
    },
    {
      "role": "capex",
      "mainRowIndex": 117,
      "mainColumn": 1,
      "mainRawRow": [
        "유형자산의 취득",
        "(1,202,826,176)",
        "",
        "(4,295,966,904)",
        "",
        "(159,475,708)",
        ""
      ],
      "auditRowIndex": 121,
      "auditColumn": 2,
      "auditRawRow": [
        "유형자산의 취득",
        "11",
        "(1,202,826,176)",
        "",
        "(4,295,966,904)",
        ""
      ],
      "amountKRW": "-1202826176"
    }
  ],
  "mainCE": {
    "openingRowIndex": 87,
    "NIRowIndex": 89,
    "closingRowIndex": 97,
    "wholeColumn": 5,
    "movementRows": [
      {
        "rowIndex": 89,
        "rawRow": [
          "당기순손실",
          "-",
          "-",
          "-",
          "(11,157,925,382)",
          "(11,157,925,382)"
        ]
      },
      {
        "rowIndex": 90,
        "rawRow": [
          "주식보상비용",
          "-",
          "-",
          "24,132,294",
          "-",
          "24,132,294"
        ]
      },
      {
        "rowIndex": 92,
        "rawRow": [
          "유상증자(전환우선주)",
          "61,015,000",
          "3,537,700,390",
          "-",
          "-",
          "3,598,715,390"
        ]
      },
      {
        "rowIndex": 93,
        "rawRow": [
          "유상증자(보통주)",
          "2,820,000",
          "146,476,000",
          "-",
          "-",
          "149,296,000"
        ]
      },
      {
        "rowIndex": 94,
        "rawRow": [
          "무상증자(보통주 및 전환우선주)",
          "2,886,000,000",
          "(2,930,092,096)",
          "-",
          "-",
          "(44,092,096)"
        ]
      },
      {
        "rowIndex": 95,
        "rawRow": [
          "상환전환우선주의 보통주 전환",
          "1,384,375,000",
          "10,981,665,845",
          "-",
          "-",
          "12,366,040,845"
        ]
      },
      {
        "rowIndex": 96,
        "rawRow": [
          "주식매입선택권의 행사",
          "82,125,000",
          "151,399,650",
          "-",
          "-",
          "233,524,650"
        ]
      }
    ],
    "openingRawRow": [
      "2021년 1월 1일",
      "657,665,000",
      "10,608,047,130",
      "7,818,393",
      "(9,761,135,336)",
      "1,512,395,187"
    ],
    "NIRawRow": [
      "당기순손실",
      "-",
      "-",
      "-",
      "(11,157,925,382)",
      "(11,157,925,382)"
    ],
    "closingRawRow": [
      "2021년 12월 31일",
      "5,074,000,000",
      "22,495,196,919",
      "31,950,687",
      "(20,919,060,718)",
      "6,682,086,888"
    ]
  },
  "auditCE": {
    "openingRowIndex": 91,
    "NIRowIndex": 93,
    "closingRowIndex": 101,
    "wholeColumn": 6,
    "movementRows": [
      {
        "rowIndex": 93,
        "rawRow": [
          "당기순손실",
          "",
          "-",
          "-",
          "-",
          "(11,157,925,382)",
          "(11,157,925,382)"
        ]
      },
      {
        "rowIndex": 94,
        "rawRow": [
          "주식보상비용",
          "22",
          "-",
          "-",
          "24,132,294",
          "-",
          "24,132,294"
        ]
      },
      {
        "rowIndex": 96,
        "rawRow": [
          "유상증자(전환우선주)",
          "20",
          "61,015,000",
          "3,537,700,390",
          "-",
          "-",
          "3,598,715,390"
        ]
      },
      {
        "rowIndex": 97,
        "rawRow": [
          "유상증자(보통주)",
          "20",
          "2,820,000",
          "146,476,000",
          "-",
          "-",
          "149,296,000"
        ]
      },
      {
        "rowIndex": 98,
        "rawRow": [
          "무상증자(보통주 및 전환우선주)",
          "20",
          "2,886,000,000",
          "(2,930,092,096)",
          "-",
          "-",
          "(44,092,096)"
        ]
      },
      {
        "rowIndex": 99,
        "rawRow": [
          "상환전환우선주의 보통주 전환",
          "20",
          "1,384,375,000",
          "10,981,665,845",
          "-",
          "-",
          "12,366,040,845"
        ]
      },
      {
        "rowIndex": 100,
        "rawRow": [
          "주식매입선택권의 행사",
          "20",
          "82,125,000",
          "151,399,650",
          "-",
          "-",
          "233,524,650"
        ]
      }
    ],
    "openingRawRow": [
      "2021년 1월 1일(당기초)",
      "",
      "657,665,000",
      "10,608,047,130",
      "7,818,393",
      "(9,761,135,336)",
      "1,512,395,187"
    ],
    "NIRawRow": [
      "당기순손실",
      "",
      "-",
      "-",
      "-",
      "(11,157,925,382)",
      "(11,157,925,382)"
    ],
    "closingRawRow": [
      "2021년 12월 31일(당기말)",
      "",
      "5,074,000,000",
      "22,495,196,919",
      "31,950,687",
      "(20,919,060,718)",
      "6,682,086,888"
    ]
  },
  "mainCashRows": [
    {
      "rowIndex": 8,
      "rawRow": [
        "현금및현금성자산",
        "3,077,502,802",
        "",
        "7,734,470,873",
        "",
        "2,723,557,238",
        ""
      ]
    },
    {
      "rowIndex": 104,
      "rawRow": [
        "영업활동으로 인한 현금흐름",
        "",
        "(6,340,522,116)",
        "",
        "(3,081,788,417)",
        "",
        "(2,003,404,950)"
      ]
    },
    {
      "rowIndex": 109,
      "rawRow": [
        "투자활동으로 인한 현금흐름",
        "",
        "(1,589,957,713)",
        "",
        "(4,476,637,333)",
        "",
        "(505,779,297)"
      ]
    },
    {
      "rowIndex": 119,
      "rawRow": [
        "재무활동으로 인한 현금흐름",
        "",
        "3,273,511,758",
        "",
        "12,569,339,385",
        "",
        "5,147,645,553"
      ]
    },
    {
      "rowIndex": 133,
      "rawRow": [
        "현금및현금성자산의 순증감",
        "",
        "(4,656,968,071)",
        "",
        "5,010,913,635",
        "",
        "2,638,461,306"
      ]
    },
    {
      "rowIndex": 134,
      "rawRow": [
        "기초 현금및현금성자산",
        "",
        "7,734,470,873",
        "",
        "2,723,557,238",
        "",
        "85,095,932"
      ]
    },
    {
      "rowIndex": 135,
      "rawRow": [
        "기말 현금및현금성자산",
        "",
        "3,077,502,802",
        "",
        "7,734,470,873",
        "",
        "2,723,557,238"
      ]
    }
  ],
  "auditCashRows": [
    {
      "rowIndex": 18,
      "rawRow": [
        "현금및현금성자산",
        "5,6,35,36,37",
        "3,077,502,802",
        "",
        "7,734,470,873",
        ""
      ]
    },
    {
      "rowIndex": 108,
      "rawRow": [
        "영업활동으로 인한 현금흐름",
        "",
        "",
        "(6,340,522,116)",
        "",
        "(3,081,788,417)"
      ]
    },
    {
      "rowIndex": 113,
      "rawRow": [
        "투자활동으로 인한 현금흐름",
        "",
        "",
        "(1,589,957,713)",
        "",
        "(4,476,637,333)"
      ]
    },
    {
      "rowIndex": 123,
      "rawRow": [
        "재무활동으로 인한 현금흐름",
        "",
        "",
        "3,273,511,758",
        "",
        "12,569,339,385"
      ]
    },
    {
      "rowIndex": 136,
      "rawRow": [
        "현금및현금성자산의 순증감",
        "",
        "",
        "(4,656,968,071)",
        "",
        "5,010,913,635"
      ]
    },
    {
      "rowIndex": 137,
      "rawRow": [
        "기초 현금및현금성자산",
        "",
        "",
        "7,734,470,873",
        "",
        "2,723,557,238"
      ]
    },
    {
      "rowIndex": 138,
      "rawRow": [
        "기말 현금및현금성자산",
        "",
        "",
        "3,077,502,802",
        "",
        "7,734,470,873"
      ]
    }
  ],
  "differences": {
    "auditMainCore0": 0,
    "auditMainCore1": 0,
    "auditMainCore2": 0,
    "auditMainCore3": 0,
    "auditMainCore4": 0,
    "auditMainCore5": 0,
    "auditMainCore6": 0,
    "auditMainCore7": 0,
    "mainBS": 0,
    "mainWholeNI": 0,
    "mainClosingE": 0,
    "mainCERoll": 0,
    "maincurrentActivities": 0,
    "maincurrentCashRoll": 0,
    "maincurrentBSCash": 0,
    "mainpriorActivities": 0,
    "mainpriorCashRoll": 0,
    "mainpriorBSCash": 0,
    "mainPriorCloseCurrentOpening": 0,
    "auditBS": 0,
    "auditWholeNI": 0,
    "auditClosingE": 0,
    "auditCERoll": 0,
    "auditcurrentActivities": 0,
    "auditcurrentCashRoll": 0,
    "auditcurrentBSCash": 0,
    "auditpriorActivities": 0,
    "auditpriorCashRoll": 0,
    "auditpriorBSCash": 0,
    "auditPriorCloseCurrentOpening": 0
  },
  "fullStatementCollected": false,
  "FXNotPrintedNoZeroFactInvented": true,
  "sourcePositiveCurrent8AndAuditCorroboration": true,
  "registerProfile": false,
  "newGET": 3,
  "API": 0,
  "DB": 0,
  "sourceChainIndependentVerified": {
    "targetOwnCorpAndOFSNode": {
      "rcpNo": "20230103000440",
      "dcmNo": "8931786",
      "eleId": "23",
      "offset": "320451",
      "length": "61445",
      "dtd": "dart3.xsd"
    },
    "targetOfficialUniqueAuditDocumentOption": [
      "rcpNo=20221226000436&dcmNo=8921665"
    ],
    "auditOwnCorp": [
      "01507810"
    ],
    "auditUniqueStatementAndOpinionNodes": [
      {
        "label": "opinion",
        "node": {
          "rcpNo": "20221226000436",
          "dcmNo": "8921665",
          "eleId": "2",
          "offset": "7045",
          "length": "4554",
          "dtd": "dart3.xsd"
        },
        "rawPath": "/Users/realyoungk/investment-ontology/outputs/filing-collection-priority/source-completeness-20261003/remaining_source_validation/anymedi2021-audit-opinion.html",
        "actualSHA": "c888bfea3ba196afd485945f3f3e5f6ab40f67bf08d403192e9ef7eb4e0df7cf"
      },
      {
        "label": "statement",
        "node": {
          "rcpNo": "20221226000436",
          "dcmNo": "8921665",
          "eleId": "3",
          "offset": "11629",
          "length": "344915",
          "dtd": "dart3.xsd"
        },
        "rawPath": "/Users/realyoungk/investment-ontology/outputs/filing-collection-priority/source-completeness-20261003/remaining_source_validation/anymedi2021-audit-statement.html",
        "actualSHA": "a12df57a4c0d27828bddeba057170b51a4a159ffb99c65450138da7fc40df20c"
      }
    ],
    "mainRawSHARevalidated": "3facf96c38b2918f37a05d084b05ebe146e9fc1b07f312c2b4d770dbae9546d6",
    "coverRawSHA": "65a5c99e07f3d3dbb4f90d58d9874191bef1c0d8c4a22903a7c37d8d591fb780",
    "mainShellRawSHA": "a6e4d9a4ab5812d21cd68eeaf5dedc3c6cf9f6a96fd7bc52aa29e5976a1863fd",
    "newGET": 0
  },
  "sources": [
    {
      "label": "shell",
      "file": "shell.html",
      "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230103000440",
      "sha256": "a6e4d9a4ab5812d21cd68eeaf5dedc3c6cf9f6a96fd7bc52aa29e5976a1863fd"
    },
    {
      "label": "cover",
      "file": "cover.html",
      "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230103000440&dcmNo=8931786&eleId=3&offset=68797&length=4037&dtd=dart3.xsd",
      "sha256": "65a5c99e07f3d3dbb4f90d58d9874191bef1c0d8c4a22903a7c37d8d591fb780"
    },
    {
      "label": "ofs",
      "file": "ofs.html",
      "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230103000440&dcmNo=8931786&eleId=23&offset=320451&length=61445&dtd=dart3.xsd",
      "sha256": "3facf96c38b2918f37a05d084b05ebe146e9fc1b07f312c2b4d770dbae9546d6"
    },
    {
      "label": "audit-shell",
      "file": "audit-shell.html",
      "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20221226000436&dcmNo=8921665",
      "sha256": "4a2a6c19e0094bd379e82dd8454b99419275081a7aff46bbc9a6ef93bf66a1d4"
    },
    {
      "label": "audit-opinion",
      "file": "audit-opinion.html",
      "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20221226000436&dcmNo=8921665&eleId=2&offset=7045&length=4554&dtd=dart3.xsd",
      "sha256": "c888bfea3ba196afd485945f3f3e5f6ab40f67bf08d403192e9ef7eb4e0df7cf"
    },
    {
      "label": "audit-statement",
      "file": "audit-statement.html",
      "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20221226000436&dcmNo=8921665&eleId=3&offset=11629&length=344915&dtd=dart3.xsd",
      "sha256": "a12df57a4c0d27828bddeba057170b51a4a159ffb99c65450138da7fc40df20c"
    }
  ],
  "actualStatementCaptions": {
    "main": [
      [
        "재 무 상 태 표"
      ],
      [
        "제6기 2021년 12월 31일 현재"
      ],
      [
        "제5기 2020년 12월 31일 현재"
      ],
      [
        "제4기 2019년 12월 31일 현재"
      ],
      [
        "",
        "(단위: 원)"
      ],
      [
        "과 목",
        "제6기 (2021년말)",
        "제5기 (2020년말)",
        "제4기 (2019년말)"
      ],
      [
        "제6기 2021년 12월 31일 현재"
      ],
      [
        "제6기 2021년 1월 1일부터 2021년 12월 31일까지"
      ],
      [
        "제6기 2021년 1월 1일부터 2021년 12월 31일까지"
      ],
      [
        "제6기 2021년 1월 1일부터 2021년 12월 31일까지"
      ]
    ],
    "audit": [
      [
        "애니메디솔루션 주식회사"
      ],
      [
        "제 6 기"
      ],
      [
        "2021년 01월 01일",
        "부터"
      ],
      [
        "2021년 12월 31일",
        "까지"
      ],
      [
        "제 5 기"
      ],
      [
        "2020년 01월 01일",
        "부터"
      ],
      [
        "2020년 12월 31일",
        "까지"
      ],
      [
        "\"첨부된 재무제표는 당사가 작성한 것입니다.\""
      ],
      [
        "애니메디솔루션 주식회사 대표이사 김국배"
      ],
      [
        "본점 소재지 :",
        "(도로명주소)",
        "서울특별시 송파구 올림픽로35길 137 한국광고문화회관 18층 1호"
      ],
      [
        "(전 화)",
        "02-6951-1311"
      ],
      [
        "재 무 상 태 표"
      ],
      [
        "제 6 (당) 기 2021년 12월 31일 현재"
      ],
      [
        "제 5 (전) 기 2020년 12월 31일 현재"
      ],
      [
        "애니메디솔루션 주식회사",
        "(단위: 원)"
      ],
      [
        "과 목",
        "주 석",
        "제 6 (당) 기말",
        "제 5 (전) 기말"
      ],
      [
        "자산",
        "",
        "",
        "",
        "",
        ""
      ]
    ]
  }
}''';
