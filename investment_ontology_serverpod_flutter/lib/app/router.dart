import 'package:flutter/foundation.dart';

import '../design/design_gallery.dart';

import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';
import '../features/auth/account_page.dart';
import '../features/auth/app_auth.dart';
import '../features/auth/sign_in_page.dart';
import '../features/home/about_page.dart';
import '../features/monetization/billing_checkout_page.dart';
import '../features/monetization/membership_plans_page.dart';
import '../features/home/explore_intent.dart';
import '../features/companies/company_filter.dart';
import '../features/companies/company_list_page.dart';
import '../features/company_detail/company_page.dart';
import '../features/data_sync/data_page.dart';
import '../features/financials/financial_report_page.dart';
import '../features/governance/person_page.dart';
import '../features/graph/graph_page.dart';
import '../features/groups/group_page.dart';
import '../features/groups/groups_page.dart';
import '../features/market_map/market_page.dart';
import '../features/macro/macro_page.dart';
import '../features/review/review_page.dart';
import '../features/screen/compare_page.dart';
import '../features/market_map/industry_discovery_page.dart';
import '../features/screen/screen_filter.dart';
import '../features/screen/screen_page.dart';
import '../features/themes/theme_page.dart';
import '../features/themes/themes_page.dart';
import 'app_shell.dart';
import '../features/watchlist/watchlist_page.dart';
import '../features/watchlist/notification_bell.dart';

/// 화면 주소.
///
/// - `/home` 질문에서 시작하는 기업 탐색 (기본 진입점)
/// - `/about` 서비스 소개
/// - `/market` 시장 — 시장 요약 · 업종 분포 · 시총 트리맵
/// - `/companies?market=&section=&division=&q=&sort=&page=` 기업 목록 (필터가 주소에 남는다)
/// - `/company/:corpCode?tab=financials` 기업 상세 (tab: overview · financials · business · governance · returns · disclosures)
/// - `/person/:personId` 인물
/// - `/themes`, `/themes/:themeId` 테마
/// - `/graph/:corpCode` 관계망
/// - `/groups`, `/groups/:corpCode` 지분 묶음 (묶음에 속한 아무 기업으로 찾는다)
/// - `/screen` 스크리너 (재무·시세로 거르기)
/// - `/compare?codes=a,b` 기업 비교
/// - `/review` AI 관계 검수
/// - `/reports/:reportId` 재무제표 원문 표
/// - `/data` 수집 상태
///
/// 맨 위 메뉴 사이 이동은 [GoRouterHelper.go], 상세로 들어갈 때는 [GoRouterHelper.push]를
/// 쓴다. push로 들어가면 목록 화면이 그대로 남아 있어 뒤로 오면 스크롤 위치까지 돌아온다.
abstract final class AppRoutes {
  static String company(String corpCode, {String? tab}) =>
      '/company/$corpCode${tab == null ? '' : '?tab=$tab'}';

  static String login({required String next}) =>
      Uri(path: '/login', queryParameters: {'next': next}).toString();

  static String afterLogin(String? next) {
    // Only known local destinations may be supplied by the login URL.
    if (next == '/account' || next == '/membership/checkout') return next!;
    final saved = Uri.tryParse(next ?? '');
    if (saved != null &&
        !saved.hasScheme &&
        !saved.hasAuthority &&
        saved.path == '/membership/checkout') {
      // Preserve an account-bound PG callback across session expiry. Unknown
      // parameters and duplicate identity values cannot enter the checkout.
      const allowed = {'state', 'authKey', 'billingKey', 'card', 'code'};
      if (saved.queryParametersAll.values.any((v) => v.length != 1)) {
        return '/membership/checkout';
      }
      return Uri(
        path: saved.path,
        queryParameters: {
          for (final entry in saved.queryParameters.entries)
            if (allowed.contains(entry.key) && entry.value.length <= 512)
              entry.key: entry.value,
        },
      ).toString();
    }
    if (saved != null &&
        !saved.hasScheme &&
        !saved.hasAuthority &&
        saved.path == '/watchlist') {
      final code = saved.queryParameters['add'];
      return code != null && RegExp(r'^\d{8}$').hasMatch(code)
          ? '/watchlist?add=$code'
          : '/watchlist';
    }
    final uri = Uri.tryParse(next ?? '');
    if (uri != null &&
        !uri.hasScheme &&
        !uri.hasAuthority &&
        RegExp(r'^/company/[0-9]{8}$').hasMatch(uri.path)) {
      return uri.toString();
    }
    return '/home';
  }

  static String person(int personId) => '/person/$personId';

  static String theme(int themeId) => '/themes/$themeId';

  static String graph(String corpCode) => '/graph/$corpCode';

  static String compare(List<String> corpCodes) =>
      '/compare${corpCodes.isEmpty ? '' : '?codes=${corpCodes.join(',')}'}';

  static String report(int reportId) => '/reports/$reportId';

  static String group(String corpCode) => '/groups/$corpCode';

  static final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: AppAuth.viewer,
    redirect: (_, state) {
      final viewer = AppAuth.viewer.value;
      final path = state.uri.path;
      // 테마와 지분 묶음은 고도화 전까지 숨긴다. 저장 데이터와 구현은 유지한다.
      if (path == '/themes' ||
          path.startsWith('/themes/') ||
          path == '/groups' ||
          path.startsWith('/groups/')) {
        return '/home';
      }
      final adminOnly =
          path == '/data' || path == '/review' || path.startsWith('/admin/');
      if (adminOnly && !(viewer?.isAdmin ?? false)) return '/home';
      if (path == '/membership/checkout' && viewer == null) {
        return login(next: state.uri.toString());
      }
      if ((path == '/watchlist' || path == '/notifications') &&
          viewer == null) {
        return login(next: state.uri.toString());
      }
      if (path == '/account' && viewer == null) return '/login?next=/account';
      if (path == '/login' && viewer != null) {
        return afterLogin(state.uri.queryParameters['next']);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/home'),
      GoRoute(path: '/login', builder: (_, _) => const SignInPage()),
      if (kDebugMode)
        GoRoute(path: '/design/auth', builder: (_, _) => const SignInPage()),
      GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri, child: child),
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, _) => const NotificationsPage(),
          ),
          GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
          GoRoute(
            path: '/watchlist',
            builder: (_, state) =>
                WatchlistPage(addCode: state.uri.queryParameters['add']),
          ),
          GoRoute(
            path: '/membership',
            builder: (_, _) => const MembershipPlansPage(),
          ),
          GoRoute(
            path: '/membership/checkout',
            builder: (_, state) => BillingCheckoutPage(
              state: state.uri.queryParameters['state'],
              authKey:
                  state.uri.queryParameters['authKey'] ??
                  state.uri.queryParameters['billingKey'],
              replaceCard: state.uri.queryParameters['card'] == 'replace',
              failed: state.uri.queryParameters.containsKey('code'),
            ),
          ),
          GoRoute(
            path: '/admin/accounts',
            builder: (_, _) => const AccountPage(manage: true),
          ),
          if (kDebugMode)
            GoRoute(path: '/design', builder: (_, _) => const DesignGallery()),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: const ValueKey('home'),
              child: HomePage(
                intent: ExploreIntent.fromQuery(
                  state.uri.queryParameters['intent'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/industries',
            pageBuilder: (context, state) => NoTransitionPage(
              key: const ValueKey('industries'),
              child: IndustryDiscoveryPage(query: state.uri.queryParameters),
            ),
          ),
          GoRoute(
            path: '/market',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MarketPage()),
          ),
          GoRoute(
            path: '/market/indicators',
            pageBuilder: (context, state) => NoTransitionPage(
              key: const ValueKey('market-indicators'),
              child: MacroPage(query: state.uri.queryParameters),
            ),
          ),
          GoRoute(
            path: '/companies',
            pageBuilder: (context, state) => NoTransitionPage(
              // 필터가 바뀌어도 같은 화면을 유지하고 목록만 다시 불러온다.
              key: const ValueKey('companies'),
              child: CompanyListPage(
                filter: CompanyFilter.fromQuery(state.uri.queryParameters),
              ),
            ),
          ),
          GoRoute(
            path: '/themes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ThemesPage()),
          ),
          GoRoute(
            path: '/themes/:themeId',
            builder: (context, state) => ThemePage(
              themeId: int.tryParse(state.pathParameters['themeId']!) ?? -1,
            ),
          ),
          GoRoute(
            path: '/graph',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GraphPage()),
          ),
          GoRoute(
            path: '/graph/:corpCode',
            // 키에 기업을 넣는다. 고정 키 하나면 관계망을 관계망 위에 쌓을 때
            // (기업 상세의 "관계망 →") 같은 키가 둘이 되어 Navigator가 걸린다.
            pageBuilder: (context, state) => NoTransitionPage(
              key: ValueKey('graph:${state.pathParameters['corpCode']}'),
              child: GraphPage(corpCode: state.pathParameters['corpCode']),
            ),
          ),
          GoRoute(
            path: '/groups',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GroupsPage()),
          ),
          GoRoute(
            path: '/groups/:corpCode',
            builder: (context, state) =>
                GroupPage(corpCode: state.pathParameters['corpCode']!),
          ),
          GoRoute(
            path: '/screen',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ScreenerPage(
                filter: ScreenFilter.fromQuery(state.uri.queryParameters),
              ),
            ),
          ),
          GoRoute(
            path: '/compare',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ComparePage(
                discoveryProduct: state.uri.queryParameters['industryProduct'],
                corpCodes: [
                  for (final c
                      in (state.uri.queryParameters['codes'] ?? '').split(','))
                    if (c.trim().isNotEmpty) c.trim(),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/review',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReviewQueuePage()),
          ),
          GoRoute(
            path: '/data',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DataPage()),
          ),
          GoRoute(
            path: '/company/:corpCode',
            builder: (context, state) => CompanyPage(
              corpCode: state.pathParameters['corpCode']!,
              initialTab:
                  CompanyTab.values
                      .asNameMap()[state.uri.queryParameters['tab']] ??
                  CompanyTab.overview,
            ),
          ),
          GoRoute(
            path: '/person/:personId',
            builder: (context, state) => PersonPage(
              personId: int.tryParse(state.pathParameters['personId']!) ?? -1,
            ),
          ),
          GoRoute(
            path: '/reports/:reportId',
            builder: (context, state) => FinancialReportPage(
              reportId: int.tryParse(state.pathParameters['reportId']!) ?? -1,
            ),
          ),
        ],
      ),
    ],
  );
}
