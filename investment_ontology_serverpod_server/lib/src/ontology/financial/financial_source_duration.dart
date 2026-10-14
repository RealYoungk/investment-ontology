import 'dart:convert';

import '../dart/bnk_six_core_profile.dart';
import '../dart/pureun_six_core_profile.dart';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// Independently stored source audit dates. Unknown/malformed metadata never
/// becomes a guessed duration; no JSON casts run inside SQL.
class FinancialSourceDuration {
  const FinancialSourceDuration(this.start, this.end);
  final DateTime start;
  final DateTime end;
  int get days => end.difference(start).inDays + 1;
  bool get isShort =>
      end != DateTime.utc(end.year, end.month + 1, 0) ||
      start != DateTime.utc(end.year - 1, end.month + 1, 1);
  String get label => '${_date(start)} ~ ${_date(end)} ($days일)';
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:T00:00:00(?:\.000)?Z?)?$')
        .firstMatch(raw);
    if (match == null) return null;
    final y = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    final d = int.parse(match[3]!);
    final date = DateTime.utc(y, m, d);
    return date.year == y && date.month == m && date.day == d ? date : null;
  }

  static FinancialSourceDuration? validate({
    required FinancialReport report,
    required Company company,
    required Source reportSource,
    required Source audit,
  }) {
    if (report.reportCode != FinancialReportCode.annual ||
        reportSource.id != report.sourceId ||
        report.companyId != company.id ||
        reportSource.kind != SourceKind.dartReport ||
        reportSource.reference != report.rceptNo ||
        audit.kind != SourceKind.dartReport ||
        audit.reference !=
            'financial-api-noData-source:${report.rceptNo}:${report.fsDiv.name}' ||
        audit.url != reportSource.url ||
        audit.url == null) {
      {
        return null;
      }
    }
    final uri = Uri.tryParse(audit.url!);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'dart.fss.or.kr' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        !{'/report/viewer.do', '/pdf/download/ifrs.do'}.contains(uri.path) ||
        uri
                .queryParametersAll[uri.path == '/report/viewer.do'
                    ? 'rcpNo'
                    : 'rcp_no']
                ?.length !=
            1 ||
        uri.queryParameters[uri.path == '/report/viewer.do'
                ? 'rcpNo'
                : 'rcp_no'] !=
            report.rceptNo) {
      {
        return null;
      }
    }
    try {
      final json = jsonDecode(audit.title);
      if (json is! Map ||
          json['action'] != 'verified-keyless-annual-source-after-api-noData' ||
          !{'html', 'xbrl'}.contains(json['format']) ||
          json['targetReceipt'] != report.rceptNo ||
          json['sourceReceipt'] != report.rceptNo ||
          json['corpCode'] != company.corpCode ||
          json['reportName'] != report.reportName ||
          json['fsDiv'] != report.fsDiv.name ||
          json['sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(json['sha256'] as String) ||
          !reportSource.title.contains('SHA256:${json['sha256']}')) {
        {
          return null;
        }
      }
      final rows = json['coreRowProvenance'];
      final exactSix =
          (json['format'] == 'html' &&
              reportSource.title.startsWith(BnkSixCoreProfile.title) &&
              json['coverSource'] == BnkSixCoreProfile.coverUri &&
              BnkSixCoreProfile.storedProof(
                rows,
                sourceDigest: json['sha256'],
                sourceUrl: reportSource.url ?? '',
                companyCode: company.corpCode,
                targetReceipt: report.rceptNo,
                basis: report.fsDiv.name,
                year: report.bsnsYear,
                reportName: report.reportName,
              )) ||
          (json['format'] == 'html' &&
              reportSource.title.startsWith(PureunSixCoreProfile.title) &&
              json['coverSource'] == PureunSixCoreProfile.coverUri &&
              PureunSixCoreProfile.storedProof(
                rows,
                sourceDigest: json['sha256'],
                sourceUrl: reportSource.url ?? '',
                companyCode: company.corpCode,
                targetReceipt: report.rceptNo,
                basis: report.fsDiv.name,
                year: report.bsnsYear,
                reportName: report.reportName,
              ));
      if (rows is! List ||
          (rows.length < 7 && !exactSix) ||
          rows.length > 8 ||
          json['coreRows'] != rows.length) {
        return null;
      }
      DateTime? start;
      DateTime? end;
      for (final row in rows) {
        if (row is! Map ||
            row['currency'] != 'KRW' ||
            row[json['format'] == 'html'
                    ? 'html_provenance'
                    : 'xbrl_provenance']
                is! Map) {
          return null;
        }
        final provenance =
            row[json['format'] == 'html'
                    ? 'html_provenance'
                    : 'xbrl_provenance']
                as Map;
        if (provenance['source'] != reportSource.url ||
            provenance['basis'] !=
                (report.fsDiv == FsDiv.consolidated ? 'CFS' : 'OFS')) {
          {
            return null;
          }
        }
        final a = _parseDate(provenance['periodStart']);
        final b = _parseDate(provenance['periodEnd']);
        if (a == null ||
            b == null ||
            a.isAfter(b) ||
            start != null && (start != a || end != b)) {
          {
            return null;
          }
        }
        start = a;
        end = b;
      }
      final actual = RegExp(r'\((\d{4})\.(\d{2})\)$')
          .firstMatch(report.reportName);
      if (actual == null ||
          end!.year != report.bsnsYear ||
          end != DateTime.utc(end.year, end.month + 1, 0) ||
          end.year != int.parse(actual[1]!) ||
          end.month != int.parse(actual[2]!)) {
        {
          return null;
        }
      }
      final duration = FinancialSourceDuration(start!, end);
      return duration.days <= 366 ? duration : null;
    } on FormatException {
      {
        return null;
      }
    }
  }

  /// A cover-period anchor proves dates only. Its cover SHA is independent of
  /// the financial ZIP SHA; this never revalidates or rewrites monetary facts.
  static FinancialSourceDuration? validateAnchor({
    required FinancialReport report,
    required Company company,
    required Source reportSource,
    required Source audit,
    required DartFiling sourceFiling,
    required DartFiling targetFiling,
  }) {
    if (audit.kind != SourceKind.dartReport ||
        reportSource.kind != SourceKind.dartReport ||
        reportSource.id != report.sourceId ||
        reportSource.reference != report.rceptNo ||
        report.companyId != company.id ||
        report.reportCode != FinancialReportCode.annual ||
        audit.reference !=
            'financial-source-period-anchor:${report.rceptNo}:${targetFiling.rceptNo}' ||
        sourceFiling.rceptNo != report.rceptNo) {
      return null;
    }
    for (final filing in [sourceFiling, targetFiling]) {
      if (filing.companyId != company.id ||
          filing.corpCode != company.corpCode ||
          filing.bsnsYear != report.bsnsYear ||
          filing.reportCode != report.reportCode) {
        return null;
      }
    }
    try {
      final metadata = jsonDecode(audit.title);
      if (metadata is! Map ||
          metadata['kind'] != 'verified-source-cover-period-metadata' ||
          metadata['sourceReceipt'] != report.rceptNo ||
          metadata['targetReceipt'] != targetFiling.rceptNo ||
          metadata['corpCode'] != company.corpCode ||
          metadata['sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(metadata['sha256'] as String) ||
          audit.url != metadata['coverSource']) {
        return null;
      }
      for (final path in {
        'coverSource': '/report/viewer.do',
        'shellSource': '/dsaf001/main.do',
      }.entries) {
        if (metadata[path.key] is! String) return null;
        final uri = Uri.tryParse(metadata[path.key] as String);
        if (uri == null ||
            uri.scheme != 'https' ||
            uri.host != 'dart.fss.or.kr' ||
            uri.path != path.value ||
            uri.hasPort ||
            uri.userInfo.isNotEmpty ||
            uri.hasFragment ||
            uri.queryParametersAll['rcpNo']?.length != 1 ||
            uri.queryParameters['rcpNo'] != report.rceptNo) {
          return null;
        }
      }
      final start = _parseDate(metadata['periodStart']);
      final end = _parseDate(metadata['periodEnd']);
      if (start == null ||
          end == null ||
          start.isAfter(end) ||
          end.year != report.bsnsYear ||
          end != DateTime.utc(end.year, end.month + 1, 0)) {
        return null;
      }
      final expected = '${end.year}.${end.month.toString().padLeft(2, '0')}';
      for (final name in [
        report.reportName,
        sourceFiling.reportName,
        targetFiling.reportName,
      ]) {
        if (RegExp(r'\(([0-9]{4}\.[0-9]{2})\)$').firstMatch(name)?.group(1) !=
            expected) {
          return null;
        }
      }
      final range = FinancialSourceDuration(start, end);
      return range.days <= 366 ? range : null;
    } on FormatException {
      {
        return null;
      }
    }
  }

  /// Reads only candidate audit rows and associated reports/sources/companies.
  /// Existing eligible-report SQL still verifies the original filing anchor.
  static Future<
    ({Map<int, FinancialSourceDuration> ranges, Set<int> blockedReportIds})
  >
  load(Session session, {List<int>? companyIds}) async {
    if (companyIds?.isEmpty ?? false) {
      return (
        ranges: <int, FinancialSourceDuration>{},
        blockedReportIds: <int>{},
      );
    }
    // Narrow the source metadata before loading its JSON titles. Those titles
    // contain full provenance and can total several megabytes across the
    // universe; a company request needs only its annual report receipts.
    final scopedReports = companyIds == null
        ? null
        : await FinancialReport.db.find(
            session,
            where: (t) =>
                t.companyId.inSet(companyIds.toSet()) &
                t.reportCode.equals(FinancialReportCode.annual),
          );
    final scopedReceipts = scopedReports?.map((r) => r.rceptNo).toSet();
    if (scopedReceipts?.isEmpty ?? false) {
      return (
        ranges: <int, FinancialSourceDuration>{},
        blockedReportIds: <int>{},
      );
    }
    final audits = await Source.db.find(
      session,
      where: (t) =>
          t.kind.equals(SourceKind.dartReport) &
          t.reference.like('financial-api-noData-source:%') &
          (scopedReceipts == null
              ? t.id.notEquals(null)
              : t.reference.inSet({
                  for (final receipt in scopedReceipts)
                    for (final basis in FsDiv.values)
                      'financial-api-noData-source:$receipt:${basis.name}',
                })),
    );
    Set<int>? scopedAnchorIds;
    if (scopedReceipts != null) {
      final parameters = <String, Object?>{};
      final placeholders = <String>[];
      for (final (index, receipt) in scopedReceipts.indexed) {
        parameters['receipt$index'] = receipt;
        placeholders.add('@receipt$index');
      }
      final rows = await session.db.unsafeQuery(
        "SELECT id FROM source WHERE kind='dartReport' "
        "AND reference LIKE 'financial-source-period-anchor:%' "
        "AND split_part(reference, ':', 2) IN (${placeholders.join(',')})",
        parameters: QueryParameters.named(parameters),
      );
      scopedAnchorIds = {for (final row in rows) row.first as int};
    }
    final anchors = await Source.db.find(
      session,
      where: (t) =>
          t.kind.equals(SourceKind.dartReport) &
          t.reference.like('financial-source-period-anchor:%') &
          (scopedAnchorIds == null
              ? t.id.notEquals(null)
              : t.id.inSet(scopedAnchorIds)),
    );
    final anchorsByReceipt = <String, List<Source>>{};
    final anchorReceipts = <String>{};
    for (final anchor in anchors) {
      final match = RegExp(
        r'^financial-source-period-anchor:(\d{14}):(\d{14})$',
      ).firstMatch(anchor.reference ?? '');
      if (match != null) {
        (anchorsByReceipt[match[1]!] ??= []).add(anchor);
        anchorReceipts.addAll([match[1]!, match[2]!]);
      }
    }
    final filings = {
      for (final f
          in anchorReceipts.isEmpty
              ? <DartFiling>[]
              : await DartFiling.db.find(
                  session,
                  where: (t) => t.rceptNo.inSet(anchorReceipts),
                ))
        f.rceptNo: f,
    };
    final partialSources = await Source.db.find(
      session,
      where: (t) =>
          t.kind.equals(SourceKind.dartReport) &
          (t.title.like('DART 원문 HTML 부분 핵심계정(%') |
              t.title.like('DART 원문 XBRL 핵심계정 ·%')) &
          (scopedReceipts == null
              ? t.id.notEquals(null)
              : t.reference.inSet(scopedReceipts)),
    );
    final byReceipt = <String, List<Source>>{};
    for (final audit in audits) {
      final match = RegExp(
        r'^financial-api-noData-source:(\d{14}):(consolidated|separate)$',
      ).firstMatch(audit.reference ?? '');
      if (match != null) (byReceipt[match[1]!] ??= []).add(audit);
    }
    final receipts = {
      ...byReceipt.keys,
      ...anchorsByReceipt.keys,
      for (final source in partialSources)
        if (RegExp(r'^\d{14}$').hasMatch(source.reference ?? ''))
          source.reference!,
    };
    if (receipts.isEmpty) {
      return (
        ranges: <int, FinancialSourceDuration>{},
        blockedReportIds: <int>{},
      );
    }
    final reports = await FinancialReport.db.find(
      session,
      where: (t) =>
          t.rceptNo.inSet(receipts) &
          t.reportCode.equals(FinancialReportCode.annual) &
          (companyIds == null
              ? t.companyId.notEquals(null)
              : t.companyId.inSet(companyIds.toSet())),
    );
    if (reports.isEmpty) {
      return (
        ranges: <int, FinancialSourceDuration>{},
        blockedReportIds: <int>{},
      );
    }
    final sources = {
      for (final s in await Source.db.find(
        session,
        where: (t) => t.id.inSet(<int>{for (final r in reports) r.sourceId}),
      ))
        s.id!: s,
    };
    final companies = {
      for (final c in await Company.db.find(
        session,
        where: (t) => t.id.inSet(<int>{for (final r in reports) r.companyId}),
      ))
        c.id!: c,
    };
    final result = <int, FinancialSourceDuration>{};
    final blocked = <int>{};
    for (final report in reports) {
      final source = sources[report.sourceId];
      final company = companies[report.companyId];
      if (source == null || company == null) continue;
      final valid = (byReceipt[report.rceptNo] ?? <Source>[])
          .map(
            (a) => validate(
              report: report,
              company: company,
              reportSource: source,
              audit: a,
            ),
          )
          .whereType<FinancialSourceDuration>()
          .toList();
      for (final anchor in anchorsByReceipt[report.rceptNo] ?? <Source>[]) {
        final parts = anchor.reference!.split(':');
        final sf = filings[report.rceptNo];
        final tf = filings[parts.last];
        if (sf == null || tf == null) continue;
        final range = validateAnchor(
          report: report,
          company: company,
          reportSource: source,
          audit: anchor,
          sourceFiling: sf,
          targetFiling: tf,
        );
        if (range != null) valid.add(range);
      }
      final distinct = {for (final range in valid) range.label};
      final verified = distinct.length == 1 ? valid.first : null;
      if (verified != null) result[report.id!] = verified;
      final isPartialHtml =
          source.kind == SourceKind.dartReport &&
          source.reference == report.rceptNo &&
          (source.title.startsWith('DART 원문 HTML 부분 핵심계정(') ||
              source.title.startsWith('DART 원문 XBRL 핵심계정 ·'));
      if (isPartialHtml && (verified == null || verified.isShort)) {
        blocked.add(report.id!);
      }
    }
    return (ranges: result, blockedReportIds: blocked);
  }
}
