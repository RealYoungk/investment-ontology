import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/latest_business_body_coverage.dart';

void main() {
  final profiles = RegExp(
    r"\('(\d{14})','(\d{14})','(\d{8})','(\d{4}\.\d{2})',(\d{4}),'(annual|halfYear)'\)",
  ).allMatches(LatestBusinessBodyCoverage.verifiedFamilies).toList();
  test('공식 가족목록으로 검증한 정확한 10개만 사용한다', () {
    expect(profiles, hasLength(10));
    expect(profiles.map((x) => x[1]).toSet(), hasLength(10));
  });
  for (final p in profiles) {
    test('${p[1]} 원문 가족목록·법인코드·보고서 종류 증거', () {
      final raw = File(
        'test/fixtures/business-latest-family/${p[1]}-shell.html',
      ).readAsStringSync();
      final corp = RegExp(r"openCorpInfoNew\('(\d{8})'")
          .allMatches(raw)
          .map((m) => m[1])
          .toSet();
      expect(corp, {p[3]});
      final families = RegExp(
        r'<select\b[^>]*id="family"[^>]*>(.*?)</select>',
        dotAll: true,
      ).allMatches(raw).toList();
      expect(families, hasLength(1));
      final options = RegExp(r'<option\b([^>]*)>(.*?)</option>', dotAll: true)
          .allMatches(families.single[1]!)
          .where((m) => m[1]!.contains('rcpNo=${p[2]}'))
          .toList();
      expect(options, hasLength(1));
      expect(
        options.single[1],
        contains('title="${p[6] == 'annual' ? '사업보고서' : '반기보고서'}"'),
      );
      expect(int.parse(p[2]!), lessThan(int.parse(p[1]!)));
    });
  }
}
