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
  ];
  static AnnualSourceCacheEntry? find(String receipt, FsDiv basis) {
    for (final entry in entries) {
      if (entry.receipt == receipt && entry.basis == basis) return entry;
    }
    return null;
  }
}
