import 'dart:async';

import 'package:shad/shad.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/screen/compare_company_search.dart';

import 'package:investment_ontology_serverpod_flutter/features/screen/compare_page.dart';

import '../support/shad_test_host.dart';

void main() {
  Future<void> host(
    WidgetTester tester,
    Future<List<CompanyListItem>> Function(String) search, {
    List<String> selected = const [],
    ValueChanged<String>? add,
    ValueChanged<String>? remove,
  }) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(researchDeskBrand),
          home: Scaffold(
            body: CompareCompanySearch(
              selectedCodes: selected,
              onAdd: add ?? (_) {},
              onRemove: remove ?? (_) {},
              search: search,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('first selection and last removal preserve search state', (
    tester,
  ) async {
    Future<void> page(List<String> codes) => tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(researchDeskBrand),
          home: Scaffold(body: ComparePage(corpCodes: codes)),
        ),
      ),
    );
    await page([]);
    await tester.enterText(find.byType(EditableText), '삼성');
    await tester.pump();
    final controller = tester
        .widget<EditableText>(find.byType(EditableText))
        .controller;
    await page(['00126380']);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller,
      same(controller),
    );
    expect(controller.text, '삼성');
    await page([]);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller,
      same(controller),
    );
    expect(controller.text, '삼성');
    await tester.tap(find.bySemanticsLabel('검색어 지우기'));
    await tester.pump();
  });
  testWidgets(
    'loading is immediate, stale results cannot replace latest query, clear cancels pending',
    (tester) async {
      final first = Completer<List<CompanyListItem>>();
      final second = Completer<List<CompanyListItem>>();
      await host(tester, (q) => q == '삼성' ? first.future : second.future);
      final emptyInputRect = tester.getRect(find.byType(ShadInput));
      expect(emptyInputRect.height, 48);
      await tester.enterText(find.byType(EditableText), '삼성');
      await tester.pump();
      expect(find.text('검색 중…'), findsOneWidget);
      expect(tester.getRect(find.byType(ShadInput)), emptyInputRect);
      await tester.pump(const Duration(milliseconds: 251));
      await tester.enterText(find.byType(EditableText), '기아');
      await tester.pump(const Duration(milliseconds: 251));
      second.complete([CompanyListItem(corpCode: '2', name: '기아')]);
      await tester.pump();
      await tester.pump();
      expect(find.text('기아'), findsWidgets);
      first.complete([CompanyListItem(corpCode: '1', name: '옛 결과')]);
      await tester.pump();
      expect(find.text('옛 결과'), findsNothing);
      await tester.enterText(find.byType(EditableText), '다음');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('검색어 지우기'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('검색 중…'), findsNothing);
      expect(tester.getRect(find.byType(ShadInput)), emptyInputRect);
      expect(find.text('검색 결과가 없습니다.'), findsNothing);
    },
  );
  testWidgets('failure retry and empty response are different states', (
    tester,
  ) async {
    var calls = 0;
    await host(tester, (_) async {
      if (++calls == 1) throw StateError('offline');
      return [];
    });
    await tester.enterText(find.byType(EditableText), '삼성');
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pump();
    expect(find.text('검색 결과가 없습니다.'), findsNothing);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pump();
    await tester.pump();
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    expect(calls, 2);
  });
  testWidgets(
    '320px checkbox selection keeps results, supports removal and enforces four limit',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? added;
      String? removed;
      Future<List<CompanyListItem>> search(String _) async => [
        CompanyListItem(corpCode: '1', name: '이미 담긴 기업'),
        CompanyListItem(
          corpCode: '2',
          name: '매우 긴 이름의 비교 대상 기업',
          stockCode: '000002',
        ),
        CompanyListItem(
          corpCode: '5',
          name: '아직 담지 않은 기업',
          stockCode: '000005',
        ),
      ];
      await host(
        tester,
        search,
        selected: ['1'],
        add: (c) => added = c,
        remove: (c) => removed = c,
      );
      await tester.enterText(find.byType(EditableText), '기업');
      await tester.pump(const Duration(milliseconds: 251));
      await tester.pump();
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox).at(0)).value,
        isTrue,
      );
      await tester.tap(find.byType(ShadCheckbox).at(1));
      await tester.pump();
      expect(added, '2');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '기업',
      );
      expect(find.text('매우 긴 이름의 비교 대상 기업'), findsOneWidget);
      await host(
        tester,
        search,
        selected: ['1', '2', '3', '4'],
        remove: (c) => removed = c,
      );
      await tester.pump();
      expect(tester.widget<ShadInput>(find.byType(ShadInput)).enabled, isTrue);
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox).at(2)).enabled,
        isFalse,
      );
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox).at(1)).enabled,
        isTrue,
      );
      await tester.tap(find.byType(ShadCheckbox).at(1));
      await tester.pump();
      expect(removed, '2');
      await host(tester, search, selected: ['1', '3', '4']);
      await tester.pump();
      expect(
        tester.widget<ShadCheckbox>(find.byType(ShadCheckbox).at(2)).enabled,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
