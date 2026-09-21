import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// 사업보고서 본문에서 뽑은 값([DocumentFact])을 검증해 저장한다.
///
/// 관계 추출과 규칙이 같다. 근거 문장이 원문에 그대로 있어야 하고(공백 무시), 모두
/// 검수 대기(draft)로 들어가며, 사람이 이미 내린 결정은 다시 넣어도 유지된다.
abstract final class DocumentFacts {
  /// 한 문서에 넣을 수 있는 값의 수. 표 하나가 통째로 들어오는 것을 막는다.
  static const maxPerDocument = 60;

  static String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '');

  /// 근거가 원문에 그대로 있는지.
  static bool grounded(String evidence, String source) =>
      _squash(evidence).length >= 8 &&
      _squash(source).contains(_squash(evidence));

  /// 제출한 JSON을 값으로 바꾼다. 형식이 틀리면 [FormatException].
  ///
  /// ```json
  /// {"facts": [{"kind": "orderBacklog", "label": "건설사업", "value": 21292358,
  ///             "unit": "백만원", "asOf": "2025-12-31", "evidence": "…", "confidence": 0.9}]}
  /// ```
  static List<
    ({
      DocumentFactKind kind,
      String label,
      double value,
      String unit,
      DateTime? asOf,
      String evidence,
      double? confidence,
    })
  >
  parse(Map<String, dynamic> json) {
    final list = json['facts'];
    if (list is! List) throw const FormatException('facts 배열이 없습니다.');
    final kinds = {for (final k in DocumentFactKind.values) k.name: k};
    return [
      for (final raw in list.take(maxPerDocument))
        if (raw is Map<String, dynamic>)
          (
            kind:
                kinds[raw['kind']] ??
                (throw FormatException('모르는 kind: ${raw['kind']}')),
            label: '${raw['label'] ?? ''}'.trim(),
            value: (raw['value'] as num).toDouble(),
            unit: '${raw['unit'] ?? ''}'.trim(),
            asOf: _date(raw['asOf']),
            evidence: '${raw['evidence'] ?? ''}'.trim(),
            confidence: (raw['confidence'] as num?)?.toDouble(),
          ),
    ];
  }

  /// `2025-12-31` 같은 날짜는 그 날짜 그대로 둔다 (시간대 때문에 하루 밀리지 않게).
  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (m != null) {
      return DateTime.utc(
        int.parse(m[1]!),
        int.parse(m[2]!),
        int.parse(m[3]!),
      );
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  /// 검증을 통과한 값만 저장한다. 이 문서의 이전 draft는 지우고, 사람이 결정한 것은 남긴다.
  static Future<({int stored, int dropped})> store(
    Session session,
    BusinessDocument doc,
    List<
      ({
        DocumentFactKind kind,
        String label,
        double value,
        String unit,
        DateTime? asOf,
        String evidence,
        double? confidence,
      })
    >
    facts,
    String model,
  ) async {
    final report = await DisclosureReport.db.findById(session, doc.reportId);
    final now = DateTime.now().toUtc();
    // 같은 항목이라도 기준일이 다르면 다른 값이다 (한 표에 여러 해가 적히기도 한다).
    String keyOf(DocumentFactKind kind, String label, DateTime? asOf) =>
        '${kind.name}|$label|${asOf?.toIso8601String().substring(0, 10) ?? ''}';
    final decided = {
      for (final f in await DocumentFact.db.find(
        session,
        where: (t) =>
            t.documentId.equals(doc.id!) &
            t.status.notEquals(RelationStatus.draft),
      ))
        keyOf(f.kind, f.label, f.asOf),
    };
    final seen = <String>{};
    final rows = <DocumentFact>[];
    var dropped = 0;
    for (final f in facts) {
      final key = keyOf(f.kind, f.label, f.asOf);
      if (f.label.isEmpty ||
          f.unit.isEmpty ||
          !grounded(f.evidence, doc.text) ||
          decided.contains(key) ||
          !seen.add(key)) {
        dropped++;
        continue;
      }
      rows.add(
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: f.kind,
          label: f.label,
          value: f.value,
          unit: f.unit,
          asOf: f.asOf,
          evidence: f.evidence,
          sourceId: report?.sourceId,
          extractedBy: RelationOrigin.ai,
          extractorModel: model,
          confidence: f.confidence,
          status: RelationStatus.draft,
          createdAt: now,
        ),
      );
    }
    await session.db.transaction((tx) async {
      await DocumentFact.db.deleteWhere(
        session,
        where: (t) =>
            t.documentId.equals(doc.id!) &
            t.status.equals(RelationStatus.draft),
        transaction: tx,
      );
      if (rows.isNotEmpty) {
        await DocumentFact.db.insert(session, rows, transaction: tx);
      }
    });
    return (stored: rows.length, dropped: dropped);
  }
}
