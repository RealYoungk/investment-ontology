import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../auth/ontology_access.dart';
import '../billing/membership_ledger.dart';
import '../watchlist/watchlist_service.dart';
import 'investment_note_content.dart';

abstract final class InvestmentNotes {
  static Future<Map<String, dynamic>> importDraft(
    Session session,
    String payload, {
    int? articleId,
  }) async {
    OntologyAccess.requireAdmin(session);
    final content = InvestmentNoteContent.parse(payload);
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(content['corpCode'] as String),
    );
    if (company == null) throw const FormatException('등록된 기업을 찾을 수 없습니다.');
    return session.db.transaction((tx) async {
      final previousId = content['previousArticleId'] as int?;
      if (previousId != null) {
        final previous = await ResearchArticle.db.findById(
          session,
          previousId,
          transaction: tx,
        );
        if (previous?.publishedVersion == null || previousId == articleId) {
          throw const FormatException('공개된 다른 글을 후속 글의 원글로 지정하세요.');
        }
        final rev = await ResearchRevision.db.findFirstRow(
          session,
          where: (t) =>
              t.articleId.equals(previousId) &
              t.version.equals(previous!.publishedVersion!),
          transaction: tx,
        );
        if (rev?.format != InvestmentNoteContent.format ||
            InvestmentNoteContent.parse(rev!.content)['corpCode'] !=
                content['corpCode']) {
          throw const FormatException('같은 기업의 공개 글에만 연결할 수 있습니다.');
        }
      }
      ResearchArticle? article;
      if (articleId != null) {
        article = await ResearchArticle.db.findById(
          session,
          articleId,
          transaction: tx,
          lockMode: LockMode.forUpdate,
        );
        if (article == null || article.publishedVersion != null) {
          throw const FormatException('공개 글은 수정할 수 없습니다. 새 후속 글을 작성하세요.');
        }
        final old = await ResearchRevision.db.findFirstRow(
          session,
          where: (t) =>
              t.articleId.equals(articleId) &
              t.version.equals(article!.latestVersion),
          transaction: tx,
        );
        if (old?.format != InvestmentNoteContent.format) {
          throw const FormatException('다른 리서치 콘텐츠는 수정할 수 없습니다.');
        }
      } else {
        article = await ResearchArticle.db.insertRow(
          session,
          ResearchArticle(slug: 'note-${const Uuid().v4()}', latestVersion: 0),
          transaction: tx,
        );
      }
      final version = article.latestVersion + 1;
      final encoded = jsonEncode(content);
      await ResearchRevision.db.insertRow(
        session,
        ResearchRevision(
          articleId: article.id!,
          version: version,
          title: content['title'] as String,
          summary: content['introduction'] as String,
          ticker: company.stockCode ?? '',
          market: company.market?.name ?? 'unknown',
          content: encoded,
          format: InvestmentNoteContent.format,
          // Not indexed as public search content.
          searchText: '',
          dataAsOf: DateTime.parse(content['dataAsOf'] as String),
          createdAt: DateTime.now().toUtc(),
          legacy: false,
          note: jsonEncode({
            'importedBy': session.authenticated!.userIdentifier,
          }),
        ),
        transaction: tx,
      );
      await ResearchArticle.db.updateRow(
        session,
        article.copyWith(latestVersion: version),
        transaction: tx,
      );
      return {
        'id': article.id,
        'version': version,
        'digest': InvestmentNoteContent.digest(article.id!, version, encoded),
        'content': content,
        'state': 'draft',
      };
    });
  }

  static Future<Map<String, dynamic>> preview(Session session, int id) async {
    OntologyAccess.requireAdmin(session);
    final article = await ResearchArticle.db.findById(session, id);
    if (article == null) throw const FormatException('글을 찾을 수 없습니다.');
    final rev = await ResearchRevision.db.findFirstRow(
      session,
      where: (t) =>
          t.articleId.equals(id) & t.version.equals(article.latestVersion),
    );
    if (rev?.format != InvestmentNoteContent.format) {
      throw const FormatException('글을 찾을 수 없습니다.');
    }
    return {
      'id': id,
      'version': rev!.version,
      'digest': InvestmentNoteContent.digest(id, rev.version, rev.content),
      'state': article.publishedVersion == null ? 'draft' : 'published',
      'content': InvestmentNoteContent.parse(rev.content),
    };
  }

  static Future<void> publish(
    Session session,
    int id,
    String approvedDigest,
  ) async {
    OntologyAccess.requireAdmin(session);
    await session.db.transaction((tx) async {
      final article = await ResearchArticle.db.findById(
        session,
        id,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (article == null) throw const FormatException('글을 찾을 수 없습니다.');
      final rev = await ResearchRevision.db.findFirstRow(
        session,
        where: (t) =>
            t.articleId.equals(id) & t.version.equals(article.latestVersion),
        transaction: tx,
      );
      if (rev?.format != InvestmentNoteContent.format ||
          InvestmentNoteContent.digest(id, rev!.version, rev.content) !=
              approvedDigest) {
        throw const FormatException('확인한 초안과 현재 초안이 다릅니다. 다시 확인하세요.');
      }
      if (article.publishedVersion != null) return;
      final now = DateTime.now().toUtc();
      final data = InvestmentNoteContent.parse(rev.content);
      final event = await CompanyUpdateEvent.db.insertRow(
        session,
        CompanyUpdateEvent(
          corpCode: data['corpCode'] as String,
          receipt: 'investment-note-$id',
          title: '작성자 투자 관점 업데이트',
          url: 'https://alfinder.kr/insights/$id',
          publishedAt: now,
          discoveredAt: now,
        ),
        transaction: tx,
      );
      for (final entry in await WatchlistService.activeEntries(session)) {
        if (entry.corpCode != data['corpCode']) continue;
        final notice = await WatchlistNotice.db.insertRow(
          session,
          WatchlistNotice(
            ownerId: entry.ownerId,
            eventId: event.id!,
            corpCode: entry.corpCode,
            createdAt: now,
          ),
          transaction: tx,
        );
        if (entry.muted) continue;
        final devices = await WebPushSubscription.db.find(
          session,
          where: (t) => t.ownerId.equals(entry.ownerId),
          transaction: tx,
        );
        for (final device in devices) {
          await WebPushDelivery.db.insertRow(
            session,
            WebPushDelivery(noticeId: notice.id!, subscriptionId: device.id!),
            transaction: tx,
          );
        }
      }
      await ResearchRevision.db.updateRow(
        session,
        rev.copyWith(
          publishedAt: now,
          note: jsonEncode({
            'approvedBy': session.authenticated!.userIdentifier,
            'approvedDigest': approvedDigest,
            'approvedAt': now.toIso8601String(),
          }),
        ),
        transaction: tx,
      );
      await ResearchArticle.db.updateRow(
        session,
        article.copyWith(publishedVersion: rev.version),
        transaction: tx,
      );
    });
  }

  static Future<bool> _member(Session session) async {
    if (OntologyAccess.isAdmin(session.authenticated)) return true;
    if (session.authenticated == null) return false;
    return (await MembershipLedger.status(session)).adFree;
  }

  static Future<List<Map<String, dynamic>>> list(
    Session session, {
    String? corpCode,
    int offset = 0,
  }) async {
    if (corpCode != null && !RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw const FormatException('기업코드 오류');
    }
    if (offset < 0 || offset > 10000) throw const FormatException('조회 범위 오류');
    final member = await _member(session);
    // Published notes only; keep article/version pointer authoritative.
    final rows = await ResearchRevision.db.find(
      session,
      where: (t) =>
          t.format.equals(InvestmentNoteContent.format) &
          t.publishedAt.notEquals(null),
      orderByList: (t) => [t.publishedAt.desc(), t.id.desc()],
      limit: 1000,
    );
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final data = InvestmentNoteContent.parse(row.content);
      if (corpCode != null && data['corpCode'] != corpCode) continue;
      final article = await ResearchArticle.db.findById(session, row.articleId);
      if (article?.publishedVersion != row.version) continue;
      final company = await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals(data['corpCode'] as String),
      );
      final view = InvestmentNoteContent.readerView(
        data,
        member: member,
        id: row.articleId,
        publishedAt: row.publishedAt!,
        companyName: company?.name ?? '기업',
      );
      // Lists never include member bodies, even for entitled readers.
      view.remove('sections');
      view.remove('sources');
      result.add(view);
    }
    return result.skip(offset).take(30).toList();
  }

  static Future<Map<String, dynamic>?> detail(Session session, int id) async {
    final article = await ResearchArticle.db.findById(session, id);
    if (article?.publishedVersion == null) return null;
    final row = await ResearchRevision.db.findFirstRow(
      session,
      where: (t) =>
          t.articleId.equals(id) & t.version.equals(article!.publishedVersion!),
    );
    if (row?.format != InvestmentNoteContent.format ||
        row?.publishedAt == null) {
      return null;
    }
    final data = InvestmentNoteContent.parse(row!.content);
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(data['corpCode'] as String),
    );
    return InvestmentNoteContent.readerView(
      data,
      member: await _member(session),
      id: id,
      publishedAt: row.publishedAt!,
      companyName: company?.name ?? '기업',
    );
  }
}
