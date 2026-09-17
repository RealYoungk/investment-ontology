import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// `assets/ksic/ksic_10.json`(통계청 KSIC 10차)을 industry 테이블에 반영한다.
class KsicSeeder {
  static const assetPath = 'assets/ksic/ksic_10.json';

  /// 새로 넣거나 바뀐 항목 수.
  static Future<int> seed(Session session) async {
    final json =
        jsonDecode(await File(assetPath).readAsString())
            as Map<String, dynamic>;
    final revision = json['revision'] as String;
    final items = (json['items'] as List).cast<Map<String, dynamic>>();

    final existing = {
      for (final i in await Industry.db.find(session)) i.code: i,
    };
    final toInsert = <Industry>[];
    final toUpdate = <Industry>[];
    for (final item in items) {
      final next = Industry(
        code: item['code'] as String,
        name: item['name'] as String,
        level: item['level'] as int,
        parentCode: item['parentCode'] as String?,
        revision: revision,
      );
      final current = existing[next.code];
      if (current == null) {
        toInsert.add(next);
      } else if (current.name != next.name ||
          current.level != next.level ||
          current.parentCode != next.parentCode ||
          current.revision != next.revision) {
        toUpdate.add(next.copyWith(id: current.id));
      }
    }
    await session.db.transaction((tx) async {
      if (toInsert.isNotEmpty) {
        await Industry.db.insert(session, toInsert, transaction: tx);
      }
      if (toUpdate.isNotEmpty) {
        await Industry.db.update(session, toUpdate, transaction: tx);
      }
    });
    return toInsert.length + toUpdate.length;
  }

  /// KSIC 코드에서 중분류(2자리)와 대분류(A~U)를 구한다.
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
