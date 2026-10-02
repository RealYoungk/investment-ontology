import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_report_name.dart';
import 'capital_structure_parser.dart';

abstract final class CapitalStructureStore {
  static const kind = 'capitalStructure';
  static String? period(DartFiling filing) {
    final name = DartReportName.parse(filing.reportName);
    if (name == null) return null;
    return DateTime.utc(
      name.periodYear,
      name.periodMonth + 1,
      0,
    ).toIso8601String().substring(0, 10);
  }

  static Future<int> save(
    Session session,
    Company company,
    DartFiling filing,
    String document, {
    List<String> urls = const [],
  }) async {
    final end = period(filing);
    if (end == null || company.corpCode != filing.corpCode) {
      throw const FormatException('Capital filing identity mismatch');
    }
    final data = CapitalStructureParser.parse(
      document,
      receipt: filing.rceptNo,
      periodEnd: end,
      companyName: company.name,
    );
    data['sourceUrls'] = urls;
    data['corpCode'] = company.corpCode;
    data['reportName'] = filing.reportName;
    final payload = jsonEncode(data);
    final digest = sha256.convert(utf8.encode(payload)).toString();
    return session.db.transaction((tx) async {
      await session.db.unsafeQuery(
        'SELECT id FROM company WHERE id=@id FOR UPDATE',
        parameters: QueryParameters.named({'id': company.id!}),
        transaction: tx,
      );
      final existing = await ResearchSnapshot.db.findFirstRow(
        session,
        where: (t) =>
            t.companyId.equals(company.id!) &
            t.kind.equals(kind) &
            t.digest.equals(digest),
        transaction: tx,
      );
      if (existing != null) return existing.id!;
      final now = DateTime.now().toUtc();
      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartReport,
          title:
              'DART 자본·미상환 주식연계사채 · ${filing.reportName} · SHA256=${data['bodySha256']}',
          reference: filing.rceptNo,
          url: 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${filing.rceptNo}',
          retrievedAt: now,
        ),
        transaction: tx,
      );
      final snapshot = await ResearchSnapshot.db.insertRow(
        session,
        ResearchSnapshot(
          companyId: company.id!,
          kind: kind,
          provider: 'DART 공시 원문',
          payload: payload,
          sourceId: source.id!,
          digest: digest,
          createdAt: now,
        ),
        transaction: tx,
      );
      return snapshot.id!;
    });
  }
}
