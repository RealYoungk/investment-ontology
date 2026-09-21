import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// 사업보고서 본문의 "생산능력·생산실적·가동률" 표를 규칙으로 읽는다 (AI 없음).
///
/// 형식이 일정한 표만 받는다: 머리글에 생산능력·생산실적·가동률이 함께 있고, 각 줄의
/// 끝 세 칸이 (수, 수, 퍼센트)이며, 가동률이 생산실적 ÷ 생산능력과 맞아야 한다.
/// 하나라도 어긋나면 그 줄은 버린다 — 틀린 값을 넣느니 비워 두는 쪽이 낫다.
///
/// 이렇게 뽑은 값은 DART API로 받은 값과 같은 급으로 본다 (`extractedBy: api`,
/// 사람 검수 없이 확정). 표를 그대로 옮긴 것이고 숫자끼리 앞뒤가 맞는지 확인하기
/// 때문이다. 문장에서 읽어야 하는 값(수주잔고 등)은 여전히 AI가 뽑고 사람이 본다.
abstract final class ProductionFacts {
  /// 가동률과 (생산실적 ÷ 생산능력)의 차이가 이보다 크면 열을 잘못 읽은 것으로 본다.
  static const tolerance = 2.0;

  /// 한 문서에서 받아들이는 최대 줄 수. 표가 통째로 들어오는 것을 막는다.
  static const maxRows = 40;

  static final _number = RegExp(r'^-?[\d,]+(?:\.\d+)?$');

  /// 표의 한 줄에서 읽은 값.
  static List<
    ({
      String label,
      String unit,
      double capacity,
      double production,
      double utilization,
      String evidence,
    })
  >
  parse(String text) {
    final out =
        <
          ({
            String label,
            String unit,
            double capacity,
            double production,
            double utilization,
            String evidence,
          })
        >[];
    final lines = text.split('\n');
    var inTable = false;
    var unitFromHeader = '';
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final cells = [for (final c in line.split('|')) c.trim()];

      // 머리글: 생산능력·생산실적·가동률이 한 줄에 같이 있다.
      if (line.contains('생산능력') &&
          line.contains('생산실적') &&
          RegExp('가동률').hasMatch(line)) {
        inTable = true;
        unitFromHeader = _unitIn(line);
        continue;
      }
      if (!inTable) continue;
      // 숫자 줄이 아니면 표가 끝난 것으로 본다 (주석 ※ 등).
      if (cells.length < 4 || line.startsWith('※')) {
        if (!line.startsWith('※')) inTable = false;
        continue;
      }

      final last = cells.last;
      if (!last.endsWith('%')) continue;
      final util = double.tryParse(last.replaceAll(RegExp(r'[%,]'), ''));
      final cap = _num(cells[cells.length - 3]);
      final prod = _num(cells[cells.length - 2]);
      if (util == null || cap == null || prod == null || cap <= 0) continue;
      if ((util - 100 * prod / cap).abs() > tolerance) continue;

      final labels = [
        for (final c in cells.sublist(0, cells.length - 3))
          if (c.isNotEmpty && !_number.hasMatch(c)) c,
      ];
      if (labels.isEmpty) continue;
      // 마지막 글자 칸이 단위일 때가 많다 (백만개, 톤 …).
      final unit = _unitOf(labels.last, unitFromHeader);
      final name = [
        for (final l in labels)
          if (l != unit) l,
      ].join(' · ');
      if (name.isEmpty) continue;
      out.add((
        label: name.length > 60 ? name.substring(0, 60) : name,
        unit: unit,
        capacity: cap,
        production: prod,
        utilization: util,
        evidence: line,
      ));
      if (out.length >= maxRows) break;
    }
    return out;
  }

  static double? _num(String s) =>
      _number.hasMatch(s) ? double.tryParse(s.replaceAll(',', '')) : null;

  /// "(단위 : 백만개, %)" 처럼 적힌 단위.
  static String _unitIn(String line) {
    final m = RegExp(r'단위\s*[:：]\s*([^,)\]]+)').firstMatch(line);
    return m == null ? '' : m.group(1)!.trim();
  }

  /// 칸에 적힌 단위처럼 보이면 그것을, 아니면 머리글의 단위를 쓴다.
  static String _unitOf(String cell, String fromHeader) {
    const known = {
      '백만개',
      '천개',
      '개',
      '톤',
      '대',
      '천대',
      '백만원',
      '억원',
      '천㎡',
      '㎡',
      'MH',
      '배치',
      '억개',
      'GWh',
      '천톤',
    };
    if (known.contains(cell)) return cell;
    return known.contains(fromHeader) ? fromHeader : '';
  }

  /// 한 문서에서 읽어 저장한다. 이미 사람이 결정한 항목은 건드리지 않는다.
  static Future<int> store(Session session, BusinessDocument doc) async {
    final rows = parse(doc.text);
    if (rows.isEmpty) return 0;
    final report = await DisclosureReport.db.findById(session, doc.reportId);
    final existing = {
      for (final f in await DocumentFact.db.find(
        session,
        where: (t) => t.documentId.equals(doc.id!),
      ))
        '${f.kind.name}|${f.label}',
    };
    final now = DateTime.now().toUtc();
    final facts = <DocumentFact>[];
    for (final r in rows) {
      if (r.unit.isEmpty) continue;
      for (final (kind, value, unit) in [
        (DocumentFactKind.capacity, r.capacity, r.unit),
        (DocumentFactKind.production, r.production, r.unit),
        (DocumentFactKind.utilization, r.utilization, '%'),
      ]) {
        if (existing.contains('${kind.name}|${r.label}')) continue;
        facts.add(
          DocumentFact(
            companyId: doc.companyId,
            documentId: doc.id!,
            bsnsYear: doc.bsnsYear,
            kind: kind,
            label: r.label,
            value: value,
            unit: unit,
            asOf: DateTime.utc(doc.bsnsYear, 12, 31),
            evidence: r.evidence,
            sourceId: report?.sourceId,
            // 표를 그대로 옮긴 것이라 DART API로 받은 값과 같은 급으로 본다.
            extractedBy: RelationOrigin.api,
            extractorModel: '표 규칙',
            status: RelationStatus.verified,
            reviewedAt: now,
            reviewedBy: '표 규칙 (가동률 = 생산실적 ÷ 생산능력 확인)',
            createdAt: now,
          ),
        );
      }
    }
    if (facts.isEmpty) return 0;
    await DocumentFact.db.insert(session, facts);
    return facts.length;
  }
}
