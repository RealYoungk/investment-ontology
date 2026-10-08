import 'package:flutter/material.dart';

import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/company_detail/widgets/business_structure.dart';

BusinessContent content(String text) => BusinessContent(
  bsnsYear: 2026,
  rceptNo: 'test',
  title: '반기보고서',
  sections: [BusinessSection(title: '사업의 개요', text: text)],
  charCount: text.length,
  years: [2026],
);
void main() {
  for (final width in [320.0, 913.0]) {
    testWidgets('roles and evidence expand without overflow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = content(
        '사업부문 | 해당 연결회사 | 주요 제품 및 제공 용역\n반도체 | 회사A | 고유 제조 역할\n회사B | 고유 세정 역할',
      );
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(ledgerBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: BusinessStructureOverview(
                  items: businessStructureItems(source),
                  content: source,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('+ 담당 회사·제공 사업'));
      await tester.pumpAndSettle();
      expect(find.text('회사B'), findsOneWidget);
      await tester.tap(find.text('+ 원문 근거'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'continuations retain segment and exact company-service association',
    () {
      final items = businessStructureItems(
        content(
          '사업부문 | 해당 연결회사 | 주요 제품 및 제공 용역\n반도체 | 미코 | 부품 제작\n코미코 | 세정 및 코팅\n에너지&환경(Energy&Environment) | 미코파워 | SOFC\n\n사업부문 | 품목 | 구체적 용도\n에너지&환경 | 연료전지 | 발전용',
        ),
      );
      expect(items.length, 2);
      expect(items.first.providers, [
        (company: '미코', service: '부품 제작'),
        (company: '코미코', service: '세정 및 코팅'),
      ]);
      expect(items.last.products, ['연료전지']);
      expect(items.last.uses, ['발전용']);
    },
  );
  test('two-level year headers preserve product and use columns', () {
    final items = businessStructureItems(
      content(
        '사업부문 | 매출유형 | 품목 | 구체적 용도 | 2026 | 2025\n매출액 | 비율 | 매출액 | 비율\n반도체 | 제품 | ESC | 공정 부품 | 100 | 50% | 200 | 60%',
      ),
    );
    expect(items.single.products, ['ESC']);
    expect(items.single.uses, ['공정 부품']);
  });
  test('financial tables and prose do not fabricate business structure', () {
    expect(
      businessStructureItems(
        content('사업부문 | 매출액 | 비율\n반도체 | 123 | 50%\n\n당사는 반도체를 제조합니다.'),
      ),
      isEmpty,
    );
  });
  test('repeated service does not lose company association', () {
    final items = businessStructureItems(
      content('사업부문 | 해당 연결회사 | 주요 제품 및 제공 용역\n반도체 | A | 제조\nB | 제조\nC | 세정'),
    );
    expect(items.single.providers.last, (company: 'C', service: '세정'));
    expect(items.single.providers.length, 3);
  });
}
