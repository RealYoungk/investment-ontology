import 'package:shad/shad.dart';
import 'package:investment_ontology_serverpod_flutter/features/financials/split_plan_source_registry.dart';

import '../../financials/retrospective_fund_contract.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/ingest_monitor.dart';
import 'reviewed_issuer_document_metadata.dart';
import '../../../../client.dart';
import '../../../../design/tokens.dart';

const issuerDocumentFunds = {
  '02038566': '네오뷰 · 분할 대행 원문',
  '02042949': '한화머시너리앤서비스홀딩스 · 분할 대행 원문',
  '00435297': '맥쿼리인프라',
  '01880801': 'KB발해인프라',
  '00600013': '맵스리얼티',
  '01564514': "주식회사 글로벌테크놀로지",
  '01586923': "주식회사 스카이랩스",
  '01722066': "빅웨이브로보틱스 주식회사",
  '01867688': "주식회사 와이즈플래닛컴퍼니",
  '01876251': "네오사피엔스 주식회사",
  '02029258': "한국제17호기업인수목적 주식회사",
  '02030166': "엔에이치기업인수목적34호 주식회사",
  '02032155': "케이비제34호기업인수목적 주식회사",
  '01801026': "주식회사 브릴스",
};
const _hosts = {
  '00435297': 'www.mkif.com',
  '01880801': 'kbif.co.kr',
  '00600013': 're1.miraeasset.com',
};

/// Validates public metadata, without implying extracted financial values.
List<Map<String, dynamic>> issuerDocumentRows(String raw, String corp) {
  final input = jsonDecode(raw);
  if (input is! Map ||
      !{'ready', 'notCollected', 'schemaPending'}.contains(input['state'])) {
    throw const FormatException('응답 상태 오류');
  }
  if (input['state'] != 'ready') return [];
  if (SplitPlanSourceRegistry.supports(corp)) {
    return [SplitPlanSourceRegistry.validate(corp, input)];
  }
  final source = input['source'];
  if (source is! Map ||
      source['kind'] != 'officialFile' ||
      input['rows'] is! List) {
    throw const FormatException('공식 출처 오류');
  }
  final sourceUri = Uri.tryParse(source['url']?.toString() ?? '');
  if (sourceUri?.scheme != 'https' ||
      !(_hosts[corp] == sourceUri?.host ||
          reviewedDartIssuerMetadata.any(
            (r) =>
                r['corpCode'] == corp &&
                source['url'] == 'https://dart.fss.or.kr',
          )) ||
      sourceUri!.hasPort ||
      sourceUri.userInfo.isNotEmpty) {
    throw const FormatException('출처 회사 오류');
  }
  final seen = <String>{};
  return (input['rows'] as List).map((value) {
    if (value is! Map) throw const FormatException('행 오류');
    final r = Map<String, dynamic>.from(value);
    for (final key in ['title', 'issuerQuote', 'periodQuote']) {
      if (r[key] is! String || (r[key] as String).trim().isEmpty) {
        throw FormatException('$key 오류');
      }
    }
    for (final key in ['periodStart', 'periodEnd']) {
      final v = r[key];
      final d = v is String ? DateTime.tryParse(v) : null;
      if (d == null ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v as String) ||
          d.toIso8601String().substring(0, 10) != v) {
        throw FormatException('$key 오류');
      }
    }
    if (r['provider'] == 'DART' ||
        reviewedDartIssuerMetadata.any(
          (p) => p['officialUrl'] == r['officialUrl'],
        )) {
      final matches = reviewedDartIssuerMetadata.where(
        (p) => p['corpCode'] == corp && p['officialUrl'] == r['officialUrl'],
      );
      if (matches.length != 1 ||
          r.length != matches.single.length ||
          matches.single.entries.any(
            (e) => jsonEncode(r[e.key]) != jsonEncode(e.value),
          ) ||
          !seen.add('${r['officialUrl']}|${r['sha256']}')) {
        throw const FormatException('고정 DART 메타데이터 검증 실패');
      }
      return r;
    }
    final u = Uri.tryParse(r['officialUrl']?.toString() ?? '');
    if (r['corpCode'] != corp ||
        r['numericState'] != 'notExtracted' ||
        r['financialValues'] != null ||
        r['publicContent'] != 'linkOnly' ||
        !{
              'auditReport',
              'assetManagementReport',
              'operatingReport',
            }.contains(r['documentType']) &&
            !RetrospectiveFundContract.same(
              r,
              RetrospectiveFundContract.data['metadata'],
            ) ||
        !{'officialIR', 'KIND'}.contains(r['provider']) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(r['sha256']?.toString() ?? '') ||
        u == null ||
        u.scheme != 'https' ||
        u.host != _hosts[corp] ||
        u.hasPort ||
        u.hasQuery ||
        u.hasFragment ||
        u.userInfo.isNotEmpty ||
        !u.path.endsWith('.pdf') ||
        u.path.contains('%') ||
        u.pathSegments.contains('..') ||
        !(u.path.startsWith('/upload/') ||
            u.path.startsWith('/assets/mkif/')) ||
        (r['periodStart'] as String).compareTo(r['periodEnd'] as String) > 0 ||
        !seen.add('${r['officialUrl']}|${r['sha256']}')) {
      throw const FormatException('메타데이터 검증 실패');
    }
    for (final key in ['providerReceipt', 'providerDocumentId']) {
      final value = r[key];
      if (value != null &&
          (value is! String || !RegExp(r'^\d{14}$').hasMatch(value))) {
        throw const FormatException('원접수 식별자 오류');
      }
    }
    if (r['provider'] == 'KIND' && r['providerReceipt'] == null ||
        r['provider'] == 'officialIR' &&
            (r['providerReceipt'] != null || r['providerDocumentId'] != null)) {
      throw const FormatException('제공처 식별자 오류');
    }
    return r;
  }).toList();
}

class IssuerDocumentsStatus extends StatefulWidget {
  const IssuerDocumentsStatus({super.key, this.load, this.dataVersion});
  final Future<String> Function(String)? load;
  final ValueListenable<int>? dataVersion;
  @override
  State<IssuerDocumentsStatus> createState() => _IssuerDocumentsStatusState();
}

class _IssuerDocumentsStatusState extends State<IssuerDocumentsStatus> {
  final _rows = <String, List<Map<String, dynamic>>>{};
  final _states = <String, String>{};
  late final ValueListenable<int> _version;
  int _sequence = 0;
  @override
  void initState() {
    super.initState();
    _version = widget.dataVersion ?? IngestMonitor.instance.dataVersion;
    _version.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _sequence++;
    _version.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_sequence;
    setState(() {
      _rows.clear();
      _states.clear();
    });
    await Future.wait(
      issuerDocumentFunds.keys.map((corp) async {
        List<Map<String, dynamic>> rows = [];
        String state;
        try {
          final raw =
              await (widget.load?.call(corp) ??
                  client.research.data(
                    corp,
                    SplitPlanSourceRegistry.supports(corp)
                        ? 'splitPlanDocuments'
                        : 'issuerDocuments',
                  ));
          rows = issuerDocumentRows(raw, corp);
          final response = jsonDecode(raw) as Map;
          state = response['state'] == 'ready'
              ? (rows.isEmpty ? '저장된 문서 없음' : '원문 보존')
              : response['state'] == 'schemaPending'
              ? '저장소 준비 중'
              : '서버 수집 전';
        } catch (_) {
          state = '원문 상태 확인 실패';
        }
        if (!mounted || seq != _sequence) return;
        setState(() {
          _rows[corp] = rows;
          _states[corp] = state;
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows.values.expand((r) => r).toList();
    final historical = rows
        .where(
          (r) =>
              r['documentType'] == 'auditReport' &&
              RegExp(r'^202[1-5]-').hasMatch(r['periodStart']) &&
              RegExp(r'^202[1-5]-').hasMatch(r['periodEnd']),
        )
        .map((r) => '${r['officialUrl']}|${r['sha256']}')
        .toSet()
        .length;
    final latest = rows
        .where(
          (r) =>
              r['periodEnd'] == '2026-06-30' &&
              r['periodStart'] ==
                  (r['corpCode'] == '00600013' ? '2026-01-01' : '2026-04-01'),
        )
        .map((r) => r['corpCode'])
        .toSet()
        .length;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.lg),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('공식 별도 원문', style: context.typo.sectionTitle),
            const SizedBox(height: AppSpace.sm),
            const Text('투자회사·신규 상장회사 14곳 · 공식 별도 원문(분할 대행 제출 2곳 포함)'),
            Text(
              '서버 보존: 과거 감사 원문 $historical개 · 최신 투자회사 원문 $latest/3 · 전체 ${rows.length}개',
            ),
            const Text(
              'KB발해인프라 2021~2023 당해 감사보고서 원문 미확보 · 2024-11-15 정정 투자설명서의 과거 상세표는 별도 출처입니다. 재무 탭에서 별도 수집 상태와 원문 충돌·누락을 확인합니다.',
            ),
            const Text(
              '정기보고서·사업본문·재무 숫자 집계에 포함하지 않습니다. DART 자료는 읽은 재무 장만 보존하며 전체 원문 확보를 뜻하지 않습니다. 분할 대행 원문은 신설회사 자체 연간 보고서와 구분하며 숫자를 추출하지 않습니다. 자체 과거 원문 미확보 기간은 별도 확인 중입니다.',
            ),
            for (final entry in issuerDocumentFunds.entries)
              ShadAccordion<int>(
                maintainState: true,
                children: [
                  ShadAccordionItem<int>(
                    value: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.value),
                        Text(_states[entry.key] ?? '확인 중…'),
                      ],
                    ),
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final row
                            in _rows[entry.key] ?? <Map<String, dynamic>>[])
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  SplitPlanSourceRegistry.supports(entry.key)
                                      ? '${row['filingActorPrintedName']} 대행 제출 분할 증권신고서'
                                      : row['title'] as String,
                                ),
                                Text(
                                  SplitPlanSourceRegistry.supports(entry.key)
                                      ? '제출 ${row['filingDate']} · 계획 ${row['plannedSplitDate']} · 실제 설립 ${row['actualEstablishedDate']}'
                                      : RetrospectiveFundContract.same(
                                          row,
                                          RetrospectiveFundContract
                                              .data['metadata'],
                                        )
                                      ? '정정 게시 ${row['publishedAt']} · 과거 표의 범위 ${row['periodStart']} ~ ${row['periodEnd']} (한 회계기간 아님)'
                                      : '${row['periodStart']} ~ ${row['periodEnd']}',
                                ),
                                SelectableText(
                                  row['officialUrl'] as String,
                                  style: context.typo.supportingText,
                                ),
                                Text(
                                  'SHA-256: ${row['sha256']}',
                                  style: context.typo.supportingText,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
