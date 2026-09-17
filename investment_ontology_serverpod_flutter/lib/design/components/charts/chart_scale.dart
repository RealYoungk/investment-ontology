import 'dart:math' as math;

/// 축 눈금: 0을 포함하고 1·2·5 단위로 떨어지는 값.
class ChartScale {
  ChartScale._(this.min, this.max, this.ticks);

  /// [values]의 범위를 덮는 눈금을 약 [targetTicks]개로 만든다. 값이 없으면 0~1.
  factory ChartScale.of(Iterable<double> values, {int targetTicks = 4}) {
    var lo = 0.0, hi = 0.0;
    for (final v in values) {
      if (!v.isFinite) continue;
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
    if (lo == hi) hi = lo + 1;
    final step = _niceStep((hi - lo) / targetTicks);
    final min = (lo / step).floorToDouble() * step;
    final max = (hi / step).ceilToDouble() * step;
    final ticks = <double>[
      for (var t = min; t <= max + step / 2; t += step)
        // 부동소수 오차로 -0.0000001 같은 값이 생기지 않게 반올림.
        (t / step).roundToDouble() * step,
    ];
    return ChartScale._(min, max, ticks);
  }

  final double min;
  final double max;
  final List<double> ticks;

  /// 값 → 0(아래)~1(위).
  double fraction(double v) => (v - min) / (max - min);

  static double _niceStep(double raw) {
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / exp;
    // 가장 가까운 1·2·5 단위로 반올림한다.
    final nice = f < 1.5
        ? 1
        : f < 3
        ? 2
        : f < 7
        ? 5
        : 10;
    return nice * exp;
  }
}
