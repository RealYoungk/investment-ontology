import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';
import 'package:investment_ontology_serverpod_flutter/client.dart' as app;
import 'package:investment_ontology_serverpod_flutter/design/app_theme.dart';
import 'package:investment_ontology_serverpod_flutter/design/brands/research_desk_brand.dart';
import 'package:investment_ontology_serverpod_flutter/features/governance/person_page.dart';

import '../support/shad_test_host.dart';

class PeopleFixture implements EndpointGovernance {
  final requests = <int, Completer<PersonProfile?>>{};
  @override
  Future<PersonProfile?> person(int personId) =>
      (requests[personId] = Completer<PersonProfile?>()).future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PeopleClientFixture implements Client {
  @override
  final PeopleFixture governance = PeopleFixture();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PersonProfile profile(int id) => PersonProfile(
  person: Person(id: id, name: '인물 $id', personKey: '$id', estimated: false),
  roles: [],
);
void main() {
  testWidgets('인물 주소 변경 중 이전 응답이 새 인물을 덮어쓰지 않는다', (tester) async {
    final fixture = PeopleClientFixture();
    app.client = fixture;
    Future<void> show(int id) => tester.pumpWidget(
      shadTestHost(
        MaterialApp(
          theme: buildAppTheme(researchDeskBrand),
          home: PersonPage(personId: id),
        ),
      ),
    );
    await show(1);
    await show(2);
    fixture.governance.requests[2]!.complete(profile(2));
    await tester.pumpAndSettle();
    expect(find.text('인물 2'), findsWidgets);
    fixture.governance.requests[1]!.complete(profile(1));
    await tester.pumpAndSettle();
    expect(find.text('인물 1'), findsNothing);
    expect(find.text('인물 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
