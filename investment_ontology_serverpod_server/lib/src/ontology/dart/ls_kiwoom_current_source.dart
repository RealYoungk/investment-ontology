import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Five exact own annual/basis packages; no global issuer/date/unit relaxation.
abstract final class LsKiwoomCurrentSource {
  static final List _profiles = jsonDecode(
    r'''[{"receipt": "20220324000600", "corp": "00296290", "year": 2021, "name": "키움증권(주)", "basis": "consolidated", "rule": "kiwoom-2021-own-cfs-current-eight-v1", "statementLabel": "cfs", "ownCoverName": "키움증권(주)", "shellCurrentName": "키움증권", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220324000600", "sha256": "d1a8873adcb475d2ad34e3026befffb847cbcdf378a9585ffd8331791cb64892"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220324000600&dcmNo=8502035&eleId=3&offset=13103&length=4031&dtd=dart3.xsd", "sha256": "e1f89dfccb9fb2a58dc79c19eae8b7690fa530441cea5dc3a15970b95a441f84"}, {"label": "cfs", "file": "cfs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220324000600&dcmNo=8502035&eleId=19&offset=912123&length=103978&dtd=dart3.xsd", "sha256": "ae5d0f8cbff86058ceb9819c801e302b06eed5b7b221834ac7caadba14a32cf1"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220324000600&dcmNo=8502035&eleId=20&offset=1016105&length=1084531&dtd=dart3.xsd", "sha256": "0e6e482426b7eccb96b8fc5736312d17207368ddfb7673e90ca4089066f9e201"}], "rows": [{"index": 20, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "45,301,100,676,390"}, {"index": 32, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "40,999,237,946,334"}, {"index": 43, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "4,301,862,730,056"}, {"index": 52, "column": 3, "kind": "IS", "label": "영 업 수 익", "printed": "5,866,189,220,774"}, {"index": 72, "column": 3, "kind": "IS", "label": "영 업 이 익", "printed": "1,208,885,819,778"}, {"index": 77, "column": 3, "kind": "IS", "label": "당 기 순 이 익 (대손준비금 반영후 조정이익 당기: 903,901,167천원, 전기: 680,651,395천원)", "printed": "910,172,830,315"}, {"index": 150, "column": 2, "kind": "CF", "label": "영업활동으로 인한 현금흐름 (주석41)", "printed": "(3,528,473,618,059)"}, {"index": 197, "column": 1, "kind": "CF", "label": "7. 유형자산의 취득", "printed": "(15,526,716,807)"}], "rowCount": 226, "witnesses": {"1": ["제23기 (당)기 2021년 12월 31일 현재"], "4": ["키움증권주식회사와 그 종속기업", "(단위: 원)"], "5": ["과 목", "주석", "제23(당)기말", "제22(전)기말"], "47": ["제23기 (당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "50": ["키움증권주식회사와 그 종속기업", "(단위: 원)"], "51": ["과 목", "주석", "제23(당)기", "제22(전)기"], "102": ["제23기 (당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "104": ["키움증권주식회사와 그 종속기업", "(단위: 원)"], "105": ["과 목", "지배주주지분", "비지배지분", "총 계"], "106": ["자본금", "연결자본잉여금", "연결자본조정", "연결기타포괄손익누계액", "연결이익잉여금", "합 계"], "146": ["제23기 (당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "148": ["키움증권주식회사와 그 종속기업", "(단위: 원)"], "149": ["과 목", "제23기(당)기", "제22기(전)기"], "143": ["2021년 12월 31일(당기말)", "145,224,895,000", "1,038,849,055,690", "(63,598,062,610)", "12,553,569,022", "3,132,210,657,911", "4,265,240,115,013", "36,622,615,043", "4,301,862,730,056"], "125": ["2021년 1월 1일(당기초)", "127,624,890,000", "541,055,258,303", "(61,103,110,671)", "(56,548,872,009)", "2,305,698,449,788", "2,856,726,615,411", "28,185,170,872", "2,884,911,786,283"]}, "equations": [{"label": "BS", "result": [20, 2], "terms": [[32, 2, 1], [43, 2, 1]]}, {"label": "OP", "result": [72, 3], "terms": [[52, 3, 1], [63, 3, -1]]}, {"label": "NI", "result": [77, 3], "terms": [[75, 3, 1], [76, 3, -1]]}, {"label": "NIowners", "result": [77, 3], "terms": [[78, 3, 1], [79, 3, 1]]}, {"label": "CENI", "result": [77, 3], "terms": [[127, 8, 1]]}, {"label": "CFpretax", "result": [75, 3], "terms": [[151, 1, 1]]}, {"label": "CEclose", "result": [143, 8], "terms": [[125, 8, 1], [136, 8, 1], [138, 8, 1], [139, 8, 1], [140, 8, 1], [141, 8, 1], [142, 8, 1]]}, {"label": "CFO", "result": [150, 2], "terms": [[151, 1, 1], [152, 1, 1], [175, 1, 1], [186, 1, 1], [187, 1, 1], [188, 1, 1], [189, 1, 1]]}, {"label": "CFI", "result": [190, 2], "terms": [[191, 1, 1], [192, 1, 1], [193, 1, 1], [194, 1, 1], [195, 1, 1], [196, 1, 1], [197, 1, 1], [198, 1, 1], [199, 1, 1], [200, 1, 1], [201, 1, 1], [202, 1, 1], [203, 1, 1], [204, 1, 1], [205, 1, 1], [206, 1, 1]]}, {"label": "CFF", "result": [207, 2], "terms": [[208, 1, 1], [209, 1, 1], [210, 1, 1], [211, 1, 1], [212, 1, 1], [213, 1, 1], [214, 1, 1], [215, 1, 1], [216, 1, 1], [217, 1, 1], [218, 1, 1], [219, 1, 1], [220, 1, 1]]}, {"label": "cashnet", "result": [221, 2], "terms": [[150, 2, 1], [190, 2, 1], [207, 2, 1]]}, {"label": "cashclose", "result": [224, 2], "terms": [[223, 2, 1], [221, 2, 1], [222, 2, 1]]}, {"label": "CEwhole=BSwhole", "result": [143, 8], "terms": [[43, 2, 1]]}, {"label": "CEopening=BSprior", "result": [125, 8], "terms": [[43, 3, 1]]}], "noteRowCount": 2832, "noteWitnesses": {"0": ["제23(당)기 2021년 1월 1일부터 2021년 12월 31일까지"], "1": ["제22(전)기 2020년 1월 1일부터 2020년 12월 31일까지"], "2": ["키움증권주식회사와 그 종속기업"], "3": ["구 분", "주주명", "주식수(주)", "지분율(%)", "비고"], "859": ["(단위: 천원)"], "860": ["구 분", "당기말", "전기말"], "861": ["현금 및현금성자산", "현금", "344,337", "478,111"], "862": ["요구불예금", "284,852,804", "309,713,379"], "863": ["외화예금", "9,841,304", "11,125,019"], "864": ["양도성예금증서", "-", "69,277,822"], "865": ["기타", "739,977,612", "457,410,232"], "866": ["소 계", "1,035,016,056", "848,004,563"], "867": ["예치금", "원화예치금", "2,548,270,324", "960,506,106"], "868": ["외화예치금", "3,036,584,777", "1,811,405,543"], "869": ["소 계", "5,584,855,101", "2,771,911,649"], "870": ["합 계", "6,619,871,157", "3,619,916,212"]}, "noteEquations": [{"label": "cash+deposit=BSnote", "result": [870, 1], "terms": [[866, 1, 1], [869, 1, 1]], "expectedResidual": "0"}, {"label": "cash-detail", "result": [866, 1], "terms": [[861, 2, 1], [862, 1, 1], [863, 1, 1], [864, 1, 1], [865, 1, 1]], "expectedResidual": "-1"}, {"label": "deposit-detail", "result": [869, 1], "terms": [[867, 2, 1], [868, 1, 1]], "expectedResidual": "0"}], "notePrecisionEvidence": {"cfWonMinusNoteCashTimes1000": 156, "bsWonMinusNoteCombinedTimes1000": -7}, "noteScope": {"note": "17. 현금 및 예치금", "printedUnit": "천원", "statementUnit": "원", "combinedSubtotalResidual": "0", "cashDetailResidual": "-1", "depositDetailResidual": "0", "crossPrecisionEqualityClaim": false, "roundingCauseClaim": false, "allNotesVerified": false}, "periodEvidence": {"ownCoverYear": 2021, "sameCurrentBSPLCECFHeaders": true, "wholeEntityNI": true, "priorNumericPeriodsCollected": false}}, {"receipt": "20230316001115", "corp": "00330424", "year": 2022, "name": "엘에스증권(주)", "basis": "consolidated", "rule": "ls-ebest-2022-own-cfs-current-seven-v1", "statementLabel": "cfs", "ownCoverName": "이베스트투자증권(주)", "shellCurrentName": "LS증권", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230316001115", "sha256": "9b41f0d01d5c4add0e57f554ee265e1b9c52c5a8fa49ea58767e0953e289a45f"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=1&offset=803&length=4037&dtd=dart3.xsd", "sha256": "2c176b3505d2b7a8899593b37ffa95176a94365330ce57f622d45cd9ad951dc2"}, {"label": "cfs", "file": "cfs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=17&offset=317594&length=51185&dtd=dart3.xsd", "sha256": "8d44e40d162128bc586cb5eaaa9a3b265b9fefc9ec314d2fc32c1e1373ba4092"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=18&offset=368783&length=1182206&dtd=dart3.xsd", "sha256": "4fa8d600d687caa71f84eb26c55b40b3377113f332eb058662f16cb90d1f5f35"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=3&offset=5340&length=87037&dtd=dart3.xsd", "sha256": "a9691289a81baefe10572ef9efcc761c115b377dab9f8ce70d462b19904d2dc9", "file": "overview.html", "label": "overview"}], "rows": [{"index": 16, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "6,169,919,669,399"}, {"index": 25, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "5,250,382,412,000"}, {"index": 32, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "919,537,257,399"}, {"index": 41, "column": 3, "kind": "IS", "label": "I. 영업수익", "printed": "1,348,600,743,673"}, {"index": 60, "column": 3, "kind": "IS", "label": "III. 영업이익", "printed": "41,776,774,836"}, {"index": 73, "column": 3, "kind": "IS", "label": "VIII. 당기순이익 (대손준비금 반영후 조정이익: 당기 35,862,295천원 전기 153,367,335천원)", "printed": "29,709,033,982"}, {"index": 108, "column": 3, "kind": "CF", "label": "I. 영업활동으로 인한 현금흐름", "printed": "(44,210,626,065)"}], "rowCount": 146, "witnesses": {"1": ["제 24 기 2022년 12월 31일 현재"], "4": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "5": ["과 목", "주석", "제24기", "제23기"], "36": ["제 24 기 2022년 1월 1일부터 2022년 12월 31일까지"], "39": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "40": ["과 목", "주석", "제24기", "제23기"], "85": ["제 24 기 2022년 1월 1일부터 2022년 12월 31일까지"], "88": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "89": ["과 목", "자본금", "기타불입자본", "이익잉여금", "총계"], "103": ["제 24 기 2022년 1월 1일부터 2022년 12월 31일까지"], "106": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "107": ["과 목", "주석", "제24기", "제23기"], "100": ["2022.12.31", "363,969,375,000", "99,172,645,668", "(46,549,638,620)", "1,505,390", "3,096,424", "502,940,273,537", "919,537,257,399"], "96": ["2022.01.01", "363,969,375,000", "100,252,645,668", "(46,549,638,620)", "1,505,390", "3,096,424", "510,703,256,930", "928,380,240,792"]}, "equations": [{"label": "BS", "result": [16, 2], "terms": [[25, 2, 1], [32, 2, 1]]}, {"label": "OP", "result": [60, 3], "terms": [[41, 3, 1], [51, 3, -1]]}, {"label": "NI", "result": [73, 3], "terms": [[71, 3, 1], [72, 3, -1]]}, {"label": "CENI", "result": [73, 3], "terms": [[99, 7, 1]]}, {"label": "CFNI", "result": [73, 3], "terms": [[109, 2, 1]]}, {"label": "CEclose", "result": [100, 7], "terms": [[96, 7, 1], [97, 7, 1], [98, 7, 1], [99, 7, 1]]}, {"label": "CFO", "result": [108, 3], "terms": [[109, 2, 1], [110, 2, 1], [111, 2, 1], [112, 2, 1], [113, 2, 1], [114, 2, 1]]}, {"label": "CFI", "result": [115, 3], "terms": [[116, 2, 1], [122, 2, 1]]}, {"label": "CFF", "result": [129, 3], "terms": [[130, 2, 1], [135, 2, 1]]}, {"label": "cashnet", "result": [141, 3], "terms": [[108, 3, 1], [115, 3, 1], [129, 3, 1]]}, {"label": "cashclose", "result": [144, 3], "terms": [[142, 3, 1], [141, 3, 1], [143, 3, 1]]}, {"label": "CEwhole=BSwhole", "result": [100, 7], "terms": [[32, 2, 1]]}, {"label": "CEopening=BSprior", "result": [96, 7], "terms": [[32, 3, 1]]}], "noteRowCount": 3117, "noteWitnesses": {"0": ["제 24 기 2022년 12월 31일 현재"], "1": ["제 23 기 2021년 12월 31일 현재"], "2": [""], "3": ["이베스트투자증권주식회사와 그 종속기업"], "472": ["(단위:천원)"], "473": ["구분", "당기말", "전기말"], "474": ["현금및현금성자산", "49,595,413", "34,625,901"], "475": ["예치금", "423,101,247", "310,008,103"], "476": ["합계", "472,696,660", "344,634,004"], "477": ["(단위:천원)"], "478": ["구분", "당기말", "전기말"], "479": ["보통예금", "3,340,075", "4,151,813"], "480": ["외화예금", "7,384,704", "6,130,556"], "481": ["당좌예금", "670,634", "443,532"], "482": ["MMDA", "18,200,000", "3,900,000"], "483": ["발행어음", "20,000,000", "20,000,000"], "484": ["합계", "49,595,413", "34,625,901"], "485": ["(단위:천원)"], "486": ["구분", "당기말", "전기말"], "487": ["투자자예탁금별도예치금(예금)", "62,915,311", "70,454,637"], "488": ["대차거래이행보증금", "103,385,781", "445"], "489": ["장내파생상품거래예치금", "131,285,614", "94,635,783"], "490": ["장내파생상품매매증거금", "55,200,000", "64,000,000"], "491": ["주식매매증거금", "16,511,115", "30,803,953"], "492": ["스왑증거금", "1,000,000", "-"], "493": ["유통금융차주담보금", "595,241", "280,124"], "494": ["유통금융담보금", "28,700,000", "19,900,000"], "495": ["담보금융지원대출담보금", "3,000,000", "-"], "496": ["특정예금", "20,500", "2,914,720"], "497": ["기타예치금", "17,487,685", "24,018,441"], "498": ["정기예적금", "3,000,000", "3,000,000"], "499": ["합계", "423,101,247", "310,008,103"]}, "noteEquations": [{"label": "cash+deposit=BSnote", "result": [476, 1], "terms": [[474, 1, 1], [475, 1, 1]], "expectedResidual": "0"}, {"label": "cash-detail", "result": [474, 1], "terms": [[479, 1, 1], [480, 1, 1], [481, 1, 1], [482, 1, 1], [483, 1, 1]], "expectedResidual": "0"}, {"label": "deposit-detail", "result": [475, 1], "terms": [[487, 1, 1], [488, 1, 1], [489, 1, 1], [490, 1, 1], [491, 1, 1], [492, 1, 1], [493, 1, 1], [494, 1, 1], [495, 1, 1], [496, 1, 1], [497, 1, 1], [498, 1, 1]], "expectedResidual": "0"}], "notePrecisionEvidence": {"cfWonMinusNoteCashTimes1000": 147, "bsWonMinusNoteCombinedTimes1000": -12}, "noteScope": {"note": "5. 현금및예치금", "printedUnit": "천원", "statementUnit": "원", "combinedSubtotalResidual": "0", "cashDetailResidual": "0", "depositDetailResidual": "0", "crossPrecisionEqualityClaim": false, "roundingCauseClaim": false, "allNotesVerified": false}, "periodEvidence": {"ownCoverYear": 2022, "sameCurrentBSPLCECFHeaders": true, "wholeEntityNI": true, "priorNumericPeriodsCollected": false}}, {"receipt": "20230316001115", "corp": "00330424", "year": 2022, "name": "엘에스증권(주)", "basis": "separate", "rule": "ls-ebest-2022-own-ofs-current-seven-v1", "statementLabel": "ofs", "ownCoverName": "이베스트투자증권(주)", "shellCurrentName": "LS증권", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230316001115", "sha256": "9b41f0d01d5c4add0e57f554ee265e1b9c52c5a8fa49ea58767e0953e289a45f"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=1&offset=803&length=4037&dtd=dart3.xsd", "sha256": "2c176b3505d2b7a8899593b37ffa95176a94365330ce57f622d45cd9ad951dc2"}, {"label": "ofs", "file": "ofs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=19&offset=1550993&length=49562&dtd=dart3.xsd", "sha256": "9ddb6225c54b8354c06f53beff0d1a079ccff0552b7a7baeeb226555e4cf2ba3"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=20&offset=1600559&length=1297367&dtd=dart3.xsd", "sha256": "9f4ec1b943d03c1a950386a406db341344a65e4296e401c899805c77355d362a"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20230316001115&dcmNo=9065788&eleId=3&offset=5340&length=87037&dtd=dart3.xsd", "sha256": "a9691289a81baefe10572ef9efcc761c115b377dab9f8ce70d462b19904d2dc9", "file": "overview.html", "label": "overview"}], "rows": [{"index": 16, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "6,163,539,030,726"}, {"index": 25, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "5,243,911,359,473"}, {"index": 30, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "919,627,671,253"}, {"index": 39, "column": 3, "kind": "IS", "label": "I. 영업수익", "printed": "1,348,050,976,024"}, {"index": 58, "column": 3, "kind": "IS", "label": "III. 영업이익", "printed": "41,611,282,378"}, {"index": 71, "column": 3, "kind": "IS", "label": "VIII. 당기순이익 (대손준비금 반영후 조정이익: 당기 35,776,373천원 전기 153,214,707천원)", "printed": "29,623,112,906"}, {"index": 101, "column": 3, "kind": "CF", "label": "I. 영업활동으로 인한 현금흐름", "printed": "(44,361,755,686)"}], "rowCount": 139, "witnesses": {"1": ["제 24 기 2022년 12월 31일 현재"], "4": ["이베스트투자증권주식회사", "(단위 : 원)"], "5": ["과 목", "주석", "제24기", "제23기"], "34": ["제 24 기 2022년 1월 1일부터 2022년 12월 31일까지"], "37": ["이베스트투자증권주식회사", "(단위 : 원)"], "38": ["과 목", "주석", "제24기", "제23기"], "79": ["제 24 기 2022년 1월 1일부터 2022년 12월 31일까지"], "82": ["이베스트투자증권주식회사", "(단위 : 원)"], "83": ["과 목", "자본금", "기타불입자본", "이익잉여금", "총계"], "96": ["제 24 기 2022년 1월 1일부터 2022년 12월 31일까지"], "99": ["이베스트투자증권주식회사", "(단위 : 원)"], "100": ["과 목", "주석", "제24기", "제23기"], "94": ["2022.12.31", "363,969,375,000", "99,172,645,668", "(46,549,638,620)", "1,505,390", "3,096,424", "503,030,687,391", "919,627,671,253"], "90": ["2022.01.01", "363,969,375,000", "100,252,645,668", "(46,549,638,620)", "1,505,390", "3,096,424", "510,879,591,860", "928,556,575,722"]}, "equations": [{"label": "BS", "result": [16, 2], "terms": [[25, 2, 1], [30, 2, 1]]}, {"label": "OP", "result": [58, 3], "terms": [[39, 3, 1], [49, 3, -1]]}, {"label": "NI", "result": [71, 3], "terms": [[69, 3, 1], [70, 3, -1]]}, {"label": "CENI", "result": [71, 3], "terms": [[93, 7, 1]]}, {"label": "CFNI", "result": [71, 3], "terms": [[102, 2, 1]]}, {"label": "CEclose", "result": [94, 7], "terms": [[90, 7, 1], [91, 7, 1], [92, 7, 1], [93, 7, 1]]}, {"label": "CFO", "result": [101, 3], "terms": [[102, 2, 1], [103, 2, 1], [104, 2, 1], [105, 2, 1], [106, 2, 1], [107, 2, 1]]}, {"label": "CFI", "result": [108, 3], "terms": [[109, 2, 1], [115, 2, 1]]}, {"label": "CFF", "result": [122, 3], "terms": [[123, 2, 1], [128, 2, 1]]}, {"label": "cashnet", "result": [134, 3], "terms": [[101, 3, 1], [108, 3, 1], [122, 3, 1]]}, {"label": "cashclose", "result": [137, 3], "terms": [[135, 3, 1], [134, 3, 1], [136, 3, 1]]}, {"label": "CEwhole=BSwhole", "result": [94, 7], "terms": [[30, 2, 1]]}, {"label": "CEopening=BSprior", "result": [90, 7], "terms": [[30, 3, 1]]}], "noteRowCount": 3492, "noteWitnesses": {"0": ["제 24 기 2022년 12월 31일 현재"], "1": ["제 23 기 2021년 12월 31일 현재"], "2": [""], "3": ["이베스트투자증권주식회사"], "102": ["(단위:천원)"], "103": ["구분", "당기말", "전기말"], "104": ["현금및현금성자산", "46,779,620", "31,130,955"], "105": ["예치금", "423,101,247", "307,113,883"], "106": ["합계", "469,880,867", "338,244,838"], "107": ["(단위:천원)"], "108": ["구분", "당기말", "전기말"], "109": ["보통예금", "524,282", "656,867"], "110": ["외화예금", "7,384,704", "6,130,556"], "111": ["당좌예금", "670,634", "443,532"], "112": ["MMDA", "18,200,000", "3,900,000"], "113": ["발행어음", "20,000,000", "20,000,000"], "114": ["합계", "46,779,620", "31,130,955"], "115": ["(단위:천원)"], "116": ["구분", "당기말", "전기말"], "117": ["투자자예탁금별도예치금(예금)", "62,915,311", "70,454,637"], "118": ["대차거래이행보증금", "103,385,781", "445"], "119": ["장내파생상품거래예치금", "131,285,614", "94,635,783"], "120": ["장내파생상품매매증거금", "55,200,000", "64,000,000"], "121": ["주식매매증거금", "16,511,115", "30,803,953"], "122": ["스왑증거금", "1,000,000", "-"], "123": ["유통금융차주담보금", "595,241", "280,124"], "124": ["유통금융담보금", "28,700,000", "19,900,000"], "125": ["담보금융지원대출담보금", "3,000,000", "-"], "126": ["특정예금", "20,500", "20,500"], "127": ["기타예치금", "17,487,685", "24,018,441"], "128": ["정기예적금", "3,000,000", "3,000,000"], "129": ["합계", "423,101,247", "307,113,883"]}, "noteEquations": [{"label": "cash+deposit=BSnote", "result": [106, 1], "terms": [[104, 1, 1], [105, 1, 1]], "expectedResidual": "0"}, {"label": "cash-detail", "result": [104, 1], "terms": [[109, 1, 1], [110, 1, 1], [111, 1, 1], [112, 1, 1], [113, 1, 1]], "expectedResidual": "0"}, {"label": "deposit-detail", "result": [105, 1], "terms": [[117, 1, 1], [118, 1, 1], [119, 1, 1], [120, 1, 1], [121, 1, 1], [122, 1, 1], [123, 1, 1], [124, 1, 1], [125, 1, 1], [126, 1, 1], [127, 1, 1], [128, 1, 1]], "expectedResidual": "0"}], "notePrecisionEvidence": {"cfWonMinusNoteCashTimes1000": -32, "bsWonMinusNoteCombinedTimes1000": -191}, "noteScope": {"note": "5. 현금및예치금", "printedUnit": "천원", "statementUnit": "원", "combinedSubtotalResidual": "0", "cashDetailResidual": "0", "depositDetailResidual": "0", "crossPrecisionEqualityClaim": false, "roundingCauseClaim": false, "allNotesVerified": false}, "periodEvidence": {"ownCoverYear": 2022, "sameCurrentBSPLCECFHeaders": true, "wholeEntityNI": true, "priorNumericPeriodsCollected": false}}, {"receipt": "20220317000673", "corp": "00330424", "year": 2021, "name": "엘에스증권(주)", "basis": "consolidated", "rule": "ls-ebest-2021-own-cfs-current-seven-v1", "statementLabel": "cfs", "ownCoverName": "이베스트투자증권(주)", "shellCurrentName": "LS증권", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220317000673", "sha256": "898190d37b6426e9ed396d378122e132497e01fc00dd04d42911854f8a7bc86f"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=1&offset=811&length=4042&dtd=dart3.xsd", "sha256": "e5e5a18339cdcecbccf6fcd0c51d7fd2611f6753835a5b68bc5526acd3bb521f"}, {"label": "cfs", "file": "cfs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=17&offset=310337&length=50806&dtd=dart3.xsd", "sha256": "d25c41ed9b04442c369574587e0ada0284289a519999d2906af66a68ae42aa8d"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=18&offset=361147&length=1067963&dtd=dart3.xsd", "sha256": "435949050d81ff2a6678b428b6c021efe42417d6122ef308067e8dd91f7b9824"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=3&offset=5377&length=85664&dtd=dart3.xsd", "sha256": "e9790ef02468da3dd78b2aabfc438a9608cb500ea58ea513bc6cb409f564437d", "file": "overview.html", "label": "overview"}], "rows": [{"index": 16, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "6,931,932,578,875"}, {"index": 25, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "6,003,552,338,083"}, {"index": 32, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "928,380,240,792"}, {"index": 41, "column": 3, "kind": "IS", "label": "I. 영업수익", "printed": "1,544,545,436,005"}, {"index": 59, "column": 3, "kind": "IS", "label": "III. 영업이익", "printed": "225,778,127,755"}, {"index": 72, "column": 3, "kind": "IS", "label": "VIII. 당기순이익 (대손준비금 반영후 조정이익: 당기 153,367,335천원 전기 121,709,052천원)", "printed": "160,829,586,520"}, {"index": 107, "column": 3, "kind": "CF", "label": "I. 영업활동으로 인한 현금흐름", "printed": "(171,229,176,384)"}], "rowCount": 140, "witnesses": {"1": ["제 23 기 2021년 12월 31일 현재"], "4": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "5": ["과 목", "주석", "제23기", "제22기"], "36": ["제 23 기 2021년 1월 1일부터 2021년 12월 31일까지"], "39": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "40": ["과 목", "주석", "제23기", "제22기"], "84": ["제 23 기 2021년 1월 1일부터 2021년 12월 31일까지"], "87": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "88": ["과 목", "자본금", "기타불입자본", "이익잉여금", "총계"], "102": ["제 23 기 2021년 1월 1일부터 2021년 12월 31일까지"], "105": ["이베스트투자증권주식회사와 그 종속기업", "(단위 : 원)"], "106": ["과 목", "주석", "제23기", "제22기"], "99": ["2021.12.31", "363,969,375,000", "100,252,645,668", "(46,549,638,620)", "1,505,390", "3,096,424", "510,703,256,930", "928,380,240,792"], "95": ["2021.01.01", "335,114,900,000", "70,091,441,833", "(46,549,638,620)", "1,505,390", "3,096,424", "382,017,128,534", "740,678,433,561"]}, "equations": [{"label": "BS", "result": [16, 2], "terms": [[25, 2, 1], [32, 2, 1]]}, {"label": "OP", "result": [59, 3], "terms": [[41, 3, 1], [51, 3, -1]]}, {"label": "NI", "result": [72, 3], "terms": [[70, 3, 1], [71, 3, -1]]}, {"label": "CENI", "result": [72, 3], "terms": [[98, 7, 1]]}, {"label": "CFNI", "result": [72, 3], "terms": [[108, 2, 1]]}, {"label": "CEclose", "result": [99, 7], "terms": [[95, 7, 1], [96, 7, 1], [97, 7, 1], [98, 7, 1]]}, {"label": "CFO", "result": [107, 3], "terms": [[108, 2, 1], [109, 2, 1], [110, 2, 1], [111, 2, 1], [112, 2, 1], [113, 2, 1]]}, {"label": "CFI", "result": [114, 3], "terms": [[115, 2, 1], [121, 2, 1]]}, {"label": "CFF", "result": [127, 3], "terms": [[128, 2, 1], [131, 2, 1]]}, {"label": "cashnet", "result": [135, 3], "terms": [[107, 3, 1], [114, 3, 1], [127, 3, 1]]}, {"label": "cashclose", "result": [138, 3], "terms": [[136, 3, 1], [135, 3, 1], [137, 3, 1]]}, {"label": "CEwhole=BSwhole", "result": [99, 7], "terms": [[32, 2, 1]]}, {"label": "CEopening=BSprior", "result": [95, 7], "terms": [[32, 3, 1]]}], "noteRowCount": 2794, "noteWitnesses": {"0": ["제 23 기 2021년 12월 31일 현재"], "1": ["제 22 기 2020년 12월 31일 현재"], "2": [""], "3": ["이베스트투자증권주식회사와 그 종속기업"], "370": ["(단위:천원)"], "371": ["구분", "당기말", "전기말"], "372": ["현금및현금성자산", "34,625,901", "79,518,526"], "373": ["예치금", "310,008,103", "542,009,931"], "374": ["합계", "344,634,004", "621,528,457"], "375": ["(단위:천원)"], "376": ["구분", "당기말", "전기말"], "377": ["보통예금", "4,151,813", "3,346,555"], "378": ["외화예금", "6,130,556", "10,464,014"], "379": ["당좌예금", "443,532", "407,957"], "380": ["MMDA", "3,900,000", "15,300,000"], "381": ["발행어음", "20,000,000", "30,000,000"], "382": ["기타예금", "-", "20,000,000"], "383": ["합계", "34,625,901", "79,518,526"], "384": ["(단위:천원)"], "385": ["구분", "당기말", "전기말"], "386": ["투자자예탁금별도예치금(예금)", "70,454,637", "136,002,350"], "387": ["대차거래이행보증금", "445", "192,620,997"], "388": ["장내파생상품거래예치금", "94,635,783", "63,100,014"], "389": ["장내파생상품매매증거금", "64,000,000", "75,000,000"], "390": ["주식매매증거금", "30,803,953", "14,087,728"], "391": ["스왑증거금", "-", "2,300,000"], "392": ["유통금융차주담보금", "280,124", "-"], "393": ["유통금융담보금", "19,900,000", "29,700,000"], "394": ["특정예금", "2,914,720", "20,500"], "395": ["기타예치금", "24,018,441", "26,178,342"], "396": ["정기예적금", "3,000,000", "3,000,000"], "397": ["합계", "310,008,103", "542,009,931"]}, "noteEquations": [{"label": "cash+deposit=BSnote", "result": [374, 1], "terms": [[372, 1, 1], [373, 1, 1]], "expectedResidual": "0"}, {"label": "cash-detail", "result": [372, 1], "terms": [[377, 1, 1], [378, 1, 1], [379, 1, 1], [380, 1, 1], [381, 1, 1], [382, 1, 1]], "expectedResidual": "0"}, {"label": "deposit-detail", "result": [373, 1], "terms": [[386, 1, 1], [387, 1, 1], [388, 1, 1], [389, 1, 1], [390, 1, 1], [391, 1, 1], [392, 1, 1], [393, 1, 1], [394, 1, 1], [395, 1, 1], [396, 1, 1]], "expectedResidual": "0"}], "notePrecisionEvidence": {"cfWonMinusNoteCashTimes1000": -161, "bsWonMinusNoteCombinedTimes1000": -484}, "noteScope": {"note": "5. 현금및예치금", "printedUnit": "천원", "statementUnit": "원", "combinedSubtotalResidual": "0", "cashDetailResidual": "0", "depositDetailResidual": "0", "crossPrecisionEqualityClaim": false, "roundingCauseClaim": false, "allNotesVerified": false}, "periodEvidence": {"ownCoverYear": 2021, "sameCurrentBSPLCECFHeaders": true, "wholeEntityNI": true, "priorNumericPeriodsCollected": false}}, {"receipt": "20220317000673", "corp": "00330424", "year": 2021, "name": "엘에스증권(주)", "basis": "separate", "rule": "ls-ebest-2021-own-ofs-current-seven-v1", "statementLabel": "ofs", "ownCoverName": "이베스트투자증권(주)", "shellCurrentName": "LS증권", "sources": [{"label": "shell", "file": "shell.html", "url": "https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220317000673", "sha256": "898190d37b6426e9ed396d378122e132497e01fc00dd04d42911854f8a7bc86f"}, {"label": "cover", "file": "cover.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=1&offset=811&length=4042&dtd=dart3.xsd", "sha256": "e5e5a18339cdcecbccf6fcd0c51d7fd2611f6753835a5b68bc5526acd3bb521f"}, {"label": "ofs", "file": "ofs.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=19&offset=1429114&length=55332&dtd=dart3.xsd", "sha256": "d84d32f7cc81af284c23b00448bcdbd944f1d4479469250c3338784d9e2b5107"}, {"label": "notes", "file": "notes.html", "url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=20&offset=1484450&length=1164331&dtd=dart3.xsd", "sha256": "b77eae291dad4095e6a8d0cf252dc152db86355e2c8ac98589cd6312d44a04db"}, {"url": "https://dart.fss.or.kr/report/viewer.do?rcpNo=20220317000673&dcmNo=8470739&eleId=3&offset=5377&length=85664&dtd=dart3.xsd", "sha256": "e9790ef02468da3dd78b2aabfc438a9608cb500ea58ea513bc6cb409f564437d", "file": "overview.html", "label": "overview"}], "rows": [{"index": 16, "column": 2, "kind": "BS", "label": "자 산 총 계", "printed": "6,921,167,983,689"}, {"index": 25, "column": 2, "kind": "BS", "label": "부 채 총 계", "printed": "5,992,611,407,967"}, {"index": 30, "column": 2, "kind": "BS", "label": "자 본 총 계", "printed": "928,556,575,722"}, {"index": 39, "column": 3, "kind": "IS", "label": "I. 영업수익", "printed": "1,540,762,440,279"}, {"index": 57, "column": 3, "kind": "IS", "label": "III. 영업이익", "printed": "225,446,321,920"}, {"index": 70, "column": 3, "kind": "IS", "label": "VIII. 당기순이익 (대손준비금 반영후 조정이익: 당기 153,214,707천원 전기 121,089,623천원)", "printed": "160,676,957,829"}, {"index": 101, "column": 3, "kind": "CF", "label": "I. 영업활동으로 인한 현금흐름", "printed": "(170,171,725,867)"}], "rowCount": 149, "witnesses": {"1": ["제 23 기 2021년 12월 31일 현재"], "4": ["이베스트투자증권주식회사", "(단위 : 원)"], "5": ["과 목", "주석", "제23기", "제22기"], "34": ["제 23 기 2021년 1월 1일부터 2021년 12월 31일까지"], "37": ["이베스트투자증권주식회사", "(단위 : 원)"], "38": ["과 목", "주석", "제23기", "제22기"], "78": ["제 23 기 2021년 1월 1일부터 2021년 12월 31일까지"], "81": ["이베스트투자증권주식회사", "(단위 : 원)"], "82": ["과 목", "자본금", "기타불입자본", "이익잉여금", "총계"], "96": ["제 23 기 2021년 1월 1일부터 2021년 12월 31일까지"], "99": ["이베스트투자증권주식회사", "(단위 : 원)"], "100": ["과 목", "주석", "제23기", "제22기"], "93": ["2021.12.31", "363,969,375,000", "100,252,645,668", "(46,549,638,620)", "1,505,390", "3,096,424", "510,879,591,860", "928,556,575,722"], "89": ["2021.01.01", "335,114,900,000", "70,091,441,833", "(46,549,638,620)", "1,505,390", "3,096,424", "382,346,092,155", "741,007,397,182"]}, "equations": [{"label": "BS", "result": [16, 2], "terms": [[25, 2, 1], [30, 2, 1]]}, {"label": "OP", "result": [57, 3], "terms": [[39, 3, 1], [49, 3, -1]]}, {"label": "NI", "result": [70, 3], "terms": [[68, 3, 1], [69, 3, -1]]}, {"label": "CENI", "result": [70, 3], "terms": [[92, 7, 1]]}, {"label": "CFNI", "result": [70, 3], "terms": [[102, 2, 1]]}, {"label": "CEclose", "result": [93, 7], "terms": [[89, 7, 1], [90, 7, 1], [91, 7, 1], [92, 7, 1]]}, {"label": "CFO", "result": [101, 3], "terms": [[102, 2, 1], [103, 2, 1], [104, 2, 1], [105, 2, 1], [106, 2, 1], [107, 2, 1]]}, {"label": "CFI", "result": [108, 3], "terms": [[109, 2, 1], [115, 2, 1]]}, {"label": "CFF", "result": [121, 3], "terms": [[122, 2, 1], [125, 2, 1]]}, {"label": "cashnet", "result": [129, 3], "terms": [[101, 3, 1], [108, 3, 1], [121, 3, 1]]}, {"label": "cashclose", "result": [132, 3], "terms": [[130, 3, 1], [129, 3, 1], [131, 3, 1]]}, {"label": "CEwhole=BSwhole", "result": [93, 7], "terms": [[30, 2, 1]]}, {"label": "CEopening=BSprior", "result": [89, 7], "terms": [[30, 3, 1]]}], "noteRowCount": 3117, "noteWitnesses": {"0": ["제 23 기 2021년 12월 31일 현재"], "1": ["제 22 기 2020년 12월 31일 현재"], "2": [""], "3": ["이베스트투자증권주식회사"], "98": ["(단위:천원)"], "99": ["구분", "당기말", "전기말"], "100": ["현금및현금성자산", "31,130,955", "77,169,593"], "101": ["예치금", "307,113,883", "542,009,931"], "102": ["합계", "338,244,838", "619,179,524"], "103": ["(단위:천원)"], "104": ["구분", "당기말", "전기말"], "105": ["보통예금", "656,867", "997,622"], "106": ["외화예금", "6,130,556", "10,464,014"], "107": ["당좌예금", "443,532", "407,957"], "108": ["MMDA", "3,900,000", "15,300,000"], "109": ["발행어음", "20,000,000", "30,000,000"], "110": ["기타예금", "-", "20,000,000"], "111": ["합계", "31,130,955", "77,169,593"], "112": ["(단위:천원)"], "113": ["구분", "당기말", "전기말"], "114": ["투자자예탁금별도예치금(예금)", "70,454,637", "136,002,350"], "115": ["대차거래이행보증금", "445", "192,620,997"], "116": ["장내파생상품거래예치금", "94,635,783", "63,100,014"], "117": ["장내파생상품매매증거금", "64,000,000", "75,000,000"], "118": ["주식매매증거금", "30,803,953", "14,087,728"], "119": ["스왑증거금", "-", "2,300,000"], "120": ["유통금융차주담보금", "280,124", "-"], "121": ["유통금융담보금", "19,900,000", "29,700,000"], "122": ["특정예금", "20,500", "20,500"], "123": ["기타예치금", "24,018,441", "26,178,342"], "124": ["정기예적금", "3,000,000", "3,000,000"], "125": ["합계", "307,113,883", "542,009,931"]}, "noteEquations": [{"label": "cash+deposit=BSnote", "result": [102, 1], "terms": [[100, 1, 1], [101, 1, 1]], "expectedResidual": "0"}, {"label": "cash-detail", "result": [100, 1], "terms": [[105, 1, 1], [106, 1, 1], [107, 1, 1], [108, 1, 1], [109, 1, 1], [110, 1, 1]], "expectedResidual": "0"}, {"label": "deposit-detail", "result": [101, 1], "terms": [[114, 1, 1], [115, 1, 1], [116, 1, 1], [117, 1, 1], [118, 1, 1], [119, 1, 1], [120, 1, 1], [121, 1, 1], [122, 1, 1], [123, 1, 1], [124, 1, 1]], "expectedResidual": "0"}], "notePrecisionEvidence": {"cfWonMinusNoteCashTimes1000": -115, "bsWonMinusNoteCombinedTimes1000": 257}, "noteScope": {"note": "5. 현금및예치금", "printedUnit": "천원", "statementUnit": "원", "combinedSubtotalResidual": "0", "cashDetailResidual": "0", "depositDetailResidual": "0", "crossPrecisionEqualityClaim": false, "roundingCauseClaim": false, "allNotesVerified": false}, "periodEvidence": {"ownCoverYear": 2021, "sameCurrentBSPLCECFHeaders": true, "wholeEntityNI": true, "priorNumericPeriodsCollected": false}}]''',
  );
  static List get profiles => jsonDecode(jsonEncode(_profiles)) as List;
  static bool supports(String rule) => _profiles.any((p) => p['rule'] == rule);

  /// Only exact validated current rows attach scope evidence to the existing
  /// report Source title. Unknown rows cannot obtain a finite scope notice.
  static Map<String, dynamic>? storedScope({
    required List<Map<String, dynamic>> rows,
    required String receipt,
    required String corp,
    required String companyName,
    required bool consolidated,
    required Uri? source,
    required String? digest,
  }) {
    final matches = _profiles
        .where(
          (p) =>
              p['receipt'] == receipt &&
              p['corp'] == corp &&
              p['name'] == companyName &&
              (p['basis'] == 'consolidated') == consolidated,
        )
        .toList();
    if (matches.length != 1) return null;
    final p = matches.single as Map;
    final main = (p['sources'] as List).singleWhere(
      (s) => s['label'] == p['statementLabel'],
    );
    if (source?.toString() != main['url'] ||
        digest != main['sha256'] ||
        rows.length != (p['rows'] as List).length) {
      return null;
    }
    for (var i = 0; i < rows.length; i++) {
      final expected = p['rows'][i] as Map, row = rows[i];
      final provenance = row['html_provenance'];
      final amount = (expected['printed'] as String)
          .replaceAll(',', '')
          .replaceAll('(', '-')
          .replaceAll(')', '');
      if (row['account_nm'] != expected['label'] ||
          row['thstrm_amount'] != amount ||
          row['rcept_no'] != receipt ||
          row['corp_code'] != corp ||
          row['bsns_year'] != '${p['year']}' ||
          row['reprt_code'] != '11011' ||
          row['sj_div'] != expected['kind'] ||
          provenance is! Map ||
          provenance['basis'] != (consolidated ? 'CFS' : 'OFS') ||
          provenance['periodStart'] != '${p['year']}-01-01' ||
          provenance['periodEnd'] != '${p['year']}-12-31' ||
          provenance['ruleVersion'] != p['rule'] ||
          provenance['sourceSha256'] != digest ||
          provenance['unit'] != '원' ||
          provenance['unitMultiplier'] != '1' ||
          provenance['fullStatementVerified'] != false ||
          provenance['notesVerified'] != false ||
          provenance['numericCellCorrection'] != false ||
          provenance['genericRoundingTolerance'] != false) {
        return null;
      }
    }
    return {
      'action': 'verified-keyless-annual-source-after-api-noData',
      'targetReceipt': receipt,
      'sourceReceipt': receipt,
      'corpCode': corp,
      'fsDiv': consolidated ? 'consolidated' : 'separate',
      'coreRows': rows.length,
      'coreRowProvenance': rows,
    };
  }

  static List<Map<String, dynamic>> parse({
    required Map<String, String> raw,
    required Map<String, Uri> uris,
    required String receipt,
    required String corp,
    required String companyName,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    final candidates = _profiles
        .where(
          (p) =>
              p['receipt'] == receipt &&
              (p['basis'] == 'consolidated') == consolidated,
        )
        .toList();
    if (candidates.length != 1) {
      throw const FormatException('LS/Kiwoom exact receipt/basis mismatch');
    }
    final p = candidates.single as Map;
    final year = p['year'] as int;
    if (corp != p['corp'] ||
        companyName != p['name'] ||
        start != DateTime.utc(year) ||
        end != DateTime.utc(year, 12, 31)) {
      throw const FormatException(
        'LS/Kiwoom exact own annual identity mismatch',
      );
    }
    final labels = (p['sources'] as List).map((s) => s['label']).toSet();
    if (raw.length != labels.length ||
        uris.length != labels.length ||
        !raw.keys.toSet().containsAll(labels) ||
        !uris.keys.toSet().containsAll(labels)) {
      throw const FormatException('LS/Kiwoom unexpected source member');
    }
    for (final s in p['sources'] as List) {
      final label = s['label'] as String;
      if (uris[label]?.toString() != s['url'] ||
          sha256.convert(utf8.encode(raw[label]!)).toString() != s['sha256']) {
        throw const FormatException(
          'LS/Kiwoom exact original URI/SHA mismatch',
        );
      }
    }
    String text(String h) => h
        .replaceAll(RegExp('<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cover = text(raw['cover']!);
    if (!cover.contains(p['ownCoverName'] as String) ||
        !cover.contains('$year년 01월 01일') ||
        !cover.contains('$year년 12월 31일')) {
      throw const FormatException(
        'LS/Kiwoom own printed cover actor/period mismatch',
      );
    }
    final actors = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((m) => m[1])
        .toSet();
    if (actors.length != 1 ||
        actors.single != corp ||
        !raw['shell']!.contains('${p['shellCurrentName']}</span>')) {
      throw const FormatException(
        'LS/Kiwoom exact shell current issuer mismatch',
      );
    }
    // Historical Ebest is restricted to these four own annual bodies and
    // the same-corp receipt shell. No global company-name alias is installed.
    if (corp == '00330424' &&
        !text(raw['overview']!).contains('이트레이드증권(주) → 이베스트투자증권(주)')) {
      throw const FormatException('LS exact own historical overview mismatch');
    }
    List<List<String>> rows(String h) => [
      for (final tr in RegExp(
        r'<tr\b[^>]*>(.*?)</tr>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(h))
        [
          for (final c in RegExp(
            r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
            caseSensitive: false,
            dotAll: true,
          ).allMatches(tr[1]!))
            text(c[1]!),
        ],
    ];
    final statementLabel = p['statementLabel'] as String;
    final statement = rows(raw[statementLabel]!);
    final notes = rows(raw['notes']!);
    void witnesses(List<List<String>> r, Map expected, int count) {
      if (r.length != count) {
        throw const FormatException('LS/Kiwoom exact row structure changed');
      }
      for (final w in expected.entries) {
        if (r[int.parse(w.key as String)]
                .join('|')
                .replaceAll(RegExp(r'\s+'), '') !=
            (w.value as List).join('|').replaceAll(RegExp(r'\s+'), '')) {
          throw const FormatException(
            'LS/Kiwoom printed unit/actor/period witness mismatch',
          );
        }
      }
    }

    witnesses(statement, p['witnesses'] as Map, p['rowCount'] as int);
    witnesses(notes, p['noteWitnesses'] as Map, p['noteRowCount'] as int);
    BigInt money(String v) => v == '-'
        ? BigInt.zero
        : BigInt.parse(
            v.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    BigInt value(List<List<String>> r, List xy) =>
        money(r[xy[0] as int][xy[1] as int]);
    BigInt residual(List<List<String>> r, Map e) =>
        value(r, e['result'] as List) -
        (e['terms'] as List).fold(
          BigInt.zero,
          (sum, term) => sum + value(r, term) * BigInt.from(term[2] as int),
        );
    for (final e in p['equations'] as List) {
      if (residual(statement, e as Map) != BigInt.zero) {
        throw const FormatException(
          'LS/Kiwoom current whole BS/PL/CE/CF conflict',
        );
      }
    }
    // Notes have their own printed 천원 unit. The exact pinned cash-detail
    // residual -1 in Kiwoom is a diagnostic, never a tolerated zero residual.
    for (final e in p['noteEquations'] as List) {
      if (residual(notes, e as Map) !=
          BigInt.parse(e['expectedResidual'] as String)) {
        throw const FormatException(
          'LS/Kiwoom own printed cash-note evidence changed',
        );
      }
    }
    final eight = (p['rows'] as List).length == 8;
    final noteSource =
        (p['sources'] as List).singleWhere((s) => s['label'] == 'notes') as Map;
    final mainSource = (p['sources'] as List).singleWhere(
      (s) => s['label'] == statementLabel,
    ) as Map;
    return [
      for (final s in p['rows'] as List)
        {
          'rcept_no': receipt,
          'corp_code': corp,
          'bsns_year': '$year',
          'reprt_code': '11011',
          'account_id': null,
          'account_nm': s['label'],
          'account_detail': '-',
          'sj_div': s['kind'],
          'thstrm_nm': s['kind'] == 'BS'
              ? '$year-12-31'
              : '$year-01-01~$year-12-31',
          'thstrm_amount': money(
            statement[s['index'] as int][s['column'] as int],
          ).toString(),
          'currency': 'KRW',
          'html_provenance': {
            'source': uris[statementLabel].toString(),
            'sourceReceipt': receipt,
            'sourceSha256': mainSource['sha256'],
            'ruleVersion': p['rule'],
            'printedLabel': statement[s['index'] as int][0],
            'printedAmount': statement[s['index'] as int][s['column'] as int],
            'currentColumn': s['column'],
            'htmlTrIndex': s['index'],
            'unit': '원',
            'unitMultiplier': '1',
            'basis': consolidated ? 'CFS' : 'OFS',
            'periodStart': '$year-01-01',
            'periodEnd': '$year-12-31',
            'partialCore7': !eight,
            'currentCore8': eight,
            'wholeNetIncomeExact': true,
            'coreAmountsConflicting': false,
            'fullStatementCollected': false,
            'fullStatementVerified': false,
            'allStatementRowsVerified': false,
            'notesVerified': false,
            'numericCellCorrection': false,
            'genericRoundingTolerance': false,
            'uncollectedOptionalAccounts': eight ? <String>[] : ['capex'],
            'optionalAccountsNotCollected': eight ? <String>[] : ['capex'],
            'missingAccountReasons': eight
                ? <String, String>{}
                : {
                    'capex': 'Only equipment/vehicle acquisition subclasses printed; no whole PPE acquisition total. No sum or zero substitution.',
                  },
            'ownAnnualActor': p['ownCoverName'],
            'exactReceiptHistoricalIdentityOnly': true,
            'currentPeriodWitnesses': p['witnesses'],
            'priorNumericPeriodsCollected': false,
            'sameUnitCurrentMainEquationsExact': true,
            'cashScopeEvidence': {
              'source': noteSource['url'],
              'sha256': noteSource['sha256'],
              'receipt': receipt,
              'corpCode': corp,
              'basis': consolidated ? 'CFS' : 'OFS',
              'periodEnd': '$year-12-31',
              ...p['noteScope'] as Map,
              'rawPrintedPrecisionDifferences': p['notePrecisionEvidence'],
              'printedSameUnitNoteChecks': p['noteEquations'],
              'cashDetailAnomalyPreserved': eight,
            },
            'sourceScopeNotice': eight
                ? '당기 핵심 8개 계정만 검증했습니다. 주석은 천원, 재무제표는 원 단위이며 서로 정확히 같다고 주장하지 않습니다. 현금 주석의 세부 합계 차이 -1천원을 보존했습니다. 전체 세부 계정과 주석은 검증을 마치지 않았습니다.'
                : '당기 핵심 7개 계정만 검증했습니다. 전체 유형자산 취득액은 인쇄되지 않아 미확보이며 일부 취득액으로 대신하지 않습니다. FCF를 계산하지 않습니다. 현금 주석과 재무제표의 인쇄 단위 차이를 보존했고 전체 세부 계정과 주석은 검증을 마치지 않았습니다.',
          },
        },
    ];
  }
}
