import 'rule_document_store.dart';
import 'printed_period_columns.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'disclosure_links.dart';
import 'market_share_facts.dart';
import 'order_facts.dart';
import 'investment_facts.dart';
import 'segment_revenue.dart';
import 'business_breakdown_facts.dart';

/// 사업보고서 본문의 "생산능력·생산실적·가동률" 표를 규칙으로 읽는다 (AI 없음).
///
/// 형식이 일정한 표만 받는다: 머리글에 생산능력·생산실적·가동률이 함께 있고, 각 줄의
/// 끝 세 칸이 (수, 수, 퍼센트)이며, 가동률이 생산실적 ÷ 생산능력과 맞아야 한다.
/// 하나라도 어긋나면 그 줄은 버린다 — 틀린 값을 넣느니 비워 두는 쪽이 낫다.
///
/// 이렇게 뽑은 값은 DART API로 받은 값과 같은 급으로 본다 (`extractedBy: api`,
/// 사람 검수 없이 확정). 표를 그대로 옮긴 것이고 숫자끼리 앞뒤가 맞는지 확인하기
/// 때문이다. 문장에서 읽어야 하는 값(수주잔고 등)은 여전히 AI가 뽑고 사람이 본다.
abstract final class ProductionFacts {
  /// 가동률과 (생산실적 ÷ 생산능력)의 차이가 이보다 크면 열을 잘못 읽은 것으로 본다.
  static const tolerance = 2.0;

  /// 한 문서에서 받아들이는 최대 줄 수. 표가 통째로 들어오는 것을 막는다.

  /// 지주회사 (KSIC). 이 업종은 본문이 자회사 이야기라 규칙 추출을 하지 않는다.
  static const holdingCompanyCode = '64992';

  static final _number = RegExp(r'^-?[\d,]+(?:\.\d+)?$');

  /// 표의 한 줄에서 읽은 값.
  static List<
    ({
      String label,
      String unit,
      double? capacity,
      double? production,
      double utilization,
      String evidence,
    })
  >
  parse(
    String text, {
    String? owner,

    /// 다른 회사 이름(정규화한 키). 이 이름이 대괄호로 붙은 구역의 표는 건너뛴다.
    /// 대괄호는 사업부문 제목에도 쓰이므로, 아는 회사 이름일 때만 건너뛴다.
    Set<String> otherCompanies = const {},
  }) {
    final out =
        <
          ({
            String label,
            String unit,
            double? capacity,
            double? production,
            double utilization,
            String evidence,
          })
        >[];
    final lines = text.split('\n');
    // "[SK하이닉스]"처럼 다른 회사 이름이 붙은 구역의 표는 그 회사 것이다.
    // 지주사 보고서에는 자회사·관계기업의 표가 섞여 있다.
    final ownerKey = _key(owner ?? '');
    var otherCompany = false;
    var inTable = false;
    var onlyUtilization = false;
    var itemHeader = false;
    var utilAsProduction = false;
    var overAt = -1, underAt = -1;
    // 생산능력·생산실적·가동률 칸의 자리와 머리글의 칸 수 (오른쪽 끝 기준으로 다시 센다).
    var capAt = -1, prodAt = -1, utilAt = -1, columns = -1;
    var unitFromHeader = '';
    // 단위 줄("(단위 : 천㎡, %)")은 머리글 앞 6줄까지 찾되 절 경계를 넘기지 않는다.
    String? lastUnit;
    var lastUnitAt = -1000;
    // 세로형 표: "… | 생산능력 | 1,729,388 | …" 줄 뒤에 생산실적 줄, 가동률 줄이 온다.
    List<String>? vCapLabels;
    double? vCap, vProd;
    var vCapIsCapacity = false;
    var vAt = -1000;
    String vUnit = '';
    int verticalPeriod = 0;
    int verticalPeriods = 0;
    var process = '';
    void resetTable() {
      lastUnit = null;
      lastUnitAt = -1000;
      unitFromHeader = '';
      inTable = false;
      itemHeader = false;
      vCap = null;
      vProd = null;
      vUnit = '';
      verticalPeriod = 0;
      verticalPeriods = 0;
      process = '';
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (RegExp(r'^\(\d+\)\s*[^|]+$').hasMatch(line)) process = '';
      final processTitle = RegExp(r'(고진공\s*주조공정|가공\s*공정)$').firstMatch(line);
      if (processTitle != null && line.length < 200) {
        process = processTitle.group(1)!.trim();
      }
      // BusinessText가 절 제목을 ## 형태로 보존한다. 새 절에서는 단위뿐 아니라
      // 이전 가로형 머리글과 미완성 세로형 묶음도 이어 쓰면 안 된다.
      if (RegExp(r'^#{1,6}\s').hasMatch(line)) {
        resetTable();
        continue;
      }
      final marker = RegExp(r'^\[([^\]]{2,20})\]').firstMatch(line);
      if (marker != null) {
        final name = _key(marker.group(1)!);
        final isOwner =
            ownerKey.isNotEmpty &&
            (ownerKey.contains(name) || name.contains(ownerKey));
        // 대괄호는 "[제78기 누계]"처럼 표 제목에도 쓰인다. 회사 이름일 때만 바꾼다.
        if (isOwner) {
          otherCompany = false;
          resetTable();
        } else if (otherCompanies.contains(name)) {
          otherCompany = true;
          resetTable();
        }
        continue;
      }
      if (otherCompany) continue;
      final u = RegExp(r'단위\s*[:：]\s*([^)\]]+)').firstMatch(line);
      if (u != null) {
        lastUnit = u.group(1)!.trim();
        lastUnitAt = i;
      }
      final cells = [for (final c in line.split('|')) c.trim()];
      final printedPeriod = newestPrintedPeriod(cells);
      if (printedPeriod != null &&
          !cells.any((c) => _num(c) != null || c.endsWith('%'))) {
        verticalPeriod = printedPeriod;
        verticalPeriods = cells
            .where((c) => RegExp(r'(?:19|20)\d{2}|제\s*\d+\s*기').hasMatch(c))
            .length;
      }

      // 머리글: 생산능력·생산실적·가동률이 한 줄에 같이 있다.
      final headerCells = cells
          .map((c) => c.replaceAll(RegExp(r'\s+'), ''))
          .toList();
      if (headerCells.any((c) => c.contains('생산능력')) &&
          headerCells.any((c) => RegExp(r'생산실적|생산량|실제생산').hasMatch(c)) &&
          headerCells.any((c) => RegExp(r'가동률|가동율').hasMatch(c))) {
        // 당기·전기를 나란히 적는 표가 있다. 머리글에서 칸을 집어 **맨 앞(당기)**만 읽는다.
        capAt = headerCells.indexWhere((c) => c.contains('생산능력'));
        prodAt = headerCells.indexWhere(
          (c) => RegExp(r'생산실적|생산량|실제생산').hasMatch(c),
        );
        utilAt = headerCells.indexWhere((c) => RegExp(r'가동률|가동율').hasMatch(c));
        columns = cells.length;
        itemHeader = capAt == 1 && headerCells.first == '품목';
        inTable =
            capAt >= 0 &&
            prodAt >= 0 &&
            utilAt >= 0 &&
            capAt != prodAt &&
            capAt != utilAt &&
            prodAt != utilAt;
        onlyUtilization = false;
        unitFromHeader = _unitIn(line);
        // "생산능력(톤)"처럼 머리글 칸 괄호에 단위를 적기도 한다.
        if (unitFromHeader.isEmpty && capAt >= 0) {
          unitFromHeader = _unitFromParens(cells[capAt]);
        }
        if (unitFromHeader.isEmpty && i - lastUnitAt <= 6) {
          unitFromHeader = _firstUnit(lastUnit);
        }
        // 실제 열 머리글에서만 소비한다. 세 키워드가 든 설명 문장은
        // 머리글이 아니며, 그 문장에 적힌 단위는 다음 표가 사용한다.
        if (inTable) lastUnit = null;
        vCap = null;
        vProd = null;
        continue;
      }
      // 세로형: 구분 칸에 생산능력·생산실적·가동률이 줄마다 있고 숫자는 그 뒤 칸(당기가 맨 앞).
      final vertical = _verticalRow(
        cells,
        period: verticalPeriod,
        periods: verticalPeriods,
      );
      if (vertical != null) {
        final (kind, labels, value, unitInCell) = vertical;
        if (kind == 'cap') {
          vCapLabels = labels;
          vCap = value;
          vCapIsCapacity = cells.any((c) => c.contains('생산능력'));
          vProd = null;
          vAt = i;
          // "생산능력(PACK)"처럼 구분 칸 괄호의 단위가 먼저다.
          vUnit = unitInCell;
          if (vUnit.isEmpty && i - lastUnitAt <= 6) {
            vUnit = _firstUnit(lastUnit);
          }
          if (vUnit.isEmpty) {
            for (final l in labels) {
              vUnit = _unitFromParens(l);
              if (vUnit.isNotEmpty) break;
            }
          }
        } else if (kind == 'prod' && vCap != null && i - vAt <= 2) {
          vProd = value;
        } else if (kind == 'util' &&
            vCap != null &&
            vProd != null &&
            i - vAt <= 3 &&
            vCap! > 0 &&
            (value - 100 * vProd! / vCap!).abs() <= tolerance) {
          final name = [
            ...vCapLabels!.isEmpty ? ['전체'] : vCapLabels,
            if (process.isNotEmpty) process,
          ].join(' · ');
          if (name.isNotEmpty) {
            out.add((
              label: name.length > 60 ? name.substring(0, 60) : name,
              unit: vCapIsCapacity ? vUnit : '',
              capacity: vCapIsCapacity ? vCap : null,
              production: vCapIsCapacity ? vProd : null,
              utilization: value,
              evidence: line,
            ));
          }
          vCap = null;
          vProd = null;
        }
        if (kind != 'cap' && kind != 'prod') {
          vCap = null;
        }
        continue;
      }
      // 가동률만 따로 적는 표 (가동가능시간·실제가동시간 …). 비율만 받되,
      // 머리글에서 분자(실제…)와 분모(…가능) 칸을 집어 스스로 검산한다.
      if (line.contains('가동률') && cells.length >= 3) {
        final over = cells.indexWhere((c) => c.contains('실제'));
        final under = cells.indexWhere((c) => c.contains('가능'));
        inTable = over >= 0 && under >= 0 && over != under;
        columns = cells.length;
        onlyUtilization = inTable;
        itemHeader = false;
        overAt = over;
        underAt = under;
        // "생산가능수량 | 실제생산수량"은 생산능력·생산실적이다 (시간이면 가동률만).
        utilAsProduction =
            inTable &&
            cells[over].contains('생산') &&
            cells[under].contains('생산') &&
            !cells[under].contains('시간');
        unitFromHeader = '';
        if (utilAsProduction) {
          unitFromHeader = _unitFromParens(cells[under]);
          if (unitFromHeader.isEmpty && i - lastUnitAt <= 6) {
            unitFromHeader = _firstUnit(lastUnit);
          }
        }
        lastUnit = null;
        vCap = null;
        vProd = null;
        continue;
      }
      if (!inTable) continue;
      // 숫자 줄이 아니면 표가 끝난 것으로 본다 (주석 ※ 등).
      if (cells.length < 4 || line.startsWith('※')) {
        if (!line.startsWith('※')) inTable = false;
        continue;
      }

      double? util;
      double? cap, prod;
      var labelEnd = cells.length - 1;
      if (onlyUtilization) {
        final last = cells.last;
        if (!last.endsWith('%')) continue;
        util = double.tryParse(last.replaceAll(RegExp(r'[%,]'), ''));
        if (util == null) continue;
        final overIdx = cells.length - (columns - overAt);
        final underIdx = cells.length - (columns - underAt);
        if (overIdx < 0 || underIdx < 0) continue;
        final over = _num(cells[overIdx]), under = _num(cells[underIdx]);
        if (over == null || under == null || under <= 0) continue;
        if ((util - 100 * over / under).abs() > tolerance) continue;
        if (utilAsProduction) {
          cap = under;
          prod = over;
          labelEnd = underIdx;
        }
      } else {
        // 머리글에서 집은 칸을 오른쪽 끝 기준으로 다시 찾는다 (이름 칸이 합쳐져 있어도
        // 기(期)별 숫자 묶음은 그대로다).
        final capIdx = cells.length - (columns - capAt);
        final prodIdx = cells.length - (columns - prodAt);
        final utilIdx = cells.length - (columns - utilAt);
        if (capIdx < 0 || utilIdx >= cells.length) continue;
        util = _percent(cells[utilIdx]);
        cap = _num(cells[capIdx]);
        prod = _num(cells[prodIdx]);
        if (util == null || cap == null || prod == null || cap <= 0) continue;
        if ((util - 100 * prod / cap).abs() > tolerance) continue;
        labelEnd = capIdx;
      }

      final labels = [
        for (final c in cells.sublist(0, labelEnd.clamp(0, cells.length)))
          if (c.isNotEmpty && !_number.hasMatch(c)) c,
      ];
      if (labels.isEmpty) continue;
      // 마지막 글자 칸이 단위일 때가 많다 (백만개, 톤 …). 이름 칸 괄호("광학솔루션(백만개)",
      // "Chemical(ton)")에 적기도 한다.
      var unit = _unitOf(labels.last, unitFromHeader);
      if (unit.isEmpty) {
        for (final l in labels) {
          unit = _unitFromParens(l);
          if (unit.isNotEmpty) break;
        }
      }
      final name = [
        // A merged division cell precedes the product beneath one 품목 header.
        // Keep the actual item stable when that division suffix is misspelled.
        for (final l
            in itemHeader &&
                    labels.length == 2 &&
                    RegExp(r'(부문|부분)$').hasMatch(labels.first)
                ? labels.skip(1)
                : labels)
          if (l != unit) l,
      ].join(' · ');
      if (name.isEmpty) continue;
      out.add((
        label: name.length > 60 ? name.substring(0, 60) : name,
        unit: unit,
        capacity: cap,
        production: prod,
        utilization: util,
        evidence: line,
      ));
    }
    return out;
  }

  /// "50%", "50.4 %" → 50, 50.4. 아니면 null.
  static double? _percent(String s) =>
      double.tryParse(s.replaceAll(RegExp(r'[%,\s]'), ''));

  /// 이름 비교용 (괄호·법인 표기·공백을 떼고 소문자로).
  static String _key(String name) {
    var k = name.replaceAll(RegExp(r'\(주\)|㈜|주식회사|\s'), '').toLowerCase();
    // 같은 회사를 한글·로마자로 섞어 적는다 ("SK스퀘어" · "에스케이스퀘어").
    const alias = {
      '에스케이': 'sk',
      '엘지': 'lg',
      '케이티': 'kt',
      '지에스': 'gs',
      '씨제이': 'cj',
      '에이치디': 'hd',
      '포스코': 'posco',
    };
    for (final e in alias.entries) {
      k = k.replaceAll(e.key, e.value);
    }
    return k;
  }

  static double? _num(String s) =>
      _number.hasMatch(s) ? double.tryParse(s.replaceAll(',', '')) : null;

  /// 단위 줄의 첫 단위 ("천㎡, %" → 천㎡). 품목마다 다른 단위("완제의약품-백만정, …")나
  /// 숫자가 섞인 것은 단위로 보지 않는다.
  static String _firstUnit(String? raw) {
    if (raw == null) return '';
    // A printed scale belongs to the unit; its thousands comma is not a
    // separator between different units. Preserve it without converting values.
    final scaled = RegExp(
      r'^\s*((?:1,000,000|1,000|1000|1000000)\s*(?:pcs|PCS|EA|ea|개))\s*(?:,\s*%)?\s*$',
    ).firstMatch(raw);
    if (scaled != null) return scaled.group(1)!.trim();
    for (final part in raw.split(',')) {
      final t = part.trim();
      if (t.isEmpty || t == '%') continue;
      if (t.length > 8 || RegExp(r'[0-9\-:]').hasMatch(t)) return '';
      return t;
    }
    return '';
  }

  /// 괄호 속 단위 낱말 ("광학솔루션(백만개)" → 백만개, "Chemical(ton)" → ton). 단위처럼
  /// 생긴 짧은 낱말만 — "(연결)"·"(주1)"은 아니다.
  static final _unitWord = RegExp(
    r'^(백만|천|억|만|百万|千|億|萬)?\s*(개|대|톤|ton|TON|t|㎡|m²|㎥|시간|MH|배치|GWh|MWh|MW|kW|장|매|EA|ea|박스|병|kg|L|ℓ|km|m|시트|Sheet|sheet|Panel|셀|Cell|Set|set|Bbl|배럴|정|Bag|Syringe|個|台|枚|PACK|Pack|pack|Roll|롤|Kg|KG|톤/년|대/년|M|MT|BBL)$',
  );

  static String _unitFromParens(String cell) {
    for (final m in RegExp(r'\(([^()]{1,10})\)').allMatches(cell)) {
      final t = m.group(1)!.trim();
      if (_unitWord.hasMatch(t)) return t;
    }
    return '';
  }

  static final _vCap = RegExp(r'^(당기\s*)?(생산능력|가동가능시간|목표\s*가동시간|조업가능)');
  static final _vProd = RegExp(r'^(당기\s*)?(생산실적|실제\s*가동시간|실제\s*생산)');
  static final _vUtil = RegExp(r'^(당기\s*|평균\s*)?(가동률|가동율)');

  /// 세로형 표의 한 줄: (종류, 이름 칸들, 첫 숫자). 구분 칸(생산능력·생산실적·가동률) 바로
  /// 뒤의 숫자가 당기다. 그런 칸이 없으면 null.
  static (String, List<String>, double, String)? _verticalRow(
    List<String> cells, {
    int period = 0,
    int periods = 0,
  }) {
    for (var k = 0; k < cells.length - 1; k++) {
      final c = cells[k];
      final kind = _vCap.hasMatch(c)
          ? 'cap'
          : _vProd.hasMatch(c)
          ? 'prod'
          : _vUtil.hasMatch(c)
          ? 'util'
          : null;
      if (kind == null) continue;
      final at = periods > 0 ? cells.length - periods + period : k + 1;
      if (at <= k || at >= cells.length) return null;
      final next = cells[at];
      final v = kind == 'util' ? _percent(next) : _num(next);
      if (v == null) return null;
      final labels = [
        for (final l in cells.sublist(0, k))
          if (l.isNotEmpty && !_number.hasMatch(l)) l,
      ];
      return (kind, labels, v, _unitFromParens(c));
    }
    return null;
  }

  /// "(단위 : 백만개, %)" 처럼 적힌 단위.
  static String _unitIn(String line) {
    final m = RegExp(r'단위\s*[:：]\s*([^)\]]+)').firstMatch(line);
    return m == null ? '' : _firstUnit(m.group(1));
  }

  /// 칸에 적힌 단위처럼 보이면 그것을, 아니면 머리글의 단위를 쓴다.
  static String _unitOf(String cell, String fromHeader) {
    const known = {
      '백만개',
      '천개',
      '개',
      '톤',
      '대',
      '천대',
      '백만원',
      '억원',
      '천㎡',
      '㎡',
      'MH',
      '배치',
      '억개',
      'GWh',
      '천톤',
    };
    if (known.contains(cell)) return cell;
    if (_unitWord.hasMatch(fromHeader) ||
        RegExp(r'^(?:1,000,000|1,000|1000|1000000)\s*(?:pcs|PCS|EA|ea|개)$')
            .hasMatch(fromHeader)) {
      return fromHeader;
    }
    return known.contains(fromHeader) ? fromHeader : '';
  }

  /// 상장사 이름 키 (대괄호 구역이 다른 회사 것인지 가릴 때 쓴다).
  static Future<Set<String>> listedKeys(
    Session session, {
    Transaction? transaction,
  }) async => {
    for (final c in await Company.db.find(
      session,
      where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
      transaction: transaction,
    ))
      _key(c.name),
  };

  /// 한 문서에서 읽어 저장한다. 이미 사람이 결정한 항목은 건드리지 않는다.
  /// A table's fiscal-half/quarter header uses the issuer's fiscal calendar.
  static DateTime marketShareDate({
    required int year,
    required int month,
    required int bsnsYear,
    required DateTime periodEnd,
    required FinancialReportCode reportCode,
  }) {
    if (month == 12) return DateTime.utc(year, 12, 31);
    final elapsed = switch (reportCode) {
      FinancialReportCode.q1 => 3,
      FinancialReportCode.halfYear => 6,
      FinancialReportCode.q3 => 9,
      FinancialReportCode.annual => 12,
    };
    return DateTime.utc(
      periodEnd.year - (bsnsYear - year),
      periodEnd.month + month - elapsed + 1,
      0,
    );
  }

  static Future<int> store(
    Session session,
    BusinessDocument doc, {

    /// 상장사 이름 키. 없으면 읽어 온다 (여러 문서를 돌릴 때는 미리 만들어 넘긴다).
    Set<String>? companyKeys,
  }) => RuleDocumentStore.run(
    session,
    doc,
    (current, tx) => _store(session, current, tx, companyKeys: companyKeys),
  );

  static Future<int> _store(
    Session session,
    BusinessDocument doc,
    Transaction tx, {
    Set<String>? companyKeys,
  }) async {
    await DocumentFact.db.deleteWhere(
      session,
      transaction: tx,
      where: (t) =>
          t.documentId.equals(doc.id!) &
          t.extractedBy.equals(RelationOrigin.api) &
          t.extractorModel.equals('표 규칙') &
          t.reviewedBy.like('표 규칙%') &
          t.kind.notInSet({
            DocumentFactKind.rndExpense,
            DocumentFactKind.rndRatio,
          }),
    );
    final company = await Company.db.findById(
      session,
      doc.companyId,
      transaction: tx,
    );
    // 지주회사(KSIC 64992)의 "사업의 내용"은 대부분 자회사·관계기업의 표다.
    // 그 회사 값으로 잘못 넣느니 통째로 건너뛴다.
    if (company?.industryCode == holdingCompanyCode) return 0;
    final others = companyKeys ?? await listedKeys(session, transaction: tx);
    // 가동률 표가 없어도 부문별 매출·수주 표는 있을 수 있다 — 여기서 돌아가지 않는다.
    final rows = parse(doc.text, owner: company?.name, otherCompanies: others);
    final report = await DisclosureReport.db.findById(
      session,
      doc.reportId,
      transaction: tx,
    );
    // A cumulative interim value is dated to the actual reporting period, never December.
    final periodEnd =
        report?.settlementDate ?? DateTime.utc(doc.bsnsYear, 12, 31);
    if (report?.reportCode != FinancialReportCode.annual &&
        report?.settlementDate == null) {
      return 0;
    }
    final existing = {
      for (final f in await DocumentFact.db.find(
        session,
        transaction: tx,
        where: (t) => t.documentId.equals(doc.id!),
      ))
        if (f.kind == DocumentFactKind.marketShare)
          '${f.kind.name}|${f.label}|${f.asOf?.year}'
        else
          '${f.kind.name}|${f.label}',
    };
    final now = DateTime.now().toUtc();
    final facts = <DocumentFact>[];
    for (final r in rows) {
      // 단위를 모르면 생산능력·실적은 넣지 않지만, 가동률(%)은 단위가 필요 없으니 넣는다.
      final withAmounts = r.unit.isNotEmpty;
      for (final (kind, value, unit) in [
        if (withAmounts && r.capacity != null)
          (DocumentFactKind.capacity, r.capacity!, r.unit),
        if (withAmounts && r.production != null)
          (DocumentFactKind.production, r.production!, r.unit),
        (DocumentFactKind.utilization, r.utilization, '%'),
      ]) {
        if (!existing.add('${kind.name}|${r.label}')) continue;
        facts.add(
          DocumentFact(
            companyId: doc.companyId,
            documentId: doc.id!,
            bsnsYear: doc.bsnsYear,
            kind: kind,
            label: r.label,
            value: value,
            unit: unit,
            asOf: periodEnd,
            evidence: r.evidence,
            sourceId: report?.sourceId,
            // 표를 그대로 옮긴 것이라 DART API로 받은 값과 같은 급으로 본다.
            extractedBy: RelationOrigin.api,
            extractorModel: '표 규칙',
            status: RelationStatus.verified,
            reviewedAt: now,
            reviewedBy: '표 규칙 (가동률 = 생산실적 ÷ 생산능력 확인)',
            createdAt: now,
          ),
        );
      }
    }
    // 부문별 매출도 같은 규칙으로 (표의 비중으로 스스로 검산된다).
    for (final r in SegmentRevenue.parse(doc.text)) {
      if (!existing.add('segmentRevenue|${r.label}')) continue;
      facts.add(
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: DocumentFactKind.segmentRevenue,
          label: r.label,
          value: r.amount,
          unit: r.unit,
          asOf: periodEnd,
          evidence: r.evidence,
          sourceId: report?.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedAt: now,
          reviewedBy: '표 규칙 (비중 = 매출액 ÷ 합계 확인)',
          createdAt: now,
        ),
      );
    }
    for (final r in BusinessBreakdownFacts.parse(
      doc.text,
      year: doc.bsnsYear,
      owner: company?.name,
      otherCompanies: others,
    )) {
      if (!existing.add('${r.kind.name}|${r.label}')) continue;
      facts.add(
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: r.kind,
          label: r.label,
          value: r.value,
          unit: r.unit,
          asOf: periodEnd,
          evidence: r.evidence,
          sourceId: report?.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedAt: now,
          reviewedBy: '표 규칙 (사업부문 비중·지역 매출 합계 검증)',
          reviewNote: r.note,
          createdAt: now,
        ),
      );
    }
    // 수주상황 표도 같은 규칙으로 (수주총액 − 기납품액 = 수주잔고로 스스로 검산된다).
    for (final r in OrderFacts.parse(doc.text)) {
      for (final (kind, value) in [
        (DocumentFactKind.orderTotal, r.total),
        (DocumentFactKind.orderDelivered, r.delivered),
        (DocumentFactKind.orderBacklog, r.backlog),
      ]) {
        if (!existing.add('${kind.name}|${r.label}')) continue;
        facts.add(
          DocumentFact(
            companyId: doc.companyId,
            documentId: doc.id!,
            bsnsYear: doc.bsnsYear,
            kind: kind,
            label: r.label,
            value: value,
            unit: r.unit,
            asOf: periodEnd,
            evidence: r.evidence,
            sourceId: report?.sourceId,
            extractedBy: RelationOrigin.api,
            extractorModel: '표 규칙',
            status: RelationStatus.verified,
            reviewedAt: now,
            reviewedBy: '표 규칙 (수주총액 − 기납품액 = 수주잔고 확인)',
            createdAt: now,
          ),
        );
      }
    }
    for (final r in InvestmentFacts.parse(
      doc.text,
      periodEnd: periodEnd,
      owner: company?.name,
      otherCompanies: others,
    )) {
      if (!existing.add('investmentActual|${r.label}')) continue;
      facts.add(
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: DocumentFactKind.investmentActual,
          label: r.label,
          value: r.value,
          unit: r.unit,
          asOf: r.asOf,
          evidence: r.evidence,
          sourceId: report?.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedAt: now,
          reviewNote: r.reconciled ? null : '원문 부문 합계와 공시 총액 불일치',
          reviewedBy: r.reconciled
              ? '표 규칙 (투자기간·금액열 확인·부문 합계 검산)'
              : '표 규칙 (투자기간·금액열 확인·원문 합계 불일치 기록)',
          createdAt: now,
        ),
      );
    }
    // 연도별 시장점유율 표 (이 회사 줄의 % 값만). 해마다 값이 있어 키에 연도를 넣는다.
    for (final r in MarketShareFacts.parse(
      doc.text,
      owner: company!.name,
      bsnsYear: doc.bsnsYear,
    )) {
      final asOf = marketShareDate(
        year: r.year,
        month: r.month,
        bsnsYear: doc.bsnsYear,
        periodEnd: periodEnd,
        reportCode: report?.reportCode ?? FinancialReportCode.annual,
      );
      if (asOf.isAfter(periodEnd)) continue;
      if (!existing.add('marketShare|${r.label}|${r.year}')) continue;
      facts.add(
        DocumentFact(
          companyId: doc.companyId,
          documentId: doc.id!,
          bsnsYear: doc.bsnsYear,
          kind: DocumentFactKind.marketShare,
          label: r.label,
          value: r.value,
          unit: '%',
          asOf: asOf,
          evidence: r.evidence,
          sourceId: report?.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedAt: now,
          reviewNote: [
            if (r.basis.isNotEmpty) r.basis,
            if (r.estimated && r.year == doc.bsnsYear) '회사 추정',
          ].join(' · '),
          reviewedBy: '표 규칙 (연도별 시장점유율 표, 당사 줄)',
          createdAt: now,
        ),
      );
    }
    if (facts.isEmpty) return 0;
    await DocumentFact.db.insert(session, facts, transaction: tx);
    return facts.length;
  }
}
