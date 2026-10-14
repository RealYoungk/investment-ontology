import '../../generated/protocol.dart';
import 'market_share_facts.dart';
import 'recovered_market_share_facts.dart';
import 'holding_source_scope.dart';

/// Read-only recovery of rule observations. Unsupported/manual prose is kept.
abstract final class StoredMarketShareProjection {
  static final _year = RegExp(
    r"^(?:'?[0-9]{2}|(?:19|20)[0-9]{2})\s*년?(?:도)?\s*(?:상반기|반기|1분기|3분기)?(?:말)?$",
  );

  /// Only the parser's flat year-table shape can prove a legacy row unsupported.
  /// Do not turn a parser miss in another table shape into a rejection.
  static Set<String> supportedEvidence(String text) {
    final lines = text.split('\n');
    final result = <String>{};
    for (var i = 0; i < lines.length; i++) {
      final h = lines[i].split('|').map((v) => v.trim()).toList();
      if (h.length < 3 || !h.skip(1).every(_year.hasMatch)) continue;
      final context = lines
          .sublist(i > 15 ? i - 15 : 0, (i + 7).clamp(0, lines.length))
          .join('\n');
      if (!context.contains('점유율')) continue;
      for (var j = i + 1; j < lines.length && lines[j].contains('|'); j++) {
        final c = lines[j].split('|').map((v) => v.trim()).toList();
        if (c.length < 3 ||
            c
                    .skip(1)
                    .where(
                      (v) =>
                          RegExp(r"(?:19|20)\d{2}|^'?[0-9]{2}\s*년").hasMatch(v),
                    )
                    .length >=
                2) {
          break;
        }
        // Flat text labels followed solely by numeric/percent cells.
        if (c
            .skip(1)
            .every(
              (v) =>
                  RegExp(r'^\d+(?:\.\d+)?%?$').hasMatch(v) ||
                  v == '-' ||
                  v.isEmpty,
            )) {
          result.add(lines[j].trim());
        }
      }
    }
    return result;
  }

  /// Explicit table-local issuer-product wording preserves already stored
  /// observations in a multi-product shape the current parser does not read.
  static Set<String> explicitOwnProductEvidence(String text) {
    final lines = text.split('\n');
    final out = <String>{};
    for (var i = 0; i < lines.length; i++) {
      final h = lines[i].split('|').map((v) => v.trim()).toList();
      if (h.length < 3 ||
          h.skip(1).where(_year.hasMatch).length < 2 ||
          h.any((v) => RegExp(r'회사명|회사|제조사|업체').hasMatch(v))) {
        continue;
      }
      var end = i + 1;
      for (; end < lines.length && lines[end].contains('|'); end++) {}
      final before = lines.sublist(i > 3 ? i - 3 : 0, i).join('\n');
      final after = lines
          .sublist(end, (end + 2).clamp(0, lines.length))
          .join('\n');
      final explicit =
          RegExp(r'당사(?:의)?[^\n]{0,50}(?:사업부문별|제품별|품목별)[^\n]{0,30}시장\s*점유율')
              .hasMatch(before) ||
          RegExp(r'대비\s*당사\s*매출수량\s*비율').hasMatch(after);
      if (!explicit) continue;
      for (var j = i + 1; j < end; j++) {
        out.add(lines[j].trim());
      }
    }
    return out;
  }

  /// A direct issuer declaration, not mention of an investee holding company.
  static bool declaresHolding(String text) =>
      HoldingSourceScope.declaresHolding(text);

  static bool bareDataYearCollision(String evidence) {
    final years = evidence
        .split('|')
        .skip(1)
        .map((c) => c.trim())
        .where((c) => RegExp(r"^'?[0-9]{2}$").hasMatch(c))
        .toList();
    return years.length >= 2 && years.length == years.toSet().length;
  }

  static List<DocumentFact> recover(
    BusinessDocument doc,
    DisclosureReport report,
    List<DocumentFact> existing, {
    required String owner,
    String? industryCode,
    bool holding = false,
  }) => RecoveredMarketShareFacts.project(
    doc,
    report,
    existing,
    owner: owner,
    industryCode: industryCode,
    holding: holding,
  );

  static List<DocumentFact> project(
    List<DocumentFact> facts,
    BusinessDocument doc, {
    required String owner,
    String? industryCode,
    bool holding = false,
  }) {
    final parsed = MarketShareFacts.parse(
      doc.text,
      owner: owner,
      bsnsYear: doc.bsnsYear,
    );
    final supported = supportedEvidence(doc.text);
    final ownProducts = explicitOwnProductEvidence(doc.text);
    return [
      for (final f in facts)
        if (f.documentId != doc.id ||
            f.kind != DocumentFactKind.marketShare ||
            f.extractedBy != RelationOrigin.api ||
            f.extractorModel != '표 규칙')
          f
        else if (!holding &&
            !declaresHolding(doc.text) &&
            industryCode != '64992' &&
            (parsed.any(
                  (r) =>
                      r.evidence.trim() == f.evidence.trim() &&
                      (r.value - f.value).abs() < 1e-8 &&
                      f.unit == '%' &&
                      f.asOf?.year == r.year &&
                      f.asOf?.month == r.month,
                ) ||
                ownProducts.contains(f.evidence.trim()) ||
                !supported.contains(f.evidence.trim())))
          f,
    ];
  }
}
