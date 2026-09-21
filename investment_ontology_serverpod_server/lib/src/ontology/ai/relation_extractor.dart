import 'dart:convert';

import '../../generated/protocol.dart';
import '../disclosure/business_text.dart';
import '../disclosure/disclosure_values.dart';

/// 모델이 답한 관계 하나.
typedef ExtractedRelation = ({
  String type,
  String name,
  String evidence,
  double? confidence,
});

/// 사업보고서 본문 → AI 관계 후보 (4단계).
///
/// 원칙 3: AI는 글에서 관계만 뽑고, 근거 인용을 붙이고, 사람이 검수하기 전까지 draft다.
/// 인용이 원문에 그대로 없으면(모델이 지어냈으면) 버린다.
abstract final class RelationExtractor {
  /// 모델에 보내는 글의 최대 길이 (글자).
  static const maxChars = 60000;

  static const types = {'product', 'supplier', 'customer', 'competitor'};

  static const system =
      '너는 한국 상장사 사업보고서에서 기업 간 관계를 뽑는 도구다. '
      '원문에 적힌 것만 뽑고 추측하지 않는다. 근거 인용(evidence)은 원문을 한 글자도 바꾸지 않고 '
      '그대로 복사하며 200자를 넘지 않는다. 답은 JSON 하나로만 한다.';

  /// 관계를 찾을 만한 하위 절(사업의 개요·제품·원재료·매출·수주·경쟁)을 먼저, 나머지를 뒤에 붙여 자른다.
  static String excerpt(String text, {int? maxChars}) {
    final limit = maxChars == null
        ? RelationExtractor.maxChars
        : maxChars.clamp(500, RelationExtractor.maxChars);
    final sections = BusinessText.sections(text);
    bool useful(String title) => RegExp(
      r'개요|제품|서비스|원재료|매출|수주|경쟁|영업',
    ).hasMatch(title);
    final ordered = [
      for (final s in sections)
        if (useful(s.title)) s,
      for (final s in sections)
        if (!useful(s.title)) s,
    ];
    final buf = StringBuffer();
    for (final s in ordered) {
      if (buf.length >= limit) break;
      buf
        ..writeln('## ${s.title}')
        ..writeln(s.text);
    }
    final out = buf.toString();
    return out.length > limit ? out.substring(0, limit) : out;
  }

  static String prompt(String companyName, int bsnsYear, String excerpt) =>
      '''회사: $companyName
아래는 $companyName의 FY$bsnsYear 사업보고서 "II. 사업의 내용" 일부다. 다음 관계를 뽑아라.
- product: 이 회사가 만들거나 파는 주요 제품·서비스
- supplier: 이 회사에 원재료·부품·상품을 공급하는 회사 (원재료 매입처)
- customer: 이 회사의 주요 매출처(고객사)
- competitor: 원문이 경쟁사로 언급한 회사

규칙:
- 원문에 이름이 적힌 것만. 회사 이름·제품 이름은 원문 표기 그대로.
- "A사", "국내 대기업"처럼 이름이 없는 것은 넣지 마라.
- evidence는 원문을 그대로 복사한 인용(200자 이내). 표에서 뽑았으면 그 줄을 그대로.
- confidence는 원문이 그 관계를 얼마나 분명히 말하는지 0~1.

형식 (JSON만):
{"relations":[{"type":"product|supplier|customer|competitor","name":"...","evidence":"...","confidence":0.9}]}

<문서>
$excerpt
</문서>''';

  /// 모델 답에서 JSON을 꺼낸다. 형식이 틀린 **항목**은 버리지만, 답 전체가 JSON이
  /// 아니면(토큰 한도에 걸려 잘린 답 등) [AnswerFormatException]을 던진다 — 관계가
  /// 없는 문서와 읽지 못한 문서를 구분해야 다시 시도할 수 있다.
  static List<ExtractedRelation> parse(String answer) {
    final start = answer.indexOf('{');
    final end = answer.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw AnswerFormatException('답에서 JSON을 찾지 못했습니다');
    }
    final Object? json;
    try {
      json = jsonDecode(answer.substring(start, end + 1));
    } on FormatException catch (e) {
      throw AnswerFormatException('JSON을 해석하지 못했습니다: ${e.message}');
    }
    final list = json is Map ? json['relations'] : null;
    if (list is! List) {
      throw AnswerFormatException('relations 배열이 없습니다');
    }
    return [
      for (final r in list.whereType<Map>())
        if (r['type'] is String &&
            types.contains(r['type']) &&
            r['name'] is String &&
            (r['name'] as String).trim().isNotEmpty &&
            r['evidence'] is String)
          (
            type: r['type'] as String,
            name: (r['name'] as String).trim(),
            evidence: (r['evidence'] as String).trim(),
            confidence: (r['confidence'] as num?)?.toDouble(),
          ),
    ];
  }

  static String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '');

  /// 인용이 원문에 그대로 있고, 이름이 인용 안에 있는지 (공백은 무시).
  static bool grounded(ExtractedRelation r, String source) {
    final evidence = _squash(r.evidence);
    if (evidence.length < 4) return false;
    return _squash(source).contains(evidence) &&
        evidence.contains(_squash(r.name));
  }

  /// 검증을 통과한 후보를 관계로 바꾼다. 같은 (종류, 이름)은 하나만.
  static ({List<OntologyRelation> relations, int dropped}) toRelations(
    List<ExtractedRelation> extracted, {
    required BusinessDocument document,
    required Company company,
    required int sourceId,
    required String model,
    required Map<String, int> companiesByName,
    required Map<int, String> companyNames,
  }) {
    final seen = <String>{};
    final relations = <OntologyRelation>[];
    var dropped = 0;
    for (final r in extracted) {
      if (!grounded(r, document.text) ||
          !seen.add('${r.type}|${_squash(r.name)}')) {
        dropped++;
        continue;
      }
      final otherId = r.type == 'product'
          ? null
          : companiesByName[DisclosureValues.companyName(r.name)];
      if (otherId == company.id) {
        dropped++;
        continue;
      }
      final otherName = otherId == null
          ? r.name
          : companyNames[otherId] ?? r.name;
      final (predicate, subjectIsCompany) = switch (r.type) {
        'product' => (RelationPredicate.produces, true),
        'customer' => (RelationPredicate.suppliesTo, true),
        'supplier' => (RelationPredicate.suppliesTo, false),
        _ => (RelationPredicate.competesWith, true),
      };
      relations.add(
        OntologyRelation(
          predicate: predicate,
          subjectCompanyId: subjectIsCompany ? company.id : otherId,
          subjectName: subjectIsCompany ? company.name : otherName,
          objectCompanyId: subjectIsCompany ? otherId : company.id,
          objectName: subjectIsCompany ? otherName : company.name,
          bsnsYear: document.bsnsYear,
          weight: null,
          sourceId: sourceId,
          factKind: RelationFactKind.businessDocument,
          factId: document.id!,
          extractedBy: RelationOrigin.ai,
          status: RelationStatus.draft,
          evidence: r.evidence,
          confidence: r.confidence,
          extractorModel: model,
        ),
      );
    }
    return (relations: relations, dropped: dropped);
  }
}

/// 모델 답이 JSON이 아니거나 잘렸다.
class AnswerFormatException implements Exception {
  AnswerFormatException(this.message);

  final String message;

  @override
  String toString() => 'AnswerFormatException: $message';
}
