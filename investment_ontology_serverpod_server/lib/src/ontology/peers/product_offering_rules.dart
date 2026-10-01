import 'dart:convert';
import 'dart:io';

/// Rules for the issuer's structured primary-products field, not full-text
/// keyword search. Source columns and legal-entity identity are handled upstream.
abstract final class ProductOfferingRules {
  static final definitions = (jsonDecode(
    File('assets/discovery/product_offering_rules.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  static final _compiled = [
    for (final r in definitions)
      (
        r,
        RegExp(r['pattern'] as String, caseSensitive: false),
        RegExp(r['exclude'] as String, caseSensitive: false),
      ),
  ];
  static List<(String, String, String, String)> match(
    String products,
    String registeredSector,
  ) {
    final matches = <(String, String, String, String)>[];
    for (final (r, pattern, exclude) in _compiled) {
      if (!(r['registeredSectors'] as List).contains(registeredSector)) {
        continue;
      }
      for (final span in pattern.allMatches(products)) {
        // English abbreviations must be whole tokens (TV is not TVRO).
        if ((span.start > 0 &&
                RegExp(r'[A-Za-z]').hasMatch(products[span.start - 1]) &&
                RegExp(r'^[A-Za-z]').hasMatch(span.group(0)!)) ||
            (span.end < products.length &&
                RegExp(r'[A-Za-z]').hasMatch(products[span.end]) &&
                RegExp(r'[A-Za-z]$').hasMatch(span.group(0)!))) {
          continue;
        }
        final suffix = products.substring(span.end);
        // A trailing shared modifier governs a coordinated product list too:
        // '세탁기, 에어컨 및 LCD 부품' does not establish finished appliances.
        if ({'생활가전', '가전제품', '디스플레이'}.contains(r['group']) &&
            RegExp(r'(?:부품|부분품|소재)(?:\s*등)?$').hasMatch(products.trim()) &&
            !RegExp(r'제조|판매|생산|공급').hasMatch(products)) {
          continue;
        }
        final componentGroup = RegExp(r'부품|소재|원료|소모품|판재|선재|전자파 차폐')
            .hasMatch(r['group'] as String);
        if (RegExp(r'^\s*(?:제조\s*검사|제조\s*장비|검사\s*장비|용\s*(?:장비|부품|소재))')
                .hasMatch(suffix) ||
            (!componentGroup &&
                RegExp(r'^\s*(?:부품|부분품|소재|원료)').hasMatch(suffix))) {
          continue;
        }
        final start = span.start == 0
            ? -1
            : products.lastIndexOf(RegExp(r'[,;/]'), span.start - 1);
        final end = products.indexOf(RegExp(r'[,;/]'), span.end);
        final clause = products.substring(
          start < 0 ? 0 : start + 1,
          end < 0 ? products.length : end,
        );
        if (RegExp(r'계획|예정|추진|검토|중단|철수|사업종료|생산종료|매각|과거|않|아닌')
            .hasMatch(clause)) {
          continue;
        }
        if ((r['exclude'] as String).isNotEmpty && exclude.hasMatch(clause)) {
          continue;
        }
        matches.add((
          r['industry'] as String,
          r['group'] as String,
          'offering:${r['id']}',
          r['label'] as String? ?? r['group'] as String,
        ));
        break;
      }
    }
    // An umbrella is not a second peer group beside its own specific subtype.
    if (matches.any((m) => m.$1 == 'auto' && m.$2 != '자동차 부품')) {
      matches.removeWhere((m) => m.$1 == 'auto' && m.$2 == '자동차 부품');
    }
    if (matches.any((m) => m.$1 == 'cosmetics' && m.$2 == '화장품 위탁개발·생산')) {
      matches.removeWhere((m) => m.$1 == 'cosmetics' && m.$2 == '화장품');
    }
    return matches;
  }
}
