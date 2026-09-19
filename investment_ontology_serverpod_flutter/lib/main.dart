import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/ingest_monitor.dart';
import 'app/router.dart';
import 'client.dart';
import 'design/app_theme.dart';
import 'design/brands/ledger_brand.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 주소에 #을 쓰지 않는다 (/company/00126380).
  usePathUrlStrategy();
  await initializeClient();
  IngestMonitor.instance.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '투자 온톨로지',
      debugShowCheckedModeBanner: false,
      // 리브랜딩: 새 AppBrand를 만들어 여기만 바꾼다.
      theme: buildAppTheme(ledgerBrand),
      routerConfig: AppRoutes.router,
    );
  }
}
