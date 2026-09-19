import 'package:serverpod/serverpod.dart';

/// 수집이 하루 몫을 다 썼을 때 다음 날 이어받기를 예약하는 함수.
///
/// FutureCall 파일은 생성 코드(`futureCalls`)를 참조하는 [IngestSchedule]을 가져오지 않는다.
/// 가져오면 `serverpod start`의 코드 생성기가 생성 코드가 없던 때의 분석 결과로 그 FutureCall을
/// 오류로 보고 생성에서 빼는 순환에 빠진다 (2026-09-19 DisclosureFutureCall에서 겪음).
/// 그래서 서버가 켜질 때 [IngestSchedule.onServerStart]가 여기에 예약 함수를 넣는다.
abstract final class ResumeHooks {
  static Future<void> Function(Session session, DateTime at)? disclosures;
}
