import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/market/macro_data.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 2);
  final from = DateTime.utc(2023, 10, 2);
  test('Missing days remain absent; negative oil price stays valid; sorted UTC dates', () {
    final points = MacroData.parseCsv(
      'observation_date,DCOILWTICO\n2026-10-01,72.1\n2026-09-30,.\n2026-09-29,-1\n2026-09-28,\n',
      'DCOILWTICO',
      now: now,
      from: from,
    );
    expect(points.map((p) => p.value), [-1, 72.1]);
    expect(points.first.date.isUtc, isTrue);
  });
  test('Wrong headers, HTML, impossible/future dates, nonfinite and conflicts fail closed', () {
    for (final csv in [
      '<html>not data</html>',
      'observation_date,DGS2\n2026-10-01,3',
      'observation_date,DGS10\n2026-02-30,3',
      'observation_date,DGS10\n2026-10-03,3',
      'observation_date,DGS10\n2026-10-01,NaN',
      'observation_date,DGS10\n2026-10-01,Infinity',
      'observation_date,DGS10\n2026-10-01,3\n2026-10-01,4',
    ]) {
      expect(
        () => MacroData.parseCsv(csv, 'DGS10', now: now, from: from),
        throwsFormatException,
      );
    }
  });
  String treasury(String year, {bool missingTwo = false}) =>
      '<feed xmlns="http://www.w3.org/2005/Atom" xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices">'
      '${year == '2026' ? '<entry><content><m:properties><d:NEW_DATE>2026-10-01T00:00:00</d:NEW_DATE><d:BC_2YEAR>${missingTwo ? '' : '4'}</d:BC_2YEAR><d:BC_10YEAR>5</d:BC_10YEAR></m:properties></content></entry>' : ''}</feed>';
  const ecb =
      '<Envelope xmlns="http://www.gesmes.org/xml/2002-08-01"><Cube xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref"><Cube time="2026-10-01"><Cube currency="USD" rate="1.1298"/><Cube currency="KRW" rate="1537.96"/></Cube></Cube></Envelope>';

  test('Treasury uses exact maturity; ECB derives same-date cross rate', () {
    expect(
      MacroData.parseTreasury(
        treasury('2026'),
        'DGS2',
        now: now,
        from: from,
      ).single.value,
      4,
    );
    expect(
      MacroData.parseTreasury(
        treasury('2026'),
        'DGS10',
        now: now,
        from: from,
      ).single.value,
      5,
    );
    expect(
      MacroData.parseEcb(ecb, now: now, from: from).single.value,
      closeTo(1537.96 / 1.1298, 0.000001),
    );
    expect(
      () => MacroData.parseEcb(
        ecb.replaceFirst('1.1298', '0'),
        now: now,
        from: from,
      ),
      throwsFormatException,
    );
    expect(
      () => MacroData.parseEcb(
        ecb.replaceFirst('2026-10-01', '2026-10-03'),
        now: now,
        from: from,
      ),
      throwsFormatException,
    );
    expect(
      () => MacroData.parseTreasury(
        treasury('2026'),
        'DGS3',
        now: now,
        from: from,
      ),
      throwsFormatException,
    );
  });

  test('Exim selects USD reference rate and rejects auth errors or malformed values', () {
    const body =
        '[{"result":1,"cur_unit":"USD","deal_bas_r":"1,359.6"},{"result":1,"cur_unit":"JPY(100)","deal_bas_r":"900"}]';
    expect(
      MacroData.parseExim(body, now, now: now, from: from).single.value,
      1359.6,
    );
    expect(MacroData.parseExim('[]', now, now: now, from: from), isEmpty);
    for (final bad in [
      body.replaceFirst('"result":1', '"result":3'),
      body.replaceFirst('1,359.6', '1,35.6'),
    ]) {
      expect(
        () => MacroData.parseExim(bad, now, now: now, from: from),
        throwsFormatException,
      );
    }
    expect(
      () => MacroData.parseExim(
        body,
        now.add(const Duration(days: 1)),
        now: now,
        from: from,
      ),
      throwsFormatException,
    );
  });

  test('EIA rejects wrong units and truncated pagination', () {
    const valid =
        r'{"response":{"total":"1","data":[{"period":"2026-10-01","series":"RWTC","units":"$/BBL","value":"-2"}]}}';
    expect(
      MacroData.parseEia(valid, 'RWTC', now: now, from: from).single.value,
      -2,
    );
    for (final bad in [
      valid.replaceFirst(r'$/BBL', 'USD'),
      valid.replaceFirst('"1"', '"2"'),
      valid.replaceFirst('RWTC', 'RBRTE'),
    ]) {
      expect(
        () => MacroData.parseEia(bad, 'RWTC', now: now, from: from),
        throwsFormatException,
      );
    }
  });

  test(
    'Shared feeds coalesce; expiry refreshes and failure preserves provenance',
    () async {
      var clock = now;
      var calls = 0;
      var fail = false;
      final requests = <Uri>[];
      final data = MacroData(
        now: () => clock,
        koreaEximApiKey: 'test-only-key',
        eximHistoryJson: '{"seriesId":"EXIM_USDKRW","points":[{"date":"2026-10-01","value":4}]}',
        client: MockClient((request) async {
          calls++;
          requests.add(request.url);
          if (fail) return http.Response('failure', 503);
          if (request.url.host == 'home.treasury.gov') {
            return http.Response(
              treasury(request.url.queryParameters['field_tdr_date_value']!),
              200,
            );
          }
          if (request.url.host == 'oapi.koreaexim.go.kr') {
            return http.Response(
              '[{"result":1,"cur_unit":"USD","deal_bas_r":"4"}]',
              200,
            );
          }
          final id = request.url.queryParameters['id'];
          return http.Response('observation_date,$id\n2026-10-01,4\n', 200);
        }),
      );
      final result = await Future.wait([data.overview(), data.overview()]);
      expect(result.first.every((s) => s.status == 'ready'), isTrue);
      expect(requests.where((u) => u.host == 'home.treasury.gov').length, 4);
      expect(
        result.first.singleWhere((s) => s.seriesId == 'DGS2').source!.title,
        contains('재무부'),
      );
      expect(
        result.first
            .singleWhere((s) => s.seriesId == 'EXIM_USDKRW')
            .source!
            .url,
        contains('koreaexim.go.kr'),
      );
      final initialCalls = calls;
      await data.overview();
      expect(calls, initialCalls);
      clock = clock.add(const Duration(hours: 2));
      fail = true;
      final stale = await data.overview();
      expect(stale.every((s) => s.status == 'stale'), isTrue);
      expect(stale.first.source!.retrievedAt, now);
      final failedCalls = calls;
      await data.overview();
      expect(calls, failedCalls);
      clock = clock.add(const Duration(minutes: 6));
      fail = false;
      expect((await data.overview()).every((s) => s.status == 'ready'), isTrue);
    },
  );

  test('Direct Treasury outage falls back to identical FRED maturity; FX stays independent', () async {
    final data = MacroData(
      now: () => now,
      koreaEximApiKey: 'test-only-key',
      eximHistoryJson: '{"seriesId":"EXIM_USDKRW","points":[]}',
      client: MockClient((request) async {
        if (request.url.host == 'home.treasury.gov' ||
            request.url.host == 'oapi.koreaexim.go.kr') {
          return http.Response('failure', 503);
        }
        final id = request.url.queryParameters['id'];
        return http.Response('observation_date,$id\n2026-10-01,4\n', 200);
      }),
    );
    final result = await data.overview();
    expect(result.where((s) => s.status == 'ready').length, 5);
    expect(
      result.singleWhere((s) => s.seriesId == 'EXIM_USDKRW').points,
      isEmpty,
    );
    expect(
      result.singleWhere((s) => s.seriesId == 'DGS2').source!.title,
      contains('대체'),
    );
  });
}
