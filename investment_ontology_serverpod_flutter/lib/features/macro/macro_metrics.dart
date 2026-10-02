import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

abstract final class MacroMetrics {
  static String value(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$integer.${parts.last}';
  }

  static IndexPoint? base(List<IndexPoint> points, int days) {
    if (points.length < 2) return null;
    if (days == 0) {
      final previous = points[points.length - 2];
      return points.last.date.difference(previous.date).inDays <= 7
          ? previous
          : null;
    }
    final target = points.last.date.subtract(Duration(days: days));
    for (final point in points.reversed) {
      if (!point.date.isAfter(target)) {
        return target.difference(point.date).inDays <= 7 ? point : null;
      }
    }
    return null;
  }

  static double? change(MacroSeriesView series, IndexPoint? base) {
    if (base == null || series.points.isEmpty) return null;
    final last = series.points.last.value;
    if (series.rate) return last - base.value;
    // Negative oil prices exist historically; relative changes need a positive base.
    return base.value > 0 ? (last / base.value - 1) * 100 : null;
  }

  static String delta(MacroSeriesView s, double? value) => value == null
      ? '자료 부족'
      : '${value > 0 ? '+' : ''}${value.toStringAsFixed(2)}${s.rate ? '%p' : '%'}';
}
