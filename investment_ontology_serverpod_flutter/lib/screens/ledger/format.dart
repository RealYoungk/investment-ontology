import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

String marketLabel(Market? m) => switch (m) {
  Market.kospi => '유가',
  Market.kosdaq => '코스닥',
  Market.konex => '코넥스',
  Market.other => '기타',
  null => '—',
};

/// YYYYMMDD → YYYY.MM.DD
String formatYmd(String? ymd) {
  if (ymd == null || ymd.length != 8) return ymd ?? '—';
  return '${ymd.substring(0, 4)}.${ymd.substring(4, 6)}.${ymd.substring(6)}';
}

String formatCount(int n) => n.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

String formatDateTime(DateTime dt) {
  final l = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${l.year}.${two(l.month)}.${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}
