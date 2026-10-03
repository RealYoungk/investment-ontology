import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/historical_primary_cfs_absence.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

void main() {
  for (final receipt in [
    '20221026000437',
    '20230314000624',
    '20240319000167',
    '20220318000943',
    '20230728000135',
    '20241227000654',
  ]) {
    final entry = VerifiedAnnualSourceRegistry.find(
      receipt,
      FsDiv.consolidated,
    )!;
    final dir = entry.assetDirectory;
    final manifest = jsonDecode(File('$dir/manifest.json').readAsStringSync());
    final m = {
      'corp': entry.corpCode,
      'name': entry.companyName,
      'year': entry.year,
      'reportName': '사업보고서 (${entry.year}.12)',
      'sources': manifest['sources'],
    };
    Map source(String l) => (m['sources'] as List).singleWhere(
      (x) => x['label'] == (l == 'ofs' ? 'issuer-ofs' : l),
    );
    String raw(String l) =>
        File('$dir/${source(l)['file']}').readAsStringSync();
    Uri uri(String l) => Uri.parse(source(l)['url']);
    final literal = receipt == '20240319000167'
        ? '※ 당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.'
        : m['corp'] == '00978075'
        ? '당사는 주식회사의 외부감사에 관한 법률 제1조의2에 의한 연결재무제표 작성대상 법인이 아닙니다.'
        : '당사는 해당사항 없습니다.';
    PublicFinancialHtmlBasisNotApplicable verify({
      String? cfs,
      String? ofs,
      String? corp,
      String? target,
      Uri? cfSource,
      DateTime? end,
      String? expected,
    }) => HistoricalPrimaryCfsAbsence.verify(
      receipt: target ?? receipt,
      corpCode: corp ?? m['corp'],
      currentName: m['name'],
      reportName: m['reportName'],
      start: DateTime.utc(m['year']),
      end: end ?? DateTime.utc(m['year'], 12, 31),
      shellSource: uri('shell'),
      shell: raw('shell'),
      coverSource: uri('cover'),
      cover: raw('cover'),
      ofsSource: uri('ofs'),
      ofs: ofs ?? raw('ofs'),
      overviewSource: uri('overview'),
      overview: raw('overview'),
      cfsSource: cfSource ?? uri('cfs'),
      cfs: cfs ?? raw('cfs'),
      expectedLiteral: expected ?? literal,
    );
    test('$receipt actual pure CFS uses OFS identity only', () {
      final x = verify();
      expect(x.sourceReceipt, receipt);
      expect(x.statementSource, uri('cfs'));
      expect(
        x.evidence.replaceAll(RegExp(r'\s+'), ''),
        literal.replaceAll(RegExp(r'\s+'), ''),
      );
      expect(
        x.issuerIdentityEvidence!['primaryWitnessSource'],
        uri('ofs').toString(),
      );
      expect(
        x.issuerIdentityEvidence!['usage'],
        contains('no CFS amount inference'),
      );
      expect(x.consolidated, isTrue);
    });
    test('$receipt pinned fifth witness SHA rejects tampering', () async {
      final f = DartFiling(
        id: 1,
        companyId: 1,
        corpCode: entry.corpCode,
        rceptNo: receipt,
        bsnsYear: entry.year,
        reportCode: FinancialReportCode.annual,
        reportName: '사업보고서 (${entry.year}.12)',
        consolidatedStatus: FilingFetchStatus.failed,
        separateStatus: FilingFetchStatus.stored,
        attempts: 3,
        lastError: 'api-noData-annual-public:attempt=3; previous source failed',
        discoveredAt: DateTime.utc(2026),
      );
      final c = Company(
        id: 1,
        corpCode: entry.corpCode,
        name: entry.companyName,
        stockCode: '000001',
        fiscalMonth: 12,
      );
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async => File(p).readAsBytes(),
      );
      final x = await cache.verifyRegistered(f, c, FsDiv.consolidated);
      expect(x.numeric, isNull);
      expect(
        x.absence!.issuerIdentityEvidence!['primaryWitnessSource'],
        uri('ofs').toString(),
      );
      for (final label in ['shell', 'cover', 'cfs', 'overview', 'issuer-ofs']) {
        final mutated = VerifiedAnnualSourceCache(
          readAsset: (p) async => p.endsWith('/$label.html')
              ? utf8.encode('different source')
              : File(p).readAsBytes(),
        );
        await expectLater(
          mutated.verifyRegistered(f, c, FsDiv.consolidated),
          throwsA(isA<FormatException>()),
        );
      }
    });
    test('$receipt own source boundaries reject mutation', () {
      var negativeIndex = 0;
      for (final bad in [
        () => verify(corp: '00000000'),
        () => verify(target: '20260101000001'),
        () => verify(cfSource: uri('ofs')),
        () => verify(end: DateTime.utc(m['year'] - 1, 12, 31)),
        () => verify(expected: '해당사항 없습니다.'),
        () => verify(cfs: raw('cfs').replaceAll('2. 연결재무제표', '4. 재무제표')),
        () => verify(
          cfs: raw('cfs').replaceAll('</BODY>', '<P>주석을 참고하십시오.</P></BODY>'),
        ),
        () => verify(
          cfs: raw(
            'cfs',
          ).replaceAll('</BODY>', '<TABLE><TR><TD>1</TD></TR></TABLE></BODY>'),
        ),
        () => verify(
          cfs: raw('cfs').replaceAll('</BODY>', '<SCRIPT>1</SCRIPT></BODY>'),
        ),
        () => verify(ofs: '<BODY>재무제표 계정 누락</BODY>'),
      ]) {
        expect(
          bad,
          throwsA(isA<FormatException>()),
          reason: 'negative ${negativeIndex++}',
        );
      }
    });
  }
}
