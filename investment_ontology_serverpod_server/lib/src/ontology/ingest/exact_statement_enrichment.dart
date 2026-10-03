import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/exact_statement_rows.dart';
import 'financial_rows.dart';

/// Called only by the normal financial collection worker. Original core facts,
/// report source and all historical/source rows remain immutable.
abstract final class ExactStatementEnrichment {
  static Future<int> append(
    Session session, {
    required int jobId,
    required FinancialReport report,
    required DartFiling filing,
    required Company company,
    required ExactStatementRows prepared,
  }) async {
    if (!ExactStatementRows.eligible(filing.rceptNo, report.fsDiv) ||
        filing.rceptNo != prepared.receipt ||
        company.corpCode != prepared.corpCode ||
        filing.companyId != company.id ||
        report.companyId != company.id ||
        report.rceptNo != prepared.receipt ||
        report.bsnsYear != prepared.year ||
        report.fsDiv != prepared.basis ||
        report.reportCode != FinancialReportCode.annual ||
        report.supersededById != null ||
        report.reportName != filing.reportName) {
      throw const FormatException('Exact enrichment report identity mismatch');
    }
    return session.db.transaction((tx) async {
      final job = await IngestJob.db.findById(
        session,
        jobId,
        transaction: tx,
        lockMode: LockMode.forShare,
      );
      if (job == null ||
          job.status != IngestStatus.running ||
          !const {
            'financial_facts',
            'financial_facts_company',
          }.contains(job.kind)) {
        return 0;
      }
      final currentFiling = await DartFiling.db.findById(
        session,
        filing.id!,
        transaction: tx,
        lockMode: LockMode.forShare,
      );
      // Same order as cached replay: filing lock -> period supersession lock
      // -> report lock. This also excludes concurrent correction supersession.
      await session.db.unsafeQuery(
        'SELECT pg_advisory_xact_lock(461101, hashtext(@key))',
        parameters: QueryParameters.named({
          'key': '${company.id}:${prepared.year}:annual:${prepared.basis.name}',
        }),
        transaction: tx,
      );
      final current = await FinancialReport.db.findById(
        session,
        report.id!,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      final currentCompany = await Company.db.findById(
        session,
        company.id!,
        transaction: tx,
        lockMode: LockMode.forShare,
      );
      if (current == null ||
          currentFiling == null ||
          currentCompany == null ||
          current.sourceId != report.sourceId ||
          current.companyId != company.id ||
          current.rceptNo != prepared.receipt ||
          current.bsnsYear != prepared.year ||
          current.fsDiv != prepared.basis ||
          current.supersededById != null ||
          current.reportCode != FinancialReportCode.annual ||
          current.reportName != filing.reportName ||
          currentFiling.rceptNo != filing.rceptNo ||
          currentFiling.companyId != company.id ||
          currentFiling.corpCode != company.corpCode ||
          currentFiling.bsnsYear != prepared.year ||
          currentFiling.reportCode != FinancialReportCode.annual ||
          currentFiling.reportName != filing.reportName ||
          currentCompany.corpCode != company.corpCode ||
          currentCompany.name != company.name ||
          (prepared.basis == FsDiv.separate
                  ? currentFiling.separateStatus
                  : currentFiling.consolidatedStatus) !=
              FilingFetchStatus.stored) {
        throw const FormatException(
          'Exact enrichment changed during preparation',
        );
      }
      final original = await Source.db.findById(
        session,
        current.sourceId,
        transaction: tx,
      );
      if (original == null ||
          original.kind != SourceKind.dartReport ||
          original.reference != prepared.receipt ||
          original.url != prepared.primary.statementSource.toString() ||
          !original.title.startsWith('DART 원문 HTML 부분 핵심계정') ||
          !original.title.contains('SHA256:${prepared.primary.sourceDigest}')) {
        throw const FormatException(
          'Exact enrichment requires original pinned HTML core',
        );
      }
      final old = await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(current.id!),
        transaction: tx,
      );
      final originalFacts = old
          .where((f) => f.sourceId == original.id)
          .toList();
      if (originalFacts.length != 8 ||
          prepared.coreRows.length != 8 ||
          originalFacts.any((f) => f.supersededById != null) ||
          prepared.coreRows.any(
            (r) =>
                originalFacts
                    .where(
                      (f) =>
                          f.statement ==
                              FinancialCodes.statementFromDart(r['sj_div']) &&
                          compact(f.accountName) ==
                              compact(r['account_nm'].toString()) &&
                          f.amount?.toString() == r['thstrm_amount'] &&
                          f.currency == 'KRW' &&
                          f.accountId == null &&
                          f.companyId == company.id &&
                          f.bsnsYear == prepared.year &&
                          f.fsDiv == prepared.basis &&
                          f.reportCode == FinancialReportCode.annual &&
                          f.accountDetail == null &&
                          f.periodName == r['thstrm_nm'] &&
                          f.priorAmount == null &&
                          f.beforePriorAmount == null &&
                          f.cumulativeAmount == null,
                    )
                    .length !=
                1,
          )) {
        throw const FormatException('Exact enrichment original core changed');
      }
      final reference =
          '${ExactStatementRows.rule}:${current.id}:${prepared.primary.sourceDigest}';
      final previous = await Source.db.findFirstRow(
        session,
        where: (t) => t.reference.equals(reference),
        transaction: tx,
      );
      final expectedPayload = {
        ...prepared.payload,
        'originalSourceId': original.id,
        'originalFactIds': originalFacts.map((f) => f.id!).toList()..sort(),
      };
      final title = 'DART 원문 HTML 당기 추가행 · ${jsonEncode(expectedPayload)}';
      if (previous != null &&
          (previous.title != title ||
              previous.kind != SourceKind.dartReport ||
              previous.url != prepared.primary.statementSource.toString())) {
        throw const FormatException('Immutable enrichment source mismatch');
      }
      if (previous == null && old.length != originalFacts.length) {
        throw const FormatException('Unproven extra facts already exist');
      }
      final source =
          previous ??
          await Source.db.insertRow(
            session,
            Source(
              kind: SourceKind.dartReport,
              title: title,
              reference: reference,
              url: prepared.primary.statementSource.toString(),
              retrievedAt: DateTime.now().toUtc(),
            ),
            transaction: tx,
          );
      final converted = FinancialRows.toFacts(
        prepared.rows,
        reportId: current.id!,
        companyId: company.id!,
        bsnsYear: prepared.year,
        reportCode: FinancialReportCode.annual,
        fsDiv: prepared.basis,
        sourceId: source.id!,
      );
      if (converted.invalidAmounts != 0 ||
          converted.skippedRows != 0 ||
          converted.facts.length != prepared.rows.length ||
          converted.facts.any(
            (f) =>
                f.amount == null ||
                f.accountId != null ||
                f.currency != 'KRW' ||
                f.priorAmount != null ||
                f.cumulativeAmount != null,
          )) {
        throw const FormatException('Exact enrichment conversion incomplete');
      }
      if (previous != null) {
        final added = old.where((f) => f.sourceId == source.id).toList();
        if (old.length != originalFacts.length + converted.facts.length ||
            added.length != converted.facts.length ||
            converted.facts.any(
              (f) => added.where((a) => same(a, f)).length != 1,
            ) ||
            current.factCount != old.length) {
          throw const FormatException(
            'Exact enrichment stored coordinates changed',
          );
        }
        return 0;
      }
      await FinancialFact.db.insert(session, converted.facts, transaction: tx);
      await FinancialReport.db.updateRow(
        session,
        current.copyWith(factCount: old.length + converted.facts.length),
        transaction: tx,
      );
      return converted.facts.length;
    });
  }

  static String compact(String s) => s.replaceAll(RegExp(r'\s+'), '');
  static bool same(FinancialFact a, FinancialFact b) =>
      a.reportId == b.reportId &&
      a.companyId == b.companyId &&
      a.bsnsYear == b.bsnsYear &&
      a.reportCode == b.reportCode &&
      a.fsDiv == b.fsDiv &&
      a.statement == b.statement &&
      a.accountName == b.accountName &&
      a.accountId == b.accountId &&
      a.accountDetail == b.accountDetail &&
      a.ord == b.ord &&
      a.periodName == b.periodName &&
      a.amount == b.amount &&
      a.currency == b.currency &&
      a.sourceId == b.sourceId &&
      a.supersededById == null &&
      a.priorAmount == null &&
      a.priorQuarterAmount == null &&
      a.beforePriorAmount == null &&
      a.cumulativeAmount == null &&
      a.priorCumulativeAmount == null;
}
