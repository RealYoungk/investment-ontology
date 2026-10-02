import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:serverpod/serverpod.dart';

import '../api_secret.dart';

import '../../generated/protocol.dart';

typedef MacroDefinition = ({
  String id,
  String name,
  String group,
  String unit,
  bool rate,
  String publisher,
});

/// Treasury and ECB direct daily data; EIA direct API when configured.
/// FRED remains the official distribution fallback for identical series.
/// Fixed allowlist: callers cannot supply URLs or create shared facts.
class MacroData {
  MacroData({
    http.Client? client,
    DateTime Function()? now,
    String? eiaApiKey,
    String? koreaEximApiKey,
    String? eximHistoryJson,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       // Keep credentials private while allowing injection in isolated tests.
       // ignore: prefer_initializing_formals
       _eiaApiKey = eiaApiKey,
       // ignore: prefer_initializing_formals
       _koreaEximApiKey = koreaEximApiKey,
       // ignore: prefer_initializing_formals
       _eximHistoryJson = eximHistoryJson;

  static var shared = MacroData();
  static const _eiaSecret = ApiSecret(
    passwordName: 'eiaApiKey',
    envName: 'EIA_API_KEY',
  );
  static const _eximSecret = ApiSecret(
    passwordName: 'koreaEximApiKey',
    envName: 'KOREA_EXIM_API_KEY',
  );
  static MacroData forSession(Session session) {
    final key = _eiaSecret.read(session);
    final eximKey = _eximSecret.read(session);
    if (shared._eiaApiKey != key || shared._koreaEximApiKey != eximKey) {
      shared = MacroData(eiaApiKey: key, koreaEximApiKey: eximKey);
    }
    return shared;
  }

  static const definitions = <MacroDefinition>[
    (
      id: 'DCOILBRENTEU',
      name: '브렌트 원유',
      group: '원자재',
      unit: '달러/배럴',
      rate: false,
      publisher: '미국 EIA',
    ),
    (
      id: 'DCOILWTICO',
      name: 'WTI 원유',
      group: '원자재',
      unit: '달러/배럴',
      rate: false,
      publisher: '미국 EIA',
    ),
    (
      id: 'EXIM_USDKRW',
      name: '원/달러 환율',
      group: '환율',
      unit: '원/달러',
      rate: false,
      publisher: '한국수출입은행',
    ),
    (
      id: 'DTWEXBGS',
      name: '달러 지수 · 광의',
      group: '환율',
      unit: '지수 (2006=100)',
      rate: false,
      publisher: '미국 연준 H.10',
    ),
    (
      id: 'DGS2',
      name: '미국 국채 2년',
      group: '금리',
      unit: '%',
      rate: true,
      publisher: '미국 재무부',
    ),
    (
      id: 'DGS10',
      name: '미국 국채 10년',
      group: '금리',
      unit: '%',
      rate: true,
      publisher: '미국 재무부',
    ),
  ];
  final String? _eiaApiKey;
  final String? _koreaEximApiKey;
  final String? _eximHistoryJson;
  final http.Client _client;
  final _documents = <String, ({DateTime expires, Future<String> body})>{};

  /// Coalesces shared annual Treasury feeds and bounds upstream requests.
  Future<String> _document(Uri uri, DateTime now) {
    final key = uri.toString();
    final cached = _documents[key];
    if (cached != null && cached.expires.isAfter(now)) return cached.body;
    final future = () async {
      try {
        final response = await _client
            .get(uri)
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200 ||
            response.bodyBytes.length > 15000000) {
          throw const FormatException('Invalid official response');
        }
        return utf8.decode(response.bodyBytes);
      } catch (_) {
        _documents.remove(key);
        rethrow;
      }
    }();
    _documents[key] = (
      expires: now.add(const Duration(hours: 1)),
      body: future,
    );
    return future;
  }

  Future<({List<IndexPoint> points, String title, String url})> _load(
    MacroDefinition d,
    DateTime now,
    DateTime from,
  ) async {
    if (d.id == 'EXIM_USDKRW') {
      final key = _koreaEximApiKey;
      if (key == null) {
        throw const FormatException('Missing exchange credentials');
      }
      final observations = <DateTime, double>{};
      final historyText =
          _eximHistoryJson ??
          await File('assets/macro/exim_usdkrw.json').readAsString();
      final history = jsonDecode(historyText) as Map<String, dynamic>;
      if (history['seriesId'] != d.id) {
        throw const FormatException('Wrong exchange history');
      }
      final rows = (history['points'] as List).cast<Map<String, dynamic>>();
      final cacheDirectory =
          Platform.environment['MACRO_CACHE_DIRECTORY'] ??
          '.serverpod/macro-cache';
      final cacheFile = File('$cacheDirectory/exim_usdkrw.json');
      if (_eximHistoryJson == null && await cacheFile.exists()) {
        try {
          final cached = jsonDecode(
            await cacheFile.readAsString(),
          ) as Map<String, dynamic>;
          if (cached['seriesId'] == d.id) {
            rows.addAll(
              (cached['points'] as List).cast<Map<String, dynamic>>(),
            );
          }
        } catch (_) {
          // Discard unreadable cache; immutable official seed remains intact.
        }
      }
      final historical = parseCsv(
        'observation_date,${d.id}\n${{for (final r in rows) r['date']: r['value']}.entries.map((r) => '${r.key},${r.value}').join('\n')}',
        d.id,
        now: now,
        from: from,
      );
      for (final point in historical) {
        observations[point.date] = point.value;
      }
      // Korean reference dates; holiday responses remain absent.
      final koreaNow = now.add(const Duration(hours: 9));
      final today = DateTime.utc(koreaNow.year, koreaNow.month, koreaNow.day);
      final latest = await Future.wait([
        for (var offset = 0; offset < 7; offset++)
          () async {
            final date = today.subtract(Duration(days: offset));
            if (date.weekday == DateTime.saturday ||
                date.weekday == DateTime.sunday) {
              return <IndexPoint>[];
            }
            final uri = Uri.https(
              'oapi.koreaexim.go.kr',
              '/site/program/financial/exchangeJSON',
              {
                'authkey': key,
                'data': 'AP01',
                'searchdate': _date(date).replaceAll('-', ''),
              },
            );
            return parseExim(
              await _document(uri, now),
              date,
              now: today.add(const Duration(days: 1)),
              from: from,
            );
          }(),
      ]);
      for (final points in latest) {
        for (final point in points) {
          observations[point.date] = point.value;
        }
      }
      final dates = observations.keys.toList()..sort();
      if (_eximHistoryJson == null) {
        await cacheFile.parent.create(recursive: true);
        final temp = File('${cacheFile.path}.tmp');
        await temp.writeAsString(
          jsonEncode({
            'seriesId': d.id,
            'points': [
              for (final date in dates)
                {'date': _date(date), 'value': observations[date]},
            ],
          }),
        );
        await temp.rename(cacheFile.path);
      }
      return (
        points: [
          for (final date in dates)
            IndexPoint(date: date, value: observations[date]!),
        ],
        title: '한국수출입은행 · 일별 매매기준율',
        url: 'https://www.koreaexim.go.kr/ir/HPHKIR020M01?apino=2',
      );
    }
    if (d.id == 'ECB_USDKRW') {
      const url =
          'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.xml';
      final body = await _document(Uri.parse(url), now);
      return (
        points: parseEcb(body, now: now, from: from),
        title: 'ECB · 유로 기준환율에서 원/달러 환산',
        url: url,
      );
    }
    if (d.rate) {
      try {
        final annual = await Future.wait([
          for (var year = from.year; year <= now.year; year++)
            _document(
              Uri.https(
                'home.treasury.gov',
                '/resource-center/data-chart-center/interest-rates/pages/xml',
                {
                  'data': 'daily_treasury_yield_curve',
                  'field_tdr_date_value': '$year',
                },
              ),
              now,
            ),
        ]);
        final points = [
          for (final body in annual)
            ...parseTreasury(body, d.id, now: now, from: from),
        ]..sort((a, b) => a.date.compareTo(b.date));
        if (points.isEmpty) {
          throw const FormatException('No Treasury observations');
        }
        return (
          points: points,
          title: '미국 재무부 · 일별 국채 파 수익률',
          url: 'https://home.treasury.gov/resource-center-data-chart-center/interest-rates/TextView?type=daily_treasury_yield_curve',
        );
      } catch (_) {
        // FRED carries the same CMT series; never substitute another maturity.
      }
    }
    if (_eiaApiKey != null && d.group == '원자재') {
      try {
        final code = d.id == 'DCOILWTICO' ? 'RWTC' : 'RBRTE';
        final body = await _document(
          Uri.https('api.eia.gov', '/v2/petroleum/pri/spt/data/', {
            'api_key': _eiaApiKey,
            'frequency': 'daily',
            'data[0]': 'value',
            'facets[series][]': code,
            'start': _date(from),
            'end': _date(now),
            'sort[0][column]': 'period',
            'sort[0][direction]': 'asc',
            'length': '5000',
          }),
          now,
        );
        final points = parseEia(body, code, now: now, from: from);
        if (points.isEmpty) throw const FormatException('No EIA observations');
        return (
          points: points,
          title: '미국 EIA · 일별 현물가격 API',
          url: 'https://www.eia.gov/dnav/pet/pet_pri_spt_s1_d.htm',
        );
      } catch (_) {
        // No keys or authenticated request URLs are exposed in Source or logs.
      }
    }
    final uri = Uri.https('fred.stlouisfed.org', '/graph/fredgraph.csv', {
      'id': d.id,
      'cosd': _date(from),
      'coed': _date(now),
    });
    return (
      points: parseCsv(await _document(uri, now), d.id, now: now, from: from),
      title:
          '${d.publisher} · FRED 공식 배포${d.rate || _eiaApiKey != null && d.group == '원자재' ? ' (원기관 연결 실패 대체)' : ''}',
      url: 'https://fred.stlouisfed.org/series/${d.id}',
    );
  }

  static List<IndexPoint> parseExim(
    String body,
    DateTime date, {
    required DateTime now,
    required DateTime from,
  }) {
    final data = jsonDecode(body);
    if (data == null) return [];
    if (data is! List) throw const FormatException('Invalid exchange response');
    for (final row in data) {
      if (row is! Map || row['result'] != 1) {
        throw const FormatException('Exchange request rejected');
      }
    }
    final usd = data.where((row) => row['cur_unit'] == 'USD').toList();
    if (usd.isEmpty) return [];
    if (usd.length != 1) throw const FormatException('Duplicate USD rates');
    final raw = usd.single['deal_bas_r'];
    if (raw is! String ||
        !RegExp(r'^\d+(?:,\d{3})*(?:\.\d+)?$').hasMatch(raw)) {
      throw const FormatException('Invalid reference rate');
    }
    final value = double.parse(raw.replaceAll(',', ''));
    if (value <= 0) throw const FormatException('Invalid reference rate');
    return parseCsv(
      'observation_date,EXIM_USDKRW\n${_date(date)},$value',
      'EXIM_USDKRW',
      now: now,
      from: from,
    );
  }

  static List<IndexPoint> parseTreasury(
    String body,
    String id, {
    required DateTime now,
    required DateTime from,
  }) {
    if (id != 'DGS2' && id != 'DGS10') {
      throw const FormatException('Unknown maturity');
    }
    final doc = XmlDocument.parse(body);
    if (doc.rootElement.name.local != 'feed') {
      throw const FormatException('Invalid Treasury feed');
    }
    final rows = <String>[];
    for (final row in doc.findAllElements(
      'properties',
      namespaceUri:
          'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata',
    )) {
      String? field(String name) => row
          .getElement(
            name,
            namespaceUri:
                'http://schemas.microsoft.com/ado/2007/08/dataservices',
          )
          ?.innerText;
      final date = field('NEW_DATE');
      final value = field(id == 'DGS2' ? 'BC_2YEAR' : 'BC_10YEAR');
      if (date == null || date.length < 10) {
        throw const FormatException('Missing Treasury date');
      }
      rows.add(
        '${date.substring(0, 10)},${value == null || value.isEmpty ? '.' : value}',
      );
    }
    return parseCsv(
      'observation_date,$id\n${rows.join('\n')}',
      id,
      now: now,
      from: from,
    );
  }

  static List<IndexPoint> parseEcb(
    String body, {
    required DateTime now,
    required DateTime from,
  }) {
    final doc = XmlDocument.parse(body);
    if (doc.rootElement.name.local != 'Envelope') {
      throw const FormatException('Invalid ECB feed');
    }
    final rows = <String>[];
    for (final row in doc.findAllElements(
      'Cube',
      namespaceUri: 'http://www.ecb.int/vocabulary/2002-08-01/eurofxref',
    )) {
      final date = row.getAttribute('time');
      if (date == null) continue;
      final rates = <String, double>{};
      for (final currency in row.childElements) {
        final code = currency.getAttribute('currency');
        if (code != 'USD' && code != 'KRW') continue;
        final rate = double.tryParse(currency.getAttribute('rate') ?? '');
        if (rate == null ||
            !rate.isFinite ||
            rate <= 0 ||
            rates.containsKey(code)) {
          throw const FormatException('Invalid ECB rate');
        }
        rates[code!] = rate;
      }
      if (rates.length == 2) rows.add('$date,${rates['KRW']! / rates['USD']!}');
    }
    return parseCsv(
      'observation_date,ECB_USDKRW\n${rows.join('\n')}',
      'ECB_USDKRW',
      now: now,
      from: from,
    );
  }

  static List<IndexPoint> parseEia(
    String body,
    String code, {
    required DateTime now,
    required DateTime from,
  }) {
    final root = jsonDecode(body) as Map<String, dynamic>;
    final response = root['response'] as Map<String, dynamic>;
    final data = response['data'] as List;
    if (int.parse('${response['total']}') != data.length) {
      throw const FormatException('Truncated EIA response');
    }
    final rows = <String>[];
    for (final row in data.cast<Map<String, dynamic>>()) {
      if (row['series'] != code || row['units'] != r'$/BBL') {
        throw const FormatException('Wrong EIA series or units');
      }
      rows.add('${row['period']},${row['value'] ?? '.'}');
    }
    return parseCsv(
      'observation_date,$code\n${rows.join('\n')}',
      code,
      now: now,
      from: from,
    );
  }

  final DateTime Function() _now;
  final _values = <String, MacroSeriesView>{};
  final _retryAt = <String, DateTime>{};
  Future<List<MacroSeriesView>>? _pending;

  Future<List<MacroSeriesView>> overview() async {
    if (_pending != null) return _pending!;
    final pending = Future.wait(definitions.map(_read));
    _pending = pending;
    try {
      return await pending;
    } finally {
      _pending = null;
    }
  }

  Future<MacroSeriesView> _read(MacroDefinition d) async {
    final now = _now().toUtc();
    final old = _values[d.id];
    if (_retryAt[d.id]?.isAfter(now) ?? false) return old!;
    try {
      final from = DateTime.utc(
        now.year - 3,
        now.month,
        now.day,
      ).subtract(const Duration(days: 10));
      final loaded = await _load(d, now, from);
      final points = loaded.points;
      if (points.isEmpty) throw const FormatException('No observations');
      final stale = now.difference(points.last.date).inDays > 14;
      final view = MacroSeriesView(
        seriesId: d.id,
        name: d.name,
        group: d.group,
        unit: d.unit,
        rate: d.rate,
        source: Source(
          kind: SourceKind.officialFile,
          title: loaded.title,
          reference: d.id,
          url: loaded.url,
          retrievedAt: now,
        ),
        points: points,
        status: stale ? 'stale' : 'ready',
        message: stale ? '최근 관측값이 14일 이상 경과했습니다.' : null,
      );
      _values[d.id] = view;
      _retryAt[d.id] = now.add(const Duration(hours: 1));
      return view;
    } catch (_) {
      final view = MacroSeriesView(
        seriesId: d.id,
        name: d.name,
        group: d.group,
        unit: d.unit,
        rate: d.rate,
        source: old?.source,
        points: old?.points ?? [],
        status: old != null && old.points.isNotEmpty ? 'stale' : 'unavailable',
        message: old != null && old.points.isNotEmpty
            ? '갱신에 실패해 이전 자료를 표시합니다.'
            : '공식 자료를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
      _values[d.id] = view;
      _retryAt[d.id] = now.add(const Duration(minutes: 5));
      return view;
    }
  }

  /// Reject wrong series, HTML, malformed/conflicting rows and future dates.
  /// Missing observations are omitted, never replaced by zero or forward-filled.
  static List<IndexPoint> parseCsv(
    String csv,
    String id, {
    required DateTime now,
    required DateTime from,
  }) {
    final lines = const LineSplitter().convert(csv.trim());
    if (lines.isEmpty ||
        lines.first.replaceFirst('\uFEFF', '') != 'observation_date,$id') {
      throw const FormatException('Unexpected series header');
    }
    final observations = <DateTime, double>{};
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cells = line.split(',');
      if (cells.length != 2 ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cells[0])) {
        throw const FormatException('Malformed observation');
      }
      final date = DateTime.tryParse('${cells[0]}T00:00:00Z');
      if (date == null || _date(date) != cells[0] || date.isAfter(now)) {
        throw const FormatException('Invalid date');
      }
      if (cells[1].isEmpty || cells[1] == '.') continue;
      final value = double.tryParse(cells[1]);
      if (value == null || !value.isFinite) {
        throw const FormatException('Invalid value');
      }
      if (observations.containsKey(date) && observations[date] != value) {
        throw const FormatException('Conflicting observations');
      }
      if (!date.isBefore(from)) observations[date] = value;
    }
    final dates = observations.keys.toList()..sort();
    return [
      for (final date in dates)
        IndexPoint(date: date, value: observations[date]!),
    ];
  }

  static String _date(DateTime value) =>
      value.toIso8601String().substring(0, 10);
}
