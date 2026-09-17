import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// 외부 API 일일 호출 한도 관리.
///
/// 한도는 KST 날짜 기준으로 초기화된다고 보고, 제공자별로 [ApiCallUsage]에 합산한다.
abstract final class ApiCallBudget {
  /// DART 키당 일일 한도 (약 20,000건).
  static const dartDailyLimit = 20000;

  /// 재무 수집이 하루에 쓸 수 있는 DART 호출 수. 나머지는 기업마스터 수집 몫으로 남긴다.
  static const dartFinancialBudget = 18000;

  static const _kstOffset = Duration(hours: 9);

  /// [now] 시각의 KST 날짜 (YYYY-MM-DD).
  static String kstDay(DateTime now) {
    final k = now.toUtc().add(_kstOffset);
    return '${k.year.toString().padLeft(4, '0')}-'
        '${k.month.toString().padLeft(2, '0')}-'
        '${k.day.toString().padLeft(2, '0')}';
  }

  /// [now] 이후 처음 오는 KST 자정 (UTC).
  static DateTime nextKstMidnight(DateTime now) {
    final k = now.toUtc().add(_kstOffset);
    return DateTime.utc(k.year, k.month, k.day + 1).subtract(_kstOffset);
  }

  /// 오늘(KST) 사용한 호출 수.
  static Future<int> usedToday(
    Session session,
    ApiProvider provider, {
    DateTime? now,
  }) async {
    final row = await ApiCallUsage.db.findFirstRow(
      session,
      where: (t) =>
          t.provider.equals(provider) &
          t.day.equals(kstDay(now ?? DateTime.now())),
    );
    return row?.calls ?? 0;
  }

  /// 호출 수를 더한다. 동시에 도는 작업끼리 덮어쓰지 않도록 DB에서 더한다.
  static Future<void> record(
    Session session,
    ApiProvider provider,
    int calls, {
    DateTime? now,
  }) async {
    if (calls <= 0) return;
    await session.db.unsafeExecute(
      'INSERT INTO "api_call_usage" ("provider", "day", "calls") '
      'VALUES (@provider, @day, @calls) '
      'ON CONFLICT ("provider", "day") '
      'DO UPDATE SET "calls" = "api_call_usage"."calls" + EXCLUDED."calls"',
      parameters: QueryParameters.named({
        'provider': provider.name,
        'day': kstDay(now ?? DateTime.now()),
        'calls': calls,
      }),
    );
  }
}

/// 클라이언트의 누적 호출 수를 읽어, 마지막 기록 이후 늘어난 만큼만 [ApiCallBudget]에 더한다.
class ApiCallMeter {
  ApiCallMeter(this.provider, this._readCalls);

  final ApiProvider provider;
  final int Function() _readCalls;
  int _recorded = 0;

  Future<void> flush(Session session) async {
    final calls = _readCalls();
    final delta = calls - _recorded;
    if (delta <= 0) return;
    await ApiCallBudget.record(session, provider, delta);
    _recorded = calls;
  }
}
