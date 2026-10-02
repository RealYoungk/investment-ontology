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
  test('Concurrent reads coalesce, failures preserve source date, retries are bounded', () async {
    var clock = now;
    var calls = 0;
    var fail = false;
    final data = MacroData(
      now: () => clock,
      client: MockClient((request) async {
        calls++;
        if (fail) return http.Response('failure', 503);
        final id = request.url.queryParameters['id'];
        return http.Response(
          'observation_date,$id\n2026-09-30,3\n2026-10-01,4\n',
          200,
        );
      }),
    );
    final first = await Future.wait([data.overview(), data.overview()]);
    expect(calls, 6);
    expect(first.first.every((s) => s.status == 'ready'), isTrue);
    expect(first.first.every((s) => s.source?.reference == s.seriesId), isTrue);
    await data.overview();
    expect(calls, 6);
    clock = clock.add(const Duration(hours: 7));
    fail = true;
    final stale = await data.overview();
    expect(calls, 12);
    expect(stale.every((s) => s.status == 'stale'), isTrue);
    expect(stale.first.source!.retrievedAt, now);
    expect(stale.first.points.last.value, 4);
    await data.overview();
    expect(calls, 12);
    clock = clock.add(const Duration(minutes: 6));
    fail = false;
    final recovered = await data.overview();
    expect(recovered.first.status, 'ready');
    expect(calls, 18);
  });
  test('One unavailable series leaves five usable; absent observations are not zero', () async {
    final data = MacroData(
      now: () => now,
      client: MockClient((request) async {
        final id = request.url.queryParameters['id'];
        return http.Response(
          id == 'DGS2'
              ? 'observation_date,$id\n2026-10-01,.\n'
              : 'observation_date,$id\n2026-10-01,4\n',
          200,
        );
      }),
    );
    final result = await data.overview();
    expect(result.where((s) => s.status == 'ready').length, 5);
    expect(result.singleWhere((s) => s.seriesId == 'DGS2').points, isEmpty);
    expect(result.singleWhere((s) => s.seriesId == 'DGS2').source, isNull);
  });
}
