import 'dart:convert';
import 'dart:io';

import '../../generated/protocol.dart';

/// Human-readable aliases of registered activities, never inferred products.
/// Longest prefix wins, within the registered sector. This table covers every
/// registered code currently used by the listed-company universe.
abstract final class RegisteredOfferings {
  static final definitions = (jsonDecode(
    File('assets/discovery/registered_offerings.json').readAsStringSync(),
  ) as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();

  static Map<String, dynamic>? definition(String industry, String code) {
    Map<String, dynamic>? best;
    var length = -1;
    for (final row in definitions) {
      if (row['industry'] != industry) continue;
      for (final prefix in (row['prefixes'] as List).cast<String>()) {
        if (code.startsWith(prefix) && prefix.length > length) {
          best = row;
          length = prefix.length;
        }
      }
    }
    return best;
  }

  static (String, String)? group(IndustryActivity a) {
    final row = definition(
      a.industryKey ?? '',
      a.productKey.replaceFirst('ksic:', ''),
    );
    if (row == null) return null;
    final label = row['label'] as String;
    return (role(a.industryKey ?? '', label), label);
  }

  static String role(String industry, String label) =>
      switch ((industry, label)) {
        ('semiconductor', '설계 IP') => 'design_ip',
        ('semiconductor', '설계 서비스') => 'design_service',
        ('semiconductor', '웨이퍼 제조 서비스') => 'foundry',
        ('semiconductor', '패키징·테스트 서비스') => 'osat',
        ('pharma', '연구·임상 지원') => 'research_service',
        ('pharma', '신약 개발·기술이전') => 'drug_discovery',
        ('pharma', '개발·생산 수탁') => 'cdmo',
        ('semiconductor', '칩 설계·제조') => 'chip',
        ('semiconductor', '장비') => 'equipment',
        ('pharma', '의약품·치료제') => 'drug',
        ('pharma', '의약 원료') => 'ingredient',
        ('software', '소프트웨어 제품') => 'software_product',
        ('software', 'IT 구축·운영') => 'it_service',
        ('software', '클라우드·인프라 서비스') => 'infrastructure',
        _ => 'business:$label',
      };
}
