import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/known_annual_source_not_presented.dart';

void main() {
  test('negative cache preserves exhausted failure and rejects every modified source', () async {
    final c = Company(id: 1, corpCode: '00442455', name: '코스나인');
    final f = DartFiling(
      id: 1,
      companyId: 1,
      corpCode: c.corpCode,
      rceptNo: '20260324000091',
      reportName: '사업보고서 (2025.12)',
      bsnsYear: 2025,
      reportCode: FinancialReportCode.annual,
      discoveredAt: DateTime.utc(2026),
      attempts: 3,
      consolidatedStatus: FilingFetchStatus.failed,
      separateStatus: FilingFetchStatus.failed,
    );
    for (final div in FsDiv.values) {
      final proof = await KnownAnnualNotPresentedCache().verify(f, c, div);
      expect(proof.evidence['auditAttachmentReadFromPinnedCache'], true);
      expect(proof.evidence['basisNotApplicable'], false);
      expect(
        KnownAnnualNotPresentedCache.eligible(f.copyWith(attempts: 2), c, div),
        false,
      );
      expect(
        KnownAnnualNotPresentedCache.eligible(
          f.copyWith(corpCode: '00000000'),
          c,
          div,
        ),
        false,
      );
      for (final name in [
        'manifest.json',
        ...KnownAnnualNotPresentedCache.pins.keys.map((x) => '$x.html'),
      ]) {
        final cache = KnownAnnualNotPresentedCache(
          readAsset: (path) async {
            final bytes = await File(path).readAsBytes();
            return path.endsWith('/$name') ? [...bytes, 32] : bytes;
          },
        );
        await expectLater(cache.verify(f, c, div), throwsFormatException);
      }
    }
  });

  for (final consolidated in [true, false]) {
    test('normal annual parser preserves not-presented failure: $consolidated', () {
      expect(
        () => PublicFinancialHtml.parseStandardAnnual(
          coverHtml: File('test/fixtures/kosnine_not_presented/cover.html')
              .readAsStringSync(),
          statementHtml: File(
            'test/fixtures/kosnine_not_presented/${consolidated ? 'cfs' : 'ofs'}.html',
          ).readAsStringSync(),
          coverSource: Uri.parse(KnownAnnualSourcesNotPresented.coverSource),
          statementSource: Uri.parse(
            KnownAnnualSourcesNotPresented.sources[consolidated]!,
          ),
          receipt: KnownAnnualSourcesNotPresented.receipt,
          corpCode: KnownAnnualSourcesNotPresented.corpCode,
          companyName: '(주)코스나인',
          periodStart: DateTime.utc(2025, 1, 1),
          periodEnd: DateTime.utc(2025, 12, 31),
          consolidated: consolidated,
        ),
        throwsA(isA<KnownAnnualSourceNotPresented>()),
      );
    });
    test('exact own current blank source is failed evidence: $consolidated', () {
      final cover = File('test/fixtures/kosnine_not_presented/cover.html')
          .readAsStringSync();
      final body = File(
        'test/fixtures/kosnine_not_presented/${consolidated ? 'cfs' : 'ofs'}.html',
      ).readAsStringSync();
      void verify({
        String? receipt,
        String? corp,
        String? html,
        DateTime? start,
        Uri? source,
      }) => KnownAnnualSourcesNotPresented.verify(
        receipt: receipt ?? KnownAnnualSourcesNotPresented.receipt,
        corpCode: corp ?? KnownAnnualSourcesNotPresented.corpCode,
        consolidated: consolidated,
        start: start ?? DateTime.utc(2025, 1, 1),
        end: DateTime.utc(2025, 12, 31),
        coverSource: Uri.parse(KnownAnnualSourcesNotPresented.coverSource),
        statementSource:
            source ??
            Uri.parse(KnownAnnualSourcesNotPresented.sources[consolidated]!),
        coverHtml: cover,
        statementHtml: html ?? body,
      );
      try {
        verify();
      } on KnownAnnualSourceNotPresented catch (e) {
        final audit = e.evidence['independentAuditEvidence'] as Map;
        final raw = File(
          'test/fixtures/kosnine_not_presented/${consolidated ? 'cfs' : 'ofs'}-audit.html',
        ).readAsBytesSync();
        expect(sha256.convert(raw).toString(), audit['sha256']);
        expect(e.evidence['auditAttachmentFetchedThisRun'], false);
      }
      expect(
        () => verify(),
        throwsA(
          isA<KnownAnnualSourceNotPresented>()
              .having(
                (e) => e.evidence['financialFactsStored'],
                'no amount facts',
                false,
              )
              .having(
                (e) => e.evidence['basisNotApplicable'],
                'not legal basis absence',
                false,
              )
              .having(
                (e) => e.evidence['collectionComplete'],
                'not complete',
                false,
              )
              .having(
                (e) => e.evidence['currentNumericCells'],
                'printed blank current',
                0,
              ),
        ),
      );
      expect(() => verify(receipt: '20250324000091'), returnsNormally);
      expect(() => verify(corp: '00000000'), returnsNormally);
      expect(() => verify(start: DateTime.utc(2024, 1, 1)), returnsNormally);
      expect(
        () => verify(
          source: Uri.parse(
            KnownAnnualSourcesNotPresented.sources[!consolidated]!,
          ),
        ),
        returnsNormally,
      );
      expect(() => verify(html: '$body '), returnsNormally);
    });
  }
}

final notPresentedCases = <Map<String, dynamic>>[
  for (final cfs in [true, false])
    {
      'receipt': KnownAnnualSourcesNotPresented.receipt,
      'corpCode': KnownAnnualSourcesNotPresented.corpCode,
      'name': '(주)코스나인',
      'basis': cfs ? 'cfs' : 'ofs',
      'reportName': '사업보고서 (2025.12)',
      'sources': [
        {'sha256': KnownAnnualSourcesNotPresented.coverSha},
        {'sha256': KnownAnnualSourcesNotPresented.hashes[cfs]},
      ],
    },
];
int year(Map<String, dynamic> e) => 2025;
Uri sourceUri(Map<String, dynamic> e, String basis) => Uri.parse(
  basis == 'cover'
      ? KnownAnnualSourcesNotPresented.coverSource
      : KnownAnnualSourcesNotPresented.sources[basis == 'cfs']!,
);
Future<PublicFinancialHtmlSource> fetchNotPresented(
  Map<String, dynamic> e, {
  required String corp,
  required bool cfs,
}) async {
  KnownAnnualSourcesNotPresented.verify(
    receipt: e['receipt'],
    corpCode: corp,
    consolidated: cfs,
    start: DateTime.utc(2025, 1, 1),
    end: DateTime.utc(2025, 12, 31),
    coverSource: sourceUri(e, 'cover'),
    statementSource: sourceUri(e, e['basis']),
    coverHtml: File('test/fixtures/kosnine_not_presented/cover.html')
        .readAsStringSync(),
    statementHtml: File(
      'test/fixtures/kosnine_not_presented/${cfs ? 'cfs' : 'ofs'}.html',
    ).readAsStringSync(),
  );
  throw StateError('Pinned not-presented source was not recognized');
}
