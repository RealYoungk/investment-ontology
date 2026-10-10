import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/client.dart' as app;
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/account_page.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/app_viewer.dart';
import 'package:shad/shad.dart';

import '../support/shad_test_host.dart';

class Accounts implements EndpointAccount {
  int mailCalls = 0;
  int listCalls = 0;
  bool fail = false;
  @override
  Future<bool> mailConfigured() async {
    mailCalls++;
    return false;
  }

  @override
  Future<List<AccountView>> list({required int offset}) async {
    listCalls++;
    if (fail) throw StateError('fixture');
    return [
      AccountView(
        userId: 'self',
        email: 'admin@example.com',
        createdAt: DateTime(2026),
        isAdmin: true,
        blocked: false,
      ),
      AccountView(
        userId: 'reader',
        email: 'reader@example.com',
        createdAt: DateTime(2026),
        isAdmin: false,
        blocked: true,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FixtureClient implements Client {
  @override
  final Accounts account = Accounts();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final fixture = FixtureClient();
  setUpAll(() => app.client = fixture);
  Future<void> pump(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(researchDeskBrand),
          home: const AppViewerScope(
            viewer: AppViewer(userId: 'self', isAdmin: true),
            child: Scaffold(body: AccountPage(manage: true)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 1440.0]) {
    testWidgets(
      'member search preserves self protection and cached mail at $width',
      (tester) async {
        fixture.account.fail = false;
        final mailBefore = fixture.account.mailCalls;
        await pump(tester, width);
        expect(find.text('admin@example.com'), findsOneWidget);
        expect(find.text('reader@example.com'), findsOneWidget);
        expect(find.text('현재 내 계정'), findsOneWidget);
        expect(find.text('이용 정지'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.descendant(
            of: find.byType(ShadInput),
            matching: find.byType(EditableText),
          ),
          'reader',
        );
        await tester.pumpAndSettle();
        expect(find.text('admin@example.com'), findsNothing);
        expect(find.text('reader@example.com'), findsOneWidget);
        expect(fixture.account.mailCalls, mailBefore + 1);
        await tester.tap(find.text('관리자로 변경'));
        await tester.pumpAndSettle();
        expect(find.text('관리자 권한 부여'), findsOneWidget);
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(ShadInput),
            matching: find.byType(EditableText),
          ),
          'absent',
        );
        await tester.pumpAndSettle();
        expect(find.text('현재 페이지에 검색 결과가 없습니다.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('failed member request offers retry and recovers', (
    tester,
  ) async {
    fixture.account.fail = true;
    await pump(tester, 1440);
    expect(find.text('계정 정보를 불러오지 못했습니다.'), findsOneWidget);
    fixture.account.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('reader@example.com'), findsOneWidget);
    expect(find.byType(ShadInput), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
