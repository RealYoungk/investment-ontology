import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_client.dart';
import '../dart/dart_values.dart';
import 'api_call_budget.dart';
import 'company_changes.dart';
import 'ingest_jobs.dart';
import 'ksic_revision.dart';
import 'ksic_seeder.dart';

/// DART 고유번호 목록 + 기업개황으로 상장사 마스터를 채운다.
class CompanyMasterSync {
  CompanyMasterSync(
    this.session,
    this.dart,
    this.jobId, {
    this.dailyLimit = ApiCallBudget.dartDailyLimit - 100,
  });

  static const kind = 'company_master';

  /// DART 변경일에 반영되지 않는 개황 변경을 놓치지 않도록 이 주기마다 전체를 다시 받는다.
  static const fullRefreshInterval = Duration(days: 30);

  /// 마지막으로 성공한 전체 갱신 작업.
  static Future<IngestJob?> lastFullRefresh(Session session) =>
      IngestJob.db.findFirstRow(
        session,
        where: (t) =>
            t.kind.equals(kind) &
            t.fullRefresh.equals(true) &
            t.status.equals(IngestStatus.succeeded),
        orderBy: (t) => t.finishedAt.desc(),
      );

  /// 다음 전체 갱신 예정 시각. 한 번도 안 했으면 null (= 바로 필요).
  static DateTime? nextFullRefreshAt(IngestJob? lastFull) {
    final at = lastFull?.finishedAt;
    return at?.add(fullRefreshInterval);
  }

  static Future<bool> isFullRefreshDue(Session session) async {
    final next = nextFullRefreshAt(await lastFullRefresh(session));
    return next == null || !DateTime.now().toUtc().isBefore(next);
  }

  /// DART는 분당 과다 호출 시 IP를 차단한다. 초당 약 5건으로 제한.
  static const _callInterval = Duration(milliseconds: 200);
  static const _progressEvery = 20;

  final Session session;
  final DartClient dart;
  final int jobId;

  /// 이 수집이 오늘 쓸 수 있는 DART 호출 상한 (재무 수집 등 다른 수집과 합산, 약간 여유).
  final int dailyLimit;

  /// DART 요청 제한 초과.
  static const _limitExceeded = '020';
  late final _meter = ApiCallMeter(ApiProvider.dart, () => dart.calls);

  Future<void> run({required bool force}) async {
    final claimed = await IngestJobs.claim(session, jobId);
    if (claimed == null) {
      dart.close();
      return;
    }
    var job = claimed;
    try {
      await KsicSeeder.seed(session);

      final corpCodes = await dart.fetchCorpCodes();
      final withStock = corpCodes.where((c) => c.stockCode != null).toList();
      final companies = {
        for (final c in await Company.db.find(session)) c.corpCode: c,
      };
      final statuses = {
        for (final s in await DartCorpStatus.db.find(session)) s.corpCode: s,
      };

      final targets = force
          ? withStock
          : withStock
                .where(
                  (c) => _needsFetch(
                    c,
                    companies[c.corpCode],
                    statuses[c.corpCode],
                  ),
                )
                .toList();

      job = await _save(job.copyWith(total: targets.length));

      // 재무 수집이 같은 날 DART 한도를 많이 썼으면 남은 만큼만 쓰고 멈춘다.
      final allowance =
          dailyLimit - await ApiCallBudget.usedToday(session, ApiProvider.dart);
      var limitReached = false;
      var processed = 0, updated = 0, failed = 0;
      final failures = <String>[];
      for (final corp in targets) {
        if (processed % _progressEvery == 0 && await _isCancelled()) {
          job = job.copyWith(status: IngestStatus.cancelled);
          break;
        }
        if (dart.calls >= allowance) {
          limitReached = true;
          break;
        }
        try {
          final profile = await dart.fetchCompany(corp.corpCode);
          final changed = await _store(
            corp,
            profile,
            companies[corp.corpCode],
            statuses[corp.corpCode],
          );
          if (changed) updated++;
        } on DartApiException catch (e) {
          if (e.status == _limitExceeded) {
            limitReached = true;
            break;
          }
          if (e.isFatal) rethrow;
          failed++;
          if (failures.length < 10) failures.add('${corp.corpName}: $e');
          session.log(
            'company.json 실패 ${corp.corpCode}: $e',
            level: LogLevel.warning,
          );
        }
        processed++;
        if (processed % _progressEvery == 0) {
          await _meter.flush(session);
          job = await _save(
            job.copyWith(
              processed: processed,
              updated: updated,
              failed: failed,
              apiCalls: dart.calls,
            ),
          );
        }
        await Future<void>.delayed(_callInterval);
      }

      if (limitReached && job.status != IngestStatus.cancelled) {
        // 전체 갱신이 끝나지 않았으므로 성공으로 남기지 않는다 (다음 수집이 다시 전체 갱신).
        // 받은 기업은 저장되어 있고, 변경분 수집은 변경일이 남은 기업을 다시 고른다.
        await _save(
          job.copyWith(
            status: IngestStatus.failed,
            processed: processed,
            updated: updated,
            failed: failed,
            apiCalls: dart.calls,
            finishedAt: DateTime.now().toUtc(),
            message:
                'DART 일일 호출 한도에 닿아 ${targets.length}건 중 $processed건에서 멈춤. '
                '받은 것은 저장되어 있습니다. 내일 다시 수집하면 남은 기업을 받습니다.',
          ),
        );
        return;
      }

      await _save(
        job.copyWith(
          status: job.status == IngestStatus.cancelled
              ? IngestStatus.cancelled
              : IngestStatus.succeeded,
          processed: processed,
          updated: updated,
          failed: failed,
          apiCalls: dart.calls,
          finishedAt: DateTime.now().toUtc(),
          message: failures.isEmpty
              ? '${force ? '전체 갱신' : '변경분'} 대상 ${targets.length}건 (고유번호 중 종목코드 보유 ${withStock.length}건)'
              : '실패 예시: ${failures.join(' / ')}',
        ),
      );
    } catch (e, st) {
      if (e is DartApiException && e.status == _limitExceeded) {
        // 기업개황 목록(corpCode.xml)부터 한도에 걸린 경우.
        await fail(
          session,
          jobId,
          'DART 일일 호출 한도에 닿아 수집하지 못했습니다. 내일 다시 수집하세요.',
          apiCalls: dart.calls,
        );
        return;
      }
      session.log(
        '상장사 마스터 수집 실패',
        level: LogLevel.error,
        exception: e,
        stackTrace: st,
      );
      await fail(session, jobId, '$e', apiCalls: dart.calls);
    } finally {
      await _meter.flush(session);
      dart.close();
      await KsicRevision.invalidate(session);
    }
  }

  /// 작업을 실패로 끝낸다.
  static Future<void> fail(
    Session session,
    int jobId,
    String message, {
    int? apiCalls,
  }) => IngestJobs.fail(session, jobId, message, apiCalls: apiCalls);

  /// 기업개황을 다시 받아야 하는지.
  ///
  /// DART 변경일이 그대로면 건너뛴다. 상장사는 company 행으로, 상장폐지 등
  /// 저장하지 않는 기업은 수집 장부(DartCorpStatus)로 판단한다.
  static bool _needsFetch(
    DartCorpCode corp,
    Company? company,
    DartCorpStatus? status,
  ) {
    if (company != null) {
      return company.profileUpdatedAt == null ||
          company.dartModifiedDate != corp.modifyDate;
    }
    if (status != null) return status.modifiedDate != corp.modifyDate;
    return true;
  }

  /// 기업개황을 저장한다. 바뀐 내용이 있으면 true.
  ///
  /// 상장사(Y/K/N)는 저장하고, 상장폐지 등(E)은 이미 저장된 기업만 `other`로
  /// 갱신한다. 어느 경우든 수집 장부에 확인 결과를 남긴다.
  Future<bool> _store(
    DartCorpCode corp,
    Map<String, dynamic> p,
    Company? current,
    DartCorpStatus? status,
  ) async {
    final corpCls = DartValues.text(p['corp_cls']) ?? '?';
    final market = switch (corpCls) {
      'Y' => Market.kospi,
      'K' => Market.kosdaq,
      'N' => Market.konex,
      _ => Market.other,
    };
    final now = DateTime.now().toUtc();

    return session.db.transaction((tx) async {
      final nextStatus = DartCorpStatus(
        id: status?.id,
        corpCode: corp.corpCode,
        corpCls: corpCls,
        modifiedDate: corp.modifyDate,
        checkedAt: now,
      );
      if (status == null) {
        await DartCorpStatus.db.insertRow(session, nextStatus, transaction: tx);
      } else {
        await DartCorpStatus.db.updateRow(session, nextStatus, transaction: tx);
      }

      if (market == Market.other && current == null) return false;

      final industryCode = DartValues.text(p['induty_code']);
      final cls = KsicSeeder.classify(industryCode);
      final next = Company(
        id: current?.id,
        corpCode: corp.corpCode,
        name: DartValues.text(p['corp_name']) ?? corp.corpName,
        nameEng: DartValues.text(p['corp_name_eng']),
        stockName: DartValues.text(p['stock_name']),
        stockCode: DartValues.text(p['stock_code']) ?? corp.stockCode,
        market: market,
        ceoName: DartValues.text(p['ceo_nm']),
        jurirNo: DartValues.text(p['jurir_no']),
        bizrNo: DartValues.text(p['bizr_no']),
        address: DartValues.text(p['adres']),
        homepageUrl: DartValues.text(p['hm_url']),
        irUrl: DartValues.text(p['ir_url']),
        phone: DartValues.text(p['phone_num']),
        industryCode: industryCode,
        sectionCode: cls.section,
        divisionCode: cls.division,
        establishedDate: DartValues.ymd(p['est_dt']),
        fiscalMonth: DartValues.month(p['acc_mt']),
        dartModifiedDate: corp.modifyDate,
        profileUpdatedAt: now,
      );

      final changes = current == null
          ? const <FieldChange>[]
          : CompanyChanges.diff(current, next);
      // 다시 받았는데 바뀐 게 없으면 출처·이력을 늘리지 않고 확인 시각만 갱신.
      if (current != null && changes.isEmpty) {
        await Company.db.updateRow(
          session,
          current.copyWith(
            dartModifiedDate: corp.modifyDate,
            profileUpdatedAt: now,
          ),
          transaction: tx,
        );
        return false;
      }

      final source = await Source.db.insertRow(
        session,
        Source(
          kind: SourceKind.dartApi,
          title: 'DART 기업개황 (company.json)',
          reference: corp.corpCode,
          url: DartClient.companyApiUrl(corp.corpCode).toString(),
          retrievedAt: now,
        ),
        transaction: tx,
      );
      final saved = current == null
          ? await Company.db.insertRow(
              session,
              next.copyWith(profileSourceId: source.id),
              transaction: tx,
            )
          : await Company.db.updateRow(
              session,
              next.copyWith(profileSourceId: source.id),
              transaction: tx,
            );
      if (changes.isNotEmpty) {
        await CompanyChange.db.insert(session, [
          for (final c in changes)
            CompanyChange(
              companyId: saved.id!,
              field: c.field,
              oldValue: c.oldValue,
              newValue: c.newValue,
              sourceId: source.id,
              changedAt: now,
            ),
        ], transaction: tx);
      }
      return true;
    });
  }

  Future<bool> _isCancelled() => IngestJobs.isCancelled(session, jobId);

  Future<IngestJob> _save(IngestJob job) => IngestJobs.save(session, job);
}
