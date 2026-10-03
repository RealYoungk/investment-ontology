import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../generated/protocol.dart';
import 'public_financial_html_fetch.dart';
import 'verified_annual_source_registry.dart';

/// Finite own current-row packages. Original and correction receipts stay distinct.
abstract final class LocatedOwnCurrentSource {
  static const absenceRule = 'located-own-explicit-cfs-absence-v1';
  static const rule = 'located-own-current-eight-v1';
  static const printedLossRule = 'located-own-printed-loss-current-eight-v1';
  static const partialRule = 'located-own-current-seven-v1';
  static const capexMissingReason =
      'No printed whole PPE acquisition total; printed acquisition components are not the total.';
  static final List _profiles = jsonDecode(
    r'''[{"receipt":"20251021000231","corp":"01035942","name":"(주)메디안디노스틱","year":2024,"basis":"consolidated","sourceReceipt":"20251021000220","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20251021000231-cfs-located-own-current","digest":"89f834093957526744792ed3d9880d603bb806622e8db6644a1d07237bd6fda7","sourceDigest":"af7790fe62b3c89d67613def1dd07b61542b616906cda689705f0079810af315","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20251021000220&dcmNo=10846771&eleId=21&offset=331848&length=55177&dtd=dart4.xsd","statementSHA":"2ae8f77e5bd1ec4800b0474160a2cab19b4574ed1959f5e493d2e7008b0d649b"},{"receipt":"20251021000231","corp":"01035942","name":"(주)메디안디노스틱","year":2024,"basis":"separate","sourceReceipt":"20251021000220","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20251021000231-ofs-located-own-current","digest":"0e1f76876409477f5da88a2c4cb134527d4b6ea91cb00a79590f67a2431225f9","sourceDigest":"9614693495143ef8753ff583ee665bf338d86e6591fb604059fb2f370871b2c4","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20251021000220&dcmNo=10846771&eleId=23&offset=675311&length=48682&dtd=dart4.xsd","statementSHA":"49c2d2d7f8134f479e63e645beb2960e557e22084b301da097bb9ba789e4bcdb"},{"receipt":"20230321001535","corp":"00990396","name":"(주)레드우즈","year":2022,"basis":"consolidated","sourceReceipt":"20230321001515","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230321001535-cfs-located-own-current","digest":"3275bc2ffae06e0f76fd36bf9fb002c126dd179720f9addd65fb3a22d91e25ee","sourceDigest":"4729421e346acef6528e18ad0f9e7dffc0122c9859b235a771be5c53e10843cc","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001515&dcmNo=9085914&eleId=19&offset=139791&length=55959&dtd=dart3.xsd","statementSHA":"8cdeea8ef47694259dafe6a208c2ee043319f5b6db875f385f0c87c8d49ab850"},{"receipt":"20230321001535","corp":"00990396","name":"(주)레드우즈","year":2022,"basis":"separate","sourceReceipt":"20230321001515","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230321001535-ofs-located-own-current","digest":"610751dd98b52d5dc3cc393700e57b92d7c120a67bcdfa200a26510f058d13b0","sourceDigest":"d63c01a407500235270f6fd366eac9239bd8636f28c74140679de2660a4e6535","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001515&dcmNo=9085914&eleId=21&offset=498919&length=48967&dtd=dart3.xsd","statementSHA":"45052061e6962b918f8a9f20acc4b0548039583e95b61f645359f38b2b4a229b"},{"receipt":"20230721000635","corp":"01579020","name":"(주)아이엠지티","year":2022,"basis":"separate","sourceReceipt":"20230721000635","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230721000635-ofs-located-own-current","digest":"d7e5b8b4e832c153c4762e900393e7cc71bb6c43af223990874465b8123425dc","sourceDigest":"6399f1770820b859551fe7494c0d5ea58d14ae6857af2f67049cca1fcd2e7329","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230721000635&dcmNo=9358597&eleId=21&offset=175703&length=86206&dtd=dart3.xsd","statementSHA":"47f6e3f386f66d431ec5e33ce5c688c8096b19ae532854c10cd019b4e542dee5"},{"receipt":"20220322000617","sourceReceipt":"20220322000512","corp":"00149594","name":"한국캐피탈(주)","year":2021,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20220322000617-cfs-located-own-absence","digest":"be4cdb5a1fdd215f2b06b25f8a4505d969360ef575508e71ceec72dcabcbaaef","absenceLiteral":"2. 연결재무제표 - 해당사항 없음"},{"receipt":"20220421000450","sourceReceipt":"20220421000448","corp":"00414540","name":"대주이엔티(주)","year":2021,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20220421000450-cfs-located-own-absence","digest":"6f43c49351a80f4d892dee1ffffd2437ebdcb552660cdcd5bf386c61edd1cfbd","absenceLiteral":"2. 연결재무제표 - 해당사항 없습니다."},{"receipt":"20240704000080","sourceReceipt":"20240704000080","corp":"00666329","name":"(주)코나솔","year":2023,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20240704000080-cfs-located-own-absence","digest":"930b9ed5ce08c22f9375379634660d2327d9a062fa069e5d0b1ad228f23b41cc","absenceLiteral":"2. 연결재무제표 당사는 사업보고서 제출일 현재 해당사항이 없습니다"},{"receipt":"20230331004542","sourceReceipt":"20230331004538","corp":"01203312","name":"주식회사 케이뱅크","year":2022,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20230331004542-cfs-located-own-absence","digest":"0090b7831c0456ff5aa45df4d7af508d676eb2d6724b85b643e462982f4dca04","absenceLiteral":"2. 연결재무제표 해당사항 없습니다."},{"receipt":"20220318000774","sourceReceipt":"20220310001176","corp":"01466832","name":"(주)라피치","year":2021,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20220318000774-cfs-located-own-absence","digest":"898c1fef84f882aca78edc94b53dc4748a768bc7c478d9e3c97ea99fdbcce508","absenceLiteral":"2. 연결재무제표 당사는 사업보고서 제출일 현재 해당사항이 없습니다."},{"receipt":"20230721000635","sourceReceipt":"20230721000635","corp":"01579020","name":"(주)아이엠지티","year":2022,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20230721000635-cfs-located-own-absence","digest":"ec713395b2e0df944b9e40addc78c324015f8de29dce00a96e4f9e7c862fb585","absenceLiteral":"2. 연결재무제표 당사는 사업보고서 기준일 현재 해당사항 없습니다."},{"receipt":"20220615000399","corp":"00136721","name":"신영증권(주)","year":2022,"basis":"separate","sourceReceipt":"20220615000399","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20220615000399-ofs-located-own-current","digest":"4ef91342e5fa142840264cbaae4fe3908b0e5ca8344cccd1d7990a9bec649e34","sourceDigest":"8342d38ca1b5a144b8a57efc4a4166161f3638594b68cc83a651882b142ac1a5","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220615000399&dcmNo=8701694&eleId=19&offset=1127761&length=74482&dtd=dart3.xsd","statementSHA":"b55697be746e47ee90663b1d6d9eefc6d36fc5015fd44a4005af4203b0a64d82","periodStart":"2021-04-01","periodEnd":"2022-03-31","requiresOwnNotes":true,"coverPeriodTokens":["2021년04월01일","2022년03월31일"]},{"receipt":"20250320000572","corp":"01063556","name":"(주)질경이","year":2024,"basis":"separate","sourceReceipt":"20250320000572","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20250320000572-ofs-located-own-current","digest":"efc418d6d201129512833d82eb693890e427f516d55b666a81827efcbaaa0c8b","sourceDigest":"e63aa7a61d14c80f568467f426f43b0c8f4af36a715d1752c7c5aa7700c9a8cd","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320000572&dcmNo=10433870&eleId=21&offset=559412&length=45860&dtd=dart4.xsd","statementSHA":"f133d3d6ee63ddf3c4d051165445baf39d81da8f4160d84821c66a8f6e6078d5","periodStart":"2024-01-01","periodEnd":"2024-12-31","requiresOwnNotes":true,"coverPeriodTokens":["2024년01월01일","2024년12월31일"]},{"receipt":"20220322000802","corp":"01116344","name":"이비테크(주)","year":2021,"basis":"separate","sourceReceipt":"20220322000802","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20220322000802-ofs-located-own-seven","digest":"2485e6e119aa1b2a9d17bb177d2b33d5246ac0cef4aa3d6c7bb392c8684f344d","sourceDigest":"84d3e9dca89dfbb45b0b7ea3ddf31c5d5b7f63264c65007cdcd8382461cd7c62","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220322000802&dcmNo=8491700&eleId=21&offset=104211&length=61838&dtd=dart3.xsd","statementSHA":"461d7461a17ce3eae8b2af6347c9a524831a727e4249b75e3b0d972b80cc4167","periodStart":"2021-01-01","periodEnd":"2021-12-31","coverPeriodTokens":["2021년01월01일","2021년12월31일"],"coreCells":[{"table":1,"row":43,"column":2,"label":"자산총계","literal":"13,640,640,446","value":13640640446,"key":"assets","kind":"BS"},{"table":1,"row":57,"column":2,"label":"부채총계","literal":"1,932,480,266","value":1932480266,"key":"liabilities","kind":"BS"},{"table":1,"row":65,"column":2,"label":"자본총계","literal":"11,708,160,180","value":11708160180,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":2,"label":"Ⅰ.매출액","literal":"5,442,616,873","value":5442616873,"key":"revenue","kind":"CIS"},{"table":3,"row":35,"column":2,"label":"Ⅴ.영업이익","literal":"980,641,199","value":980641199,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":50,"column":2,"label":"Ⅹ.당기순이익","literal":"1,252,122,946","value":1252122946,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":2,"label":"Ⅰ.영업활동으로인한현금흐름","literal":"1,108,524,316","value":1108524316,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20250429000919","corp":"01366824","name":"(주)제이엠멀티","year":2024,"basis":"separate","sourceReceipt":"20250429000919","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20250429000919-ofs-located-own-seven","digest":"de0e64e1faf02a7dc3b8c48f4ae8e914cb2609daef747f712b60fab643ced49f","sourceDigest":"71dbd5715f71f7d9f2bd634ea79e09275deb361f3d9fccea0ad4b0a7bf9ea142","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250429000919&dcmNo=10622174&eleId=23&offset=497606&length=92172&dtd=dart4.xsd","statementSHA":"f8d6476b43a84323bc9819bf4e269b5a0d141a97c0334f1917f1e83e53c59a75","periodStart":"2024-01-01","periodEnd":"2024-12-31","coverPeriodTokens":["2024년01월01일","2024년12월31일"],"coreCells":[{"table":1,"row":42,"column":1,"label":"자산총계","literal":"16,084,409,690","value":16084409690,"key":"assets","kind":"BS"},{"table":1,"row":62,"column":1,"label":"부채총계","literal":"11,039,082,612","value":11039082612,"key":"liabilities","kind":"BS"},{"table":1,"row":73,"column":1,"label":"자본총계","literal":"5,045,327,078","value":5045327078,"key":"equity","kind":"BS"},{"table":3,"row":3,"column":1,"label":"Ⅰ.매출액","literal":"5,905,964,916","value":5905964916,"key":"revenue","kind":"CIS"},{"table":3,"row":42,"column":1,"label":"Ⅴ.영업이익","literal":"631,071,070","value":631071070,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":66,"column":1,"label":"Ⅹ.당기순이익","literal":"110,592,403","value":110592403,"key":"netIncome","kind":"CIS"},{"table":7,"row":3,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"282,402,537","value":282402537,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20240424000570","corp":"01366824","name":"(주)제이엠멀티","year":2023,"basis":"consolidated","sourceReceipt":"20240424000570","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20240424000570-cfs-located-own-seven","digest":"c29444e8944b07fc0c821a63ff93967082ccf6cd25c1a50a13b19d696dff1d58","sourceDigest":"2a0f6b6f09037d78664769f82e78bbb79bf3432333e0d809d689bb51b843f675","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20240424000570&dcmNo=9915137&eleId=21&offset=207959&length=83860&dtd=dart4.xsd","statementSHA":"76c36c8f05076f229c560f48334e1f1841904bdc5e3b8d6d814d9931c9af83b4","periodStart":"2023-01-01","periodEnd":"2023-12-31","coverPeriodTokens":["2023년01월01일","2023년12월31일"],"coreCells":[{"table":1,"row":52,"column":1,"label":"자산총계","literal":"27,090,759,677","value":27090759677,"key":"assets","kind":"BS"},{"table":1,"row":73,"column":1,"label":"부채총계","literal":"21,955,237,924","value":21955237924,"key":"liabilities","kind":"BS"},{"table":1,"row":89,"column":1,"label":"자본총계","literal":"5,135,521,753","value":5135521753,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":1,"label":"I.매출액","literal":"27,566,621,076","value":27566621076,"key":"revenue","kind":"CIS"},{"table":3,"row":47,"column":1,"label":"V.영업이익","literal":"(1,134,271,491)","value":-1134271491,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":73,"column":1,"label":"X.당기순이익(손실)","literal":"(1,965,491,271)","value":-1965491271,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"848,887,238","value":848887238,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20230314000692","corp":"00113359","name":"교보증권(주)","year":2022,"basis":"consolidated","sourceReceipt":"20230314000692","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230314000692-cfs-located-own-current","digest":"c39465856e5876afe991b17687ac86c4a1222c07f431c5dc5284afdca9db2c4b","sourceDigest":"02645bbb853b2642a9d5620a156048a3166747f24d2a9fea48c310965d0dcb34","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000692&dcmNo=9053903&eleId=17&offset=538174&length=64343&dtd=dart3.xsd","statementSHA":"3a10f627c47c32761929697459ac83496258b92bac617816f59abdfa72c8abad","periodStart":"2022-01-01","periodEnd":"2022-12-31","requiresOwnNotes":true,"coverPeriodTokens":["2022년01월01일","2022년12월31일"],"noteSHA":"a45867870163ddd7432cd7356c28f58e569ff4e898a50d5524741c0cbf676791","crossPrecisionLiteralRemainders":[-101,363,-50,-447],"mainPrecisionCells":[[1,2,1],[7,35,1],[1,2,2],[7,34,1]],"notePrecisionCells":[[155,2,1],[155,4,1],[155,2,2],[155,4,2]],"coreCells":[{"table":1,"row":13,"column":1,"label":"자산총계","literal":"13,417,260,497,201","value":13417260497201,"key":"assets","kind":"BS"},{"table":1,"row":23,"column":1,"label":"부채총계","literal":"11,855,462,300,592","value":11855462300592,"key":"liabilities","kind":"BS"},{"table":1,"row":32,"column":1,"label":"자본총계","literal":"1,561,798,196,609","value":1561798196609,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":1,"label":"I．영업수익","literal":"4,065,850,269,135","value":4065850269135,"key":"revenue","kind":"CIS"},{"table":3,"row":18,"column":1,"label":"III.영업이익","literal":"51,650,690,828","value":51650690828,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":23,"column":1,"label":"VIII.당기순이익","literal":"43,289,135,655","value":43289135655,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"(929,113,661,308)","value":-929113661308,"key":"operatingCashFlow","kind":"CF"},{"table":7,"row":19,"column":1,"label":"유형자산의취득","literal":"(12,814,286,680)","value":-12814286680,"key":"capex","kind":"CF"}]},{"receipt":"20230314000692","corp":"00113359","name":"교보증권(주)","year":2022,"basis":"separate","sourceReceipt":"20230314000692","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230314000692-ofs-located-own-current","digest":"4123cbe5ea35fd6ef275aa10696b3ef88b40a8fc9b8eaea6173fdb09b1a706ed","sourceDigest":"1fa6c42bb92bc497cda0f0c7f4b0212553c8d055de5cd7de0225fe69995761da","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000692&dcmNo=9053903&eleId=19&offset=1393110&length=62092&dtd=dart3.xsd","statementSHA":"b89b4669555a6c2cd77787775762cb4824a3a96a8edb3f0bba888a03dc65c5c5","periodStart":"2022-01-01","periodEnd":"2022-12-31","requiresOwnNotes":true,"coverPeriodTokens":["2022년01월01일","2022년12월31일"],"noteSHA":"0453470adeee47642198f32eeba4fa2ded89a140427e44744708285b2673d782","crossPrecisionLiteralRemainders":[-154,310,-297,306],"mainPrecisionCells":[[1,2,1],[9,36,1],[1,2,2],[9,35,1]],"notePrecisionCells":[[155,2,1],[155,4,1],[155,2,2],[155,4,2]],"coreCells":[{"table":1,"row":13,"column":1,"label":"자산총계","literal":"12,149,139,534,066","value":12149139534066,"key":"assets","kind":"BS"},{"table":1,"row":23,"column":1,"label":"부채총계","literal":"10,584,274,049,147","value":10584274049147,"key":"liabilities","kind":"BS"},{"table":1,"row":30,"column":1,"label":"자본총계","literal":"1,564,865,484,919","value":1564865484919,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":1,"label":"I．영업수익","literal":"4,036,211,804,575","value":4036211804575,"key":"revenue","kind":"CIS"},{"table":3,"row":18,"column":1,"label":"III.영업이익","literal":"90,025,670,393","value":90025670393,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":23,"column":1,"label":"VIII.당기순이익(대손준비금반영후조정이익당기:42,496,823,151원전기:143,662,328,354원전전기:103,600,160,833원)","literal":"44,599,774,443","value":44599774443,"key":"netIncome","kind":"CIS"},{"table":9,"row":1,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"70,701,089,899","value":70701089899,"key":"operatingCashFlow","kind":"CF"},{"table":9,"row":21,"column":1,"label":"유형자산의취득","literal":"(12,814,286,680)","value":-12814286680,"key":"capex","kind":"CF"}]},{"receipt":"20250407004339","sourceReceipt":"20250407004208","corp":"01118643","name":"(주)솔루믹스","year":2024,"basis":"separate","rule":"located-own-printed-loss-current-eight-v1","directory":"assets/financial_source_cache/20250407004339-ofs-located-own-loss-eight","digest":"615bc8f19c7d862d4a94756b632665666d9c225117f009e435adeee7aa8116d9","sourceDigest":"d748fcf7ba86e0755b448d49d969611582c60bd4c3914db93cab8b6c5051e998","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250407004208&dcmNo=10552128&eleId=21&offset=535164&length=43797&dtd=dart4.xsd","statementSHA":"13f346389d0f93f9b5b2abc9d89c2547540afd5a1c595cfcc78471a24a71bfb7","periodStart":"2024-01-01","periodEnd":"2024-12-31","lossMagnitudeKeys":["operatingIncome","netIncome"],"ownCoverActor":"주식회사로보쓰리에이아이","ownIssuerFilingSeriesEvidence":{"policy":"exact-own-filing-series-current-rows-v1","identityScope":"official-DART-filing-series-only","ownCoverActor":"주식회사로보쓰리에이아이","currentName":"(주)솔루믹스","corpCode":"01118643","ownShellCorpProof":"01118643","sourceReceipt":"20250407004208","targetReceipt":"20250407004339","ownShellSource":"https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250407004208","ownShellSha256":"27eb1cab4b657d8a350cadb047e7743ecb47e75244818c9b31491540b954243b","coverSource":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250407004208&dcmNo=10552128&eleId=1&offset=959&length=4494&dtd=dart4.xsd","coverSha256":"87f8d01b836a114296f1702e109f5665767bfdac20384503c6a48863a40f456e","jurirContinuityVerified":false,"operatingHistoryContinuityVerified":false},"coreCells":[{"table":1,"row":17,"column":2,"label":"자산총계","literal":"6,748,542,446","value":6748542446,"key":"assets","derivedInterpretation":6748542446,"signRule":"none","kind":"BS","signNormalization":"none"},{"table":1,"row":31,"column":2,"label":"부채총계","literal":"5,130,649,389","value":5130649389,"key":"liabilities","derivedInterpretation":5130649389,"signRule":"none","kind":"BS","signNormalization":"none"},{"table":1,"row":37,"column":2,"label":"자본총계","literal":"1,617,893,057","value":1617893057,"key":"equity","derivedInterpretation":1617893057,"signRule":"none","kind":"BS","signNormalization":"none"},{"table":4,"row":1,"column":2,"label":"I.매출액","literal":"579,284,000","value":579284000,"key":"revenue","derivedInterpretation":579284000,"signRule":"none","kind":"CIS","signNormalization":"none"},{"table":4,"row":5,"column":2,"label":"IV.영업손실","literal":"1,541,424,780","value":1541424780,"key":"operatingIncome","derivedInterpretation":-1541424780,"signRule":"explicitLossMagnitudeOnly","kind":"CIS","signNormalization":"explicitPrintedLossMagnitudeCorroborated"},{"table":4,"row":13,"column":2,"label":"VII.당기순손실","literal":"15,048,850,696","value":15048850696,"key":"netIncome","derivedInterpretation":-15048850696,"signRule":"explicitLossMagnitudeOnly","kind":"CIS","signNormalization":"explicitPrintedLossMagnitudeCorroborated"},{"table":10,"row":1,"column":2,"label":"I.영업활동으로인한현금흐름","literal":"(1,615,783,238)","value":-1615783238,"key":"operatingCashFlow","derivedInterpretation":-1615783238,"signRule":"none","kind":"CF","signNormalization":"none"},{"table":10,"row":24,"column":2,"label":"유형자산의취득","literal":"195,994,915","value":195994915,"key":"capex","derivedInterpretation":195994915,"signRule":"none","kind":"CF","signNormalization":"none"}]},{"receipt":"20230314000604","corp":"00148610","name":"한화투자증권(주)","year":2022,"basis":"separate","sourceReceipt":"20230314000604","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230314000604-ofs-located-own-current","digest":"8a38fa1ed8053a141aea6ae032adc520c279386b01bfa4c3a499b9b1a99a8441","sourceDigest":"d02ae964630763028e57f51cd48a4ee4e5dfc1a291ff5718a061e5ea9609c3ac","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314000604&dcmNo=9053632&eleId=19&offset=1586818&length=80144&dtd=dart3.xsd","statementSHA":"a0eea6a4547c6c78dcb0cb1b44fc6bcc68fa9c8268e7386cf51fca6f65d6547c","periodStart":"2022-01-01","periodEnd":"2022-12-31","requiresOwnNotes":true,"coverPeriodTokens":["2022.01.01","2022.12.31"],"noteSHA":"fee05d5ab134b35944ed005225e01d67745a5cb2d57fade24a1e822decceb6e2","crossPrecisionLiteralRemainders":[-747,-393,-40,-78],"mainPrecisionCells":[[1,2,1],[7,94,1],[1,2,2],[7,92,1]],"notePrecisionCells":[[68,19,1],[68,6,1],[68,19,2],[68,6,2]],"noteUnitCell":[67,0,0],"mainFullyNumericCheckCount":6,"coreCells":[{"table":1,"row":14,"column":1,"label":"자산총계","literal":"11,109,693,898,660","value":11109693898660,"key":"assets","kind":"BS"},{"table":1,"row":28,"column":1,"label":"부채총계","literal":"9,524,691,995,176","value":9524691995176,"key":"liabilities","kind":"BS"},{"table":1,"row":35,"column":1,"label":"자본총계","literal":"1,585,001,903,484","value":1585001903484,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":1,"label":"I.영업수익","literal":"2,059,136,420,659","value":2059136420659,"key":"revenue","kind":"CIS"},{"table":3,"row":19,"column":1,"label":"III.영업손익","literal":"53,860,324,418","value":53860324418,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":24,"column":1,"label":"VIII.당기순손익(대손준비금반영후조정손익당기:-26,558,393,256원전기:139,504,588,566원전전기:55,820,612,484원)","literal":"-23,530,284,903","value":-23530284903,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"287,695,588,326","value":287695588326,"key":"operatingCashFlow","kind":"CF"},{"table":7,"row":78,"column":1,"label":"유형자산의취득","literal":"-9,379,614,884","value":-9379614884,"key":"capex","kind":"CF"}],"ceMissingCurrentTotalCells":[{"table":5,"row":22,"column":6,"literal":"-"},{"table":5,"row":24,"column":6,"literal":"-"}]},{"receipt":"20260323001293","sourceReceipt":"20260323001293","corp":"00541862","name":"(주)판도라티비","year":2025,"basis":"separate","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20260323001293-ofs-located-own-seven","digest":"0e00d65b64e8815caca8dbcb96e10e412c8899ea52232729c44c7cddabd06542","sourceDigest":"4768abd1f044566489b2e05794e422b920f50ad4f525d90436285c24f5ac7341","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20260323001293&dcmNo=11166834&eleId=21&offset=578017&length=44326&dtd=dart4.xsd","statementSHA":"e2ee5952f63fafc3ebfbb65034aa053dbaa250b5edc550b29d5359a3a510b9d5","periodStart":"2025-01-01","periodEnd":"2025-12-31","coverPeriodTokens":["2025년01월01일","2025년12월31일"],"requiresBoundedUnverifiedNotes":true,"noteURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20260323001293&dcmNo=11166834&eleId=22&offset=622347&length=322014&dtd=dart4.xsd","noteSHA":"8f9edcc77d8009e9a6cce2a1e228b33834050842b8aa80cca2ed1d40c30f2a82","ownNoteDisagreements":[{"label":"generation","column":1,"total":{"table":183,"row":31,"column":1,"label":"영업으로부터창출된현금","literal":"(1,738,775)"},"terms":[{"table":183,"row":1,"column":1,"label":"당기순손익","literal":"(247,983)","coefficient":1},{"table":183,"row":2,"column":1,"label":"조정:","literal":"969,524","coefficient":1},{"table":183,"row":20,"column":1,"label":"운전자본의변동","literal":"(2,460,315)","coefficient":1}],"omittedPrintedDashCells":[],"residual":-1,"unit":"천원","dashIsNumericFact":false},{"label":"adjustments","column":1,"total":{"table":183,"row":2,"column":1,"label":"조정:","literal":"969,524"},"terms":[{"table":183,"row":3,"column":1,"label":"감가상각비","literal":"279,319","coefficient":1},{"table":183,"row":4,"column":1,"label":"대손상각비","literal":"38,879","coefficient":1},{"table":183,"row":5,"column":1,"label":"무형자산상각비","literal":"25,260","coefficient":1},{"table":183,"row":6,"column":1,"label":"외화환산손실","literal":"15,071","coefficient":1},{"table":183,"row":7,"column":1,"label":"이자비용","literal":"219,657","coefficient":1},{"table":183,"row":8,"column":1,"label":"당기손익-공정가치측정금융자산평가손실","literal":"4,294","coefficient":1},{"table":183,"row":9,"column":1,"label":"당기손익-공정가치측정금융자산처분손실","literal":"33,013","coefficient":1},{"table":183,"row":10,"column":1,"label":"무형자산처분손실","literal":"200","coefficient":1},{"table":183,"row":11,"column":1,"label":"무형자산손상차손","literal":"469,371","coefficient":1},{"table":183,"row":12,"column":1,"label":"종속기업투자감액손실","literal":"500,000","coefficient":1},{"table":183,"row":13,"column":1,"label":"외화환산이익","literal":"(51,319)","coefficient":1},{"table":183,"row":14,"column":1,"label":"이자수익","literal":"(60,033)","coefficient":1},{"table":183,"row":15,"column":1,"label":"배당금수익","literal":"(452,620)","coefficient":1},{"table":183,"row":16,"column":1,"label":"당기손익-공정가치측정금융자산평가이익","literal":"(44,539)","coefficient":1},{"table":183,"row":17,"column":1,"label":"당기손익-공정가치측정금융자산처분이익","literal":"(6,943)","coefficient":1},{"table":183,"row":18,"column":1,"label":"무형자산처분이익","literal":"(86)","coefficient":1}],"omittedPrintedDashCells":[{"table":183,"row":19,"column":1,"label":"기타","literal":"-"}],"residual":0,"unit":"천원","dashIsNumericFact":false},{"label":"workingCapital","column":1,"total":{"table":183,"row":20,"column":1,"label":"운전자본의변동","literal":"(2,460,315)"},"terms":[{"table":183,"row":21,"column":1,"label":"매출채권의증감","literal":"(2,566,790)","coefficient":1},{"table":183,"row":22,"column":1,"label":"미수금의증감","literal":"43,248","coefficient":1},{"table":183,"row":23,"column":1,"label":"선급금의증감","literal":"(3,753)","coefficient":1},{"table":183,"row":24,"column":1,"label":"선급비용의증감","literal":"21,348","coefficient":1},{"table":183,"row":25,"column":1,"label":"매입채무의증감","literal":"29","coefficient":1},{"table":183,"row":26,"column":1,"label":"미지급금의증감","literal":"11,231","coefficient":1},{"table":183,"row":27,"column":1,"label":"예수금의증감","literal":"2,098","coefficient":1},{"table":183,"row":28,"column":1,"label":"선수금의증감","literal":"(715)","coefficient":1},{"table":183,"row":29,"column":1,"label":"미지급비용의증감","literal":"(2,212)","coefficient":1},{"table":183,"row":30,"column":1,"label":"선수수익의증감","literal":"35,200","coefficient":1}],"omittedPrintedDashCells":[],"residual":1,"unit":"천원","dashIsNumericFact":false},{"label":"generation","column":2,"total":{"table":183,"row":31,"column":2,"label":"영업으로부터창출된현금","literal":"780,210"},"terms":[{"table":183,"row":1,"column":2,"label":"당기순손익","literal":"1,727,119","coefficient":1},{"table":183,"row":2,"column":2,"label":"조정:","literal":"339,272","coefficient":1},{"table":183,"row":20,"column":2,"label":"운전자본의변동","literal":"(1,286,181)","coefficient":1}],"omittedPrintedDashCells":[],"residual":0,"unit":"천원","dashIsNumericFact":false},{"label":"adjustments","column":2,"total":{"table":183,"row":2,"column":2,"label":"조정:","literal":"339,272"},"terms":[{"table":183,"row":3,"column":2,"label":"감가상각비","literal":"492,679","coefficient":1},{"table":183,"row":4,"column":2,"label":"대손상각비","literal":"926,959","coefficient":1},{"table":183,"row":5,"column":2,"label":"무형자산상각비","literal":"80,972","coefficient":1},{"table":183,"row":7,"column":2,"label":"이자비용","literal":"70,086","coefficient":1},{"table":183,"row":8,"column":2,"label":"당기손익-공정가치측정금융자산평가손실","literal":"17,687","coefficient":1},{"table":183,"row":11,"column":2,"label":"무형자산손상차손","literal":"58,990","coefficient":1},{"table":183,"row":13,"column":2,"label":"외화환산이익","literal":"(244,487)","coefficient":1},{"table":183,"row":14,"column":2,"label":"이자수익","literal":"(220,792)","coefficient":1},{"table":183,"row":15,"column":2,"label":"배당금수익","literal":"(721,047)","coefficient":1},{"table":183,"row":16,"column":2,"label":"당기손익-공정가치측정금융자산평가이익","literal":"(81,039)","coefficient":1},{"table":183,"row":19,"column":2,"label":"기타","literal":"(40,735)","coefficient":1}],"omittedPrintedDashCells":[{"table":183,"row":6,"column":2,"label":"외화환산손실","literal":"-"},{"table":183,"row":9,"column":2,"label":"당기손익-공정가치측정금융자산처분손실","literal":"-"},{"table":183,"row":10,"column":2,"label":"무형자산처분손실","literal":"-"},{"table":183,"row":12,"column":2,"label":"종속기업투자감액손실","literal":"-"},{"table":183,"row":17,"column":2,"label":"당기손익-공정가치측정금융자산처분이익","literal":"-"},{"table":183,"row":18,"column":2,"label":"무형자산처분이익","literal":"-"}],"residual":-1,"unit":"천원","dashIsNumericFact":false},{"label":"workingCapital","column":2,"total":{"table":183,"row":20,"column":2,"label":"운전자본의변동","literal":"(1,286,181)"},"terms":[{"table":183,"row":21,"column":2,"label":"매출채권의증감","literal":"(1,375,292)","coefficient":1},{"table":183,"row":22,"column":2,"label":"미수금의증감","literal":"114,357","coefficient":1},{"table":183,"row":23,"column":2,"label":"선급금의증감","literal":"9,466","coefficient":1},{"table":183,"row":24,"column":2,"label":"선급비용의증감","literal":"(1,039)","coefficient":1},{"table":183,"row":25,"column":2,"label":"매입채무의증감","literal":"(17,977)","coefficient":1},{"table":183,"row":26,"column":2,"label":"미지급금의증감","literal":"(4,802)","coefficient":1},{"table":183,"row":27,"column":2,"label":"예수금의증감","literal":"992","coefficient":1},{"table":183,"row":28,"column":2,"label":"선수금의증감","literal":"715","coefficient":1},{"table":183,"row":29,"column":2,"label":"미지급비용의증감","literal":"(12,603)","coefficient":1}],"omittedPrintedDashCells":[{"table":183,"row":30,"column":2,"label":"선수수익의증감","literal":"-"}],"residual":2,"unit":"천원","dashIsNumericFact":false}],"ownNoteCrossPrecisionResiduals":[{"label":"currentNI_mainWon_minusNoteThousand","main":{"table":4,"row":12,"column":3,"label":"Ⅵ.당기순이익(손실)","literal":"(247,983,169)","value":-247983169,"key":"netIncome","kind":"CIS"},"note":{"table":183,"row":1,"column":1,"label":"당기순손익","literal":"(247,983)"},"notePrintedUnit":"천원","noteUnitMultiplier":1000,"residual":-169},{"label":"currentGeneratedCash_mainWon_minusNoteThousand","main":{"table":10,"row":2,"column":2,"label":"영업으로부터창출된현금흐름","literal":"(1,738,775,092)"},"note":{"table":183,"row":31,"column":1,"label":"영업으로부터창출된현금","literal":"(1,738,775)"},"notePrintedUnit":"천원","noteUnitMultiplier":1000,"residual":-92}],"coreCells":[{"table":1,"row":15,"column":2,"label":"자산총계","literal":"24,269,242,057","value":24269242057,"key":"assets","kind":"BS"},{"table":1,"row":26,"column":2,"label":"부채총계","literal":"9,899,013,382","value":9899013382,"key":"liabilities","kind":"BS"},{"table":1,"row":33,"column":2,"label":"자본총계","literal":"14,370,228,675","value":14370228675,"key":"equity","kind":"BS"},{"table":4,"row":1,"column":3,"label":"Ⅰ.매출액","literal":"4,006,707,694","value":4006707694,"key":"revenue","kind":"CIS"},{"table":4,"row":5,"column":3,"label":"Ⅳ.영업이익(손실)","literal":"451,405,935","value":451405935,"key":"operatingIncome","kind":"CIS"},{"table":4,"row":12,"column":3,"label":"Ⅵ.당기순이익(손실)","literal":"(247,983,169)","value":-247983169,"key":"netIncome","kind":"CIS"},{"table":10,"row":1,"column":2,"label":"Ⅰ.영업활동으로인한현금흐름","literal":"(1,357,231,951)","value":-1357231951,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20230314001218","corp":"00135917","name":"한화손해보험(주)","year":2022,"basis":"consolidated","sourceReceipt":"20230314001218","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20230314001218-cfs-located-own-seven","digest":"a04db728ed2220f5a1cedf0caafcddddfec9b6f4140cd4296a200bbfab4e8a4f","sourceDigest":"e21591575738c367c919b289af5f9f2015d3705f466ae9bc16df63bb2086d72b","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314001218&dcmNo=9055696&eleId=17&offset=346860&length=105943&dtd=dart3.xsd","statementSHA":"350718db3e280e3db1013d4546871bec463a435c4e27d108c48384d40ca15453","periodStart":"2022-01-01","periodEnd":"2022-12-31","coverPeriodTokens":["2022년01월01일","2022년12월31일"],"coreCells":[{"table":1,"row":24,"column":3,"label":"자산총계","literal":"20,382,687,831,487","value":20382687831487,"key":"assets","kind":"BS"},{"table":1,"row":40,"column":3,"label":"부채총계","literal":"20,115,322,903,774","value":20115322903774,"key":"liabilities","kind":"BS"},{"table":1,"row":49,"column":3,"label":"자본총계","literal":"267,364,927,713","value":267364927713,"key":"equity","kind":"BS"},{"table":4,"row":1,"column":3,"label":"I.영업수익","literal":"8,473,762,873,234","value":8473762873234,"key":"revenue","kind":"CIS"},{"table":4,"row":36,"column":3,"label":"III.영업이익","literal":"245,686,345,885","value":245686345885,"key":"operatingIncome","kind":"CIS"},{"table":4,"row":41,"column":3,"label":"VIII.당기순이익","literal":"219,230,965,661","value":219230965661,"key":"netIncome","kind":"CIS"},{"table":10,"row":1,"column":3,"label":"I.영업활동으로인한현금흐름","literal":"1,462,166,183","value":1462166183,"key":"operatingCashFlow","kind":"CF"}],"combinedPPEAcquisition":{"table":10,"row":23,"column":2,"label":"투자부동산및유형자산의취득","literal":"(16,974,349,776)","purePPE":false},"ceMissingCurrentTotalCells":[{"table":7,"row":22,"column":9,"label":"재평가한토지의처분","literal":"-"}]}]''',
  ) as List;

  static List get profiles => jsonDecode(jsonEncode(_profiles)) as List;

  static String _start(Map p) =>
      p['periodStart'] as String? ?? '${p['year']}-01-01';
  static String _end(Map p) =>
      p['periodEnd'] as String? ?? '${p['year']}-12-31';

  static Map? _profile(String receipt, FsDiv basis) {
    final found = _profiles
        .where((p) => p['receipt'] == receipt && p['basis'] == basis.name)
        .toList();
    return found.length == 1 ? found.single as Map : null;
  }

  static bool sourceEligible({
    required String receipt,
    required String corp,
    required FsDiv basis,
    required DateTime start,
    required DateTime end,
    required String sourceReceipt,
  }) {
    final p = _profile(receipt, basis);
    return p != null &&
        p['corp'] == corp &&
        p['sourceReceipt'] == sourceReceipt &&
        start == DateTime.parse('${_start(p)}T00:00:00Z') &&
        end == DateTime.parse('${_end(p)}T00:00:00Z');
  }

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
              p['sourceReceipt'] == receipt &&
              p['corp'] == corp &&
              p['name'] == companyName &&
              p['basis'] == (consolidated ? 'consolidated' : 'separate'),
        )
        .toList();
    if (matches.length != 1) return null;
    final p = matches.single as Map;
    final partial = p['rule'] == partialRule;
    final count = partial ? 7 : 8;
    if (rows.length != count ||
        source?.toString() != p['statementURI'] ||
        digest != p['sourceDigest']) {
      return null;
    }
    for (final r in rows) {
      final v = r['html_provenance'];
      if (p['receipt'] == '20230314001218' &&
          (v is! Map ||
              v['fullyNumericMainEquationCount'] != 10 ||
              v['ceRollFullyNumericVerified'] != false ||
              jsonEncode(v['combinedPPEAcquisition']) !=
                  jsonEncode(p['combinedPPEAcquisition']) ||
              jsonEncode(v['ceMissingCurrentTotalCells']) !=
                  jsonEncode(p['ceMissingCurrentTotalCells']))) {
        return null;
      }

      if (v is! Map ||
          v['ruleVersion'] != p['rule'] ||
          v['sourceReceipt'] != receipt ||
          v['targetReceipt'] != p['receipt'] ||
          v['sourceSha256'] != p['statementSHA'] ||
          v['currentCore8'] != !partial ||
          (p['requiresBoundedUnverifiedNotes'] == true &&
              !_unverifiedNoteProof(v, p)) ||
          (p['rule'] == printedLossRule &&
              (v['sourceCellRewritten'] != false ||
                  v['printedLossSourceOwnOnly'] != true ||
                  jsonEncode(v['ownIssuerFilingSeriesEvidence']) !=
                      jsonEncode(p['ownIssuerFilingSeriesEvidence']))) ||
          (partial &&
              (v['partialCore7'] != true ||
                  v['coreAccountsProvided'] != 7 ||
                  jsonEncode(v['missingRequiredAccounts']) != '["capex"]' ||
                  v['missingAccountReasons'] is! Map ||
                  (v['missingAccountReasons'] as Map)['capex'] !=
                      capexMissingReason ||
                  v['syntheticCapex'] != false)) ||
          v['unit'] != '원' ||
          v['periodStart'] != _start(p) ||
          v['periodEnd'] != _end(p) ||
          v['fullStatementVerified'] != false ||
          v['detailEnrichmentApproved'] != false ||
          r['rcept_no'] != receipt ||
          r['corp_code'] != corp) {
        return null;
      }
    }
    if ({'20230314000692', '20230314000604'}.contains(p['receipt'])) {
      for (var i = 0; i < count; i++) {
        final r = rows[i], c = (p['coreCells'] as List)[i] as Map;
        final v = r['html_provenance'] as Map;
        if (p['receipt'] == '20230314000604' &&
            (v['ceRollFullyNumericVerified'] != false ||
                jsonEncode(v['ceMissingCurrentTotalCells']) !=
                    jsonEncode(p['ceMissingCurrentTotalCells']))) {
          return null;
        }
        if (r['account_nm'] != c['label'] ||
            r['account_id'] != null ||
            r['sj_div'] != c['kind'] ||
            r['currency'] != 'KRW' ||
            r['thstrm_amount'] != (c['value'] as int).toString() ||
            v['printedAmount'] != c['literal'] ||
            v['tableIndex'] != c['table'] ||
            v['rowIndex'] != c['row'] ||
            v['currentColumn'] != c['column'] ||
            v['supportingNoteSha256'] != p['noteSHA'] ||
            jsonEncode(v['crossPrecisionLiteralRemainders']) !=
                jsonEncode(p['crossPrecisionLiteralRemainders']) ||
            v['notesVerified'] != false ||
            v['roundingCauseInferred'] != false ||
            v['crossPrecisionEqualityClaim'] != false ||
            v['fullStatementCollected'] != false) {
          return null;
        }
      }
    }
    if (p['rule'] == printedLossRule) {
      for (var i = 0; i < 8; i++) {
        final c = (p['coreCells'] as List)[i] as Map;
        final r = rows[i], v = r['html_provenance'] as Map;
        final signed =
            (c['signNormalization'] ==
                    'explicitPrintedLossMagnitudeCorroborated'
                ? '-'
                : '') +
            (c['literal'] as String)
                .replaceAll(',', '')
                .replaceAll('(', '-')
                .replaceAll(')', '');
        if (r['account_nm'] != c['label'] ||
            r['account_id'] != null ||
            r['currency'] != 'KRW' ||
            r['thstrm_amount'] != signed ||
            v['printedAmount'] != c['literal'] ||
            v['printedLabel'] != c['label'] ||
            v['tableIndex'] != c['table'] ||
            v['rowIndex'] != c['row'] ||
            v['currentColumn'] != c['column'] ||
            v['signNormalization'] != c['signNormalization'] ||
            v['derivedSignedAmount'] != signed ||
            v['sourceMainEquationCount'] != 18 ||
            v['printedFxDashIsNumericZero'] != false) {
          return null;
        }
      }
    }
    return {
      'action': 'verified-keyless-annual-source-after-api-noData',
      'targetReceipt': p['receipt'],
      'sourceReceipt': receipt,
      'corpCode': corp,
      'fsDiv': consolidated ? 'consolidated' : 'separate',
      'coreRows': count,
      if (partial) ...{
        'partialCore7': true,
        'currentCore8': false,
        'coreAccountsProvided': 7,
        'missingRequiredAccounts': ['capex'],
        'missingAccountReasons': {'capex': capexMissingReason},
        'optionalAccountsNotCollected': ['capex'],
        'fullStatementCollected': false,
        'notesVerified': false,
        'detailHierarchyVerified': false,
      },
      if (p['rule'] == printedLossRule) ...{
        'ownIssuerFilingSeriesEvidence': p['ownIssuerFilingSeriesEvidence'],
        'fullStatementCollected': false,
        'notesVerified': false,
        'detailHierarchyVerified': false,
        'printedLossSourceOwnOnly': true,
      },
      'coreRowProvenance': rows,
    };
  }

  /// Only these compiled own-Source partial profiles identify missing whole PPE.
  static bool recordedPartialScope(
    Source source,
    FinancialReport report,
    String corp,
  ) {
    final p = _profile(report.rceptNo, report.fsDiv);
    if (p == null ||
        p['rule'] != partialRule ||
        p['corp'] != corp ||
        report.bsnsYear != p['year'] ||
        report.reportCode != FinancialReportCode.annual ||
        source.kind != SourceKind.dartReport ||
        source.url != p['statementURI'] ||
        source.reference !=
            'financial-api-noData-source:${report.rceptNo}:${report.fsDiv.name}') {
      return false;
    }
    try {
      final v = jsonDecode(source.title);
      if (v is! Map ||
          v['action'] != 'verified-keyless-annual-source-after-api-noData' ||
          v['sourceReceipt'] != p['sourceReceipt'] ||
          v['targetReceipt'] != p['receipt'] ||
          v['corpCode'] != corp ||
          v['fsDiv'] != report.fsDiv.name ||
          v['reportName'] != report.reportName ||
          v['format'] != 'html' ||
          v['sha256'] != p['sourceDigest'] ||
          v['coreRows'] != 7) {
        return false;
      }
      final rows = v['coreRowProvenance'];
      if (rows is! List || rows.length != 7) return false;
      for (var i = 0; i < 7; i++) {
        final r = rows[i], c = (p['coreCells'] as List)[i];
        if (r is! Map ||
            r['html_provenance'] is! Map ||
            r['account_nm'] != c['label'] ||
            r['account_id'] != null ||
            r['currency'] != 'KRW' ||
            r['thstrm_amount'] !=
                (c['literal'] as String)
                    .replaceAll(',', '')
                    .replaceAll('(', '-')
                    .replaceAll(')', '')) {
          return false;
        }
        final proof = r['html_provenance'] as Map;
        if (p['receipt'] == '20230314001218' &&
            (proof['fullyNumericMainEquationCount'] != 10 ||
                proof['ceRollFullyNumericVerified'] != false ||
                jsonEncode(proof['combinedPPEAcquisition']) !=
                    jsonEncode(p['combinedPPEAcquisition']) ||
                jsonEncode(proof['ceMissingCurrentTotalCells']) !=
                    jsonEncode(p['ceMissingCurrentTotalCells']))) {
          return false;
        }

        if (proof['ruleVersion'] != partialRule ||
            proof['sourceReceipt'] != p['sourceReceipt'] ||
            proof['targetReceipt'] != p['receipt'] ||
            proof['sourceSha256'] != p['statementSHA'] ||
            proof['source'] != p['statementURI'] ||
            proof['tableIndex'] != c['table'] ||
            proof['rowIndex'] != c['row'] ||
            proof['currentColumn'] != c['column'] ||
            proof['printedAmount'] != c['literal'] ||
            proof['printedLabel'] != c['label'] ||
            proof['unit'] != '원' ||
            proof['unitMultiplier'] != '1' ||
            proof['periodStart'] != _start(p) ||
            proof['periodEnd'] != _end(p) ||
            proof['basis'] !=
                (report.fsDiv == FsDiv.consolidated ? 'CFS' : 'OFS') ||
            proof['partialCore7'] != true ||
            proof['currentCore8'] != false ||
            (p['requiresBoundedUnverifiedNotes'] == true &&
                !_unverifiedNoteProof(proof, p)) ||
            proof['fullStatementVerified'] != false ||
            proof['notesVerified'] != false ||
            proof['detailEnrichmentApproved'] != false ||
            proof['syntheticCapex'] != false ||
            proof['missingAccountReasons'] is! Map ||
            (proof['missingAccountReasons'] as Map)['capex'] !=
                capexMissingReason) {
          return false;
        }
      }
      return true;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
  }

  static bool _unverifiedNoteProof(Map v, Map p) =>
      v['supportingUnverifiedNoteSource'] == p['noteURI'] &&
      v['supportingUnverifiedNoteSha256'] == p['noteSHA'] &&
      v['independentCFNetIncomePrinted'] == false &&
      v['independentCFNetIncomeExact'] == false &&
      v['mainNetIncomePLCEExact'] == true &&
      v['unresolvedOwnNoteDetailConflict'] == true &&
      v['notesVerified'] == false &&
      jsonEncode(v['ownNoteDisagreements']) ==
          jsonEncode(p['ownNoteDisagreements']) &&
      jsonEncode(v['ownNoteCrossPrecisionResiduals']) ==
          jsonEncode(p['ownNoteCrossPrecisionResiduals']);

  static String compact(String x) => x
      .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), '');
  static List<List<List<String>>> tables(String raw) => [
    for (final t in RegExp(
      r'<table\b[^>]*>(.*?)</table>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(raw))
      [
        for (final r in RegExp(
          r'<tr\b[^>]*>(.*?)</tr>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(t[1]!))
          [
            for (final c in RegExp(
              r'<t[dh]\b[^>]*>(.*?)</t[dh]>',
              caseSensitive: false,
              dotAll: true,
            ).allMatches(r[1]!))
              compact(c[1]!),
          ],
      ],
  ];
  static Future<
    ({
      PublicFinancialHtmlSource? numeric,
      PublicFinancialHtmlBasisNotApplicable? absence,
    })
  >
  verify({
    required AnnualSourceCacheEntry entry,
    required Company company,
    required DartFiling filing,
    required List<int> rawManifest,
    required Future<List<int>> Function(String) read,
  }) async {
    void guard(bool ok, String why) {
      if (!ok) throw FormatException('Located own source: $why');
    }

    final p = _profile(entry.receipt, entry.basis);
    guard(p != null, 'unknown finite source');
    final profile = p!;
    final y = profile['year'] as int;
    guard(
      entry.ruleVersion == profile['rule'] &&
          entry.absenceLiteral == profile['absenceLiteral'] &&
          entry.manifestDigest == profile['digest'] &&
          sha256.convert(rawManifest).toString() == profile['digest'] &&
          company.name == profile['name'] &&
          company.corpCode == profile['corp'] &&
          filing.corpCode == profile['corp'] &&
          filing.companyId == company.id &&
          filing.rceptNo == profile['receipt'] &&
          filing.bsnsYear == y &&
          entry.year == y &&
          entry.periodStart == DateTime.parse('${_start(profile)}T00:00:00Z') &&
          entry.periodEnd == DateTime.parse('${_end(profile)}T00:00:00Z'),
      'issuer/period/immutable manifest mismatch',
    );
    final m = jsonDecode(utf8.decode(rawManifest)) as Map;
    guard(
      m['receipt'] == entry.receipt &&
          m['corpCode'] == company.corpCode &&
          m['companyName'] == company.name &&
          m['basis'] == entry.basis.name &&
          m['year'] == y &&
          m['kind'] == 'annual' &&
          m['ruleVersion'] == profile['rule'] &&
          m['sourceReceipt'] == profile['sourceReceipt'] &&
          m['periodStart'] == _start(profile) &&
          m['periodEnd'] == _end(profile),
      'declared identity mismatch',
    );
    final sourceReceipt = m['sourceReceipt'] as String;
    final statement = entry.statementLabel;
    final requiredLabels = {
      'shell',
      'cover',
      statement,
      if (profile['requiresOwnNotes'] == true ||
          profile['requiresBoundedUnverifiedNotes'] == true)
        'notes',
      if (sourceReceipt != entry.receipt) 'originalShell',
    };
    final raw = <String, String>{}, uris = <String, Uri>{};
    final sha = <String, String>{};
    for (final d in m['sources'] as List) {
      final label = d['label'] as String;
      guard(
        requiredLabels.contains(label) &&
            !raw.containsKey(label) &&
            d['file'] == '$label.html',
        'unknown/duplicate filename',
      );
      final bytes = await read('${entry.assetDirectory}/$label.html');
      guard(
        sha256.convert(bytes).toString() == d['sha256'],
        'original raw SHA changed',
      );
      final u = Uri.parse(d['url'] as String);
      guard(
        u.scheme == 'https' &&
            u.host == 'dart.fss.or.kr' &&
            !u.hasPort &&
            u.queryParametersAll.values.every((v) => v.length == 1) &&
            !uris.values.contains(u),
        'official distinct URI mismatch',
      );
      raw[label] = utf8.decode(bytes);
      uris[label] = u;
      sha[label] = d['sha256'] as String;
    }
    guard(raw.length == requiredLabels.length, 'own package incomplete');
    guard(
      uris['shell'].toString() ==
          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${entry.receipt}',
      'target shell mismatch',
    );
    final ownLabel = sourceReceipt == entry.receipt ? 'shell' : 'originalShell';
    guard(
      uris[ownLabel].toString() ==
          'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$sourceReceipt',
      'own shell mismatch',
    );
    for (final label in {'shell', ownLabel}) {
      final ids = RegExp(r'''openCorpInfoNew\(\s*['\"]([0-9]{8})['\"]\s*,''')
          .allMatches(raw[label]!)
          .map((v) => v[1])
          .toSet();
      guard(
        ids.length == 1 && ids.single == company.corpCode,
        'exact own corporate identity missing',
      );
    }
    if (sourceReceipt != entry.receipt) {
      final family = RegExp(
        r'<select[^>]*id=["\x27]family["\x27][^>]*>(.*?)</select>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(raw['shell']!).toList();
      guard(family.length == 1, 'target family ambiguous');
      final options =
          RegExp(
                r'<option\b([^>]*)>(.*?)</option>',
                caseSensitive: false,
                dotAll: true,
              )
              .allMatches(family.single[1]!)
              .where(
                (v) =>
                    RegExp('value=["\x27]rcpNo=$sourceReceipt["\x27]')
                        .hasMatch(v[1]!) &&
                    compact(v[2]!).contains('사업보고서'),
              )
              .toList();
      guard(options.length == 1, 'original own annual family unlinked');
    }
    for (final label in [
      'cover',
      statement,
      if (profile['requiresOwnNotes'] == true ||
          profile['requiresBoundedUnverifiedNotes'] == true)
        'notes',
    ]) {
      final u = uris[label]!;
      guard(
        u.path == '/report/viewer.do' &&
            u.queryParameters['rcpNo'] == sourceReceipt,
        'viewer source receipt mismatch',
      );
      final nodes =
          RegExp(
            r'''(node[12])\['text'\]\s*=\s*\"([^\"]+)\";(.*?)(?=node[12]\['text'\]|$)''',
            dotAll: true,
          ).allMatches(raw[ownLabel]!).where((node) {
            final a = <String, String>{
              for (final x in RegExp(
                r'''node[12]\['(rcpNo|dcmNo|eleId|offset|length|dtd)'\]\s*=\s*\"([^\"]+)\"''',
              ).allMatches(node[3]!))
                x[1]!: x[2]!,
            };
            return a.length == 6 &&
                a.entries.every((v) => u.queryParameters[v.key] == v.value);
          }).toList();
      guard(nodes.length == 1, 'own physical viewer node missing/ambiguous');
    }
    final cover = compact(raw['cover']!);
    guard(
      profile['coverPeriodTokens'] is List
          ? (profile['coverPeriodTokens'] as List).every(
              (token) => cover.contains(token as String),
            )
          : profile['receipt'] == '20220318000774' &&
                sourceReceipt == '20220310001176' &&
                y == 2021
          ? cover.contains('2021.01.01') && cover.contains('2021.12.31')
          : cover.contains('$y년01월01일') && cover.contains('$y년12월31일'),
      'own printed cover period mismatch',
    );
    guard(
      cover.contains('회사명:${m['ownCoverActor']}'),
      'own printed legal actor mismatch',
    );
    if (entry.ruleVersion == absenceRule) {
      guard(
        entry.basis == FsDiv.consolidated &&
            m['absenceLiteral'] == entry.absenceLiteral &&
            cover.contains('회사명:${m['ownCoverActor']}') &&
            compact(raw[statement]!) == compact(m['absenceLiteral'] as String),
        'own explicit CFS non-presentation actor/literal mismatch',
      );
      return (
        numeric: null,
        absence: _LocatedOwnBasisAbsence(
          identityEvidence: {
            'kind': 'exact-own-shell-cover-actor-period-only',
            'policy': 'exact-own-filing-series-cfs-none-v1',
            'identityScope': 'official-DART-filing-series-only',
            'ownCoverActor': m['ownCoverActor'] as String,
            'ownShellCorpProof': company.corpCode,
            'jurirContinuityVerified': 'false',
            'operatingHistoryContinuityVerified': 'false',
            'sourceNotice':
                '현재 표기 ${company.name}와 자체 공시 표지 ${m['ownCoverActor']}를 같은 공식 DART 기업고유번호의 이 공시 구간에 한해 연결했습니다. 법인번호·사업 연속성을 검증한 회사명 별칭이 아니며 재무 숫자를 수집하지 않았습니다.',
            'receipt': sourceReceipt,
            'targetReceipt': entry.receipt,
            'corpCode': company.corpCode,
            'currentName': company.name,
            'printedName': m['ownCoverActor'] as String,
            'coverSource': uris['cover'].toString(),
            'coverSha256': sha['cover']!,
            'ownShellSource': uris[ownLabel].toString(),
            'ownShellSha256': sha[ownLabel]!,
          },
          sourceReceipt: sourceReceipt,
          corpCode: company.corpCode,
          companyName: company.name,
          reportName: filing.reportName,
          periodStart: entry.periodStart,
          periodEnd: entry.periodEnd,
          coverSource: uris['cover']!,
          statementSource: uris[statement]!,
          coverHtml: raw['cover']!,
          statementHtml: raw[statement]!,
          evidence: entry.absenceLiteral!,
        ),
      );
    }
    final grid = tables(raw[statement]!);
    guard(
      jsonEncode(grid) == jsonEncode(m['tables']),
      'exact physical table grid changed',
    );
    String literal(Map c) =>
        grid[c['table'] as int][c['row'] as int][c['column'] as int];
    BigInt? money(String x) {
      if (x == '' || x == '-') return null;
      guard(
        RegExp(r'^-?(?:\d+|\d{1,3}(?:,\d{3})+)$')
            .hasMatch(x.replaceAll('(', '-').replaceAll(')', '')),
        'malformed monetary grouping',
      );
      return BigInt.parse(
        x.replaceAll(',', '').replaceAll('(', '-').replaceAll(')', ''),
      );
    }

    BigInt residual(Map e) =>
        money(literal(e['total'] as Map))! -
        (e['terms'] as List).fold(
          BigInt.zero,
          (sum, t) =>
              sum +
              (money(literal(t as Map)) ?? BigInt.zero) *
                  BigInt.from(t['coefficient'] as int),
        );
    for (final e in m['checks'] as List) {
      guard(
        e['residual'] == 0 && residual(e as Map) == BigInt.zero,
        'current main equation failed',
      );
    }
    if (profile['requiresOwnNotes'] == true) {
      final noteGrid = tables(raw['notes']!);
      final boundedTables = m['supportingNoteTables'] as Map;
      for (final table in boundedTables.entries) {
        guard(
          jsonEncode(noteGrid[int.parse(table.key as String)]) ==
              jsonEncode(table.value),
          'own bounded note physical table changed',
        );
      }
      BigInt? noteMoney(Map c) => money(
        noteGrid[c['table'] as int][c['row'] as int][c['column'] as int],
      );
      for (final e in m['supportingNoteChecks'] as List) {
        guard(
          e['residual'] == 0 &&
              noteMoney(e['total'] as Map)! ==
                  (e['terms'] as List).fold<BigInt>(
                    BigInt.zero,
                    (sum, term) =>
                        sum +
                        (noteMoney(term as Map) ?? BigInt.zero) *
                            BigInt.from(term['coefficient'] as int),
                  ),
          'own bounded note equation failed',
        );
      }
      if ({'20230314000692', '20230314000604'}.contains(entry.receipt)) {
        guard(
          sha['notes'] == profile['noteSHA'] &&
              (entry.receipt == '20230314000692'
                      ? noteGrid[155][0].single
                      : noteGrid[67][0].single) ==
                  '(단위:천원)' &&
              jsonEncode(m['crossPrecisionLiteralRemainders']) ==
                  jsonEncode(profile['crossPrecisionLiteralRemainders']) &&
              m['notesVerified'] == false &&
              m['fullStatementCollected'] == false &&
              m['detailHierarchyVerified'] == false &&
              (m['checks'] as List).length ==
                  (profile['mainFullyNumericCheckCount'] ?? 8) &&
              (m['checks'] as List).every(
                (e) =>
                    e['fullyNumeric'] == true &&
                    (e['missingTerms'] as List).isEmpty &&
                    (e['terms'] as List).every(
                      (t) => money(literal(t as Map)) != null,
                    ),
              ),
          'own Kyobo bounded precision/read scope changed',
        );
        if (entry.receipt == '20230314000604') {
          guard(
            m['ceRollFullyNumericVerified'] == false &&
                jsonEncode(m['ceMissingCurrentTotalCells']) ==
                    jsonEncode(profile['ceMissingCurrentTotalCells']),
            'own CE dash scope changed',
          );
          for (final c in profile['ceMissingCurrentTotalCells'] as List) {
            guard(
              grid[c['table'] as int][c['row'] as int][c['column'] as int] ==
                  '-',
              'printed CE dash changed',
            );
          }
        }
        for (var i = 0; i < 4; i++) {
          final a = (profile['mainPrecisionCells'] as List)[i] as List;
          final b = (profile['notePrecisionCells'] as List)[i] as List;
          guard(
            money(grid[a[0] as int][a[1] as int][a[2] as int])! -
                    money(noteGrid[b[0] as int][b[1] as int][b[2] as int])! *
                        BigInt.from(1000) ==
                BigInt.from(
                  (profile['crossPrecisionLiteralRemainders'] as List)[i]
                      as int,
                ),
            'own literal cross-precision remainder changed',
          );
        }
      } else if (entry.receipt == '20220615000399') {
        guard(
          noteGrid[45].single[1] == '(단위:천원)',
          'own cash note unit changed',
        );
        final expected = <int>[127, -53, -129, 163];
        final mainCells = <List<int>>[
          [1, 2, 1],
          [7, 43, 2],
          [1, 2, 2],
          [7, 42, 2],
        ];
        final noteCells = <List<int>>[
          [46, 7, 1],
          [245, 2, 1],
          [46, 7, 2],
          [245, 2, 2],
        ];
        for (var i = 0; i < expected.length; i++) {
          final main = mainCells[i], note = noteCells[i];
          guard(
            money(grid[main[0]][main[1]][main[2]])! -
                    money(noteGrid[note[0]][note[1]][note[2]])! *
                        BigInt.from(1000) ==
                BigInt.from(expected[i]),
            'own cross-precision literal disagreement changed',
          );
        }
      } else {
        guard(
          entry.receipt == '20250320000572' &&
              noteGrid[154].single.single == '(단위:원)' &&
              money(noteGrid[155][1][1]) == money(grid[3][12][2]) &&
              money(noteGrid[155][29][1]) == money(grid[7][2][2]),
          'own note32 NI/generated cash scope changed',
        );
      }
    }
    if (profile['requiresBoundedUnverifiedNotes'] == true) {
      guard(
        entry.receipt == '20260323001293' &&
            sourceReceipt == entry.receipt &&
            company.corpCode == '00541862' &&
            entry.basis == FsDiv.separate &&
            y == 2025 &&
            m['notesVerified'] == false &&
            m['independentCFNetIncomePrinted'] == false &&
            m['independentCFNetIncomeExact'] == false &&
            m['mainNetIncomePLCEExact'] == true &&
            m['unresolvedOwnNoteDetailConflict'] == true,
        'finite unresolved own-note partial7 scope mismatch',
      );
      final ng = tables(raw['notes']!);
      final bounded = m['boundedUnverifiedOwnNoteTables'] as Map;
      for (final e in bounded.entries) {
        guard(
          jsonEncode(ng[int.parse(e.key as String)]) == jsonEncode(e.value),
          'unverified own note grid changed',
        );
      }
      guard(
        uris['notes'].toString() == profile['noteURI'] &&
            sha['notes'] == profile['noteSHA'] &&
            ng[182][0][1] == '(단위:천원)' &&
            jsonEncode(m['ownNoteDisagreements']) ==
                jsonEncode(profile['ownNoteDisagreements']) &&
            jsonEncode(m['ownNoteCrossPrecisionResiduals']) ==
                jsonEncode(profile['ownNoteCrossPrecisionResiduals']),
        'finite printed note disagreement proof changed',
      );
      String nl(Map c) =>
          ng[c['table'] as int][c['row'] as int][c['column'] as int];
      for (final e in m['ownNoteDisagreements'] as List) {
        final residual =
            money(nl(e['total'] as Map))! -
            (e['terms'] as List).fold<BigInt>(
              BigInt.zero,
              (sum, c) =>
                  sum +
                  money(nl(c as Map))! * BigInt.from(c['coefficient'] as int),
            );
        guard(
          residual == BigInt.from(e['residual'] as int),
          'printed unresolved note residual changed',
        );
      }
      for (final e in m['ownNoteCrossPrecisionResiduals'] as List) {
        guard(
          money(literal(e['main'] as Map))! -
                  money(nl(e['note'] as Map))! *
                      BigInt.from(e['noteUnitMultiplier'] as int) ==
              BigInt.from(e['residual'] as int),
          'separate printed precisions changed',
        );
      }
    }
    if (entry.receipt == '20230314001218') {
      guard(
        entry.basis == FsDiv.consolidated &&
            company.corpCode == '00135917' &&
            [
              '사업보고서 (2022.12)',
              '[기재정정]사업보고서 (2022.12)',
            ].contains(filing.reportName) &&
            jsonEncode(m['core']) == jsonEncode(profile['coreCells']) &&
            (m['checks'] as List).length == 10 &&
            (m['checks'] as List).every(
              (e) =>
                  e['fullyNumeric'] == true &&
                  (e['missingTerms'] as List).isEmpty &&
                  money(literal(e['total'] as Map)) != null &&
                  (e['terms'] as List).every(
                    (t) => money(literal(t as Map)) != null,
                  ),
            ) &&
            m['ceRollFullyNumericVerified'] == false &&
            jsonEncode(m['ceMissingCurrentTotalCells']) ==
                jsonEncode(profile['ceMissingCurrentTotalCells']) &&
            jsonEncode(m['combinedPPEAcquisition']) ==
                jsonEncode(profile['combinedPPEAcquisition']) &&
            grid[10][23][0] == '투자부동산및유형자산의취득' &&
            grid[10][23][2] == '(16,974,349,776)' &&
            grid[7][22][9] == '-' &&
            [0, 3, 6, 9].every(
              (t) =>
                  grid[t][3][0] == '한화손해보험주식회사와그종속기업' &&
                  grid[t][3][1] == '(단위:원)',
            ) &&
            jsonEncode(m['ownCurrentPeriodProof']['statementHeaders']) ==
                jsonEncode({
                  for (final t in [0, 3, 6, 9]) '$t': grid[t],
                }),
        'finite insurance combined PPE/current seven proof changed',
      );
    }
    final anomalies = m['sourceDetailAnomalies'] as List;
    for (final e in anomalies) {
      guard(
        residual(e as Map) == BigInt.from(e['residual'] as int),
        'literal detail disagreement changed',
      );
    }
    final lossProfile = profile['rule'] == printedLossRule;
    if (lossProfile) {
      guard(
        entry.receipt == '20250407004339' &&
            sourceReceipt == '20250407004208' &&
            company.corpCode == '01118643' &&
            entry.basis == FsDiv.separate &&
            y == 2024 &&
            m['ownCoverActor'] == profile['ownCoverActor'] &&
            jsonEncode(m['ownIssuerFilingSeriesEvidence']) ==
                jsonEncode(profile['ownIssuerFilingSeriesEvidence']) &&
            jsonEncode(m['core']) == jsonEncode(profile['coreCells']),
        'finite own printed-loss actor/core proof mismatch',
      );
      guard(
        grid[1][5][3] == '773,018,50' &&
            m['fullStatementCollected'] == false &&
            m['notesVerified'] == false &&
            m['detailEnrichmentApproved'] == false &&
            m['detailHierarchyVerified'] == false,
        'unverified comparative detail changed',
      );
    }
    final partial = profile['rule'] == partialRule;
    final count = partial ? 7 : 8;
    if (partial) {
      guard(
        m['partialCore7'] == true &&
            m['currentCore8'] == false &&
            m['coreAccountsProvided'] == 7 &&
            jsonEncode(m['missingRequiredAccounts']) == '["capex"]' &&
            (m['missingAccountReasons'] as Map)['capex'] ==
                capexMissingReason &&
            m['syntheticCapex'] == false &&
            m['capexNotPrinted'] == true &&
            m['ownCurrentPeriodProof'] is Map &&
            (m['ownCurrentPeriodProof'] as Map)['genericDateSubstitution'] ==
                false,
        'finite partial current7 scope changed',
      );
    }
    final cores = m['core'] as List;
    guard(
      cores.length == count &&
          cores.map((v) => v['key']).toSet().length == count &&
          (!partial ||
              jsonEncode(cores.map((v) => v['key']).toList()) ==
                  '["assets","liabilities","equity","revenue","operatingIncome","netIncome","operatingCashFlow"]'),
      'finite current core scope mismatch',
    );
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < cores.length; i++) {
      final c = cores[i] as Map;
      final printedAmount = money(literal(c));
      final loss =
          lossProfile &&
          (profile['lossMagnitudeKeys'] as List).contains(c['key']);
      guard(
        !loss ||
            (printedAmount != null &&
                printedAmount > BigInt.zero &&
                c['signNormalization'] ==
                    'explicitPrintedLossMagnitudeCorroborated' &&
                ((c['key'] == 'operatingIncome' && c['label'] == 'IV.영업손실') ||
                    (c['key'] == 'netIncome' && c['label'] == 'VII.당기순손실'))),
        'exact printed-loss scope changed',
      );
      final amount = loss ? -printedAmount! : printedAmount;
      guard(
        amount != null &&
            grid[c['table'] as int][c['row'] as int][0] == c['label'],
        'current printed core cell missing',
      );
      result.add({
        'rcept_no': sourceReceipt,
        'corp_code': company.corpCode,
        'bsns_year': '$y',
        'reprt_code': '11011',
        'fs_div': entry.basis == FsDiv.consolidated ? 'CFS' : 'OFS',
        'sj_div': c['kind'],
        'account_id': null,
        'account_nm': c['label'],
        'ord':
            '${grid.take(c['table'] as int).fold<int>(0, (n, table) => n + table.length) + (c['row'] as int) + 1}',
        'thstrm_nm': '당기',
        'thstrm_dt': c['kind'] == 'BS'
            ? _end(profile)
            : '${_start(profile)}~${_end(profile)}',
        'thstrm_amount': amount!.toString(),
        'currency': 'KRW',
        'html_provenance': {
          'ruleVersion': profile['rule'],
          'source': uris[statement].toString(),
          'sourceReceipt': sourceReceipt,
          'targetReceipt': entry.receipt,
          'sourceSha256': sha[statement],
          'printedLabel': c['label'],
          'printedAmount': literal(c),
          if (lossProfile) ...{
            'signNormalization': loss
                ? 'explicitPrintedLossMagnitudeCorroborated'
                : 'none',
            'derivedSignedAmount': amount.toString(),
            'sourceCellRewritten': false,
            'printedLossSourceOwnOnly': true,
            'ownIssuerFilingSeriesEvidence': m['ownIssuerFilingSeriesEvidence'],
            'sourceRawAnomalies': m['unverifiedNonCoreCells'],
            'printedFxDashIsNumericZero': false,
            'sourceMainEquationCount': (m['checks'] as List).length,
          },
          'htmlTrIndex':
              grid
                  .take(c['table'] as int)
                  .fold<int>(0, (n, table) => n + table.length) +
              (c['row'] as int),
          'tableIndex': c['table'],
          'rowIndex': c['row'],
          'currentColumn': c['column'],
          'unit': '원',
          'unitMultiplier': '1',
          'basis': entry.basis == FsDiv.consolidated ? 'CFS' : 'OFS',
          'periodStart': _start(profile),
          'periodEnd': _end(profile),
          'currentCore8': !partial,
          if (entry.receipt == '20230314001218') ...{
            'combinedPPEAcquisition': m['combinedPPEAcquisition'],
            'ceRollFullyNumericVerified': false,
            'ceMissingCurrentTotalCells': m['ceMissingCurrentTotalCells'],
            'fullyNumericMainEquationCount': 10,
          },
          if (partial) ...{
            'partialCore7': true,
            'coreAccountsProvided': 7,
            'missingRequiredAccounts': ['capex'],
            'optionalAccountsNotCollected': ['capex'],
            'uncollectedOptionalAccounts': ['capex'],
            'missingAccountReasons': {'capex': capexMissingReason},
            'syntheticCapex': false,
            'detailHierarchyComplete': false,
            'notesReadScopeComplete': false,
            'ownCurrentPeriodProof': m['ownCurrentPeriodProof'],
          },
          'wholeNetIncomeExact': true,
          'sameUnitCurrentMainEquationsExact': true,
          'printedEquationCount': (m['checks'] as List).length,
          if (entry.receipt == '20230314000604') ...{
            'ceRollFullyNumericVerified': false,
            'ceMissingCurrentTotalCells': profile['ceMissingCurrentTotalCells'],
          },
          'fullStatementCollected': false,
          'fullStatementVerified': false,
          'allStatementRowsVerified': false,
          'notesVerified': false,
          'detailEnrichmentApproved': false,
          'detailHierarchyVerified': m['detailHierarchyVerified'],
          'sourceDetailAnomalies': anomalies,
          'numericCellCorrection': false,
          'genericRoundingTolerance': false,
          'priorNumericPeriodsCollected': false,
          'summaryPrecisionSourceNotUsed': m['summaryPrecisionSourceNotUsed'],
          if (profile['requiresBoundedUnverifiedNotes'] == true) ...{
            'supportingUnverifiedNoteSource': uris['notes'].toString(),
            'supportingUnverifiedNoteSha256': sha['notes'],
            'ownNoteDisagreements': m['ownNoteDisagreements'],
            'ownNoteCrossPrecisionResiduals':
                m['ownNoteCrossPrecisionResiduals'],
            'independentCFNetIncomePrinted': false,
            'independentCFNetIncomeExact': false,
            'mainNetIncomePLCEExact': true,
            'unresolvedOwnNoteDetailConflict': true,
          },
          'supportingNoteSource': uris['notes']?.toString(),
          'supportingNoteSha256': sha['notes'],
          'supportingNoteScope': m['supportingNoteScope'],
          if ({'20230314000692', '20230314000604'}.contains(entry.receipt))
            'crossPrecisionLiteralRemainders':
                profile['crossPrecisionLiteralRemainders'],
          'sourceCaptionDifference': m['sourceCaptionDifference'],
          'crossPrecisionEqualityClaim': false,
          'roundingCauseInferred': false,
          'sourceScopeNotice':
              m['sourceScopeNotice'] ??
              (anomalies.isEmpty
                  ? '당기 핵심 8개 계정만 검증했습니다. 전체 계정과 주석 수집 완료를 뜻하지 않습니다.'
                  : '당기 핵심 8개 직접 계정만 검증했습니다. 원문 세부 합계 차이 8,176원 및 기타포괄손익 세부 1원 차이를 보존했으며 상세 계정 확대와 전체 주석 검증은 승인하지 않았습니다.'),
        },
      });
    }
    return (
      numeric: PublicFinancialHtmlSource(
        sourceReceipt: sourceReceipt,
        correctionReceipt: sourceReceipt == entry.receipt
            ? null
            : entry.receipt,
        correctionSource: sourceReceipt == entry.receipt ? null : uris['shell'],
        coverHtml: raw['cover']!,
        coverSource: uris['cover']!,
        statementHtml: raw[statement]!,
        statementSource: uris[statement]!,
        periodStart: entry.periodStart,
        periodEnd: entry.periodEnd,
        rows: result,
      ),
      absence: null,
    );
  }
}

final class _LocatedOwnBasisAbsence
    extends PublicFinancialHtmlBasisNotApplicable {
  _LocatedOwnBasisAbsence({
    required Map<String, String> identityEvidence,
    required super.sourceReceipt,
    required super.corpCode,
    required super.companyName,
    required super.reportName,
    required super.periodStart,
    required super.periodEnd,
    required super.coverSource,
    required super.statementSource,
    required super.coverHtml,
    required super.statementHtml,
    required super.evidence,
  }) : _identityEvidence = Map.unmodifiable(identityEvidence);
  final Map<String, String> _identityEvidence;
  @override
  Map<String, String> get issuerIdentityEvidence => _identityEvidence;
}
