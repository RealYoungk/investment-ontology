import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/production_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/rnd_facts.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/disclosure/supplier_relations.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

const production = '''
(단위 : 톤, %)
품목 | 생산능력 | 생산실적 | 가동률
철강 | 100 | 80 | 80%
''';
const research = '''
연구개발비용
(단위 : 백만원)
과목 | 2025년 | 2024년 | 2023년
매 출 액 | 1000 | 1000 | 1000
연구개발비용 계 | 100 | 100 | 100
연구개발비 / 매출액 비율 | 10.0% | 10.0% | 10.0%
''';
void main() {
  withServerpod(
    'Given atomic rule replay',
    rollbackDatabase: RollbackDatabase.disabled,
    (builder, _) {
      var seq = 0;
      Future<BusinessDocument> seed(String text) async {
        final s = builder.build();
        final key = (++seq).toString().padLeft(8, '0');
        final company = await Company.db.insertRow(
          s,
          Company(corpCode: key, name: '제조회사$key', market: Market.kospi),
        );
        final source = await Source.db.insertRow(
          s,
          Source(
            kind: SourceKind.dartReport,
            title: 'fixture',
            retrievedAt: DateTime.now(),
          ),
        );
        final report = await DisclosureReport.db.insertRow(
          s,
          DisclosureReport(
            companyId: company.id!,
            section: DartSection.businessContent,
            rceptNo: key,
            bsnsYear: 2025,
            reportCode: FinancialReportCode.annual,
            rowCount: 1,
            sourceId: source.id!,
            fetchedAt: DateTime.now(),
          ),
        );
        return BusinessDocument.db.insertRow(
          s,
          BusinessDocument(
            reportId: report.id!,
            companyId: company.id!,
            bsnsYear: 2025,
            rceptNo: key,
            title: 'fixture',
            text: text,
            charCount: text.length,
          ),
        );
      }

      Future<List<DocumentFact>> facts(BusinessDocument d) => DocumentFact.db
          .find(builder.build(), where: (t) => t.documentId.equals(d.id!));
      Future<BusinessDocument> update(BusinessDocument d, String text) =>
          BusinessDocument.db.updateRow(
            builder.build(),
            d.copyWith(text: text, charCount: text.length),
          );

      test('concurrent production replay creates one set and replaces changed values', () async {
        final d = await seed(production);
        await Future.wait([
          for (var i = 0; i < 8; i++) ProductionFacts.store(builder.build(), d),
        ]);
        expect(await facts(d), hasLength(3));
        final changed = await update(
          d,
          production.replaceAll('100 | 80 | 80%', '200 | 100 | 50%'),
        );
        // Deliberately pass a stale in-memory document; the locked DB row wins.
        await ProductionFacts.store(builder.build(), d);
        final current = await facts(changed);
        expect(
          current.singleWhere((f) => f.kind == DocumentFactKind.capacity).value,
          200,
        );
        expect(
          current
              .singleWhere((f) => f.kind == DocumentFactKind.utilization)
              .value,
          50,
        );
      });
      test(
        'removed tables retract automatic values but preserve human decisions',
        () async {
          var d = await seed(production);
          await ProductionFacts.store(builder.build(), d);
          final keep = (await facts(d)).first;
          await DocumentFact.db.updateRow(
            builder.build(),
            keep.copyWith(reviewedBy: null),
          );
          d = await update(d, '생산 표 없음');
          await ProductionFacts.store(builder.build(), d);
          expect((await facts(d)).map((f) => f.id), [keep.id]);
        },
      );
      test(
        'R&D and production own separate kinds and both retract missing tables',
        () async {
          var d = await seed('$production\n$research');
          await Future.wait([
            ProductionFacts.store(builder.build(), d),
            RndFacts.store(builder.build(), d),
            RndFacts.store(builder.build(), d),
          ]);
          expect(await facts(d), hasLength(9));
          d = await update(d, production);
          await RndFacts.store(builder.build(), d);
          expect(await facts(d), hasLength(3));
        },
      );
      test(
        'supplier replay serializes and preserves a human-reviewed relation',
        () async {
          var d = await seed('주요 매출처는 Tesla입니다.');
          await Future.wait([
            for (var i = 0; i < 6; i++)
              SupplierRelations.store(builder.build(), d),
          ]);
          Future<List<OntologyRelation>> relations() =>
              OntologyRelation.db.find(
                builder.build(),
                where: (t) =>
                    t.factKind.equals(RelationFactKind.businessDocument) &
                    t.factId.equals(d.id!),
              );
          final rows = await relations();
          expect(rows, hasLength(1));
          await OntologyRelation.db.updateRow(
            builder.build(),
            rows.single.copyWith(reviewedBy: null),
          );
          d = await update(d, '거래처 비공개');
          await SupplierRelations.store(builder.build(), d);
          expect((await relations()).single.id, rows.single.id);
        },
      );
      test(
        'supplier replay retracts stale automatic edges when table disappears',
        () async {
          var d = await seed('주요 매출처는 Tesla입니다.');
          expect(await SupplierRelations.store(builder.build(), d), 1);
          d = await update(d, '거래처 비공개');
          await SupplierRelations.store(builder.build(), d);
          expect(
            await OntologyRelation.db.count(
              builder.build(),
              where: (t) =>
                  t.factId.equals(d.id!) &
                  t.factKind.equals(RelationFactKind.businessDocument),
            ),
            0,
          );
        },
      );
    },
  );
}
