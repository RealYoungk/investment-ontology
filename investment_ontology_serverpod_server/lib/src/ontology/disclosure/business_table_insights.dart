import '../../generated/protocol.dart';

/// Additional explicit filing tables. Read only stored source: no API or AI call.
/// A chartable observation requires a named metric and an explicit unit.
abstract final class BusinessTableInsights {
  static String _key(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static final _year = RegExp(r'20\d{2}|제\d+기');
  static final _unit = RegExp(r'단위\s*[:：]\s*([^\)\]）]+)');
  static final _numeric = RegExp(r'^[+-]?\d[\d,]*(?:\.\d+)?%?$');
  static final _total = RegExp(r'^(합계|총계|계|.*소계)(?:\([^)]*\))?$');

  static bool _validUnit(String value) =>
      RegExp(
        r'원|달러|USD|EUR|KRW|JPY|CNY|CHF|THB|SGD|GBP|AUD|유로|엔|위안|%|톤|kg|Kg|개|대|리터',
      ).hasMatch(value) &&
      !RegExp(r'또는|및').hasMatch(value) &&
      RegExp(r'원|달러|USD|EUR|KRW|JPY|CNY|CHF|THB|SGD|GBP|AUD|유로|엔|위안')
              .allMatches(value)
              .length <=
          1;

  static double? number(String text) {
    var s = text.trim().replaceAll('△', '-').replaceAll('−', '-');
    if (RegExp(r'^\([\d,.]+\)$').hasMatch(s)) {
      s = '-${s.substring(1, s.length - 1)}';
    }
    if (!_numeric.hasMatch(s)) return null;
    final value = double.tryParse(s.replaceAll(',', '').replaceAll('%', ''));
    return value != null && value.isFinite ? value : null;
  }

  // Accept only a literal number with an explicit currency/quantity suffix.
  // Never interpret amounts embedded in contract or research prose.
  static (double, String?)? _observation(String text, String? commonUnit) {
    final plain = number(text);
    if (plain != null) return (plain, null);
    final amountShare = RegExp(
      r'^([+-]?\d[\d,]*(?:\.\d+)?)\s*\((\d+(?:\.\d+)?)%\)$',
    ).firstMatch(text.trim());
    if (amountShare != null) {
      return (number(amountShare.group(1)!)!, null);
    }
    final suffixed = RegExp(r'^([+-]?\d[\d,]*(?:\.\d+)?)\s*(백만원|천원|억원|원)$')
        .firstMatch(text.trim());
    if (suffixed != null) {
      return (number(suffixed.group(1)!)!, suffixed.group(2)!);
    }
    final match = RegExp(
      r'^(USD|EUR|JPY|CNY|CHF|THB|SGD|KRW|GBP|AUD|HKD|US\$|\$|\\|₩)?\s*([+-]?\d[\d,]*(?:\.\d+)?)\s*(백만|천)?(?:/(톤|kg|ton|kWh|m|㎥))?$',
    ).firstMatch(text.trim());
    if (match == null || (match.group(1) == null && match.group(4) == null)) {
      return null;
    }
    final value = number(match.group(2)!);
    if (value == null) return null;
    final currency = switch (match.group(1)) {
      r'$' || r'US$' => 'USD',
      r'\' || '₩' => '원',
      final v => v,
    };
    final base = currency ?? commonUnit;
    if (base == null || !_validUnit(base)) return null;
    return (
      value,
      '${match.group(3) ?? ''}$base${match.group(4) == null ? '' : '/${match.group(4)}'}',
    );
  }

  static String? _topic(List<String> header, String context) {
    if (header.any((value) => number(value) != null)) return null;
    final h = header.map(_key).join('|');
    final c = _key(context);
    if (header
        .skip(1)
        .every((v) => v.isEmpty || v == '-' || number(v) != null)) {
      return null;
    }
    if (header.any((v) => _year.hasMatch(v)) &&
        RegExp(r'조달항목|운용항목').hasMatch(h)) {
      return 'bankFunding';
    }
    if (header.where((v) => _year.hasMatch(v)).length >= 2 &&
        RegExp(r'BIS|자본적정성|자산건전성|유동성비율|대손충당금비율|주요경영지표').hasMatch(c) &&
        RegExp(r'^구분\||^비율\||^지표\|').hasMatch(h)) {
      return 'financialSoundness';
    }

    if (header.length == 2 &&
        {
          '거래상대방',
          '계약일',
          '만기일',
          '계약금액',
          '기초자산',
          '정산방법',
        }.contains(_key(header.first))) {
      return null;
    }
    if (header
            .skip(1)
            .any(
              (v) => RegExp(
                r'^(자산|부채|이익|손실|관련손익|미결제약정계약금액|미결제약정금액|평가이익|평가손실|평가이익\(손실\)|거래이익\(손실\)|계약금액.*|공정가치|파생상품자산.*|파생상품부채.*|만기일|통화|당기말|당반기말)$',
              ).hasMatch(_key(v)),
            ) &&
        RegExp(r'파생상품|파생거래|통화선도|통화스왑|파생금융').hasMatch('$c$h') &&
        RegExp(r'명목금액|계약금액|공정가치|만기|평가|손익|자산|부채|매입통화').hasMatch(h)) {
      return 'derivatives';
    }
    if (RegExp(r'기투자액|당기투자액|투자집행액').hasMatch(h) && !h.contains('향후투자액')) {
      return 'investmentExecution';
    }
    if (h.contains('향후투자액') ||
        (h.contains('투자대상') && h.contains('총소요자금') && h.contains('기지출액'))) {
      return 'investmentPlan';
    }
    if (h.contains('판매경로') &&
        (RegExp(r'매출액|비중').hasMatch(h) ||
            (header.any((v) => _year.hasMatch(v)) && c.contains('판매경로별매출')))) {
      return 'salesChannel';
    }
    if (RegExp(r'매입액|구매금액|투입액|매입비중').hasMatch(h) &&
        RegExp(r'원재료|매입|품목').hasMatch('$c$h')) {
      return 'materialPurchase';
    }
    if (RegExp(r'원재료.*매입현황|원재료.*매입액').hasMatch(c) &&
        !c.contains('가격') &&
        header.any((v) => _year.hasMatch(v)) &&
        RegExp(r'품목|구분|원재료|주요자재|매입유형').hasMatch(h)) {
      return 'materialPurchase';
    }
    if (RegExp(r'제품.*가격.*변동').hasMatch(c) &&
        header.any((v) => _year.hasMatch(v)) &&
        RegExp(r'품목|구분').hasMatch(h)) {
      return 'productPrice';
    }
    if (RegExp(r'(원재료|원자재|자재).*가격|가격.*(원재료|원자재)').hasMatch(c) &&
        !RegExp(r'생산능력|생산실적|가동률|매출현황').hasMatch(c) &&
        header.any((v) => _year.hasMatch(v)) &&
        RegExp(r'품목|구분|원재료|주요자재|매입유형').hasMatch(h)) {
      return 'materialPrice';
    }
    if (RegExp(r'투자계획|투자예정').hasMatch(c) &&
        (RegExp(r'투자액|투자금액|예정액|계획액').hasMatch(h) ||
            (header.any((v) => _year.hasMatch(v)) &&
                RegExp(r'사업명|투자대상|설비명|구분').hasMatch(h)))) {
      return 'investmentPlan';
    }
    if (RegExp(r'계약명|계약내용|계약상대|계약상대방|계약처').hasMatch(h) &&
        RegExp(r'계약기간|계약일|체결일|계약금액|계약총액|계약종료일|계약일자').hasMatch(h)) {
      return 'majorContracts';
    }
    if (RegExp(r'연구과제명|연구개발과제|개발과제|과제명|연구과제').hasMatch(h) &&
        RegExp(r'연구내용|연구기간|관련제품|개발기간|개발시기|진행|개발단계|기대효과|사업화|상품화').hasMatch(h)) {
      return 'researchProjects';
    }
    if (RegExp(r'연구개발|파이프라인').hasMatch(c) &&
        RegExp(r'품목|후보물질|프로젝트|제품명').hasMatch(h) &&
        RegExp(r'적응증|임상단계|개발단계|진행단계').hasMatch(h)) {
      return 'researchProjects';
    }
    if (header
            .skip(1)
            .any(
              (v) => RegExp(
                r'^(명목금액|계약금액.*|공정가치|만기일|만기|거래상대방|자산|부채|평가손익|평가이익\(손실\)|거래이익\(손실\))$',
              ).hasMatch(_key(v)),
            ) &&
        RegExp(r'파생상품|파생거래').hasMatch(c) &&
        RegExp(r'명목금액|계약금액|공정가치|만기일|만기|거래상대방|자산|부채|평가손익').hasMatch(h)) {
      return 'derivatives';
    }
    if (RegExp(r'환위험|외환위험|이자율위험|시장위험|민감도').hasMatch(c) &&
        RegExp(r'손익|자본|이익|상승|하락').hasMatch(h)) {
      return 'riskSensitivity';
    }
    return null;
  }

  static String title(String topic) => switch (topic) {
    'materialPurchase' => '원재료 매입 구성',
    'bankFunding' => '은행 자금 조달·운용',
    'financialSoundness' => '금융 건전성 지표',
    'materialPrice' => '원재료 가격 변화',
    'productPrice' => '제품 판매가격 변화',
    'investmentExecution' => '투자 집행 현황',
    'salesChannel' => '판매경로별 매출',
    'investmentPlan' => '투자계획',
    'researchProjects' => '연구개발 과제',
    'majorContracts' => '주요 계약',
    'derivatives' => '파생상품·위험관리',
    'riskSensitivity' => '금융위험 민감도',
    _ => topic,
  };

  // Exact, bounded filing shapes that cannot use the flat-header reader.
  static List<BusinessTableInsight> _special(String text, String period) {
    final lines = text.split('\n');
    final out = <BusinessTableInsight>[];
    for (var i = 0; i < lines.length; i++) {
      final h = lines[i].split('|').map((v) => v.trim()).toList();
      final keys = h.map(_key).toList();
      final rows = <BusinessTableRecord>[];
      final measures = <BusinessTableMeasure>[];
      String? topic;
      var j = i + 1;
      List<String> columns = h;
      if (keys.join('|') == '계약상대방|항목|내용') {
        topic = 'majorContracts';
        columns = ['계약 상대방', '계약 유형', '체결 시기', '계약 금액', '목적 및 내용'];
        String? counterparty;
        var fields = <String, String>{};
        void flush() {
          if (counterparty == null || fields.isEmpty) return;
          rows.add(
            BusinessTableRecord(
              label: counterparty,
              cells: [
                counterparty,
                for (final k in columns.skip(1)) fields[_key(k)] ?? '',
              ],
            ),
          );
          final amount = _observation(fields['계약금액'] ?? '', null);
          if (amount != null && amount.$2 != null) {
            measures.add(
              BusinessTableMeasure(
                label: counterparty,
                metric: '계약 금액',
                period: fields['체결시기'] ?? period,
                value: amount.$1,
                unit: amount.$2!,
              ),
            );
          }
        }

        for (; j < lines.length && lines[j].contains('|'); j++) {
          final c = lines[j].split('|').map((v) => v.trim()).toList();
          if (c.length == 3 && _key(c[1]) == '계약유형') {
            flush();
            counterparty = c[0];
            fields = {'계약유형': c[2]};
          } else if (c.length == 2 &&
              {'체결시기', '계약금액', '목적및내용'}.contains(_key(c[0])) &&
              counterparty != null) {
            fields[_key(c[0])] = c[1];
          } else {
            break;
          }
        }
        flush();
      } else if (keys.join('|') == '지수|세전이익에대한영향' &&
          j < lines.length &&
          _key(lines[j]) == '당반기|전기') {
        topic = 'riskSensitivity';
        columns = ['지수', '변동 조건', '당반기', '전기'];
        j++;
        String? index;
        for (; j < lines.length && lines[j].contains('|'); j++) {
          final c = lines[j].split('|').map((v) => v.trim()).toList();
          if (c.length == 4) index = c.removeAt(0);
          if (c.length != 3 ||
              index == null ||
              !RegExp(r'^\d+(?:\.\d+)?% (상승|하락)시$').hasMatch(c[0])) {
            break;
          }
          final unit = _unit
              .allMatches(lines.sublist(i > 5 ? i - 5 : 0, i).join('\n'))
              .lastOrNull
              ?.group(1)
              ?.trim();
          rows.add(
            BusinessTableRecord(
              label: '$index · ${c[0]}',
              cells: [index, ...c],
            ),
          );
          for (var k = 1; k < 3; k++) {
            final v = number(c[k]);
            if (v != null && unit != null && _validUnit(unit)) {
              measures.add(
                BusinessTableMeasure(
                  label: '$index · ${c[0]}',
                  metric: '세전 이익 영향',
                  period: '${columns[k + 1]} ($period 보고서)',
                  value: v,
                  unit: unit,
                ),
              );
            }
          }
        }
      } else if (keys.length == 4 &&
          keys[0] == '부문' &&
          keys[1] == '품목' &&
          RegExp(r'^제\d+기$').hasMatch(keys[2]) &&
          keys[3] == '주요매입처' &&
          j + 1 < lines.length &&
          lines[j + 1].contains('당기 매입액')) {
        final c = lines[j].split('|').map((v) => v.trim()).toList();
        final unit = _unit
            .allMatches(lines.sublist(i > 3 ? i - 3 : 0, i).join('\n'))
            .lastOrNull
            ?.group(1)
            ?.trim();
        if (c.length == 4 &&
            number(c[2]) != null &&
            unit != null &&
            _validUnit(unit)) {
          topic = 'materialPurchase';
          columns = [h[0], h[1], '${h[2]} 매입액', h[3]];
          rows.add(BusinessTableRecord(label: c[1], cells: c));
          measures.add(
            BusinessTableMeasure(
              label: c[1],
              metric: '매입액',
              period: h[2],
              value: number(c[2])!,
              unit: unit,
            ),
          );
          j++;
        }
      }
      if (topic != null && rows.isNotEmpty) {
        out.add(
          BusinessTableInsight(
            topic: topic,
            title: title(topic),
            columns: columns,
            rows: rows,
            measures: measures,
            evidence: lines.sublist(i > 3 ? i - 3 : 0, j).join('\n'),
            validation: '명시된 열·원문 값 구조화 · 합계/비율 검산 미수행',
          ),
        );
      }
    }
    return out;
  }

  static List<BusinessTableInsight> parse(
    String text, {
    required String reportPeriod,
  }) {
    final lines = text.split('\n');
    final out = _special(text, reportPeriod);
    final seen = <String>{};
    String? scope;
    var subsection = '';
    String? entity;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('## ') ||
          RegExp(r'^\[[^\]]+\]$').hasMatch(lines[i].trim())) {
        scope = lines[i].replaceFirst('## ', '').trim();
        subsection = '';
        entity = null;
      }
      final heading = lines[i].trim();
      if (RegExp(r'^[가-힣]\. |^\d+[.)] |^\(\d+\)|^[○①②③④⑤⑥⑦]')
              .hasMatch(heading) &&
          !heading.contains('|')) {
        subsection = heading;
      }
      if (heading.contains('■') && heading.split('■').last.isNotEmpty) {
        entity = heading
            .split('■')
            .last
            .split(RegExp(r'[가나다라]\. '))
            .first
            .trim();
      }
      if (heading == '■' && i + 1 < lines.length) entity = lines[i + 1].trim();
      if (!lines[i].contains('|')) continue;
      var header = lines[i].split('|').map((s) => s.trim()).toList();
      if (header.length < 2 ||
          header.length > 24 ||
          header.any((h) => h.length > 80) ||
          header.first == '-') {
        continue;
      }
      // Never classify a value row as a new header.
      if (header.any((s) => number(s) != null)) continue;
      final before = lines.sublist(i > 5 ? i - 5 : 0, i).join('\n');
      final contextLines = before.split('## ').last.split('\n');
      final priorTable = contextLines.lastIndexWhere(
        (l) => l.contains('|') && !_unit.hasMatch(l),
      );
      final context = contextLines.skip(priorTable + 1).join('\n');
      // Licensing/contract tables often use field/value rows instead of column headers.
      if (header.length == 2 &&
          {'계약상대방', '계약명', '품목', '계약구분'}.contains(_key(header.first))) {
        final fields = <String>[];
        final values = <String>[];
        var end = i;
        const contractFields = {
          '계약상대방',
          '계약명',
          '품목',
          '계약구분',
          '계약내용',
          '계약일',
          '계약일자',
          '계약체결일',
          '계약기간',
          '계약종료일',
          '계약금액',
          '총계약금액',
          '진행상황',
          '진행경과',
          '개발단계',
          '적응증',
          '수수방법',
          '기타사항',
        };
        for (; end < lines.length; end++) {
          final pair = lines[end].split('|').map((s) => s.trim()).toList();
          if (pair.length != 2 ||
              !contractFields.contains(_key(pair.first)) ||
              fields.contains(pair.first)) {
            break;
          }
          fields.add(pair.first);
          values.add(pair.last);
        }
        if (fields.length >= 3 &&
            fields.any((f) => _key(f) == '계약상대방') &&
            fields.any((f) => RegExp(r'계약기간|계약.*일').hasMatch(_key(f)))) {
          final label = values[fields.indexWhere((f) => _key(f) == '계약상대방')];
          final unit = _unit.allMatches(context).lastOrNull?.group(1)?.trim();
          out.add(
            BusinessTableInsight(
              topic: 'majorContracts',
              title: title('majorContracts'),
              columns: fields,
              rows: [BusinessTableRecord(label: label, cells: values)],
              measures: [
                for (var k = 0; k < fields.length; k++)
                  if (_key(fields[k]).contains('계약금액') &&
                      number(values[k]) != null &&
                      unit != null &&
                      _validUnit(unit) &&
                      !unit.contains(','))
                    BusinessTableMeasure(
                      label: label,
                      metric: fields[k],
                      period: reportPeriod,
                      value: number(values[k])!,
                      unit: unit,
                    ),
              ],
              evidence: lines.sublist(i > 5 ? i - 5 : 0, end).join('\n'),
              validation: '명시된 항목·원문 값 구조화 · 합계/비율 검산 미수행',
              scope: [
                ?scope,
                ?entity,
              ].join(' · '),
            ),
          );
          i = end - 1;
          continue;
        }
      }
      final topic = _topic(
        header,
        '${header.any((h) => RegExp(r'계약금액|계약잔액|만기일').hasMatch(h)) ? scope ?? '' : ''}\n$subsection\n${context.split('\n').where((l) => l.length < 160).join('\n')}',
      );
      if (topic == null) continue;
      if (header.first.isEmpty) header[0] = '구분';
      var dataStart = i + 1;
      if (dataStart < lines.length &&
          _key(header.last) == '장부금액' &&
          _key(lines[dataStart]) == '자산|부채') {
        header = [...header.take(header.length - 1), '장부금액 · 자산', '장부금액 · 부채'];
        dataStart++;
      }
      // Some filers omit a leading group header while retaining that column in rows.
      // Preserve it explicitly; align named amount columns only from the right.
      final widths = <int>[];
      for (var r = dataStart; r < lines.length; r++) {
        if (!lines[r].contains('|') ||
            (_unit.hasMatch(lines[r]) && lines[r].split('|').length <= 2) ||
            lines[r].startsWith('## ')) {
          break;
        }
        widths.add(lines[r].split('|').length);
      }
      final yearColumn = header.indexWhere((h) => _year.hasMatch(h));
      final firstRow = dataStart < lines.length
          ? lines[dataStart].split('|').map((s) => s.trim()).toList()
          : <String>[];
      if (yearColumn >= 0 &&
          widths.isNotEmpty &&
          widths.every((w) => w <= header.length + 1) &&
          firstRow.length > yearColumn &&
          RegExp(r'^(원|천원|USD|\$)/').hasMatch(firstRow[yearColumn])) {
        header = [...header.take(yearColumn), '단위', ...header.skip(yearColumn)];
      }
      if (widths.contains(header.length + 1) &&
          {'부문', '사업부문'}.contains(_key(header.first)) &&
          widths.every((w) => w <= header.length + 1) &&
          {
            'materialPurchase',
            'materialPrice',
            'productPrice',
          }.contains(topic)) {
        header = ['원문 선행 구분', ...header];
      }
      final firstPeriod = header.indexWhere((h) => _year.hasMatch(h));
      if (firstPeriod >= 0 && dataStart < lines.length) {
        final subheader = lines[dataStart]
            .split('|')
            .map((s) => s.trim())
            .toList();
        final years = header.skip(firstPeriod).toList();
        if (years.every((h) => _year.hasMatch(h)) &&
            subheader.every(
              (h) =>
                  RegExp(r'^(금액|점유율|평균잔액|이자율|비중|비율|매입액|매출액|투자액|계획액|%)$')
                      .hasMatch(_key(h)),
            ) &&
            subheader.length % years.length == 0 &&
            subheader.length ~/ years.length <= 3) {
          final perYear = subheader.length ~/ years.length;
          header = [
            ...header.take(firstPeriod),
            for (var y = 0; y < years.length; y++)
              for (var k = 0; k < perYear; k++)
                '${years[y]} · ${subheader[y * perYear + k]}',
          ];
          dataStart++;
        }
      }
      final rawUnit = _unit.allMatches(context).lastOrNull?.group(1)?.trim();
      final units =
          rawUnit
              ?.split(RegExp(r'[,，]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && s != '%')
              .toList() ??
          [];
      // Multiple currencies / row-specific units are not silently merged.
      final commonUnit = rawUnit == '%'
          ? '%'
          : units.length == 1 &&
                !RegExp(r'및|또는|/USD|/달러').hasMatch(units.single)
          ? units.single
          : null;
      final records = <BusinessTableRecord>[];
      final measures = <BusinessTableMeasure>[];
      var inherited = List<String>.filled(header.length, '');
      var j = dataStart;
      for (; j < lines.length; j++) {
        final line = lines[j].trim();
        if (line.isEmpty) continue;
        if (!line.contains('|') ||
            line.startsWith('## ') ||
            (_unit.hasMatch(line) && line.split('|').length <= 2)) {
          break;
        }
        var cells = line.split('|').map((s) => s.trim()).toList();
        if (cells.length == header.length + 1 && cells.first.isEmpty) {
          cells = cells.sublist(1);
        }
        if (cells.length > header.length || cells.isEmpty) break;
        if (RegExp(r'^(주\s*\d*[)）]|\(주\d*\)|주\))').hasMatch(cells.first)) break;
        if (cells.every(
          (c) => RegExp(r'^(당반기|당기|전기|전반기|단가|외화단가\(USD\))$').hasMatch(_key(c)),
        )) {
          break;
        }
        if (cells.join('|') == header.join('|') || _topic(cells, '') != null) {
          break;
        }
        if (cells
                    .where(
                      (c) =>
                          RegExp(r'^(20\d{2}년?|제\d+기)[^|.]{0,20}$').hasMatch(c),
                    )
                    .length >=
                2 &&
            cells
                .skip(1)
                .every(
                  (c) =>
                      c.isEmpty ||
                      RegExp(r'^(20\d{2}년?|제\d+기)[^|.]{0,20}$').hasMatch(c),
                )) {
          break;
        }
        // Numeric subtables with unresolved multi-row headers are not guessed.
        if (cells.every(
          (s) => RegExp(r'^(금액|비중|비율|매출액|자산|부채|%)$').hasMatch(_key(s)),
        )) {
          break;
        }
        final padded = [
          ...List<String>.filled(header.length - cells.length, ''),
          ...cells,
        ];
        // This filing shape omits both the business segment and usage cells.
        // Restore only those named columns; retain the printed item and type.
        if (topic == 'materialPurchase' &&
            header.length >= 5 &&
            _key(header[0]) == '사업부문' &&
            _key(header[1]) == '매입유형' &&
            _key(header[2]) == '품목' &&
            _key(header[3]) == '구체적용도' &&
            cells.length == header.length - 2 &&
            inherited[0].isNotEmpty &&
            cells.skip(2).every((v) => _observation(v, commonUnit) != null)) {
          padded.setAll(0, [
            inherited[0],
            cells[0],
            cells[1],
            inherited[3],
            ...cells.skip(2),
          ]);
        }
        // A total is not part of the preceding segment's merged cell.
        if (cells.isNotEmpty &&
            RegExp(r'^(합계|총계|계)$').hasMatch(_key(cells.first))) {
          for (var k = 0; k < padded.length - cells.length; k++) {
            padded[k] = '-';
          }
        }
        final numericColumns = <int>[];
        for (var k = 0; k < header.length; k++) {
          final h = _key(header[k]);
          if (RegExp(
                r'매입액|구매금액|투입액|매입금액|매출액|투자액|투자금액|총소요자금|기지출액|정부출연금|예정액|계획액|명목금액|계약금액|계약총액|수취금액|과제비|계약잔액|공정가치|가격|단가|비중|비율|·금액',
              ).hasMatch(h) ||
              (topic == 'derivatives' &&
                  RegExp(
                    r'^(자산|부채|이익|손실|관련손익|미결제약정금액|평가이익\(손실\)|거래이익\(손실\)|파생상품자산\(부채\)|파생상품자산|파생상품부채|파생상품평가손익|장부금액·자산|장부금액·부채)$',
                  ).hasMatch(h)) ||
              (({
                    'bankFunding',
                    'financialSoundness',
                    'materialPrice',
                    'productPrice',
                    'investmentPlan',
                    'materialPurchase',
                    'salesChannel',
                  }.contains(topic)) &&
                  _year.hasMatch(h)) ||
              (topic == 'riskSensitivity' &&
                  RegExp(r'손익|자본|이익|상승|하락').hasMatch(h))) {
            numericColumns.add(k);
          }
        }
        final labels = <String>[];
        if (cells.length < header.length &&
            !(topic == 'majorContracts' &&
                _key(header.first) == '품목' &&
                cells.length == header.length - 1) &&
            numericColumns.any(
              (k) =>
                  padded[k].isNotEmpty &&
                  padded[k] != '-' &&
                  _observation(padded[k], commonUnit) == null,
            )) {
          // Only leading merged metadata may be carried; never shift a text label into a metric.
          continue;
        }
        for (var k = 0; k < header.length; k++) {
          if (numericColumns.contains(k) ||
              RegExp(r'비고|매입처|연구내용|기대효과|계약내용').hasMatch(_key(header[k]))) {
            continue;
          }
          if (padded[k].isEmpty) padded[k] = inherited[k];
          if (padded[k].isNotEmpty && padded[k] != '-') labels.add(padded[k]);
        }
        final preferred = header.indexWhere(
          (h) => switch (topic) {
            'materialPurchase' ||
            'materialPrice' ||
            'productPrice' => {'품목', '원재료', '주요자재'}.contains(_key(h)),
            'salesChannel' => _key(h) == '판매경로',
            'majorContracts' => {'계약상대방', '계약상대', '계약처'}.contains(_key(h)),
            _ => false,
          },
        );
        final label = <String>{
          if (preferred >= 0 &&
              padded[preferred].isNotEmpty &&
              padded[preferred] != '-')
            padded[preferred],
          ...labels,
        }.join(' · ');
        if (label.isEmpty) break;
        if (topic == 'materialPrice' &&
            RegExp(r'생산능력|생산실적|가동률').hasMatch(label)) {
          break;
        }
        final numeric = numericColumns.any(
          (k) => _observation(padded[k], commonUnit) != null,
        );
        final textual = {
          'researchProjects',
          'majorContracts',
          'derivatives',
        }.contains(topic);
        if (!numeric && !textual && numericColumns.isEmpty) {
          continue;
        }
        records.add(BusinessTableRecord(label: label, cells: padded));
        inherited = padded;
        if (!padded.any((c) => _total.hasMatch(_key(c)))) {
          for (final k in numericColumns) {
            final observation = _observation(padded[k], commonUnit);
            if (observation == null) continue;
            final value = observation.$1;
            final h = header[k];
            final percent =
                RegExp(r'비중|비율|점유율|이자율').hasMatch(_key(h)) ||
                padded[k].endsWith('%') ||
                commonUnit == '%' ||
                (topic == 'financialSoundness' &&
                    RegExp(r'비율|적립률|연체율|NIM|ROA|ROE|NCR').hasMatch(label));
            final parenthetical = RegExp(r'[(（]([^()（）]+)[)）]')
                .firstMatch(h)
                ?.group(1);
            final unitColumn = header.indexWhere(
              (c) => {'단위', '통화', '통화단위'}.contains(_key(c)),
            );
            final rowUnit = unitColumn < 0
                ? null
                : padded[unitColumn].replaceFirst(r'$', 'USD');
            final noteUnit = _unit
                .firstMatch(padded.join('|'))
                ?.group(1)
                ?.split(',')
                .first
                .trim();
            final explicitUnit =
                parenthetical != null && _validUnit(parenthetical)
                ? parenthetical
                : null;
            final scale = RegExp(r'^(백만|천|외화-천)$').hasMatch(rawUnit ?? '')
                ? rawUnit!.replaceFirst('외화-', '')
                : null;
            final rowCurrencyUnit = rowUnit == null
                ? null
                : units
                      .where(
                        (u) => _validUnit(u) && u.contains(rowUnit),
                      )
                      .firstOrNull;
            final parentheticalScale = parenthetical == null
                ? null
                : RegExp(r'단위[:：]\s*(백만|천)$')
                      .firstMatch(parenthetical)
                      ?.group(1);
            final literalUnit = observation.$2;
            final unit = percent
                ? '%'
                : literalUnit != null
                ? '${parentheticalScale ?? ''}$literalUnit'
                : explicitUnit ??
                      rowCurrencyUnit ??
                      (rowUnit != null && _validUnit(rowUnit) && scale != null
                          ? '$scale$rowUnit'
                          : commonUnit ??
                                (noteUnit != null && _validUnit(noteUnit)
                                    ? noteUnit
                                    : null) ??
                                (rowUnit != null &&
                                        _validUnit(rowUnit) &&
                                        rawUnit == null
                                    ? rowUnit
                                    : null));
            if (unit == null ||
                !_validUnit(unit) ||
                unit.isEmpty ||
                (percent &&
                    topic != 'financialSoundness' &&
                    (value < 0 || value > 100))) {
              continue;
            }
            measures.add(
              BusinessTableMeasure(
                label: label,
                metric:
                    {'materialPrice', 'productPrice'}.contains(topic) &&
                        _year.hasMatch(h)
                    ? '가격'
                    : topic == 'investmentPlan' && _year.hasMatch(h)
                    ? '계획액'
                    : topic == 'materialPurchase' &&
                          _year.hasMatch(h) &&
                          !RegExp(r'비중|비율').hasMatch(h)
                    ? '매입액'
                    : topic == 'salesChannel' &&
                          _year.hasMatch(h) &&
                          !RegExp(r'비중|비율').hasMatch(h)
                    ? '매출액'
                    : h,
                period:
                    !_year.hasMatch(h) &&
                        RegExp(r'비중|비율').hasMatch(h) &&
                        header.take(k).any((column) => _year.hasMatch(column))
                    ? header
                          .take(k)
                          .lastWhere((column) => _year.hasMatch(column))
                    : _year.hasMatch(h)
                    ? h
                    : context
                              .split('\n')
                              .where(
                                (l) =>
                                    RegExp(r'^(당기말|당반기말|전기말|전반기말)$')
                                        .hasMatch(l.trim()),
                              )
                              .lastOrNull ==
                          null
                    ? reportPeriod
                    : '${context.split('\n').where((l) => RegExp(r'^(당기말|당반기말|전기말|전반기말)$').hasMatch(l.trim())).last.trim()} ($reportPeriod 보고서)',
                value: value,
                unit: unit,
              ),
            );
            final printedShare = RegExp(
              r'^[+-]?\d[\d,]*(?:\.\d+)?\s*\((\d+(?:\.\d+)?)%\)$',
            ).firstMatch(padded[k].trim());
            if (printedShare != null &&
                {'materialPurchase', 'salesChannel'}.contains(topic) &&
                _year.hasMatch(h)) {
              final share = double.parse(printedShare.group(1)!);
              if (share >= 0 && share <= 100) {
                measures.add(
                  BusinessTableMeasure(
                    label: label,
                    metric: '비중',
                    period: h,
                    value: share,
                    unit: '%',
                  ),
                );
              }
            }
          }
        }
      }
      if (records.isEmpty) continue;
      final evidence = lines.sublist(i > 5 ? i - 5 : 0, j).join('\n');
      if (!seen.add(evidence)) continue;
      out.add(
        BusinessTableInsight(
          topic: topic,
          title: title(topic),
          columns: header,
          rows: records,
          measures: measures,
          evidence: evidence,
          validation: '명시된 열·원문 값 구조화 · 합계/비율 검산 미수행',
          scope: [
            ?scope,
            ?entity,
          ].join(' · '),
        ),
      );
      i = j - 1;
    }
    return out;
  }
}
