import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_publication_timing.dart';

void main() {
  test(
    'actual official body hashes and read schedule bind partial calendar',
    () {
      final proof = jsonDecode(
        File('test/fixtures/market_publication/source-proof.json')
            .readAsStringSync(),
      ) as Map;
      for (final pair in [
        ('publication', 'data-gov-stock-publication.html'),
        ('governmentCalendar', 'kasi-2026-monthly-calendar.html'),
      ]) {
        final bytes = File('test/fixtures/market_publication/${pair.$2}')
            .readAsBytesSync();
        expect(sha256.convert(bytes).toString(), proof[pair.$1]['sha256']);
        final text = utf8
            .decode(bytes)
            .replaceAll(RegExp('<[^>]+>'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ');
        expect(
          text,
          contains(pair.$1 == 'publication' ? '영업일 하루 뒤 오후 1시 이후' : '10월 3~5일'),
        );
      }
    },
  );
  test('Oct2 Friday expected recheck crosses independently read Monday public holiday', () {
    final d = DateTime.utc(2026, 10, 2), now = DateTime.utc(2026, 10, 3, 5);
    expect(
      MarketPublicationTiming.estimateUtc(d),
      DateTime.utc(2026, 10, 6, 4),
    );
    expect(
      MarketPublicationTiming.retryAt(now, [d]),
      DateTime.utc(2026, 10, 6, 4),
    );
    expect(
      MarketPublicationTiming.estimateMessage(now, [d]),
      contains('실제 공개/입수 보장 아님'),
    );
    expect(
      MarketPublicationTiming.withinExpectedResponseWindow(
        d,
        DateTime.utc(2026, 10, 6, 3),
      ),
      true,
    );
    expect(
      MarketPublicationTiming.withinExpectedResponseWindow(
        d,
        DateTime.utc(2026, 10, 7, 5),
      ),
      false,
    );
  });
  test(
    'KRX-only May1 and yearend are not treated as provider public holidays',
    () {
      expect(
        MarketPublicationTiming.estimateUtc(DateTime.utc(2026, 4, 30)),
        DateTime.utc(2026, 5, 1, 4),
      );
      expect(
        MarketPublicationTiming.estimateUtc(DateTime.utc(2026, 12, 30)),
        DateTime.utc(2026, 12, 31, 4),
      );
    },
  );
  test(
    'passed/unknown estimated dates retain bounded hourly retry, never noData',
    () {
      final now = DateTime.utc(2026, 9, 17, 3);
      expect(
        MarketPublicationTiming.retryAt(now, [DateTime.utc(2026, 9, 16)]),
        now.add(const Duration(hours: 1)),
      );
      expect(
        MarketPublicationTiming.retryAt(DateTime.utc(2027, 1, 3, 5), [
          DateTime.utc(2026, 12, 31),
        ]),
        DateTime.utc(2027, 1, 3, 6),
      );
    },
  );
}
