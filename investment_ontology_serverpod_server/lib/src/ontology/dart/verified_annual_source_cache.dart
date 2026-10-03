import 'cns_micro_current_seven_source.dart';
import 'uxn_2023_exact_source.dart';
import 'heungkuk_current_exact_source.dart';
import 'verified_historical_company_identity.dart';
import 'talos_2021_current_seven_source.dart';
import 'talos_2022_exact_source.dart';
import 'exact_current_row_profiles.dart';
import 'anymedi_audit_period_source.dart';
import 'sk_square_short_annual_source.dart';
import 'exact_aone_annual_source.dart';
import 'exact_current_cfs_source.dart';
import 'db_fy22_whole_current_source.dart';
import 'db_fy22_exact_issuer_identity.dart';
import 'woori_investment_2021_source.dart';
import 'db_exact_issuer_identity.dart';

import 'dart:convert';

import 'gne_own_audit_source.dart';

import 'public_financial_html.dart';
import 'source_verified_partial_core.dart';
import 'sk_signet_identity.dart';

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../generated/protocol.dart';
import 'nh_2021_exact_source.dart';
import 'daishin_2022_exact_source.dart';
import 'dart_report_name.dart';
import 'public_financial_html_fetch.dart';
import 'verified_annual_source_registry.dart';
import 'same_receipt_audit_source.dart';
import 'linked_correction_audit_source.dart';
import 'header18_linked_primary_source.dart';
import 'pureun_six_core_profile.dart';
import 'historical_primary_cfs_absence.dart';

/// Only compiled, byte-pinned official packages; the adapter has no network.
final class VerifiedAnnualSourceCache {
  VerifiedAnnualSourceCache({Future<List<int>> Function(String)? readAsset})
    : _read = readAsset ?? ((path) => File(path).readAsBytes());
  final Future<List<int>> Function(String) _read;
  static const receipt = '20260323001652';
  static const corpCode = '01020269';
  static const ruleVersion = 'talos-cfs-pure-literal-v1';
  static const manifestDigest =
      '039849225de164921a9aeb65fa3458fadcbe6574b4ab56e6bb035b7084e6ebf4';
  static const assetDirectory = 'assets/financial_source_cache/talos-cfs-2025';
  static const auditReference =
      'financial-cache-replay:$manifestDigest:$receipt:consolidated:$ruleVersion';
  static const pimReceipt = '20250321001900';
  static const pimCorpCode = '00765897';
  static const pimRuleVersion = 'pim-cfs-whole-ce-v1';
  static const pimManifestDigest =
      'c964aef1f97af016e1d54595c8b05c5fb5762bc80ab02cc363b504ea1c62ac80';
  static const pimAssetDirectory = 'assets/financial_source_cache/pim-cfs-2024';

  static bool isPim(DartFiling filing) => filing.rceptNo == pimReceipt;
  static String digestFor(
    DartFiling filing, [
    FsDiv basis = FsDiv.consolidated,
  ]) => _entry(filing, basis).manifestDigest;
  static String ruleFor(
    DartFiling filing, [
    FsDiv basis = FsDiv.consolidated,
  ]) => _entry(filing, basis).ruleVersion;
  static String referenceFor(
    DartFiling filing, [
    FsDiv basis = FsDiv.consolidated,
  ]) => _entry(filing, basis).auditReference;
  static AnnualSourceCacheEntry _entry(DartFiling filing, FsDiv basis) =>
      VerifiedAnnualSourceRegistry.find(filing.rceptNo, basis) ??
      (throw const FormatException('Unknown immutable annual package'));
  static bool eligible(DartFiling filing) =>
      filing.rceptNo == receipt &&
      eligibleFor(filing, _entry(filing, FsDiv.consolidated));
  static bool eligiblePim(DartFiling filing) =>
      filing.rceptNo == pimReceipt &&
      eligibleFor(filing, _entry(filing, FsDiv.consolidated));
  static bool eligibleAny(DartFiling filing) => VerifiedAnnualSourceRegistry
      .entries
      .any((entry) => eligibleFor(filing, entry));
  static bool eligibleFor(DartFiling filing, AnnualSourceCacheEntry entry) {
    if (!identical(
      VerifiedAnnualSourceRegistry.find(entry.receipt, entry.basis),
      entry,
    )) {
      return false;
    }
    final report = DartReportName.parse(filing.reportName);
    final attempts = RegExp(r'api-noData-annual-public:attempt=(\d+);')
        .firstMatch(filing.lastError ?? '');
    final status = entry.basis == FsDiv.consolidated
        ? filing.consolidatedStatus
        : filing.separateStatus;
    return filing.rceptNo == entry.receipt &&
        filing.corpCode == entry.corpCode &&
        filing.bsnsYear == entry.year &&
        filing.reportCode == FinancialReportCode.annual &&
        report?.kind == DartReportKind.annual &&
        report?.periodYear == entry.year &&
        report?.periodMonth == entry.periodEnd.month &&
        attempts?.group(1) == '3' &&
        (status == FilingFetchStatus.failed ||
            status == FilingFetchStatus.pending);
  }

  Future<PublicFinancialHtmlBasisNotApplicable> verify(
    DartFiling f,
    Company c,
  ) async {
    if (!eligible(f)) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    final result = await verifyRegistered(f, c, FsDiv.consolidated);
    return result.absence ??
        (throw const FormatException(
          'Cached annual expected typed absence missing',
        ));
  }

  Future<PublicFinancialHtmlSource> verifyPim(DartFiling f, Company c) async {
    if (!eligiblePim(f)) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    final result = await verifyRegistered(f, c, FsDiv.consolidated);
    return result.numeric ??
        (throw const FormatException(
          'Cached annual expected numeric source missing',
        ));
  }

  Future<
    ({
      PublicFinancialHtmlSource? numeric,
      PublicFinancialHtmlBasisNotApplicable? absence,
    })
  >
  verifyRegistered(DartFiling filing, Company company, FsDiv basis) async {
    final entry = _entry(filing, basis);
    if (!eligibleFor(filing, entry) ||
        company.corpCode != entry.corpCode ||
        filing.companyId != company.id ||
        company.stockCode == null) {
      throw const FormatException('Cached annual scope identity mismatch');
    }
    return _verifyBound(entry, filing, company, basis);
  }

  /// Existing reports may be enriched only for these independently bound
  /// current-row packages. The normal failed/pending replay gate is unchanged.
  Future<PublicFinancialHtmlSource> verifyExistingRows(
    DartFiling filing,
    Company company,
    FsDiv basis,
  ) async {
    final entry = _entry(filing, basis);
    final exact =
        (const {'20250320000036', '20230321000015'}.contains(filing.rceptNo) &&
            basis == FsDiv.separate) ||
        (filing.rceptNo == '20220310001159' &&
            (basis == FsDiv.consolidated || basis == FsDiv.separate)) ||
        ExactCurrentRowProfiles.find(filing.rceptNo, basis) != null;
    final report = DartReportName.parse(filing.reportName);
    if (!exact ||
        filing.corpCode != entry.corpCode ||
        company.corpCode != entry.corpCode ||
        company.name != entry.companyName ||
        company.stockCode == null ||
        filing.companyId != company.id ||
        filing.bsnsYear != entry.year ||
        filing.reportCode != FinancialReportCode.annual ||
        report?.kind != DartReportKind.annual ||
        report?.periodYear != entry.year ||
        report?.periodMonth != 12 ||
        (basis == FsDiv.separate
                ? filing.separateStatus
                : filing.consolidatedStatus) !=
            FilingFetchStatus.stored) {
      throw const FormatException('Existing row enrichment identity mismatch');
    }
    final result = await _verifyBound(entry, filing, company, basis);
    return result.numeric ??
        (throw const FormatException(
          'Existing row enrichment needs numeric source',
        ));
  }

  Future<
    ({
      PublicFinancialHtmlSource? numeric,
      PublicFinancialHtmlBasisNotApplicable? absence,
    })
  >
  _verifyBound(
    AnnualSourceCacheEntry entry,
    DartFiling filing,
    Company company,
    FsDiv basis,
  ) async {
    final rawManifest = await _read('${entry.assetDirectory}/manifest.json');
    if (sha256.convert(rawManifest).toString() != entry.manifestDigest) {
      throw const FormatException('Cached annual manifest digest mismatch');
    }
    if (entry.ruleVersion == Header18LinkedPrimarySource.primaryRule ||
        entry.ruleVersion == Header18LinkedPrimarySource.absenceRule) {
      return Header18LinkedPrimarySource.verify(
        entry: entry,
        company: company,
        filing: filing,
        rawManifest: rawManifest,
        read: _read,
      );
    }
    final manifest = jsonDecode(utf8.decode(rawManifest)) as Map;
    final start = entry.periodStart, end = entry.periodEnd;
    if (manifest['receipt'] != entry.receipt ||
        manifest['corpCode'] != entry.corpCode ||
        manifest['basis'] != basis.name ||
        manifest['kind'] != 'annual' ||
        manifest['year'] != entry.year ||
        manifest['periodStart'] != start.toIso8601String().substring(0, 10) ||
        manifest['periodEnd'] != end.toIso8601String().substring(0, 10) ||
        manifest['ruleVersion'] != entry.ruleVersion) {
      throw const FormatException('Cached annual declared identity mismatch');
    }
    final correctionAudit =
        entry.ruleVersion == 'linked-correction-audit-immutable-v1' &&
        LinkedCorrectionAuditSource.eligible(
          receipt: entry.receipt,
          corpCode: entry.corpCode,
          consolidated: basis == FsDiv.consolidated,
          start: start,
          end: end,
        );
    final linkedAudit =
        entry.ruleVersion == 'same-receipt-audit-immutable-v1' &&
        SameReceiptAuditSource.eligible(
          receipt: entry.receipt,
          corpCode: entry.corpCode,
          consolidated: basis == FsDiv.consolidated,
          start: start,
          end: end,
        );
    final requiredLabels = {
      if (entry.ruleVersion == AnyMediAuditPeriodSource.rule) ...{
        'audit-shell',
        'audit-opinion',
        'audit-statement',
      },
      'shell',
      'cover',
      entry.statementLabel,
      if (linkedAudit || correctionAudit) 'auditShell',
      if (correctionAudit) 'originalShell',
      if (correctionAudit &&
          LinkedCorrectionAuditSource.witnessUri(entry.receipt) != null)
        'targetOfs',
      if (entry.requiresIssuerOverview) 'overview',
      if (entry.requiresCashScopeNotes) 'notes',
      if (entry.requiresOwnOfsWitness) 'issuer-ofs',
    };
    final documentCount = requiredLabels.length;
    final documents = <Uri, List<int>>{};
    final labels = <String>{};
    for (final source in manifest['sources'] as List) {
      final label = source['label'];
      if (!requiredLabels.contains(label) ||
          !labels.add(label as String) ||
          source['file'] != '$label.html') {
        throw const FormatException('Unknown cached annual document');
      }
      final uri = Uri.parse(source['url'] as String),
          bytes = await _read('${entry.assetDirectory}/${source['file']}');
      if (documents.containsKey(uri) ||
          sha256.convert(bytes).toString() != source['sha256']) {
        throw const FormatException('Cached annual raw digest mismatch');
      }
      documents[uri] = bytes;
    }
    if (documents.length != documentCount || labels.length != documentCount) {
      throw const FormatException('Cached annual package incomplete');
    }

    if (entry.ruleVersion == Talos2021CurrentSevenSource.rule) {
      final uris = <String, Uri>{
        for (final s in manifest['sources'] as List)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raw = <String, String>{
        for (final e in uris.entries) e.key: utf8.decode(documents[e.value]!),
      };
      final rows = Talos2021CurrentSevenSource.parse(
        raw: raw,
        uris: uris,
        receipt: entry.receipt,
        corp: company.corpCode,
        start: start,
        end: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raw['ofs']!,
          statementSource: uris['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (CnsMicroCurrentSevenSource.supports(entry.ruleVersion)) {
      final uris = <String, Uri>{
        for (final s in manifest['sources'] as List)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raw = <String, String>{
        for (final e in uris.entries) e.key: utf8.decode(documents[e.value]!),
      };
      final rows = CnsMicroCurrentSevenSource.parse(
        raw: raw,
        uris: uris,
        receipt: entry.receipt,
        corp: company.corpCode,
        start: start,
        end: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raw['ofs']!,
          statementSource: uris['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == Uxn2023ExactSource.rule) {
      final uris = <String, Uri>{
        for (final s in manifest['sources'] as List)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raw = <String, String>{
        for (final e in uris.entries) e.key: utf8.decode(documents[e.value]!),
      };
      final rows = Uxn2023ExactSource.parse(
        raw: raw,
        uris: uris,
        receipt: entry.receipt,
        corp: company.corpCode,
        start: start,
        end: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raw['ofs']!,
          statementSource: uris['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == Talos2022ExactSource.rule) {
      final uris = <String, Uri>{
        for (final s in manifest['sources'] as List)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raw = <String, String>{
        for (final e in uris.entries) e.key: utf8.decode(documents[e.value]!),
      };
      final rows = Talos2022ExactSource.parse(
        raw: raw,
        uris: uris,
        receipt: entry.receipt,
        corp: company.corpCode,
        start: start,
        end: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raw['ofs']!,
          statementSource: uris['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == ExactCurrentCfsSource.rule) {
      final uris = <String, Uri>{
        for (final s in manifest['sources'] as List)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raw = <String, String>{
        for (final s in uris.entries) s.key: utf8.decode(documents[s.value]!),
      };
      final rows = ExactCurrentCfsSource.parse(
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: company.name,
        consolidated: basis == FsDiv.consolidated,
        start: start,
        end: end,
        raw: raw,
        uris: uris,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raw['cfs']!,
          statementSource: uris['cfs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (HeungkukCurrentExactSource.supports(entry.ruleVersion)) {
      final src = manifest['sources'] as List;
      final uris = <String, Uri>{
        for (final s in src)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raws = <String, String>{
        for (final s in src)
          s['label'] as String: utf8.decode(documents[uris[s['label']]]!),
      };
      final rows = HeungkukCurrentExactSource.parse(
        raw: raws,
        uris: uris,
        receipt: entry.receipt,
        corp: company.corpCode,
        start: start,
        end: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raws['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raws['ofs']!,
          statementSource: uris['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == Daishin2022ExactSource.rule) {
      final src = manifest['sources'] as List;
      final uris = <String, Uri>{
        for (final s in src)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raws = <String, String>{
        for (final s in src)
          s['label'] as String: utf8.decode(documents[uris[s['label']]]!),
      };
      final rows = Daishin2022ExactSource.parse(
        raw: raws,
        uris: uris,
        receipt: entry.receipt,
        corp: company.corpCode,
        start: start,
        end: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raws['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raws['ofs']!,
          statementSource: uris['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == Nh2021ExactSource.rule) {
      final src = manifest['sources'] as List;
      final uris = <String, Uri>{
        for (final s in src)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final raws = <String, String>{
        for (final s in src)
          s['label'] as String: utf8.decode(documents[uris[s['label']]]!),
      };
      final rows = Nh2021ExactSource.parse(
        raw: raws,
        uris: uris,
        receipt: entry.receipt,
        corp: company.corpCode,
        start: start,
        end: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raws['cover']!,
          coverSource: uris['cover']!,
          statementHtml: raws['ofs']!,
          statementSource: uris['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == WooriInvestment2021Source.rule) {
      final src = manifest['sources'] as List;
      Uri uri(String label) => Uri.parse(
        src.singleWhere((s) => s['label'] == label)['url'] as String,
      );
      final sh = uri('shell'),
          co = uri('cover'),
          st = uri(basis == FsDiv.consolidated ? 'cfs' : 'ofs');
      String raw(Uri u) => utf8.decode(documents[u]!);
      final rows = WooriInvestment2021Source.parse(
        shell: raw(sh),
        cover: raw(co),
        statement: raw(st),
        shellSource: sh,
        coverSource: co,
        statementSource: st,
        sourceReceipt: entry.receipt,
        corpCode: company.corpCode,
        periodStart: start,
        periodEnd: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw(co),
          coverSource: co,
          statementHtml: raw(st),
          statementSource: st,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == 'gne-own-audit-whole7-v1') {
      String raw(String uri) => utf8.decode(documents[Uri.parse(uri)]!);
      final cover = raw(GneOwnAuditSource.coverUri),
          statement = raw(GneOwnAuditSource.statementUri);
      final rows = GneOwnAuditSource.parse(
        shell: raw(GneOwnAuditSource.shellUri),
        cover: cover,
        statement: statement,
        shellSource: Uri.parse(GneOwnAuditSource.shellUri),
        coverSource: Uri.parse(GneOwnAuditSource.coverUri),
        statementSource: Uri.parse(GneOwnAuditSource.statementUri),
        sourceReceipt: entry.receipt,
        corpCode: company.corpCode,
        periodStart: start,
        periodEnd: end,
        consolidated: basis == FsDiv.consolidated,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: cover,
          coverSource: Uri.parse(GneOwnAuditSource.coverUri),
          statementHtml: statement,
          statementSource: Uri.parse(GneOwnAuditSource.statementUri),
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == 'db-exact-self-declared-issuer-v1') {
      final raw = <String, String>{};
      for (final source in manifest['sources'] as List) {
        final label = source['label'] as String;
        if (source['url'] != DbExactIssuerIdentity.urls[label]) {
          throw const FormatException('Exact DB issuer URI mismatch');
        }
        raw[label] = utf8.decode(documents[Uri.parse(source['url'])]!);
      }
      final identity = DbExactIssuerIdentity.verify(
        raw,
        receipt: entry.receipt,
        corp: company.corpCode,
        currentName: company.name,
        consolidated: basis == FsDiv.consolidated,
        start: start,
        end: end,
      );
      final coverUri = Uri.parse(DbExactIssuerIdentity.urls['cover']!);
      final statementUri = Uri.parse(DbExactIssuerIdentity.urls['ofs']!);
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: raw['cover']!,
        statementHtml: raw['ofs']!,
        coverSource: coverUri,
        statementSource: statementUri,
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: 'DB금융투자주식회사',
        periodStart: start,
        periodEnd: end,
        consolidated: false,
      );
      for (final row in rows) {
        (row['html_provenance'] as Map)['exactIssuerIdentity'] = identity;
      }
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw['cover']!,
          coverSource: coverUri,
          statementHtml: raw['ofs']!,
          statementSource: statementUri,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == 'db-fy22-exact-self-declared-issuer-v1') {
      final raw = <String, String>{};
      for (final source in manifest['sources'] as List) {
        final label = source['label'] as String;
        if (source['url'] != DbFy22ExactIssuerIdentity.urls[label]) {
          throw const FormatException('Exact DB issuer URI mismatch');
        }
        raw[label] = utf8.decode(documents[Uri.parse(source['url'])]!);
      }
      final identity = DbFy22ExactIssuerIdentity.verify(
        raw,
        receipt: entry.receipt,
        corp: company.corpCode,
        currentName: company.name,
        consolidated: basis == FsDiv.consolidated,
        start: start,
        end: end,
      );
      final coverUri = Uri.parse(DbFy22ExactIssuerIdentity.urls['cover']!);
      final statementUri = Uri.parse(DbFy22ExactIssuerIdentity.urls['cfs']!);
      final rows = DbFy22WholeCurrentSource.parse(
        cover: raw['cover']!,
        body: raw['cfs']!,
        coverSource: coverUri,
        statementSource: statementUri,
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: company.name,
        start: start,
        end: end,
        consolidated: true,
      );
      for (final row in rows) {
        (row['html_provenance'] as Map)['exactIssuerIdentity'] = identity;
      }
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: raw['cover']!,
          coverSource: coverUri,
          statementHtml: raw['cfs']!,
          statementSource: statementUri,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.requiresOwnOfsWitness) {
      if (entry.ruleVersion != 'historical-issuer-cfs-none-own-ofs-v1' ||
          basis != FsDiv.consolidated ||
          entry.absenceLiteral == null ||
          !entry.requiresIssuerOverview) {
        throw const FormatException('Invalid compiled issuer witness scope');
      }
      Uri uri(String label) => Uri.parse(
        (manifest['sources'] as List).singleWhere(
              (x) => x['label'] == label,
            )['url']
            as String,
      );
      String raw(String label) => utf8.decode(documents[uri(label)]!);
      final absence = HistoricalPrimaryCfsAbsence.verify(
        receipt: entry.receipt,
        corpCode: entry.corpCode,
        currentName: company.name,
        reportName: filing.reportName,
        start: start,
        end: end,
        shellSource: uri('shell'),
        shell: raw('shell'),
        coverSource: uri('cover'),
        cover: raw('cover'),
        ofsSource: uri('issuer-ofs'),
        ofs: raw('issuer-ofs'),
        overviewSource: uri('overview'),
        overview: raw('overview'),
        cfsSource: uri('cfs'),
        cfs: raw('cfs'),
        expectedLiteral: entry.absenceLiteral!,
      );
      return (numeric: null, absence: absence);
    }
    if (entry.ruleVersion == 'sk-signet-direct-rename-event-v1') {
      String raw(String label) => utf8.decode(
        documents[Uri.parse(
          label == 'shell'
              ? 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=${entry.receipt}'
              : SkSignetIdentity.urls[label]!,
        )]!,
      );
      final cover = raw('cover'), statement = raw('ofs');
      final coverUri = Uri.parse(SkSignetIdentity.urls['cover']!),
          statementUri = Uri.parse(SkSignetIdentity.urls['ofs']!);
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: cover,
        statementHtml: statement,
        coverSource: coverUri,
        statementSource: statementUri,
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: company.name,
        periodStart: start,
        periodEnd: end,
        consolidated: false,
        skSignetIdentity: SkSignetIdentity(
          shell: raw('shell'),
          overview: raw('overview'),
          overviewSource: Uri.parse(SkSignetIdentity.urls['overview']!),
        ),
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: cover,
          coverSource: coverUri,
          statementHtml: statement,
          statementSource: statementUri,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == ExactAoneAnnualSource.rule) {
      final sourceMaps = (manifest['sources'] as List).cast<Map>();
      final uriByLabel = <String, Uri>{
        for (final s in sourceMaps)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final rawByLabel = <String, String>{
        for (final s in sourceMaps)
          s['label'] as String: utf8.decode(documents[uriByLabel[s['label']]]!),
      };
      final rows = ExactAoneAnnualSource.parse(
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: company.name,
        consolidated: basis == FsDiv.consolidated,
        start: start,
        end: end,
        raw: rawByLabel,
        uris: uriByLabel,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: rawByLabel['cover']!,
          coverSource: uriByLabel['cover']!,
          statementHtml: rawByLabel['ofs']!,
          statementSource: uriByLabel['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == SkSquareShortAnnualSource.rule) {
      final sourceMaps = (manifest['sources'] as List).cast<Map>();
      final uriByLabel = <String, Uri>{
        for (final s in sourceMaps)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final rawByLabel = <String, String>{
        for (final s in sourceMaps)
          s['label'] as String: utf8.decode(documents[uriByLabel[s['label']]]!),
      };
      final rows = SkSquareShortAnnualSource.parse(
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: company.name,
        consolidated: basis == FsDiv.consolidated,
        start: start,
        end: end,
        raw: rawByLabel,
        uris: uriByLabel,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: rawByLabel['cover']!,
          coverSource: uriByLabel['cover']!,
          statementHtml: rawByLabel['cfs']!,
          statementSource: uriByLabel['cfs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == AnyMediAuditPeriodSource.rule) {
      final sourceMaps = (manifest['sources'] as List).cast<Map>();
      final uriByLabel = <String, Uri>{
        for (final s in sourceMaps)
          s['label'] as String: Uri.parse(s['url'] as String),
      };
      final rawByLabel = <String, String>{
        for (final s in sourceMaps)
          s['label'] as String: utf8.decode(documents[uriByLabel[s['label']]]!),
      };
      final rows = AnyMediAuditPeriodSource.parse(
        receipt: entry.receipt,
        corpCode: company.corpCode,
        companyName: company.name,
        consolidated: basis == FsDiv.consolidated,
        start: start,
        end: end,
        raw: rawByLabel,
        uris: uriByLabel,
      );
      return (
        numeric: PublicFinancialHtmlSource(
          sourceReceipt: entry.receipt,
          correctionReceipt: null,
          correctionSource: null,
          coverHtml: rawByLabel['cover']!,
          coverSource: uriByLabel['cover']!,
          statementHtml: rawByLabel['ofs']!,
          statementSource: uriByLabel['ofs']!,
          periodStart: start,
          periodEnd: end,
          rows: rows,
        ),
        absence: null,
      );
    }
    if (entry.ruleVersion == 'historical-receipt-bound-cfs-explicit-none-v1') {
      final sources = manifest['sources'] as List;
      Uri source(String label) => Uri.parse(
        sources.singleWhere((x) => x['label'] == label)['url'] as String,
      );
      String raw(String label) => utf8.decode(documents[source(label)]!);
      final contracts = <String, (String, String, String)>{
        '20220329001197': ('주식회사 로보쓰리', '2.연결재무제표해당사항없습니다.', '해당사항 없습니다.'),
        '20220321000965': (
          '주식회사 프로테옴텍',
          '2.연결재무제표당사는연결대상종속회사가존재하지않으므로,한국채택국제회계기준의주된재무제표인연결기준의재무정보를기재하지않습니다.',
          '당사는 연결대상 종속회사가 존재하지 않으므로, 한국채택국제회계기준의 주된 재무제표인 연결기준의 재무정보를 기재하지 않습니다.',
        ),
        '20230328000161': (
          '주식회사 씨유박스',
          '2.연결재무제표당사는사업보고서제출일현재해당사항없습니다.',
          '당사는 사업보고서 제출일 현재 해당사항 없습니다.',
        ),
      };
      final contract = contracts[entry.receipt];
      final printed = raw('cfs').replaceAll(RegExp(r'<[^>]*>|\s+|&nbsp;'), '');
      if (contract == null ||
          basis != FsDiv.consolidated ||
          documentCount != 3 ||
          start != DateTime.utc(entry.year, 1, 1) ||
          end != DateTime.utc(entry.year, 12, 31) ||
          printed != contract.$2 ||
          entry.absenceLiteral != contract.$3 ||
          VerifiedHistoricalCompanyIdentity.evidence(
                receipt: entry.receipt,
                corpCode: company.corpCode,
                currentName: company.name,
                printedName: contract.$1,
                periodEnd: end,
                consolidated: true,
                coverSource: source('cover'),
                coverHtml: raw('cover'),
              ) ==
              null ||
          !raw('shell').contains("openCorpInfoNew('${entry.corpCode}'")) {
        throw const FormatException(
          'Historical exact own CFS absence binding mismatch',
        );
      }
      return (
        numeric: null,
        absence: PublicFinancialHtmlBasisNotApplicable(
          sourceReceipt: entry.receipt,
          corpCode: company.corpCode,
          companyName: company.name,
          reportName: filing.reportName,
          periodStart: start,
          periodEnd: end,
          coverSource: source('cover'),
          statementSource: source('cfs'),
          coverHtml: raw('cover'),
          statementHtml: raw('cfs'),
          evidence: contract.$3,
        ),
      );
    }
    final client = _PinnedRawClient(documents, maxRequests: documentCount);
    try {
      final numeric = await PublicFinancialHtmlFetcher(client).fetchAnnual(
        entry.receipt,
        reportName: filing.reportName,
        corpCode: company.corpCode,
        companyName: company.name,
        bsnsYear: filing.bsnsYear!,
        periodEnd: end,
        consolidated: basis == FsDiv.consolidated,
        allowPrimaryHistoricalIssuer:
            entry.ruleVersion == 'primary-historical-issuer-whole-seven-v1',
        allowSourceVerifiedPartialCore:
            entry.ruleVersion == 'source-six-with-unavailable-whole-revenue-v1',
      );
      if (entry.absenceLiteral != null ||
          client.requests != documentCount ||
          numeric.sourceReceipt !=
              (correctionAudit
                  ? LinkedCorrectionAuditSource.originalFor(entry.receipt)
                  : entry.receipt) ||
          numeric.periodStart != start ||
          numeric.periodEnd != end ||
          (numeric.rows.length < 7 &&
              !PureunSixCoreProfile.storedProof(
                numeric.rows,
                sourceDigest: numeric.sourceDigest,
                sourceUrl: numeric.statementSource.toString(),
                companyCode: company.corpCode,
                targetReceipt: filing.rceptNo,
                basis: basis.name,
                year: filing.bsnsYear!,
                reportName: filing.reportName,
              ) &&
              !(entry.ruleVersion ==
                      'source-six-with-unavailable-whole-revenue-v1' &&
                  SourceVerifiedPartialCore.verifiedRows(
                    numeric.rows,
                    sourceDigest: numeric.sourceDigest,
                    bodySha256: sha256
                        .convert(utf8.encode(numeric.statementHtml))
                        .toString(),
                    sourceUrl: numeric.statementSource.toString(),
                    companyCode: company.corpCode,
                    targetReceipt: filing.rceptNo,
                    basis: basis.name,
                    year: filing.bsnsYear!,
                  ))) ||
          numeric.rows.length > 8 ||
          numeric.rows.any((r) => r['account_id'] != null)) {
        throw const FormatException(
          'Cached annual verified numeric scope mismatch',
        );
      }
      // Exact eight-account package: ordinary parsing and immutable guards
      // above are still required, and all statement rows remain uncollected.
      if (entry.receipt == '20220317000713' &&
          entry.corpCode == '00148993' &&
          basis == FsDiv.consolidated) {
        for (final row in numeric.rows) {
          final proof = row['html_provenance'] as Map<String, dynamic>;
          proof['fullStatementCollected'] = false;
          proof['uncollectedOptionalAccounts'] = <String>[];
          proof['independentWholeCurrentEvidence'] = {
            'periodStart': '2021-01-01',
            'periodEnd': '2021-12-31',
            'source': numeric.statementSource.toString(),
            'sourceSha256': '5288be65cbc6388214c4f5150a2f29ae9b1833a28120afee8459da45cedca898',
            'wholeEquityColumn': 9,
            'currentProfit': '67355184309',
            'openingEquity': '1060384697419',
            'closingEquity': '1087375061719',
            'openingCash': '266139295663',
            'closingCash': '476020981941',
            'cashIncrease': '209881686278',
            'exchangeCash': '853243026',
            'allStatementRowsVerified': false,
          };
        }
      }
      // Exact independently checked packages retain the partial eight-account scope.
      if ((entry.receipt == '20250321001653' &&
              entry.corpCode == '00886792' &&
              basis == FsDiv.consolidated) ||
          (entry.receipt == '20220331003444' &&
              entry.corpCode == '01085026' &&
              basis == FsDiv.separate)) {
        for (final row in numeric.rows) {
          final proof = row['html_provenance'] as Map<String, dynamic>;
          proof['fullStatementCollected'] = false;
          proof['uncollectedOptionalAccounts'] = <String>[];
          proof['allStatementRowsVerified'] = false;
        }
      }
      return (numeric: numeric, absence: null);
    } on PublicFinancialHtmlBasisNotApplicable catch (absence) {
      if (entry.absenceLiteral == null ||
          basis != FsDiv.consolidated ||
          client.requests != documentCount ||
          absence.sourceReceipt != entry.receipt ||
          absence.corpCode != entry.corpCode ||
          absence.periodStart != start ||
          absence.periodEnd != end ||
          absence.evidence.replaceAll(RegExp(r'\s+'), '') !=
              entry.absenceLiteral!.replaceAll(RegExp(r'\s+'), '')) {
        throw const FormatException('Cached annual verified absence mismatch');
      }
      return (numeric: null, absence: absence);
    } finally {
      client.close();
    }
  }
}

class _PinnedRawClient extends http.BaseClient {
  _PinnedRawClient(this.documents, {this.maxRequests = 3});
  final int maxRequests;
  final Map<Uri, List<int>> documents;
  int requests = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = documents[request.url];
    if (request.method != 'GET' || bytes == null || ++requests > maxRequests) {
      throw const FormatException('Unpinned cached annual source request');
    }
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'text/html; charset=utf-8'},
      request: request,
    );
  }
}
