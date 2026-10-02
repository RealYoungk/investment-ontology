import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';

DartFiling target({
  String corp = '00765897',
  String receipt = '20250321001900',
  int year = 2024,
  FinancialReportCode kind = FinancialReportCode.annual,
  String name = '사업보고서 (2024.12)',
  FilingFetchStatus cfs = FilingFetchStatus.failed,
  int cap = 3,
}) => DartFiling(
  id: 1,
  companyId: 1,
  rceptNo: receipt,
  corpCode: corp,
  bsnsYear: year,
  reportCode: kind,
  reportName: name,
  consolidatedStatus: cfs,
  separateStatus: FilingFetchStatus.stored,
  attempts: 7,
  lastError: 'api-noData-annual-public:attempt=$cap; previous failure',
  discoveredAt: DateTime.utc(2026),
);
Company company({
  String corp = '00765897',
  String name = '한국피아이엠',
  String? stock = '231090',
}) => Company(
  id: 1,
  corpCode: corp,
  name: name,
  stockCode: stock,
  fiscalMonth: 12,
);
void main() {
  test('packaged immutable official bytes replay whole numeric CFS without network', () async {
    final filing = target();
    final before = filing.toJson();
    final reads = <String>[];
    final cache = VerifiedAnnualSourceCache(
      readAsset: (p) async {
        reads.add(p);
        return File(p).readAsBytes();
      },
    );
    final result = await cache.verifyPim(filing, company());
    expect(result.sourceReceipt, VerifiedAnnualSourceCache.pimReceipt);
    expect(result.rows.take(7).map((r) => r['thstrm_amount']).toList(), [
      '76459309100',
      '32807209849',
      '43652099251',
      '37447247186',
      '3606809251',
      '2777596031',
      '3548256433',
    ]);
    expect(result.rows.every((r) => r['account_id'] == null), true);
    expect(result.periodStart, DateTime.utc(2024));
    expect(result.periodEnd, DateTime.utc(2024, 12, 31));
    expect(reads.length, 4);
    expect(filing.toJson(), before);
    final manifest = jsonDecode(
      File('${VerifiedAnnualSourceCache.pimAssetDirectory}/manifest.json')
          .readAsStringSync(),
    );
    expect(
      sha256
          .convert(
            File('${VerifiedAnnualSourceCache.pimAssetDirectory}/manifest.json')
                .readAsBytesSync(),
          )
          .toString(),
      VerifiedAnnualSourceCache.pimManifestDigest,
    );
    for (final source in manifest['sources']) {
      expect(
        sha256
            .convert(
              File(
                '${VerifiedAnnualSourceCache.pimAssetDirectory}/${source['file']}',
              ).readAsBytesSync(),
            )
            .toString(),
        source['sha256'],
      );
    }
    expect(result.statementSource.queryParameters['eleId'], '19');
    expect(result.statementSource.queryParameters['dcmNo'], '10450768');
  });
  for (final f in [
    target(corp: '00126380'),
    target(receipt: '20250321001901'),
    target(year: 2025),
    target(kind: FinancialReportCode.halfYear),
    target(name: '반기보고서 (2025.12)'),
    target(name: '사업보고서 (2025.06)'),
    target(cfs: FilingFetchStatus.stored),
    target(cfs: FilingFetchStatus.noData),
    target(cap: 2),
    target(cap: 4),
  ]) {
    test('only exact exhausted annual CFS eligible ${f.toJson()}', () {
      expect(VerifiedAnnualSourceCache.eligiblePim(f), false);
    });
  }
  for (final file in [
    'manifest.json',
    'shell.html',
    'cover.html',
    'cfs.html',
  ]) {
    test('changed $file bytes never authenticate', () async {
      final cache = VerifiedAnnualSourceCache(
        readAsset: (p) async {
          final raw = await File(p).readAsBytes();
          return p.endsWith(file) ? [...raw, 32] : raw;
        },
      );
      await expectLater(
        cache.verifyPim(target(), company()),
        throwsFormatException,
      );
    });
  }
  for (final edit in [
    (Map m) {
      m['corpCode'] = '00126380';
    },
    (Map m) {
      m['receipt'] = '20250321001901';
    },
    (Map m) {
      m['periodEnd'] = '2025-06-30';
    },
    (Map m) {
      m['basis'] = 'separate';
    },
    (Map m) {
      m['sources'][2]['url'] = 'https://example.com/statement';
    },
    (Map m) {
      m['sources'][2]['file'] = '../../unknown.html';
    },
  ]) {
    test(
      'unknown edited manifest rejects even internally consistent raw data ${edit.hashCode}',
      () async {
        final cache = VerifiedAnnualSourceCache(
          readAsset: (p) async {
            final raw = await File(p).readAsBytes();
            if (!p.endsWith('manifest.json')) return raw;
            final m = jsonDecode(utf8.decode(raw));
            edit(m);
            return utf8.encode(jsonEncode(m));
          },
        );
        await expectLater(
          cache.verifyPim(target(), company()),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'current legal name mismatch retains original strict cover guard',
    () => expectLater(
      VerifiedAnnualSourceCache().verifyPim(target(), company(name: '다른법인')),
      throwsFormatException,
    ),
  );
  test('wrong company corporation fails before reading assets', () async {
    var reads = 0;
    final cache = VerifiedAnnualSourceCache(
      readAsset: (p) async {
        reads++;
        return [];
      },
    );
    await expectLater(
      cache.verifyPim(target(), company(corp: '00126380')),
      throwsFormatException,
    );
    expect(reads, 0);
  });
  test(
    'different company ID fails before reading assets',
    () => expectLater(
      VerifiedAnnualSourceCache().verifyPim(
        target().copyWith(companyId: 2),
        company(),
      ),
      throwsFormatException,
    ),
  );
}
