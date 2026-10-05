import '../../generated/protocol.dart';

/// Current offerings only, in an explicit products/services section. A pipeline
/// and its approval/development status are distinct from the current product mix.
abstract final class CurrentProductRows {
  static final _section = RegExp(r'주요\s*(제품|상품|서비스)');
  static final _notCurrent = RegExp(
    r'파이프라인|pipeline|개발\s*(중|단계|예정)|기획\s*단계|탐색\s*단계|임상|협력기관|인허가|경쟁사|타사|종속회사|자회사',
    caseSensitive: false,
  );
  static final _name = RegExp(
    r'^(주요)?(제품(명|군)?|상품(명)?|품목|서비스(명)?)(및(서비스|용역))?$',
  );
  static String normalize(String value) =>
      value.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static List<BusinessProduct> parse(String text) {
    final products = <BusinessProduct>[];
    var active = false;
    var blocked = false;
    List<String>? header;
    int? nameColumn;
    int? detailColumn;
    int? descriptionColumn;
    var group = '';
    for (final raw in text.split('\n')) {
      final trimmed = raw.trim();
      if (trimmed.startsWith('##')) {
        // Top-level section boundaries reset attribution; nested headings can
        // only narrow it and must never reactivate a pipeline on their own.
        if (RegExp(r'^##\s*\d+[.\s]').hasMatch(trimmed) ||
            _section.hasMatch(trimmed)) {
          active = _section.hasMatch(trimmed);
          blocked = false;
        }
        blocked = blocked || _notCurrent.hasMatch(trimmed);
        header = null;
        nameColumn = null;
        group = '';
        continue;
      }
      if (!active) continue;
      if (!trimmed.contains('|')) {
        header = null;
        nameColumn = null;
        group = '';
        if (trimmed.isNotEmpty) blocked = _notCurrent.hasMatch(trimmed);
        continue;
      }
      final cells = raw.split('|').map((c) => c.trim()).toList();
      final names = cells.map(normalize).toList();
      final index = names.indexWhere((c) => _name.hasMatch(c));
      if (index >= 0) {
        header = cells;
        nameColumn = index;
        detailColumn = names.indexWhere(
          (c) => c == '세부제품' || c == '세부상품' || c == '세부서비스',
        );
        descriptionColumn = names.indexWhere(
          (c) => c == '설명' || c == '제품설명' || c == '서비스설명',
        );
        blocked = blocked || _notCurrent.hasMatch(raw);
        group = '';
        continue;
      }
      if (blocked ||
          header == null ||
          nameColumn == null ||
          _notCurrent.hasMatch(raw)) {
        continue;
      }
      var row = cells;
      // Only the explicitly named family/detail/description shape supports
      // omission of the repeated family cell. Other ragged tables are skipped.
      if (nameColumn == 0 &&
          detailColumn == 1 &&
          descriptionColumn == 2 &&
          header.length == 3 &&
          cells.length == 2 &&
          group.isNotEmpty) {
        row = [group, ...cells];
      }
      if (row.length != header.length) {
        header = null;
        nameColumn = null;
        continue;
      }
      final family = row[nameColumn];
      if (family.isNotEmpty && family != '-') group = family;
      final detail = detailColumn != null && detailColumn >= 0
          ? row[detailColumn]
          : '';
      final label = detail.isEmpty || detail == '-'
          ? family
          : '${family.isEmpty ? group : family} · $detail';
      final identity = normalize(label);
      if (identity.isEmpty ||
          label.length > 90 ||
          RegExp(r'합계|총계|기타|구분|매출액|매출비중|^[-\d,.%\s]+$').hasMatch(label)) {
        continue;
      }
      if (products.any((p) => normalize(p.name) == identity)) continue;
      products.add(
        BusinessProduct(
          key: 'product/current/$identity',
          name: label,
          role: descriptionColumn != null && descriptionColumn >= 0
              ? row[descriptionColumn]
              : '',
          process: '',
          benefit: '',
          evidence: raw,
          explanationKind: 'source_only',
        ),
      );
    }
    return products;
  }
}
