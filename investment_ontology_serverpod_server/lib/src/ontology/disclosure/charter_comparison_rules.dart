import 'capital_structure_parser.dart';

/// Explicit comparison/history columns only; no inference from filing titles.
// Protocol dependency of classes declared with `extends Endpoint`.
// Refresh helper dependencies in Serverpod's incremental analyzer context.
abstract final class CharterComparisonRules {
  static const beforeNames = [
    '변경전내용',
    '변경전',
    '현행',
    '현행정관',
    '현행조문',
    '개정전',
    '개정전내용',
  ];
  static const afterNames = [
    '변경후내용',
    '변경후',
    '개정안',
    '개정(안)',
    '변경안',
    '개정정관',
    '개정조문',
    '개정후',
    '개정후내용',
  ];
  static String compact(String text) => text.replaceAll(RegExp(r'\s+'), '');

  static Map<String, dynamic> parse(String html) {
    final tables =
        RegExp(
              r'<TABLE\b[^>]*>.*?</TABLE>',
              caseSensitive: false,
              dotAll: true,
            )
            .allMatches(html)
            .where((m) {
              // Unrelated meeting tables can have hundreds of rowspan cells. Inspect
              // explicit header names before applying the bounded comparison grid.
              final cells =
                  RegExp(
                        r'<(TD|TH|TE|TU)\b[^>]*>(.*?)</\1>',
                        caseSensitive: false,
                        dotAll: true,
                      )
                      .allMatches(m[0]!)
                      .map((c) => compact(CapitalStructureParser.plain(c[2]!)))
                      .toSet();
              return cells.any(beforeNames.contains) &&
                      cells.any(afterNames.contains) ||
                  cells.any(['정관변경일', '변경일자'].contains) &&
                      cells.any(['주요변경사항', '변경내용'].contains);
            })
            .map((m) => CapitalStructureParser.grid(m[0]!))
            .toList();
    return fromTables(tables);
  }

  static Map<String, dynamic> fromTables(List<List<List<String>>> tables) {
    final history = <Map<String, dynamic>>[];
    final changes = <Map<String, dynamic>>[];
    String agenda = '', purpose = '';
    for (final table in tables) {
      if (table.isEmpty) continue;
      final headerIndex = table
          .take(6)
          .toList()
          .indexWhere(
            (r) =>
                (r.map(compact).any(beforeNames.contains) &&
                    r.map(compact).any(afterNames.contains)) ||
                r.map(compact).any(['정관변경일', '변경일자'].contains),
          );
      if (headerIndex < 0) continue;
      final headers = table[headerIndex].map(compact).toList();
      int column(List<String> names) => headers.indexWhere(names.contains);
      final before = column(beforeNames);
      final after = column(afterNames);
      final reason = column(['변경의목적', '변경목적', '변경이유', '개정사유', '개정이유', '비고']);
      final date = column(['정관변경일', '변경일자']);
      final content = column(['주요변경사항', '변경내용']);
      if (date >= 0 && content >= 0 && reason >= 0) {
        for (final row in table.skip(headerIndex + 1)) {
          if (row.length != headers.length) continue;
          final parsedDate = CapitalStructureParser.date(row[date]);
          if (parsedDate == null || row[content].trim().isEmpty) continue;
          history.add({
            'date': parsedDate,
            'content': row[content],
            'reason': row[reason],
          });
        }
        continue;
      }
      if (before < 0 || after < 0 || before == after) continue;
      purpose = '';
      final group = column(['구분']);
      for (final row in table.skip(headerIndex + 1)) {
        if (row.length != headers.length) continue;
        final old = row[before].trim(), next = row[after].trim();
        if (group >= 0 && row[group].trim().isNotEmpty) agenda = row[group];
        if (reason >= 0 && row[reason].trim().isNotEmpty) purpose = row[reason];
        // A page continuation has no new article title. Join only to the
        // immediately preceding row, preserving both source texts/pages.
        final article = RegExp(r'제\s*\d+\s*조(?:\s*의\s*\d+)?');
        if (!article.hasMatch(old) &&
            !article.hasMatch(next) &&
            (group < 0 || row[group].trim().isEmpty) &&
            changes.isNotEmpty) {
          final last = changes.last;
          last['before'] = '${last['before']}\n$old'.trim();
          last['after'] = '${last['after']}\n$next'.trim();
          continue;
        }
        if (old.isEmpty || next.isEmpty) continue;
        if (!article.hasMatch(old) && !article.hasMatch(next)) continue;
        changes.add({
          'agenda': agenda,
          'before': old,
          'after': next,
          'reason': purpose,
        });
      }
    }
    // Compare only after page continuations have restored the full article.
    changes.removeWhere(
      (row) =>
          compact(row['before'] as String) == compact(row['after'] as String),
    );
    for (final row in changes) {
      row.addAll(explain(row['before'] as String, row['after'] as String));
    }
    history.sort(
      (a, b) => (b['date'] as String).compareTo(a['date'] as String),
    );
    return {'history': history, 'changes': changes};
  }

  /// Finite, inspectable rules. Unknown changes keep the actual text.
  static Map<String, String> explain(String before, String after) {
    final b = compact(before), a = compact(after);
    if (b.contains('집중투표제') && b.contains('적용하지아니') && a.contains('삭제')) {
      return {
        'title': '집중투표를 막던 조항 삭제',
        'beforeShort': '이사 선임에 집중투표제 적용 제외',
        'afterShort': '적용 제외 조항 삭제',
        'meaning': '여러 이사를 뽑을 때 특정 후보에게 표를 모을 수 있는 집중투표를 정관에서 배제하지 않게 됩니다. 실제 적용 시점은 부칙을 따릅니다.',
        'topic': '의결권',
      };
    }
    if (b.contains('임기') &&
        b.contains('3년으로한다') &&
        (a.contains('3년을초과하지못') || a.contains('3년이내'))) {
      return {
        'title': '이사 임기: 3년 고정 → 최대 3년',
        'beforeShort': '임기는 3년',
        'afterShort': '임기는 3년 이내',
        'meaning': '3년보다 짧은 임기도 정할 수 있는 문구로 바뀝니다. 실제 선임 때 정하는 임기와 여러 이사의 선임 시기가 어떻게 나뉘는지가 주주의 견제에 중요한 확인 지점입니다.',
        'topic': '이사회 견제',
      };
    }
    if (b.contains('충실의무') && a.contains('회사및주주') && !b.contains('회사및주주')) {
      return {
        'title': '이사의 충실의무에 주주를 명시',
        'beforeShort': '회사를 위해 직무 수행',
        'afterShort': '회사와 주주를 위해 직무 수행',
        'meaning': '직무 수행의 대상에 주주를 명시합니다. 주주 이익 보호와 공평한 대우 문구가 함께 추가됐는지는 아래 개정문에서 확인할 수 있습니다.',
        'topic': '주주 보호',
      };
    }
    if (a.contains('감사위원') &&
        a.contains('분리') &&
        a.contains('2인') &&
        !b.contains('분리')) {
      return {
        'title': '감사위원 2명을 다른 이사와 분리 선출',
        'beforeShort': '분리 선출 인원 명시 없음',
        'afterShort': '감사위원 2명 분리 선출 명시',
        'meaning': '감사위원이 되는 이사를 다른 이사 선임과 별도로 뽑는 절차가 조문에 추가됩니다.',
        'topic': '감사·견제',
      };
    }
    if (a.contains('원격지') && a.contains('전자적방법') && !b.contains('원격지')) {
      return {
        'title': '원격으로 참여하는 전자주주총회 도입',
        'beforeShort': '주총 개최 장소만 규정',
        'afterShort': '전자적 방법으로 결의 참가 명시',
        'meaning':
            '현장에 직접 가지 않고 결의에 참여하는 주총 방식이 추가됩니다. 단순 온라인 중계와 다르며 시행일은 부칙을 따릅니다.',
        'topic': '주총 참여',
      };
    }
    if (b.contains('주식의소각') && a.contains('삭제')) {
      return {
        'title': '기존 주식 소각 조항 삭제',
        'beforeShort': '배당가능이익 범위에서 이사회 결의로 소각',
        'afterShort': '해당 정관 조항 삭제',
        'meaning': '정관의 기존 소각 조항을 삭제하는 변경입니다. 이 조항 삭제만으로 소각 금지나 실제 소각 계획의 취소를 뜻한다고 해석할 수는 없습니다.',
        'topic': '자기주식',
      };
    }
    if (a.contains('시행일')) {
      return {
        'title': '조항별 시행일을 부칙에 명시',
        'meaning':
            '같은 주총에서 바뀐 조항도 적용 시점이 다를 수 있습니다. 날짜와 대상 조항을 아래 원문 그대로 표시합니다.',
        'topic': '시행 시점',
      };
    }
    if (b.contains('사외이사') && a.contains('독립이사')) {
      return {
        'title': '사외이사 명칭을 독립이사로 변경',
        'meaning': '이사·위원회 명칭을 바꾸는 조문입니다. 명칭 변경만으로 실제 독립성이 개선됐다고 판정하지 않습니다.',
        'topic': '이사회',
      };
    }
    return {
      'title':
          RegExp(r'제\s*\d+\s*조(?:\s*의\s*\d+)?\s*\([^)]*\)')
              .firstMatch(before)
              ?.group(0) ??
          '정관 조문 변경',
      'topic': '기타 변경',
      'beforeShort': excerpt(before, after),
      'afterShort': excerpt(after, before),
      'meaning': '변경 부분의 원문을 발췌했습니다. 전체 조문과 회사의 변경 사유는 아래 원문에서 확인할 수 있습니다.',
    };
  }

  /// Character comparison only: preserve source words, never invent a meaning.
  static String excerpt(String source, String counterpart) {
    final a = source.replaceAll(RegExp(r'\s+'), ' ').trim();
    final b = counterpart.replaceAll(RegExp(r'\s+'), ' ').trim();
    var prefix = 0, suffix = 0;
    while (prefix < a.length && prefix < b.length && a[prefix] == b[prefix]) {
      prefix++;
    }
    while (suffix < a.length - prefix &&
        suffix < b.length - prefix &&
        a[a.length - suffix - 1] == b[b.length - suffix - 1]) {
      suffix++;
    }
    final start = (prefix - 30).clamp(0, a.length);
    final end = (a.length - suffix + 30).clamp(start, a.length);
    final boundedEnd = (start + 180).clamp(start, end);
    return '${start > 0 ? '…' : ''}${a.substring(start, boundedEnd)}${boundedEnd < a.length ? '…' : ''}';
  }
}
