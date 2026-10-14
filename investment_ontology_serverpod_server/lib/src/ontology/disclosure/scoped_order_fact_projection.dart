import '../../generated/protocol.dart';
import 'order_facts.dart';

/// Read-only revalidation; the original persisted record is never modified.
abstract final class ScopedOrderFactProjection {
  static bool handles(DocumentFact fact) =>
      fact.extractedBy == RelationOrigin.api &&
      {
        DocumentFactKind.orderTotal,
        DocumentFactKind.orderDelivered,
        DocumentFactKind.orderBacklog,
      }.contains(fact.kind);

  /// A failed/unsupported parse is not proof that a historical fact is wrong.
  /// Reject only an explicitly supported row whose numeric grammar/equation fails.
  static List<DocumentFact> revalidate(
    List<DocumentFact> facts,
    String text, {
    String? companyName,
  }) {
    if (!facts.any(handles)) return facts;
    final rejected = <String>{};
    final ambiguous = <String>{};
    final components = <OrderFactSourceRow>[];
    final rows = OrderFacts.parse(
      text,
      rejectedEvidence: rejected,
      verifiedRows: components,
      ambiguousEvidence: ambiguous,
    );
    final result = <DocumentFact>[];
    for (final fact in facts) {
      if (!handles(fact)) {
        result.add(fact);
        continue;
      }
      final scope = explicitScope(
        text,
        fact.evidence.trim(),
        companyName: companyName,
      );
      final scopeNote = scope == null
          ? ''
          : ' 원문 명시 $scope 범위이며 제출회사 전체 수주 합계로 단정하지 않음.';
      String scopedLabel(String label) =>
          scope == null || label.startsWith('$scope · ')
          ? label
          : '$scope · $label';
      var matches = rows
          .where((r) => r.evidence == fact.evidence.trim())
          .toList();
      if (matches.isEmpty) {
        matches = components
            .where((r) => r.evidence == fact.evidence.trim())
            .toList();
      }
      final equivalent =
          matches.length > 1 &&
          _equivalentSourceProofs(matches, fact, text, companyName);
      if (matches.length == 1 || equivalent) {
        final row = matches.first;
        result.add(
          fact.copyWith(
            label: scopedLabel(equivalent ? fact.label : row.label),
            value: switch (fact.kind) {
              DocumentFactKind.orderTotal => row.total,
              DocumentFactKind.orderDelivered => row.delivered,
              _ => row.backlog,
            },
            unit: row.unit,
            reviewedBy: '표 규칙 · 현재 금액 열 및 수주 차감식 재검산(허용오차 0.5%)',
            reviewNote:
                '${row.total} − ${row.delivered} ≈ ${row.backlog} (${row.unit}); 차감 잔차 ${row.total - row.delivered - row.backlog}, 허용오차 0.5%. ${equivalent ? "동일 문서·기간·범위·금액·단위 중복 근거를 하나로 확인함; 기존 라벨 유지. " : ""}명시 금액 열 사용, 수량·환율차이 칸과 구분.$scopeNote',
          ),
        );
      } else if (!rejected.contains(fact.evidence.trim()) &&
          !ambiguous.contains(fact.evidence.trim())) {
        // Absent, composed or currently unsupported evidence remains unresolved.
        result.add(
          fact.copyWith(
            label: scopedLabel(fact.label),
            reviewedBy: '과거 승인값 · 현재 표 규칙 재검산 미확인',
            reviewNote:
                '현재 지원 표에서 고유한 금액 행을 확인하지 못해 기존 승인값을 보존함. 현재 차감식 검산 일치로 재확인한 값은 아님.$scopeNote',
          ),
        );
      }
    }
    return result;
  }

  static bool _equivalentSourceProofs(
    List<OrderFactSourceRow> matches,
    DocumentFact fact,
    String text,
    String? companyName,
  ) {
    final date = fact.asOf;
    if (companyName == null || date == null || date.year != fact.bsnsYear) {
      return false;
    }
    final numbers = {
      for (final m in matches)
        (
          m.total,
          m.delivered,
          m.backlog,
          m.unit,
          m.label.contains(' · ') ? m.label.split(' · ').first : '',
        ),
    };
    if (numbers.length != 1) return false;
    final lines = text.split('\n');
    final occurrences = [
      for (var i = 0; i < lines.length; i++)
        if (lines[i].trim() == fact.evidence.trim()) i,
    ];
    if (occurrences.length != matches.length) return false;
    final scopes = <String>{};
    for (final at in occurrences) {
      scopes.add(
        explicitScope(
              text,
              fact.evidence.trim(),
              companyName: companyName,
              sourceLineIndex: at,
            ) ??
            companyName,
      );
      // The caller already validates source document/company/report provenance.
      // Default period is that exact report's approved asOf. An explicit local
      // table date/year must agree; conflicting dates never collapse.
      for (var i = at - 1; i >= 0 && i >= at - 45; i--) {
        final line = lines[i].trim();
        if (line.startsWith('##')) break;
        if ((line.contains('|') && !line.contains('단위')) ||
            !RegExp(r'기준일|기말\s*현재|년말\s*현재|작성기준').hasMatch(line)) {
          continue;
        }
        final dates = RegExp(r'(20\d{2})[.\-/](\d{1,2})[.\-/](\d{1,2})')
            .allMatches(line);
        for (final d in dates) {
          if (int.parse(d.group(1)!) != date.year ||
              int.parse(d.group(2)!) != date.month ||
              int.parse(d.group(3)!) != date.day) {
            return false;
          }
        }
        final years = RegExp(r'(20\d{2})\s*년').allMatches(line);
        if (years.any((y) => int.parse(y.group(1)!) != date.year)) return false;
      }
    }
    return scopes.length == 1;
  }

  /// Only source-named business scopes, with a bounded window and no guessing.
  static String? explicitScope(
    String text,
    String evidence, {
    String? companyName,
    int? sourceLineIndex,
  }) {
    final lines = text.split('\n');
    final at =
        sourceLineIndex ?? lines.indexWhere((line) => line.trim() == evidence);
    if (at < 0) return null;
    String? scope;
    for (var i = at - 1; i >= 0 && i >= at - 45; i--) {
      final line = lines[i].trim();
      if (line.startsWith('##')) break;
      final namedStatement = RegExp(
        r'(?:아래와 같으며,?|같으며,?)\s*((?:\(주\)|㈜|주식회사)?[가-힣A-Za-z0-9]+)(?:은|는)\s*수주산업',
      ).firstMatch(line);
      if (namedStatement != null) {
        scope = namedStatement.group(1);
        break;
      }
      final heading = RegExp(
        r'^■\s*[^|]*부문\s*[:：]\s*((?:\(주\)|㈜|주식회사)?[가-힣A-Za-z0-9]+)\s*$',
      ).firstMatch(line);
      if (heading != null) {
        scope = heading.group(1);
        break;
      }
    }
    if (scope == null || {'당사', '회사'}.contains(scope)) {
      // A section-local explicit alias is stronger than an inferred name.
      for (var i = at - 1; i >= 0; i--) {
        final line = lines[i].trim();
        if (line.startsWith('##')) break;
        final alias = RegExp(
          r'^((?:주식회사|\(주\)|㈜)[가-힣A-Za-z0-9\s]+)\(이하\s*[“\"「]당사[”\"」]\)',
        ).firstMatch(line);
        if (alias != null) {
          scope = alias.group(1)?.trim();
          break;
        }
      }
    }
    if (scope == null || {'당사', '회사'}.contains(scope)) return null;
    String normalize(String name) =>
        name.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
    if (companyName != null && normalize(scope) == normalize(companyName)) {
      return null;
    }
    return scope;
  }
}
