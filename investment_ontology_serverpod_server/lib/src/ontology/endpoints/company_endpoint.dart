import '../presentation/company_presentation.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../ingest/company_master_sync.dart';
import '../ingest/ksic_revision.dart';
import '../market/market_caps.dart';

/// 상장사 조회.
class CompanyEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  static const _listed = {Market.kospi, Market.kosdaq, Market.konex};

  /// 시장·대분류별 상장사 수와 최근 수집 작업.
  Future<Overview> overview(Session session) async {
    final byMarket = <FacetCount>[];
    for (final m in _listed) {
      byMarket.add(
        FacetCount(
          code: m.name,
          name: _marketName(m),
          count: await Company.db.count(
            session,
            where: (t) => t.market.equals(m),
          ),
        ),
      );
    }
    final lastJob = await IngestJob.db.findFirstRow(
      session,
      where: (t) => t.kind.equals(CompanyMasterSync.kind),
      orderBy: (t) => t.startedAt.desc(),
    );
    final lastFull = await CompanyMasterSync.lastFullRefresh(session);
    final revision = await KsicRevision.current(session);
    return Overview(
      totalListed: byMarket.fold(0, (sum, f) => sum + f.count),
      byMarket: byMarket,
      bySection: await _facet(
        session,
        column: 'sectionCode',
        revision: revision.revision,
      ),
      lastJob: lastJob,
      lastFullRefreshAt: lastFull?.finishedAt,
      nextFullRefreshAt: CompanyMasterSync.nextFullRefreshAt(lastFull),
      industryRevision: revision,
    );
  }

  /// 대분류 안의 중분류별 상장사 수.
  Future<List<FacetCount>> divisions(
    Session session,
    String sectionCode, {
    Market? market,
  }) async => _facet(
    session,
    column: 'divisionCode',
    sectionCode: sectionCode,
    market: market,
    revision: (await KsicRevision.current(session)).revision,
  );

  Future<CompanyPage> list(
    Session session, {
    String? query,
    Market? market,
    String? sectionCode,
    String? divisionCode,
    CompanySort? sort,
    int? offset,
    int? limit,
  }) async {
    final order = sort ?? CompanySort.name;
    offset = (offset ?? 0).clamp(0, 1 << 31);
    limit = (limit ?? 50).clamp(1, 200);
    Expression where(CompanyTable t) {
      Expression e = market != null
          ? t.market.equals(market)
          : t.market.inSet(_listed);
      if (sectionCode != null) e = e & t.sectionCode.equals(sectionCode);
      if (divisionCode != null) e = e & t.divisionCode.equals(divisionCode);
      return e;
    }

    final q = query?.trim() ?? '';
    final List<Company> rows;
    final Map<int, BigInt> caps;
    final int total;
    if (q.isEmpty) {
      total = await Company.db.count(session, where: where);
      if (order == CompanySort.marketCap) {
        // 시가총액은 시세 테이블에 있어, 조건에 맞는 기업 전체의 시총을 구해 정렬한 뒤 자른다.
        final all = await Company.db.find(session, where: where);
        caps = (await MarketCaps.latest(session, {
          for (final c in all) c.id!,
        })).caps;
        all.sort((a, b) {
          final ca = caps[a.id], cb = caps[b.id];
          if (ca == null && cb == null) {
            return a.displayName.compareTo(b.displayName);
          }
          if (ca == null) return 1;
          if (cb == null) return -1;
          return cb.compareTo(ca);
        });
        rows = all.skip(offset).take(limit).toList();
      } else if (order == CompanySort.name) {
        final all = await Company.db.find(session, where: where);
        all.sort((a, b) {
          final result = a.displayName.compareTo(b.displayName);
          return result != 0 ? result : a.corpCode.compareTo(b.corpCode);
        });
        rows = all.skip(offset).take(limit).toList();
        caps = (await MarketCaps.latest(session, {
          for (final c in rows) c.id!,
        })).caps;
      } else {
        rows = await Company.db.find(
          session,
          where: where,
          orderByList: (t) => switch (order) {
            CompanySort.name => [t.name.asc()],
            CompanySort.stockCode => [t.stockCode.asc()],
            CompanySort.establishedDate => [
              t.establishedDate.asc(),
              t.name.asc(),
            ],
            CompanySort.marketCap => [t.name.asc()],
          },
          offset: offset,
          limit: limit,
        );
        caps = (await MarketCaps.latest(session, {
          for (final c in rows) c.id!,
        })).caps;
      }
    } else {
      final all = await Company.db.find(session, where: where);
      final ranks = {for (final c in all) c.id!: CompanySearch.rank(c, q)};
      all.removeWhere((c) => ranks[c.id] == null);
      total = all.length;
      caps = (await MarketCaps.latest(session, {
        for (final c in all) c.id!,
      })).caps;
      all.sort((a, b) {
        if (order == CompanySort.marketCap) {
          final relevance = ranks[a.id]!.compareTo(ranks[b.id]!);
          if (relevance != 0) return relevance;
        }
        final comparison = switch (order) {
          CompanySort.name => a.displayName.compareTo(b.displayName),
          CompanySort.stockCode => (a.stockCode ?? '').compareTo(
            b.stockCode ?? '',
          ),
          CompanySort.establishedDate =>
            (a.establishedDate ?? DateTime(9999)).compareTo(
              b.establishedDate ?? DateTime(9999),
            ),
          CompanySort.marketCap =>
            caps[a.id] == null
                ? (caps[b.id] == null ? 0 : 1)
                : (caps[b.id] == null
                      ? -1
                      : caps[b.id]!.compareTo(caps[a.id]!)),
        };
        return comparison != 0
            ? comparison
            : a.displayName.compareTo(b.displayName);
      });
      rows = all.skip(offset).take(limit).toList();
    }

    final names = await _industryNames(
      session,
      (await KsicRevision.current(session)).revision,
      {
        for (final c in rows) ...[?c.industryCode, ?c.sectionCode],
      },
    );
    return CompanyPage(
      total: total,
      items: [
        for (final c in rows)
          CompanyListItem(
            corpCode: c.corpCode,
            name: c.displayName,
            stockCode: c.stockCode,
            market: c.market,
            industryCode: c.industryCode,
            industryName: names[c.industryCode],
            sectionCode: c.sectionCode,
            sectionName: names[c.sectionCode],
            ceoName: c.ceoName,
            fiscalMonth: c.fiscalMonth,
            establishedDate: c.establishedDate,
            marketCap: caps[c.id],
          ),
      ],
    );
  }

  Future<CompanyDetail?> detail(Session session, String corpCode) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return null;

    final path = <Industry>[];
    final code = company.industryCode;
    if (code != null) {
      final codes = [
        ?company.sectionCode,
        for (var len = 2; len <= code.length; len++) code.substring(0, len),
      ];
      final revision = (await KsicRevision.current(session)).revision;
      final found = {
        for (final i in await Industry.db.find(
          session,
          where: (t) =>
              t.revision.equals(revision) & t.code.inSet(codes.toSet()),
        ))
          i.code: i,
      };
      path.addAll([for (final c in codes) ?found[c]]);
    }

    final sourceId = company.profileSourceId;
    return CompanyDetail(
      company: company,
      industryPath: path,
      profileSource: sourceId == null
          ? null
          : await Source.db.findById(session, sourceId),
      changes: await CompanyChange.db.find(
        session,
        where: (t) => t.companyId.equals(company.id!),
        orderByList: (t) => [t.changedAt.desc(), t.field.asc()],
        limit: 50,
      ),
    );
  }

  Future<List<FacetCount>> _facet(
    Session session, {
    required String column,
    required String revision,
    String? sectionCode,
    Market? market,
  }) async {
    final markets = market != null ? [market] : _listed;
    final params = <String, dynamic>{
      for (final (i, m) in markets.indexed) 'm$i': m.name,
      'section': ?sectionCode,
    };
    final result = await session.db.unsafeQuery(
      'SELECT "$column" AS code, count(*)::int AS n FROM company '
      'WHERE "market" IN (${[for (var i = 0; i < markets.length; i++) '@m$i'].join(', ')}) '
      '${sectionCode != null ? 'AND "sectionCode" = @section ' : ''}'
      'AND "$column" IS NOT NULL '
      'GROUP BY 1 ORDER BY n DESC',
      parameters: QueryParameters.named(params),
    );
    final counts = [
      for (final row in result)
        (
          code: row.toColumnMap()['code'] as String,
          n: row.toColumnMap()['n'] as int,
        ),
    ];
    final names = await _industryNames(session, revision, {
      for (final c in counts) c.code,
    });
    return [
      for (final c in counts)
        FacetCount(code: c.code, name: names[c.code] ?? c.code, count: c.n),
    ];
  }

  Future<Map<String, String>> _industryNames(
    Session session,
    String revision,
    Set<String> codes,
  ) async {
    if (codes.isEmpty) return {};
    final rows = await Industry.db.find(
      session,
      where: (t) => t.revision.equals(revision) & t.code.inSet(codes),
    );
    return {for (final i in rows) i.code: i.name};
  }

  static String _marketName(Market m) => switch (m) {
    Market.kospi => '유가증권',
    Market.kosdaq => '코스닥',
    Market.konex => '코넥스',
    Market.other => '기타',
  };
}

/// Lookup keys never replace the source company name.
abstract final class CompanySearch {
  static const _letters = {
    'a': '에이',
    'b': '비',
    'c': '씨',
    'd': '디',
    'e': '이',
    'f': '에프',
    'g': '지',
    'h': '에이치',
    'i': '아이',
    'j': '제이',
    'k': '케이',
    'l': '엘',
    'm': '엠',
    'n': '엔',
    'o': '오',
    'p': '피',
    'q': '큐',
    'r': '알',
    's': '에스',
    't': '티',
    'u': '유',
    'v': '브이',
    'w': '더블유',
    'x': '엑스',
    'y': '와이',
    'z': '제트',
  };
  // A bounded vocabulary for name tokens, shared by every company. Unknown
  // English words are retained rather than guessed or fuzzily transliterated.
  static const _words = {
    '홀딩스': 'holdings',
    '네트웍스': 'networks',
    '네트워크': 'network',
    '바이오': 'bio',
    '테크': 'tech',
    '오일': 'oil',
    '뱅크': 'bank',
  };
  static String normalize(String value) {
    final width = String.fromCharCodes(
      value.runes.map((r) => r >= 0xff01 && r <= 0xff5e ? r - 0xfee0 : r),
    );
    return width
        .toLowerCase()
        .replaceAll(RegExp(r'\(\s*주\s*\)|㈜|주식회사|\(\s*유\s*\)|㈲|유한회사'), '')
        .replaceAll(RegExp(r'[\s\-‐‑–—·.,()&＆]'), '');
  }

  static String _canonical(String value) {
    var key = normalize(value);
    for (final entry in _words.entries) {
      key = key.replaceAll(entry.key, entry.value);
    }
    // Longest pronunciation first: 에이치 must precede 에이.
    final letters = _letters.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final pronunciations = letters.map((e) => e.value).join('|');
    key = key.replaceAllMapped(
      RegExp('($pronunciations)(?:앤드|앤)(?=($pronunciations))'),
      (m) => m[1]!,
    );
    final pattern = RegExp(pronunciations);
    return key.replaceAllMapped(
      pattern,
      (m) => letters.firstWhere((e) => e.value == m[0]).key,
    );
  }

  static String _initials(String value) => String.fromCharCodes(
    normalize(value).runes.map(
      (r) => r >= 0xac00 && r <= 0xd7a3
          ? 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'.runes.elementAt((r - 0xac00) ~/ 588)
          : r,
    ),
  );

  // Corrections are separate from literal matching. A real company named with
  // the user's spelling must outrank an inferred pronunciation or keyboard hit.
  static int? rank(Company company, String query) {
    final direct = _directRank(company, query);
    if (direct != null) return direct;
    final variant = query.replaceAll('애스', '에스');
    if (variant != query) {
      final corrected = _directRank(company, variant);
      if (corrected != null) return 10 + corrected;
    }
    // Avoid interpreting short acronyms/codes/punctuation as Korean keystrokes.
    // Preserve shifted double consonants/vowels; all-uppercase input is Caps Lock.
    final width = String.fromCharCodes(
      query.runes.map((r) => r >= 0xff01 && r <= 0xff5e ? r - 0xfee0 : r),
    ).trim().replaceAll(RegExp(r'[\s\-‐‑–—]'), '');
    if (!RegExp(r'^[a-zA-Z]{4,80}$').hasMatch(width)) return null;
    final keys = width == width.toUpperCase()
        ? width.toLowerCase()
        : width.replaceAllMapped(
            RegExp(r'[A-Z]'),
            (m) => 'REQTWOP'.contains(m[0]!) ? m[0]! : m[0]!.toLowerCase(),
          );
    var best = 99;
    for (final name in {
      normalize(company.name),
      normalize(company.displayName),
      _spokenName(company.name),
    }) {
      for (final spelling in {name, name.replaceAll('에스', '애스')}) {
        final keyboard = _keyboardKeys(spelling);
        if (keyboard == null) continue;
        final score = keyboard == keys
            ? 10
            : keyboard.startsWith(keys)
            ? 11
            : keyboard.contains(keys)
            ? 13
            : null;
        if (score != null && score < best) best = score;
      }
    }
    return best == 99 ? null : best;
  }

  static String _spokenName(String name) {
    var value = normalize(name);
    // Known name words keep their reading; remaining ASCII letters are initials.
    for (final entry in _words.entries) {
      value = value.replaceAll(entry.value, entry.key);
    }
    return value.replaceAllMapped(RegExp(r'[a-z]'), (m) => _letters[m[0]]!);
  }

  // Compare keystrokes against the indexed name rather than guessing syllable
  // boundaries in a mistyped query (e.g. dpt can mean 엣 or the start of 에스).
  // Unicode Hangul decomposition also covers compound vowels and final clusters.
  static String? _keyboardKeys(String name) {
    const leads = [
      'r',
      'R',
      's',
      'e',
      'E',
      'f',
      'a',
      'q',
      'Q',
      't',
      'T',
      'd',
      'w',
      'W',
      'c',
      'z',
      'x',
      'v',
      'g',
    ];
    const vowels = [
      'k',
      'o',
      'i',
      'O',
      'j',
      'p',
      'u',
      'P',
      'h',
      'hk',
      'ho',
      'hl',
      'y',
      'n',
      'nj',
      'np',
      'nl',
      'b',
      'm',
      'ml',
      'l',
    ];
    const tails = [
      '',
      'r',
      'R',
      'rt',
      's',
      'sw',
      'sg',
      'e',
      'f',
      'fr',
      'fa',
      'fq',
      'ft',
      'fx',
      'fv',
      'fg',
      'a',
      'q',
      'qt',
      't',
      'T',
      'd',
      'w',
      'c',
      'z',
      'x',
      'v',
      'g',
    ];
    final output = StringBuffer();
    var syllables = 0;
    for (final rune in name.runes) {
      if (rune < 0xac00 || rune > 0xd7a3) {
        output.writeCharCode(rune);
        continue;
      }
      final index = rune - 0xac00;
      output
        ..write(leads[index ~/ 588])
        ..write(vowels[(index % 588) ~/ 28])
        ..write(tails[index % 28]);
      syllables++;
    }
    return syllables >= 2 ? output.toString() : null;
  }

  static int? _directRank(Company company, String query) {
    final q = normalize(query);
    if (q.isEmpty) return null;
    final display = normalize(company.displayName);
    final stock = normalize(company.stockName ?? '');
    if (display == q || stock == q) return 0;
    if (display.startsWith(q) || (stock.isNotEmpty && stock.startsWith(q))) {
      return 1;
    }
    final name = normalize(company.name);
    final code = company.stockCode ?? '';
    if (name == q || code == q) return 0;
    final key = _canonical(query);
    final canonicalName = _canonical(company.name);
    if (canonicalName == key) return 0;
    if (name.startsWith(q) ||
        canonicalName.startsWith(key) ||
        code.startsWith(q)) {
      return 1;
    }
    final english = normalize(company.nameEng ?? '');
    if (english == q) return 0;
    if (english.startsWith(q)) return 2;
    if (display.contains(q) ||
        stock.contains(q) ||
        name.contains(q) ||
        canonicalName.contains(key) ||
        english.contains(q)) {
      return 3;
    }
    // Initial-only queries are explicit. Do not turn ordinary Korean text
    // into broad fuzzy matches or edit-distance guesses.
    if (RegExp(r'^[ㄱ-ㅎ]+$').hasMatch(q) &&
        _initials(company.name).contains(q)) {
      return 3;
    }
    if (normalize(company.ceoName ?? '').contains(q)) return 4;
    return null;
  }
}
