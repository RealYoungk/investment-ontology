import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // 글꼴을 첫 배치 전에 받는다. 나중에 바뀌면 표가 글꼴 바뀌기 전 폭으로 열을 잰 채 남아
  // 이름 열이 접히고 flex 열만 넓어진다 (헤드리스 캡처에서 확인).
  final theme = buildAppTheme(ledgerBrand);
  await GoogleFonts.pendingFonts();
  runApp(MyApp(theme: theme));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.theme});

  /// 리브랜딩: 새 AppBrand를 만들어 main()에서 바꾼다.
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '투자 온톨로지',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: AppRoutes.router,
    );
  }
}
