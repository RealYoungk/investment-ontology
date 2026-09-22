/// 예약 시각까지의 실제 간격. 전체 데이터 수집 완료 예상과는 구분한다.
String scheduleCountdown(DateTime at, DateTime now, {bool resuming = false}) {
  final remaining = at.difference(now);
  if (remaining <= Duration.zero) return '예약 시각 지남 · 실행 대기 중';
  // 아직 남은 1초 미만을 0초로 표시하지 않는다.
  final seconds = (remaining.inMicroseconds / Duration.microsecondsPerSecond)
      .ceil();
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final rest = seconds % 60;
  final duration = [
    if (hours > 0) '$hours시간',
    if (hours > 0 || minutes > 0) '$minutes분',
    '$rest초',
  ].join(' ');
  return '${resuming ? '이어받기' : '다음 수집'}까지 $duration 남음';
}
