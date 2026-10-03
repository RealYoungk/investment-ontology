import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../generated/protocol.dart';
import 'public_financial_html_fetch.dart';
import 'verified_annual_source_registry.dart';

/// Finite own current-row packages. Original and correction receipts stay distinct.
abstract final class LocatedOwnCurrentSource {
  static const absenceRule = 'located-own-explicit-cfs-absence-v1';
  static const rule = 'located-own-current-eight-v1';
  static const partialRule = 'located-own-current-seven-v1';
  static const capexMissingReason =
      'No printed whole PPE acquisition total; printed acquisition components are not the total.';
  static final List _profiles = jsonDecode(
    r'''[{"receipt":"20251021000231","corp":"01035942","name":"(주)메디안디노스틱","year":2024,"basis":"consolidated","sourceReceipt":"20251021000220","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20251021000231-cfs-located-own-current","digest":"89f834093957526744792ed3d9880d603bb806622e8db6644a1d07237bd6fda7","sourceDigest":"af7790fe62b3c89d67613def1dd07b61542b616906cda689705f0079810af315","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20251021000220&dcmNo=10846771&eleId=21&offset=331848&length=55177&dtd=dart4.xsd","statementSHA":"2ae8f77e5bd1ec4800b0474160a2cab19b4574ed1959f5e493d2e7008b0d649b"},{"receipt":"20251021000231","corp":"01035942","name":"(주)메디안디노스틱","year":2024,"basis":"separate","sourceReceipt":"20251021000220","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20251021000231-ofs-located-own-current","digest":"0e1f76876409477f5da88a2c4cb134527d4b6ea91cb00a79590f67a2431225f9","sourceDigest":"9614693495143ef8753ff583ee665bf338d86e6591fb604059fb2f370871b2c4","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20251021000220&dcmNo=10846771&eleId=23&offset=675311&length=48682&dtd=dart4.xsd","statementSHA":"49c2d2d7f8134f479e63e645beb2960e557e22084b301da097bb9ba789e4bcdb"},{"receipt":"20230321001535","corp":"00990396","name":"(주)레드우즈","year":2022,"basis":"consolidated","sourceReceipt":"20230321001515","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230321001535-cfs-located-own-current","digest":"3275bc2ffae06e0f76fd36bf9fb002c126dd179720f9addd65fb3a22d91e25ee","sourceDigest":"4729421e346acef6528e18ad0f9e7dffc0122c9859b235a771be5c53e10843cc","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001515&dcmNo=9085914&eleId=19&offset=139791&length=55959&dtd=dart3.xsd","statementSHA":"8cdeea8ef47694259dafe6a208c2ee043319f5b6db875f385f0c87c8d49ab850"},{"receipt":"20230321001535","corp":"00990396","name":"(주)레드우즈","year":2022,"basis":"separate","sourceReceipt":"20230321001515","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230321001535-ofs-located-own-current","digest":"610751dd98b52d5dc3cc393700e57b92d7c120a67bcdfa200a26510f058d13b0","sourceDigest":"d63c01a407500235270f6fd366eac9239bd8636f28c74140679de2660a4e6535","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001515&dcmNo=9085914&eleId=21&offset=498919&length=48967&dtd=dart3.xsd","statementSHA":"45052061e6962b918f8a9f20acc4b0548039583e95b61f645359f38b2b4a229b"},{"receipt":"20230721000635","corp":"01579020","name":"(주)아이엠지티","year":2022,"basis":"separate","sourceReceipt":"20230721000635","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20230721000635-ofs-located-own-current","digest":"d7e5b8b4e832c153c4762e900393e7cc71bb6c43af223990874465b8123425dc","sourceDigest":"6399f1770820b859551fe7494c0d5ea58d14ae6857af2f67049cca1fcd2e7329","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20230721000635&dcmNo=9358597&eleId=21&offset=175703&length=86206&dtd=dart3.xsd","statementSHA":"47f6e3f386f66d431ec5e33ce5c688c8096b19ae532854c10cd019b4e542dee5"},{"receipt":"20220322000617","sourceReceipt":"20220322000512","corp":"00149594","name":"한국캐피탈(주)","year":2021,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20220322000617-cfs-located-own-absence","digest":"be4cdb5a1fdd215f2b06b25f8a4505d969360ef575508e71ceec72dcabcbaaef","absenceLiteral":"2. 연결재무제표 - 해당사항 없음"},{"receipt":"20220421000450","sourceReceipt":"20220421000448","corp":"00414540","name":"대주이엔티(주)","year":2021,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20220421000450-cfs-located-own-absence","digest":"6f43c49351a80f4d892dee1ffffd2437ebdcb552660cdcd5bf386c61edd1cfbd","absenceLiteral":"2. 연결재무제표 - 해당사항 없습니다."},{"receipt":"20240704000080","sourceReceipt":"20240704000080","corp":"00666329","name":"(주)코나솔","year":2023,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20240704000080-cfs-located-own-absence","digest":"930b9ed5ce08c22f9375379634660d2327d9a062fa069e5d0b1ad228f23b41cc","absenceLiteral":"2. 연결재무제표 당사는 사업보고서 제출일 현재 해당사항이 없습니다"},{"receipt":"20230331004542","sourceReceipt":"20230331004538","corp":"01203312","name":"주식회사 케이뱅크","year":2022,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20230331004542-cfs-located-own-absence","digest":"0090b7831c0456ff5aa45df4d7af508d676eb2d6724b85b643e462982f4dca04","absenceLiteral":"2. 연결재무제표 해당사항 없습니다."},{"receipt":"20220318000774","sourceReceipt":"20220310001176","corp":"01466832","name":"(주)라피치","year":2021,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20220318000774-cfs-located-own-absence","digest":"898c1fef84f882aca78edc94b53dc4748a768bc7c478d9e3c97ea99fdbcce508","absenceLiteral":"2. 연결재무제표 당사는 사업보고서 제출일 현재 해당사항이 없습니다."},{"receipt":"20230721000635","sourceReceipt":"20230721000635","corp":"01579020","name":"(주)아이엠지티","year":2022,"basis":"consolidated","rule":"located-own-explicit-cfs-absence-v1","directory":"assets/financial_source_cache/20230721000635-cfs-located-own-absence","digest":"ec713395b2e0df944b9e40addc78c324015f8de29dce00a96e4f9e7c862fb585","absenceLiteral":"2. 연결재무제표 당사는 사업보고서 기준일 현재 해당사항 없습니다."},{"receipt":"20220615000399","corp":"00136721","name":"신영증권(주)","year":2022,"basis":"separate","sourceReceipt":"20220615000399","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20220615000399-ofs-located-own-current","digest":"4ef91342e5fa142840264cbaae4fe3908b0e5ca8344cccd1d7990a9bec649e34","sourceDigest":"8342d38ca1b5a144b8a57efc4a4166161f3638594b68cc83a651882b142ac1a5","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220615000399&dcmNo=8701694&eleId=19&offset=1127761&length=74482&dtd=dart3.xsd","statementSHA":"b55697be746e47ee90663b1d6d9eefc6d36fc5015fd44a4005af4203b0a64d82","periodStart":"2021-04-01","periodEnd":"2022-03-31","requiresOwnNotes":true,"coverPeriodTokens":["2021년04월01일","2022년03월31일"]},{"receipt":"20250320000572","corp":"01063556","name":"(주)질경이","year":2024,"basis":"separate","sourceReceipt":"20250320000572","rule":"located-own-current-eight-v1","directory":"assets/financial_source_cache/20250320000572-ofs-located-own-current","digest":"efc418d6d201129512833d82eb693890e427f516d55b666a81827efcbaaa0c8b","sourceDigest":"e63aa7a61d14c80f568467f426f43b0c8f4af36a715d1752c7c5aa7700c9a8cd","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320000572&dcmNo=10433870&eleId=21&offset=559412&length=45860&dtd=dart4.xsd","statementSHA":"f133d3d6ee63ddf3c4d051165445baf39d81da8f4160d84821c66a8f6e6078d5","periodStart":"2024-01-01","periodEnd":"2024-12-31","requiresOwnNotes":true,"coverPeriodTokens":["2024년01월01일","2024년12월31일"]},{"receipt":"20220322000802","corp":"01116344","name":"이비테크(주)","year":2021,"basis":"separate","sourceReceipt":"20220322000802","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20220322000802-ofs-located-own-seven","digest":"2485e6e119aa1b2a9d17bb177d2b33d5246ac0cef4aa3d6c7bb392c8684f344d","sourceDigest":"84d3e9dca89dfbb45b0b7ea3ddf31c5d5b7f63264c65007cdcd8382461cd7c62","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20220322000802&dcmNo=8491700&eleId=21&offset=104211&length=61838&dtd=dart3.xsd","statementSHA":"461d7461a17ce3eae8b2af6347c9a524831a727e4249b75e3b0d972b80cc4167","periodStart":"2021-01-01","periodEnd":"2021-12-31","coverPeriodTokens":["2021년01월01일","2021년12월31일"],"coreCells":[{"table":1,"row":43,"column":2,"label":"자산총계","literal":"13,640,640,446","value":13640640446,"key":"assets","kind":"BS"},{"table":1,"row":57,"column":2,"label":"부채총계","literal":"1,932,480,266","value":1932480266,"key":"liabilities","kind":"BS"},{"table":1,"row":65,"column":2,"label":"자본총계","literal":"11,708,160,180","value":11708160180,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":2,"label":"Ⅰ.매출액","literal":"5,442,616,873","value":5442616873,"key":"revenue","kind":"CIS"},{"table":3,"row":35,"column":2,"label":"Ⅴ.영업이익","literal":"980,641,199","value":980641199,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":50,"column":2,"label":"Ⅹ.당기순이익","literal":"1,252,122,946","value":1252122946,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":2,"label":"Ⅰ.영업활동으로인한현금흐름","literal":"1,108,524,316","value":1108524316,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20250429000919","corp":"01366824","name":"(주)제이엠멀티","year":2024,"basis":"separate","sourceReceipt":"20250429000919","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20250429000919-ofs-located-own-seven","digest":"de0e64e1faf02a7dc3b8c48f4ae8e914cb2609daef747f712b60fab643ced49f","sourceDigest":"71dbd5715f71f7d9f2bd634ea79e09275deb361f3d9fccea0ad4b0a7bf9ea142","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20250429000919&dcmNo=10622174&eleId=23&offset=497606&length=92172&dtd=dart4.xsd","statementSHA":"f8d6476b43a84323bc9819bf4e269b5a0d141a97c0334f1917f1e83e53c59a75","periodStart":"2024-01-01","periodEnd":"2024-12-31","coverPeriodTokens":["2024년01월01일","2024년12월31일"],"coreCells":[{"table":1,"row":42,"column":1,"label":"자산총계","literal":"16,084,409,690","value":16084409690,"key":"assets","kind":"BS"},{"table":1,"row":62,"column":1,"label":"부채총계","literal":"11,039,082,612","value":11039082612,"key":"liabilities","kind":"BS"},{"table":1,"row":73,"column":1,"label":"자본총계","literal":"5,045,327,078","value":5045327078,"key":"equity","kind":"BS"},{"table":3,"row":3,"column":1,"label":"Ⅰ.매출액","literal":"5,905,964,916","value":5905964916,"key":"revenue","kind":"CIS"},{"table":3,"row":42,"column":1,"label":"Ⅴ.영업이익","literal":"631,071,070","value":631071070,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":66,"column":1,"label":"Ⅹ.당기순이익","literal":"110,592,403","value":110592403,"key":"netIncome","kind":"CIS"},{"table":7,"row":3,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"282,402,537","value":282402537,"key":"operatingCashFlow","kind":"CF"}]},{"receipt":"20240424000570","corp":"01366824","name":"(주)제이엠멀티","year":2023,"basis":"consolidated","sourceReceipt":"20240424000570","rule":"located-own-current-seven-v1","directory":"assets/financial_source_cache/20240424000570-cfs-located-own-seven","digest":"c29444e8944b07fc0c821a63ff93967082ccf6cd25c1a50a13b19d696dff1d58","sourceDigest":"2a0f6b6f09037d78664769f82e78bbb79bf3432333e0d809d689bb51b843f675","statementURI":"https://dart.fss.or.kr/report/viewer.do?rcpNo=20240424000570&dcmNo=9915137&eleId=21&offset=207959&length=83860&dtd=dart4.xsd","statementSHA":"76c36c8f05076f229c560f48334e1f1841904bdc5e3b8d6d814d9931c9af83b4","periodStart":"2023-01-01","periodEnd":"2023-12-31","coverPeriodTokens":["2023년01월01일","2023년12월31일"],"coreCells":[{"table":1,"row":52,"column":1,"label":"자산총계","literal":"27,090,759,677","value":27090759677,"key":"assets","kind":"BS"},{"table":1,"row":73,"column":1,"label":"부채총계","literal":"21,955,237,924","value":21955237924,"key":"liabilities","kind":"BS"},{"table":1,"row":89,"column":1,"label":"자본총계","literal":"5,135,521,753","value":5135521753,"key":"equity","kind":"BS"},{"table":3,"row":1,"column":1,"label":"I.매출액","literal":"27,566,621,076","value":27566621076,"key":"revenue","kind":"CIS"},{"table":3,"row":47,"column":1,"label":"V.영업이익","literal":"(1,134,271,491)","value":-1134271491,"key":"operatingIncome","kind":"CIS"},{"table":3,"row":73,"column":1,"label":"X.당기순이익(손실)","literal":"(1,965,491,271)","value":-1965491271,"key":"netIncome","kind":"CIS"},{"table":7,"row":1,"column":1,"label":"I.영업활동으로인한현금흐름","literal":"848,887,238","value":848887238,"key":"operatingCashFlow","kind":"CF"}]}]''',
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
      if (v is! Map ||
          v['ruleVersion'] != p['rule'] ||
          v['sourceReceipt'] != receipt ||
          v['targetReceipt'] != p['receipt'] ||
          v['sourceSha256'] != p['statementSHA'] ||
          v['currentCore8'] != !partial ||
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
            r['thstrm_amount'] !=
                (c['literal'] as String)
                    .replaceAll(',', '')
                    .replaceAll('(', '-')
                    .replaceAll(')', '')) {
          return false;
        }
        final proof = r['html_provenance'] as Map;
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
      if (profile['requiresOwnNotes'] == true) 'notes',
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
      if (profile['requiresOwnNotes'] == true) 'notes',
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
      if (entry.receipt == '20220615000399') {
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
    final anomalies = m['sourceDetailAnomalies'] as List;
    for (final e in anomalies) {
      guard(
        residual(e as Map) == BigInt.from(e['residual'] as int),
        'literal detail disagreement changed',
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
      final c = cores[i] as Map, amount = money(literal(c));
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
          'supportingNoteSource': uris['notes']?.toString(),
          'supportingNoteSha256': sha['notes'],
          'supportingNoteScope': m['supportingNoteScope'],
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
