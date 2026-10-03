import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/design/components/components.dart';
import 'package:investment_ontology_serverpod_flutter/design/tokens.dart';

import '../support/shad_test_host.dart';

Widget host(Widget child) => shadTestHost(
  MaterialApp(
    theme: buildAppTheme(
      const AppBrand(
        colors: researchDeskColors,
        shape: AppShape(radius: 10, strokeWidth: 1),
        typography: AppTypography(
          displayBase: TextStyle(),
          bodyBase: TextStyle(),
          numericBase: TextStyle(),
          labelBase: TextStyle(),
        ),
      ),
    ),
    home: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('관계망은 서버 없이 그려지고 표시 노드 선택을 전달한다', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selected;
    await tester.pumpWidget(
      host(
        ResearchGraphCanvas(
          graph: const ResearchGraph(
            centerKey: 'a',
            nodes: [
              ResearchGraphNode(
                key: 'a',
                kind: 'company',
                label: '합성 기업 A',
                tooltip: '합성 중심 기업',
                depth: 0,
              ),
              ResearchGraphNode(
                key: 'b',
                kind: 'person',
                label: '합성 인물 B',
                tooltip: '합성 인물',
                depth: 1,
              ),
            ],
            edges: [
              ResearchGraphEdge(
                from: 'b',
                to: 'a',
                kind: ResearchLinkKind.executive,
                estimated: true,
              ),
            ],
          ),
          selected: null,
          onTap: (node) => selected = node.key,
        ),
      ),
    );
    await tester.tap(find.text('합성 인물 B'));
    await tester.pump();
    expect(selected, 'b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('방향성 도식은 표시 단위·추정·탐색 대상을 호출자가 정한다', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(
        RelationshipDiagram<String>(
          center: '합성 중심',
          left: const [
            RelationshipDiagramNode(
              value: 'holder',
              name: '합성 주주',
              kind: 'company',
              weightLabel: '15.0%',
              tooltip: '원문 근거 예시',
              linked: true,
              weight: 15,
              estimated: true,
            ),
          ],
          right: const [
            RelationshipDiagramNode(
              value: 'unknown',
              name: '미확인 이름',
              kind: 'name',
              weightLabel: '—',
              tooltip: '확인되지 않은 이름',
              linked: false,
            ),
          ],
          onTap: (node) => selected = node.value,
        ),
      ),
    );
    expect(find.text('15.0%'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    await tester.tap(find.text('미확인 이름'));
    expect(selected, isNull);
    await tester.tap(find.text('합성 주주'));
    expect(selected, 'holder');
    expect(tester.takeException(), isNull);
  });

  testWidgets('동작 줄이기 설정에서는 수집 상태 점의 반복 애니메이션을 멈춘다', (tester) async {
    await tester.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatusDot(
            color: researchDeskColors.accent,
            label: '수집 중',
            pulsing: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('수집 중'), findsOneWidget);
    await tester.pumpAndSettle();
    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(StatusDot),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
  });
}
