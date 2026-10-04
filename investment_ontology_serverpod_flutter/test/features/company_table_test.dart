import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/features/companies/widgets/company_table.dart';

import '../support/shad_test_host.dart';

import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('기업 목록 배치와 상세·페이지 이동 $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? selected;
      int? offset;
      CompanySort? sort;
      await tester.pumpWidget(
        shadTestHost(
          MaterialApp(
            theme: buildAppTheme(researchDeskBrand),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CompanyTable(
                    page: CompanyPage(
                      total: 51,
                      items: [
                        CompanyListItem(
                          corpCode: '00126380',
                          name: '삼성전자',
                          stockCode: '005930',
                          market: Market.kospi,
                        ),
                      ],
                    ),
                    loading: false,
                    compact: width < 980,
                    selected: null,
                    sort: CompanySort.marketCap,
                    onSort: (value) => sort = value,
                    offset: 0,
                    pageSize: 20,
                    onSelect: (value) => selected = value,
                    onPage: (value) => offset = value,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('삼성전자'), findsOneWidget);
      await tester.tap(find.text('삼성전자'));
      expect(selected, '00126380');
      await tester.tap(find.text('회사명'));
      expect(sort, CompanySort.name);
      await tester.tap(find.text('다음'));
      expect(offset, 20);
      expect(tester.takeException(), isNull);
    });
  }
}
