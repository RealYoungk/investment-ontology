import 'dart:math' as math;

/// 축 눈금: 1·2·5 단위로 떨어지는 값. 기본은 0을 포함한다 (막대는 0에서 자라야 한다).
class ChartScale {
  ChartScale._(this.min, this.max, this.ticks);

  /// [values]의 범위를 덮는 눈금을 약 [targetTicks]개로 만든다. 값이 없으면 0~1.
  ///
  /// [includeZero]가 false이면 값의 범위만 덮는다 — 주가처럼 0에서 먼 값은
  /// 0을 넣으면 움직임이 눌려 보인다.
  factory ChartScale.of(
    Iterable<double> values, {
    int targetTicks = 4,
    bool includeZero = true,
  }) {
    if (targetTicks < 1) {
      throw ArgumentError.value(targetTicks, 'targetTicks', 'must be positive');
    }
    double? lo, hi;
    if (includeZero) {
      lo = 0.0;
      hi = 0.0;
    }
    for (final v in values) {
      if (!v.isFinite) continue;
      lo = lo == null ? v : math.min(lo, v);
      hi = hi == null ? v : math.max(hi, v);
    }
    lo ??= 0.0;
    hi ??= 0.0;
    if (lo == hi) hi = lo + 1;
    var step = _niceStep((hi - lo) / targetTicks);
    // 0을 넣지 않기로 했는데 눈금이 굵어 바닥이 0으로 떨어지면 (주가 8만~36만에
    // 눈금 10만) 아래 눈금이 값보다 작아지도록 한 단계 줄인다.
    if (!includeZero && lo > 0 && step > lo) {
      final candidate = _niceStep(lo, down: true);
      final count = (hi / candidate).ceil() - (lo / candidate).floor() + 1;
      // A low starting price must not produce hundreds of labels after a rally.
      // includeZero=false permits a zero tick; it does not require excluding it.
      if (count <= targetTicks * 2) step = candidate;
    }
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

  /// [raw]에 가까운 1·2·5 단위. [down]이면 [raw]를 넘지 않는 가장 큰 단위.
  static double _niceStep(double raw, {bool down = false}) {
    final exp = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / exp;
    final nice = down
        ? (f >= 5
              ? 5
              : f >= 2
              ? 2
              : 1)
        : (f < 1.5
              ? 1
              : f < 3
              ? 2
              : f < 7
              ? 5
              : 10);
    return nice * exp;
  }
}
