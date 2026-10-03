import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../research/split_plan_documents.dart';
import '../research/issuer_documents_collector.dart';
import '../research/research_snapshot_store.dart';

/// Only the normal scheduled business worker calls this. No periodic ledgers.
abstract final class SplitPlanDocumentsSync {
  static Future<void> verifyCompany(
    Session session,
    Company company,
    Map<String, dynamic> row,
  ) async {
    final parent = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(row['filingActorCorpCode'] as String),
    );
    String name(String value) => value
        .replaceAll('주식회사', '')
        .replaceAll('(주)', '')
        .replaceAll('㈜', '')
        .replaceAll(RegExp(r'\s+'), '');
    if (parent == null ||
        name(parent.name) != name(row['filingActorPrintedName'] as String) ||
        name(company.name) != name(row['targetPrintedName'] as String) ||
        company.corpCode != row['corpCode'] ||
        company.establishedDate?.toIso8601String().substring(0, 10) !=
            row['actualEstablishedDate']) {
      throw const FormatException(
        'Split target/parent master identity changed',
      );
    }
    for (final c in [company, parent]) {
      final source = c.profileSourceId == null
          ? null
          : await Source.db.findById(session, c.profileSourceId!);
      if (source?.kind != SourceKind.dartApi ||
          source?.reference != c.corpCode ||
          source?.url !=
              'https://opendart.fss.or.kr/api/company.json?corp_code=${c.corpCode}') {
        throw const FormatException(
          'Split company master Source binding missing',
        );
      }
    }
  }

  static Future<
    ({int stored, int failed, bool cancelled, List<String> reasons})
  >
  collect(
    Session session,
    IssuerDocumentsCollector collector,
    Future<bool> Function() cancelled,
  ) async {
    var stored = 0, failed = 0;
    final reasons = <String>[];
    for (final row in SplitPlanDocuments.rows) {
      if (await cancelled()) {
        return (
          stored: stored,
          failed: failed,
          cancelled: true,
          reasons: reasons,
        );
      }
      try {
        final c = await Company.db.findFirstRow(
          session,
          where: (t) => t.corpCode.equals(row['corpCode'] as String),
        );
        if (c == null) {
          throw const FormatException('Split target company missing');
        }
        await verifyCompany(session, c, row);
        if (!await collector.ensureSplit(row, cancelled: cancelled)) {
          return (
            stored: stored,
            failed: failed,
            cancelled: true,
            reasons: reasons,
          );
        }
        await ResearchSnapshotStore.store(
          session,
          c,
          SplitPlanDocuments.kind,
          [Map<String, dynamic>.from(row)],
          SplitPlanDocuments.provider,
          'https://kind.krx.co.kr',
          SplitPlanDocuments.reference,
          SourceKind.officialFile,
          sourceTitle: jsonEncode({
            'kind': 'delegated-split-original-metadata',
            'readScope': row['readScope'],
            'numericCount': 0,
            'regularAnnualPeriodCount': 0,
            'wholeFinancialStatementsComplete': false,
          }),
          cancelled: cancelled,
        );
        stored++;
      } catch (e) {
        if (await cancelled()) {
          return (
            stored: stored,
            failed: failed,
            cancelled: true,
            reasons: reasons,
          );
        }
        failed++;
        reasons.add(
          '${row['corpCode']}: 분할 원문 보존 실패 (${e is FormatException ? e.message : e.runtimeType})',
        );
      }
    }
    return (stored: stored, failed: failed, cancelled: false, reasons: reasons);
  }

  static Future<bool> pending(Session session, Directory? cache) async {
    for (final row in SplitPlanDocuments.rows) {
      final c = await Company.db.findFirstRow(
        session,
        where: (t) => t.corpCode.equals(row['corpCode'] as String),
      );
      if (c == null) continue;
      try {
        await verifyCompany(session, c, row);
        if (cache == null) return true;
        final f = File('${cache.path}/${row['sha256']}.html');
        if (!await f.exists() ||
            await f.length() > IssuerDocumentsCollector.maxBytes) {
          return true;
        }
        SplitPlanDocuments.verifyBytes(row, await f.readAsBytes());
        final snap = await ResearchSnapshot.db.findFirstRow(
          session,
          where: (t) =>
              t.companyId.equals(c.id!) &
              t.kind.equals(SplitPlanDocuments.kind),
          orderByList: (t) => [t.createdAt.desc(), t.id.desc()],
        );
        if (snap == null ||
            snap.provider != SplitPlanDocuments.provider ||
            snap.payload != jsonEncode([row])) {
          return true;
        }
        final source = await Source.db.findById(session, snap.sourceId);
        if (source?.kind != SourceKind.officialFile ||
            source?.url != 'https://kind.krx.co.kr' ||
            source?.reference != SplitPlanDocuments.reference) {
          return true;
        }
      } on FormatException {
        return true;
      } on FileSystemException {
        return true;
      }
    }
    return false;
  }
}
