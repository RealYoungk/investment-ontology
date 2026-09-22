import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'disclosure_links.dart';
import 'market_share_facts.dart';
import 'order_facts.dart';
import 'segment_revenue.dart';

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
  static const maxRows = 40;

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
    var overAt = -1, underAt = -1;
    // 생산능력·생산실적·가동률 칸의 자리와 머리글의 칸 수 (오른쪽 끝 기준으로 다시 센다).
    var capAt = -1, prodAt = -1, utilAt = -1, columns = -1;
    var unitFromHeader = '';
    // 단위 줄("(단위 : 천㎡, %)")은 머리글 바로 위에 따로 온다. 3줄 안의 것만 쓴다.
    String? lastUnit;
    var lastUnitAt = -1000;
    // 세로형 표: "… | 생산능력 | 1,729,388 | …" 줄 뒤에 생산실적 줄, 가동률 줄이 온다.
    List<String>? vCapLabels;
    double? vCap, vProd;
    var vCapIsCapacity = false;
    var vAt = -1000;
    String vUnit = '';
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final u = RegExp(r'단위\s*[:：]\s*([^)\]]+)').firstMatch(line);
      if (u != null) {
        lastUnit = u.group(1)!.trim();
        lastUnitAt = i;
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
          inTable = false;
        } else if (otherCompanies.contains(name)) {
          otherCompany = true;
          inTable = false;
        }
        continue;
      }
      if (otherCompany) continue;
      final cells = [for (final c in line.split('|')) c.trim()];

      // 머리글: 생산능력·생산실적·가동률이 한 줄에 같이 있다.
      if (line.contains('생산능력') &&
          line.contains('생산실적') &&
          line.contains('가동률')) {
        // 당기·전기를 나란히 적는 표가 있다. 머리글에서 칸을 집어 **맨 앞(당기)**만 읽는다.
        capAt = cells.indexWhere((c) => c.contains('생산능력'));
        prodAt = cells.indexWhere((c) => c.contains('생산실적'));
        utilAt = cells.indexWhere((c) => c.contains('가동률'));
        columns = cells.length;
        inTable = capAt >= 0 && prodAt >= 0 && utilAt >= 0;
        onlyUtilization = false;
        unitFromHeader = _unitIn(line);
        // "생산능력(톤)"처럼 머리글 칸 괄호에 단위를 적기도 한다.
        if (unitFromHeader.isEmpty && capAt >= 0) {
          unitFromHeader = _unitFromParens(cells[capAt]);
        }
        if (unitFromHeader.isEmpty && i - lastUnitAt <= 6) {
          unitFromHeader = _firstUnit(lastUnit);
        }
        continue;
      }
      // 세로형: 구분 칸에 생산능력·생산실적·가동률이 줄마다 있고 숫자는 그 뒤 칸(당기가 맨 앞).
      final vertical = _verticalRow(cells);
      if (vertical != null) {
        final (kind, labels, value) = vertical;
        if (kind == 'cap') {
          vCapLabels = labels;
          vCap = value;
          vCapIsCapacity = cells.any((c) => c.contains('생산능력'));
          vProd = null;
          vAt = i;
          vUnit = i - lastUnitAt <= 6 ? _firstUnit(lastUnit) : '';
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
            vCap > 0 &&
            (value - 100 * vProd / vCap).abs() <= tolerance) {
          final name = vCapLabels!.join(' · ');
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
        inTable = over > 0 && under > 0;
        onlyUtilization = inTable;
        overAt = over;
        underAt = under;
        unitFromHeader = '';
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
        if (overAt >= cells.length || underAt >= cells.length) continue;
        final over = _num(cells[overAt]), under = _num(cells[underAt]);
        if (over == null || under == null || under <= 0) continue;
        if ((util - 100 * over / under).abs() > tolerance) continue;
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
        for (final l in labels)
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
      if (out.length >= maxRows) break;
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
    r'^(백만|천|억|만|百万|千|億|萬)?\s*(개|대|톤|ton|TON|t|㎡|m²|㎥|시간|MH|배치|GWh|MWh|MW|kW|장|매|EA|ea|박스|병|kg|L|ℓ|km|m|시트|Sheet|sheet|Panel|셀|Cell|Set|set|Bbl|배럴|정|Bag|Syringe|個|台|枚|톤/년|대/년)$',
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
  static (String, List<String>, double)? _verticalRow(List<String> cells) {
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
      final next = cells[k + 1];
      final v = kind == 'util' ? _percent(next) : _num(next);
      if (v == null) return null;
      final labels = [
        for (final l in cells.sublist(0, k))
          if (l.isNotEmpty && !_number.hasMatch(l)) l,
      ];
      return (kind, labels, v);
    }
    return null;
  }

  /// "(단위 : 백만개, %)" 처럼 적힌 단위.
  static String _unitIn(String line) {
    final m = RegExp(r'단위\s*[:：]\s*([^,)\]]+)').firstMatch(line);
    return m == null ? '' : m.group(1)!.trim();
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
    return known.contains(fromHeader) ? fromHeader : '';
  }

  /// 상장사 이름 키 (대괄호 구역이 다른 회사 것인지 가릴 때 쓴다).
  static Future<Set<String>> listedKeys(Session session) async => {
    for (final c in await Company.db.find(
      session,
      where: (t) => t.market.inSet(DisclosureLinks.listedMarkets),
    ))
      _key(c.name),
  };

  /// 한 문서에서 읽어 저장한다. 이미 사람이 결정한 항목은 건드리지 않는다.
  static Future<int> store(
    Session session,
    BusinessDocument doc, {

    /// 상장사 이름 키. 없으면 읽어 온다 (여러 문서를 돌릴 때는 미리 만들어 넘긴다).
    Set<String>? companyKeys,
  }) async {
    final company = await Company.db.findById(session, doc.companyId);
    // 지주회사(KSIC 64992)의 "사업의 내용"은 대부분 자회사·관계기업의 표다.
    // 그 회사 값으로 잘못 넣느니 통째로 건너뛴다.
    if (company?.industryCode == holdingCompanyCode) return 0;
    final others = companyKeys ?? await listedKeys(session);
    // 가동률 표가 없어도 부문별 매출·수주 표는 있을 수 있다 — 여기서 돌아가지 않는다.
    final rows = parse(doc.text, owner: company?.name, otherCompanies: others);
    final report = await DisclosureReport.db.findById(session, doc.reportId);
    final existing = {
      for (final f in await DocumentFact.db.find(
        session,
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
            asOf: DateTime.utc(doc.bsnsYear, 12, 31),
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
          asOf: DateTime.utc(doc.bsnsYear, 12, 31),
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
            asOf: DateTime.utc(doc.bsnsYear, 12, 31),
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
    // 연도별 시장점유율 표 (이 회사 줄의 % 값만). 해마다 값이 있어 키에 연도를 넣는다.
    for (final r in MarketShareFacts.parse(
      doc.text,
      owner: company!.name,
      bsnsYear: doc.bsnsYear,
    )) {
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
          asOf: DateTime.utc(r.year, 12, 31),
          evidence: r.evidence,
          sourceId: report?.sourceId,
          extractedBy: RelationOrigin.api,
          extractorModel: '표 규칙',
          status: RelationStatus.verified,
          reviewedAt: now,
          reviewedBy: '표 규칙 (연도별 시장점유율 표, 당사 줄)',
          createdAt: now,
        ),
      );
    }
    if (facts.isEmpty) return 0;
    await DocumentFact.db.insert(session, facts);
    return facts.length;
  }
}
