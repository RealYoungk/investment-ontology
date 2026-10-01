// Local-only real Flutter renderer + authenticated isolated RPC; never shipped.
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

import '../lib/client.dart';
import '../lib/design/app_theme.dart';
import '../lib/design/brands/ledger_brand.dart';
import '../lib/features/auth/app_viewer.dart';
import '../lib/features/monetization/ad_banner.dart';
import '../lib/features/monetization/ad_config.dart';
import '../lib/features/monetization/membership_monitor.dart';

@JS('alfinderAdFixture.pushes')
external JSNumber get pushes;
@JS('alfinderAdFixture.adScripts')
external JSNumber get scripts;

class FixtureAuth implements ClientAuthKeyProvider {
  FixtureAuth(this.token);
  String? token;
  @override
  Future<String?> get authHeaderValue async =>
      token == null ? null : 'Bearer $token';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final f = jsonDecode(
    const String.fromEnvironment('BILLING_BROWSER_FIXTURE'),
  ) as Map<String, dynamic>;
  final auth = FixtureAuth(f['token'] as String);
  client = Client(f['url'] as String)..authKeyProvider = auth;
  final result = (web.document.createElement('pre') as web.HTMLElement)
    ..id = 'ad-membership-result'
    ..textContent = 'Native Flutter browser check running';
  result.style.cssText = 'position:fixed;bottom:0;left:0;right:0;max-height:60vh;overflow:auto;z-index:9999;background:white;color:black;padding:16px';
  web.document.body!.appendChild(result);
  try {
    final loaded = Completer<void>();
    final bridge = web.HTMLScriptElement()
      ..src = '${f['control']}/ad_loader.js';
    bridge.onload = ((web.Event _) => loaded.complete()).toJS;
    bridge.onerror = ((web.Event _) => loaded.completeError(
      StateError('fixture script'),
    )).toJS;
    web.document.head!.appendChild(bridge);
    await loaded.future;
    final source = ValueNotifier<AppViewer?>(
      AppViewer.fromScopes(f['user'] as String, {}),
    );
    var fail = false;
    final monitor = MembershipMonitor(
      source: source,
      fetch: () => fail
          ? Future.error(StateError('fixture unavailable'))
          : client.membership.status(),
    );
    runApp(
      MaterialApp(
        theme: buildAppTheme(ledgerBrand),
        home: Scaffold(
          body: ValueListenableBuilder<AppViewer?>(
            valueListenable: monitor.viewer,
            builder: (_, viewer, _) => AppViewerScope(
              viewer: viewer,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: AdBanner(
                  config: AdConfig(
                    enabled: true,
                    siteApproved: true,
                    privacyReady: true,
                    publisher: 'ca-pub-4209548390738211',
                    slot: '3239020318',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final rows = <Map<String, dynamic>>[];
    Future<void> record(String name, int expectedPush, bool slot) async {
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (pushes.toDartInt == expectedPush &&
            (web.document.querySelector('ins.adsbygoogle') != null) == slot)
          break;
      }
      final row = {
        'scenario': name,
        'pushes': pushes.toDartInt,
        'adScripts': scripts.toDartInt,
        'slot': web.document.querySelector('ins.adsbygoogle') != null,
        'passed':
            pushes.toDartInt == expectedPush &&
            (web.document.querySelector('ins.adsbygoogle') != null) == slot,
      };
      rows.add(row);
      result.textContent = jsonEncode(rows);
      if (row['passed'] != true) throw StateError('Failed $name');
    }

    Future<void> control(String op) async {
      final r = await http.post(
        Uri.parse('${f['control']}/$op'),
        headers: {'Authorization': 'Bearer ${f['token']}'},
      );
      if (r.statusCode != 200) throw StateError('control failed');
    }

    await monitor.refresh();
    await record('free', 1, true);
    fail = true;
    await monitor.refresh();
    await record('membershipFailure', 1, false);
    fail = false;
    await monitor.refresh();
    await record('recoveredFree', 2, true);
    final checkout = await client.membership.beginCheckout('sandbox-v1');
    await client.membership.completeCheckout(checkout.state, 'fixture-auth');
    await monitor.refresh();
    await record('paid', 2, false);
    await client.membership.cancelRenewal();
    await monitor.refresh();
    await record('cancelPaidPeriod', 2, false);
    await client.membership.resumeRenewal();
    await control('expire');
    await monitor.refresh();
    await record('expired', 3, true);
    await control('renew');
    await monitor.refresh();
    await record('renewedPaid', 3, false);
    await control('refund');
    await monitor.refresh();
    await record('refunded', 4, true);
    auth.token = null;
    source.value = null;
    await record('logout', 5, true);
    result.textContent = jsonEncode({
      'passed': rows.length,
      'total': rows.length,
      'provider': 'Google/Toss mocked; real Flutter renderer, production JS, authenticated RPC and isolated DB',
      'results': rows,
    });
    monitor.dispose();
    source.dispose();
    client.close();
    await control('stop');
  } catch (e) {
    result.textContent = 'FAILED: $e\n${result.textContent}';
  }
}
