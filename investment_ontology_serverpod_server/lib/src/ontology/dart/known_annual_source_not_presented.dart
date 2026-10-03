import 'dart:io';

import '../../generated/protocol.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A receipt-bound unavailable primary statement, never basis absence or zero.
class KnownAnnualSourceNotPresented extends FormatException {
  final Map<String, Object> evidence;
  KnownAnnualSourceNotPresented(Map<String, Object> evidence)
    : evidence = Map.unmodifiable(evidence),
      super(evidence['reason'] as String);
}

abstract final class KnownAnnualSourcesNotPresented {
  static const receipt = '20260324000091';
  static const corpCode = '00442455';
  static const coverSource =
      'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171060&eleId=1&offset=969&length=4522&dtd=dart4.xsd';
  static const coverSha =
      '6627761e4da2452fb5dfd8aca725b0f8c7fb1c48018f9de8cef1935b2c6208e6';
  static const sources = {
    true: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171060&eleId=19&offset=202225&length=131779&dtd=dart4.xsd',
    false: 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171060&eleId=25&offset=334347&length=115559&dtd=dart4.xsd',
  };
  static const hashes = {
    true: '415e32d72cf2a6f1a9f3fb2f0504cae4f583fe3472fa4c307bd6329d8770d295',
    false: '7a4f64c579187db2da4c1a8bc06ad52a56e626eb402fbaea7b19dabc633e8234',
  };

  static void verify({
    required String receipt,
    required String corpCode,
    required bool consolidated,
    required DateTime start,
    required DateTime end,
    required Uri coverSource,
    required Uri statementSource,
    required String coverHtml,
    required String statementHtml,
  }) {
    if (receipt != KnownAnnualSourcesNotPresented.receipt ||
        corpCode != KnownAnnualSourcesNotPresented.corpCode ||
        start != DateTime.utc(2025, 1, 1) ||
        end != DateTime.utc(2025, 12, 31) ||
        coverSource.toString() != KnownAnnualSourcesNotPresented.coverSource ||
        statementSource.toString() != sources[consolidated] ||
        sha256.convert(utf8.encode(coverHtml)).toString() != coverSha ||
        sha256.convert(utf8.encode(statementHtml)).toString() !=
            hashes[consolidated]) {
      return;
    }
    // Exact bytes bind the independently checked four primary tables, whose
    // current cells are all blank. No amount is parsed or manufactured here.
    throw KnownAnnualSourceNotPresented({
      'reason': '2025년 연결·별도 당기 재무제표가 원문에서 제시되지 않음. 비교기간 숫자는 당기로 대체하지 않으며 수집 실패 상태를 유지합니다.',
      'receipt': receipt,
      'corpCode': corpCode,
      'year': 2025,
      'consolidated': consolidated,
      'periodStart': '2025-01-01',
      'periodEnd': '2025-12-31',
      'coverSource': coverSource.toString(),
      'statementSource': statementSource.toString(),
      'coverSha256': coverSha,
      'statementSha256': hashes[consolidated]!,
      'printedUnit': '원',
      'currentColumn': 1,
      'currentTerm': '제 25 기',
      'comparativeColumnsNotUsed': [2, 3],
      'currentNumericCells': 0,
      'statementScope': ['BS', 'CIS', 'CE', 'CF'],
      'financialFactsStored': false,
      'basisNotApplicable': false,
      'collectionComplete': false,
      'notesVerified': false,
      'auditAttachmentFetchedThisRun': false,
      'independentAuditEvidence': {
        'source': consolidated
            ? 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171059&eleId=3&offset=7797&length=5144&dtd=dart4.xsd'
            : 'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260324000091&dcmNo=11171058&eleId=3&offset=8601&length=5761&dtd=dart4.xsd',
        'sha256': consolidated
            ? 'ae1ebbd050fe6a75c9130d369958e4eae2c6809b2a70b236917abfae932b5385'
            : 'c4453dcd957706779fdc99de6ce60d6a6c1e3097f73ffc3c19842f962ba0350c',
        'reviewedAheadOfTime': true,
        'printedEvidence': consolidated
            ? '회사의 경영진은 2025년 12월 31일로 종료되는 연결재무제표를 제시하지 아니함에 따라 동 재무제표를 첨부하지 아니합니다.'
            : '회사의 경영진은 2025년 12월 31일로 종료되는 재무제표를 제시하지 아니함에 따라 동 재무제표를 첨부하지 아니합니다.',
      },
    });
  }
}

/// Separate negative-evidence registry; never authorizes numeric/noData storage.
final class KnownAnnualNotPresentedCache {
  KnownAnnualNotPresentedCache({Future<List<int>> Function(String)? readAsset})
    : _read = readAsset ?? ((path) => File(path).readAsBytes());
  final Future<List<int>> Function(String) _read;
  static const directory =
      'assets/financial_source_cache/kosnine-2025-not-presented';
  static const manifestSha =
      '9411e095e8a2fdad35af5e846050fe6e298f27f357bbdad1bbe0419374475b88';
  static const pins = {
    "cover": "6627761e4da2452fb5dfd8aca725b0f8c7fb1c48018f9de8cef1935b2c6208e6",
    "cfs": "415e32d72cf2a6f1a9f3fb2f0504cae4f583fe3472fa4c307bd6329d8770d295",
    "ofs": "7a4f64c579187db2da4c1a8bc06ad52a56e626eb402fbaea7b19dabc633e8234",
    "shell": "675cc555b5fac5fa56ce8f66eb59abb26c95e3be223c5c38669a11436bde22b2",
    "cfs-audit":
        "ae1ebbd050fe6a75c9130d369958e4eae2c6809b2a70b236917abfae932b5385",
    "ofs-audit":
        "c4453dcd957706779fdc99de6ce60d6a6c1e3097f73ffc3c19842f962ba0350c",
  };
  static bool eligible(DartFiling f, Company c, FsDiv div) =>
      f.rceptNo == KnownAnnualSourcesNotPresented.receipt &&
      f.corpCode == KnownAnnualSourcesNotPresented.corpCode &&
      c.corpCode == f.corpCode &&
      f.companyId == c.id &&
      f.bsnsYear == 2025 &&
      f.reportCode == FinancialReportCode.annual &&
      f.reportName == '사업보고서 (2025.12)' &&
      f.attempts >= 3 &&
      (div == FsDiv.consolidated ? f.consolidatedStatus : f.separateStatus) ==
          FilingFetchStatus.failed;
  Future<KnownAnnualSourceNotPresented> verify(
    DartFiling f,
    Company c,
    FsDiv div,
  ) async {
    if (!eligible(f, c, div)) {
      throw const FormatException(
        'Not-presented negative cache scope mismatch',
      );
    }
    final manifest = await _read('$directory/manifest.json');
    if (sha256.convert(manifest).toString() != manifestSha) {
      throw const FormatException('Negative cache manifest changed');
    }
    final bodies = <String, String>{};
    for (final p in pins.entries) {
      final bytes = await _read('$directory/${p.key}.html');
      if (sha256.convert(bytes).toString() != p.value) {
        throw const FormatException('Negative primary source bytes changed');
      }
      bodies[p.key] = utf8.decode(bytes);
    }
    if (!bodies['shell']!.contains("openCorpInfoNew('00442455'")) {
      throw const FormatException('Negative cache legal issuer mismatch');
    }
    final cfs = div == FsDiv.consolidated;
    try {
      KnownAnnualSourcesNotPresented.verify(
        receipt: f.rceptNo,
        corpCode: c.corpCode,
        consolidated: cfs,
        start: DateTime.utc(2025, 1, 1),
        end: DateTime.utc(2025, 12, 31),
        coverSource: Uri.parse(KnownAnnualSourcesNotPresented.coverSource),
        statementSource: Uri.parse(
          KnownAnnualSourcesNotPresented.sources[cfs]!,
        ),
        coverHtml: bodies['cover']!,
        statementHtml: bodies[cfs ? 'cfs' : 'ofs']!,
      );
    } on KnownAnnualSourceNotPresented catch (e) {
      return KnownAnnualSourceNotPresented({
        ...e.evidence,
        'negativeCacheManifestSha256': manifestSha,
        'auditAttachmentReadFromPinnedCache': true,
        'legalIssuerShellSha256': pins['shell']!,
        'legalIssuerShellSource':
            'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=20260324000091',
      });
    }
    throw const FormatException('Pinned negative contract not recognized');
  }
}
