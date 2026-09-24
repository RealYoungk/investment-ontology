import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../research/research_content.dart';

/// Published editions are public; drafts and publishing are administrator-only.
class ResearchEndpoint extends Endpoint {
  Future<List<ResearchEntry>> list(
    Session session, {
    String query = '',
    String market = '',
    bool manage = false,
    bool savedOnly = false,
    String? ticker,
    int offset = 0,
  }) async {
    if (manage) OntologyAccess.requireAdmin(session);
    if (savedOnly && session.authenticated == null) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.unauthenticated,
      );
    }
    // Only the one revision a reader may see (published, or latest for
    // administrators) is joined, filtered, ordered and paged in the database;
    // bodies are searched there and never leave it.
    final user = session.authenticated?.userIdentifier;
    final params = <String, Object>{
      'user': user ?? '',
      'offset': offset.clamp(0, 100000),
      'limit': pageSize,
    };
    final where = <String>[];
    if (savedOnly) where.add('b."id" IS NOT NULL');
    if (market.isNotEmpty) {
      where.add('r."market" = @market');
      params['market'] = market;
    }
    if (ticker != null) {
      where.add('r."ticker" = @ticker');
      params['ticker'] = ticker;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      // strpos, not LIKE: % and _ in a search are literal characters.
      where.add(
        "strpos(lower(r.\"title\" || ' ' || r.\"ticker\" || ' ' || "
        "r.\"summary\" || ' ' || r.\"searchText\"), @q) > 0",
      );
      params['q'] = q;
    }
    final rows = await session.db.unsafeQuery(
      'SELECT a."id" AS "articleId", a."slug", a."latestVersion", '
      'a."publishedVersion", r."id", r."version", r."title", r."summary", '
      'r."ticker", r."market", r."format", r."dataAsOf", r."publishedAt", '
      'r."createdAt", ${manage ? 'r."note"' : "''"} AS "note", r."legacy", b."id" IS NOT NULL AS "saved" '
      'FROM "research_article" a '
      'JOIN "research_revision" r ON r."articleId" = a."id" AND r."version" = '
      '${manage ? 'a."latestVersion"' : 'a."publishedVersion"'} '
      'LEFT JOIN "research_bookmark" b '
      'ON b."articleId" = a."id" AND b."userId" = @user '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
      'ORDER BY r."dataAsOf" DESC, a."id" DESC LIMIT @limit OFFSET @offset',
      parameters: QueryParameters.named(params),
    );
    return [
      for (final row in rows) _entry(row.toColumnMap()),
    ];
  }

  /// Page size of [list]; the app asks for more while a full page comes back.
  static const pageSize = 30;

  static ResearchEntry _entry(Map<String, dynamic> m) => ResearchEntry(
    article: ResearchArticle(
      id: m['articleId'] as int,
      slug: m['slug'] as String,
      latestVersion: m['latestVersion'] as int,
      publishedVersion: m['publishedVersion'] as int?,
    ),
    revision: ResearchRevision(
      id: m['id'] as int,
      articleId: m['articleId'] as int,
      version: m['version'] as int,
      title: m['title'] as String,
      summary: m['summary'] as String,
      ticker: m['ticker'] as String,
      market: m['market'] as String,
      content: '',
      format: m['format'] as String,
      searchText: '',
      dataAsOf: _utc(m['dataAsOf'])!,
      publishedAt: _utc(m['publishedAt']),
      createdAt: _utc(m['createdAt'])!,
      note: m['note'] as String,
      legacy: m['legacy'] as bool,
    ),
    saved: m['saved'] as bool,
  );

  // Columns are `timestamp without time zone` holding UTC, as the ORM writes.
  static DateTime? _utc(Object? v) => v == null
      ? null
      : (v as DateTime).isUtc
      ? v
      : DateTime.utc(
          v.year,
          v.month,
          v.day,
          v.hour,
          v.minute,
          v.second,
          v.millisecond,
          v.microsecond,
        );

  Future<ResearchEntry?> get(
    Session session,
    String slug, {
    bool draft = false,
    bool source = false,
    int? version,
  }) async {
    if (draft || source) {
      OntologyAccess.requireAdmin(session);
    }
    final a = await ResearchArticle.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(slug),
    );
    if (a == null) return null;
    final v = version ?? (draft ? a.latestVersion : a.publishedVersion);
    if (v == null) return null;
    final r = await ResearchRevision.db.findFirstRow(
      session,
      where: (t) => t.articleId.equals(a.id!) & t.version.equals(v),
    );
    if (r == null) return null;
    if (version != null &&
        !OntologyAccess.isAdmin(session.authenticated) &&
        (r.publishedAt == null || a.publishedVersion == null)) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.insufficientAccess,
      );
    }
    final c = await Company.db.findFirstRow(
      session,
      where: (t) => t.stockCode.equals(r.ticker),
    );
    final saved = session.authenticated == null
        ? null
        : await ResearchBookmark.db.findFirstRow(
            session,
            where: (t) =>
                t.articleId.equals(a.id!) &
                t.userId.equals(session.authenticated!.userIdentifier),
          );
    // Public payload always contains rendered, sanitized markup, never draft source.
    return ResearchEntry(
      article: a,
      revision: source
          ? r
          : r.copyWith(
              content: ResearchContent.render(r.content, r.format),
              format: 'html',
              searchText: '',
              note: '',
            ),
      corpCode: c?.corpCode,
      saved: saved != null,
    );
  }

  Future<ResearchEntry> save(
    Session session,
    String slug,
    String title,
    String summary,
    String ticker,
    String market,
    String content,
    String format,
    DateTime dataAsOf,
    int expectedVersion,
    String note,
  ) async {
    OntologyAccess.requireAdmin(session);
    if (slug == 'new' ||
        !RegExp(r'^[a-z0-9][a-z0-9-]{0,79}$').hasMatch(slug) ||
        title.trim().isEmpty ||
        title.length > 160 ||
        summary.trim().isEmpty ||
        summary.length > 1500 ||
        !RegExp(r'^[0-9A-Za-z]{6}$').hasMatch(ticker) ||
        !{'KOSPI', 'KOSDAQ', 'KONEX'}.contains(market) ||
        note.length > 1000) {
      throw IngestException(message: '주소·제목·핵심 관점·6자리 종목코드·시장을 확인하세요.');
    }
    final String rendered;
    try {
      rendered = ResearchContent.render(content, format);
    } on ArgumentError catch (e) {
      // Too long or an unknown format: a message for the editor, not a 500.
      throw IngestException(message: '${e.message}');
    }
    final text = ResearchContent.text(rendered);
    if (text.trim().isEmpty) throw IngestException(message: '본문을 입력하세요.');
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'LOCK TABLE research_article IN EXCLUSIVE MODE',
        transaction: tx,
      );
      var a = await ResearchArticle.db.findFirstRow(
        session,
        where: (t) => t.slug.equals(slug),
        transaction: tx,
      );
      if ((a?.latestVersion ?? 0) != expectedVersion) {
        throw IngestException(message: '다른 곳에서 수정되었습니다. 최신 버전을 다시 불러오세요.');
      }
      a ??= await ResearchArticle.db.insertRow(
        session,
        ResearchArticle(slug: slug, latestVersion: 0),
        transaction: tx,
      );
      final old = await ResearchRevision.db.findFirstRow(
        session,
        where: (t) =>
            t.articleId.equals(a!.id!) & t.version.equals(a.latestVersion),
        transaction: tx,
      );
      final v = a.latestVersion + 1;
      await ResearchRevision.db.insertRow(
        session,
        ResearchRevision(
          articleId: a.id!,
          version: v,
          title: title.trim(),
          summary: summary.trim(),
          ticker: ticker.toUpperCase(),
          market: market,
          content: format == 'html' ? rendered : content,
          format: format,
          searchText: text,
          dataAsOf: dataAsOf.toUtc(),
          createdAt: DateTime.now().toUtc(),
          note: note.trim(),
          legacy: old?.legacy ?? false,
        ),
        transaction: tx,
      );
      await ResearchArticle.db.updateRow(
        session,
        a.copyWith(latestVersion: v),
        transaction: tx,
      );
    });
    return (await get(session, slug, draft: true, source: true))!;
  }

  Future<void> publish(
    Session session,
    String slug,
    int version, {
    bool withdraw = false,
  }) async {
    OntologyAccess.requireAdmin(session);
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'LOCK TABLE research_article IN EXCLUSIVE MODE',
        transaction: tx,
      );
      final a = await ResearchArticle.db.findFirstRow(
        session,
        where: (t) => t.slug.equals(slug),
        transaction: tx,
      );
      if (a == null || a.latestVersion != version) {
        throw IngestException(message: '최신 초안을 다시 확인하세요.');
      }
      if (!withdraw) {
        final r = await ResearchRevision.db.findFirstRow(
          session,
          where: (t) => t.articleId.equals(a.id!) & t.version.equals(version),
          transaction: tx,
        );
        if (r == null) throw IngestException(message: '발행할 초안을 찾을 수 없습니다.');
        if (version > 1 && r.note.isEmpty) {
          throw IngestException(message: '이번 수정 내용을 적고 저장한 뒤 발행하세요.');
        }
        if (r.publishedAt == null) {
          await ResearchRevision.db.updateRow(
            session,
            r.copyWith(publishedAt: DateTime.now().toUtc()),
            transaction: tx,
          );
        }
      }
      a.publishedVersion = withdraw ? null : version;
      await ResearchArticle.db.updateRow(session, a, transaction: tx);
    });
  }

  Future<List<ResearchRevision>> editions(Session session, String slug) async {
    final a = await ResearchArticle.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(slug),
    );
    if (a?.publishedVersion == null) return [];
    final rows = await ResearchRevision.db.find(
      session,
      where: (t) => t.articleId.equals(a!.id!) & t.publishedAt.notEquals(null),
    );
    rows.sort((a, b) => b.version.compareTo(a.version));
    return rows
        .map((r) => r.copyWith(content: '', searchText: '', note: ''))
        .toList();
  }

  Future<List<ResearchRevision>> history(Session session, String slug) async {
    OntologyAccess.requireAdmin(session);
    final a = await ResearchArticle.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(slug),
    );
    if (a == null) return [];
    final rows = await ResearchRevision.db.find(
      session,
      where: (t) => t.articleId.equals(a.id!),
    );
    rows.sort((a, b) => b.version.compareTo(a.version));
    return rows.map((r) => r.copyWith(content: '', searchText: '')).toList();
  }

  Future<bool> bookmark(Session session, String slug, bool saved) async {
    final auth = session.authenticated;
    if (auth == null) {
      throw NotAuthorizedException(
        reason: AuthenticationFailureReason.unauthenticated,
      );
    }
    final a = await ResearchArticle.db.findFirstRow(
      session,
      where: (t) => t.slug.equals(slug),
    );
    if (a?.publishedVersion == null) {
      throw IngestException(message: '공개 리포트를 찾을 수 없습니다.');
    }
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'LOCK TABLE research_bookmark IN EXCLUSIVE MODE',
        transaction: tx,
      );
      final old = await ResearchBookmark.db.findFirstRow(
        session,
        where: (t) =>
            t.articleId.equals(a!.id!) & t.userId.equals(auth.userIdentifier),
        transaction: tx,
      );
      if (saved && old == null) {
        await ResearchBookmark.db.insertRow(
          session,
          ResearchBookmark(userId: auth.userIdentifier, articleId: a!.id!),
          transaction: tx,
        );
      }
      if (!saved && old != null) {
        await ResearchBookmark.db.deleteRow(session, old, transaction: tx);
      }
    });
    return saved;
  }

  /// Whether [r] was written by [importLegacy] rather than the editor.
  ///
  /// `legacy` alone is not enough: editor saves inherit it from the edition
  /// they revise, and an administrator may keep the imported note. Only the
  /// importer backdates publication to the source date, before the row
  /// existed; the editor publishes a saved row later, at the current time.
  static bool _importedEdition(ResearchRevision r) =>
      r.legacy &&
      r.publishedAt != null &&
      r.publishedAt == r.dataAsOf &&
      r.publishedAt!.isBefore(r.createdAt);

  /// Copies the local, hash-inventoried legacy corpus once; never overwrites edits.
  Future<int> importLegacy(Session session) async {
    OntologyAccess.requireAdmin(session);
    final rows = jsonDecode(
      await File('assets/research/legacy.json').readAsString(),
    ) as List;
    var count = 0;
    await session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'LOCK TABLE research_article IN EXCLUSIVE MODE',
        transaction: tx,
      );
      for (final raw in rows) {
        final m = raw as Map<String, dynamic>;
        final content = ResearchContent.render(m['content'] as String, 'html');
        final date = DateTime.parse('${m['dataAsOf']}T00:00:00Z');
        var a = await ResearchArticle.db.findFirstRow(
          session,
          where: (t) => t.slug.equals(m['slug'] as String),
          transaction: tx,
        );
        var version = 1;
        if (a != null) {
          final published = await ResearchRevision.db.findFirstRow(
            session,
            where: (t) =>
                t.articleId.equals(a!.id!) &
                t.version.equals(a.publishedVersion ?? -1),
            transaction: tx,
          );
          if (published != null &&
              published.legacy &&
              published.publishedAt == null) {
            await ResearchRevision.db.updateRow(
              session,
              published.copyWith(publishedAt: date),
              transaction: tx,
            );
          }
          // Repeatable rendering repair only for untouched imported editions.
          if (a.latestVersion != a.publishedVersion) continue;
          final previous = await ResearchRevision.db.findFirstRow(
            session,
            where: (t) =>
                t.articleId.equals(a!.id!) & t.version.equals(a.latestVersion),
            transaction: tx,
          );
          if (previous == null ||
              !_importedEdition(previous) ||
              previous.note != m['note'] ||
              (previous.content == content && previous.dataAsOf == date)) {
            continue;
          }
          version = a.latestVersion + 1;
          a = await ResearchArticle.db.updateRow(
            session,
            a.copyWith(latestVersion: version, publishedVersion: version),
            transaction: tx,
          );
        } else {
          a = await ResearchArticle.db.insertRow(
            session,
            ResearchArticle(
              slug: m['slug'] as String,
              latestVersion: 1,
              publishedVersion: 1,
            ),
            transaction: tx,
          );
        }
        await ResearchRevision.db.insertRow(
          session,
          ResearchRevision(
            articleId: a.id!,
            version: version,
            title: m['title'] as String,
            summary: m['summary'] as String,
            ticker: m['ticker'] as String,
            market: m['market'] as String,
            content: content,
            format: 'html',
            searchText: ResearchContent.text(content),
            dataAsOf: date,
            publishedAt: date,
            createdAt: DateTime.now().toUtc(),
            note: m['note'] as String,
            legacy: true,
          ),
          transaction: tx,
        );
        count++;
      }
    });
    return count;
  }
}
