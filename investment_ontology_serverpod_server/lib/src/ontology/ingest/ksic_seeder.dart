import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// 통계청 한국표준산업분류(KSIC) 고시 자료를 industry 테이블에 반영한다.
///
/// `assets/ksic/`의 JSON은 `tool/ksic/`의 스크립트로 통계청(현 국가데이터처)
/// 고시 첨부 파일에서 추출한 것이다. 개정 차수마다 따로 저장한다.
class KsicSeeder {
  static const assetPaths = [
    'assets/ksic/ksic_10.json',
    'assets/ksic/ksic_11.json',
  ];

  /// 새로 넣거나 바뀐 항목 수.
  static Future<int> seed(Session session) async {
    var changed = 0;
    for (final path in assetPaths) {
      changed += await _seedFile(session, path);
    }
    return changed;
  }

  static Future<int> _seedFile(Session session, String path) async {
    final json =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    final revision = json['revision'] as String;
    final meta = json['source'] as Map<String, dynamic>;
    final items = (json['items'] as List).cast<Map<String, dynamic>>();

    final existing = {
      for (final i in await Industry.db.find(
        session,
        where: (t) => t.revision.equals(revision),
      ))
        i.code: i,
    };

    return session.db.transaction((tx) async {
      final source = await _source(session, revision, meta, tx);
      final toInsert = <Industry>[];
      final toUpdate = <Industry>[];
      for (final item in items) {
        final next = Industry(
          code: item['code'] as String,
          name: item['name'] as String,
          level: item['level'] as int,
          parentCode: item['parentCode'] as String?,
          revision: revision,
          sourceId: source.id,
        );
        final current = existing[next.code];
        if (current == null) {
          toInsert.add(next);
        } else if (current.name != next.name ||
            current.level != next.level ||
            current.parentCode != next.parentCode ||
            current.sourceId != next.sourceId) {
          toUpdate.add(next.copyWith(id: current.id));
        }
      }
      if (toInsert.isNotEmpty) {
        await Industry.db.insert(session, toInsert, transaction: tx);
      }
      if (toUpdate.isNotEmpty) {
        await Industry.db.update(session, toUpdate, transaction: tx);
      }
      return toInsert.length + toUpdate.length;
    });
  }

  /// 차수별 고시 자료 출처. 같은 차수·URL이면 재사용한다.
  static Future<Source> _source(
    Session session,
    String revision,
    Map<String, dynamic> meta,
    Transaction tx,
  ) async {
    final url = meta['url'] as String;
    final found = await Source.db.findFirstRow(
      session,
      where: (t) =>
          t.kind.equals(SourceKind.officialFile) &
          t.reference.equals(revision) &
          t.url.equals(url),
      transaction: tx,
    );
    if (found != null) return found;
    return Source.db.insertRow(
      session,
      Source(
        kind: SourceKind.officialFile,
        title: meta['title'] as String,
        reference: revision,
        url: url,
        retrievedAt: DateTime.now().toUtc(),
      ),
      transaction: tx,
    );
  }

  /// KSIC 코드에서 중분류(2자리)와 대분류(A~U)를 구한다.
  ///
  /// 대분류별 중분류 범위는 제10차·제11차가 같다.
  static ({String? division, String? section}) classify(String? code) {
    if (code == null || code.length < 2) return (division: null, section: null);
    final division = code.substring(0, 2);
    final d = int.tryParse(division);
    if (d == null) return (division: null, section: null);
    for (final (section, lo, hi) in _sections) {
      if (d >= lo && d <= hi) return (division: division, section: section);
    }
    return (division: division, section: null);
  }

  static const _sections = [
    ('A', 1, 3),
    ('B', 5, 8),
    ('C', 10, 34),
    ('D', 35, 35),
    ('E', 36, 39),
    ('F', 41, 42),
    ('G', 45, 47),
    ('H', 49, 52),
    ('I', 55, 56),
    ('J', 58, 63),
    ('K', 64, 66),
    ('L', 68, 68),
    ('M', 70, 73),
    ('N', 74, 76),
    ('O', 84, 84),
    ('P', 85, 85),
    ('Q', 86, 87),
    ('R', 90, 91),
    ('S', 94, 96),
    ('T', 97, 98),
    ('U', 99, 99),
  ];
}
