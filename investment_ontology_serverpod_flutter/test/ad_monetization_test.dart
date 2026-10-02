import 'package:flutter/material.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/ad_content_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/ad_config.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/ad_banner.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/membership_card.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/app_viewer.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/page_frame.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';

AppBrand _brand() => AppBrand(
  colors: const AppColors(
    background: Color(0xFFF2EDE2),
    surface: Color(0xFFFAF7F0),
    surfaceHover: Color(0xFFE8E0D0),
    inverse: Color(0xFF17140F),
    onInverse: Color(0xFFF2EDE2),
    textPrimary: Color(0xFF17140F),
    textSecondary: Color(0xFF5C554A),
    textMuted: Color(0xFF9A9183),
    border: Color(0xFFCFC5B3),
    borderStrong: Color(0xFF17140F),
    accent: Color(0xFFC8401A),
    accentSubtle: Color(0xFFF3D9CC),
    onAccent: Color(0xFFF2EDE2),
    success: Color(0xFF3F6B4E),
    marketUp: Color(0xFFB83232),
    marketDown: Color(0xFF2463AD),
    marketKospi: Color(0xFF17140F),
    marketKosdaq: Color(0xFFC8401A),
    marketKonex: Color(0xFF8A7B5E),
    chartSeries1: Color(0xFF2F6DA8),
    chartSeries2: Color(0xFFC8401A),
    chartGrid: Color(0xFFE3DCCD),
    chartTile: Color(0xFFDCE5EE),
    chartTileHover: Color(0xFFBFD1E3),
  ),
  typography: const AppTypography(
    displayBase: TextStyle(),
    bodyBase: TextStyle(),
    numericBase: TextStyle(),
    labelBase: TextStyle(fontSize: 10),
  ),
  shape: const AppShape(radius: 0, strokeWidth: 1.2),
);

void main() {
  const preview = AdConfig(preview: true);
  final slot = find.byKey(const ValueKey('ad-placement-slot'));
  Widget app({
    AppViewer? viewer,
    AdConfig config = preview,
    double scale = 1,
    bool allowLeading = true,
  }) => MaterialApp(
    theme: buildAppTheme(_brand()),
    home: AppViewerScope(
      viewer: viewer,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: PageFrameLeadScope(
            leading: AdBanner(config: config),
            child: PageFrame(
              allowLeading: allowLeading,
              children: [
                const MembershipCard(),
                for (var i = 0; i < 30; i++)
                  SizedBox(height: 80, child: Text('Company $i')),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  testWidgets('content loading, empty and errors never mount an ad slot', (
    tester,
  ) async {
    for (final state in [
      const AdContentState(loading: true, failed: false, itemCount: 0),
      const AdContentState(loading: true, failed: false, itemCount: 50),
      const AdContentState(loading: false, failed: false, itemCount: 0),
      const AdContentState(loading: false, failed: true, itemCount: 0),
      const AdContentState(loading: false, failed: true, itemCount: 50),
    ]) {
      await tester.pumpWidget(app(allowLeading: state.allowsAd));
      expect(slot, findsNothing);
      expect(find.byType(AdBanner), findsNothing);
    }
    await tester.pumpWidget(
      app(
        allowLeading: const AdContentState(
          loading: false,
          failed: false,
          itemCount: 50,
        ).allowsAd,
      ),
    );
    expect(slot, findsOneWidget);
    // Subsequent refresh/error removes the already mounted platform, not just its label.
    await tester.pumpWidget(app(allowLeading: false));
    expect(find.byType(AdBanner), findsNothing);
    expect(slot, findsNothing);
  });
  testWidgets('visible publisher content keeps the same slot through refresh', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    final before = tester.element(find.byType(AdBanner));
    const refresh = AdContentState(
      loading: true,
      failed: false,
      itemCount: 50,
      contentRemainsVisible: true,
    );
    await tester.pumpWidget(app(allowLeading: refresh.allowsAd));
    expect(tester.element(find.byType(AdBanner)), same(before));
    expect(slot, findsOneWidget);
    await tester.pumpWidget(app());
    expect(tester.element(find.byType(AdBanner)), same(before));
    const failed = AdContentState(
      loading: false,
      failed: true,
      itemCount: 50,
      contentRemainsVisible: true,
    );
    await tester.pumpWidget(app(allowLeading: failed.allowsAd));
    expect(find.byType(AdBanner), findsNothing);
  });
  test('requires valid IDs and opt-in; preview never implies live ads', () {
    expect(const AdConfig().show(adFree: false, web: true), isFalse);
    expect(
      const AdConfig(enabled: true).show(adFree: false, web: true),
      isFalse,
    );
    const valid = AdConfig(
      enabled: true,
      siteApproved: true,
      privacyReady: true,
      publisher: 'ca-pub-1234567890123456',
      slot: '1234567890',
    );
    expect(valid.show(adFree: false, web: true), isTrue);
    expect(valid.show(adFree: true, web: true), isFalse);
    expect(valid.show(adFree: false, web: false), isFalse);
    expect(valid.testMode, isTrue);
  });
  test('approval and privacy gates independently prevent requests', () {
    for (final approved in [false, true]) {
      for (final privacy in [false, true]) {
        final config = AdConfig(
          enabled: true,
          siteApproved: approved,
          privacyReady: privacy,
          publisher: 'ca-pub-1234567890123456',
          slot: '1234567890',
        );
        expect(config.show(adFree: false, web: true), approved && privacy);
      }
    }
  });
  test('server-issued ad-free scope does not grant admin', () {
    final paid = AppViewer.fromScopes('reader', {adFreeScopeName});
    expect(paid.isAdFree, isTrue);
    expect(paid.isAdmin, isFalse);
    final admin = AppViewer.fromScopes('admin', {adminScopeName});
    expect(admin.isAdFree, isFalse);
    expect(
      paid,
      const AppViewer(
        userId: 'reader',
        isAdmin: false,
        isAdFree: true,
        membershipResolved: false,
      ),
    );
    expect(paid, isNot(const AppViewer(userId: 'reader', isAdmin: false)));
  });
  testWidgets('restored account requests no ads before entitlement resolves', (
    tester,
  ) async {
    await tester.pumpWidget(app(viewer: AppViewer.fromScopes('member', {})));
    expect(slot, findsNothing);
    await tester.pumpWidget(
      app(viewer: const AppViewer(userId: 'member', isAdmin: false)),
    );
    expect(slot, findsOneWidget);
  });
  testWidgets('disabled config reserves no ad space', (tester) async {
    await tester.pumpWidget(app(config: const AdConfig()));
    expect(slot, findsNothing);
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('in-flow banner fits $width and scrolls out with content', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(scale: 2));
      expect(slot, findsOneWidget);
      expect(tester.takeException(), isNull);
      final before = tester.getTopLeft(slot).dy;
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(slot).dy, lessThan(before - 100));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'paid switch removes slot and membership copy; logout restores free',
    (tester) async {
      await tester.pumpWidget(app());
      expect(slot, findsOneWidget);
      await tester.pumpWidget(
        app(viewer: AppViewer.fromScopes('paid', {adFreeScopeName})),
      );
      expect(slot, findsNothing);
      expect(find.text('멤버십 이용 중'), findsOneWidget);
      await tester.pumpWidget(
        app(viewer: const AppViewer(userId: 'free', isAdmin: false)),
      );
      expect(slot, findsOneWidget);
      expect(find.text('무료 플랜 · 관심기업 3개'), findsOneWidget);
      expect(find.text('아직 결제할 수 없으며, 요금이 청구되지 않습니다.'), findsOneWidget);
      await tester.pumpWidget(app());
      expect(slot, findsOneWidget);
    },
  );
}
