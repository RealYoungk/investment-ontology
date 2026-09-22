import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'app/ingest_monitor.dart';
import 'app/router.dart';
import 'client.dart';
import 'design/app_theme.dart';
import 'design/brands/research_desk_brand.dart';
import 'features/auth/app_auth.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/sign_in_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 주소에 #을 쓰지 않는다 (/company/00126380).
  usePathUrlStrategy();
  await initializeClient();
  AppAuth.bind(client.auth);
  // 수집 감시도 데이터 요청이다. 로그인하기 전에는 시작하지 않는다.
  void startMonitorWhenSignedIn() {
    if (AppAuth.viewer.value != null) {
      IngestMonitor.instance.start();
    } else {
      IngestMonitor.instance.stop();
    }
  }

  AppAuth.viewer.addListener(startMonitorWhenSignedIn);
  startMonitorWhenSignedIn();
  // 글꼴을 첫 배치 전에 받는다. 나중에 바뀌면 표가 글꼴 바뀌기 전 폭으로 열을 잰 채 남아
  // 이름 열이 접히고 flex 열만 넓어진다 (헤드리스 캡처에서 확인).
  final theme = buildAppTheme(researchDeskBrand);
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
      // 로그인 폼의 텍스트 칸은 한국어로 짰지만, 길게 눌렀을 때 나오는 선택 메뉴(복사·붙여
      // 넣기 등)는 Flutter의 기본 MaterialLocalizations를 따른다. 이걸 한국어로 두지
      // 않으면 그 메뉴만 영어로 남는다.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko')],
      locale: const Locale('ko'),
      routerConfig: AppRoutes.router,
      // 로그인하지 않았으면 라우터를 만들지 않는다: 어떤 화면도 데이터를 부르지 않는다.
      builder: (context, child) => AuthGate(
        viewer: AppAuth.viewer,
        signIn: const SignInPage(),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
