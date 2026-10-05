import 'dart:convert';

import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/notes/investment_notes.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/notes/investment_note_content.dart';

import 'package:serverpod_test/serverpod_test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/endpoints.dart';

import '../unit/investment_note_content_test.dart' show fixture;

void main() {
  buildWithServerpod<_NotesTestEndpoints>(
    'Authored investment notes',
    TestServerpod(
      testEndpoints: _NotesTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      isDatabaseEnabled: true,
      applyMigrations: true,
      serverpodLoggingMode: null,
      runMode: null,
      testServerOutputMode: null,
    ),
    maybeRollbackDatabase: RollbackDatabase.disabled,
    maybeEnableSessionLogging: false,
    maybeTestGroupTagsOverride: ['integration'],
    maybeServerpodStartTimeout: const Duration(seconds: 120),
    maybeTestServerOutputMode: TestServerOutputMode.normal,
  )((builder, endpoints) {
    test('admin import, exact approval, immutable publication, membership expiry and follow-up notices', () async {
      final anonymous = builder.build();
      addTearDown(anonymous.close);
      final user = await const AuthUsers().create(anonymous);
      final admin = builder
          .copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              user.id.uuid,
              {Scope.admin},
            ),
          )
          .build();
      final free = builder
          .copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              user.id.uuid,
              {},
            ),
          )
          .build();
      addTearDown(admin.close);
      addTearDown(free.close);
      await Company.db.insertRow(
        anonymous,
        Company(corpCode: '00123456', name: 'Fixture', market: Market.kosdaq),
      );
      final payload = jsonEncode(fixture());
      await expectLater(
        InvestmentNotes.importDraft(anonymous, payload),
        throwsA(anything),
      );
      await expectLater(
        InvestmentNotes.importDraft(free, payload),
        throwsA(anything),
      );
      final draft = await InvestmentNotes.importDraft(admin, payload);
      final id = draft['id'] as int;
      expect(await InvestmentNotes.list(anonymous), isEmpty);
      expect(await InvestmentNotes.detail(anonymous, id), isNull);
      await expectLater(InvestmentNotes.preview(free, id), throwsA(anything));
      await expectLater(
        InvestmentNotes.publish(free, id, draft['digest'] as String),
        throwsA(anything),
      );
      await expectLater(
        InvestmentNotes.publish(admin, id, 'wrong'),
        throwsFormatException,
      );
      final revised = await InvestmentNotes.importDraft(
        admin,
        jsonEncode({...fixture(), 'title': '확인할 새 초안'}),
        articleId: id,
      );
      await expectLater(
        InvestmentNotes.publish(admin, id, draft['digest'] as String),
        throwsFormatException,
      );
      await WatchlistEntry.db.insertRow(
        anonymous,
        WatchlistEntry(ownerId: user.id, corpCode: '00123456', position: 0),
      );
      await InvestmentNotes.publish(admin, id, revised['digest'] as String);
      await InvestmentNotes.publish(admin, id, revised['digest'] as String);
      expect(await WatchlistNotice.db.count(anonymous), 1);
      final read = await InvestmentNotes.detail(anonymous, id);
      expect(read!['introduction'], '무료 소개');
      expect(jsonEncode(read), isNot(contains('SECRET')));
      await expectLater(
        InvestmentNotes.importDraft(admin, payload, articleId: id),
        throwsFormatException,
      );
      final follow = await InvestmentNotes.importDraft(
        admin,
        jsonEncode({...fixture(), 'previousArticleId': id, 'title': '후속 관점'}),
      );
      await InvestmentNotes.publish(
        admin,
        follow['id'] as int,
        follow['digest'] as String,
      );
      expect(
        (await InvestmentNotes.detail(
          admin,
          follow['id'] as int,
        ))!['previousArticleId'],
        id,
      );
      expect((await InvestmentNotes.detail(admin, id))!['title'], '확인할 새 초안');
      expect(await WatchlistNotice.db.count(anonymous), 2);
      final now = DateTime.now().toUtc();
      final sub = await BillingSubscription.db.insertRow(
        anonymous,
        BillingSubscription(
          ownerId: user.id,
          originUtc: now,
          cancelAtPeriodEnd: true,
        ),
      );
      final payment = await BillingPaymentAttempt.db.insertRow(
        anonymous,
        BillingPaymentAttempt(
          subscriptionId: sub.id!,
          period: 0,
          orderId: 'notes-order',
          idempotencyKey: 'notes-key',
          status: 'paid',
          paidFromUtc: now.subtract(const Duration(days: 1)),
          paidThroughUtc: now.add(const Duration(days: 1)),
        ),
      );
      expect(
        jsonEncode(await InvestmentNotes.detail(free, id)),
        contains('SECRET'),
      );
      expect(
        jsonEncode(await InvestmentNotes.list(free)),
        isNot(contains('SECRET')),
      );
      await BillingPaymentAttempt.db.updateRow(
        anonymous,
        payment.copyWith(
          paidThroughUtc: now.subtract(const Duration(seconds: 1)),
        ),
      );
      expect(
        jsonEncode(await InvestmentNotes.detail(free, id)),
        isNot(contains('SECRET')),
      );
      final top = await InvestmentNotes.importDraft(
        admin,
        jsonEncode(fixture(tier: 'topPick')),
      );
      await InvestmentNotes.publish(
        admin,
        top['id'] as int,
        top['digest'] as String,
      );
      final locked = await InvestmentNotes.detail(anonymous, top['id'] as int);
      expect(locked!['title'], '멤버십 탑픽');
      expect(locked.containsKey('corpCode'), false);
      expect(InvestmentNoteContent.parse(payload)['tier'], 'watchlist');
    });
  });
}

// Uses the pinned 4.0.0 SDK's test constructor. No generated files are edited.
class _NotesTestEndpoints implements InternalTestEndpoints {
  @override
  void initialize(
    DatabaseSerializationManager serializationManager,
    EndpointDispatch endpoints,
  ) {}
}
