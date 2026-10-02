import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable same-receipt official attachment profiles. No date correction
/// or inferred earlier filing is allowed. Main cover and attached statements
/// retain their own document coordinates and raw hashes.
abstract final class SameReceiptAuditSource {
  static String _sha(String raw) => sha256.convert(utf8.encode(raw)).toString();
  static const profiles =
      <
        String,
        ({
          String corp,
          int year,
          bool consolidated,
          String cover,
          String coverSha,
          String shellSha,
          String auditShell,
          String auditShellSha,
          String statement,
          String statementSha,
        })
      >{
        '20250317000704': (
          corp: '00963000',
          year: 2024,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250317000704&dcmNo=10414791&eleId=1&offset=954&length=4722&dtd=dart4.xsd',
          coverSha: 'c6b71098e75b306dbab1792393e253aad54e1aec41a137ae983fc28a1494ef4a',
          shellSha: '1ee71512f98bee1c42009326d7ad4290eb347c32d2b965afb9d7c7cc36dda4e5',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250317000704&dcmNo=10414790',
          auditShellSha: '53584ca9518ecc64ad6247a4f5f418cde91f8a02254734283cbd2a5da26c4625',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250317000704&dcmNo=10414790&eleId=3&offset=9244&length=228268&dtd=dart4.xsd',
          statementSha: '92ea7ec5bc69f52d3d2a4496826d2039666d4f15a1bdfe41f06de1e19caa5250',
        ),

        '20220315001280': (
          corp: '00340096',
          year: 2021,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315001280&dcmNo=8462646&eleId=1&offset=797&length=3959&dtd=dart3.xsd',
          coverSha: 'f25bd230bf0047e0c122eb6965870903a4f3909a11ab85917dc2849f238fd6ca',
          shellSha: '116d6425df1d5270f329ab820aa58f3495f02011714cfd86c4197189e0cb799d',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220315001280&dcmNo=8462644',
          auditShellSha: 'd0d8ecb95f9e2ddf09b4647dcdb1c32bbb385a43c69212b91a7be03d31b5c552',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315001280&dcmNo=8462644&eleId=3&offset=16738&length=483305&dtd=dart3.xsd',
          statementSha: '547d919773375db303eab00ca9943009f5b780a2d09e7c985724d1e51500418e',
        ),
        '20230315001270': (
          corp: '00340096',
          year: 2022,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315001270&dcmNo=9060736&eleId=1&offset=800&length=3924&dtd=dart3.xsd',
          coverSha: '7e9a2fc8b97a419a5012b81e16154570a041f09da4801b61cc1c15c9b0d507ca',
          shellSha: '37314f8f3e01e67417fc7dc8afcecc3512e019033bfdc742752fe0e9a3737568',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230315001270&dcmNo=9060734',
          auditShellSha: '12d02a03a7932b0853cc9b5a8500ab6d6867e9441712906117da3ece002f24a2',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315001270&dcmNo=9060734&eleId=3&offset=14194&length=479082&dtd=dart3.xsd',
          statementSha: '5edf7a44d97504449e573eb3d60c90854e750001985a6c3806a6eef134513915',
        ),
        '20240320001438': (
          corp: '00963000',
          year: 2023,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001438&dcmNo=9740410&eleId=1&offset=954&length=4592&dtd=dart4.xsd',
          coverSha: '779a3a6cff8c09e3ed3660cd48e812803e0ecc623fc20736c8c4887e30734363',
          shellSha: '966668f96cd047795a1f6b8c2ae2a2226c587ecd743fd867f69df14c77eb0ae9',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240320001438&dcmNo=9740409',
          auditShellSha: '22d5a9768d793b9a5cf9fcb89c5f6f35b1bbbbc0d00c39b93bd9dcf04f297c92',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320001438&dcmNo=9740409&eleId=3&offset=8923&length=226646&dtd=dart4.xsd',
          statementSha: '94eb126c85b927dab64401a05655628ed0774686d946e5694045fd169c38ff11',
        ),

        '20260331004637': (
          corp: '01353848',
          year: 2025,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260331004637&dcmNo=11214858&eleId=1&offset=966&length=4501&dtd=dart4.xsd',
          coverSha: '8ec3dd27078969973fe62845b9f1291c356e7eaf55fcd5329283cf47d5d31f13',
          shellSha: 'e4a204f7b2d3c9728718e048093aee7da406f4652958c302da9caea895e5bd55',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260331004637&dcmNo=11214857',
          auditShellSha: '83c1c13555022cc4e063c4e4291e619508b5ffb33e23db73f6c37cd22669a035',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260331004637&dcmNo=11214857&eleId=3&offset=10407&length=362889&dtd=dart4.xsd',
          statementSha: 'e4ed7d6fe2972a93f83850a4851703e9e5b1ed0fb6f6bfffbe77998bcc989d3a',
        ),
        '20260326000605': (
          corp: '01139497',
          year: 2025,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260326000605&dcmNo=11181548&eleId=1&offset=968&length=4510&dtd=dart4.xsd',
          coverSha: '5c3eb5213fc6604378086b3d197f3c0df17999f5e2b0b46c73d3e9f577e6de9e',
          shellSha: 'f5403eafe39b869fe2c6cd8dacfa89fccb69fcb54d442a4a5b59bd3ff4a28c10',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260326000605&dcmNo=11181547',
          auditShellSha: '22ab8e0120c7c961e7bccae2d6a5afdf094216ca098fe81eddd5d2fb493337e1',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260326000605&dcmNo=11181547&eleId=3&offset=11960&length=284718&dtd=dart4.xsd',
          statementSha: '5e2477a86b076214e1202442ac519839f146a367e9e64de9127586564858fe9d',
        ),
        '20240320000531': (
          corp: '00663289',
          year: 2023,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320000531&dcmNo=9734828&eleId=1&offset=951&length=4019&dtd=dart4.xsd',
          coverSha: '63ac5c0c71119bc54a7b07a0490314edb16b8131873524173f7f67a63329b808',
          shellSha: '81aa7ce62bb5eb32e0d215e3a6b2c2b220e98d0df798d8f31317867f2061ac76',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240320000531&dcmNo=9734827',
          auditShellSha: '81d09a6e3351ee12cfcee4ef2d37eae9294f06e6ac0a79fa7302040f87c75e9a',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240320000531&dcmNo=9734827&eleId=3&offset=9072&length=272623&dtd=dart4.xsd',
          statementSha: '56511bd096ce263eb303a6aec63b7e9cece305eb80b3f2da4186d90ff131ba6d',
        ),
        '20250318000507': (
          corp: '01281541',
          year: 2024,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250318000507&dcmNo=10419136&eleId=1&offset=957&length=4544&dtd=dart4.xsd',
          coverSha: '8b6e80b18b37ea28fae1a462a29d2f1cbc774190bc03c903d62dac1791c6aa60',
          shellSha: 'e8c70658c99e9fdc03020e4b16757ff85dc1072d5ca0d05cbf96badd9eb9a776',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250318000507&dcmNo=10419135',
          auditShellSha: '04c7b73af864f78f3b7974f96b84655abb9f23ac62ae905079a487b2fd4793ea',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250318000507&dcmNo=10419135&eleId=3&offset=13634&length=226264&dtd=dart4.xsd',
          statementSha: '37d77e3dce3cb17fac914b450a48efe995d91ab3b81454e5e2d3d2ee98eac84f',
        ),
        '20250321001749': (
          corp: '00366517',
          year: 2024,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321001749&dcmNo=10449824&eleId=1&offset=956&length=4515&dtd=dart4.xsd',
          coverSha: '20eb000cbd59f04578d34ad8f51da88e8d2236467f7778d654ee5c6a656dabac',
          shellSha: '21ba2d9c70e69ea23810af4590f690fb0ebf2ba90ef9a12408dcd9d1a1cd50d4',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250321001749&dcmNo=10449823',
          auditShellSha: '147f35bae812cfd03160fe1f17d51a0ab30c80eb35ebbe2de270effa59ea29ee',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321001749&dcmNo=10449823&eleId=3&offset=11681&length=485766&dtd=dart4.xsd',
          statementSha: '90be48ae9f543c2f3eacdb10cd30d05f03bf7e38d4dac2533f466d11a39dfd18',
        ),
        '20250407004206': (
          corp: '00414540',
          year: 2024,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250407004206&dcmNo=10552120&eleId=1&offset=957&length=4523&dtd=dart4.xsd',
          coverSha: 'a879b6466261e9687fe7a7810ba374b813e3001388f94fd773c56d4cd9c9f241',
          shellSha: 'be2400f94a412a701299427432cf5bab20cfe609da80456059874fe136bb9716',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250407004206&dcmNo=10552118',
          auditShellSha: 'c115d8c4841181670d3429888c9539db55164704a9f8129180753c67670f924f',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250407004206&dcmNo=10552118&eleId=3&offset=13040&length=412264&dtd=dart4.xsd',
          statementSha: '39407fdf69db473a95073f8eb06d22b8e303c5f066c6b96a2b34bf4d0b52d8a5',
        ),
        '20250321001825': (
          corp: '00990396',
          year: 2024,
          consolidated: true,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321001825&dcmNo=10450233&eleId=1&offset=941&length=4572&dtd=dart4.xsd',
          coverSha: '696165e71f7637724caa97c6111151161e02b825778dfe10c9e20ba00ad0925a',
          shellSha: '823435d92599722683943aba9ab9e8d05f00039b4639c5ae949768f6337f451f',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20250321001825&dcmNo=10450232',
          auditShellSha: 'd32f8c204641b32d9e2ab7f70619cbfc6bf3adc54619490a8ecab1711c0c29fd',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250321001825&dcmNo=10450232&eleId=3&offset=11140&length=410842&dtd=dart4.xsd',
          statementSha: 'ba4464ec6f7ac21b6627e95aae17fc8051809fc70399df985d2dcc5916dacf48',
        ),
        '20260309001820': (
          corp: '01205514',
          year: 2025,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260309001820&dcmNo=11101399&eleId=1&offset=967&length=4517&dtd=dart4.xsd',
          coverSha: '579d370d7615d73b911a9815fc0ae8cb768b34703cfa4edcc34f3f361630e958',
          shellSha: '5c6664eea671901321f7927b809378806fa339020308e534b61e53e0b7b98b08',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260309001820&dcmNo=11101398',
          auditShellSha: '10e45cee1a4baa18f330c627ac0f0c6d4339d65ed0acac0870742dc13ba76ab2',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260309001820&dcmNo=11101398&eleId=3&offset=13577&length=191794&dtd=dart4.xsd',
          statementSha: 'eac6fe6ec2c8de35595ae83679aac55e3d649b9e37915a9555023e5aa305adff',
        ),
        '20240321000933': (
          corp: '01206717',
          year: 2023,
          consolidated: true,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240321000933&dcmNo=9748926&eleId=1&offset=952&length=4096&dtd=dart4.xsd',
          coverSha: 'f9b3ac9d9bf3ef514f8f8383fc465522a6a748c631c7a68fbc2a902c35a1b99b',
          shellSha: 'e0470da3b22112b61938dc66725e2db2e530392b80824b806e3aca97146bd397',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240321000933&dcmNo=9748925',
          auditShellSha: 'bba1c27bda19afd261ba3a535b5be4c55670360661fb560ee9c65ed654f5d248',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240321000933&dcmNo=9748925&eleId=3&offset=11318&length=303186&dtd=dart4.xsd',
          statementSha: 'a2653cd002f967ea82a1d99fc2eae7fea50884e1f98f2db6fafe9e952aa87d18',
        ),
        '20240401000698': (
          corp: '01229240',
          year: 2023,
          consolidated: false,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240401000698&dcmNo=9793407&eleId=1&offset=967&length=4053&dtd=dart4.xsd',
          coverSha: '3073cfe0761f9ea5224fa6ff486a367068686f2c1285696bdae4dfc46a7e2ee4',
          shellSha: '39c32ff140ef3cdc6b1244ce6dcf8f43e78f469c25cf2121371b1311dcc5411e',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20240401000698&dcmNo=9792565',
          auditShellSha: '7c575bd4df3018309680e8f001ba619ff89e8571e9bd0ad475fe2457c406a784',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20240401000698&dcmNo=9792565&eleId=3&offset=11206&length=268957&dtd=dart4.xsd',
          statementSha: 'd556b6da379c326f2608417f64cd14db5744e23341d04b5daad00c9f05f2967c',
        ),
        '20220315000038': (
          corp: '01035942',
          year: 2021,
          consolidated: true,
          cover: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315000038&dcmNo=8458314&eleId=1&offset=801&length=4039&dtd=dart3.xsd',
          coverSha: 'a46453d9c9ae7398d12d7d73494c367ca40f74fc82a52cdee6ad60898aa933a9',
          shellSha: '26c51e0e227cf2998245524bed52e2947ecd3d8b8b3534ccf7f0312df975538d',
          auditShell: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20220315000038&dcmNo=8458313',
          auditShellSha: 'fb4bad7e532f4aaf5319982335825a5c99eecd8d067ff0cc3809d32cf0695d9f',
          statement: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220315000038&dcmNo=8458313&eleId=3&offset=11924&length=300733&dtd=dart3.xsd',
          statementSha: '1eb057bca6a30926138f2c75b563d51aa4ce10e67a477758e561f7d622b8e9a5',
        ),
      };
  static bool eligible({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
  }) {
    final p = profiles[receipt];
    return p != null &&
        p.corp == corpCode &&
        p.consolidated == consolidated &&
        start == DateTime.utc(p.year) &&
        end == DateTime.utc(p.year, 12, 31);
  }

  static Uri auditShell(String receipt, String mainShell) {
    final p = profiles[receipt];
    if (p == null || _sha(mainShell) != p.shellSha) {
      throw const FormatException('Unverified same-receipt attachment family');
    }
    return Uri.parse(p.auditShell);
  }

  static Uri statement(String receipt, String auditShell) {
    final p = profiles[receipt];
    if (p == null || _sha(auditShell) != p.auditShellSha) {
      throw const FormatException('Unverified same-receipt audit shell');
    }
    return Uri.parse(p.statement);
  }

  static bool bound({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required String coverHtml,
    required Uri statementSource,
    required String statementHtml,
  }) {
    final p = profiles[receipt];
    return eligible(
          receipt: receipt,
          corpCode: corpCode,
          consolidated: consolidated,
          start: start,
          end: end,
        ) &&
        p != null &&
        coverSource.toString() == p.cover &&
        _sha(coverHtml) == p.coverSha &&
        statementSource.toString() == p.statement &&
        _sha(statementHtml) == p.statementSha;
  }

  /// Only these three immutable attachments require this additional direct CE proof.
  static Map<String, dynamic>? verifiedWholeEquity(
    String receipt,
    String raw,
    BigInt equity,
    BigInt profit,
  ) {
    if (!const {
      '20250318000507',
      '20250321001749',
      '20250407004206',
    }.contains(receipt)) {
      return null;
    }
    if (_sha(raw) != profiles[receipt]!.statementSha) {
      throw const FormatException('Audit CE raw source changed');
    }
    String compact(String value) =>
        value.replaceAll(RegExp(r'<[^>]*>|\s+|&nbsp;'), '');
    final proofs = <Map<String, dynamic>>[];
    for (final table in RegExp(
      r'<TABLE\b[^>]*>(.*?)</TABLE>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(raw)) {
      final rows = [
        for (final tr in RegExp(
          r'<TR\b[^>]*>(.*?)</TR>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(table.group(1)!))
          [
            for (final cell in RegExp(
              r'<T[DH]\b([^>]*)>(.*?)</T[DH]>',
              caseSensitive: false,
              dotAll: true,
            ).allMatches(tr.group(1)!))
              (attributes: cell.group(1)!, text: compact(cell.group(2)!)),
          ],
      ];
      if (rows.isEmpty || rows.first.isEmpty || rows.first.last.text != '총계') {
        continue;
      }
      final starts = [
        for (var i = 1; i < rows.length; i++)
          if (rows[i].isNotEmpty && rows[i].first.text == '2024.01.01(당기초)') i,
      ];
      final ends = [
        for (var i = 1; i < rows.length; i++)
          if (rows[i].isNotEmpty && rows[i].first.text == '2024.12.31(당기말)') i,
      ];
      if (starts.isEmpty && ends.isEmpty) {
        continue;
      }
      if (starts.length != 1 ||
          ends.length != 1 ||
          starts.single >= ends.single) {
        throw const FormatException('Audit CE dates ambiguous');
      }
      final nets = [
        for (var i = starts.single + 1; i < ends.single; i++)
          if (rows[i].isNotEmpty &&
              {'당기순이익', '당기순손실'}.contains(rows[i].first.text))
            i,
      ];
      if (nets.length != 1) {
        throw const FormatException('Audit CE whole profit ambiguous');
      }
      BigInt total(int i) {
        final row = rows[i];
        if (row.length != rows.first.length ||
            row.any(
              (c) => RegExp(
                r'(?:rowspan|colspan)=["\x27]?[2-9]',
                caseSensitive: false,
              ).hasMatch(c.attributes),
            )) {
          throw const FormatException('Audit CE total shape mismatch');
        }
        final value = row.last.text;
        if (!RegExp(r'^\(?-?\d{1,3}(?:,\d{3})*\)?$').hasMatch(value)) {
          throw const FormatException('Audit CE amount invalid');
        }
        final amount = BigInt.parse(value.replaceAll(RegExp(r'[(),]'), ''));
        return value.startsWith('(') ? -amount : amount;
      }

      if (total(ends.single) != equity || total(nets.single) != profit) {
        throw const FormatException('Audit CE whole net/equity conflict');
      }
      proofs.add({
        'mode': 'immutable-three-audit-whole-CE-v1',
        'periodStart': '2024-01-01',
        'periodEnd': '2024-12-31',
        'currentProfit': profit.toString(),
        'closingEquity': equity.toString(),
        'printedCurrentProfit': rows[nets.single].last.text,
        'printedEndEquity': rows[ends.single].last.text,
        'statementSha256': _sha(raw),
        'source': profiles[receipt]!.statement,
      });
    }
    if (proofs.length != 1) {
      throw const FormatException('Audit CE proof missing or ambiguous');
    }
    return proofs.single;
  }

  static Map<String, dynamic> evidence(String receipt) {
    final p = profiles[receipt]!;
    return {
      'kind': 'same-receipt-official-audit-attachment',
      'receipt': receipt,
      'corpCode': p.corp,
      'basis': p.consolidated ? 'CFS' : 'OFS',
      'mainCoverSource': p.cover,
      'mainCoverSha256': p.coverSha,
      'auditShellSource': p.auditShell,
      'auditShellSha256': p.auditShellSha,
      'actualStatementSource': p.statement,
      'statementSha256': p.statementSha,
      'mainStatementConflict': switch (receipt) {
        '20260331004637' => 'main PL printed term conflicts with cover and current columns; no term or amount corrected',
        '20260326000605' => 'main BS liabilities and CE profit conflict; original cells unchanged',
        '20240320000531' =>
          'main BS asset total conflicts; original cells unchanged',
        '20250318000507' =>
          'main CF declared end precedes start; raw dates unchanged',
        '20250321001749' => 'main BS and CIS titles conflict with current term; raw titles unchanged',
        '20250407004206' =>
          'main dates absent and CF printed unit differs; raw units unchanged',
        '20250321001825' =>
          'main CE profit and OCI labels conflict; raw labels remain unchanged',
        '20260309001820' =>
          'main flow term differs from BS; no printed term is corrected',
        '20240321000933' =>
          'main CE prints an inconsistent end year; no raw date is corrected',
        _ =>
          'main CIS prints an inconsistent end year; no raw date is corrected',
      },
      'periodStart': '${p.year}-01-01',
      'periodEnd': '${p.year}-12-31',
    };
  }
}
