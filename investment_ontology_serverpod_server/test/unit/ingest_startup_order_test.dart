import 'dart:io';

import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_hooks.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/ingest_schedule.dart';
import 'package:test/test.dart';

void main() {
  group('Given 서버 시작 순서', () {
    test('when server.dart를 읽으면 then 수집 예약 함수를 pod.start() 전에 넣는다', () {
      // pod.start()가 FutureCall 실행을 시작한다. 끊겼다 다시 실행되는 수집이 그때 이미
      // 이어받기 예약 함수를 볼 수 있어야 한다.
      final source = File('lib/server.dart').readAsStringSync();
      final install = source.indexOf('IngestSchedule.installHooks();');
      final start = source.indexOf('await pod.start();');

      expect(install, isNonNegative, reason: 'installHooks 호출이 있어야 한다');
      expect(start, isNonNegative);
      expect(install, lessThan(start));
    });

    test('when installHooks를 부르면 then 모든 예약 함수가 채워진다', () {
      IngestSchedule.installHooks();

      expect(IngestHooks.companyMasterNow, isNotNull);
      expect(IngestHooks.financialsNow, isNotNull);
      expect(IngestHooks.financialsForCompanyNow, isNotNull);
      expect(IngestHooks.financialsResume, isNotNull);
      expect(IngestHooks.marketSnapshotNow, isNotNull);
      expect(IngestHooks.marketSnapshotResume, isNotNull);
      expect(IngestHooks.disclosuresNow, isNotNull);
      expect(IngestHooks.disclosuresForCompanyNow, isNotNull);
      expect(IngestHooks.disclosures, isNotNull);
      expect(IngestHooks.aiExtractionNow, isNotNull);
    });
  });
}
