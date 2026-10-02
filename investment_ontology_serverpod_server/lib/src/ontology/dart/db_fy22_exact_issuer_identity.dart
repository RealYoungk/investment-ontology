import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class DbFy22ExactIssuerIdentity {
  static const hashes = {
    'shell': '31363c96892fea8b2f2fbce73dfb2a690d99d5efe8a3f2c109abb0cc0e32fce3',
    'cover': '3cc86ccee7cd434468865a4f32e1e0f1aa57472bf8d1fc53ed796d130050fe8d',
    'overview':
        '2275a53e257658356c9a048a47d76d3518500a98e523ebb29f5e8bfcf6fede43',
    'cfs': '65e8236b7a4e26fa2e249382c1b7def1c5c857359403d73991758e711c49d9ba',
  };
  static const urls = {
    'shell': 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20230321001219',
    'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001219&dcmNo=9083870&eleId=1&offset=784&length=3924&dtd=dart3.xsd',
    'overview': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001219&dcmNo=9083870&eleId=3&offset=5525&length=156854&dtd=dart3.xsd',
    'cfs': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230321001219&dcmNo=9083870&eleId=17&offset=427435&length=91713&dtd=dart3.xsd',
  };
  static Map<String, dynamic> verify(
    Map<String, String> raw, {
    required String receipt,
    required String corp,
    required String currentName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
  }) {
    if (receipt != '20230321001219' ||
        corp != '00115694' ||
        currentName != 'DB증권(주)' ||
        !consolidated ||
        start != DateTime.utc(2022) ||
        end != DateTime.utc(2022, 12, 31) ||
        raw.length != 4 ||
        hashes.entries.any(
          (e) =>
              raw[e.key] == null ||
              sha256.convert(utf8.encode(raw[e.key]!)).toString() != e.value,
        )) {
      throw const FormatException('Invalid exact DB issuer source bundle');
    }
    return {
      'kind': 'exact-own-filing-self-declared-issuer',
      'receipt': receipt,
      'corpCode': corp,
      'currentMasterName': currentName,
      'printedCoverName': 'DB금융투자 주식회사',
      'selfDeclaredName': '디비금융투자 주식회사',
      'selfDeclaredEnglishName': 'DB Financial Investment Co., Ltd.',
      'overviewSource': urls['overview'],
      'sourceHashes': hashes,
      'globalAlias': false,
      'basis': 'CFS',
      'fullStatementCollected': false,
      'sourceIndependentCheckCount': 15,
      'sourceIndependentCheckDifference': '0',
      'wholeNetIncome': '10770184612',
      'CEwholeNetIncome': '10770184612',
      'BSassets': '9757370294448',
      'BSliabilities': '8710072105027',
      'BSequity': '1047298189421',
      'CEclosingEquity': '1047298189421',
      'BSpriorEquity': '1048436630854',
      'CEopeningEquity': '1048436630854',
      'operatingCash': '-116571056767',
      'investingCash': '-13857171635',
      'financingCash': '212263274144',
      'printedCashChange': '81835045742',
      'exchangeCash': '-612244428',
      'openingCashAndBSpriorCash': '544685756338',
      'closingCashAndBScurrentCash': '625908557652',
      'primaryTablesDirectPrintedUnit': '원',
      'periodStart': '2022-01-01',
      'periodEnd': '2022-12-31',
      'flowCaptionPrintedStart': true,
      'adjustedNoteAmountsUsed': false,
      'ownersNetIncomeUsedAsWhole': false,
    };
  }
}
