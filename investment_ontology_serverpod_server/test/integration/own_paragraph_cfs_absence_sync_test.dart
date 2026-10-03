import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/own_paragraph_cfs_absence.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';

import 'auth_test_sessions.dart';
import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Four exact own CFS paragraphs', (builder, endpoints) {
    for (final profile in OwnParagraphCfsAbsence.profiles) {
      test(
        'normal ${profile['receipt']} CFS absence preserves independent OFS and replay',
        () async {
          final s = builder.asAdmin.build();
          final now = DateTime.utc(2026, 10, 3);
          final e = VerifiedAnnualSourceRegistry.find(
            profile['receipt'] as String,
            FsDiv.consolidated,
          )!;
          expect(e.ruleVersion, 'own-paragraph-exact-cfs-absence-v1');
          final company = await Company.db.insertRow(
            s,
            Company(
              corpCode: e.corpCode,
              name: e.companyName,
              stockCode: '000001',
              market: Market.konex,
              fiscalMonth: 12,
            ),
          );
          await ApiCallUsage.db.insertRow(
            s,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-03',
              calls: 20000,
            ),
          );
          final original = await DartFiling.db.insertRow(
            s,
            DartFiling(
              companyId: company.id,
              corpCode: company.corpCode,
              rceptNo: e.receipt,
              bsnsYear: e.year,
              reportCode: FinancialReportCode.annual,
              reportName: '사업보고서 (${e.year}.12)',
              consolidatedStatus: FilingFetchStatus.failed,
              separateStatus: FilingFetchStatus.failed,
              attempts: 3,
              lastError:
                  'api-noData-annual-public:attempt=3; preserved original',
              discoveredAt: now,
            ),
          );
          Future<IngestJob> run() async {
            final job = await IngestJob.db.insertRow(
              s,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            final client = SourceClient();
            await FinancialFactsSync(
              s,
              client,
              job.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
            ).run();
            expect(client.calls, 0);
            return (await IngestJob.db.findById(s, job.id!))!;
          }

          await run();
          final filing = (await DartFiling.db.findById(s, original.id!))!;
          expect(filing.consolidatedStatus, FilingFetchStatus.noData);
          final opposite = VerifiedAnnualSourceRegistry.find(
            e.receipt,
            FsDiv.separate,
          );
          expect(
            filing.separateStatus,
            opposite == null
                ? FilingFetchStatus.failed
                : FilingFetchStatus.stored,
          );
          expect(filing.attempts, 3);
          expect(filing.lastError, contains('attempt=3'));
          final absence = (await Source.db.find(
            s,
            where: (t) => t.reference.equals(
              'financial-public-basis-not-applicable:${e.receipt}:consolidated',
            ),
          )).single;
          final payload = jsonDecode(absence.title) as Map;
          expect(absence.kind, SourceKind.dartReport);
          expect(absence.url, profile['body']);
          expect(payload['receipt'], e.receipt);
          expect(payload['corpCode'], e.corpCode);
          expect(payload['fsDiv'], 'consolidated');
          expect(payload['evidence'], profile['evidence']);
          expect(
            payload['periodStart'],
            DateTime.utc(e.year).toIso8601String(),
          );
          expect(
            payload['periodEnd'],
            DateTime.utc(e.year, 12, 31).toIso8601String(),
          );
          expect(payload['coverSource'], profile['cover']);
          expect(payload['statementSource'], profile['body']);
          final ownAbsenceManifest = jsonDecode(
            File('${e.assetDirectory}/manifest.json').readAsStringSync(),
          ) as Map;
          final exactFiles = (ownAbsenceManifest['sources'] as List);
          final coverFile = exactFiles.singleWhere(
            (v) => v['label'] == 'cover',
          );
          final bodyFile = exactFiles.singleWhere(
            (v) => v['label'] == e.statementLabel,
          );
          final coverText = File('${e.assetDirectory}/${coverFile['file']}')
              .readAsStringSync();
          final bodyText = File('${e.assetDirectory}/${bodyFile['file']}')
              .readAsStringSync();
          expect(
            sha256.convert(utf8.encode(coverText)).toString(),
            profile['coverSHA'],
          );
          expect(
            sha256.convert(utf8.encode(bodyText)).toString(),
            profile['bodySHA'],
          );
          expect(
            payload['sha256'],
            sha256.convert(utf8.encode('$coverText\n$bodyText')).toString(),
          );
          final reports = await FinancialReport.db.find(s);
          expect(reports.where((r) => r.fsDiv == FsDiv.consolidated), isEmpty);
          expect(reports, hasLength(opposite == null ? 0 : 1));
          final facts = await FinancialFact.db.find(s);
          if (opposite == null) {
            expect(facts, isEmpty);
          } else {
            final report = reports.single;
            expect(report.rceptNo, opposite.receipt);
            expect(report.fsDiv, FsDiv.separate);
            final source = (await Source.db.findById(s, report.sourceId))!;
            final manifest = jsonDecode(
              File('${opposite.assetDirectory}/manifest.json')
                  .readAsStringSync(),
            ) as Map;
            final ownBody = (manifest['sources'] as List).singleWhere(
              (v) => v['label'] == opposite.statementLabel,
            );
            expect(source.url, ownBody['url']);
            expect(source.id, isNot(absence.id));
            expect(facts, isNotEmpty);
            expect(
              facts.every(
                (f) =>
                    f.fsDiv == FsDiv.separate &&
                    f.reportId == report.id &&
                    f.sourceId == source.id,
              ),
              isTrue,
            );
            expect(facts.any((f) => f.sourceId == absence.id), isFalse);
          }
          expect(
            await Source.db.find(
              s,
              where: (t) => t.reference.equals(e.auditReference),
            ),
            hasLength(1),
          );
          final sourcesBefore = [
            for (final row in await Source.db.find(s, orderBy: (t) => t.id))
              row.toJson(),
          ];
          final factsBefore = [
            for (final row in await FinancialFact.db.find(
              s,
              orderBy: (t) => t.id,
            ))
              row.toJson(),
          ];
          final ledgerBefore = filing.toJson();
          final replay = await run();
          expect(replay.updated, 0);
          expect([
            for (final row in await Source.db.find(s, orderBy: (t) => t.id))
              row.toJson(),
          ], sourcesBefore);
          expect([
            for (final row in await FinancialFact.db.find(
              s,
              orderBy: (t) => t.id,
            ))
              row.toJson(),
          ], factsBefore);
          expect(
            (await DartFiling.db.findById(s, original.id!))!.toJson(),
            ledgerBefore,
          );
          expect((await ApiCallUsage.db.find(s)).single.calls, 20000);
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );
    }
  });
}
