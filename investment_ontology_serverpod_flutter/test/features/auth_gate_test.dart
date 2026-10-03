import '../support/shad_test_host.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/app_viewer.dart';
import 'package:investment_ontology_serverpod_flutter/features/auth/auth_gate.dart';

/// 데이터 화면 대신: 만들어진 횟수와 버려졌는지를 센다 (데이터를 부르는 initState 자리).
class _Probe extends StatefulWidget {
  const _Probe({required this.id, required this.log});

  final String id;
  final List<String> log;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.log.add('load ${widget.id}');
  }

  @override
  void dispose() {
    widget.log.add('dispose ${widget.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('company ${widget.id}'),
        Text(context.viewer?.roleLabel ?? '-'),
        TextButton(
          onPressed: () {
            if (!context.ensureAdmin()) return;
            widget.log.add('mutate');
          },
          child: const Text('바꾸기'),
        ),
      ],
    ),
  );
}

void main() {
  late ValueNotifier<AppViewer?> viewer;
  late List<String> log;

  Future<void> pumpApp(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/company/42',
      routes: [
        GoRoute(path: '/market', builder: (_, _) => const Text('market')),
        GoRoute(
          path: '/company/:id',
          builder: (_, state) =>
              _Probe(id: state.pathParameters['id']!, log: log),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => AuthGate(
            viewer: viewer,
            signIn: const Scaffold(body: Text('로그인 화면')),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    viewer = ValueNotifier<AppViewer?>(null);
    log = [];
  });

  testWidgets('공개 탐색은 비로그인으로 열리고 관리자 권한은 없다', (tester) async {
    await tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          home: AuthGate(
            viewer: viewer,
            allowAnonymous: true,
            signIn: const Text('로그인 화면'),
            child: Builder(
              builder: (context) => Text(context.isAdmin ? '관리자' : '공개 탐색'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('공개 탐색'), findsOneWidget);
    expect(find.text('로그인 화면'), findsNothing);
    viewer.value = const AppViewer(userId: 'admin', isAdmin: true);
    await tester.pump();
    expect(find.text('관리자'), findsOneWidget);
    viewer.value = null;
    await tester.pump();
    expect(find.text('공개 탐색'), findsOneWidget);
  });

  testWidgets('로그인 전에는 어떤 화면도 만들지 않고, 로그인하면 처음 연 주소로 들어간다', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('로그인 화면'), findsOneWidget);
    expect(find.text('company 42'), findsNothing);
    expect(log, isEmpty);

    viewer.value = const AppViewer(userId: 'u1', isAdmin: false);
    await tester.pumpAndSettle();
    expect(find.text('company 42'), findsOneWidget);
    expect(find.text('읽기 전용'), findsOneWidget);
    expect(log, ['load 42']);
  });

  testWidgets('로그아웃하면 보던 화면을 버리고, 다시 로그인하면 새로 만든다', (tester) async {
    viewer.value = const AppViewer(userId: 'u1', isAdmin: true);
    await pumpApp(tester);
    expect(find.text('관리자'), findsOneWidget);

    viewer.value = null;
    await tester.pumpAndSettle();
    expect(find.text('company 42'), findsNothing);
    expect(find.text('로그인 화면'), findsOneWidget);
    expect(log, ['load 42', 'dispose 42']);

    viewer.value = const AppViewer(userId: 'u2', isAdmin: false);
    await tester.pumpAndSettle();
    expect(find.text('읽기 전용'), findsOneWidget);
    expect(log, ['load 42', 'dispose 42', 'load 42']);
  });

  testWidgets('읽기 전용 계정이 바꾸기를 누르면 요청 없이 권한 안내만 뜬다', (tester) async {
    viewer.value = const AppViewer(userId: 'u1', isAdmin: false);
    await pumpApp(tester);
    await tester.tap(find.text('바꾸기'));
    await tester.pump();
    expect(find.text(permissionMessage), findsOneWidget);
    expect(log, isNot(contains('mutate')));
  });

  testWidgets('관리자는 바꾸기가 실행된다', (tester) async {
    viewer.value = const AppViewer(userId: 'u1', isAdmin: true);
    await pumpApp(tester);
    await tester.tap(find.text('바꾸기'));
    await tester.pump();
    expect(find.text(permissionMessage), findsNothing);
    expect(log, contains('mutate'));
  });

  testWidgets('계정이 직접 바뀌어도 이전 화면 상태를 폐기한다', (tester) async {
    viewer.value = const AppViewer(userId: 'u1', isAdmin: true);
    await pumpApp(tester);
    viewer.value = const AppViewer(userId: 'u2', isAdmin: false);
    await tester.pumpAndSettle();
    expect(find.text('읽기 전용'), findsOneWidget);
    expect(log.where((line) => line == 'dispose 42'), hasLength(1));
    expect(log.where((line) => line == 'load 42'), hasLength(2));
  });

  test('역할은 서버의 admin 스코프 이름으로 정한다', () {
    expect(AppViewer.fromScopes('u', {adminScopeName}).isAdmin, isTrue);
    expect(AppViewer.fromScopes('u', {'other'}).isAdmin, isFalse);
  });
}
