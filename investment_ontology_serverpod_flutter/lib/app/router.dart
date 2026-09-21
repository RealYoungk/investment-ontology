import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/companies/company_filter.dart';
import '../features/companies/company_list_page.dart';
import '../features/company_detail/company_page.dart';
import '../features/data_sync/data_page.dart';
import '../features/financials/financial_report_page.dart';
import '../features/governance/person_page.dart';
import '../features/market_map/market_page.dart';
import 'app_shell.dart';

/// 화면 주소.
///
/// - `/market` 시장 — 시장 요약 · 업종 분포 · 시총 트리맵
/// - `/companies?market=&section=&division=&q=&sort=&page=` 기업 목록 (필터가 주소에 남는다)
/// - `/company/:corpCode?tab=financials` 기업 상세 (tab: overview · financials · governance · returns · disclosures)
/// - `/person/:personId` 인물
/// - `/reports/:reportId` 재무제표 원문 표
/// - `/data` 수집 상태
///
/// 맨 위 메뉴 사이 이동은 [GoRouterHelper.go], 상세로 들어갈 때는 [GoRouterHelper.push]를
/// 쓴다. push로 들어가면 목록 화면이 그대로 남아 있어 뒤로 오면 스크롤 위치까지 돌아온다.
abstract final class AppRoutes {
  static String company(String corpCode, {String? tab}) =>
      '/company/$corpCode${tab == null ? '' : '?tab=$tab'}';

  static String person(int personId) => '/person/$personId';

  static String report(int reportId) => '/reports/$reportId';

  static final router = GoRouter(
    initialLocation: '/market',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/market'),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri, child: child),
        routes: [
          GoRoute(
            path: '/market',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MarketPage()),
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
