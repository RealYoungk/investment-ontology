import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_client.dart';
import '../dart/dart_report_name.dart';
import 'financial_rows.dart';

/// Repairs derived fiscal metadata only after a fresh exact-receipt response
/// reproduces every stored financial value. Original values and sources stay.
abstract final class FinancialPeriodRepair {
  static Future<bool> repair(
    Session session, {
    required FinancialReport existing,
    required DartFiling filing,
    required Company company,
    required FsDiv div,
    required List<Map<String, dynamic>> freshRows,
  }) async {
    if (existing.rceptNo != filing.rceptNo ||
        existing.companyId != company.id ||
        existing.fsDiv != div ||
        existing.reportCode != filing.reportCode ||
        existing.bsnsYear == filing.bsnsYear ||
        filing.bsnsYear == null ||
        !_samePeriod(existing.reportName, filing.reportName)) {
      return false;
    }
    final parsed = DartReportName.parse(filing.reportName);
    if (parsed == null ||
        parsed.resolve(company.fiscalMonth)?.bsnsYear != filing.bsnsYear) {
      return false;
    }
    final expectedYear = parsed.periodYear.toString();
    final expectedCode = FinancialCodes.reportCodeToDart(filing.reportCode!);
    if (freshRows.isEmpty ||
        freshRows.any(
          (r) =>
              r['rcept_no'] != filing.rceptNo ||
              r['corp_code'] != company.corpCode ||
              r['bsns_year'].toString() != expectedYear ||
              r['reprt_code'] != expectedCode,
        )) {
      return false;
    }
    return session.db.transaction((tx) async {
      // Same namespace as insertion. Lock both periods in a stable order.
      final keys = {
        '${company.id}:${existing.bsnsYear}:${existing.reportCode.name}:${div.name}',
        '${company.id}:${filing.bsnsYear}:${existing.reportCode.name}:${div.name}',
      }.toList()..sort();
      for (final key in keys) {
        await session.db.unsafeExecute(
          'SELECT pg_advisory_xact_lock(461101, hashtext(@key))',
          parameters: QueryParameters.named({'key': key}),
          transaction: tx,
        );
      }
      final current = await FinancialReport.db.findById(
        session,
        existing.id!,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (current == null ||
          current.bsnsYear != existing.bsnsYear ||
          current.sourceId != existing.sourceId) {
        return false;
      }
      final facts = await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(existing.id!),
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (facts.isEmpty ||
          facts.length != existing.factCount ||
          facts.any(
            (f) =>
                f.companyId != company.id ||
                f.bsnsYear != existing.bsnsYear ||
                f.reportCode != existing.reportCode ||
                f.fsDiv != div ||
                f.sourceId != existing.sourceId,
          )) {
        return false;
      }
      final converted = FinancialRows.toFacts(
        freshRows,
        reportId: existing.id!,
        companyId: company.id!,
        bsnsYear: filing.bsnsYear!,
        reportCode: filing.reportCode!,
        fsDiv: div,
        sourceId: existing.sourceId,
      );
      final oldValues = _signatures(facts),
          freshValues = _signatures(converted.facts);
      if (converted.invalidAmounts != existing.invalidAmountCount ||
          oldValues.length != freshValues.length ||
          oldValues.join('\n') != freshValues.join('\n')) {
        return false;
      }
      final previousReportLinks = await session.db.unsafeQuery(
        '''SELECT id,"supersededById" FROM financial_report WHERE id=@id OR "supersededById"=@id OR
          ("companyId"=@company AND "bsnsYear" IN (@old,@new) AND "reportCode"=@code AND "fsDiv"=@div)''',
        parameters: QueryParameters.named({
          'id': existing.id!,
          'company': company.id!,
          'old': existing.bsnsYear,
          'new': filing.bsnsYear!,
          'code': existing.reportCode.name,
          'div': div.name,
        }),
        transaction: tx,
      );
      final previousFactLinks = await session.db.unsafeQuery(
        '''SELECT id,"supersededById" FROM financial_fact WHERE "reportId" IN
          (SELECT id FROM financial_report WHERE id=@id OR "supersededById"=@id OR
          ("companyId"=@company AND "bsnsYear" IN (@old,@new) AND "reportCode"=@code AND "fsDiv"=@div))
          OR "supersededById" IN (SELECT id FROM financial_fact WHERE "reportId"=@id)''',
        parameters: QueryParameters.named({
          'id': existing.id!,
          'company': company.id!,
          'old': existing.bsnsYear,
          'new': filing.bsnsYear!,
          'code': existing.reportCode.name,
          'div': div.name,
        }),
        transaction: tx,
      );
      await FinancialReport.db.updateRow(
        session,
        current.copyWith(bsnsYear: filing.bsnsYear),
        transaction: tx,
      );
      await session.db.unsafeExecute(
        'UPDATE financial_fact SET "bsnsYear"=@year WHERE "reportId"=@id',
        parameters: QueryParameters.named({
          'year': filing.bsnsYear!,
          'id': existing.id!,
        }),
        transaction: tx,
      );
      // An erroneous old fiscal key could have superseded a different period.
      await session.db.unsafeExecute(
        '''
        UPDATE financial_report r SET "supersededById"=NULL
        FROM financial_report n WHERE r."supersededById"=n.id
          AND (r.id=@id OR n.id=@id)
          AND (r."companyId",r."bsnsYear",r."reportCode",r."fsDiv") IS DISTINCT FROM
              (n."companyId",n."bsnsYear",n."reportCode",n."fsDiv")
      ''',
        parameters: QueryParameters.named({'id': existing.id!}),
        transaction: tx,
      );
      await session.db.unsafeExecute(
        '''
        UPDATE financial_fact f SET "supersededById"=NULL
        FROM financial_fact n WHERE f."supersededById"=n.id
          AND (f."reportId"=@id OR n."reportId"=@id)
          AND (f."companyId",f."bsnsYear",f."reportCode",f."fsDiv") IS DISTINCT FROM
              (n."companyId",n."bsnsYear",n."reportCode",n."fsDiv")
      ''',
        parameters: QueryParameters.named({'id': existing.id!}),
        transaction: tx,
      );
      final peers =
          (await FinancialReport.db.find(
                session,
                where: (t) =>
                    t.companyId.equals(company.id!) &
                    t.bsnsYear.equals(filing.bsnsYear!) &
                    t.reportCode.equals(filing.reportCode!) &
                    t.fsDiv.equals(div),
                transaction: tx,
              ))
              .where((r) => _samePeriod(r.reportName, filing.reportName))
              .toList()
            ..sort((a, b) => a.rceptNo.compareTo(b.rceptNo));
      final latest = peers.last;
      final latestFacts = await FinancialFact.db.find(
        session,
        where: (t) => t.reportId.equals(latest.id!),
        transaction: tx,
      );
      for (final peer in peers) {
        await session.db.unsafeExecute(
          'UPDATE financial_fact SET "supersededById"=NULL WHERE "reportId"=@id',
          parameters: QueryParameters.named({'id': peer.id!}),
          transaction: tx,
        );
        if (peer.id == latest.id) {
          await session.db.unsafeExecute(
            'UPDATE financial_report SET "supersededById"=NULL WHERE id=@id',
            parameters: QueryParameters.named({'id': peer.id!}),
            transaction: tx,
          );
          continue;
        }
        await FinancialReport.db.updateRow(
          session,
          peer.copyWith(supersededById: latest.id),
          transaction: tx,
        );
        final previous = await FinancialFact.db.find(
          session,
          where: (t) => t.reportId.equals(peer.id!),
          transaction: tx,
        );
        for (final link in FinancialRows.supersessions(
          previous,
          latestFacts,
        ).entries) {
          await session.db.unsafeExecute(
            'UPDATE financial_fact SET "supersededById"=@next WHERE id=@id',
            parameters: QueryParameters.named({
              'id': link.key,
              'next': link.value,
            }),
            transaction: tx,
          );
        }
      }
      final audit = {
        'reportId': existing.id,
        'receipt': filing.rceptNo,
        'previousFiscalYear': existing.bsnsYear,
        'verifiedFiscalYear': filing.bsnsYear,
        'apiCalendarYear': parsed.periodYear,
        'originalSourceId': existing.sourceId,
        'unchangedFacts': facts.length,
        'verifiedValuesSha256': sha256
            .convert(utf8.encode(freshValues.join('\n')))
            .toString(),
        'previousReportLinks': [
          for (final r in previousReportLinks) r.toColumnMap(),
        ],
        'previousFactLinks': [
          for (final r in previousFactLinks) r.toColumnMap(),
        ],
      };
      await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title: '동일 접수 원응답 대조 후 회계연도 메타데이터 복구 · ${jsonEncode(audit)}',
          reference: 'financial-period-repair:${existing.id}:${filing.rceptNo}',
          url: DartClient.filingViewerUrl(filing.rceptNo).toString(),
          retrievedAt: DateTime.now().toUtc(),
        ),
        transaction: tx,
      );
      return true;
    });
  }

  static bool _samePeriod(String first, String second) {
    final a = DartReportName.parse(first), b = DartReportName.parse(second);
    return a != null &&
        b != null &&
        a.kind == b.kind &&
        a.periodYear == b.periodYear &&
        a.periodMonth == b.periodMonth;
  }

  static List<String> _signatures(List<FinancialFact> facts) => [
    for (final f in facts)
      jsonEncode({
        'statement': f.statement.name,
        'accountId': f.accountId,
        'accountName': f.accountName,
        'accountDetail': f.accountDetail,
        'ord': f.ord,
        'periodName': f.periodName,
        'amount': f.amount?.toString(),
        'cumulativeAmount': f.cumulativeAmount?.toString(),
        'priorPeriodName': f.priorPeriodName,
        'priorAmount': f.priorAmount?.toString(),
        'priorCumulativeAmount': f.priorCumulativeAmount?.toString(),
        'priorQuarterName': f.priorQuarterName,
        'priorQuarterAmount': f.priorQuarterAmount?.toString(),
        'beforePriorPeriodName': f.beforePriorPeriodName,
        'beforePriorAmount': f.beforePriorAmount?.toString(),
        'currency': f.currency,
      }),
  ]..sort();
}
