import '../../generated/protocol.dart';
import 'product_taxonomy.dart';

/// Product-section matches, never a declaration of competitive equivalence.
abstract final class PeerRules {
  static const version = 7;
  static final _productHeading = RegExp(r'주요\s*제품|주요\s*상품');
  static final _stopHeading = RegExp(r'^##\s*\d+[.\s]');
  static final _excluded = RegExp(
    r'경쟁사|경쟁업체|개발\s*예정|개발\s*중|연구\s*개발|특허|타사|타\s*업체|검사기.{0,8}보유|검사장비.{0,8}도입',
  );
  static final _equipment = RegExp(
    r'검사|검출|inspection|\bAOI\b',
    caseSensitive: false,
  );
  static final patterns = <String, (String, RegExp)>{
    'substrate': (
      '기판·Flip-chip 검사',
      RegExp(r'FC[\s-]?BGA|반도체\s*기판|flip[\s-]?chip', caseSensitive: false),
    ),
    'wafer': ('웨이퍼 검사', RegExp(r'웨이퍼|wafer', caseSensitive: false)),
    'smt': (
      'SMT·실장 검사',
      RegExp(r'\bSMT\b|부품\s*실장|납\s*도포|\bSPI\b', caseSensitive: false),
    ),
    'display': ('디스플레이 검사', RegExp(r'디스플레이|OLED|LCD', caseSensitive: false)),
    'battery': ('이차전지 검사', RegExp(r'이차전지|2차전지|배터리')),
    'optical': (
      '광학·외관 검사',
      RegExp(
        r'\bAOI\b|자동\s*광학\s*검사|외관\s*검사|광학.{0,25}검사|optical\s*inspection',
        caseSensitive: false,
      ),
    ),
    'electrical': (
      '전기적 검사',
      RegExp(
        r'전기적.{0,20}검사|전기적.{0,20}테스트|테스트\s*핸들러|test\s*handler|메모리\s*테스터',
        caseSensitive: false,
      ),
    ),
    'repair': ('자동광학수리', RegExp(r'\bAOR\b|자동\s*광학\s*수리', caseSensitive: false)),
  };
  static const targets = {'substrate', 'wafer', 'smt', 'display', 'battery'};

  static List<PeerSignal> focuses(List<PeerSignal> signals) => [
    ...signals.where((s) => targets.contains(s.key)),
    ...signals.where(
      (s) =>
          s.key.startsWith('product/') && !s.key.startsWith('product/exact/'),
    ),
    ...signals.where((s) => s.key.startsWith('product/exact/')),
  ];

  static List<PeerSignal> parse(String text) {
    final found = <String, PeerSignal>{};
    var inProducts = false;
    var prices = false;
    int? productColumn;
    int? tableWidth;
    var combinedAmount = false;
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) {
        productColumn = null;
        tableWidth = null;
        prices = false;
        if (_productHeading.hasMatch(line)) {
          inProducts = true;
        } else if (_stopHeading.hasMatch(line)) {
          inProducts = false;
        }
        continue;
      }
      if (!inProducts || line.trim().isEmpty || _excluded.hasMatch(line)) {
        continue;
      }
      if (_productHeading.hasMatch(line) && !line.contains('가격')) {
        prices = false;
      }
      if (RegExp(r'가격\s*변동|가격변동|원재료').hasMatch(line)) {
        productColumn = null;
        tableWidth = null;
        prices = true;
      }
      final cells = line.split('|').map((c) => c.trim()).toList();
      if (cells.any((c) => RegExp(r'^매출액\s*\(비율\)$').hasMatch(c))) {
        final i = cells.indexWhere(
          (c) => RegExp(r'^매출액\s*\(비율\)$').hasMatch(c),
        );
        cells.replaceRange(i, i + 1, ['매출액', '비율']);
      }
      final headers = cells
          .map((c) => c.replaceAll(RegExp(r'\s'), ''))
          .toList();
      final index = headers.indexWhere(
        (c) => RegExp(r'^(주요제품(및용역)?|주요제품명|품목|제품명|주요상품)$').hasMatch(c),
      );
      if (!prices && cells.length > 1 && index >= 0) {
        productColumn = index;
        tableWidth = cells.length;
        combinedAmount = RegExp(r'매출액\s*\(비율\)').hasMatch(line);
      } else if (productColumn != null &&
          (cells.length == tableWidth ||
              (combinedAmount &&
                  cells.length == tableWidth! - 1 &&
                  RegExp(r'^[\d,]+\s*\([\d.]+%\)$').hasMatch(cells.last)))) {
        final cell = cells[productColumn];
        for (final (key, label) in ProductTaxonomy.match(cell)) {
          found.putIfAbsent(
            key,
            () => PeerSignal(key: key, label: label, evidence: line),
          );
        }
      }
      // One sentence/table row: don't combine a customer's wafer with our AOI.
      final pieces = line.split(RegExp(r'(?<=[.!?])\s+'));
      for (final piece in pieces) {
        if (piece.length > 1200) continue;
        for (final entry in patterns.entries) {
          if (found.containsKey(entry.key)) continue;
          final match = entry.value.$2.firstMatch(piece);
          if (match == null) continue;
          if (targets.contains(entry.key) && !_equipment.hasMatch(piece)) {
            continue;
          }
          // Keep an exact, bounded source excerpt around the product match.
          final start = (match.start - 100).clamp(0, piece.length);
          final end = (match.end + 260).clamp(0, piece.length);
          found[entry.key] = PeerSignal(
            key: entry.key,
            label: entry.value.$1,
            evidence: piece.substring(start, end),
          );
        }
      }
    }
    // A target without an identifiable equipment method is insufficient.
    if (!found.containsKey('optical') && !found.containsKey('electrical')) {
      found.removeWhere((key, _) => !key.startsWith('product/'));
    }
    return found.values.toList();
  }

  static ({
    int score,
    String tier,
    List<String> reasons,
    List<String> differences,
  })?
  match(
    List<PeerSignal> anchor,
    List<PeerSignal> candidate, {
    String? anchorIndustry,
    String? candidateIndustry,
  }) {
    final a = {for (final s in anchor) s.key};
    final b = {for (final s in candidate) s.key};
    final shared = a.intersection(b);
    final methods = shared.intersection({'optical', 'electrical'});
    final commonTargets = shared.intersection(targets);
    final products = shared.where((k) => k.startsWith('product/')).toSet();
    final sameIndustry =
        anchorIndustry != null &&
        candidateIndustry != null &&
        anchorIndustry.length >= 2 &&
        candidateIndustry.length >= 2 &&
        anchorIndustry.substring(0, 2) == candidateIndustry.substring(0, 2);
    final equipmentMatch = methods.isNotEmpty && commonTargets.isNotEmpty;
    if (!equipmentMatch && (products.isEmpty || !sameIndustry)) return null;
    final relevant = equipmentMatch
        ? shared.where((k) => !k.startsWith('product/')).toSet()
        : products;
    // Require both target and method; never fill slots with method-only peers.
    return (
      score:
          100 +
          (equipmentMatch
              ? commonTargets.length * 20 + methods.length * 10
              : products.length * 20) -
          (a.length + b.length - 2 * shared.length),
      tier: 'product',
      reasons: [
        for (final s in anchor)
          if (relevant.contains(s.key)) s.label,
      ],
      differences: [
        for (final s in anchor)
          if (!b.contains(s.key)) '기준 기업 공시: ${s.label}',
        for (final s in candidate)
          if (!a.contains(s.key)) '후보 기업 공시: ${s.label}',
        '동일 공정·직접 경쟁 여부 미확인',
        '매출 구성·고객 일치 미확인',
      ],
    );
  }
}
