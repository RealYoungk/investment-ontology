import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_documents_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/issuer_documents_collector.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/ipo_issuer_financials_html.dart';

void main() {
  test(
    '47 exact approved sources retain whole company groups and current IPO',
    () async {
      final docs = IssuerDocumentsCollector.manifest(
        await IssuerDocumentsSync.combinedManifestText(),
      );
      expect(docs, hasLength(47));
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final d in docs) {
        final m = d['metadata'] as Map;
        groups.putIfAbsent(m['corpCode'] as String, () => []).add(d);
      }
      expect(groups, hasLength(12));
      for (final rows in groups.values) {
        expect(rows.length, lessThanOrEqualTo(6));
      }
      expect(groups['01564514'], hasLength(6));
      expect(groups['01586923'], hasLength(6));
      for (final corp in ['01564514', '01586923']) {
        expect(
          groups[corp]!
              .where((d) => d['metadata']['documentType'] == 'auditReport')
              .map((d) => d['metadata']['periodEnd'])
              .toSet(),
          {
            '2021-12-31',
            '2022-12-31',
            '2023-12-31',
            '2024-12-31',
            '2025-12-31',
          },
        );
      }
      final corrected = docs.singleWhere(
        (d) => d['metadata']['providerReceipt'] == '20260331003319',
      );
      expect(corrected['metadata']['periodEnd'], '2024-12-31');
      expect(corrected['metadata']['publishedAt'], '2026-03-31');
      expect(corrected['proof']['fileSavedAt'], isNotNull);
      expect(
        corrected['proof']['downloadedAt'],
        isNull,
        reason: 'Do not invent GET completion timestamp from file mtime',
      );
      for (final d in docs.where(
        (d) =>
            d['metadata']['documentType'] == 'auditReport' &&
            d['metadata']['provider'] == 'DART',
      )) {
        expect(
          IpoIssuerFinancialsHtml.supports(d),
          isFalse,
          reason: 'Own audits are not the latest IPO numeric profile',
        );
        expect(d['metadata']['numericState'], 'notExtracted');
        expect(d['metadata']['financialValues'], isNull);
      }
      expect(docs.where(IpoIssuerFinancialsHtml.supports), hasLength(8));
    },
  );
  test(
    'larger roster never admits unpinned metadata, duplicate or 48th URI',
    () async {
      final original = await IssuerDocumentsSync.combinedManifestText();
      for (final mutation in ['changedFund', 'duplicate', 'extra']) {
        final raw = jsonDecode(original) as Map;
        final docs = raw['documents'] as List;
        if (mutation == 'changedFund') {
          docs.first['metadata']['title'] = 'unreviewed title';
        }
        if (mutation == 'duplicate') {
          docs[1] = docs.first;
        }
        if (mutation == 'extra') {
          docs.add(docs.first);
        }
        expect(
          () => IssuerDocumentsCollector.manifest(jsonEncode(raw)),
          throwsFormatException,
          reason: mutation,
        );
      }
    },
  );
}
