import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';

typedef MacroDefinition = ({
  String id,
  String name,
  String group,
  String unit,
  bool rate,
  String publisher,
});

/// FRED distributes these EIA/Federal Reserve public-domain series.
/// Fixed allowlist: callers cannot supply URLs or create shared facts.
class MacroData {
  MacroData({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static final shared = MacroData();
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
      id: 'DEXKOUS',
      name: '원/달러 환율',
      group: '환율',
      unit: '원/달러',
      rate: false,
      publisher: '미국 연준 H.10',
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
      publisher: '미국 연준 H.15',
    ),
    (
      id: 'DGS10',
      name: '미국 국채 10년',
      group: '금리',
      unit: '%',
      rate: true,
      publisher: '미국 연준 H.15',
    ),
  ];
  final http.Client _client;
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
      final uri = Uri.https('fred.stlouisfed.org', '/graph/fredgraph.csv', {
        'id': d.id,
        'cosd': _date(from),
        'coed': _date(now),
      });
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.bodyBytes.length > 1000000) {
        throw const FormatException('Invalid official response');
      }
      final points = parseCsv(
        utf8.decode(response.bodyBytes),
        d.id,
        now: now,
        from: from,
      );
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
          title: '${d.publisher} · FRED 공식 배포',
          reference: d.id,
          url: 'https://fred.stlouisfed.org/series/${d.id}',
          retrievedAt: now,
        ),
        points: points,
        status: stale ? 'stale' : 'ready',
        message: stale ? '최근 관측값이 14일 이상 경과했습니다.' : null,
      );
      _values[d.id] = view;
      _retryAt[d.id] = now.add(const Duration(hours: 6));
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
