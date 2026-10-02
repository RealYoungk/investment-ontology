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
  });
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
  String get statementLabel => basis == FsDiv.consolidated ? 'cfs' : 'ofs';
  String get auditReference =>
      'financial-cache-replay:$manifestDigest:$receipt:${basis.name}:$ruleVersion';
}

abstract final class VerifiedAnnualSourceRegistry {
  static const entries = <AnnualSourceCacheEntry>[
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
      receipt: "20250320001369",
      corpCode: "01353848",
      companyName: "(주)이노벡스",
      year: 2024,
      basis: FsDiv.separate,
      assetDirectory: "assets/financial_source_cache/20250320001369-ofs",
      manifestDigest:
          "6662ccdfa7589ee3afbf2486a4ecd1d1732047cbebd1708a306aca04a651f82c",
      ruleVersion: "exact-annual-cache-registry-v1",
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
  ];
  static AnnualSourceCacheEntry? find(String receipt, FsDiv basis) {
    for (final entry in entries) {
      if (entry.receipt == receipt && entry.basis == basis) return entry;
    }
    return null;
  }
}
