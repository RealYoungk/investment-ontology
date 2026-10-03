import 'support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/app_data_table.dart';

/// 표가 주어진 폭을 채우되, 내용 열은 제 폭을 지키고 남는 폭만 flex 열이 가져가는지.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double width = 760}) {
    return tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(ledgerBrand),
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Column(children: [child]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('flex 열이 남는 폭을 가져가고 다른 열은 한 줄로 남는다', (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => AppDataTable(
          columns: const [
            AppColumn('가진 쪽', nowrap: true),
            AppColumn('가진 기업', nowrap: true),
            AppColumn('지분율', numeric: true),
            AppColumn('근거', flex: true),
          ],
          rows: [
            for (var i = 0; i < 3; i++)
              AppRow([
                AppDataTable.text(context, '삼성생명보험(주)'),
                AppDataTable.text(context, '삼성카드(주)'),
                AppDataTable.text(context, '71.86%', numeric: true),
                AppDataTable.text(context, '최대주주 명단 · FY2025'),
              ]),
          ],
        ),
      ),
    );
    final table = tester.renderObject<RenderTable>(find.byType(Table));
    expect(table.size.width, 760);
    final name = tester.getSize(find.text('삼성생명보험(주)').first);
    final evidence = tester.getSize(
      find
          .ancestor(
            of: find.text('최대주주 명단 · FY2025').first,
            matching: find.byType(Container),
          )
          .first,
    );
    final rel = tester.getSize(
      find
          .ancestor(
            of: find.text('삼성카드(주)').first,
            matching: find.byType(Container),
          )
          .first,
    );
    // ignore: avoid_print
    print(
      'name=${name.width}x${name.height} card=${rel.width} evidence=${evidence.width}',
    );
    // 이름은 한 줄 (Ahem 글꼴 14px × 9자 = 126), 근거가 남는 폭을 가진다.
    expect(name.height, lessThan(30), reason: '이름 열이 두 줄로 접히면 안 된다');
    expect(evidence.width, greaterThan(300));
  });

  testWidgets('내용이 폭보다 넓으면 표가 폭을 넘고 (가로 스크롤), 열은 제 폭을 지킨다', (
    tester,
  ) async {
    await pump(
      tester,
      Builder(
        builder: (context) => AppDataTable(
          columns: [
            const AppColumn('기업', nowrap: true),
            for (var i = 0; i < 8; i++) const AppColumn('값', numeric: true),
          ],
          rows: [
            AppRow([
              AppDataTable.text(context, '에스케이스퀘어 주식회사'),
              for (var i = 0; i < 8; i++)
                AppDataTable.text(context, '1,234,567', numeric: true),
            ]),
          ],
        ),
      ),
      width: 400,
    );
    final table = tester.renderObject<RenderTable>(find.byType(Table));
    expect(table.size.width, greaterThan(400));
    final name = tester.getSize(find.text('에스케이스퀘어 주식회사'));
    expect(name.height, lessThan(30));
  });
  testWidgets('긴 원문은 가변 행으로 남고 결측값과 숫자는 의미를 유지한다', (tester) async {
    final evidence = '원문 근거: 연결 재무제표에 표시된 기간과 단위를 함께 확인합니다. ' * 4;
    await pump(
      tester,
      Builder(
        builder: (context) => AppDataTable(
          columns: const [
            AppColumn('기간', nowrap: true),
            AppColumn('값', numeric: true),
            AppColumn('근거', flex: true),
          ],
          rows: [
            AppRow([
              AppDataTable.text(context, '2025'),
              AppDataTable.text(context, '1,234,567', numeric: true),
              AppDataTable.text(context, evidence),
            ]),
            AppRow([
              AppDataTable.text(context, '2026'),
              AppDataTable.text(context, null, numeric: true),
              AppDataTable.text(context, '미확보'),
            ]),
          ],
        ),
      ),
      width: 390,
    );
    final original = tester.widget<Text>(find.text(evidence));
    expect(original.maxLines, isNull);
    expect(tester.getSize(find.text(evidence)).height, greaterThan(48));
    expect(find.text('—'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('1,234,567')).textAlign,
      TextAlign.right,
    );
    expect(tester.takeException(), isNull);
  });
}
