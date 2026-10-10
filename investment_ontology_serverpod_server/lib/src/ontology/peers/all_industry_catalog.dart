import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:serverpod/serverpod.dart';

import '../cache/single_flight.dart';
import 'industry_catalog_hooks.dart';

import '../../generated/protocol.dart';
import '../ingest/ksic_revision.dart';
import 'discovery_taxonomy.dart';
import 'discovery_coverage.dart';
import 'discovery_offerings.dart';
import 'industry_discovery_catalog.dart';
import 'kind_product_catalog.dart';
import 'issuer_offering_catalog.dart';
import 'discovery_resolution.dart';

/// Protocol dependency of classes declared with `extends Endpoint`.
/// Every listed company remains discoverable, even without a business filing.
/// Registered activities and filing-backed products remain distinct evidence.
abstract final class AllIndustryCatalog {
  // Bump when classification rules or catalog normalization change.
  static const builderVersion = 1;
  static const snapshotKey = 'listed-company-industry';
  static final _loadFlight = SingleFlight<IndustryCatalogSnapshot?>();
  static final _buildFlight = SingleFlight<IndustryCatalogSnapshot?>();
  static IndustryCatalogSnapshot? _stored;
  static Timer? _timer;

  /// Classification is a persistent server-managed read model, not a page job.
  /// Only worker processes build in production; read-only API processes load it.
  static void start(Serverpod pod) {
    _timer?.cancel();
    void tick() => requestRefresh(pod);
    tick();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => tick());
    IndustryCatalogHooks.changed = () => requestRefresh(pod);
  }

  static void requestRefresh(Serverpod pod) {
    unawaited(_background(pod).catchError((Object error, StackTrace stack) {}));
  }

  static Future<void> _background(Serverpod pod) async {
    await _buildFlight.run(() async {
      final session = await pod.createSession(enableLogging: false);
      try {
        // Load durable state BEFORE checking sources or running any rules.
        final saved = await loadStored(session);
        if (saved != null) _stored = saved;
        if (pod.runMode != 'production' ||
            pod.config.futureCallExecutionEnabled) {
          final result = await rebuild(session);
          if (result != null) _stored = result;
        }
        return _stored;
      } catch (error, stack) {
        session.log(
          'Stored industry classification refresh failed',
          level: LogLevel.error,
          exception: error,
          stackTrace: stack,
        );
        return _stored;
      } finally {
        await session.close();
      }
    });
  }

  static Future<IndustryCatalogSnapshot?> loadStored(Session session) =>
      IndustryCatalogSnapshot.db.findFirstRow(
        session,
        where: (t) => t.snapshotKey.equals(snapshotKey),
      );

  /// A missing snapshot is unavailable data, never an invitation to classify
  /// inside an anonymous read. Tests use the same rule as the real application.
  static Future<IndustryCatalogSnapshot> _readStored(Session session) async {
    if (session.serverpod.runMode != 'test' && _stored != null) return _stored!;
    final saved = await _loadFlight.run(() => loadStored(session));
    if (saved == null) {
      throw StateError('기업 분류를 서버에서 준비하고 있습니다.');
    }
    if (session.serverpod.runMode != 'test') _stored = saved;
    return saved;
  }

  static Future<IndustryDiscovery> read(Session session) async =>
      (await _readStored(session)).catalog;

  static Future<IndustryDiscovery> pilot(Session session) async =>
      (await _readStored(session)).pilot;

  static Future<String> sourceFingerprint(Session session) async {
    final rows = await IndustryDiscoveryCatalog.sourceRows(session);
    final industries = await Industry.db.find(
      session,
      orderByList: (t) => [t.revision, t.code],
    );
    final usedCodes = await session.db.unsafeQuery(
      'SELECT DISTINCT "industryCode" FROM company ORDER BY "industryCode"',
    );
    return sha256
        .convert(
          utf8.encode(
            jsonEncode([
              builderVersion,
              DateTime.now().year,
              rows.map((r) => r.toList()).toList(),
              industries.map((i) => i.toJson()).toList(),
              usedCodes.map((r) => r.toList()).toList(),
              KindProductCatalog.source,
              IssuerOfferingCatalog.rows,
            ]),
          ),
        )
        .toString();
  }

  /// The process writer/advisory lock keeps concurrent workers from publishing
  /// different generations. Replacement is atomic; failures keep the old row.
  /// Called only by server background work or an administrator, never a read.
  static Future<IndustryCatalogSnapshot?> rebuild(Session session) async {
    final result = await session.db.transaction((tx) async {
      final lock = await session.db.unsafeQuery(
        'SELECT pg_try_advisory_xact_lock(461009, 1)',
        transaction: tx,
      );
      if (lock.first[0] != true) return loadStored(session);
      final saved = await loadStored(session);
      final fingerprint = await sourceFingerprint(session);
      if (saved?.sourceFingerprint == fingerprint &&
          saved?.builderVersion == builderVersion) {
        return saved;
      }
      await KsicRevision.invalidate(session);
      final built = await _compute(session);
      // If ingestion moved the source while building, retain the last result.
      if (await sourceFingerprint(session) != fingerprint) return saved;
      final next = IndustryCatalogSnapshot(
        id: saved?.id,
        snapshotKey: snapshotKey,
        sourceFingerprint: fingerprint,
        builderVersion: builderVersion,
        catalog: built.catalog,
        pilot: built.pilot,
        computedAt: built.catalog.computedAt,
      );
      final result = saved == null
          ? await IndustryCatalogSnapshot.db.insertRow(
              session,
              next,
              transaction: tx,
            )
          : await IndustryCatalogSnapshot.db.updateRow(
              session,
              next,
              transaction: tx,
            );
      return result;
    });
    if (session.serverpod.runMode != 'test' && result != null) _stored = result;
    return result;
  }

  static Future<({IndustryDiscovery catalog, IndustryDiscovery pilot})>
  _compute(Session session) async {
    final built = await IndustryDiscoveryCatalog.build(session);
    final semiconductor = built.pilot;
    final revision = await KsicRevision.current(session);
    final industries = await Industry.db.find(
      session,
      where: (t) => t.revision.equals(revision.revision),
    );
    final byCode = {for (final i in industries) i.code: i};
    // Some shortened labels coincide across parent/child codes. Show one button.
    final canonicalGroups = <(String, String), String>{};
    final ordered = [...industries]
      ..sort((a, b) => a.code.length.compareTo(b.code.length));
    for (final item in ordered) {
      canonicalGroups.putIfAbsent(
        (
          DiscoveryTaxonomy.category(item.code).$1,
          DiscoveryTaxonomy.label(item.code, item.name),
        ),
        () => item.code,
      );
    }
    final companies = await Company.db.find(
      session,
      where: (t) => t.market.inSet({Market.kospi, Market.kosdaq, Market.konex}),
    );
    final activities = <IndustryActivity>[
      for (final c in companies) ...KindProductCatalog.forCompany(c),
      for (final c in companies) ...IssuerOfferingCatalog.forCompany(c),
      ...built.business,
      for (final a in semiconductor.activities)
        a.copyWith(
          industryKey: 'semiconductor',
          industryName: '반도체',
          classificationBasis: 'filing',
          groupName: const {
            'chip': '칩 설계·제조',
            'design': '설계 IP·디자인하우스',
            'equipment': '장비',
            'material': '소재',
            'component': '부품·소모품',
            'service': '위탁생산·패키징·테스트',
          }[a.role],
        ),
    ];
    // Prefer the filing-derived offering over a broad registration-only join.
    final filingSectors = activities
        .where(
          (a) =>
              a.classificationBasis == 'filing' ||
              a.classificationBasis == 'filing_activity',
        )
        .map((a) => (a.corpCode, a.industryKey))
        .toSet();
    activities.removeWhere(
      (a) =>
          a.classificationBasis == 'kind_registered' &&
          filingSectors.contains((a.corpCode, a.industryKey)),
    );
    for (var i = 0; i < activities.length; i++) {
      activities[i] = DiscoveryOfferings.normalize(activities[i]);
    }
    for (final c in companies) {
      final official = byCode[c.industryCode];
      final category = DiscoveryTaxonomy.category(official?.code);
      var group = official;
      while (group != null &&
          group.level > 4 &&
          group.code != '29271' &&
          group.code != '64992') {
        final parent = byCode[group.parentCode];
        if (parent == null ||
            DiscoveryTaxonomy.category(parent.code).$1 != category.$1) {
          break;
        }
        group = parent;
      }
      final groupName = group == null
          ? '업종 정보 미확보'
          : DiscoveryTaxonomy.label(group.code, group.name);
      final label = official == null
          ? '업종 정보 미확보'
          : DiscoveryTaxonomy.label(official.code, official.name);
      activities.add(
        IndustryActivity(
          corpCode: c.corpCode,
          companyName: c.name,
          market: c.market!.name,
          industryCode: c.industryCode,
          industryKey: category.$1,
          industryName: category.$2,
          role:
              'ksic:${canonicalGroups[(category.$1, groupName)] ?? group?.code ?? 'unknown'}',
          groupName: groupName,
          productKey: 'ksic:${official?.code ?? 'unknown'}',
          productName: label,
          process: '',
          classificationBasis: official == null ? 'unclassified' : 'ksic',
          evidence: official == null
              ? '등록 업종을 현재 분류표와 연결하지 못했습니다. 기업명으로 사업을 추정하지 않았습니다.'
              : 'DART 기업개황 등록 업종 · ${revision.revision} ${official.code} ${official.name}. 제품·사업 매출 및 직접 경쟁 관계를 확인한 분류는 아닙니다.',
          bsnsYear: 0,
          rceptNo: '',
        ),
      );
    }
    activities.sort((a, b) => a.companyName.compareTo(b.companyName));
    return (
      pilot: semiconductor,
      catalog: semiconductor.copyWith(
        activities: DiscoveryCoverage.complete(
          DiscoveryResolution.resolve(activities),
        ),
        listedCompanyCount: companies.length,
        classifiedCompanyCount: activities
            .where((a) => a.classificationBasis != 'unclassified')
            .map((a) => a.corpCode)
            .toSet()
            .length,
        ruleVersion: 12,
        computedAt: DateTime.now().toUtc(),
      ),
    );
  }
}
