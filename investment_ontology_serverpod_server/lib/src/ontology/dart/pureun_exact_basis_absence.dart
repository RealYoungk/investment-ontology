import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Two exact own annual CFS sections; no generalized colon absence grammar.
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
    final own2021 = receipt == '20220308000292';
    final year = own2021 ? 2021 : 2022;
    if ((!own2021 && receipt != PureunExactBasisAbsence.receipt) ||
        corp != PureunExactBasisAbsence.corp ||
        start != DateTime.utc(year) ||
        end != DateTime.utc(year, 12, 31) ||
        shellSource !=
            Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
              'rcpNo': receipt,
            }) ||
        sha256.convert(utf8.encode(shell)).toString() !=
            (own2021
                ? '5b5e1b14eb3d91370410bfe494fa101f77eb8c217476fc1c1ee129c5a874499c'
                : 'ccbe266d86938e9b79cf00ee806ed59e1caf04eabf06098ad5367690597f7a83') ||
        coverSource.toString() !=
            (own2021
                ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220308000292&dcmNo=8445080&eleId=1&offset=811&length=4036&dtd=dart3.xsd'
                : 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230315000460&dcmNo=9057394&eleId=1&offset=814&length=4035&dtd=dart3.xsd') ||
        sha256.convert(utf8.encode(cover)).toString() !=
            (own2021
                ? '26baec5f40bbc13a62f3beeae66fe5dfe2f6171ba61b1af343c3cc48aa061cd3'
                : '535cde2bfccf39b211ea8587cc5c8d9bbcd2dc247edf9b864451a98742bfa270') ||
        statementSource.toString() !=
            (own2021
                ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20220308000292&dcmNo=8445080&eleId=17&offset=139044&length=142&dtd=dart3.xsd'
                : statementUrl) ||
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
