import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One immutable own-company rename event; no transliteration or alias rules.
final class SkSignetIdentity {
  const SkSignetIdentity({
    required this.shell,
    required this.overview,
    required this.overviewSource,
  });
  final String shell, overview;
  final Uri overviewSource;
  static const receipt = '20250320001633', corpCode = '01188730';
  static const directory = 'assets/financial_source_cache/20250320001633-ofs';
  static const hashes = <String, String>{
    'shell': '1871e674e5287a4b2405e1e659ae8271c22838ae615972f44e4e602c9e1040c4',
    'cover': '397be826b3698513bf845fe91851584fc70520480c1763c9638c778c9e40d3b6',
    'ofs': '72602a99390b6e61aafd1b1da710ce5aeb6432c390e0f6d279c0753ba24a58a2',
    'overview':
        'a350546f0cff89de029bbd01ff2cfbad1f002d4d3e348e57afec67dbdfa5fc26',
  };
  static const urls = <String, String>{
    'overview': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=3&offset=6025&length=107581&dtd=dart4.xsd',
    'cover': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=1&offset=958&length=4511&dtd=dart4.xsd',
    'ofs': 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20250320001633&dcmNo=10440936&eleId=21&offset=556438&length=95968&dtd=dart4.xsd',
  };
  Map<String, String> verify({
    required String targetReceipt,
    required String companyCode,
    required String masterName,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required String cover,
    required String statement,
    required Uri coverSource,
    required Uri statementSource,
  }) {
    String digest(String raw) => sha256.convert(utf8.encode(raw)).toString();
    final owners = RegExp(r'''openCorpInfoNew\(['"](\d{8})''')
        .allMatches(shell)
        .map((m) => m.group(1))
        .toSet();
    if (targetReceipt != receipt ||
        companyCode != corpCode ||
        consolidated ||
        masterName.replaceAll(RegExp(r'\s|주식회사|\(주\)|㈜'), '') != 'SK시그넷' ||
        start != DateTime.utc(2024) ||
        end != DateTime.utc(2024, 12, 31) ||
        digest(shell) != hashes['shell'] ||
        digest(overview) != hashes['overview'] ||
        digest(cover) != hashes['cover'] ||
        digest(statement) != hashes['ofs'] ||
        owners.length != 1 ||
        owners.single != corpCode ||
        overviewSource.toString() != urls['overview'] ||
        coverSource.toString() != urls['cover'] ||
        statementSource.toString() != urls['ofs']) {
      throw const FormatException(
        'Invalid exact SK Signet own rename evidence',
      );
    }
    // The pinned complete I section has a completed own-company declaration
    // (2022.03.30) and one rename-table row (2022.03), same previous name.
    final text = overview.replaceAll(RegExp(r'<[^>]+>|\s|&nbsp;'), '');
    const declaration = '당사는2022년3월30일자로주식회사시그넷이브이에서에스케이시그넷주식회사로사명을변경하였습니다.';
    const row = '2022.03(주)시그넷이브이SK시그넷(주)-';
    if (declaration.allMatches(text).length != 1 ||
        row.allMatches(text).length != 1 ||
        !text.contains('라.상호의변경변경일자변경전상호변경후상호비고') ||
        !DateTime.utc(2022, 3, 30).isBefore(start)) {
      throw const FormatException('Ambiguous SK Signet completed rename event');
    }
    return {
      'rule': 'sk-signet-direct-rename-event-v1',
      'receipt': receipt,
      'corpCode': corpCode,
      'source': overviewSource.toString(),
      'sha256': hashes['overview']!,
      'printedCoverName': '에스케이시그넷 주식회사',
      'printedStatementName': 'SK시그넷 주식회사',
      'previousName': '주식회사 시그넷이브이',
      'completedDate': '2022-03-30',
      'renameTableMonth': '2022.03',
    };
  }
}
