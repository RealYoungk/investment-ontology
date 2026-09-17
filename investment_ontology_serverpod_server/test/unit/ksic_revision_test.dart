import 'dart:convert';
import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_revision.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ksic_seeder.dart';
import 'package:test/test.dart';

void main() {
  group('KSIC 자료 파일', () {
    // 통계청 고시 기준 분류 항목 수 (대/중/소/세/세세)
    const expected = {
      'KSIC 10': [21, 77, 232, 495, 1196],
      'KSIC 11': [21, 77, 234, 501, 1205],
    };

    for (final path in KsicSeeder.assetPaths) {
      test('$path: 항목 수와 계층이 고시와 맞다', () {
        final json =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final items = (json['items'] as List).cast<Map<String, dynamic>>();
        final counts = [
          for (var level = 1; level <= 5; level++)
            items.where((i) => i['level'] == level).length,
        ];
        expect(counts, expected[json['revision']]);

        final codes = {for (final i in items) i['code']};
        expect(codes.length, items.length, reason: '코드 중복 없음');
        for (final i in items) {
          final parent = i['parentCode'];
          if (parent != null) expect(codes, contains(parent));
        }
        expect(
          (json['source'] as Map)['url'],
          startsWith('https://mods.go.kr/'),
        );
      });
    }
  });

  group('KsicRevision.decide', () {
    final byRevision = {
      'KSIC 10': {'261', '264', '274', '108'},
      'KSIC 11': {'261', '264', '109', '108'},
    };

    test('한 차수에만 있는 코드가 쓰였으면 그 차수로 확정', () {
      final check = KsicRevision.decide({'261', '274'}, byRevision);
      expect(check.revision, 'KSIC 10');
      expect(check.evidenceCodes, ['274']);
      expect(check.unmatchedCodes, isEmpty);
      expect(check.confirmed, isTrue);

      final eleven = KsicRevision.decide({'264', '109'}, byRevision);
      expect(eleven.revision, 'KSIC 11');
      expect(eleven.confirmed, isTrue);
    });

    test('근거가 없으면 최신 차수를 쓰되 확정하지 않는다', () {
      final check = KsicRevision.decide({'261', '108'}, byRevision);
      expect(check.revision, 'KSIC 11');
      expect(check.confirmed, isFalse);
    });

    test('어느 차수에도 없는 코드는 unmatched로 보고', () {
      final check = KsicRevision.decide({'261', '109', '999'}, byRevision);
      expect(check.revision, 'KSIC 11');
      expect(check.unmatchedCodes, ['999']);
    });

    test('양쪽 근거가 섞이면 확정하지 않는다', () {
      final check = KsicRevision.decide({'274', '109'}, byRevision);
      expect(check.confirmed, isFalse);
      expect(check.unmatchedCodes, hasLength(1));
    });
  });
}
