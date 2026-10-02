/// Stored-only, exact-integer reconciliation of issuer CB face balances.
/// A missing series is never a zero; a price adjustment is never conversion.
abstract final class BondTrends {
  static String? series(Object? value) {
    final s = value?.toString().replaceAll(RegExp(r'\s+'), '') ?? '';
    final m = RegExp(r'^(?:제)?(\d+)(?:회차|회)?$').firstMatch(s);
    return m == null ? null : int.parse(m[1]!).toString();
  }

  static BigInt? won(Map<String, dynamic> row) {
    final scale = switch (row['unit']) {
      '원' => 1,
      '천원' => 1000,
      '백만원' => 1000000,
      _ => null,
    };
    final value = BigInt.tryParse('${row['balance']}');
    return scale == null ||
            value == null ||
            value < BigInt.zero ||
            row['balanceValidation'] != 'verified'
        ? null
        : value * BigInt.from(scale);
  }

  static String? identity(Map<String, dynamic> row) {
    final number = series(row['series']);
    final issue = row['issueDate']?.toString();
    final printedKind = row['stockKind']?.toString().replaceAll(
      RegExp(r'\s+'),
      '',
    );
    final kind =
        printedKind != null &&
            RegExp(r'^(?:기명식)?보통주(?:식)?$').hasMatch(printedKind)
        ? '보통주'
        : printedKind;
    if (number == null ||
        issue == null ||
        kind == null ||
        kind.isEmpty ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(issue)) {
      return null;
    }
    return '$number|$issue|$kind';
  }

  /// [periods] includes uncollected final corrections; callers bind snapshots
  /// to those exact receipts. Dates must be chronological. No external calls.
  static Map<String, dynamic> build(List<Map<String, dynamic>> periods) {
    final points = <Map<String, dynamic>>[];
    final changes = <Map<String, dynamic>>[];
    Map<String, dynamic>? previous;
    for (final period in periods) {
      final rows = ((period['entries'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .where((r) => r['type'] == 'CB')
          .toList();
      final state = (period['balanceStates'] as Map?)?['CB'] ?? 'missing';
      final complete =
          period['state'] == 'ready' &&
          (state == 'none' || state == 'verified') &&
          rows.every((r) => won(r) != null);
      final balance = complete
          ? rows.fold(BigInt.zero, (sum, r) => sum + won(r)!)
          : null;
      final sharesVerified =
          complete && rows.every((r) => r['validation'] == 'verified');
      final shares = sharesVerified
          ? rows.fold(
              BigInt.zero,
              (sum, r) => sum + BigInt.parse('${r['shares']}'),
            )
          : null;
      final point = <String, dynamic>{
        'periodEnd': period['periodEnd'],
        'receipt': period['receipt'],
        'reportName': period['reportName'],
        'collectedAt': period['collectedAt'],
        'sourceUrl':
            'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${period['receipt']}',
        'state': period['state'] == 'ready' ? state : 'notCollected',
        'balanceWon': balance?.toString(),
        'potentialShares': shares?.toString(),
        'entries': rows,
      };
      points.add(point);
      if (previous != null) {
        final before = (previous['entries'] as List)
            .cast<Map<String, dynamic>>();
        final old = <String, Map<String, dynamic>>{};
        final duplicates = <String>{};
        for (final row in before) {
          final key = identity(row);
          if (key == null) continue;
          if (old.containsKey(key)) duplicates.add(key);
          old[key] = row;
        }
        final currentKeys = rows.map(identity).whereType<String>().toList();
        for (final key in currentKeys.toSet()) {
          if (currentKeys.where((k) => k == key).length > 1) {
            duplicates.add(key);
          }
        }
        var matched = 0;
        var difference = BigInt.zero;
        for (final row in rows) {
          final key = identity(row);
          final from = key == null || duplicates.contains(key)
              ? null
              : old[key];
          final a = from == null ? null : won(from), b = won(row);
          // A partial/missing source can omit duplicate or disambiguating rows.
          final comparable =
              previous['balanceWon'] != null &&
              balance != null &&
              a != null &&
              b != null;
          final delta = comparable ? a - b : null;
          if (delta != null) {
            matched++;
            difference += delta;
          }
          changes.add({
            'series': row['series'],
            'issueDate': row['issueDate'],
            'stockKind': row['stockKind'],
            'fromDate': previous['periodEnd'],
            'toDate': point['periodEnd'],
            'fromReceipt': previous['receipt'],
            'toReceipt': point['receipt'],
            'beforeWon': a?.toString(),
            'afterWon': b?.toString(),
            'netDecreaseWon': delta?.toString(),
            'beforePrice': from?['price'],
            'afterPrice': row['price'],
            'beforeShares': from?['shares'],
            'afterShares': row['shares'],
            'reason': comparable
                ? null
                : key == null
                ? '회차·발행일·주식 종류 식별 미확보'
                : duplicates.contains(key)
                ? '동일 회차 중복으로 비교 불가'
                : from == null
                ? '이전 보고서에 같은 회차 미확보'
                : '한쪽 보고서의 잔액 표 또는 단위 미확보',
            'confirmedConversionWon': null,
            'confirmedRedemptionWon': null,
            'unexplainedDecreaseWon': delta != null && delta > BigInt.zero
                ? delta.toString()
                : null,
            'eventState': 'notCollected',
          });
        }
        // Preserve disappearing rows explicitly. Absence is not redemption.
        for (final row in before) {
          final key = identity(row);
          if (key != null && currentKeys.contains(key)) continue;
          changes.add({
            'series': row['series'],
            'issueDate': row['issueDate'],
            'stockKind': row['stockKind'],
            'fromDate': previous['periodEnd'],
            'toDate': point['periodEnd'],
            'fromReceipt': previous['receipt'],
            'toReceipt': point['receipt'],
            'beforeWon': won(row)?.toString(),
            'afterWon': null,
            'netDecreaseWon': null,
            'reason': '현재 보고서에서 같은 회차 미확보 · 잔액 0으로 간주하지 않음',
          });
        }
        point['matchedSeries'] = matched;
        point['matchedNetDecreaseWon'] = matched == 0
            ? null
            : difference.toString();
        // Only equal, fully identified series sets allow an issuer-level sum.
        point['netDecreaseWon'] =
            matched == rows.length &&
                matched == before.length &&
                balance != null &&
                previous['balanceWon'] != null
            ? (BigInt.parse('${previous['balanceWon']}') - balance).toString()
            : null;
        point['fromDate'] = previous['periodEnd'];
      }
      previous = point;
    }
    return {
      'version': 1,
      'state': points.any((p) => p['balanceWon'] != null)
          ? 'ready'
          : 'notCollected',
      'points': points,
      'changes': changes,
      'collectedPeriods': periods.where((p) => p['state'] == 'ready').length,
      'expectedPeriods': periods.length,
      'eventState': 'notCollected',
    };
  }
}
