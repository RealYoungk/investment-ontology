import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

DartFiling target({
  String corp = '01020269',
  String receipt = '20260323001652',
  int year = 2025,
  FinancialReportCode kind = FinancialReportCode.annual,
  String name = '사업보고서 (2025.12)',
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
  String corp = '01020269',
  String name = '(주) 탈로스',
  String? stock = '231090',
}) => Company(
  id: 1,
  corpCode: corp,
  name: name,
  stockCode: stock,
  fiscalMonth: 12,
);
void main() {
  test('packaged immutable official bytes replay typed absence without network', () async {
    final filing = target();
    final before = filing.toJson();
    final reads = <String>[];
    final cache = VerifiedAnnualSourceCache(
      readAsset: (p) async {
        reads.add(p);
        return File(p).readAsBytes();
      },
    );
    final result = await cache.verify(filing, company());
    expect(result, isA<PublicFinancialHtmlBasisNotApplicable>());
    expect(result.sourceReceipt, VerifiedAnnualSourceCache.receipt);
    expect(result.corpCode, VerifiedAnnualSourceCache.corpCode);
    expect(result.evidence.replaceAll(' ', ''), '해당사항없음');
    expect(result.periodStart, DateTime.utc(2025));
    expect(result.periodEnd, DateTime.utc(2025, 12, 31));
    expect(reads.length, 4);
    expect(filing.toJson(), before);
    final manifest = jsonDecode(
      File('${VerifiedAnnualSourceCache.assetDirectory}/manifest.json')
          .readAsStringSync(),
    );
    expect(
      sha256
          .convert(
            File('${VerifiedAnnualSourceCache.assetDirectory}/manifest.json')
                .readAsBytesSync(),
          )
          .toString(),
      VerifiedAnnualSourceCache.manifestDigest,
    );
    for (final source in manifest['sources']) {
      expect(
        sha256
            .convert(
              File(
                '${VerifiedAnnualSourceCache.assetDirectory}/${source['file']}',
              ).readAsBytesSync(),
            )
            .toString(),
        source['sha256'],
      );
    }
    expect(result.statementSource.queryParameters['eleId'], '19');
    expect(result.statementSource.queryParameters['dcmNo'], '11169335');
  });
  for (final f in [
    target(corp: '00126380'),
    target(receipt: '20260323001653'),
    target(year: 2024),
    target(kind: FinancialReportCode.halfYear),
    target(name: '반기보고서 (2025.12)'),
    target(name: '사업보고서 (2025.06)'),
    target(cfs: FilingFetchStatus.stored),
    target(cfs: FilingFetchStatus.noData),
    target(cap: 2),
    target(cap: 4),
  ]) {
    test('only exact exhausted annual CFS eligible ${f.toJson()}', () {
      expect(VerifiedAnnualSourceCache.eligible(f), false);
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
        cache.verify(target(), company()),
        throwsFormatException,
      );
    });
  }
  for (final edit in [
    (Map m) {
      m['corpCode'] = '00126380';
    },
    (Map m) {
      m['receipt'] = '20260323001653';
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
          cache.verify(target(), company()),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'current legal name mismatch retains original strict cover guard',
    () => expectLater(
      VerifiedAnnualSourceCache().verify(target(), company(name: '다른법인')),
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
      cache.verify(target(), company(corp: '00126380')),
      throwsFormatException,
    );
    expect(reads, 0);
  });
  test(
    'different company ID fails before reading assets',
    () => expectLater(
      VerifiedAnnualSourceCache().verify(
        target().copyWith(companyId: 2),
        company(),
      ),
      throwsFormatException,
    ),
  );
}
