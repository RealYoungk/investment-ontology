@TestOn('browser')
library;

import 'package:shad/shad.dart';

import 'support/shad_test_host.dart';

// Browser + real authenticated RPC + isolated PostgreSQL; provider responses are mocked.
import 'dart:convert';
import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/client.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/ledger_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/app_viewer.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/ad_banner.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/ad_config.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/billing_checkout_page.dart';
import 'package:investment_ontology_serverpod_flutter/features/monetization/membership_monitor.dart';

class FixtureAuth implements ClientAuthKeyProvider {
  FixtureAuth(this.token);
  String? token;
  @override
  Future<String?> get authHeaderValue async =>
      token == null ? null : 'Bearer $token';
}

void main() {
  const config = String.fromEnvironment('BILLING_BROWSER_FIXTURE');
  testWidgets(
    'browser checkout, card replacement, renewal, cancel, restart, refund and account isolation',
    (tester) async {
      final originalError = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint('Browser assertion: ${details.exceptionAsString()}');
        originalError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalError);
      final f = jsonDecode(config) as Map<String, dynamic>;
      final auth = FixtureAuth(f['token'] as String);
      client = Client(f['url'] as String)..authKeyProvider = auth;
      final source = ValueNotifier<AppViewer?>(
        AppViewer(userId: f['user'] as String, isAdmin: false),
      );
      final monitor = MembershipMonitor(
        source: source,
        fetch: client.membership.status,
      );
      var disposed = false;
      addTearDown(() {
        if (disposed) return;
        monitor.dispose();
        source.dispose();
        client.close();
      });
      Future<T> io<T>(Future<T> Function() action) async =>
          (await tester.runAsync(action)) as T;
      Future<void> waitFor(bool Function() condition) async {
        for (var i = 0; i < 150 && !condition(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        expect(condition(), true);
      }

      Future<Map<String, dynamic>> control(String op) => io(() async {
        final response = await http.post(
          Uri.parse('${f['control']}/$op'),
          headers: {'Authorization': 'Bearer ${f['token']}'},
        );
        expect(response.statusCode, 200);
        return jsonDecode(response.body) as Map<String, dynamic>;
      });
      Future<void> refresh() => io(monitor.refresh);
      Future<void> show(BillingCheckoutPage page) async {
        await tester.pumpWidget(
          shadTestHost(
            MaterialApp(
              theme: buildAppTheme(ledgerBrand),
              home: Scaffold(
                body: ValueListenableBuilder<AppViewer?>(
                  valueListenable: monitor.viewer,
                  builder: (_, viewer, _) => AppViewerScope(
                    viewer: viewer,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const AdBanner(config: AdConfig(preview: true)),
                          page,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await waitFor(
          () => find.byType(ShadProgress).evaluate().isEmpty,
        );
      }

      await io(() async {
        final loaded = Completer<void>();
        final script = web.HTMLScriptElement()
          ..src = '${f['control']}/billing_loader.js';
        script.onload = ((web.Event _) {
          loaded.complete();
        }).toJS;
        script.onerror = ((web.Event _) {
          loaded.completeError(StateError('Local bridge unavailable'));
        }).toJS;
        web.document.head!.appendChild(script);
        await loaded.future;
      });
      await refresh();
      BillingCheckoutView? launched;
      await show(
        BillingCheckoutPage(
          checkoutEnabled: true,
          key: const ValueKey('first'),
          launch: (v) async {
            launched = v;
          },
        ),
      );
      expect(find.byKey(const ValueKey('ad-placement-slot')), findsOneWidget);
      final start = find.widgetWithText(ShadButton, '테스트 카드 등록');
      expect(tester.widget<ShadButton>(start).onPressed, isNull);
      await tester.ensureVisible(find.byType(ShadCheckbox));
      await tester.tap(find.byType(ShadCheckbox));
      await tester.pump();
      await tester.ensureVisible(start);
      await tester.tap(start);
      await waitFor(() => launched != null);
      final first = launched!;
      // Another account cannot consume the callback produced by this screen.
      auth.token = f['otherToken'] as String;
      var foreignDenied = false;
      await io(() async {
        try {
          await client.membership.completeCheckout(first.state, 'fixture-auth');
        } catch (_) {
          foreignDenied = true;
        }
      });
      expect(foreignDenied, true);
      auth.token = f['token'] as String;
      await show(
        BillingCheckoutPage(
          checkoutEnabled: true,
          key: const ValueKey('callback'),
          state: first.state,
          authKey: 'fixture-auth',
          refresh: monitor.refresh,
        ),
      );
      expect(
        find.text('멤버십이 적용되었습니다. 관심기업을 20개까지 등록할 수 있습니다.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ad-placement-slot')), findsNothing);
      expect((await control('stats'))['charges'], 1);
      await io(client.membership.cancelRenewal);
      await refresh();
      expect(monitor.viewer.value!.cancelAtPeriodEnd, true);
      final priorEnd = monitor.viewer.value!.paidThroughUtc;
      final replacement = await io(
        () => client.membership.beginCardReplacement('sandbox-v1'),
      );
      await show(
        BillingCheckoutPage(
          checkoutEnabled: true,
          key: const ValueKey('card'),
          replaceCard: true,
          state: replacement.state,
          authKey: 'fixture-replace',
          refresh: monitor.refresh,
        ),
      );
      expect(find.text('결제 카드를 변경했습니다. 추가 요금은 청구하지 않았습니다.'), findsOneWidget);
      expect(monitor.viewer.value!.paidThroughUtc, priorEnd);
      expect(monitor.viewer.value!.cancelAtPeriodEnd, true);
      expect((await control('stats'))['charges'], 1);
      await io(client.membership.resumeRenewal);
      await refresh();
      expect(monitor.viewer.value!.cancelAtPeriodEnd, false);
      await control('expire');
      await refresh();
      await tester.pump();
      expect(find.byKey(const ValueKey('ad-placement-slot')), findsOneWidget);
      await control('renew');
      await refresh();
      await tester.pump();
      expect(monitor.viewer.value!.isAdFree, true);
      expect((await control('stats'))['charges'], 2);
      await io(client.membership.cancelRenewal);
      await control('expire');
      await refresh();
      // Expire the latest renewed period as well, then restart via a new checkout.
      await control('expireAll');
      await refresh();
      final restart = await io(
        () => client.membership.beginCheckout('sandbox-v1'),
      );
      await show(
        BillingCheckoutPage(
          checkoutEnabled: true,
          key: const ValueKey('restart'),
          state: restart.state,
          authKey: 'fixture-rejoin',
          refresh: monitor.refresh,
        ),
      );
      expect(monitor.viewer.value!.isAdFree, true);
      expect((await control('stats'))['charges'], 3);
      await control('refund');
      await refresh();
      await tester.pump();
      expect(monitor.viewer.value!.isAdFree, false);
      expect(find.byKey(const ValueKey('ad-placement-slot')), findsOneWidget);
      auth.token = f['otherToken'] as String;
      source.value = AppViewer(userId: f['other'] as String, isAdmin: false);
      await refresh();
      expect(monitor.viewer.value!.isAdFree, false);
      auth.token = null;
      source.value = null;
      await tester.pump();
      var anonymousDenied = false;
      await io(() async {
        try {
          await client.membership.status();
        } catch (_) {
          anonymousDenied = true;
        }
      });
      expect(anonymousDenied, true);
      await control('stop');
      monitor.dispose();
      source.dispose();
      client.close();
      disposed = true;
      await tester.pumpWidget(shadTestHost(const SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 21));
    },
    skip: config.isEmpty,
  );
}
