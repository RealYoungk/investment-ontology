import 'package:serverpod/serverpod.dart';

typedef JobLauncher = Future<void> Function(Session session, int jobId);
typedef CompanyJobLauncher = Future<void> Function(
  Session session,
  int jobId,
  String corpCode,
);
typedef ResumeScheduler = Future<void> Function(Session session, DateTime at);

/// 수집 작업을 예약하는 함수들. 서버가 켜질 때 [IngestSchedule.onServerStart]가 넣는다.
///
/// 엔드포인트와 FutureCall 파일은 생성 코드(`futureCalls`)를 참조하는 IngestSchedule을 가져오지
/// 않고 이것만 쓴다. 가져오면 `serverpod start`의 코드 생성기가 새 FutureCall의 생성 코드가 아직
/// 없던 때의 분석 결과를 붙들고 그 엔드포인트·FutureCall을 생성에서 빼는 순환에 빠진다
/// (2026-09-19 DisclosureFutureCall, AiEndpoint에서 겪음).
abstract final class IngestHooks {
  static Future<void> Function(Session session, int jobId, bool force)?
  companyMasterNow;
  static ResumeScheduler? companyMasterResume;
  static JobLauncher? financialsNow;
  static CompanyJobLauncher? financialsForCompanyNow;
  static ResumeScheduler? financialsResume;
  static JobLauncher? marketSnapshotNow;
  static ResumeScheduler? marketSnapshotResume;
  static JobLauncher? businessDocumentsNow;
  static ResumeScheduler? businessDocumentsResume;
  static JobLauncher? disclosuresNow;
  static CompanyJobLauncher? disclosuresForCompanyNow;
  static ResumeScheduler? disclosures;
  static Future<void> Function(Session session, int jobId, int limit)?
  aiExtractionNow;

  /// 서버 시작 전(테스트 등)에 부르면 알기 쉽게 실패한다.
  static T require<T>(T? hook, String name) =>
      hook ?? (throw StateError('수집 예약 함수($name)가 아직 없습니다. 서버 시작 때 등록됩니다.'));
}
