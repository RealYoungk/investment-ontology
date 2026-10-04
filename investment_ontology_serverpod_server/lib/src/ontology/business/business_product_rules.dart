import '../../generated/protocol.dart';
import '../peers/peer_rules.dart';
import 'current_product_rows.dart';

/// Versioned, reusable product explanations. Company attribution always needs
/// its own product-heading AND adjacent operating-description evidence.
/// No company identifiers, customer lists, forecasts or automatic AI summaries.
abstract final class BusinessProductRules {
  // Product vocabulary updates invalidate the stored explanations as well.
  static const version = 40000 + PeerRules.version;
  static final _excluded = RegExp(
    r'경쟁|타사|개발\s*중|개발\s*예정|출시\s*예정|계획|목표|종속회사|자회사|파이프라인|임상',
  );
  static final _catalog =
      <
        ({
          String key,
          String name,
          RegExp heading,
          String role,
          String process,
          String benefit,
          String url,
        })
      >[
        (
          key: 'substrate_aoi',
          name: 'AOI · 자동광학검사기',
          heading: RegExp(r'\bAOI\b|자동\s*광학\s*검사기', caseSensitive: false),
          role: '기판 회로의 결함을 광학 영상으로 찾습니다.',
          process: '기판 제조 · 회로 형성 후 검사',
          benefit: '불량 기판이 다음 공정으로 넘어가는 것을 줄입니다.',
          url: 'https://gigavis.com/kr/product/aoi/contents',
        ),
        (
          key: 'substrate_vrs',
          name: 'VRS · 결함 확인 장비',
          heading: RegExp(r'\bVRS\b|결함확인검증', caseSensitive: false),
          role: '검사 장비가 표시한 결함을 확대해 확인합니다.',
          process: '기판 제조 · 검출된 결함 확인',
          benefit: '작업자의 불량 판정과 검사 영상 기록을 돕습니다.',
          url: 'https://www.gigavis.com/kr/product/vrs/contents',
        ),
        (
          key: 'substrate_aor',
          name: 'AOR · 자동광학수리기',
          heading: RegExp(r'\bAOR\b|자동\s*광학\s*수리기', caseSensitive: false),
          role: '쇼트·돌기처럼 불필요하게 붙은 구리 결함을 수리합니다.',
          process: '기판 제조 · 수리 가능한 결함 처리',
          benefit: '수리 가능한 기판을 다시 사용해 폐기를 줄입니다.',
          url: 'https://www.gigavis.com/kr/product/aor/contents',
        ),
      ];

  static List<BusinessProduct> parse(String text) {
    final result = <BusinessProduct>[];
    final currentRows = CurrentProductRows.parse(text);
    var inProducts = false;
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('##')) {
        inProducts = RegExp(r'주요\s*제품|주요\s*상품').hasMatch(line);
        continue;
      }
      if (RegExp(r'파이프라인|pipeline', caseSensitive: false).hasMatch(line)) {
        inProducts = false;
      }
      if (!inProducts ||
          line.contains('|') ||
          line.length > 160 ||
          !RegExp(r'^\(?\d+[).]|^[가-힣][.]').hasMatch(line)) {
        continue;
      }
      final paragraphs = <String>[];
      for (var j = i + 1; j < lines.length && j <= i + 4; j++) {
        final next = lines[j];
        if (next.contains('|') ||
            next.startsWith('##') ||
            RegExp(r'^\(?\d+[).]').hasMatch(next)) {
          break;
        }
        if (next.trim().isNotEmpty) paragraphs.add(next);
      }
      final evidence = paragraphs.join('\n');
      if (evidence.isEmpty ||
          evidence.length > 1800 ||
          _excluded.hasMatch('$line\n$evidence') ||
          !text.contains(evidence) ||
          !evidence.contains('기판')) {
        continue;
      }
      for (final item in _catalog) {
        if (!item.heading.hasMatch(line) ||
            result.any((p) => p.key == item.key)) {
          continue;
        }
        final supported = switch (item.key) {
          'substrate_aoi' =>
            RegExp(r'회로\s*형성').hasMatch(evidence) && evidence.contains('검사'),
          'substrate_vrs' =>
            evidence.contains('확인') && RegExp(r'영상|이미지|확대').hasMatch(evidence),
          'substrate_aor' =>
            evidence.contains('수리') &&
                RegExp(r'쇼트|돌기|과잉\s*구리').hasMatch(evidence),
          _ => false,
        };
        if (!supported) continue;
        result.add(
          BusinessProduct(
            key: item.key,
            name: item.name,
            role: item.role,
            process: item.process,
            benefit: item.benefit,
            evidence: evidence,
            referenceUrl: item.url,
            explanationKind: 'reference_and_filing',
          ),
        );
      }
    }
    // Broader product vocabulary remains useful even without a process template.
    // Never infer an equipment role merely from its target's industry name.
    for (final signal
        in PeerRules.parse(
          text,
        ).where(
          (s) =>
              s.key.startsWith('product/') &&
              !s.key.startsWith('product/exact/') &&
              currentRows.any((p) => p.evidence == s.evidence),
        )) {
      final reference = switch (signal.key) {
        'product/mlcc' => (
          '전하를 저장했다가 공급하고 전자회로의 노이즈를 줄이는 부품입니다.',
          '전자기기의 회로 기판에 실장',
          '전자부품이 안정적으로 동작하도록 전원과 신호 잡음을 관리합니다.',
          'https://www.samsungsem.com/kr/product/passive-component/mlcc.do',
        ),
        'product/substrate' => (
          '반도체 칩과 메인보드 사이에서 전기 신호를 연결하는 기판입니다.',
          '반도체 패키징 · 칩과 메인보드 사이',
          '칩의 신호를 전달하고 외부 스트레스로부터 보호합니다.',
          'https://www.samsungsem.com/kr/product/substrate/package-substrate.do',
        ),
        _ => null,
      };
      result.add(
        BusinessProduct(
          key: signal.key,
          name: currentRows
              .firstWhere((p) => p.evidence == signal.evidence)
              .name,
          role: reference?.$1 ?? '',
          process: reference?.$2 ?? '',
          benefit: reference?.$3 ?? '',
          evidence: signal.evidence,
          referenceUrl: reference?.$4,
          explanationKind: reference == null
              ? 'source_only'
              : 'reference_and_filing',
        ),
      );
    }
    for (final product in currentRows) {
      if (!result.any(
        (p) =>
            CurrentProductRows.normalize(p.name) ==
            CurrentProductRows.normalize(product.name),
      )) {
        result.add(product);
      }
    }
    result.addAll(_supportingRevenue(text));
    return result;
  }

  /// Descriptions require a relevant section and explicit operating evidence.
  /// Revenue labels alone never establish what a service consists of.
  static List<BusinessProduct> _supportingRevenue(String text) {
    final result = <BusinessProduct>[];
    var section = '';
    var heading = '';
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) {
        section = line;
        heading = '';
        continue;
      }
      if (RegExp(r'^\(?\d+[).]|^[가-힣][.]|^\([가-힣]\)').hasMatch(line)) {
        heading = line;
        continue;
      }
      if (line.contains('|') || _excluded.hasMatch('$heading\n$line')) continue;
      final products = RegExp(r'주요\s*제품|주요\s*상품').hasMatch(section);
      final revenue = RegExp(r'매출.*수주|매출\s*실적').hasMatch(section);
      void add(String key, String name, String role) {
        if (result.any((p) => p.key == key)) return;
        result.add(
          BusinessProduct(
            key: key,
            name: name,
            role: role,
            process: '',
            benefit: '',
            evidence: line,
            explanationKind: 'filing_supported',
          ),
        );
      }

      if (products &&
          RegExp(r'\bFA\b').hasMatch(heading) &&
          line.contains('기판') &&
          line.contains('자동화') &&
          line.contains('Loader/Unloader') &&
          line.contains('In-Line')) {
        add('support/fa', 'FA · 자동화 설비', '기판의 투입·배출과 생산라인 연결을 자동화하는 설비입니다.');
      }
      if (products &&
          heading.contains('소프트웨어') &&
          [
            'AOI',
            'VRS',
            'AOR',
            '운영',
            '소프트웨어',
            'GVIS CAM',
            'DTS',
          ].every(line.contains)) {
        add(
          'support/software',
          'SOFTWARE · 장비 운영 소프트웨어',
          '검사·확인·수리 장비를 효율적으로 함께 운영하도록 돕는 프로그램입니다.',
        );
      }
      if (revenue &&
          line.contains('용역매출') &&
          RegExp(r'용역매출은[^.]*제품 판매 후[^.]*사후 서비스\(AS\)').hasMatch(line)) {
        add(
          'support/after_sales',
          '용역 · 판매 후 서비스',
          '장비를 판매한 뒤 제공하는 사후 서비스(AS) 성격의 매출입니다.',
        );
      }
      if (revenue && RegExp(r'공장부지 중 일부[^.]*임대[^.]*임대료 수익').hasMatch(line)) {
        add('support/rental', '임대료 · 공장부지 임대', '공장부지 일부를 임대해 받는 수익입니다.');
      }
    }
    return result;
  }
}
