import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One exact primary CFS section; does not generalize colon absence grammar.
abstract final class PureunExactBasisAbsence {
  static const receipt = '20230315000460';
  static const corp = '00124805';
  static const evidence = ': 해당사항 없음';
  static const statementUrl =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000460&dcmNo=9057394&eleId=17&offset=137261&length=142&dtd=dart3.xsd';
  static bool matches({
    required String receipt,
    required String corp,
    required Uri shellSource,
    required String shell,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required String cover,
    required Uri statementSource,
    required String body,
  }) {
    if (receipt != PureunExactBasisAbsence.receipt ||
        corp != PureunExactBasisAbsence.corp ||
        start != DateTime.utc(2022) ||
        end != DateTime.utc(2022, 12, 31) ||
        shellSource !=
            Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
              'rcpNo': receipt,
            }) ||
        sha256.convert(utf8.encode(shell)).toString() !=
            'ccbe266d86938e9b79cf00ee806ed59e1caf04eabf06098ad5367690597f7a83' ||
        coverSource.toString() !=
            'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000460&dcmNo=9057394&eleId=1&offset=814&length=4035&dtd=dart3.xsd' ||
        sha256.convert(utf8.encode(cover)).toString() !=
            '535cde2bfccf39b211ea8587cc5c8d9bbcd2dc247edf9b864451a98742bfa270' ||
        statementSource.toString() != statementUrl ||
        sha256.convert(utf8.encode(body)).toString() !=
            'cf005f3305904d45d46b12c425f201e2154565a66d0b6fa55eff4f68f02426ae') {
      return false;
    }
    final sections = RegExp(
      r'<body\b[^>]*>(.*?)</body>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(body).toList();
    if (sections.length != 1 ||
        RegExp(
          r'<(?:table|script|style)\b',
          caseSensitive: false,
        ).hasMatch(sections.single[1]!)) {
      return false;
    }
    final plain = sections.single[1]!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', '')
        .replaceAll(RegExp(r'\s+'), '');
    return plain == '2.연결재무제표:해당사항없음';
  }
}
