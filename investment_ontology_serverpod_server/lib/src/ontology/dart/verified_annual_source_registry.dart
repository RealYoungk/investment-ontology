import '../../generated/protocol.dart';

/// Compiled immutable packages only; callers cannot submit a source package.
final class AnnualSourceCacheEntry {
  const AnnualSourceCacheEntry({
    required this.receipt,
    required this.corpCode,
    required this.companyName,
    required this.year,
    required this.basis,
    required this.assetDirectory,
    required this.manifestDigest,
    required this.ruleVersion,
    required this.absenceLiteral,
    this.requiresIssuerOverview = false,
    this.requiresCashScopeNotes = false,
    this.requiresOwnOfsWitness = false,
    this.declaredPeriodStart,
    this.declaredPeriodEnd,
  }) : assert((declaredPeriodStart == null) == (declaredPeriodEnd == null));
  final String receipt,
      corpCode,
      companyName,
      assetDirectory,
      manifestDigest,
      ruleVersion;
  final int year;
  final FsDiv basis;
  final String? absenceLiteral;
  final bool requiresIssuerOverview;
  final bool requiresCashScopeNotes;
  final bool requiresOwnOfsWitness;
  final String? declaredPeriodStart, declaredPeriodEnd;
  DateTime get periodStart => declaredPeriodStart == null
      ? DateTime.utc(year)
      : _declaredDate(declaredPeriodStart!);
  DateTime get periodEnd => declaredPeriodEnd == null
      ? DateTime.utc(year, 12, 31)
      : _declaredDate(declaredPeriodEnd!);
  static DateTime _declaredDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid compiled annual calendar date');
    }
    final date = DateTime.parse('${value}T00:00:00Z');
    if (date.toIso8601String().substring(0, 10) != value) {
      throw const FormatException('Invalid compiled annual calendar date');
    }
    return date;
  }

  String get statementLabel => basis == FsDiv.consolidated ? 'cfs' : 'ofs';
  String get auditReference =>
      'financial-cache-replay:$manifestDigest:$receipt:${basis.name}:$ruleVersion';
}

abstract final class VerifiedAnnualSourceRegistry {
  static const entries = <AnnualSourceCacheEntry>[
    AnnualSourceCacheEntry(
      receipt: '20250320000036',
      corpCode: '00614089',
      companyName: '주식회사 에이원큐브텍',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20250320000036-ofs-exact-aone',
      manifestDigest:
          'f2a6ed5faf13f6e80b5d8ffe097a89d72a9876e4cb64a6e45314227920da2b53',
      ruleVersion: 'exact-aone-current-ofs-eight-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240318000135',
      corpCode: '00614089',
      companyName: '주식회사 에이원큐브텍',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20240318000135-ofs-exact-aone',
      manifestDigest:
          'cfcda8dce0afe1bd492e4e7a4fdd0e358feea47b812b161d975f14e903541c3f',
      ruleVersion: 'exact-aone-current-ofs-eight-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230321000015',
      corpCode: '00614089',
      companyName: '주식회사 에이원큐브텍',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230321000015-ofs-exact-aone',
      manifestDigest:
          '243fc77518c8676883eda7f597806ca810453f8f7e64e3327298a0f239e2319c',
      ruleVersion: 'exact-aone-current-ofs-eight-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220330000851',
      corpCode: '00614089',
      companyName: '주식회사 에이원큐브텍',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220330000851-ofs-exact-aone',
      manifestDigest:
          'd9930d510c64d9cf8dde5538e97914c8f39795d7f9a48c41099036d555e71bf4',
      ruleVersion: 'exact-aone-current-ofs-eight-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20250321001653',
      corpCode: '00886792',
      companyName: '(주)루켄테크놀러지스',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250321001653-cfs',
      manifestDigest:
          'e0cd29ec82a7da0660aacb49fcec36d386dd57a2f172a79990d8fe22aa8f8529',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220331003444',
      corpCode: '01085026',
      companyName: '(주)유진테크놀로지',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220331003444-ofs',
      manifestDigest:
          'e33e8b53e3b8079c1d3a4afd1121970f09516825503815eb188a163bcd7c6e98',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220317000713',
      corpCode: '00148993',
      companyName: '하이트진로홀딩스(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220317000713-cfs',
      manifestDigest:
          'f3b5715036643e86a519d7b858904b2f8cdbc1088a160acde89333bd0a819835',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20250321000195',
      corpCode: '00861100',
      companyName: '아이케이세미콘(주)',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20250321000195-cfs-exact-current',
      manifestDigest:
          '4d80f931b42026f0b513d13f53a4b9312319558168f1026815ea7f5df00e3ad3',
      ruleVersion: 'exact-current-cfs-seven-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250424000405',
      corpCode: '00756163',
      companyName: '(주)볼빅',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20250424000405-cfs-exact-current',
      manifestDigest:
          '82ab650b7aa78e9f609c654a98bf8503ce58ff9f46f08ac29817d7f7b06430c2',
      ruleVersion: 'exact-current-cfs-seven-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230316001545',
      corpCode: '00110893',
      companyName: '대신증권(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230316001545-ofs-daishin',
      manifestDigest:
          'c14278e41ce4c40b7521f4ca0b11ea0b563a047cdfa9f2dc42a64ffab96b15e9',
      ruleVersion: 'daishin-2022-exact-cash-scope-whole-eight-v1',
      absenceLiteral: null,
      requiresCashScopeNotes: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220315000644',
      corpCode: '00120182',
      companyName: '엔에이치투자증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220315000644-ofs-nh',
      manifestDigest:
          '8b44c10a1d2904ad4e265a4625699acaea7242ca8654b7cb3cb8715216f07473',
      ruleVersion: 'nh-2021-exact-whole-eight-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220308000939',
      corpCode: '00126256',
      companyName: "삼성생명보험(주)",
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20220308000939-cfs-insurance-current',
      manifestDigest:
          'aa79d3e76106c362a292d4902a5f574c5d737ce26c41df05c655794c3cde7653',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220308000939',
      corpCode: '00126256',
      companyName: "삼성생명보험(주)",
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220308000939-ofs-insurance-current',
      manifestDigest:
          '3ac3313940005f63bbba1435a03bd62a4b77d4a44dba272b9cebf6ebf8815088',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220323000792',
      corpCode: '00113562',
      companyName: "롯데손해보험(주)",
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220323000792-ofs-insurance-current',
      manifestDigest:
          '18300be4e431b471151a128ab1851b38b574fe4ea7f8ce7cb342675a7dbf3bc9',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20221017000313',
      corpCode: '00112332',
      companyName: "미래에셋생명보험(주)",
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20221017000313-cfs-insurance-current',
      manifestDigest:
          'e3f56aad630f96aae78d02ea127af2294351ec1b7a453808a7fe0eed5e8d49f9',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20221017000313',
      corpCode: '00112332',
      companyName: "미래에셋생명보험(주)",
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20221017000313-ofs-insurance-current',
      manifestDigest:
          '9629cd0e732f7f5f1eaa74fcb53f56e322eda8c8aad0d3fee0c8e68604359665',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230309000797',
      corpCode: '00164973',
      companyName: "현대해상화재보험(주)",
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20230309000797-cfs-insurance-current',
      manifestDigest:
          '54db342ac880400eaf32c5226837aa3c525c241b5bcfa2a90af7d8865772fee6',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230309000797',
      corpCode: '00164973',
      companyName: "현대해상화재보험(주)",
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230309000797-ofs-insurance-current',
      manifestDigest:
          'c3396f7c9406473f0809bf2338cccdb2c34b919db539a40b40f1365832e6bf9a',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230317001035',
      corpCode: '00112332',
      companyName: "미래에셋생명보험(주)",
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20230317001035-cfs-insurance-current',
      manifestDigest:
          '2a00fef4e1a276258a5a9c25f846ce066f01ef1b248c31d6b1fba05eff0c08db',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230317001035',
      corpCode: '00112332',
      companyName: "미래에셋생명보험(주)",
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230317001035-ofs-insurance-current',
      manifestDigest:
          '100992c9d42ce5986c3cc3d4f9883f3bdd143b610ddd514583ff2fb111b17486',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323001495',
      corpCode: '00113562',
      companyName: "롯데손해보험(주)",
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230323001495-ofs-insurance-current',
      manifestDigest:
          '2f5049acb5a9ddb95634818386032dc6eedee1984851022aa4ed8938db1a553c',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220816002204',
      corpCode: '00164973',
      companyName: "현대해상화재보험(주)",
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20220816002204-cfs-insurance-current',
      manifestDigest:
          '493fdec6d7cc3462b67e0296feb51402446e839a493c94182a157cbdea1bf8cf',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220816002204',
      corpCode: '00164973',
      companyName: "현대해상화재보험(주)",
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220816002204-ofs-insurance-current',
      manifestDigest:
          'b777195be3aeb7e8f1134ff91ed38598ed51e111fee69f0a11442382640f88cd',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230308000737',
      corpCode: '00126256',
      companyName: "삼성생명보험(주)",
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20230308000737-cfs-insurance-current',
      manifestDigest:
          '7b10ae292694a93e0c7f8a3cdab3f8e4d96bbb0956aa3db78035d40fa3912333',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230308000737',
      corpCode: '00126256',
      companyName: "삼성생명보험(주)",
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230308000737-ofs-insurance-current',
      manifestDigest:
          '0512ba45aa2c062fb0aa91999ca6ed3ce5b2317a1f56051a3feb535b74ad21c1',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230322000851',
      corpCode: '00231664',
      companyName: "우리기술투자(주)",
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20230322000851-cfs-insurance-current',
      manifestDigest:
          '7b02f66718de2ee500f17c1faa4043fd31243d9ddb2d6e68fe42d9ce954e40ce',
      ruleVersion: 'exact-insurance-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220715000446',
      corpCode: '00231664',
      companyName: '우리기술투자(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220715000446-ofs',
      manifestDigest:
          'ad372989a3f8a7f97137ebc8fdb10be3ca16ca977ab2afea40688b4d58dc20bc',
      ruleVersion: 'woori-investment-2021-whole7-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323001437',
      corpCode: '01363924',
      companyName: '(주)한국미라클피플사',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230323001437-ofs-exact-seven',
      manifestDigest:
          'd1e08fc06f798ad6577545e32d49816a938f18217327bbca2f1c70df08cf1f3a',
      ruleVersion: 'exact-seven-bs-ce-cash-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230315000894',
      corpCode: '00162416',
      companyName: '한양증권(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230315000894-ofs-exact-seven',
      manifestDigest:
          '2acceec4fe4bba202a473b2a7ad9a516b96cb8e122e1258b856bab3e3c8b4568',
      ruleVersion: 'exact-seven-bs-ce-cash-annual-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230331004027',
      corpCode: '01085026',
      companyName: "(주)유진테크놀로지",
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20230331004027-cfs-dated-current',
      manifestDigest:
          'b4459013f9c7307498a2f2008f7049ea10097a452f27089aec8ff0af0ae50e58',
      ruleVersion: 'exact-printed-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230331004027',
      corpCode: '01085026',
      companyName: "(주)유진테크놀로지",
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230331004027-ofs-dated-current',
      manifestDigest:
          'd2351069ad13e4fa03df19a3159cf3bbc64d4f125e3f7f4e74ed722470410ae2',
      ruleVersion: 'exact-printed-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240314000984',
      corpCode: '01344363',
      companyName: "(주)다원넥스뷰",
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20240314000984-ofs-dated-current',
      manifestDigest:
          '4270074c9fc0fc0abf23c217df15ac00773f34c8cdbb18be1ea68521458f5593',
      ruleVersion: 'exact-printed-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240401003353',
      corpCode: '01497373',
      companyName: "주식회사 아이엠비디엑스",
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20240401003353-ofs-dated-current',
      manifestDigest:
          '0d240205557728e8626f2e36997b8c71ab4760984c177006ab320eec5ddd57c2',
      ruleVersion: 'exact-printed-current-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260429001010',
      corpCode: '01188749',
      companyName: '주식회사 지앤이헬스케어',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/gne-own-audit-2025-ofs',
      manifestDigest:
          'cbd1ba85e2fc37d9ef8827b1545813a7f1f3aa3aa761fa6905292fc9a018e8cc',
      ruleVersion: 'gne-own-audit-whole7-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220322000265',
      corpCode: '01396931',
      companyName: '주식회사 유엑스엔',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220322000265-ofs-header18',
      manifestDigest:
          '0c12f71f2ae2c8c367cf209d761be9dea53d06a948677f6a60891078e3681be4',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220324000876',
      corpCode: '01397620',
      companyName: '주식회사 루닛',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20220324000876-cfs-header18',
      manifestDigest:
          'ab52277dd9d4858b075580e53fa224e4d514fe3bd7f5ee6a72ba73c61ee16477',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220324000876',
      corpCode: '01397620',
      companyName: '주식회사 루닛',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220324000876-ofs-header18',
      manifestDigest:
          '93da5692428b5332075d89b10dd702f4b60a7646e3116ec411a0da20571dc42e',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220328000884',
      corpCode: '01353848',
      companyName: '(주)이노벡스',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220328000884-ofs-header18',
      manifestDigest:
          '4de2cc81b6350d2e5aaa6e4c919ee38cb9bb7c9892b642fcc467d6cb77fb36ee',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20221213000195',
      corpCode: '00311216',
      companyName: '에이치엔에스하이텍(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20221213000195-cfs-header18',
      manifestDigest:
          '7d1e652fd413b4598aa8b91db7eed526e6bc1ab2b06581088c385f188a4b8ad1',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20221213000195',
      corpCode: '00311216',
      companyName: '에이치엔에스하이텍(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20221213000195-ofs-header18',
      manifestDigest:
          '6c41defb7b2b123b7abb3e490ebe22e6f10193cddd9ffa8983b4a74e7686ffa0',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323001121',
      corpCode: '00976615',
      companyName: '(주)틸론',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20230323001121-cfs-header18',
      manifestDigest:
          '63bead4f55ed89ceb2b5a32ac62f1954f8f3d184bfdbfa81cd6a94b08617e5eb',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323001121',
      corpCode: '00976615',
      companyName: '(주)틸론',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230323001121-ofs-header18',
      manifestDigest:
          '79868de23a397e2b2b0f1217a72f7ddf7fd11c537647756226ffdc2474f9de48',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250327000068',
      corpCode: '01466832',
      companyName: '(주)라피치',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20250327000068-ofs-header18',
      manifestDigest:
          '0c214d0977b4b91a550dda162a544b24386807c6e94b731deee8334d3baaec90',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260320001301',
      corpCode: '01466832',
      companyName: '(주)라피치',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20260320001301-ofs-header18',
      manifestDigest:
          '84f63ded1b530584b1ffa9da3db4807bc72e7c74f6ebe0a04c84b410829b10ff',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323000764',
      corpCode: '01229240',
      companyName: '(주)가이아코퍼레이션',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20260323000764-cfs-header18',
      manifestDigest:
          '50293af1fc3287e8df9dd0f1f2afe297657586c28e11d05227bf653dc00dad24',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323000764',
      corpCode: '01229240',
      companyName: '(주)가이아코퍼레이션',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20260323000764-ofs-header18',
      manifestDigest:
          'cecf6877b154cb9a424cb6265512c491388f0ea3c6fffe949bc308ee68ec5ee3',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260324000715',
      corpCode: '00929228',
      companyName: '(주)엔에스컴퍼니',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20260324000715-ofs-header18',
      manifestDigest:
          '6eac7bf6e5d727b4058f4103cae575a01f01fd7b3819395b583d9429534c2588',
      ruleVersion: 'header18-linked-direct-whole-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220322000265',
      corpCode: '01396931',
      companyName: '주식회사 유엑스엔',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20220322000265-cfs-header18',
      manifestDigest:
          '27e185774c6e623594fa3c40099c1733fff94631a063cb8ead03fec8a0864cf2',
      ruleVersion: 'header18-linked-explicit-absence-v1',
      absenceLiteral: '당사는 사업보고서 작성 기준일 현재 해당사항이 없습니다.',
    ),
    AnnualSourceCacheEntry(
      receipt: '20220328000884',
      corpCode: '01353848',
      companyName: '(주)이노벡스',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20220328000884-cfs-header18',
      manifestDigest:
          '7232bb79571aefd16637e0f9f65394885879d0ee3eccf595765e7c893a73f2a1',
      ruleVersion: 'header18-linked-explicit-absence-v1',
      absenceLiteral: '해 당 사 항 없 음',
    ),
    AnnualSourceCacheEntry(
      receipt: '20250327000068',
      corpCode: '01466832',
      companyName: '(주)라피치',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20250327000068-cfs-header18',
      manifestDigest:
          '388d996da4eecee2aaacbdd42c038d9264849b5d90e90065329e337e737fea75',
      ruleVersion: 'header18-linked-explicit-absence-v1',
      absenceLiteral: '당사는 사업보고서 제출일 현재 해당사항이 없습니다.',
    ),
    AnnualSourceCacheEntry(
      receipt: '20260320001301',
      corpCode: '01466832',
      companyName: '(주)라피치',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20260320001301-cfs-header18',
      manifestDigest:
          '3f79096aa61c191199311fb9755a7560d66b01b6541ff80221d163938b43b80c',
      ruleVersion: 'header18-linked-explicit-absence-v1',
      absenceLiteral: '당사는 사업보고서 제출일 현재 해당사항이 없습니다.',
    ),
    AnnualSourceCacheEntry(
      receipt: '20260324000715',
      corpCode: '00929228',
      companyName: '(주)엔에스컴퍼니',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20260324000715-cfs-header18',
      manifestDigest:
          '4d1d4c245791a126ebe7f96a1be6682e1e77923161d1d22e5febb8dbfd242437',
      ruleVersion: 'header18-linked-explicit-absence-v1',
      absenceLiteral: '해당사항 없음.',
    ),
    AnnualSourceCacheEntry(
      receipt: '20220321001162',
      corpCode: '01188749',
      companyName: '(주)지앤이헬스케어',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220321001162-cfs',
      manifestDigest:
          '2c2dff77dfce97afeb3c2684f05eac957a7161972196370d6293775a167d56aa',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20220322000589',
      corpCode: '00929228',
      companyName: '(주)엔에스컴퍼니',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220322000589-cfs',
      manifestDigest:
          '0ada8016a4b1b2e314e7147dee36b08487514b531ad75f4cbbd359ec847b30cf',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20220329000316',
      corpCode: '01034730',
      companyName: '크로넥스(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220329000316-cfs',
      manifestDigest:
          '5d05acf60696e4a2d18db957752b612f3422fe784fabffcbb5f1bbd77eb08e77',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "당사는 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20220330000929',
      corpCode: '01116380',
      companyName: '(주)씨앤에스링크',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220330000929-cfs',
      manifestDigest:
          'faff8a181e4117cbfc38e7d9cd01dbb9c181d148f5fa7b51bb1195dfa467a99d',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20220624000490',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220624000490-cfs',
      manifestDigest:
          'e0b0bd3a4d7e7bd3141b1e8cbb349b7e1cf5c269bda7a83277c9d903ae84dfdd',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323001068',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230323001068-cfs',
      manifestDigest:
          'd6de333f2aab248cabf96a862aa83c741d2014b281fe0910118583eecc7a08ec',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20230327000728',
      corpCode: '00929228',
      companyName: '(주)엔에스컴퍼니',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230327000728-cfs',
      manifestDigest:
          '12c5a657eb6b1d44da881331d40c5d4c8f2b3d85bf33099555a852ec0c1a61cd',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20240321000503',
      corpCode: '01116380',
      companyName: '(주)씨앤에스링크',
      year: 2023,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20240321000503-cfs',
      manifestDigest:
          'ab017550d8a1be2f69e3dde04074c42a8fd8809cf25203337debd902698a7967',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20240321001467',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2023,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20240321001467-cfs',
      manifestDigest:
          '2ca3747a57538bc889240530c1e4a78687c40c1f7cc1882486d2531e8135fcaf',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20250318000656',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250318000656-cfs',
      manifestDigest:
          'a09592818aa4667cfeeee09ba3882fcdf32d8380b9cd0aaf444dbbe7c8418972',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "※ 당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20250320000656',
      corpCode: '01116380',
      companyName: '(주)씨앤에스링크',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250320000656-cfs',
      manifestDigest:
          '449ee2560bedf581c8073bf9039cfd9403548c6860f7fb83813e73f2977fb44b',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321000943',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250321000943-cfs',
      manifestDigest:
          'd70dee95d64b3a151d99aa2a709dc0a0a169bae2b8ae62271bad017584d6a5a4',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321001385',
      corpCode: '01034730',
      companyName: '크로넥스(주)',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250321001385-cfs',
      manifestDigest:
          '9658149cae00238039348585849160e2e366a9c2a5fa790ba84f990fd1134066',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "당사는 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323000673',
      corpCode: '01063237',
      companyName: '(주)플럼라인생명과학',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20260323000673-cfs',
      manifestDigest:
          'be485fa6a9068d5532af08f5e238fafa9acdeb22d6b03b3d351c0f12e60fc007',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "보고서 제출일 현재 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323001028',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20260323001028-cfs',
      manifestDigest:
          '6c67e98effc2b14396a6dbed66aa29df3b5de78d0782ba5c10d82b67d4d4e933',
      ruleVersion: 'paired-own-cfs-pure-none-v1',
      absenceLiteral: "상기 내역과 관련하여 본 보고서 제출 기준일 현재 해당사항 없습니다.",
    ),

    AnnualSourceCacheEntry(
      receipt: '20220316001241',
      corpCode: '00115694',
      companyName: 'DB증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220316001241-ofs-exact-issuer',
      manifestDigest:
          '2cfe2f3f5aee21f83d59c0ef55ac3dbda3b653807fd316995771ab0bd6e64c04',
      ruleVersion: 'db-exact-self-declared-issuer-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230321001219',
      corpCode: '00115694',
      companyName: 'DB증권(주)',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20230321001219-cfs-exact-issuer',
      manifestDigest:
          '425b09ef7e29ef6dfb75fae2384213f8f304eaed9ce0fac35c66135ecdf50825',
      ruleVersion: 'db-fy22-exact-self-declared-issuer-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260804000177',
      corpCode: '01872459',
      companyName: '(주)본시스템즈',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20260804000177-ofs-linked-audit',
      manifestDigest:
          '8cf8b9cd641f655aff834ca3d0ec6cfa7fbf8364a31fb4b410d2aaebbd2458e1',
      ruleVersion: 'linked-correction-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260804000177',
      corpCode: '01872459',
      companyName: '(주)본시스템즈',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory:
          'assets/financial_source_cache/20260804000177-cfs-linked-audit',
      manifestDigest:
          '6f613aed9a944a5d6527f5b1990ee974553cc77681705065d0f72f696c84a2d4',
      ruleVersion: 'verified-basis-not-applicable-v1',
      absenceLiteral: '당사는 보고서 제출일 현재 해당사항 없습니다.',
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321000964',
      corpCode: '00991225',
      companyName: '(주)더콘텐츠온',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321000964-ofs',
      manifestDigest:
          '7fd49f310a9c6e28d60201fb279bcfdf8e177824c117b6b8d2aec4a1dc34012e',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323001088',
      corpCode: '00991225',
      companyName: '(주)더콘텐츠온',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260323001088-ofs',
      manifestDigest:
          '7f8a26cd3ffac702507bc570794cad17df9dfd85efb9102123336a4988ce6e77',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240321001908',
      corpCode: '00991225',
      companyName: '(주)더콘텐츠온',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240321001908-ofs',
      manifestDigest:
          '1c9caad26cb2bac542a96229c17d67e7ccdf59b8c7753bfb463a505991e35345',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220323000557',
      corpCode: '00991225',
      companyName: '(주)더콘텐츠온',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220323000557-ofs',
      manifestDigest:
          'c2750fe672d0198eb2eefad8fb7d4443e6aebb57d85509e9d17de40c2335f557',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220331001729',
      corpCode: '00965318',
      companyName: '(주)이노시뮬레이션',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220331001729-ofs-core50',
      manifestDigest:
          'f4c769cbb5b5db2192a3cb6d2073ce099bfcd2d60b5215f9be719cf7ce57674e',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220315001273',
      corpCode: '00148610',
      companyName: '한화투자증권(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220315001273-cfs-core50',
      manifestDigest:
          '7b82873a9a353f3680653dc825dc0f41f468a5647ab7f563366e0456de4f9874',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220315000921',
      corpCode: '00113359',
      companyName: '교보증권(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220315000921-cfs-core50',
      manifestDigest:
          'e550393be98cb725a01acb310b21a58238bb158a43e044fd5893708f350965be',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220317001218',
      corpCode: '01113499',
      companyName: '(주)아이티센피엔에스',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220317001218-cfs',
      manifestDigest:
          '81d86f9caf2c3b5ecdb7441b05f24d15cb582fbb883f80378d01b2bc7e2fa9a3',
      ruleVersion: 'two-historical-issuer-pure-none-v1',
      absenceLiteral: '당사는 사업보고서 제출기준일 현재 해당사항 없습니다.',
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220816000416',
      corpCode: '01188730',
      companyName: 'SK시그넷(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220816000416-cfs',
      manifestDigest:
          '7200e76b69c0c13fa83aeb992944f14738dcdf868332f51ad02d2f8e18811323',
      ruleVersion: 'two-historical-issuer-pure-none-v1',
      absenceLiteral: '당사는 연결재무제표 작성대상 법인이 아니므로 해당사항이 없습니다.',
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220317001218',
      corpCode: '01113499',
      companyName: '(주)아이티센피엔에스',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220317001218-ofs',
      manifestDigest:
          '25b11ba3d8ec30ced1faa1c2f24448f63b0383c7237c30acc7e734049befc27a',
      ruleVersion: 'two-historical-issuer-whole-annual-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220816000416',
      corpCode: '01188730',
      companyName: 'SK시그넷(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220816000416-ofs',
      manifestDigest:
          'be5a584ca60041032fc5be67c9755a05121c035ef197909972e817d5e0605ea6',
      ruleVersion: 'two-historical-issuer-whole-annual-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220310001159',
      corpCode: '00139214',
      companyName: '삼성화재해상보험(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220310001159-cfs',
      manifestDigest:
          '38c54494525e7e45bbc0b9c48aaa45b014f9831014c52081845ccb7828d34044',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230309000772',
      corpCode: '00139214',
      companyName: '삼성화재해상보험(주)',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230309000772-cfs',
      manifestDigest:
          'b31d4ef063e973e8dad6197297e0668f81c2d154e1165a5fa1d51a31d3e9d097',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220310001159',
      corpCode: '00139214',
      companyName: '삼성화재해상보험(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220310001159-ofs',
      manifestDigest:
          'a0dc0bb3ebeaca222c9c32da8aaa965df6326612a1555f21cc9c3d0647bd9726',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230309000772',
      corpCode: '00139214',
      companyName: '삼성화재해상보험(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230309000772-ofs',
      manifestDigest:
          'bec8f39c4ac5ab70934e68d21f4ec144c6ad7686796f754972b5e1aa0160e40d',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220317000713',
      corpCode: '00148993',
      companyName: '하이트진로홀딩스(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220317000713-ofs',
      manifestDigest:
          '475b8918b3e7900c9bd5ed247046226df4ab798a1b1b98955dc1d23f8be6406f',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250320001147',
      corpCode: '00663289',
      companyName: '위월드(주)',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250320001147-ofs',
      manifestDigest:
          'acd714473a36c35cfe8cb9261d78caa23faad7405673e5ca1c7fdab8185c6371',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220315001280',
      corpCode: '00340096',
      companyName: '미래에셋벤처투자 주식회사',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220315001280-ofs-unit-audit',
      manifestDigest:
          '223ac4dc5a23d0e45474151ce109e5a23935aab2af3a985573d67427bb4082e9',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230315001270',
      corpCode: '00340096',
      companyName: '미래에셋벤처투자 주식회사',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230315001270-ofs-unit-audit',
      manifestDigest:
          'c0de2904892a81a0f3ea1df620ebad402d46b1367cc61bc6b5b5edffb5445c55',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240320001438',
      corpCode: '00963000',
      companyName: '(주)썬테크',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20240320001438-ofs-unit-audit',
      manifestDigest:
          '1cbccbc3819aee09c5db7c44d0ebb490040aa05c09147e3dc9bad1e8614a4187',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250317000968',
      corpCode: '00963000',
      companyName: '(주)썬테크',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20250317000968-ofs-unit-audit',
      manifestDigest:
          'f3589a692d162b730860cdc01ed6dec88e9bf1e8d7b2572328f85a53d9ebdbaa',
      ruleVersion: 'linked-correction-audit-immutable-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220331002887',
      corpCode: '01366824',
      companyName: '(주)제이엠멀티',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220331002887-ofs-dated',
      manifestDigest:
          'cc009545df5f05deb25be83638547dc7818f9ae01030ce22e627ca568a6abc94',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230427000895',
      corpCode: '01366824',
      companyName: '(주)제이엠멀티',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230427000895-ofs-dated',
      manifestDigest:
          'e25c170f32a4487cb4c8a9860bcba124ded98bae6e931dbf329012849f65adfc',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220331003444',
      corpCode: '01085026',
      companyName: '(주)유진테크놀로지',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220331003444-cfs-dated',
      manifestDigest:
          '5bd5b689d1892329cad4b8190ea0d476c969e2cd74eceda76eb15428faf93d81',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250328002132',
      corpCode: '01396931',
      companyName: '주식회사 유엑스엔',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250328002132-ofs-dated',
      manifestDigest:
          '451058162cc899c518d152eb4a22f39f0c3ac80aad6d960302edf6eb533b8e40',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240320001359',
      corpCode: '01281541',
      companyName: '(주)에피바이오텍',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240320001359-ofs-dated',
      manifestDigest:
          'e6828d29c4a1278a60fcfe4fb55228bb2ac2d3d576af63353fe9094e7eb291ea',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240704000080',
      corpCode: '00666329',
      companyName: '(주)코나솔',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240704000080-ofs-dated',
      manifestDigest:
          '7593ba54398d4cebc7d51968e1952b01b8bfe51d72e195a81a859cbe91088ce8',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220331000273',
      corpCode: '01258020',
      companyName: '주식회사 에스바이오메딕스',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220331000273-ofs',
      manifestDigest:
          '137fa08e66011e310d9715f95f75a9ba61b43ffa9ede7f3c73962b7dd33cb425',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230314001218',
      corpCode: '00135917',
      companyName: '한화손해보험(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230314001218-ofs',
      manifestDigest:
          'd040c3da0b3f99a86a9c06c900ab74852497b745c28429170539bb2295ab66c8',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230321001131',
      corpCode: '01596425',
      companyName: '에스케이스퀘어 주식회사',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230321001131-ofs',
      manifestDigest:
          '4598f4a55d49e356990970bd31093ceb8a3d2c12b0b71fa607806e2dd7c89e2a',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323000050',
      corpCode: '01258020',
      companyName: '주식회사 에스바이오메딕스',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230323000050-ofs',
      manifestDigest:
          '26ce948ba039b311eea4c4e612efc8f5506dabc07251499ff1e1f08a25c7450a',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240320000922',
      corpCode: '01020269',
      companyName: '(주) 탈로스',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240320000922-ofs',
      manifestDigest:
          'ac2b8c8d6d79a07a02bd0e4da7e33358c0ca0a8956c3a1555999f0a04d2280ae',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321000195',
      corpCode: '00861100',
      companyName: '아이케이세미콘(주)',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321000195-ofs',
      manifestDigest:
          'b5398ad6d1e8ca9fc585062a74b812e5f3c8400dd31e82996f1fd205041c82a1',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250424000405',
      corpCode: '00756163',
      companyName: '(주)볼빅',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250424000405-ofs',
      manifestDigest:
          '0ffcba9b6f2656f99de483dd7308dd6aa3a5ae8c0e4b1c651400b10c307a784b',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230317000745',
      corpCode: '01065785',
      companyName: '(주)노브메타파마',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230317000745-ofs',
      manifestDigest:
          'b9da398ef3b4b721c8dafebf712eed887d73325ae3caafb7e6939f91fecd91e1',
      ruleVersion: 'direct-net-cfo-after-empty-caption-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240320001114',
      corpCode: '01065785',
      companyName: '(주)노브메타파마',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240320001114-ofs',
      manifestDigest:
          '4f06002798f3ee56e02979048262644823e30d003fe0f9d6ef01945923d338c8',
      ruleVersion: 'direct-net-cfo-after-empty-caption-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250314001145',
      corpCode: '01065785',
      companyName: '(주)노브메타파마',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250314001145-ofs',
      manifestDigest:
          '2c432ebb600d8c01aff1e616d588122401c30f124680b40e85068e263d55792d',
      ruleVersion: 'direct-net-cfo-after-empty-caption-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220315000921',
      corpCode: '00113359',
      companyName: '교보증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220315000921-ofs-whole-ce',
      manifestDigest:
          '020fd38e788825d63f34c83fc33ec01775a218c8fcfeef379c4b9d076b5bffea',
      ruleVersion: 'whole-core-independent-ce-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220315001266',
      corpCode: '00162416',
      companyName: '한양증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220315001266-ofs-whole-ce',
      manifestDigest:
          '259c9d9455f6168f91daf99315f74ca89861c00ff784f0d8645a7372b8baa85f',
      ruleVersion: 'whole-core-independent-ce-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220315001273',
      corpCode: '00148610',
      companyName: '한화투자증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20220315001273-ofs-whole-ce',
      manifestDigest:
          'cfa09723d50c61a8da4f92eb8bd51bd6cc4665203bdb8152d64c21d19bae79f0',
      ruleVersion: 'whole-core-independent-ce-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230317000614',
      corpCode: '01023822',
      companyName: '(주)메디젠휴먼케어',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory:
          'assets/financial_source_cache/20230317000614-ofs-whole-ce',
      manifestDigest:
          '7167a7756def58cc1a111a0a0b5ae36894e0209ea0d9c1e10d12061d384b11c1',
      ruleVersion: 'whole-core-independent-ce-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20210629000260',
      corpCode: '00677334',
      companyName: '(주)아하',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20210629000260-cfs',
      manifestDigest:
          '1f6dabbfbf5c20e732272adf1197aa79b34fc9345c5defad281e204b49ace3af',
      ruleVersion: 'exact-declared-fiscal-period-annual-v1',
      absenceLiteral: '- 해당사항 없음.',
      requiresIssuerOverview: true,
      declaredPeriodStart: '2020-04-01',
      declaredPeriodEnd: '2021-03-31',
    ),
    AnnualSourceCacheEntry(
      receipt: '20241227000654',
      corpCode: '01109690',
      companyName: '도부(주)',
      year: 2023,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20241227000654-cfs',
      manifestDigest:
          '7a9088c68fd7f7b2084f16d74495854ff280e23370c21ddcd7a6a5cad8d9d0c1',
      ruleVersion: 'historical-issuer-cfs-none-own-ofs-v1',
      absenceLiteral: '당사는 해당사항 없습니다.',
      requiresIssuerOverview: true,
      requiresOwnOfsWitness: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230728000135',
      corpCode: '01109690',
      companyName: '도부(주)',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230728000135-cfs',
      manifestDigest:
          '13a936d4124005214991973e2685ca22c4c2ef1114b28aec9b5630e34dc08448',
      ruleVersion: 'historical-issuer-cfs-none-own-ofs-v1',
      absenceLiteral: '당사는 해당사항 없습니다.',
      requiresIssuerOverview: true,
      requiresOwnOfsWitness: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220318000943',
      corpCode: '01109690',
      companyName: '도부(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220318000943-cfs',
      manifestDigest:
          '0e1544e0fc8cb53dcfd3d567a72a3721532f3aff2c4e41edda7ed4c81a9d59e6',
      ruleVersion: 'historical-issuer-cfs-none-own-ofs-v1',
      absenceLiteral: '당사는 해당사항 없습니다.',
      requiresIssuerOverview: true,
      requiresOwnOfsWitness: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20240319000167',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2023,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20240319000167-cfs',
      manifestDigest:
          '811c8ab51df14c3f6edc84ddaed28dd85a113f72219c5c5ba39efd75ed3b018b',
      ruleVersion: 'historical-issuer-cfs-none-own-ofs-v1',
      absenceLiteral: '※ 당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.',
      requiresIssuerOverview: true,
      requiresOwnOfsWitness: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230314000624',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230314000624-cfs',
      manifestDigest:
          'a843ca20b09301235585a5607ed369d42a599b6bd033d1aa242b33b551c8242e',
      ruleVersion: 'historical-issuer-cfs-none-own-ofs-v1',
      absenceLiteral: '당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.',
      requiresIssuerOverview: true,
      requiresOwnOfsWitness: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20221026000437',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20221026000437-cfs',
      manifestDigest:
          '1481f723211f4029a6898dc5a415cc8b64d0d3e75b342a1d89cf64273a0d3a0f',
      ruleVersion: 'historical-issuer-cfs-none-own-ofs-v1',
      absenceLiteral: '당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.',
      requiresIssuerOverview: true,
      requiresOwnOfsWitness: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20250319000137',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250319000137-cfs',
      manifestDigest:
          '0522ae8561a6a4ba581e7d0183ff8a1d4bc020223d856ffbfe8113880e0efd37',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220323001368',
      corpCode: '00980043',
      companyName: '(주)비큐에이아이',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220323001368-cfs',
      manifestDigest:
          '6771a18600a099aebbe1e4c8d7c7c7b13eca5efeb920a985db6606ab18628a67',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220316000897',
      corpCode: '00156859',
      companyName: '다올투자증권(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220316000897-cfs',
      manifestDigest:
          'f1e323beca808d8342c996dc83ed17e836ed1251304e2a34a8b24edd519ab13b',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220322000542',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220322000542-cfs',
      manifestDigest:
          'ea7b32b897870d5ef975718a2bfb6767f496a6d4902c6caf432f3263fb4cd1b6',
      ruleVersion: 'first-direct-issuer-exact-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220429000083',
      corpCode: '01085442',
      companyName: '(주)오건에코텍',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220429000083-cfs',
      manifestDigest:
          'c56957bd6021eb6335f32f06c86c7c1228b41e123f155b4d76273c9b9ed43871',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230321000275',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230321000275-cfs',
      manifestDigest:
          'a2ebabe4fb66afa64709bc32d806f6e8ae65b481aa32b1d6c094a58e429d5d1e',
      ruleVersion: 'first-direct-issuer-exact-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20250319000137',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250319000137-ofs',
      manifestDigest:
          '24e688c5a2c0676f74556745cf99968387acca496abe530a71694b4550aedd1c',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220323001368',
      corpCode: '00980043',
      companyName: '(주)비큐에이아이',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220323001368-ofs',
      manifestDigest:
          'f39b357ced4f6dd1231550787fa626f9912f7687ed8b7a291e76a8301d1ae428',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220318000943',
      corpCode: '01109690',
      companyName: '도부(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220318000943-ofs',
      manifestDigest:
          'ce40f87988f7627721876052469a06a873055be01a1b225952a37296f9355ad8',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20241227000654',
      corpCode: '01109690',
      companyName: '도부(주)',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20241227000654-ofs',
      manifestDigest:
          'cd60803ee87e249ed7df3de89518a98011294ecfb05fd3e5217e8dbf2e4f42a7',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230728000135',
      corpCode: '01109690',
      companyName: '도부(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230728000135-ofs',
      manifestDigest:
          '881d782de7fe77912071b506980791cf5249f9589984d507ee4e7e893b76631f',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220316000897',
      corpCode: '00156859',
      companyName: '다올투자증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220316000897-ofs',
      manifestDigest:
          'df688fd4d31d15a3f7e4ad870a32e2853a6ade51fcbd7adbabc8b496a5435598',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230314000624',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230314000624-ofs',
      manifestDigest:
          '0466d7d5772b5a0fbb141de80fdb11d3bfc555d7f24fd5f7128f6feac92e1a87',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20240319000167',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240319000167-ofs',
      manifestDigest:
          'b526582109d09a57fff37c61f11c5b8f5eb65e952adde1f4af7869fd100b026f',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230321000275',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230321000275-ofs',
      manifestDigest:
          '136d755ceb7bf58721a45edc85adb8ec12d4a4c4bfadc509ebaca6a71299ab99',
      ruleVersion: 'first-direct-issuer-exact-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20221026000437',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20221026000437-ofs',
      manifestDigest:
          'b7125d3432504b1ca3883a38f2e4f2a994ac9250df72a4597edf185433167bc6',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220322000542',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220322000542-ofs',
      manifestDigest:
          'c19939757336da7bf0ad377f7ee7f28aca62bdb5bb8ec60b7c3d7208618295af',
      ruleVersion: 'first-direct-issuer-exact-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220429000083',
      corpCode: '01085442',
      companyName: '(주)오건에코텍',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220429000083-ofs',
      manifestDigest:
          'cad99399acf5b6b4ba220f5460e88f213b1a5a715c5c81dc8f892fb4e8c191a8',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),

    AnnualSourceCacheEntry(
      receipt: '20210629000260',
      corpCode: '00677334',
      companyName: '(주)아하',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20210629000260-ofs',
      manifestDigest:
          'd6865d92ad6f7f97160a0f7f975fdd57160da2b00388b6a533f1e14ec87c7fb0',
      ruleVersion: 'exact-declared-fiscal-period-annual-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
      declaredPeriodStart: '2020-04-01',
      declaredPeriodEnd: '2021-03-31',
    ),

    AnnualSourceCacheEntry(
      receipt: '20230314001271',
      corpCode: '00148832',
      companyName: '(주)제주은행',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230314001271-ofs-six',
      manifestDigest:
          '6e210abde63b1bba439dac8764c2a77452ee54dfdf78e0e48d46ffc798fd49e5',
      ruleVersion: 'source-six-with-unavailable-whole-revenue-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230309000572',
      corpCode: '00104856',
      companyName: '삼성증권(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230309000572-ofs-six',
      manifestDigest:
          '6a91f64a2296877b3baaafcd50c5d2fe62e157b283faec46c3be2a2660c3ef08',
      ruleVersion: 'source-six-with-unavailable-whole-revenue-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323001133',
      corpCode: '01185867',
      companyName: '퓨쳐메디신 주식회사',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230323001133-ofs-six',
      manifestDigest:
          'bfc3e4be2515e16fa30780059f1c43d7b5a7583cfa82bcc241f3a20d2320fea7',
      ruleVersion: 'source-six-with-unavailable-whole-revenue-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323000759',
      corpCode: '00886792',
      companyName: '(주)루켄테크놀러지스',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20260323000759-cfs',
      manifestDigest:
          '6b482725c50269d1a28eba86e1efba4bf7eb6d3bd3c87f876915cde04194bdcb',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323000759',
      corpCode: '00886792',
      companyName: '(주)루켄테크놀러지스',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260323000759-ofs',
      manifestDigest:
          '02c6e41f4cc9b487dbb85ee72d5d463605478196215de5b2979ca8b92dd053a2',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260330001644',
      corpCode: '00669450',
      companyName: '(주)바이오프로테크',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20260330001644-cfs',
      manifestDigest:
          '24bbfafc4c005721cb88cb9c2028ba78247bbb209518851d7e55961213c0089a',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260330001644',
      corpCode: '00669450',
      companyName: '(주)바이오프로테크',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260330001644-ofs',
      manifestDigest:
          '6b42e35e743a60de918968ca4b0bda000a675360a16a7953c065b7447a36965e',
      ruleVersion: 'dated-current-column-whole-equity-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20250321001653',
      corpCode: '00886792',
      companyName: '(주)루켄테크놀러지스',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321001653-ofs',
      manifestDigest:
          'cb34c4f3e7f6ce095f3996235c438bd3086bd128e607ec0bfc3dac3dfb71901f',
      ruleVersion: 'year-term-bs-with-independent-ofs-ce-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230414002057',
      corpCode: '01226234',
      companyName: '(주)와이바이오로직스',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230414002057-ofs',
      manifestDigest:
          'd08e7be8a9fc2f1ad21bc1cd78f625cbde65300b55742b56513a9691042c5c9e',
      ruleVersion: 'bilingual-issuer-exact-eight-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230414002057',
      corpCode: '01226234',
      companyName: '(주)와이바이오로직스',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230414002057-cfs',
      manifestDigest:
          'bf6bb7a802b0fb45369e4088dda93777ab0b0ddd5bdad9d61a69508409d49ee1',
      ruleVersion: 'bilingual-issuer-exact-pure-none-v1',
      absenceLiteral: '*해당사항이 없습니다.',
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20220321001162',
      corpCode: '01188749',
      companyName: '(주)지앤이헬스케어',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220321001162-ofs',
      manifestDigest:
          '23d5d04a3bf92c28477eaf1bdc5d58efa3a638abd2c06b04caddcf1cf18b0b17',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220322000589',
      corpCode: '00929228',
      companyName: '(주)엔에스컴퍼니',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220322000589-ofs',
      manifestDigest:
          'e6334d0b35fc35057dba132bfcbff313b156d74e087084df03873edbccbebfca',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220324000600',
      corpCode: '00296290',
      companyName: '키움증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220324000600-ofs',
      manifestDigest:
          '9d133f359aecb3de0044a7dcf7dccf4a551231d15625bf59f27b181ed8961cb6',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220329000316',
      corpCode: '01034730',
      companyName: '크로넥스(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220329000316-ofs',
      manifestDigest:
          '4f46f69d089adb1eaf223bc4a3322c12d6cbf9e5333ffa7fda5919d0d2a28ac5',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220330000929',
      corpCode: '01116380',
      companyName: '(주)씨앤에스링크',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220330000929-ofs',
      manifestDigest:
          '704ed386874daa63f44c162f21f4a01257d89f65276ae4e0226ba04bdae08e3b',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220624000490',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220624000490-ofs',
      manifestDigest:
          'b0ed8367bed929ee84e243e4fac98c1c4581a22cf77af28236c7b2b6840eb7a7',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323001068',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230323001068-ofs',
      manifestDigest:
          '09e864b7e01f77dd780efc265ce0403fa424975cb42bde39c59359ac9266d775',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230327000728',
      corpCode: '00929228',
      companyName: '(주)엔에스컴퍼니',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230327000728-ofs',
      manifestDigest:
          '3fafcb0cfcb9982f644044390480c815a9fc6a140e2b077994b55571535235c8',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230724000233',
      corpCode: '01034730',
      companyName: '크로넥스(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230724000233-ofs',
      manifestDigest:
          '272c7e1e5ca80208c22fc817e18f29160192a206c218677bff402ad08a74ee14',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240320000871',
      corpCode: '01034730',
      companyName: '크로넥스(주)',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240320000871-ofs',
      manifestDigest:
          '2c6427bb6b94b6186131c097573b3d1d000c0d6a50bbf8bedeee1de25c37983d',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240321000503',
      corpCode: '01116380',
      companyName: '(주)씨앤에스링크',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240321000503-ofs',
      manifestDigest:
          'f71185174b681dd38f9767638574956f28885f0c8d9882e55509265066d06ad9',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240321000985',
      corpCode: '01063556',
      companyName: '(주)질경이',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240321000985-ofs',
      manifestDigest:
          'c96c3d5fd6ca940c7078301f8259f5a61d42e871f10c4effedce2a48c34bfa23',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240321001467',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240321001467-ofs',
      manifestDigest:
          '20a7a4bee5a52def06486aaf2acd976f793b3d77d4cc8e781574bf20de2a4198',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250318000656',
      corpCode: '00978075',
      companyName: '(주)머니무브',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250318000656-ofs',
      manifestDigest:
          'ff7902a7472fc569ee33daf93635711d87f4c09ecd57eafeaa8b8c368b3686be',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250320000656',
      corpCode: '01116380',
      companyName: '(주)씨앤에스링크',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250320000656-ofs',
      manifestDigest:
          '29d9486d16e2defff57653d7c7364a2df8b35492ebba3bacb2eb5033528b318d',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321000943',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321000943-ofs',
      manifestDigest:
          '8a0862b12295c37500b6f067ef9f1a8d97575ecf95e9621f503dbfe22657cd73',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321001155',
      corpCode: '01680131',
      companyName: '(주)아이오바이오',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321001155-ofs',
      manifestDigest:
          'e4fd4ad74b59c7fcd24a324bb732c406fd6a0dd78145cb1f5eb62f15c3fbd318',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321001385',
      corpCode: '01034730',
      companyName: '크로넥스(주)',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321001385-ofs',
      manifestDigest:
          '3c60442e6215ef44ee697f400bb79466c39e90d8ad3351526fc0352ab77b0c46',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323000673',
      corpCode: '01063237',
      companyName: '(주)플럼라인생명과학',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260323000673-ofs',
      manifestDigest:
          '9a1b4f509f34c437e61b2abae61371b119fdecadc1de048cdb06c5db0fa8264f',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260323001028',
      corpCode: '00611286',
      companyName: '(주)블루탑',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260323001028-ofs',
      manifestDigest:
          'bbda4e8bc9b857db3d9485256fd8e81b31e256a9b515698aa7c5bb441cf1b863',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20240319000287',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2023,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20240319000287-cfs',
      manifestDigest:
          '606510ba7f33eccf95ee72098282cb03789fad1f23b8202a65ad83715d738408',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230714000217',
      corpCode: '01085442',
      companyName: '(주)오건에코텍',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230714000217-cfs',
      manifestDigest:
          'b7f1fdbdd411241e33d6111de2f8c7dde905e7a71b6d08409acff0eda88e8f11',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230315000460',
      corpCode: '00124805',
      companyName: '(주)푸른저축은행',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230315000460-cfs',
      manifestDigest:
          '2b4a6a18f38b0428287229a61478982c78cd6e0b0670f9d3024a8df6ebb7f25a',
      ruleVersion: 'pureun-exact-colon-primary-none-v1',
      absenceLiteral: ': 해당사항 없음',
      requiresIssuerOverview: true,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230714000217',
      corpCode: '01085442',
      companyName: '(주)오건에코텍',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230714000217-ofs',
      manifestDigest:
          '3edb4b03a58ef810f82783ac49123569be0f14fe18ab026799d5d531e51a4a89',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240319000287',
      corpCode: '00321204',
      companyName: '지에이이노더스(주)',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240319000287-ofs',
      manifestDigest:
          '859889a6635e71d000b975714b83a7cfba5832c523e8e305cd067eb4aece1aca',
      ruleVersion: 'primary-historical-issuer-whole-seven-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20230315000460',
      corpCode: '00124805',
      companyName: '(주)푸른저축은행',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230315000460-ofs-six',
      manifestDigest:
          'e9244070d8c44343a9434546a2af9091a38dcc75649d01a16ace1b2cdc9c73b1',
      ruleVersion: 'pureun-exact-six-primary-raw-ce-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260331004637',
      corpCode: '01353848',
      companyName: '(주)이노벡스',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20260331004637-cfs',
      manifestDigest:
          '860e0517968f3d135fef46c645d0972607496b666acde1ef05ba18b069316a90',
      ruleVersion: 'innovex-exact-table-basis-absence-v1',
      absenceLiteral: '해당사항없음',
    ),
    AnnualSourceCacheEntry(
      receipt: '20260331004637',
      corpCode: '01353848',
      companyName: '(주)이노벡스',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260331004637-ofs',
      manifestDigest:
          'b9113e16adfae70150eada4410889a5ee3e135ceb2588c0011c64534241b9e20',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250318000507',
      corpCode: '01281541',
      companyName: '(주)에피바이오텍',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250318000507-ofs-audit',
      manifestDigest:
          '0dd5d276f0250c917b2e5811e67e5be0466ce326a8db56f8e14452bed357a3b9',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260326000605',
      corpCode: '01139497',
      companyName: '주식회사 에스제이켐',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260326000605-ofs-audit',
      manifestDigest:
          'fa91eb53273f49231f8fc1a3e00dffd79905384b21248f60dd45153555a74473',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321001749',
      corpCode: '00366517',
      companyName: '(주)케이씨산업',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321001749-ofs-audit',
      manifestDigest:
          '62507ae47740ef6e90c941bda61ba955ce15bac1ba70eed707c19661621e01c6',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240320000531',
      corpCode: '00663289',
      companyName: '위월드(주)',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240320000531-ofs-audit',
      manifestDigest:
          '5d5c8b02196fc40f3691b4e496db02049223060a2928e0a0059bba383f99930e',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250407004206',
      corpCode: '00414540',
      companyName: '대주이엔티(주)',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250407004206-ofs-audit',
      manifestDigest:
          'a9508331d9aad30682d1e057eb4198dcf821036a1ae14773cb10802a232f5f0f',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250328001780',
      corpCode: '01563667',
      companyName: '(주)더즌',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250328001780-cfs',
      manifestDigest:
          '2e0f1abccb7098ddde384ba98a1b47f1d14f9294f8c15ffaae85232ac3a6e962',
      ruleVersion: 'dozn-exact-cover-ce-cash-cfs-v1',
      absenceLiteral: null,
      requiresIssuerOverview: false,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230320000571',
      corpCode: '01267958',
      companyName: '주식회사 프로티아',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230320000571-cfs',
      manifestDigest:
          '4b416ccec3c5d967a939b8e9dfcda9913e31370485dec224125d236d9cc9fe13',
      ruleVersion: 'exact-issuer-CFS-explicit-none-v1',
      absenceLiteral: '당사는 연결대상 종속회사가 존재하지 않으므로, 한국채택국제회계기준의 주된 재무제표인 연결기준의 재무정보를 기재하지 않습니다.',
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230317000589',
      corpCode: '01113499',
      companyName: '(주)아이티센피엔에스',
      year: 2022,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20230317000589-cfs',
      manifestDigest:
          '27acf6db60c7483886ce589f126718fb88d3f59a29f98fc79988e4c14666c751',
      ruleVersion: 'exact-issuer-CFS-explicit-none-v1',
      absenceLiteral: '당사는 사업보고서 제출기준일 현재 해당사항 없습니다.',
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321001825',
      corpCode: '00990396',
      companyName: '(주)레드우즈',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250321001825-cfs',
      manifestDigest:
          'eaa4a5fcffef55deb04277cf6f317cbccb935339b372b6ec2627ac706652656b',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250320001633',
      corpCode: '01188730',
      companyName: 'SK시그넷(주)',
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20250320001633-cfs',
      manifestDigest:
          '67c62fe957c07d3d5a3266dbf258c50423eef88adc8011d774ad1f1419346a8f',
      ruleVersion: 'sk-signet-exact-consolidated-source-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240320000248',
      corpCode: '01507810',
      companyName: '애니메디솔루션 주식회사',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240320000248-ofs',
      manifestDigest:
          'd632b2421d0db1e3121ee5cb1ae7c32d249673f8c09b4f13a37c5636a87bd544',
      ruleVersion: 'animedi-exact-ce-separator-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230323000586',
      corpCode: '01507810',
      companyName: '애니메디솔루션 주식회사',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230323000586-ofs',
      manifestDigest:
          '4e88cc22cd3a4fc6e269b289135bd52cc08b7a020992a6ab8d4efe641f4ba8e3',
      ruleVersion: 'animedi-exact-ce-separator-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230317000589',
      corpCode: '01113499',
      companyName: '(주)아이티센피엔에스',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230317000589-ofs',
      manifestDigest:
          'd8d42047c961229821229c6a3f27bb114c1185a4587550de1d2fdf77436718d7',
      ruleVersion: 'itcen-exact-primary-title-notice-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230320000571',
      corpCode: '01267958',
      companyName: '주식회사 프로티아',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230320000571-ofs',
      manifestDigest:
          '3d4440f7426f4f83842bb2f95ed53dd223b803f451113ffbc720a56a37a41152',
      ruleVersion: 'protia-printed-current-full-period-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250321001825',
      corpCode: '00990396',
      companyName: '(주)레드우즈',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250321001825-ofs',
      manifestDigest:
          '85abe4e38762fe4ae48ff4607a4abbfee4b65c405a961e9e0fed50914921402d',
      ruleVersion: 'redwoods-exact-blank-header-CE-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250320001633',
      corpCode: '01188730',
      companyName: 'SK시그넷 주식회사',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250320001633-ofs',
      manifestDigest:
          '4af751dc147cf412979eb5f238166b78c8f878c2458edfb74c37e353438509da',
      ruleVersion: 'sk-signet-direct-rename-event-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250328001780',
      corpCode: '01563667',
      companyName: '(주)더즌',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250328001780-ofs',
      manifestDigest:
          '15d5fb21359a75b1680eb1d699a7f8cc3768cb53645395b85a35e01945f62360',
      ruleVersion: 'dozn-exact-cover-ce-cash-corroboration-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260316001455',
      corpCode: '00445869',
      companyName: '(주)유니포인트',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260316001455-ofs',
      manifestDigest:
          '1bb3549b45b4a7a9ed87fcb8a726a08d5fceba24d51935b6664ef0d0a6b1274a',
      ruleVersion: 'verified-standard-annual-eight-core-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260326000677',
      corpCode: '01290132',
      companyName: '주식회사 인터로이드',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260326000677-ofs',
      manifestDigest:
          '8454f74ea0318b0de07318a7b70f8c456044320b9fc82b994c1ab934d646e49c',
      ruleVersion: 'verified-standard-annual-eight-core-v1',
      absenceLiteral: null,
    ),

    AnnualSourceCacheEntry(
      receipt: '20260327001807',
      corpCode: '01018617',
      companyName: '(주)메디쎄이',
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20260327001807-cfs',
      manifestDigest:
          '00225c89f1ddca77ccb45f60113fb9669c8edc0a36ca8268e9b1f2eed6e31563',
      ruleVersion: 'medyssey-exact-CF-current-header-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20260309001820',
      corpCode: '01205514',
      companyName: '(주)큐라켐',
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20260309001820-ofs-audit',
      manifestDigest:
          'ac70052d7ba6516a5c8331ece9c9af8c3c6d3e6c7de722d6e09904ec3fdc85ef',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240321000933',
      corpCode: '01206717',
      companyName: '(주)마이크로엔엑스',
      year: 2023,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20240321000933-cfs-audit',
      manifestDigest:
          'c45e30742851582e98865e412d4d490e9e9df826dfa084fd9461459bef816628',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20250319000477',
      corpCode: '01518506',
      companyName: '(주)타조이엔터테인먼트',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250319000477-ofs',
      manifestDigest:
          '0a2cb730752e8c50e46d95550125a539ed2429b46822da21b085d872b9025c84',
      ruleVersion: 'tajoy-exact-dot-cover-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20240401000698',
      corpCode: '01229240',
      companyName: '(주)가이아코퍼레이션',
      year: 2023,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20240401000698-ofs-audit',
      manifestDigest:
          '038df934bb06262ac308a300e88f14f9f1564ada362ed63ee4f0517e0f4af1ca',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220315000038',
      corpCode: '01035942',
      companyName: '(주)메디안디노스틱',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220315000038-cfs-audit',
      manifestDigest:
          '0453c972c5618d4406878a7fe195a382522d32128164c4b01fe18bbe9fc47399',
      ruleVersion: 'same-receipt-audit-immutable-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230315000997',
      corpCode: '01601222',
      companyName: '씨피시스템(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230315000997-ofs',
      manifestDigest:
          'c864059c2a2a33177784905c4c1e57edcc25dad9f54043d279aee121b03f855c',
      ruleVersion: 'spac-explicit-revenue-null-cache-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230308000311',
      corpCode: '01476219',
      companyName: '(주)코스텍시스',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230308000311-ofs',
      manifestDigest:
          '29ddb7e5f721caec0b36f04b12478f00173a2b91d94fb2e94215c3ed4cc7121a',
      ruleVersion: 'spac-explicit-revenue-null-cache-v1',
      absenceLiteral: null,
      requiresIssuerOverview: true,
    ),
    AnnualSourceCacheEntry(
      receipt: "20250331002057",
      corpCode: "01229240",
      companyName: "(주)가이아코퍼레이션",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250331002057-cfs",
      manifestDigest:
          "a8457d556b131ab040bc233a9ab0dd19099d6ba2a4aa8f64b5e1abcd7593848f",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: "20250331002057",
      corpCode: "01229240",
      companyName: "(주)가이아코퍼레이션",
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: "assets/financial_source_cache/20250331002057-ofs",
      manifestDigest:
          "8bbdba06bd9c18d61c390410ecdd95f56a199a03c3f39eaec7e561111e177c80",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: "20250321001451",
      corpCode: "00541862",
      companyName: "(주)판도라티비",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250321001451-cfs",
      manifestDigest:
          "1a48e88927a9acc8e75a6f28c5c67f185b1a9a7c39fa6ca75a0a5c26183c7d22",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: "20260323000661",
      corpCode: "01262023",
      companyName: "(주)루트락",
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: "assets/financial_source_cache/20260323000661-ofs",
      manifestDigest:
          "a25a08b334124b420295291956cf88b21b3cfb5a3c064ea11306ff596882ac87",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: "20260323000876",
      corpCode: "01352575",
      companyName: "바이오텐(주)",
      year: 2025,
      basis: FsDiv.separate,
      assetDirectory: "assets/financial_source_cache/20260323000876-ofs",
      manifestDigest:
          "a114468d65371a12c4ffa34cf8d3550d5fb61aa48270e66152acdcd050743aa4",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: "20260323000763",
      corpCode: "01119651",
      companyName: "(주)엘리비젼",
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20260323000763-cfs",
      manifestDigest:
          "da11b0709d385042e48cd432589cf3083040a5c8a83b33d6b5ee84aa11abade1",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "해당 사항 없음",
    ),
    AnnualSourceCacheEntry(
      receipt: "20250710000060",
      corpCode: "00445869",
      companyName: "(주)유니포인트",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250710000060-cfs",
      manifestDigest:
          "2abbd57b59da076900b4dd7180708e128fd30dbb5c5ca064be0aa779558e1c3d",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "- 해당사항 없음",
    ),
    AnnualSourceCacheEntry(
      receipt: "20250321001022",
      corpCode: "01023822",
      companyName: "(주)메디젠휴먼케어",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250321001022-cfs",
      manifestDigest:
          "d395a53ba1f741799df21c84a95ec8632b7b355d630d8a825ee3e08ebd5d7467",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "- 해당사항이 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: "20250321001939",
      corpCode: "01156795",
      companyName: "(주)프로젠",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250321001939-cfs",
      manifestDigest:
          "6393f8659cb6579337b7f286103847218e1992a4debb11b358f6a91e17712fb3",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "- 당사는 보고서 제출일 현재 해당사항이 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: "20250321001395",
      corpCode: "01363924",
      companyName: "(주)한국미라클피플사",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250321001395-cfs",
      manifestDigest:
          "ff16624964bee00b5082e81ece99529e78408b2f01476e78c628cfb69e7361f9",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "당사는 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: "20250321000819",
      corpCode: "00929228",
      companyName: "(주)엔에스컴퍼니",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250321000819-cfs",
      manifestDigest:
          "825bab7a7c63682a6107b926777f393d3906019eff166c568d49a43cd12a564f",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "- 해당사항 없음.",
    ),
    AnnualSourceCacheEntry(
      receipt: "20250321000661",
      corpCode: "01345724",
      companyName: "주식회사 타임기술",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20250321000661-cfs",
      manifestDigest:
          "f7e5aeddbb8b68b88127ada87f24c207fb4affc7af7a33b3d4b4ed00052212eb",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "본보고서 작성기준일 현재 해당사항이 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: "20240328001866",
      corpCode: "01085187",
      companyName: "(주)씨알푸드",
      year: 2023,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/20240328001866-cfs",
      manifestDigest:
          "7983ff5a0d472590697debb11df73c2e72bffa5dae7f475a5214d30a8e794b47",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: "당사는 해당사항 없습니다.",
    ),
    AnnualSourceCacheEntry(
      receipt: '20250320001369',
      corpCode: '01353848',
      companyName: '(주)이노벡스',
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20250320001369-ofs',
      manifestDigest:
          '32b19ee0512bbdfd5b6ffb247752a5c8c42cc05f88e424a96975eda5230d5376',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: "20250326000875",
      corpCode: "01085187",
      companyName: "(주)씨알푸드",
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: "assets/financial_source_cache/20250326000875-ofs",
      manifestDigest:
          "1ec70860618bbe3d31b28465aaebdde0de4f2a1108c6dc569136d0cbdbc17447",
      ruleVersion: "exact-annual-cache-registry-v1",
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: "20260323001652",
      corpCode: "01020269",
      companyName: "(주) 탈로스",
      year: 2025,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/talos-cfs-2025",
      manifestDigest:
          "039849225de164921a9aeb65fa3458fadcbe6574b4ab56e6bb035b7084e6ebf4",
      ruleVersion: "talos-cfs-pure-literal-v1",
      absenceLiteral: "해당사항 없음",
    ),
    AnnualSourceCacheEntry(
      receipt: "20250321001900",
      corpCode: "00765897",
      companyName: "한국피아이엠",
      year: 2024,
      basis: FsDiv.consolidated,
      assetDirectory: "assets/financial_source_cache/pim-cfs-2024",
      manifestDigest:
          "c964aef1f97af016e1d54595c8b05c5fb5762bc80ab02cc363b504ea1c62ac80",
      ruleVersion: "pim-cfs-whole-ce-v1",
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220317000866',
      corpCode: '00123772',
      companyName: '부국증권(주)',
      year: 2021,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20220317000866-ofs',
      manifestDigest:
          '6538d0cf5c50724aafe471dc4ca315bfa749593f33cac99dac223a90b6617cdf',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230328000107',
      corpCode: '00123772',
      companyName: '부국증권(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230328000107-ofs',
      manifestDigest:
          'c7a3b0f55810e28f53bd68cd0a5d8278fedbe93312ec02812b72e7d8c0aa9394',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20230322000366',
      corpCode: '00442631',
      companyName: '태양기계(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20230322000366-ofs',
      manifestDigest:
          '1e0e1ad7733d6376c9d1ac69fc1c640e35b1165cf8e5f425a36f01b52dcbe4e8',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20231018000215',
      corpCode: '01352575',
      companyName: '바이오텐(주)',
      year: 2022,
      basis: FsDiv.separate,
      assetDirectory: 'assets/financial_source_cache/20231018000215-ofs',
      manifestDigest:
          'e40ffdadbde0fce98afa2453235c4c10e23c11803dbeee93429f209e97f0a19d',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
    AnnualSourceCacheEntry(
      receipt: '20220318000715',
      corpCode: '01065785',
      companyName: '(주)노브메타파마',
      year: 2021,
      basis: FsDiv.consolidated,
      assetDirectory: 'assets/financial_source_cache/20220318000715-cfs',
      manifestDigest:
          'b60b828a55787036a9137ce5bbcf146dffa673601730c16b7355213911ba2397',
      ruleVersion: 'verified-current-period-whole-annual-v1',
      absenceLiteral: null,
    ),
  ];
  static AnnualSourceCacheEntry? find(String receipt, FsDiv basis) {
    for (final entry in entries) {
      if (entry.receipt == receipt && entry.basis == basis) return entry;
    }
    return null;
  }
}
