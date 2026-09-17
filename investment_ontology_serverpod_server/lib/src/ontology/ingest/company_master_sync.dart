import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../dart/dart_client.dart';
import 'ksic_seeder.dart';

/// DART 고유번호 목록 + 기업개황으로 상장사 마스터를 채운다.
class CompanyMasterSync {
  CompanyMasterSync(this.session, this.dart, this.jobId);

  static const kind = 'company_master';

  /// DART는 분당 과다 호출 시 IP를 차단한다. 초당 약 5건으로 제한.
  static const _callInterval = Duration(milliseconds: 200);
  static const _progressEvery = 20;

  final Session session;
  final DartClient dart;
  final int jobId;

  Future<void> run({required bool force}) async {
    var job = (await IngestJob.db.findById(session, jobId))!;
    try {
      await KsicSeeder.seed(session);

      final corpCodes = await dart.fetchCorpCodes();
      final withStock = corpCodes.where((c) => c.stockCode != null).toList();
      final existing = {
        for (final c in await Company.db.find(session)) c.corpCode: c,
      };

      // 변경일이 같고 이미 개황을 받은 기업은 건너뛴다.
      final targets = withStock.where((c) {
        final e = existing[c.corpCode];
        return force ||
            e == null ||
            e.profileUpdatedAt == null ||
            e.dartModifiedDate != c.modifyDate;
      }).toList();

      job = await _save(job.copyWith(total: targets.length));

      var processed = 0, updated = 0, failed = 0;
      final failures = <String>[];
      for (final corp in targets) {
        if (processed % _progressEvery == 0 && await _isCancelled()) {
          job = job.copyWith(status: IngestStatus.cancelled);
          break;
        }
        try {
          final profile = await dart.fetchCompany(corp.corpCode);
          if (await _upsert(corp, profile, existing[corp.corpCode])) updated++;
        } on DartApiException catch (e) {
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
              ? '대상 ${targets.length}건 (고유번호 중 종목코드 보유 ${withStock.length}건)'
              : '실패 예시: ${failures.join(' / ')}',
        ),
      );
    } catch (e, st) {
      session.log(
        '상장사 마스터 수집 실패',
        level: LogLevel.error,
        exception: e,
        stackTrace: st,
      );
      final latest = await IngestJob.db.findById(session, jobId) ?? job;
      await _save(
        latest.copyWith(
          status: IngestStatus.failed,
          apiCalls: dart.calls,
          finishedAt: DateTime.now().toUtc(),
          message: '$e',
        ),
      );
    } finally {
      dart.close();
    }
  }

  /// 기업개황 원문을 저장. 상장사(Y/K/N)이거나 이미 있는 기업만 반영.
  Future<bool> _upsert(
    DartCorpCode corp,
    Map<String, dynamic> p,
    Company? current,
  ) async {
    final market = switch (p['corp_cls']) {
      'Y' => Market.kospi,
      'K' => Market.kosdaq,
      'N' => Market.konex,
      _ => Market.other,
    };
    if (market == Market.other && current == null) return false;

    String? s(String key) {
      final v = (p[key] as String?)?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final industryCode = s('induty_code');
    final cls = KsicSeeder.classify(industryCode);
    final now = DateTime.now().toUtc();

    return session.db.transaction((tx) async {
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
      final next = Company(
        id: current?.id,
        corpCode: corp.corpCode,
        name: s('corp_name') ?? corp.corpName,
        nameEng: s('corp_name_eng'),
        stockName: s('stock_name'),
        stockCode: s('stock_code') ?? corp.stockCode,
        market: market,
        ceoName: s('ceo_nm'),
        jurirNo: s('jurir_no'),
        bizrNo: s('bizr_no'),
        address: s('adres'),
        homepageUrl: s('hm_url'),
        irUrl: s('ir_url'),
        phone: s('phone_num'),
        industryCode: industryCode,
        sectionCode: cls.section,
        divisionCode: cls.division,
        establishedDate: s('est_dt'),
        fiscalMonth: int.tryParse(s('acc_mt') ?? ''),
        dartModifiedDate: corp.modifyDate,
        profileSourceId: source.id,
        profileUpdatedAt: now,
      );
      if (current == null) {
        await Company.db.insertRow(session, next, transaction: tx);
      } else {
        await Company.db.updateRow(session, next, transaction: tx);
      }
      return true;
    });
  }

  Future<bool> _isCancelled() async {
    final j = await IngestJob.db.findById(session, jobId);
    return j?.status == IngestStatus.cancelled;
  }

  Future<IngestJob> _save(IngestJob job) async {
    // 취소 요청은 덮어쓰지 않는다.
    if (job.status == IngestStatus.running && await _isCancelled()) {
      job = job.copyWith(status: IngestStatus.cancelled);
    }
    return IngestJob.db.updateRow(session, job);
  }
}
