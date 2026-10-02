import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two immutable same-receipt official attachment profiles. No date correction
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
      'mainStatementConflict':
          'main CIS prints an inconsistent end year; no raw date is corrected',
      'periodStart': '${p.year}-01-01',
      'periodEnd': '${p.year}-12-31',
    };
  }
}
