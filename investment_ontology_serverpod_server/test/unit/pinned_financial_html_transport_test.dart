import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';
import 'package:test/test.dart';

void main() {
  const directory = 'assets/financial_source_cache/20250321001825-cfs';
  final manifest =
      jsonDecode(File('$directory/manifest.json').readAsStringSync()) as Map;
  final documents = <Uri, List<int>>{
    for (final source in manifest['sources'] as List)
      Uri.parse(source['url'] as String): File('$directory/${source['file']}')
          .readAsBytesSync(),
  };

  Future<PublicFinancialHtmlSource> fetch(PublicFinancialHtmlFetcher fetcher) =>
      fetcher.fetchAnnual(
        '20250321001825',
        reportName: '사업보고서 (2024.12)',
        corpCode: '00990396',
        companyName: '(주)레드우즈',
        bsnsYear: 2024,
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: true,
      );

  test(
    'pinned real annual keeps provenance and creates no cadence timers',
    () async {
      final fetcher = PublicFinancialHtmlFetcher.pinnedDocuments(
        documents,
        maxRequests: documents.length,
      );
      addTearDown(fetcher.client.close);
      final timers = <Duration>[];
      final source = await runZoned(
        () => fetch(fetcher),
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, duration, callback) {
            timers.add(duration);
            return parent.createTimer(zone, duration, callback);
          },
        ),
      );
      expect(fetcher.pinnedRequestCount, documents.length);
      expect(
        timers.where(
          (d) => d > Duration.zero && d < const Duration(seconds: 30),
        ),
        isEmpty,
      );
      expect(source.sourceReceipt, manifest['receipt']);
      expect(source.statementSource.queryParameters['dcmNo'], '10450232');
      expect(
        source.rows.map((r) => r['thstrm_amount']),
        containsAll([
          '27655923765',
          '24989599096',
          '2666324669',
          '13636364',
          '-2842030359',
          '-5035450099',
          '-2396964906',
        ]),
      );
      expect(source.rows.every((r) => r['account_id'] == null), isTrue);
    },
  );

  test(
    'pinned transport cannot follow an unlisted URL or changed coordinate',
    () async {
      final fetcher = PublicFinancialHtmlFetcher.pinnedDocuments(
        documents,
        maxRequests: documents.length,
      );
      addTearDown(fetcher.client.close);
      final shell = documents.keys.first;
      for (final url in [
        shell.replace(host: 'example.com'),
        shell.replace(queryParameters: {'rcpNo': '20260101000001'}),
        Uri.parse('https://dart.fss.or.kr/unlisted'),
      ]) {
        await expectLater(fetcher.client.get(url), throwsFormatException);
      }
      await expectLater(fetcher.client.post(shell), throwsFormatException);
      expect(fetcher.pinnedRequestCount, 0);
    },
  );

  test(
    'pinned transport enforces its request cap and snapshots URL membership',
    () async {
      final input = Map<Uri, List<int>>.from(documents);
      final fetcher = PublicFinancialHtmlFetcher.pinnedDocuments(
        input,
        maxRequests: 1,
      );
      addTearDown(fetcher.client.close);
      input.clear();
      expect(
        (await fetcher.client.get(documents.keys.first)).bodyBytes,
        documents.values.first,
      );
      await expectLater(
        fetcher.client.get(documents.keys.first),
        throwsFormatException,
      );
    },
  );

  test(
    'ordinary clients still reserve network starts across fetcher instances',
    () async {
      final starts = <DateTime>[];
      for (var i = 0; i < 2; i++) {
        final client = MockClient((request) async {
          starts.add(DateTime.now());
          final body = documents[request.url];
          return http.Response.bytes(body ?? [], 200, request: request);
        });
        addTearDown(client.close);
        await fetch(PublicFinancialHtmlFetcher(client));
      }
      expect(starts, hasLength(documents.length * 2));
      for (var i = 1; i < starts.length; i++) {
        expect(
          starts[i].difference(starts[i - 1]),
          greaterThanOrEqualTo(const Duration(milliseconds: 950)),
        );
      }
    },
  );
}
