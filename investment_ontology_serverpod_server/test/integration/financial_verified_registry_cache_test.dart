import 'dart:convert';

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/header18_linked_primary_source.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_facts_sync.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/pureun_six_core_profile.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'package:investment_ontology_serverpod_server/src/ontology/dart/linked_correction_audit_source.dart';

import 'financial_html_company_title_formats_test.dart' show SourceClient;
import 'auth_test_sessions.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Registry cache normal admin ingest', (builder, endpoints) {
    for (final entry in VerifiedAnnualSourceRegistry.entries) {
      final scenarios = [
        entry.ruleVersion == 'source-six-with-unavailable-whole-revenue-v1'
            ? 'pending-rejection-and-rerun'
            : 'success-and-rerun',
        if ({
          '20260429001010',
          '20250320001633',
          '20230714000217',
          '20240319000287',
          '20240320000248',
          '20230323000586',
        }.contains(entry.receipt))
          'sha-failed-and-rerun',
        if (entry.receipt == '20260323000661' ||
            entry.receipt == '20260323000763') ...[
          'sha-failed-and-rerun',
          'cancel-during-read',
          'newer-final-receipt',
        ],
      ];
      for (final scenario in scenarios) {
        test('${entry.receipt}:${entry.basis.name}:$scenario', () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          final company = await Company.db.insertRow(
            session,
            Company(
              corpCode: entry.corpCode,
              name: entry.companyName,
              stockCode: '123456',
              fiscalMonth: 12,
              market: Market.konex,
            ),
          );
          final opposite = entry.basis == FsDiv.consolidated
              ? FsDiv.separate
              : FsDiv.consolidated;
          String? dtoPath;
          if (entry.receipt == '20260323000763') dtoPath = 'test/fixtures/financial_html/elivision-cfs-none/20260323000763/stored-ofs-public-dto.json';
          if (entry.receipt == VerifiedAnnualSourceCache.receipt) dtoPath = 'test/fixtures/financial_html/talos-current/stored-ofs-public-dto.json';
          if (entry.receipt == VerifiedAnnualSourceCache.pimReceipt) dtoPath = 'test/fixtures/financial_html/pim-cfs-whole-ce/stored-ofs-public-dto.json';
          final dto = dtoPath == null
              ? null
              : jsonDecode(File(dtoPath).readAsStringSync()) as Map;
          // Public DTO when available; otherwise explicitly synthetic preservation sentinel.
          final oldSource = await Source.db.insertRow(
            session,
            dto == null
                ? Source(
                    kind: SourceKind.dartReport,
                    reference: entry.receipt,
                    url:
                        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${entry.receipt}',
                    title: 'Synthetic opposite-basis preservation sentinel',
                    retrievedAt: now,
                  )
                : Source.fromJson(Map<String, dynamic>.from(dto['source']))
                      .copyWith(id: null),
          );
          final oldReport = await FinancialReport.db.insertRow(
            session,
            dto == null
                ? FinancialReport(
                    companyId: company.id!,
                    rceptNo: entry.receipt,
                    fsDiv: opposite,
                    bsnsYear: entry.year,
                    reportCode: FinancialReportCode.annual,
                    reportName:
                        '사업보고서 (${entry.year}.${entry.periodEnd.month.toString().padLeft(2, '0')})',
                    factCount: 1,
                    invalidAmountCount: 0,
                    sourceId: oldSource.id!,
                    fetchedAt: now,
                  )
                : FinancialReport.fromJson(
                    Map<String, dynamic>.from(dto['report']),
                  ).copyWith(
                    id: null,
                    companyId: company.id!,
                    sourceId: oldSource.id!,
                  ),
          );
          final oldFacts = await FinancialFact.db.insert(
            session,
            dto == null
                ? [
                    FinancialFact(
                      companyId: company.id!,
                      reportId: oldReport.id!,
                      bsnsYear: entry.year,
                      reportCode: FinancialReportCode.annual,
                      fsDiv: opposite,
                      statement: FinancialStatementKind.balanceSheet,
                      accountId: 'ifrs-full_Assets',
                      accountName: '합성 보존값',
                      amount: BigInt.from(1234567),
                      currency: 'KRW',
                      sourceId: oldSource.id!,
                    ),
                  ]
                : (dto['facts'] as List)
                      .map(
                        (r) =>
                            FinancialFact.fromJson(Map<String, dynamic>.from(r))
                                .copyWith(
                                  id: null,
                                  companyId: company.id!,
                                  reportId: oldReport.id!,
                                  sourceId: oldSource.id!,
                                ),
                      )
                      .toList(),
          );
          final sourceBefore = oldSource.toJson(),
              reportBefore = oldReport.toJson(),
              factsBefore = [for (final f in oldFacts) f.toJson()];
          final target = await DartFiling.db.insertRow(
            session,
            DartFiling(
              companyId: company.id,
              corpCode: entry.corpCode,
              rceptNo: entry.receipt,
              reportName:
                  '사업보고서 (${entry.year}.${entry.periodEnd.month.toString().padLeft(2, '0')})',
              bsnsYear: entry.year,
              reportCode: FinancialReportCode.annual,
              consolidatedStatus: entry.basis == FsDiv.consolidated
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              separateStatus: entry.basis == FsDiv.separate
                  ? FilingFetchStatus.failed
                  : FilingFetchStatus.stored,
              attempts: 7,
              lastError: 'api-noData-annual-public:attempt=3; original failure',
              discoveredAt: now,
            ),
          );
          if (scenario == 'newer-final-receipt') {
            await DartFiling.db.insertRow(
              session,
              target.copyWith(
                id: null,
                rceptNo: '20260930009999',
                consolidatedStatus: FilingFetchStatus.noData,
                separateStatus: FilingFetchStatus.noData,
              ),
            );
          }
          var reads = 0, runs = 0;
          Future<void> run() async {
            final job = await IngestJob.db.insertRow(
              session,
              IngestJob(
                kind: FinancialFactsSync.kind,
                status: IngestStatus.running,
                startedAt: now,
              ),
            );
            final client = SourceClient();
            final cache = VerifiedAnnualSourceCache(
              readAsset: (path) async {
                reads++;
                if (scenario == 'cancel-during-read' && reads == 1) {
                  await IngestJob.db.updateRow(
                    session,
                    job.copyWith(status: IngestStatus.cancelled),
                  );
                }
                final bytes = await File(path).readAsBytes();
                return scenario == 'sha-failed-and-rerun' &&
                        path.endsWith('manifest.json')
                    ? [...bytes, 32]
                    : bytes;
              },
            );
            await FinancialFactsSync(
              session,
              client,
              job.id!,
              dailyBudget: 0,
              clock: () => now,
              callInterval: Duration.zero,
              sourceCache: cache,
            ).run();
            expect(client.calls, 0);
            expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
            final finished = (await IngestJob.db.findById(session, job.id!))!;
            final numeric =
                scenario == 'success-and-rerun' &&
                    runs == 0 &&
                    entry.absenceLiteral == null
                ? 1
                : 0;
            expect(finished.updated, numeric);
            if (scenario != 'cancel-during-read') {
              expect(finished.message, contains('저장한 재무제표 $numeric벌'));
            }
            runs++;
          }

          await run();
          final firstReads = reads;
          final ledger = (await DartFiling.db.findById(session, target.id!))!;
          expect(ledger.attempts, 7);
          expect(
            ledger.lastError,
            contains('api-noData-annual-public:attempt=3;'),
          );
          final audits = await Source.db.find(
            session,
            where: (t) => t.reference.equals(entry.auditReference),
          );
          final actualReceipt =
              entry.ruleVersion == Header18LinkedPrimarySource.primaryRule
              ? Header18LinkedPrimarySource
                        .profiles['${entry.receipt}:${entry.statementLabel}']!['money']
                    as String
              : entry.ruleVersion == 'linked-correction-audit-immutable-v1'
              ? LinkedCorrectionAuditSource.originalFor(entry.receipt)
              : entry.receipt;
          final sourceReports = await FinancialReport.db.find(
            session,
            where: (t) =>
                t.rceptNo.equals(actualReceipt) & t.fsDiv.equals(entry.basis),
          );
          final result = entry.basis == FsDiv.consolidated
              ? ledger.consolidatedStatus
              : ledger.separateStatus;
          if (scenario == 'success-and-rerun') {
            expect(audits.length, 1);
            expect(
              result,
              entry.absenceLiteral == null
                  ? FilingFetchStatus.stored
                  : FilingFetchStatus.noData,
            );
            final audit = jsonDecode(audits.single.title);
            expect(audit['manifestDigest'], entry.manifestDigest);
            expect(audit['fsDiv'], entry.basis.name);
            expect(audit['networkRequests'], 0);
            expect(audit['apiCalls'], 0);
            if (entry.absenceLiteral == null) {
              expect(sourceReports.length, 1);
              final report = sourceReports.single;
              final source = (await Source.db.findById(
                session,
                report.sourceId,
              ))!;
              final manifest = jsonDecode(
                File('${entry.assetDirectory}/manifest.json')
                    .readAsStringSync(),
              );
              final statement = (manifest['sources'] as List).singleWhere(
                (s) =>
                    s['label'] ==
                    (entry.ruleVersion ==
                            Header18LinkedPrimarySource.primaryRule
                        ? (manifest['sourceRole'] ==
                                  'original_primary_with_current_audit_witness'
                              ? 'primary'
                              : 'audit')
                        : entry.statementLabel),
              );
              expect(source.reference, actualReceipt);
              expect(source.url, statement['url']);
              final cover = File('${entry.assetDirectory}/cover.html')
                      .readAsStringSync(),
                  body = File(
                    '${entry.assetDirectory}/${statement['file']}',
                  ).readAsStringSync();
              expect(
                source.title,
                contains(
                  'SHA256:${sha256.convert(utf8.encode('$cover\n$body'))}',
                ),
              );
              final facts = await FinancialFact.db.find(
                session,
                where: (t) => t.reportId.equals(report.id!),
              );
              if (entry.ruleVersion == 'db-exact-self-declared-issuer-v1') {
                expect(report.bsnsYear, 2021);
                expect(report.fsDiv, FsDiv.separate);
                expect(facts.length, 8);
                expect(
                  facts.singleWhere((f) => f.accountName == '영업수익').amount,
                  BigInt.parse('1278947330226'),
                );
                expect(
                  facts.singleWhere((f) => f.accountName == '당기순이익').amount,
                  BigInt.parse('97649026187'),
                );
                final identityAudit = (await Source.db.findFirstRow(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:separate',
                  ),
                ))!;
                final provenance =
                    jsonDecode(identityAudit.title)['coreRowProvenance']
                        as List;
                expect(
                  provenance.every(
                    (row) =>
                        row['html_provenance']['exactIssuerIdentity']['corpCode'] ==
                        '00115694',
                  ),
                  isTrue,
                );
                expect(
                  provenance
                      .first['html_provenance']['exactIssuerIdentity']['selfDeclaredName'],
                  '디비금융투자 주식회사',
                );
              }
              if (entry.receipt == LinkedCorrectionAuditSource.bonTarget &&
                  entry.basis == FsDiv.separate) {
                expect(report.rceptNo, LinkedCorrectionAuditSource.bonOriginal);
                expect(report.bsnsYear, 2025);
                final expected = jsonDecode(
                  File('${entry.assetDirectory}/expected-rows.json')
                      .readAsStringSync(),
                ) as List;
                expect(facts, hasLength(7));
                for (final pair in expected) {
                  final fact = facts.singleWhere(
                    (f) => f.accountName == pair[0],
                  );
                  expect(fact.amount, BigInt.parse(pair[1] as String));
                  expect(fact.accountId, isNull);
                }
                final originAudit = await Source.db.findFirstRow(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${LinkedCorrectionAuditSource.bonOriginal}:separate',
                  ),
                );
                expect(originAudit, isNotNull);
                final payload = jsonDecode(originAudit!.title);
                final proofs = payload['coreRowProvenance'] as List;
                expect(proofs, hasLength(7));
                for (final row in proofs) {
                  final comparison =
                      row['html_provenance']['linkedTargetWholeCoreComparison'];
                  expect(comparison['targetReceipt'], entry.receipt);
                  expect(comparison['sourceReceipt'], actualReceipt);
                  expect(comparison['matchingDirectAccounts'], hasLength(7));
                  expect(comparison['allStatementValuesCompared'], false);
                }
              }
              if ({
                '20220323000557',
                '20240321001908',
                '20250321000964',
                '20260323001088',
              }.contains(entry.receipt)) {
                final expected = jsonDecode(
                  File('${entry.assetDirectory}/expected-rows.json')
                      .readAsStringSync(),
                ) as List;
                expect(facts, hasLength(8));
                for (final pair in expected) {
                  final fact = facts.singleWhere(
                    (f) => f.accountName == pair[0],
                  );
                  expect(fact.amount, BigInt.parse(pair[1] as String));
                  expect(fact.bsnsYear, entry.year);
                }
                final periodAudit = await Source.db.findFirstRow(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                  ),
                );
                expect(periodAudit, isNotNull);
                final payload = jsonDecode(periodAudit!.title);
                expect(payload['sourceReceipt'], entry.receipt);
                final provenance = payload['coreRowProvenance'] as List;
                expect(provenance, hasLength(8));
                for (final row in provenance) {
                  final proof =
                      row['html_provenance']['supportingPeriodEvidence'];
                  expect(
                    proof['policy'],
                    'contents-on-exact-cover-ce-cash-corroboration-v1',
                  );
                  expect(proof['flowCaptionPrintedStart'], false);
                  expect(proof['periodStart'], '${entry.year}-01-01');
                  expect(proof['periodEnd'], '${entry.year}-12-31');
                }
              }
              final exactPureunSix =
                  entry.receipt == PureunSixCoreProfile.receipt &&
                  entry.corpCode == PureunSixCoreProfile.corpCode &&
                  entry.year == 2022 &&
                  entry.basis == FsDiv.separate &&
                  entry.ruleVersion == 'pureun-exact-six-primary-raw-ce-v1';
              if (exactPureunSix) {
                expect(facts, hasLength(6));
                final accounts = FinancialAccounts.pick(facts);
                expect(
                  accounts.map((a) => a.key).toSet(),
                  PureunSixCoreProfile.amounts.keys.toSet(),
                );
                for (final a in accounts) {
                  expect(
                    a.amount,
                    BigInt.parse(PureunSixCoreProfile.amounts[a.key]!),
                  );
                }
                expect(
                  accounts.any((a) => a.key == 'revenue' || a.key == 'capex'),
                  isFalse,
                );
                expect(source.title, startsWith(PureunSixCoreProfile.title));
                final partialAudit = (await Source.db.find(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                  ),
                )).single;
                final partial = jsonDecode(partialAudit.title);
                expect(partial['coreRows'], 6);
                expect(partial['missingRequiredAccounts'], ['revenue']);
                expect(partial['uncollectedOptionalAccounts'], ['capex']);
                expect(
                  PureunSixCoreProfile.storedProof(
                    partial['coreRowProvenance'],
                    sourceDigest: partial['sha256'],
                    sourceUrl: source.url!,
                    companyCode: company.corpCode,
                    targetReceipt: report.rceptNo,
                    basis: report.fsDiv.name,
                    year: report.bsnsYear,
                    reportName: report.reportName,
                  ),
                  isTrue,
                );
                for (final row in partial['coreRowProvenance']) {
                  expect(
                    row['html_provenance']['pureunSixCore']['cePrintedUnit'],
                    'unknown',
                  );
                }
              } else {
                expect(facts.length, inInclusiveRange(7, 8));
              }
              expect(
                facts.every(
                  (f) =>
                      f.accountId == null &&
                      f.sourceId == source.id &&
                      f.currency == 'KRW',
                ),
                true,
              );
              final summary = await endpoints.financial.summary(
                builder,
                entry.corpCode,
                fsDiv: entry.basis,
              );
              if (entry.ruleVersion == 'exact-printed-current-annual-v1') {
                final cells =
                    jsonDecode(
                          File(
                            '${entry.assetDirectory}/current-cell-evidence.json',
                          ).readAsStringSync(),
                        )['rows']
                        as List;
                final keys = [
                  'assets',
                  'liabilities',
                  'equity',
                  'revenue',
                  'operatingIncome',
                  'netIncome',
                  'operatingCashFlow',
                ];
                expect(facts, hasLength(7));
                for (var i = 0; i < cells.length; i++) {
                  final cell = cells[i] as Map;
                  final fact = facts.singleWhere(
                    (f) => f.accountName == cell['printedLabel'],
                  );
                  expect(fact.amount, BigInt.parse(cell['amount'] as String));
                  final line = summary!.periods.single.lines.singleWhere(
                    (l) => l.key == keys[i],
                  );
                  expect(line.amount, fact.amount);
                  expect(line.accountName, fact.accountName);
                }
                final sql = await session.db.unsafeQuery(
                  'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
                );
                expect(sql.where((r) => r[0] != null), hasLength(7));
                final proofAudit = (await Source.db.find(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                  ),
                )).single;
                final proof = jsonDecode(proofAudit.title) as Map;
                expect(
                  (proof['coreRowProvenance'] as List).every(
                    (row) =>
                        row['html_provenance']['supportingPeriodEvidence']['flowCaptionPrintedStart'] ==
                        true,
                  ),
                  true,
                );
              }
              if (entry.ruleVersion == 'gne-own-audit-whole7-v1') {
                const expected = {
                  'assets': '6973822992',
                  'liabilities': '2274518676',
                  'equity': '4699304316',
                  'revenue': '4896995158',
                  'operatingIncome': '371658968',
                  'netIncome': '377901260',
                  'operatingCashFlow': '701750215',
                };
                expect(facts, hasLength(7));
                for (final value in expected.entries) {
                  expect(
                    summary!.periods.single.lines
                        .singleWhere((l) => l.key == value.key)
                        .amount,
                    BigInt.parse(value.value),
                  );
                }
                final sql = await session.db.unsafeQuery(
                  'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
                );
                expect(sql.where((r) => r[0] != null), hasLength(7));
                final audit = (await Source.db.find(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                  ),
                )).single;
                final rows =
                    jsonDecode(audit.title)['coreRowProvenance'] as List;
                expect(rows, hasLength(7));
                for (final row in rows) {
                  expect(
                    row['html_provenance']['sourceReceipt'],
                    entry.receipt,
                  );
                  expect(
                    row['html_provenance']['sourceRole'],
                    'exact-target-own-audit-primary',
                  );
                  expect(
                    row['html_provenance']['ceWholeProof']['wholeNetIncome'],
                    '377901260',
                  );
                }
              }
              if (entry.ruleVersion ==
                  Header18LinkedPrimarySource.primaryRule) {
                final expected = jsonDecode(
                  File('${entry.assetDirectory}/expected-rows.json')
                      .readAsStringSync(),
                ) as List;
                expect(facts, hasLength(expected.length));
                final keys = [
                  'assets',
                  'liabilities',
                  'equity',
                  'revenue',
                  'operatingIncome',
                  'netIncome',
                  'operatingCashFlow',
                  'capex',
                ];
                for (var i = 0; i < expected.length; i++) {
                  final row = expected[i] as Map;
                  final fact = facts.singleWhere(
                    (f) => f.accountName == row['account_nm'],
                  );
                  expect(
                    fact.amount,
                    BigInt.parse(row['thstrm_amount'] as String),
                  );
                  expect(fact.reportId, report.id);
                  expect(report.rceptNo, actualReceipt);
                  expect(fact.bsnsYear, entry.year);
                  final line = summary!.periods.single.lines.singleWhere(
                    (l) => l.key == keys[i],
                  );
                  expect(line.amount, fact.amount);
                  expect(line.accountName, fact.accountName);
                }
                final sql = await session.db.unsafeQuery(
                  'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
                );
                expect(
                  sql.where((r) => r[0] != null),
                  hasLength(expected.length),
                );
                expect(
                  sql.where((r) => r[0] == 'ifrs-full_ProfitLoss'),
                  hasLength(1),
                );
                final scopeAudit = (await Source.db.find(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                  ),
                )).single;
                final scope = jsonDecode(scopeAudit.title);
                expect(scope['sourceReceipt'], actualReceipt);
                for (final row in scope['coreRowProvenance']) {
                  final proof = row['html_provenance']['linkedPrimaryEvidence'];
                  expect(proof['targetReceipt'], entry.receipt);
                  expect(proof['sourceReceipt'], actualReceipt);
                  expect(proof['sourceRole'], manifest['sourceRole']);
                  expect(
                    proof['originalCoverReceipt'],
                    manifest['originalReceipt'],
                  );
                  expect(proof['kind'], switch (manifest['sourceRole']) {
                    'same_receipt_audit' =>
                      'exact-original-receipt-audit-with-correction-family',
                    'corrected_audit' =>
                      'exact-corrected-audit-with-original-cover',
                    _ => 'exact-original-primary-with-current-audit-witness',
                  });
                  expect(proof['auditSource'], isNotEmpty);
                  expect(proof['auditSha256'], hasLength(64));
                }
              }

              if ({
                '20220310001159',
                '20230309000772',
              }.contains(entry.receipt)) {
                final expected = jsonDecode(
                  File('${entry.assetDirectory}/expected-rows.json')
                      .readAsStringSync(),
                ) as List;
                expect(facts, hasLength(8));
                final keys = [
                  'assets',
                  'liabilities',
                  'equity',
                  'revenue',
                  'operatingIncome',
                  'netIncome',
                  'operatingCashFlow',
                  'capex',
                ];
                for (var i = 0; i < keys.length; i++) {
                  final f = facts.singleWhere(
                    (f) => f.accountName == expected[i][0],
                  );
                  expect(f.amount, BigInt.parse(expected[i][1]));
                  final line = summary!.periods.single.lines.singleWhere(
                    (l) => l.key == keys[i],
                  );
                  expect(line.amount, f.amount);
                  expect(line.accountName, f.accountName);
                }
                final sql = await session.db.unsafeQuery(
                  'SELECT ${FinancialAccounts.resolvedIdSql('f')} FROM financial_fact f WHERE f."reportId"=${report.id}',
                );
                expect(sql.where((r) => r[0] != null), hasLength(8));
                expect(
                  sql.where((r) => r[0] == 'ifrs-full_ProfitLoss'),
                  hasLength(1),
                );
                final sourceAudit = (await Source.db.find(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                  ),
                )).single;
                final coreRows =
                    jsonDecode(sourceAudit.title)['coreRowProvenance'] as List;
                final profit = coreRows.singleWhere(
                  (r) => r['account_nm'].toString().contains('당기순이익 (대손'),
                );
                expect(
                  profit['html_provenance']['wholeCoreProof']['printedProfitAnnotation'],
                  true,
                );
                if (entry.basis == FsDiv.consolidated) {
                  final proof = profit['html_provenance']['wholeCoreProof'];
                  expect(
                    proof['wholeCfsHierarchy'],
                    'own-parent-components5-nci6-whole-total7',
                  );
                  expect(proof['wholeCE']['wholeColumn'], 7);
                  expect(proof['wholeCE']['wholeProfit'], expected[5][1]);
                  expect(proof['wholeCE']['closingEquity'], expected[2][1]);
                  expect(
                    proof['wholeCE']['printedProfitCells'][6],
                    isNot(proof['wholeCE']['printedProfitCells'][7]),
                  );
                }

                expect(
                  profit['html_provenance']['printedCurrentCells'].where(
                    (c) => c.toString().replaceAll(',', '') == expected[5][1],
                  ),
                  hasLength(1),
                );
              }
              if ({
                '20240320000248',
                '20230323000586',
              }.contains(entry.receipt)) {
                final expected = entry.year == 2023
                    ? {
                        'revenue': '1123621115',
                        'operatingIncome': '-3961736811',
                        'netIncome': '-4419372266',
                        'assets': '7473929363',
                        'liabilities': '3939848819',
                        'equity': '3534080544',
                        'operatingCashFlow': '-3336089290',
                      }
                    : {
                        'revenue': '655390090',
                        'operatingIncome': '-6470740465',
                        'netIncome': '-7014810066',
                        'assets': '9264697013',
                        'liabilities': '3836415588',
                        'equity': '5428281425',
                        'operatingCashFlow': '-5385272003',
                      };
                for (final e in expected.entries) {
                  expect(
                    summary!.periods.single.lines
                        .singleWhere((l) => l.key == e.key)
                        .amount,
                    BigInt.parse(e.value),
                  );
                }
              }
              if (entry.receipt == '20250320001633') {
                final lines = summary!.periods.single.lines;
                final expected = entry.basis == FsDiv.consolidated
                    ? {
                        'revenue': '83805774666',
                        'operatingIncome': '-242762417908',
                        'netIncome': '-244070248163',
                        'assets': '243910853554',
                        'liabilities': '346677333242',
                        'equity': '-102766479688',
                        'operatingCashFlow': '-66690869744',
                      }
                    : {
                        'revenue': '74401016313',
                        'operatingIncome': '-245159821034',
                        'netIncome': '-246554897630',
                        'assets': '230642631079',
                        'liabilities': '335708768291',
                        'equity': '-105066137212',
                        'operatingCashFlow': '-66891998445',
                      };
                for (final pair in expected.entries) {
                  expect(
                    lines.singleWhere((l) => l.key == pair.key).amount,
                    BigInt.parse(pair.value),
                  );
                }
                expect(
                  facts.any(
                    (f) => f.accountName.contains(
                      entry.basis == FsDiv.consolidated
                          ? '매출액(주석17)'
                          : '매출액(주석19)',
                    ),
                  ),
                  true,
                );
              }
              if ({
                '20230714000217',
                '20240319000287',
              }.contains(entry.receipt)) {
                final cases = jsonDecode(
                  File(
                    entry.basis == FsDiv.consolidated
                        ? 'test/fixtures/financial_html/historical-cfs-source/cases.json'
                        : 'test/fixtures/financial_html/primary-historical-issuer/cases.json',
                  ).readAsStringSync(),
                ) as List;
                final proof = cases.singleWhere(
                  (p) => p['receipt'] == entry.receipt,
                );
                final expected = proof['expectedRows'] as List;
                expect(facts, hasLength(7));
                for (final pair in expected) {
                  final fact = facts.singleWhere(
                    (f) => f.accountName == pair[0],
                  );
                  expect(fact.amount, BigInt.parse(pair[1]));
                }
                final coreAudit = (await Source.db.find(
                  session,
                  where: (t) => t.reference.equals(
                    'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                  ),
                )).single;
                final rows =
                    jsonDecode(coreAudit.title)['coreRowProvenance'] as List;
                expect(rows, hasLength(7));
                for (final row in rows) {
                  final identity =
                      row['html_provenance']['primaryHistoricalIssuer'];
                  expect(identity['receipt'], entry.receipt);
                  expect(identity['corpCode'], entry.corpCode);
                  expect(identity['currentMasterName'], entry.companyName);
                  expect(identity['statementSource'], statement['url']);
                }
                const keys = [
                  'assets',
                  'liabilities',
                  'equity',
                  'revenue',
                  'operatingIncome',
                  'netIncome',
                  'operatingCashFlow',
                ];
                for (var i = 0; i < keys.length; i++) {
                  expect(
                    summary!.periods.single.lines
                        .singleWhere((l) => l.key == keys[i])
                        .amount,
                    BigInt.parse(expected[i][1]),
                  );
                }
              }
              expect(
                summary!.periods.single.lines
                    .singleWhere((l) => l.key == 'netIncome')
                    .amount,
                isNotNull,
              );
            } else {
              expect(sourceReports, isEmpty);
            }
            await run();
            expect(reads, firstReads);
            expect(
              (await Source.db.find(
                session,
                where: (t) => t.reference.equals(entry.auditReference),
              )).length,
              1,
            );
          } else if (scenario == 'pending-rejection-and-rerun') {
            expect(audits, hasLength(1));
            final payload = jsonDecode(audits.single.title);
            expect(payload['status'], 'failed');
            expect(
              payload['failureReason'],
              contains('storage pending approved partial metadata'),
            );
            expect(sourceReports, isEmpty);
            expect(result, FilingFetchStatus.failed);
            expect(
              await Source.db.find(
                session,
                where: (t) => t.reference.equals(
                  'financial-api-noData-source:${entry.receipt}:${entry.basis.name}',
                ),
              ),
              isEmpty,
            );
            final auditBefore = audits.single.toJson();
            await run();
            expect(reads, firstReads);
            final after = await Source.db.find(
              session,
              where: (t) => t.reference.equals(entry.auditReference),
            );
            expect(after, hasLength(1));
            expect(after.single.toJson(), auditBefore);
            final replayLedger = await DartFiling.db.findById(
              session,
              target.id!,
            );
            expect(replayLedger!.attempts, 7);
            expect(replayLedger.lastError, contains('attempt=3'));
          } else if (scenario == 'sha-failed-and-rerun') {
            expect(audits.length, 1);
            expect(jsonDecode(audits.single.title)['status'], 'failed');
            expect(sourceReports, isEmpty);
            expect(result, FilingFetchStatus.failed);
            await run();
            expect(reads, firstReads);
            expect(
              (await Source.db.find(
                session,
                where: (t) => t.reference.equals(entry.auditReference),
              )).length,
              1,
            );
          } else {
            expect(audits, isEmpty);
            expect(sourceReports, isEmpty);
            if (scenario == 'newer-final-receipt') expect(reads, 0);
          }
          expect(
            (await Source.db.findById(session, oldSource.id!))!.toJson(),
            sourceBefore,
          );
          expect(
            (await FinancialReport.db.findById(
              session,
              oldReport.id!,
            ))!.toJson(),
            reportBefore,
          );
          for (var i = 0; i < oldFacts.length; i++) {
            expect(
              (await FinancialFact.db.findById(
                session,
                oldFacts[i].id!,
              ))!.toJson(),
              factsBefore[i],
            );
          }
        });
      }
    }
    for (final failAll in [false, true]) {
      test(
        'registry shares maximum10 and circuit6 with bounded resume failAll=$failAll',
        () async {
          final session = builder.asAdmin.build(),
              now = DateTime.utc(2026, 10, 2);
          await ApiCallUsage.db.insertRow(
            session,
            ApiCallUsage(
              provider: ApiProvider.dart,
              day: '2026-10-02',
              calls: 20000,
            ),
          );
          final companies = <String, Company>{},
              filings = <String, DartFiling>{};
          for (final entry in VerifiedAnnualSourceRegistry.entries) {
            final company = companies[entry.corpCode] ??= await Company.db
                .insertRow(
                  session,
                  Company(
                    corpCode: entry.corpCode,
                    name: entry.companyName,
                    stockCode: '123456',
                    fiscalMonth: 12,
                    market: Market.konex,
                  ),
                );
            if (!filings.containsKey(entry.receipt)) {
              filings[entry.receipt] = await DartFiling.db.insertRow(
                session,
                DartFiling(
                  companyId: company.id,
                  corpCode: entry.corpCode,
                  rceptNo: entry.receipt,
                  reportName:
                      '사업보고서 (${entry.year}.${entry.periodEnd.month.toString().padLeft(2, '0')})',
                  bsnsYear: entry.year,
                  reportCode: FinancialReportCode.annual,
                  consolidatedStatus: FilingFetchStatus.failed,
                  separateStatus: FilingFetchStatus.failed,
                  attempts: 7,
                  lastError:
                      'api-noData-annual-public:attempt=3; original failure',
                  discoveredAt: now,
                ),
              );
            }
          }
          final job = await IngestJob.db.insertRow(
            session,
            IngestJob(
              kind: FinancialFactsSync.kind,
              status: IngestStatus.running,
              startedAt: now,
            ),
          );
          final client = SourceClient();
          final resumes = <DateTime>[];
          var reads = 0;
          final cache = VerifiedAnnualSourceCache(
            readAsset: (path) async {
              reads++;
              final bytes = await File(path).readAsBytes();
              return failAll && path.endsWith('manifest.json')
                  ? [...bytes, 32]
                  : bytes;
            },
          );
          await FinancialFactsSync(
            session,
            client,
            job.id!,
            dailyBudget: 0,
            clock: () => now,
            callInterval: Duration.zero,
            sourceCache: cache,
            scheduleResume: (at) async => resumes.add(at),
          ).run();
          final audits = await Source.db.find(
            session,
            where: (t) => t.reference.like('financial-cache-replay:%'),
          );
          expect(audits.length, failAll ? 6 : 10);
          expect(
            reads,
            failAll
                ? 6
                : audits.fold<int>(0, (sum, a) {
                    final data = jsonDecode(a.title);
                    final e = VerifiedAnnualSourceRegistry.find(
                      data['receipt'],
                      data['fsDiv'] == 'consolidated'
                          ? FsDiv.consolidated
                          : FsDiv.separate,
                    )!;
                    return sum +
                        4 +
                        (e.requiresIssuerOverview ? 1 : 0) +
                        (e.ruleVersion == 'same-receipt-audit-immutable-v1'
                            ? 1
                            : 0);
                  }),
          );
          expect(client.calls, 0);
          expect((await ApiCallUsage.db.find(session)).single.calls, 20000);
          final numeric = audits
              .where(
                (a) =>
                    jsonDecode(a.title)['status'] == 'completed-source-numeric',
              )
              .length;
          final finished = (await IngestJob.db.findById(session, job.id!))!;
          expect(finished.updated, numeric);
          expect(
            finished.message,
            contains(
              '고정 공식 원문 재검증 ${audits.length}건·남은 ${VerifiedAnnualSourceRegistry.entries.length - audits.length}건',
            ),
          );
          expect(resumes, [
            now.add(
              failAll
                  ? const Duration(minutes: 15)
                  : const Duration(seconds: 30),
            ),
          ]);
          for (final f in filings.values) {
            final after = (await DartFiling.db.findById(session, f.id!))!;
            expect(after.attempts, 7);
            expect(
              after.lastError,
              contains('api-noData-annual-public:attempt=3;'),
            );
          }
        },
        // Ten bounded packages retain the real one-second source cadence;
        // four-document packages need more than the default thirty seconds.
        timeout: const Timeout(Duration(seconds: 90)),
      );
    }
  });
}
