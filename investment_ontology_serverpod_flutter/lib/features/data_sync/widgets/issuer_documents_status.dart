import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/ingest_monitor.dart';
import '../../../../client.dart';
import '../../../../design/tokens.dart';

const issuerDocumentFunds = {
  '00435297': '맥쿼리인프라',
  '01880801': 'KB발해인프라',
  '00600013': '맵스리얼티',
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
  final source = input['source'];
  if (source is! Map ||
      source['kind'] != 'officialFile' ||
      input['rows'] is! List) {
    throw const FormatException('공식 출처 오류');
  }
  final sourceUri = Uri.tryParse(source['url']?.toString() ?? '');
  if (sourceUri?.scheme != 'https' ||
      sourceUri?.host != _hosts[corp] ||
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
    final u = Uri.tryParse(r['officialUrl']?.toString() ?? '');
    if (r['corpCode'] != corp ||
        r['numericState'] != 'notExtracted' ||
        r['financialValues'] != null ||
        r['publicContent'] != 'linkOnly' ||
        !{
          'auditReport',
          'assetManagementReport',
          'operatingReport',
        }.contains(r['documentType']) ||
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
                  client.research.data(corp, 'issuerDocuments'));
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
    final annual = rows
        .where(
          (r) =>
              r['documentType'] == 'auditReport' &&
              RegExp(r'^202[1-5]-01-01$').hasMatch(r['periodStart']) &&
              r['periodEnd'] ==
                  '${(r['periodStart'] as String).substring(0, 4)}-12-31',
        )
        .map((r) => '${r['corpCode']}|${r['periodEnd']}')
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
            const Text('투자회사 3곳 · 2021~2025 연간 원문과 최신 원문'),
            Text('서버 보존: 연간 $annual/15 · 최신 $latest/3'),
            const Text('KB발해인프라 2021~2023 원문 미확보 · 재무 숫자 추출 대기'),
            const Text(
              '정기보고서·사업본문·재무 숫자 집계에 포함하지 않습니다. 최신 원문에는 3개월·6개월 자료가 포함됩니다.',
            ),
            for (final entry in issuerDocumentFunds.entries)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(entry.value),
                subtitle: Text(_states[entry.key] ?? '확인 중…'),
                children: [
                  for (final row
                      in _rows[entry.key] ?? <Map<String, dynamic>>[])
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row['title'] as String),
                          Text('${row['periodStart']} ~ ${row['periodEnd']}'),
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
          ],
        ),
      ),
    );
  }
}
