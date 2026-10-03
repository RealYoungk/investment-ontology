import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One own-receipt current CFS source; CE currency remains unverified; no general heading grammar is changed.
abstract final class SuntechCfCurrentEightSource {
  static const rule = 'suntech-2024-own-cfs-source-aware-eight-v1';
  static final profiles = jsonDecode(
    r'''{"20250317000968":{"receipt":"20250317000968","year":2024,"sources":[{"label":"shell","file":"shell.html","url":"https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250317000968","sha256":"c8a826539faf81a8c7c7f8d3067638cb6aa1d7ca128efffced85e4fdfe7543f0"},{"label":"cover","file":"cover.html","url":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250317000968&dcmNo=10416653&eleId=3&offset=6204&length=4722&dtd=dart4.xsd","sha256":"c6b71098e75b306dbab1792393e253aad54e1aec41a137ae983fc28a1494ef4a"},{"label":"cfs","file":"cfs.html","url":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250317000968&dcmNo=10416653&eleId=21&offset=313848&length=112976&dtd=dart4.xsd","sha256":"6bd9bfe052c4008bde313b8696ef8627f433f785694875583206202c82e199a1"}],"sourceDigest":"1ba5d38ebc216716dfd94b3ecd34a9e2ce4e31010d5c11682ecf79ba24a2a57e","tables":[[["제29기2024년01월01일부터2024년12월31일까지"],["제28기2023년01월01일부터2023년12월31일까지"]],[["과목","제29(당)기(연결)","제28(전)기(연결)"],["자산","-","-","-","-"],["I.유동자산","-","7,458,615,568","-","7,943,922,674"],["(1)당좌자산","-","5,081,442,962","-","5,319,593,169"],["1.현금및현금성자산(주석3)","1,939,846,488","-","1,928,912,681","-"],["정기적금","121,731,372","-","425,128,834","-"],["외상매출금","2,570,390,599","-","2,395,290,580","-"],["대손충당금","(90,382,405)","-","(90,382,405)","-"],["미수금","223,193,514","-","109,782,855","-"],["선급금","103,890,200","-","159,480,440","-"],["선급비용","479,308,729","-","600,463,613","-"],["대손충당금","(269,499,068)","-","(209,090,909)","-"],["당기법인세자산","2,963,533","-","7,480","-"],["(2)재고자산","-","2,377,172,606","-","2,624,329,505"],["1.제품","644,262,362","-","928,822,057","-"],["2.원재료","740,026,488","-","855,023,100","-"],["3.재공품","992,883,756","-","840,484,348","-"],["II.비유동자산","-","9,682,994,494","-","10,072,927,272"],["(1)투자자산","-","243,425,059","-","193,066,088"],["종속기업투자자산","-","-","-","-"],["출자금","93,152,230","-","37,500,000","-"],["장기금융상품","150,272,829","-","155,566,088","-"],["(2)유형자산(주석5,7)","-","7,933,203,009","-","8,160,533,713"],["토지","4,023,016,650","-","4,023,016,650","-"],["국고보조금토지","(400,000,000)","-","(400,000,000)","-"],["건물","4,054,559,079","-","4,054,559,079","-"],["감가상각누계액","(1,156,655,230)","-","(1,062,987,263)","-"],["국고보조금건물","(197,828,752)","-","(203,481,001)","-"],["구축물","1,540,848,020","-","1,540,848,020","-"],["감가상각누계액","((603,084,516)","-","(570,071,565)","-"],["기계장치","1,669,908,911","-","1,655,710,253","-"],["감가상각누계액","(1,253,092,889)","-","(1,180,786,492)","-"],["국고보조금기계장치","(36,026,899)","-","(41,326,899)","-"],["차량운반구","585,687,608","-","585,687,608","-"],["감가상각누계액","(394,444,448)","-","(292,722,121)","-"],["국보보조금차량운반구","(39,454,969)","-","(49,304,969)","-"],["공구와기구","29,536,349","-","15,296,834","-"],["감가상각누계액","(14,211,186)","-","(12,844,360)","-"],["비품","332,489,724","-","270,116,276","-"],["감가상각누계액","(208,083,443)","-","(171,215,337)","-"],["시설장치","136,376,183","-","136,376,183","-"],["감가상각누계액","(136,337,183)","-","(136,337,183)","-"],["무형자산","-","681,061,881","-","926,022,926"],["특허권","22,573,888","-","26,426,111","-"],["개발비","991,575,833","-","1,372,901,248","-"],["국고보조금","(350,359,840)","-","(495,758,033)","-"],["소프트웨어","86,357,333","-","112,264,533","-"],["국고보조금","(69,085,333)","-","(89,810,933)","-"],["기타비유동자산","-","825,304,545","-","793,304,545"],["임차보증금","51,250,000","-","19,250,000","-"],["회원권","754,054,545","-","754,054,545","-"],["기타보증금","20,000,000","-","20,000,000","-"],["자산총계","-","17,141,610,062","-","18,016,849,946"],["부채","-","-","-","-"],["유동부채","-","12,483,226,946","-","12,905,175,348"],["외상매입금","2,112,568,104","-","1,903,733,556","-"],["미지급금","201,122,910","-","391,599,000","-"],["예수금","43,477,908","-","51,265,558","-"],["부가세예수금","156,644,676","-","422,671,268","-"],["선수금","762,630,911","-","2,942,882,289","-"],["단기차입금","8,429,000,000","-","6,546,273,596","-"],["미지급비용","515,880,138","-","480,194,737","-"],["유동성장기부채","261,902,299","-","166,555,344","-"],["비유동부채","-","1,888,655,356","-","1,656,900,953"],["장기차입금","1,567,354,433","-","1,329,256,732","-"],["장기미지급금","-","-","6,343,298","-"],["임대보증금","20,000,000","-","20,000,000","-"],["이연법인세부채","301,300,923","-","301,300,923","-"],["부채총계","-","14,371,882,302","-","14,562,076,301"],["자본금","-","-","-","-"],["자본금","-","710,000,000","-","710,000,000"],["보통주","525,000,000","-","525,000,000","-"],["우선주자본금","185,000,000","-","185,000,000","-"],["자본잉여금","-","1751424570","-","1,639,259,650"],["주식발행초과금","1,639,259,650","-","1,639,259,650","-"],["자본잉여금","112,164,920","-","-","-"],["자본조정","-","-","-","-"],["기타포괄손익누계액","-","1,140,330,287","-","1,140,330,287"],["재평가차익","1,140,330,287","-","1,140,330,287","-"],["이익잉여금","-","(1,323,169,511)","-","(34,816,292)"],["이익준비금","30,000,000","-","30,000,000","-"],["기업합리화적립금","2,871,327","-","2,871,327","-"],["상환주식의상환액","(50,000,000)","-","(50,000,000)","-"],["미처분이익잉여금","(1,306,040,838)","-","(17,687,619)","-"],["비지배주주지분","-","491,142,414","-","-"],["자본총계","-","2,769,727,760","-","3,454,773,645"],["부채와자본총계","-","17,141,610,062","-","18,016,849,946"]],[["제29기2024년01월01일부터2024년12월31일까지"],["제28기2023년01월01일부터2023년12월31일까지"]],[["과목","제29(당)기","제28(전)기"],["Ⅰ.매출액","-","25,779,164,428","-","30,441,966,842"],["Ⅱ.매출원가","-","22,177,718,017","-","26,022,531,256"],["Ⅲ.매출총이익","-","3,601,446,411","-","4,419,435,586"],["Ⅳ.판매비와관리비(주석13)","-","4,120,872,815","-","4,026,118,026"],["임원급여","546,612,603","-","533,031,260","-"],["급료","778,110,076","-","719,224,434","-"],["잡급","5,355,000","-","4,110,900","-"],["퇴직연금","147,432,515","-","135,627,525","-"],["성과금","105,800,000","-","19,640,000","-"],["복리후생비","140,587,216","-","128,136,832","-"],["여비교통비","92,951,463","-","110,451,812","-"],["접대비","56,053,670","-","58,575,376","-"],["통신비","23,419,895","-","21,723,960","-"],["가스수도료","1,700,860","-","198,930","-"],["전력비","8,674,765","-","11,962,766","-"],["세금과공과","77,544,666","-","64,510,852","-"],["유형자산감가상각비","177,496,274","-","173,417,567","-"],["임차료","38,455,335","-","71,296,829","-"],["수선비","9,976,938","-","6,210,000","-"],["보험료","142,576,514","-","93,810,707","-"],["차량유지비","42,740,921","-","34,842,777","-"],["경상연구개발비","872,486,712","-","1,085,988,493","-"],["교육훈련비","1,261,000","-","1,348,900","-"],["운반비","73,218,600","-","104,536,500","-"],["도서인쇄비","6,201,119","-","3,740,583","-"],["협회조합비","20,172,000","-","14,556,000","-"],["사무용품비","4,064,369","-","5,649,134","-"],["소모품비","4,055,251","-","10,446,023","-"],["광고선전비","2,359,620","-","9,410,843","-"],["대손상각비","-","-","16,899,300","--"],["무형자산상각비","110,905,175","-","109,688,686","-"],["리스료","60,769,248","-","53,811,240","-"],["지급수수료","569,291,010","-","423,269,797","-"],["박람회참가비","600,000","-","-","-"],["영업이익(손실)","-","(519,426,404)","-","393,317,560"],["영업외수익","-","125,987,059","-","177,698,545"],["이자수익","18,742,587","-","10,760,498","-"],["임대료","19,200,000","-","19,200,000","-"],["외환차익","486,068","-","45,739,003","-"],["단기매매증권평가이익","1,330,883","-","-","-"],["유형자산처분이익","-","-","76,112","-"],["지방자치단체보조금","10,234,900","-","26,072,550","-"],["잡이익","71,696,454","-","51,872,474","-"],["장기금융상품평가이익","4,296,167","-","23,727,435","-"],["외화환산이익","-","-","250,473","-"],["영업외비용","-","544,765,740","-","1,052,657,759"],["이자비용","474,253,900","-","524,684,211","-"],["외환차손","1,375,745","-","46,720,201","-"],["기부금","7,313,900","-","6,600,000","-"],["기타의대손상각비","60,408,159","-","-","-"],["무형자산감액손실","-","-","455,397,414","-"],["장기금융상품평가손실","243,230","-","-","-"],["유형자산처분손실","7,000","-","663,365","-"],["잡손실","1,163,806","-","18,592,568","-"],["Ⅷ.법인세차감전순이익","-","(938,205,085)","-","(481,641,654)"],["Ⅸ.법인세등(주석15)","-","-","-","7,782,388"],["Ⅹ.당기순이익","-","(938,205,085)","-","(489,424,042)"],["비지배지분손익","-","(350,148,134)","-","-"],["주당손익","-","-","-","-"],["기본주당순이익(손실)","-","(676)","-","(360)"]],[["제29기2024년01월01일부터2024년12월31일까지"],["제28기2023년01월01일부터2023년12월31일까지"]],[["과목","자본금","자본잉여금","자본조정","기타포괄손익누계액","이익잉여금","총계"],["2023.01.01(전기초)","710,000,000","1,639,259,650","19,038,159","1,124,472,344","454,607,750","3,947,377,903"],["주식매입선택권","-","-","(19,038,159)","-","-","(19,038,159)"],["지분법자본변동","-","-","-","7,297,316","-","7,297,316"],["재평가차익","-","-","-","8,560,627","-","8,560,627"],["당기순이익","-","-","-","-","(489,424,042)","(489,424,042)"],["2023.12.31(전기말)","710,000,000","1,639,259,650","-","1,140,330,287","(34,816,292)","3,454,773,645"],["2024.01.01(당기초)","710,000,000","1,639,259,650","-","1,140,330,287","(34,816,292)","3,454,773,645"],["당기순이익","-","-","-","-","(938,205,085)","(938,205,085)"],["비지배지분손익","-","-","-","-","(350,148,134)","(350,148,134)"],["지분법자본변동","-","-","-","-","112,164,920","112,164,920"],["비지배주주지분","-","-","-","-","491,142,414","491,142,414"],["2024.12.31(당기말)","710,000,000","1,639,259,650","-","1,140,330,287","(719,862,177)","2,769,727,760"]],[["제29기2024년01월01일부터2024년12월31일까지"],["제28기2023년01월01일부터2023년12월31일까지"]],[["과목","제29(당)","제28(전)"],["Ⅰ.영업활동으로인한현금흐름","-","(3,070,619,002)","-","2,232,894,518"],["1.당기순이익","(1,288,353,219)","-","(489,424,042)","-"],["2.현금의유출이없는비용등의가산","429,208,694","-","879,652,617","-"],["대손상각비","-","-","16,899,300","-"],["감가상각비","318,053,289","-","295,602,727","-"],["무형자산상각비","110,905,175","-","111,089,831","-"],["무형자산손상차손","-","-","455,397,414","-"],["유형자산처분손실","7,000","-","663,365","-"],["장기금융상품평가손실","243,230","-","-","-"],["3.현금의유입이없는수익등의차감","4,296,167","-","(42,841,706)","-"],["유형자산처분이익","-","-","(76,112)","-"],["장기금융상품평가이익","4,296,167","-","(23,727,435)","-"],["주식보상비용","-","-","(19,038,159)","-"],["4.영업활동으로인한자산부채의변동","(2,207,178,310)","-","1,885,507,649","-"],["매출채권의감소(증가)","(175,100,019)","-","(403,217,234)","-"],["재고자산의감소(증가)","247,156,899","-","2,877,615","-"],["선급비용의감소(증가)","181,563,043","-","(65,130,267)","-"],["미수금의증가","(113,410,659)","-","79,338,882","-"],["선급금의증가","55,590,240","-","61,367,133","-"],["당기법인세자산의증가","(2,956,053)","-","1,959,860","-"],["보증금의증가","-","-","6,796,139","-"],["매입채무의감소(증가)","208,834,548","-","261,462,658","-"],["미지급금의감소(증가)","(190,476,090)","-","180,291,750","-"],["선수금의감소(증가)","(2,180,251,378)","-","1,386,123,079","-"],["예수금의증가(감소)","(7,787,650)","-","(7,802,280)","-"],["부가세예수금의감소(증가)","(266,026,592)","-","302,410,547","-"],["미지급비용의증가(감소)","35,685,401","-","97,237,439","-"],["당기법인세부채의증가","-","-","(25,990,060)","-"],["이연법인세부채감소(증가)","-","-","7,782,388","-"],["Ⅱ.투자활동으로인한현금흐름","-","279,426,664","-","(630,424,844)"],["1.투자활동으로인한현금유입액","888,589,826","-","46,543,468","-"],["유형자산의처분","-","-","46,543,468","-"],["개발비의감소","509,500,000","-","-","-"],["장기급융상품의처분","75,692,364","-","-","-"],["단기금융상품의감소","303,397,462","-","-","-"],["2.투자활동으로인한현금유출액","609,163,162","-","(676,968,312)","-"],["유형자산의증가","93,377,336","-","(221,374,517)","-"],["개발비의증가","373,073,430","-","(18,769,120)","-"],["특허권의증가","2,370,700","-","(6,300,100)","-"],["임대보증금의증가","(13,656,702)","-","-","-"],["출자금의증가","55,652,230","-","-","-"],["임차보증금의증가","32,000,000","-","-","-"],["단기금융상품의증가","-","-","(425,128,834)","-"],["장기금융상품의증가","66,346,168","-","(5,395,741)","-"],["Ⅲ.재무활동으로인한현금흐름","-","2,802,126,145","-","(476,644,200)"],["1.재무활동으로인한현금유입액","2,988,681,489","-","3,422,851,431","-"],["단기차입금의증가","1,882,726,404","-","2,099,594,784","-"],["장기차입금의증가","500,000,000","-","1,200,000,000","-"],["국가보조금의증가","2,647,751","-","123,256,647","-"],["자본금의증가","603,307,334","-","-","-"],["2.재무활동으로인한현금유출액","186,555,344","-","(3,899,495,631)","-"],["유동성장기부채의상환","166,555,344","-","(3,585,838,929)","-"],["장기미지급금의감소","20,000,000","-","(13,656,702)","-"],["장기차입금의상환","-","-","(300,000,000)","-"],["Ⅳ.현금의감소(I+II+III)","-","10,933,807","-","1,125,825,474"],["Ⅴ.기초의현금","-","1,928,912,681","-","803,087,207"],["Ⅵ.기말의현금(주석16)","-","1,939,846,488","-","1,928,912,681"]]],"currentHeaders":[{"table":0,"expected":[["제29기2024년01월01일부터2024년12월31일까지"],["제28기2023년01월01일부터2023년12월31일까지"]]},{"table":2,"expected":[["제29기2024년01월01일부터2024년12월31일까지"],["제28기2023년01월01일부터2023년12월31일까지"]]},{"table":6,"expected":[["제29기2024년01월01일부터2024년12월31일까지"],["제28기2023년01월01일부터2023년12월31일까지"]]}],"checks":[{"label":"BS","total":{"table":1,"row":52,"column":2,"raw":"17,141,610,062"},"totalCoefficient":1,"terms":[{"table":1,"row":68,"column":2,"raw":"14,371,882,302","coefficient":1},{"table":1,"row":85,"column":2,"raw":"2,769,727,760","coefficient":1}],"residualKRW":0,"missingTermCount":0},{"label":"OP","total":{"table":3,"row":35,"column":2,"raw":"(519,426,404)"},"totalCoefficient":1,"terms":[{"table":3,"row":1,"column":2,"raw":"25,779,164,428","coefficient":1},{"table":3,"row":2,"column":2,"raw":"22,177,718,017","coefficient":-1},{"table":3,"row":4,"column":2,"raw":"4,120,872,815","coefficient":-1}],"residualKRW":0,"missingTermCount":0},{"label":"pretax","total":{"table":3,"row":55,"column":2,"raw":"(938,205,085)"},"totalCoefficient":1,"terms":[{"table":3,"row":35,"column":2,"raw":"(519,426,404)","coefficient":1},{"table":3,"row":36,"column":2,"raw":"125,987,059","coefficient":1},{"table":3,"row":46,"column":2,"raw":"544,765,740","coefficient":-1}],"residualKRW":0,"missingTermCount":0},{"label":"directCFwholeNIvsPLcomponents","total":{"table":7,"row":2,"column":1,"raw":"(1,288,353,219)"},"totalCoefficient":1,"terms":[{"table":3,"row":57,"column":2,"raw":"(938,205,085)","coefficient":1},{"table":3,"row":58,"column":2,"raw":"(350,148,134)","coefficient":1}],"residualKRW":0,"missingTermCount":0},{"label":"CFO","total":{"table":7,"row":1,"column":2,"raw":"(3,070,619,002)"},"totalCoefficient":1,"terms":[{"table":7,"row":2,"column":1,"raw":"(1,288,353,219)","coefficient":1},{"table":7,"row":3,"column":1,"raw":"429,208,694","coefficient":1},{"table":7,"row":10,"column":1,"raw":"4,296,167","coefficient":-1},{"table":7,"row":14,"column":1,"raw":"(2,207,178,310)","coefficient":1}],"residualKRW":0,"missingTermCount":0},{"label":"CFI","total":{"table":7,"row":30,"column":2,"raw":"279,426,664"},"totalCoefficient":1,"terms":[{"table":7,"row":31,"column":1,"raw":"888,589,826","coefficient":1},{"table":7,"row":36,"column":1,"raw":"609,163,162","coefficient":-1}],"residualKRW":0,"missingTermCount":0},{"label":"CFF","total":{"table":7,"row":45,"column":2,"raw":"2,802,126,145"},"totalCoefficient":1,"terms":[{"table":7,"row":46,"column":1,"raw":"2,988,681,489","coefficient":1},{"table":7,"row":51,"column":1,"raw":"186,555,344","coefficient":-1}],"residualKRW":0,"missingTermCount":0},{"label":"cashActivities","total":{"table":7,"row":55,"column":2,"raw":"10,933,807"},"totalCoefficient":1,"terms":[{"table":7,"row":1,"column":2,"raw":"(3,070,619,002)","coefficient":1},{"table":7,"row":30,"column":2,"raw":"279,426,664","coefficient":1},{"table":7,"row":45,"column":2,"raw":"2,802,126,145","coefficient":1}],"residualKRW":0,"missingTermCount":0},{"label":"cashRoll","total":{"table":7,"row":57,"column":2,"raw":"1,939,846,488"},"totalCoefficient":1,"terms":[{"table":7,"row":56,"column":2,"raw":"1,928,912,681","coefficient":1},{"table":7,"row":55,"column":2,"raw":"10,933,807","coefficient":1}],"residualKRW":0,"missingTermCount":0},{"label":"BScash","total":{"table":1,"row":4,"column":1,"raw":"1,939,846,488"},"totalCoefficient":1,"terms":[{"table":7,"row":57,"column":2,"raw":"1,939,846,488","coefficient":1}],"residualKRW":0,"missingTermCount":0},{"label":"investmentOutflow","total":{"table":7,"row":36,"column":1,"raw":"609,163,162"},"totalCoefficient":1,"terms":[{"table":7,"row":37,"column":1,"raw":"93,377,336","coefficient":1},{"table":7,"row":38,"column":1,"raw":"373,073,430","coefficient":1},{"table":7,"row":39,"column":1,"raw":"2,370,700","coefficient":1},{"table":7,"row":40,"column":1,"raw":"(13,656,702)","coefficient":1},{"table":7,"row":41,"column":1,"raw":"55,652,230","coefficient":1},{"table":7,"row":42,"column":1,"raw":"32,000,000","coefficient":1},{"table":7,"row":43,"column":1,"raw":"-","coefficient":1},{"table":7,"row":44,"column":1,"raw":"66,346,168","coefficient":1}],"residualKRW":0,"missingTermCount":1},{"label":"investmentInflow","total":{"table":7,"row":31,"column":1,"raw":"888,589,826"},"totalCoefficient":1,"terms":[{"table":7,"row":32,"column":1,"raw":"-","coefficient":1},{"table":7,"row":33,"column":1,"raw":"509,500,000","coefficient":1},{"table":7,"row":34,"column":1,"raw":"75,692,364","coefficient":1},{"table":7,"row":35,"column":1,"raw":"303,397,462","coefficient":1}],"residualKRW":0,"missingTermCount":1},{"label":"financingInflow","total":{"table":7,"row":46,"column":1,"raw":"2,988,681,489"},"totalCoefficient":1,"terms":[{"table":7,"row":47,"column":1,"raw":"1,882,726,404","coefficient":1},{"table":7,"row":48,"column":1,"raw":"500,000,000","coefficient":1},{"table":7,"row":49,"column":1,"raw":"2,647,751","coefficient":1},{"table":7,"row":50,"column":1,"raw":"603,307,334","coefficient":1}],"residualKRW":0,"missingTermCount":0},{"label":"financingOutflow","total":{"table":7,"row":51,"column":1,"raw":"186,555,344"},"totalCoefficient":1,"terms":[{"table":7,"row":52,"column":1,"raw":"166,555,344","coefficient":1},{"table":7,"row":53,"column":1,"raw":"20,000,000","coefficient":1},{"table":7,"row":54,"column":1,"raw":"-","coefficient":1}],"residualKRW":0,"missingTermCount":1}],"core":[{"table":1,"row":52,"column":2,"kind":"BS","key":"assets","label":"자산총계","printed":"17,141,610,062","physicalOrd":55,"value":"17141610062","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":68,"column":2,"kind":"BS","key":"liabilities","label":"부채총계","printed":"14,371,882,302","physicalOrd":71,"value":"14371882302","magnitude":false,"explicitNormalizedLoss":false},{"table":1,"row":85,"column":2,"kind":"BS","key":"equity","label":"자본총계","printed":"2,769,727,760","physicalOrd":88,"value":"2769727760","magnitude":false,"explicitNormalizedLoss":false},{"table":3,"row":1,"column":2,"kind":"IS","key":"revenue","label":"Ⅰ.매출액","printed":"25,779,164,428","physicalOrd":93,"value":"25779164428","magnitude":false,"explicitNormalizedLoss":false},{"table":3,"row":35,"column":2,"kind":"IS","key":"operatingIncome","label":"영업이익(손실)","printed":"(519,426,404)","physicalOrd":127,"value":"-519426404","magnitude":false,"explicitNormalizedLoss":false},{"table":7,"row":2,"column":1,"kind":"CF","key":"netIncome","label":"1.당기순이익","printed":"(1,288,353,219)","physicalOrd":172,"value":"-1288353219","magnitude":false,"explicitNormalizedLoss":false},{"table":7,"row":1,"column":2,"kind":"CF","key":"operatingCashFlow","label":"Ⅰ.영업활동으로인한현금흐름","printed":"(3,070,619,002)","physicalOrd":171,"value":"-3070619002","magnitude":false,"explicitNormalizedLoss":false},{"table":7,"row":37,"column":1,"kind":"CF","key":"capex","label":"유형자산의증가","printed":"93,377,336","physicalOrd":207,"value":"93377336","magnitude":false,"explicitNormalizedLoss":false}],"scopeProof":{"partialCore7":false,"currentCore8":true,"wholeNetIncomeExact":true,"netIncomeSourceStatement":"CF","netIncomeSelection":"directOwnConsolidatedCFNetIncome","fullStatementCollected":false,"fullStatementVerified":false,"allStatementRowsVerified":false,"detailHierarchyComplete":false,"notesVerified":false,"notesReadScopeComplete":false,"CEUnitPrinted":false,"CECurrencyVerified":false,"CECurrencyCrosschecksClaim":false,"optionalAccountsNotCollected":[],"uncollectedOptionalAccounts":[],"missingTermNotFactZero":true,"numericCellCorrection":false,"genericRoundingTolerance":false,"priorNumericPeriodsCollected":false,"printedPLNI":{"table":3,"row":57,"column":2,"raw":"(938,205,085)"},"printedPLNCI":{"table":3,"row":58,"column":2,"raw":"(350,148,134)"},"wholePLNISynthesized":false,"PPEOutflowContext":{"subtotal":{"table":7,"row":36,"column":1,"raw":"609,163,162"},"directWholePPE":{"table":7,"row":37,"column":1,"raw":"93,377,336"},"magnitudeStored":true,"SourceSignCorrection":false},"checkedPrintedEquationCount":14,"fullyNumericEquationCount":11,"sourceDiscrepancies":[],"cashMovementCaption":"Raw 現金의감소 caption preserved despite positive 10,933,807; no forced signflip","BSDateCaption":"Raw flow caption Jan1–Dec31 preserved; own current column and printed end Dec31 bind balance-sheet closing date."}}}''',
  ) as Map<String, dynamic>;
  static String compact(String x) => x
      .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), '');
  static List<Map<String, dynamic>> parse({
    required Map<String, String> raw,
    required Map<String, Uri> uris,
    required String receipt,
    required String corp,
    required DateTime start,
    required DateTime end,
    required bool consolidated,
  }) {
    void guard(bool ok, String why) {
      if (!ok) throw FormatException('Suntech exact current: $why');
    }

    guard(
      profiles.containsKey(receipt) &&
          corp == '00963000' &&
          consolidated &&
          start == DateTime.utc(profiles[receipt]['year'] as int) &&
          end == DateTime.utc(profiles[receipt]['year'] as int, 12, 31),
      'issuer/basis/period mismatch',
    );
    final profile = profiles[receipt] as Map<String, dynamic>;
    final year = profile['year'] as int;
    guard(raw.length == 3 && uris.length == 3, 'own source set mismatch');
    for (final v in profile['sources'] as List) {
      final label = v['label'] as String;
      guard(
        raw[label] != null &&
            uris[label].toString() == v['url'] &&
            sha256.convert(utf8.encode(raw[label]!)).toString() == v['sha256'],
        'own URI/SHA mismatch',
      );
    }
    final ids = RegExp(r"openCorpInfoNew\('([0-9]{8})'")
        .allMatches(raw['shell']!)
        .map((v) => v[1])
        .toSet();
    guard(ids.length == 1 && ids.single == corp, 'own shell corp missing');
    guard(
      compact(raw['cover']!).contains('썬테크') &&
          compact(raw['cover']!).contains('$year년01월01일'),
      'own cover/current period missing',
    );
    final nodes =
        RegExp(
              r'''(node[12])\['text'\]\s*=\s*"([^"]+)";(.*?)(?=node[12]\['text'\]|$)''',
              dotAll: true,
            )
            .allMatches(raw['shell']!)
            .where((v) => compact(v[2]!) == '2.연결재무제표')
            .toList();
    guard(nodes.length == 1, 'unique own CFS node missing');
    final attributes = <String, String>{};
    for (final v in RegExp(
      r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*"([^"]+)"''',
    ).allMatches(nodes.single[3]!)) {
      guard(!attributes.containsKey(v[1]), 'duplicate source coordinate');
      attributes[v[1]!] = v[2]!;
    }
    guard(
      attributes.length == 6 &&
          attributes.entries.every(
            (v) => uris['cfs']!.queryParameters[v.key] == v.value,
          ),
      'own CFS chain mismatch',
    );
    final tables =
        RegExp(r'<table\b[^>]*>([\s\S]*?)</table>', caseSensitive: false)
            .allMatches(raw['cfs']!)
            .map(
              (table) =>
                  RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false)
                      .allMatches(table[1]!)
                      .map(
                        (row) =>
                            RegExp(
                                  r'<t[dh]\b[^>]*>([\s\S]*?)</t[dh]>',
                                  caseSensitive: false,
                                )
                                .allMatches(row[1]!)
                                .map((cell) => compact(cell[1]!))
                                .toList(),
                      )
                      .toList(),
            )
            .toList();
    guard(
      jsonEncode(tables) == jsonEncode(profile['tables']),
      'physical whole source rows changed',
    );
    for (final v in profile['currentHeaders'] as List) {
      guard(
        jsonEncode(tables[v['table'] as int]) == jsonEncode(v['expected']),
        'own current header/unit missing',
      );
    }
    BigInt? money(String x) {
      if (x == '' || x == '-') return null;
      guard(
        RegExp(
          r'^(?:-?(?:0|[1-9][0-9]*|[1-9][0-9]{0,2}(?:,[0-9]{3})+)|\((?:0|[1-9][0-9]*|[1-9][0-9]{0,2}(?:,[0-9]{3})+)\))$',
        ).hasMatch(x),
        'invalid printed monetary group',
      );
      return BigInt.parse(
        x.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    for (final eq in profile['checks'] as List) {
      final total = eq['total'] as Map;
      final current = money(
        tables[total['table'] as int][total['row'] as int][total['column']
            as int],
      );
      guard(current != null, 'unprinted total');
      var sum = BigInt.zero;
      var missing = 0;
      for (final term in eq['terms'] as List) {
        final value = money(
          tables[term['table'] as int][term['row'] as int][term['column']
              as int],
        );
        if (value == null) {
          missing++;
        } else {
          sum += value * BigInt.from(term['coefficient'] as int);
        }
      }
      guard(
        current! * BigInt.from(eq['totalCoefficient'] as int) == sum &&
            missing == eq['missingTermCount'],
        'bound printed subtotal identity changed',
      );
    }
    return [
      for (final cell in profile['core'] as List)
        _row(cell, tables, money, uris, guard, profile),
    ];
  }

  static List<Map<String, dynamic>> expectedRows(String receipt) {
    final profile = profiles[receipt] as Map<String, dynamic>;
    final uris = <String, Uri>{
      for (final s in profile['sources'] as List)
        s['label'] as String: Uri.parse(s['url'] as String),
    };
    BigInt? money(String x) => x == '' || x == '-'
        ? null
        : BigInt.parse(
            x.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
          );
    void guard(bool ok, String why) {
      if (!ok) throw FormatException(why);
    }

    return [
      for (final c in profile['core'] as List)
        _row(c, profile['tables'] as List, money, uris, guard, profile),
    ];
  }

  /// Exact projection persisted by the existing numeric-source audit writer.
  static List<Map<String, dynamic>> sourceAuditRows(String receipt) => [
    for (final row in expectedRows(receipt))
      {
        'account_nm': row['account_nm'],
        'account_id': row['account_id'],
        'thstrm_amount': row['thstrm_amount'],
        'currency': row['currency'],
        'html_provenance': row['html_provenance'],
        'xbrl_provenance': row['xbrl_provenance'],
      },
  ];

  static Map<String, dynamic> _row(
    Map cell,
    List tables,
    BigInt? Function(String) money,
    Map<String, Uri> uris,
    void Function(bool, String) guard,
    Map<String, dynamic> profile,
  ) {
    final year = profile['year'] as int;
    final receipt = profile['receipt'] as String;
    final actual =
        tables[cell['table'] as int][cell['row'] as int][cell['column'] as int]
            as String;
    final printed = money(actual);
    guard(
      printed != null && actual == cell['printed'],
      'direct current cell missing',
    );
    final value = printed!;
    guard(
      value.toString() == cell['value'],
      'current normalized amount mismatch',
    );
    return {
      'rcept_no': receipt,
      'corp_code': '00963000',
      'bsns_year': '$year',
      'reprt_code': '11011',
      'fs_div': 'CFS',
      'account_id': null,
      'account_nm': cell['label'],
      'account_detail': '-',
      'ord': '${cell['physicalOrd']}',
      'sj_div': cell['kind'],
      'thstrm_nm': cell['kind'] == 'BS'
          ? '$year-12-31'
          : '$year-01-01~$year-12-31',
      'thstrm_amount': value.toString(),
      'currency': 'KRW',
      'html_provenance': {
        'source': uris['cfs'].toString(),
        'sourceReceipt': receipt,
        'ruleVersion': rule,
        'sourceSha256': (profile['sources'] as List).singleWhere(
          (v) => v['label'] == 'cfs',
        )['sha256'],
        'tableIndex': cell['table'],
        'rowIndex': cell['row'],
        'column': cell['column'],
        'physicalOrd': cell['physicalOrd'],
        'printedLabel': cell['label'],
        'currentCell': actual,
        'printedUnit': '원',
        'unitMultiplier': '1',
        'precisionUnit': '1',
        'cashDirection': cell['key'] == 'capex' ? 'outflow' : null,
        'printedSign': printed.isNegative ? 'negative' : 'positive',
        'normalizedSign': value.isNegative ? 'negative' : 'positive',
        'signNormalization': 'none',
        'sourceCellRewritten': false,
        'basis': 'CFS',
        'periodStart': '$year-01-01',
        'periodEnd': '$year-12-31',
        ...profile['scopeProof'] as Map<String, dynamic>,
        'fullStatementCollected': false,
        'supportingPeriodEvidence': {
          'policy': rule,
          'flowCaptionPrintedStart': true,
          'periodStart': '$year-01-01',
          'periodEnd': '$year-12-31',
          'scopeProof': profile['scopeProof'],
          'currentEquationWitnesses': profile['checks'],
        },
      },
    };
  }
}
