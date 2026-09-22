import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/data_sync/widgets/schedule_countdown.dart';

void main() {
  final now = DateTime.utc(2026, 9, 22, 15);
  test('남은 시간을 시간·분·초로 표시하고 하루를 넘어도 누적 시간으로 보인다', () {
    expect(
      scheduleCountdown(
        now.add(const Duration(hours: 26, minutes: 4, seconds: 3)),
        now,
      ),
      '다음 수집까지 26시간 4분 3초 남음',
    );
    expect(
      scheduleCountdown(
        now.add(const Duration(seconds: 61)),
        now,
        resuming: true,
      ),
      '이어받기까지 1분 1초 남음',
    );
  });
  test('1초 미만은 올림하고 예약 시각이 지나면 음수 대신 실행 대기를 표시한다', () {
    expect(
      scheduleCountdown(now.add(const Duration(milliseconds: 1)), now),
      '다음 수집까지 1초 남음',
    );
    expect(scheduleCountdown(now, now), '예약 시각 지남 · 실행 대기 중');
    expect(
      scheduleCountdown(now.subtract(const Duration(seconds: 1)), now),
      '예약 시각 지남 · 실행 대기 중',
    );
  });
}
