import '../business/business_product_rules.dart';

/// Evidence-bound semiconductor discovery vocabulary. This is an Alfinder
/// product taxonomy, not an official KSIC or GICS company classification.
/// An activity is matched inside one product cell, never across a document.
abstract final class SemiconductorActivityRules {
  static const version = 2;

  static const roles = {
    'chip': '칩 설계·제조',
    'equipment': '장비',
    'material': '소재',
    'component': '부품·소모품',
    'service': '위탁생산·패키징·테스트',
    'design': '설계 IP·디자인하우스',
  };

  static final catalog = <SemiconductorProductRule>[
    SemiconductorProductRule(
      'osat',
      '반도체 후공정 서비스',
      'service',
      r'(?!)',
      '패키징·테스트',
    ),
    SemiconductorProductRule(
      'design_house',
      '반도체 설계 서비스 · 디자인하우스',
      'design',
      r'^(반도체\s*)?(디자인하우스|디자인\s*솔루션|설계\s*서비스)$',
      '설계',
    ),
    SemiconductorProductRule(
      'semiconductor_ip',
      '반도체 설계 IP',
      'design',
      r'^(시스템\s*)?반도체\s*(설계\s*자산|설계\s*IP|IP)$',
      '설계',
    ),
    SemiconductorProductRule(
      'video_ip',
      '영상 처리 IP',
      'design',
      r'^(비디오|영상)(\s*코덱|\s*처리)?\s*IP$',
      '설계',
    ),
    SemiconductorProductRule(
      'interface_ip',
      '인터페이스 IP',
      'design',
      r'^(초고속\s*)?(인터페이스|MIPI(\s*PHY)?|PCIe|UCIe|SERDES)\s*IP$',
      '설계',
    ),
    SemiconductorProductRule(
      'memory_ip',
      '메모리 시스템 IP',
      'design',
      r'^(Total\s*)?(Memory\s*System|메모리\s*시스템)\s*IP(\s*Solution)?$',
      '설계',
    ),
    SemiconductorProductRule(
      'fabless',
      '반도체 설계 · 팹리스',
      'chip',
      r'^팹리스$',
      '칩 설계',
    ),
    SemiconductorProductRule('mcu', '마이크로컨트롤러(MCU)', 'chip', r'(?!)', '칩'),
    SemiconductorProductRule(
      'ssd_controller',
      'SSD 컨트롤러',
      'chip',
      r'^(기업용\s*)?SSD\s*(컨트롤러|Controller)$',
      '칩',
    ),
    SemiconductorProductRule('isp', '영상 신호 처리 칩(ISP)', 'chip', r'(?!)', '칩'),
    SemiconductorProductRule(
      'dram',
      'DRAM 메모리',
      'chip',
      r'^(DRAM|디램)(\s*메모리)?$',
      '칩',
    ),
    SemiconductorProductRule(
      'nand',
      'NAND 메모리',
      'chip',
      r'^(NAND|낸드)(\s*(플래시|Flash))?(\s*메모리)?$',
      '칩',
    ),
    SemiconductorProductRule(
      'foundry',
      '반도체 위탁생산',
      'service',
      r'^(파운드리|foundry|반도체\s*위탁생산)$',
      '웨이퍼 제조',
    ),
    SemiconductorProductRule(
      'deposition',
      '증착 장비',
      'equipment',
      r'(반도체|웨이퍼).{0,12}(증착|CVD|ALD).{0,8}(장비|장치)',
      '증착',
    ),
    SemiconductorProductRule(
      'etch',
      '식각 장비',
      'equipment',
      r'(반도체|웨이퍼).{0,12}식각.{0,8}(장비|장치)',
      '식각',
    ),
    SemiconductorProductRule(
      'clean',
      '세정 장비',
      'equipment',
      r'(반도체|웨이퍼).{0,12}세정.{0,8}(장비|장치)',
      '세정',
    ),
    SemiconductorProductRule(
      'bond',
      '본딩 장비',
      'equipment',
      r'(반도체|패키지|다이|칩).{0,12}(본딩|접합).{0,8}(장비|장치)',
      '패키징·접합',
    ),
    SemiconductorProductRule(
      'wafer_optical',
      '웨이퍼 광학 검사 장비',
      'equipment',
      r'웨이퍼.{0,12}(광학\s*검사|AOI).{0,8}(장비|장치|기)',
      '검사·계측',
      target: '웨이퍼',
      method: '광학',
    ),
    SemiconductorProductRule(
      'substrate_optical',
      '패키지기판 광학 검사 장비',
      'equipment',
      r'(패키지\s*기판|반도체\s*기판|FC[ -]?BGA).{0,12}(광학\s*검사|AOI).{0,8}(장비|장치|기)',
      '검사·계측',
      target: '패키지기판',
      method: '광학',
    ),
    SemiconductorProductRule(
      'substrate_repair',
      '패키지기판 광학 수리 장비',
      'equipment',
      r'(패키지\s*기판|반도체\s*기판|FC[ -]?BGA).{0,12}(광학\s*수리|AOR).{0,8}(장비|장치|기)',
      '수리',
      target: '패키지기판',
      method: '광학',
    ),
    SemiconductorProductRule(
      'tester',
      '반도체 전기적 테스트 장비',
      'equipment',
      r'(반도체|메모리).{0,12}(전기적\s*테스트\s*(장비|장치)|테스터|컴포넌트\s*테스트\s*장비|모듈\s*테스트\s*장비)',
      '전기적 테스트',
      method: '전기적',
    ),
    SemiconductorProductRule(
      'socket',
      '반도체 테스트 소켓',
      'component',
      r'(반도체|메모리|IC).{0,10}테스트\s*소켓|^IC\s*TEST\s*SOCKET$',
      '전기적 테스트',
    ),
    SemiconductorProductRule(
      'probe_card',
      '프로브카드',
      'component',
      r'^(반도체용\s*|웨이퍼\s*테스트용\s*)?프로브\s*카드$',
      '전기적 테스트',
      target: '웨이퍼',
    ),
    SemiconductorProductRule(
      'photoresist',
      '반도체 포토레지스트',
      'material',
      r'반도체.{0,8}(포토레지스트|감광액)',
      '노광',
    ),
    SemiconductorProductRule(
      'slurry',
      '반도체 CMP 슬러리',
      'material',
      r'반도체.{0,8}CMP\s*(슬러리|Slurry)',
      '연마',
    ),
    SemiconductorProductRule(
      'precursor',
      '반도체 증착 전구체',
      'material',
      r'^반도체\s*(전구체|Precursor)$',
      '증착',
    ),
    SemiconductorProductRule(
      'silicon_wafer',
      '반도체용 실리콘 웨이퍼',
      'material',
      r'반도체용\s*실리콘\s*웨이퍼',
      '웨이퍼 제조',
    ),
    SemiconductorProductRule(
      'substrate',
      '반도체 패키지기판',
      'component',
      r'^(반도체\s*)?패키지\s*기판$|^FC[ -]?BGA$',
      '패키징',
      target: '패키지기판',
    ),
    SemiconductorProductRule(
      'packaging_service',
      '반도체 패키징 서비스',
      'service',
      r'반도체\s*패키징\s*(서비스|용역)',
      '패키징',
    ),
    SemiconductorProductRule(
      'test_service',
      '반도체 테스트 서비스',
      'service',
      r'반도체\s*테스트\s*(서비스|용역)',
      '전기적 테스트',
    ),
    SemiconductorProductRule(
      'eda',
      '반도체 설계 소프트웨어',
      'design',
      r'반도체\s*설계\s*(소프트웨어|자동화\s*도구)',
      '설계',
    ),
  ];

  static final _genericEquipment = SemiconductorProductRule(
    'equipment_unspecified',
    '반도체 장비 · 세부 제품 미확보',
    'equipment',
    r'^반도체\s*(제조용\s*|제조\s*|공정\s*)?(검사\s*)?장비$',
    '세부 공정 미확보',
  );

  static final _excluded = RegExp(
    r'경쟁|타사|고객사|매입|구매|도입|보유|원재료|예정|개발\s*중|연구\s*중|계획|목표|종속회사|자회사|판매\s*중단',
  );

  /// Only structurally unambiguous main-product table cells qualify. A named
  /// product's process is dictionary metadata; attribution is the exact row.
  static List<SemiconductorActivity> parse(String text, {String? companyName}) {
    final result = <SemiconductorActivity>[];
    var active = false;
    int? column;
    int? domainColumn;
    var equipmentList = false;
    var width = 0;
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.startsWith('##')) {
        if (RegExp(r'주요\s*제품|주요\s*상품').hasMatch(line)) {
          active = true;
        } else if (RegExp(r'^##\s*\d+[.\s]').hasMatch(line) ||
            RegExp(r'원재료|가격|연구개발|종속회사|자회사').hasMatch(line)) {
          active = false;
        }
        column = null;
        domainColumn = null;
        equipmentList = false;
        continue;
      }
      if (!active) continue;
      if (RegExp(r'가격\s*변동|원재료|매입처|종속회사|자회사').hasMatch(line)) {
        column = null;
        active = false;
        continue;
      }
      final cells = line.split('|').map((v) => v.trim()).toList();
      final headers = cells
          .map((v) => v.replaceAll(RegExp(r'\s'), ''))
          .toList();
      if (headers.length == 2 &&
          headers[0] == '제품' &&
          RegExp(r'^(장비의개요|제품의특징)$').hasMatch(headers[1])) {
        column = 0;
        domainColumn = null;
        equipmentList = false;
        width = 2;
        continue;
      }
      if (headers.length == 2 && headers[0] == '구분' && headers[1] == '비고') {
        column = 1;
        domainColumn = 0;
        equipmentList = true;
        width = 2;
        continue;
      }
      final productColumn = cells.indexWhere(
        (v) => RegExp(
          r'^(주요제품(및용역)?|주요제품명|제품명|품목|주요상품)$',
        ).hasMatch(v.replaceAll(RegExp(r'\s'), '')),
      );
      if (productColumn >= 0 && cells.length > 1) {
        column = productColumn;
        width = cells.length;
        final domain = headers.indexWhere((v) => v == '사업부문');
        domainColumn = domain < 0 ? null : domain;
        equipmentList = false;
        continue;
      }
      if (column == null || cells.length != width || _excluded.hasMatch(line)) {
        continue;
      }
      final cell = cells[column];
      if (cell.length > 180 || RegExp(r'합계|소계|기타').hasMatch(cell)) continue;
      // Do not merge attributes across products listed in the same cell.
      for (final product in cell.split(RegExp(r'[,;\n]'))) {
        var normalized = product
            .trim()
            .replaceFirst(RegExp(r'(\s*(등|외|外|류))+$'), '')
            .trim();
        final domain = domainColumn == null ? '' : cells[domainColumn];
        if (RegExp(r'^반도체(용\s*산업가스반도체\s*소재|\s*소재)?$').hasMatch(domain) &&
            RegExp(
              r'^(CMP\s*(Slurry|슬러리)|전구체|Precursor)$',
              caseSensitive: false,
            ).hasMatch(normalized)) {
          normalized = '반도체 $normalized';
        }
        if (RegExp(r'^반도체\s*(제조용\s*)?장비$').hasMatch(domain) &&
            RegExp(
              r'^(PECVD|LPCVD|ALD|LPCVDPlasmaALD)$',
              caseSensitive: false,
            ).hasMatch(normalized)) {
          normalized = '반도체 $normalized 장비';
        } else if (equipmentList) {
          continue;
        }
        final matches = catalog
            .where((r) => r.pattern.hasMatch(normalized))
            .toList();
        if (matches.isEmpty && _genericEquipment.pattern.hasMatch(normalized)) {
          matches.add(_genericEquipment);
        }
        if (matches.length != 1) continue;
        final rule = matches.single;
        if (result.any((a) => a.product.id == rule.id && a.evidence == raw)) {
          continue;
        }
        result.add(SemiconductorActivity(rule, raw));
      }
    }
    // Reuse the existing tightly scoped product-heading + adjacent description
    // rule. Require an explicit semiconductor-substrate attribution as well.
    for (final p in BusinessProductRules.parse(text)) {
      if (!RegExp(r'반도체\s*기판|패키지\s*기판').hasMatch(p.evidence)) continue;
      final key = switch (p.key) {
        'substrate_aoi' => 'substrate_optical',
        'substrate_aor' => 'substrate_repair',
        _ => null,
      };
      if (key == null) continue;
      final rule = catalog.firstWhere((r) => r.id == key);
      if (!result.any((a) => a.product.id == key)) {
        result.add(SemiconductorActivity(rule, p.evidence));
      }
    }
    result.addAll(_selfDescriptions(text, companyName));
    // Keep the specific IP product rather than a redundant general IP entry.
    if (result.any(
      (a) => ['video_ip', 'interface_ip', 'memory_ip'].contains(a.product.id),
    )) {
      result.removeWhere((a) => a.product.id == 'semiconductor_ip');
    }
    final seen = <String>{};
    result.removeWhere((a) => !seen.add(a.product.id));
    return result;
  }

  static List<SemiconductorActivity> _selfDescriptions(
    String text,
    String? companyName,
  ) {
    final result = <SemiconductorActivity>[];
    final name = (companyName ?? '').replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '');
    var active = false;
    for (final line in text.split('\n')) {
      if (line.startsWith('##')) {
        active = RegExp(r'사업의\s*개요|주요\s*제품|주요\s*상품').hasMatch(line);
        continue;
      }
      if (!active || line.contains('|')) continue;
      for (final sentence in line.split(RegExp(r'(?<=다[.!?])\s*'))) {
        final own =
            RegExp(r'^(그중\s*당사는|당사는|당사의\s*(주요\s*사업|주력\s*제품|제품|사업)|당사\s*기업용)')
                .hasMatch(sentence) ||
            (name.isNotEmpty &&
                    sentence
                        .replaceAll(RegExp(r'㈜|\(주\)|\s'), '')
                        .startsWith('$name는') ||
                (name.isNotEmpty &&
                    sentence
                        .replaceAll(RegExp(r'㈜|\(주\)|\s'), '')
                        .startsWith('$name은')));
        if (!own ||
            sentence.length > 650 ||
            RegExp(
              r'종속회사|자회사|인수|계획|예정|추진|목표|중단|철수|철회|준비|검토|(제공|판매|개발|영위)하지\s*않|아닌|아니며|구매|도입|사용권|라이선스.{0,5}받',
            ).hasMatch(sentence)) {
          continue;
        }
        final ids = <String>{};
        if (RegExp(r'반도체').hasMatch(sentence) &&
            (RegExp(r'디자인하우스.{0,30}(입니다|기업|선두주자)').hasMatch(sentence) ||
                RegExp(r'디자인\s*솔루션.{0,15}제공').hasMatch(sentence) ||
                RegExp(r'설계\s*(솔루션|엔지니어링\s*서비스|서비스).{0,100}제공')
                    .hasMatch(sentence))) {
          ids.add('design_house');
        }
        if (RegExp(r'반도체').hasMatch(sentence) &&
            RegExp(r'(설계\s*자산|설계\s*IP|IP\s*라이선싱).{0,60}(개발|판매|사업|제공)')
                .hasMatch(sentence)) {
          ids.add('semiconductor_ip');
        }
        if (RegExp(r'(비디오|영상)\s*(코덱\s*)?IP.{0,15}(라이선스|공급|판매)')
            .hasMatch(sentence)) {
          ids.add('video_ip');
        }
        if (RegExp(r'주요\s*사업.{0,35}비디오\s*IP').hasMatch(sentence)) {
          ids.add('video_ip');
        }
        if (RegExp(r'(Total Memory System|메모리\s*시스템)\s*IP')
                .hasMatch(sentence) &&
            RegExp(r'제공(하는|하고|합니다)').hasMatch(sentence)) {
          ids.add('memory_ip');
        }
        if (RegExp(r'반도체').hasMatch(sentence) &&
            RegExp(r'팹리스.{0,20}(기업입니다|업체입니다|업체로(?!부터)|회사입니다)')
                .hasMatch(sentence) &&
            !RegExp(r'주요\s*고객|매출처|대상으로').hasMatch(sentence)) {
          ids.add('fabless');
        }
        if (RegExp(r'인터페이스\s*IP\s*라이선싱').hasMatch(sentence) &&
            RegExp(r'사업.{0,15}영위').hasMatch(sentence)) {
          ids.add('interface_ip');
        }
        if (RegExp(r'주력\s*제품.{0,80}SSD\s*컨트롤러').hasMatch(sentence)) {
          ids.add('ssd_controller');
        }
        if (RegExp(r'MCU.{0,20}설계').hasMatch(sentence) &&
            ids.contains('fabless')) {
          ids.add('mcu');
        }
        if (RegExp(r'순수\s*파운드리\s*기업').hasMatch(sentence)) {
          ids.add('foundry');
        }
        if (RegExp(r'반도체').hasMatch(sentence) &&
            RegExp(r'후공정.{0,30}(전문\s*기업|산업을\s*영위|사업을\s*영위)')
                .hasMatch(sentence)) {
          ids.add('osat');
        }
        if (RegExp(r'반도체').hasMatch(sentence) &&
            RegExp(
              r'(테스트\s*솔루션을\s*제공|테스트\s*사업.{0,10}영위|Test.{0,25}용역을\s*주\s*사업)',
              caseSensitive: false,
            ).hasMatch(sentence)) {
          ids.add('test_service');
        }
        if (RegExp(r'반도체\s*패키징\s*솔루션을\s*제공').hasMatch(sentence)) {
          ids.add('packaging_service');
        }
        for (final id in ids) {
          if (!result.any((a) => a.product.id == id)) {
            result.add(
              SemiconductorActivity(
                catalog.firstWhere((r) => r.id == id),
                sentence,
              ),
            );
          }
        }
      }
    }
    return result;
  }
}

class SemiconductorProductRule {
  SemiconductorProductRule(
    this.id,
    this.label,
    this.role,
    String pattern,
    this.process, {
    this.target,
    this.method,
  }) : pattern = RegExp(pattern, caseSensitive: false);
  final String id;
  final String label;
  final String role;
  final RegExp pattern;
  final String process;
  final String? target;
  final String? method;
}

class SemiconductorActivity {
  const SemiconductorActivity(this.product, this.evidence);
  final SemiconductorProductRule product;
  final String evidence;
}
