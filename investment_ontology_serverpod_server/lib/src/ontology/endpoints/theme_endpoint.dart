import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../ingest/ksic_revision.dart';
import '../market/market_caps.dart';

/// 테마 (5단계): 사용자가 정의하는 투자 주제와 기업 편입.
///
/// 편입은 사람의 판단이므로 출처는 manual Source로 남긴다.
class ThemeEndpoint extends Endpoint {
  /// 테마 목록. 편입 기업 시가총액이 큰 순서.
  Future<List<ThemeSummary>> list(Session session) async {
    final themes = await InvestmentTheme.db.find(
      session,
      orderBy: (t) => t.name,
    );
    final members = await ThemeMember.db.find(session);
    final companyIds = {for (final m in members) m.companyId};
    final caps = await MarketCaps.latest(session, companyIds);
    final names = {
      for (final c
          in companyIds.isEmpty
              ? const <Company>[]
              : await Company.db.find(
                  session,
                  where: (t) => t.id.inSet(companyIds),
                ))
        c.id!: c.name,
    };
    final summaries = [
      for (final theme in themes)
        () {
          final mine =
              [
                for (final m in members)
                  if (m.themeId == theme.id) m,
              ]..sort(
                (a, b) => (caps.caps[b.companyId] ?? BigInt.zero).compareTo(
                  caps.caps[a.companyId] ?? BigInt.zero,
                ),
              );
          final withCap = [
            for (final m in mine) ?caps.caps[m.companyId],
          ];
          return ThemeSummary(
            theme: theme,
            memberCount: mine.length,
            marketCap: withCap.isEmpty ? null : withCap.reduce((a, b) => a + b),
            topNames: [
              for (final m in mine.take(4)) names[m.companyId] ?? '',
            ],
          );
        }(),
    ];
    summaries.sort(
      (a, b) => (b.marketCap ?? BigInt.zero).compareTo(
        a.marketCap ?? BigInt.zero,
      ),
    );
    return summaries;
  }

  Future<InvestmentTheme> create(
    Session session,
    String name, {
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw IngestException(message: '테마 이름을 입력하세요.');
    }
    final existing = await InvestmentTheme.db.findFirstRow(
      session,
      where: (t) => t.name.equals(trimmed),
    );
    if (existing != null) return existing;
    final now = DateTime.now().toUtc();
    return InvestmentTheme.db.insertRow(
      session,
      InvestmentTheme(
        name: trimmed,
        description: _text(description),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<InvestmentTheme?> update(
    Session session,
    int themeId,
    String name, {
    String? description,
  }) async {
    final theme = await InvestmentTheme.db.findById(session, themeId);
    if (theme == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw IngestException(message: '테마 이름을 입력하세요.');
    }
    return InvestmentTheme.db.updateRow(
      session,
      InvestmentTheme(
        id: theme.id,
        name: trimmed,
        description: _text(description),
        createdAt: theme.createdAt,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// 테마를 지운다 (편입 기록도 함께). 사용자가 만든 것이라 지울 수 있다.
  Future<void> delete(Session session, int themeId) async {
    await InvestmentTheme.db.deleteWhere(
      session,
      where: (t) => t.id.equals(themeId),
    );
  }

  /// 테마와 편입 기업 (시가총액 큰 순서).
  Future<ThemeDetail?> detail(Session session, int themeId) async {
    final theme = await InvestmentTheme.db.findById(session, themeId);
    if (theme == null) return null;
    final members = await ThemeMember.db.find(
      session,
      where: (t) => t.themeId.equals(themeId),
    );
    final companyIds = {for (final m in members) m.companyId};
    final companies = {
      for (final c
          in companyIds.isEmpty
              ? const <Company>[]
              : await Company.db.find(
                  session,
                  where: (t) => t.id.inSet(companyIds),
                ))
        c.id!: c,
    };
    final caps = await MarketCaps.latest(session, companyIds);
    final industries = await _industryNames(session, companies.values);
    final views =
        [
          for (final m in members)
            if (companies[m.companyId] case final c?)
              ThemeMemberView(
                member: m,
                company: CompanyRef(
                  id: c.id!,
                  corpCode: c.corpCode,
                  name: c.name,
                  market: c.market,
                ),
                industryName: industries[c.industryCode],
                marketCap: caps.caps[c.id],
              ),
        ]..sort(
          (a, b) => (b.marketCap ?? BigInt.zero).compareTo(
            a.marketCap ?? BigInt.zero,
          ),
        );
    return ThemeDetail(theme: theme, members: views, baseDate: caps.baseDate);
  }

  /// 기업을 테마에 넣는다. 이미 있으면 메모만 고친다.
  Future<ThemeMember?> addCompany(
    Session session,
    int themeId,
    String corpCode, {
    String? note,
  }) async {
    final theme = await InvestmentTheme.db.findById(session, themeId);
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (theme == null || company == null) return null;
    final existing = await ThemeMember.db.findFirstRow(
      session,
      where: (t) => t.themeId.equals(themeId) & t.companyId.equals(company.id!),
    );
    if (existing != null) {
      return ThemeMember.db.updateRow(
        session,
        ThemeMember(
          id: existing.id,
          themeId: existing.themeId,
          companyId: existing.companyId,
          note: _text(note),
          sourceId: existing.sourceId,
          createdAt: existing.createdAt,
        ),
      );
    }
    final now = DateTime.now().toUtc();
    return session.db.transaction((tx) async {
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.manual,
          title: '사용자 입력 · 테마 "${theme.name}"에 ${company.name} 편입',
          retrievedAt: now,
        ),
        transaction: tx,
      );
      final member = await ThemeMember.db.insertRow(
        session,
        ThemeMember(
          themeId: themeId,
          companyId: company.id!,
          note: _text(note),
          sourceId: source.id!,
          createdAt: now,
        ),
        transaction: tx,
      );
      await InvestmentTheme.db.updateRow(
        session,
        theme.copyWith(updatedAt: now),
        transaction: tx,
      );
      return member;
    });
  }

  Future<void> removeCompany(
    Session session,
    int themeId,
    String corpCode,
  ) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return;
    await ThemeMember.db.deleteWhere(
      session,
      where: (t) => t.themeId.equals(themeId) & t.companyId.equals(company.id!),
    );
  }

  /// 기업이 속한 테마.
  Future<List<InvestmentTheme>> themesOf(
    Session session,
    String corpCode,
  ) async {
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) return [];
    final ids = {
      for (final m in await ThemeMember.db.find(
        session,
        where: (t) => t.companyId.equals(company.id!),
      ))
        m.themeId,
    };
    if (ids.isEmpty) return [];
    return InvestmentTheme.db.find(
      session,
      where: (t) => t.id.inSet(ids),
      orderBy: (t) => t.name,
    );
  }

  static String? _text(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  static Future<Map<String, String>> _industryNames(
    Session session,
    Iterable<Company> companies,
  ) async {
    final codes = {for (final c in companies) ?c.industryCode};
    if (codes.isEmpty) return {};
    final revision = (await KsicRevision.current(session)).revision;
    return {
      for (final i in await Industry.db.find(
        session,
        where: (t) => t.revision.equals(revision) & t.code.inSet(codes),
      ))
        i.code: i.name,
    };
  }
}
