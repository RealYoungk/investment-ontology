import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

void main() {
  final cases = jsonDecode(
    r'''[{"receipt": "20221026000437", "corpCode": "00978075", "basis": "separate", "year": 2021, "amounts": {"자 산 총 계": "868193385", "부 채 총 계": "553489548", "자 본 총 계": "314703837", "Ⅰ. 영업수익": "6020799", "Ⅲ. 영업손실": "-1126497673", "Ⅷ. 당기순이익(손실)": "-1229580493", "Ⅰ.영업활동으로 인한 현금흐름": "-1047830257"}}, {"receipt": "20230321000275", "corpCode": "00321204", "basis": "separate", "year": 2022, "amounts": {"자 산 총 계": "85301749791", "부 채 총 계": "11816182801", "자 본 총 계": "73485566990", "Ⅰ.매 출": "186387391813", "Ⅴ.영업이익": "3266065091", "Ⅹ.당기순이익": "5603718522", "Ⅰ.영업활동으로 인한 현금흐름": "-7805201389"}}, {"receipt": "20240319000167", "corpCode": "00978075", "basis": "separate", "year": 2023, "amounts": {"자 산 총 계": "1535092755", "부 채 총 계": "921372829", "자 본 총 계": "613719926", "Ⅰ. 영업수익": "165762173", "Ⅲ. 영업손실": "-2537939403", "Ⅷ. 당기순손실": "-2600262943", "Ⅰ.영업활동으로 인한 현금흐름": "-2430028474"}}, {"receipt": "20230314000624", "corpCode": "00978075", "basis": "separate", "year": 2022, "amounts": {"자 산 총 계": "1827597559", "부 채 총 계": "871126017", "자 본 총 계": "956471542", "Ⅰ. 영업수익": "14740000", "Ⅲ. 영업손실": "-2169891966", "Ⅷ. 당기순이익(손실)": "-2276183476", "Ⅰ.영업활동으로 인한 현금흐름": "-2048023588"}}, {"receipt": "20220316000897", "corpCode": "00156859", "basis": "separate", "year": 2021, "amounts": {"자 산 총 계": "4683397881239", "부 채 총 계": "4020444700355", "자 본 총 계": "662953180884", "Ⅰ. 영업수익": "522222784865", "Ⅲ. 영업이익": "105446891755", "Ⅶ. 당기순이익": "179503012584", "I. 영업활동 현금흐름": "-344854588198", "6. 유형자산의 취득": "-4835667018"}}, {"receipt": "20230728000135", "corpCode": "01109690", "basis": "separate", "year": 2022, "amounts": {"자 산 총 계": "18411238905", "부 채 총 계": "15259881627", "자 본 총 계": "3151357278", "매출액": "4713863451", "영업손실": "-13795522044", "당기순손실": "-15668205808", "I. 영업활동현금흐름": "-1261458881"}}, {"receipt": "20241227000654", "corpCode": "01109690", "basis": "separate", "year": 2023, "amounts": {"자 산 총 계": "12535488143", "부 채 총 계": "4404232249", "자 본 총 계": "8131255894", "매출액": "944894116", "영업손실": "-4779869657", "당기순손실": "-8070246607", "I. 영업활동현금흐름": "-575765390"}}, {"receipt": "20220318000943", "corpCode": "01109690", "basis": "separate", "year": 2021, "amounts": {"자 산 총 계": "26893284527", "부 채 총 계": "9569936957", "자 본 총 계": "17323347570", "매출액": "5171797936", "영업이익(손실)": "-12111007482", "당기순이익(손실)": "-9974007872", "I. 영업활동현금흐름": "-11198155207", "유형자산의 취득": "-1083959328"}}, {"receipt": "20220323001368", "corpCode": "00980043", "basis": "separate", "year": 2021, "amounts": {"자산총계": "9367540774", "부채총계": "6957699801", "자본총계": "2409840973", "I.영업수익": "16994279855", "III.영업이익": "-820599525", "VIII.당기순손실": "-1899039453", "Ⅰ.영업활동으로인한현금흐름": "527945521", "유형자산의 취득": "-138855484"}}, {"receipt": "20250319000137", "corpCode": "00321204", "basis": "separate", "year": 2024, "amounts": {"자 산 총 계": "96398674080", "부 채 총 계": "8525555331", "자 본 총 계": "87873118749", "Ⅰ.매 출": "143219002377", "Ⅴ.영업이익": "2664318295", "Ⅹ.당기순이익": "14569065633", "Ⅰ.영업활동으로 인한 현금흐름": "-7591172478"}}, {"receipt": "20230321000275", "corpCode": "00321204", "basis": "consolidated", "year": 2022, "amounts": {"자 산 총 계": "89606205110", "부 채 총 계": "16120638120", "자 본 총 계": "73485566990", "Ⅰ.매 출": "224493603654", "Ⅴ.영업이익": "4890526281", "Ⅹ.당기순이익": "5603718522", "Ⅰ.영업활동으로 인한 현금흐름": "-5773698024"}}, {"receipt": "20220429000083", "corpCode": "01085442", "basis": "consolidated", "year": 2021, "amounts": {"자 산 총 계": "10278087326", "부 채 총 계": "8033729847", "자 본 총 계": "2244357479", "Ⅰ.매출액": "6727460756", "Ⅴ.영업손실": "-2996163537", "Ⅹ.연결당기순손실": "-5236216412", "Ⅰ.영업활동으로인한현금흐름": "-2135293689"}}, {"receipt": "20220322000542", "corpCode": "00321204", "basis": "consolidated", "year": 2021, "amounts": {"자 산 총 계": "90176461555", "부 채 총 계": "21642562459", "자 본 총 계": "68533899096", "Ⅰ.매 출": "182217749936", "Ⅴ.영업이익": "7081462287", "Ⅹ.당기순이익": "6518634883", "Ⅰ.영업활동으로 인한 현금흐름": "-1539213820"}}, {"receipt": "20220316000897", "corpCode": "00156859", "basis": "consolidated", "year": 2021, "amounts": {"자 산 총 계": "9229156624529", "부 채 총 계": "8261480967609", "자 본 총 계": "967675656920", "Ⅰ.영업수익": "779882897513", "Ⅲ. 영업이익": "148244663001", "Ⅶ. 당기순이익": "176109480069", "I. 영업활동 현금흐름": "-619514531273", "4. 유형자산의 취득": "-6871852095"}}, {"receipt": "20220323001368", "corpCode": "00980043", "basis": "consolidated", "year": 2021, "amounts": {"자산총계": "9516649715", "부채총계": "7104892617", "자본총계": "2411757098", "I.영업수익": "17018222585", "III.영업이익": "-942291729", "IX.당기순손실": "-746018827", "Ⅰ.영업활동으로인한현금흐름": "-238608823", "유형자산의 취득": "-164964575"}}, {"receipt": "20250319000137", "corpCode": "00321204", "basis": "consolidated", "year": 2024, "amounts": {"자 산 총 계": "107622386731", "부 채 총 계": "19749267982", "자 본 총 계": "87873118749", "Ⅰ.매 출": "180571325354", "Ⅴ.영업이익": "5950579259", "Ⅹ.당기순이익": "14569065633", "Ⅰ.영업활동으로 인한 현금흐름": "-703221838"}}]''',
  ) as List;
  for (final x in cases) {
    test(
      '${x['receipt']}:${x['basis']} current own primary immutable numbers',
      () async {
        final div = x['basis'] == 'separate'
            ? FsDiv.separate
            : FsDiv.consolidated;
        final entry = VerifiedAnnualSourceRegistry.find(x['receipt'], div)!;
        final f = DartFiling(
          id: 1,
          companyId: 1,
          corpCode: entry.corpCode,
          rceptNo: entry.receipt,
          bsnsYear: entry.year,
          reportCode: FinancialReportCode.annual,
          reportName: '사업보고서 (${entry.year}.12)',
          consolidatedStatus: FilingFetchStatus.failed,
          separateStatus: FilingFetchStatus.failed,
          attempts: 3,
          lastError: 'api-noData-annual-public:attempt=3; source failed',
          discoveredAt: DateTime.utc(2026),
        );
        final c = Company(
          id: 1,
          corpCode: entry.corpCode,
          name: entry.companyName,
          stockCode: '000001',
          fiscalMonth: 12,
        );
        final before = f.toJson();
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async => File(p).readAsBytes(),
        );
        final result = await cache.verifyRegistered(f, c, div);
        expect({
          for (final r in result.numeric!.rows)
            r['account_nm']: r['thstrm_amount'].toString(),
        }, x['amounts']);
        expect(result.numeric!.sourceReceipt, entry.receipt);
        expect(f.toJson(), before);
        for (final bad in [
          f.copyWith(corpCode: '00000000'),
          f.copyWith(rceptNo: '20260101000001'),
          f.copyWith(bsnsYear: 2020),
          f.copyWith(reportName: '사업보고서 (${entry.year}.06)'),
          f.copyWith(reportCode: FinancialReportCode.halfYear),
          f.copyWith(
            lastError: 'api-noData-annual-public:attempt=4; exhausted',
          ),
        ]) {
          expect(VerifiedAnnualSourceCache.eligibleFor(bad, entry), isFalse);
        }
      },
    );
  }
}
