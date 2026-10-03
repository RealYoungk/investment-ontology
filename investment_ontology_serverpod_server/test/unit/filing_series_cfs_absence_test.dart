import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/filing_series_cfs_absence.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';

import 'verified_annual_source_registry_test.dart' show filing, company;

void main() {
  test(
    'eleven normal-calendar finite original paragraphs; five noncalendar held',
    () {
      expect(FilingSeriesCfsAbsence.profiles, hasLength(11));
      for (final receipt in [
        '20220304000655',
        '20220317000539',
        '20220323001071',
        '20230103000440',
        '20230323000728',
      ]) {
        expect(
          FilingSeriesCfsAbsence.profiles.where((p) => p['receipt'] == receipt),
          isEmpty,
        );
      }
    },
  );
  for (final p in FilingSeriesCfsAbsence.profiles) {
    final e = VerifiedAnnualSourceRegistry.find(
      p['receipt'],
      FsDiv.consolidated,
    )!;
    test(
      '${e.receipt} own compound digest/literal/filing-only identity, no numbers',
      () async {
        final r = await VerifiedAnnualSourceCache().verifyRegistered(
          filing(e),
          company(e),
          e.basis,
        );
        expect(r.numeric, isNull);
        final a = r.absence!;
        expect(a.evidence, p['literal']);
        expect(a.sourceDigest, p['sourceDigest']);
        expect(a.periodStart, DateTime.utc(e.year));
        expect(a.periodEnd, DateTime.utc(e.year, 12, 31));
        final i = a.issuerIdentityEvidence!;
        expect(i['printedFilingActor'], p['actor']);
        expect(i['currentMasterName'], p['name']);
        expect(i['identityScope'], 'official-DART-filing-series-only');
        expect(i['jurirContinuityVerified'], 'false');
        expect(i['operatingHistoryContinuityVerified'], 'false');
        expect(i['numericFactsCollected'], '0');
        expect(i['coreFinancialsVerified'], 'false');
        expect(i['fullFinancialsVerified'], 'false');
        expect(i['printedCurrentShellName'], isNotEmpty);
        expect(i['sourceNotice'], contains(p['actor']));
        if (p['historicalSpac'] == true) {
          expect(i['sourceNotice'], contains('과거 SPAC 공시기준'));
        }
      },
    );
    for (final file in [
      'shell.html',
      'cover.html',
      'cfs.html',
      'manifest.json',
    ]) {
      test('${e.receipt} rejects mutation $file', () async {
        final c = VerifiedAnnualSourceCache(
          readAsset: (path) async {
            final b = await File(path).readAsBytes();
            return path.endsWith(file) ? [...b, 32] : b;
          },
        );
        expect(
          () => c.verifyRegistered(filing(e), company(e), e.basis),
          throwsA(isA<FormatException>()),
        );
      });
    }
    for (final bad in [
      'corp',
      'name',
      'receipt',
      'start',
      'end',
      'uri',
      'body',
    ]) {
      test('${e.receipt} rejects $bad substitution', () {
        final sources = p['sources'] as List;
        final raw = <String, String>{
          for (final s in sources)
            s['label']: File('${e.assetDirectory}/${s['file']}')
                .readAsStringSync(),
        };
        final uris = <String, Uri>{
          for (final s in sources) s['label']: Uri.parse(s['url']),
        };
        if (bad == 'uri') uris['cfs'] = uris['cover']!;
        if (bad == 'body') raw['cfs'] = '2. 연결재무제표 해당사항 없습니다.';
        expect(
          () => FilingSeriesCfsAbsence.verify(
            receipt: bad == 'receipt' ? '20220302000462' : e.receipt,
            corp: bad == 'corp' ? '99999999' : e.corpCode,
            currentName: bad == 'name'
                ? '${e.companyName} 다른법인'
                : e.companyName,
            reportName: '사업보고서 (${e.year}.12)',
            start: bad == 'start' ? DateTime.utc(e.year, 2) : e.periodStart,
            end: bad == 'end' ? DateTime.utc(e.year, 12, 21) : e.periodEnd,
            raw: raw,
            uris: uris,
          ),
          throwsA(isA<FormatException>()),
        );
      });
    }
  }
}
