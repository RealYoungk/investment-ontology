import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/data_sync/widgets/issuer_documents_status.dart';

List<Map<String, dynamic>> actualRows() =>
    ((jsonDecode(File('test/fixtures/issuer_documents.json').readAsStringSync())
                as Map)['documents']
            as List)
        .map((d) => Map<String, dynamic>.from(d['metadata'] as Map))
        .toList();
String ready(String corp, List<Map<String, dynamic>> rows) => jsonEncode({
  'state': 'ready',
  'source': {
    'kind': 'officialFile',
    'url': rows.isEmpty
        ? 'https://www.mkif.com'
        : Uri.parse(rows.first['officialUrl'] as String).origin,
  },
  'rows': rows,
});
Widget app(Widget child) => MaterialApp(
  theme: buildAppTheme(ledgerBrand),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
void main() {
  test('actual fifteen metadata rows preserve twelve annual and three latest documents', () {
    final rows = actualRows();
    expect(rows.length, 15);
    for (final corp in issuerDocumentFunds.keys) {
      final own = rows.where((r) => r['corpCode'] == corp).toList();
      expect(issuerDocumentRows(ready(corp, own), corp), own);
    }
  });
  test('owner, source, invalid dates, invented amounts and duplicate documents fail closed', () {
    final row = actualRows().first;
    for (final changes in [
      {'corpCode': '01880801'},
      {'periodStart': '2025-02-30'},
      {
        'financialValues': {'revenue': 1},
      },
      {'officialUrl': 'https://evil.example/a.pdf'},
      {'sha256': 'bad'},
    ]) {
      expect(
        () => issuerDocumentRows(
          ready('00435297', [
            {...row, ...changes},
          ]),
          '00435297',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => issuerDocumentRows(ready('00435297', [row, row]), '00435297'),
      throwsFormatException,
    );
    expect(
      () => issuerDocumentRows(
        jsonEncode({
          'state': 'ready',
          'rows': [row],
          'source': {'kind': 'manual', 'url': 'https://www.mkif.com'},
        }),
        '00435297',
      ),
      throwsFormatException,
    );
  });
  testWidgets(
    '320px shows honest independent counts and missing historical years',
    (t) async {
      t.view.physicalSize = const Size(320, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final rows = actualRows();
      final version = ValueNotifier(0);
      addTearDown(version.dispose);
      await t.pumpWidget(
        app(
          IssuerDocumentsStatus(
            dataVersion: version,
            load: (corp) async =>
                ready(corp, rows.where((r) => r['corpCode'] == corp).toList()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('서버 보존: 연간 12/15 · 최신 3/3'), findsOneWidget);
      expect(find.textContaining('2021~2023 원문 미확보'), findsOneWidget);
      await t.tap(find.text('맥쿼리인프라'));
      await t.pumpAndSettle();
      expect(find.text('2025-01-01 ~ 2025-12-31'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'empty, not collected and errors remain distinct; stale reload is discarded',
    (t) async {
      final version = ValueNotifier(0);
      addTearDown(version.dispose);
      final old = <String, Completer<String>>{};
      var first = true;
      await t.pumpWidget(
        app(
          IssuerDocumentsStatus(
            dataVersion: version,
            load: (corp) {
              if (first) {
                return (old[corp] = Completer<String>()).future;
              }
              if (corp == '00435297') return Future.value(ready(corp, []));
              if (corp == '01880801') {
                return Future.value('{"state":"notCollected","rows":[]}');
              }
              return Future.error(StateError('offline'));
            },
          ),
        ),
      );
      first = false;
      version.value++;
      await t.pumpAndSettle();
      expect(find.text('저장된 문서 없음'), findsOneWidget);
      expect(find.text('서버 수집 전'), findsOneWidget);
      expect(find.text('원문 상태 확인 실패'), findsOneWidget);
      for (final entry in old.entries) {
        entry.value.complete(
          ready(
            entry.key,
            actualRows().where((r) => r['corpCode'] == entry.key).toList(),
          ),
        );
      }
      await t.pumpAndSettle();
      expect(find.text('서버 보존: 연간 0/15 · 최신 0/3'), findsOneWidget);
    },
  );
}
