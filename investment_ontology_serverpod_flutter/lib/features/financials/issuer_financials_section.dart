import 'mkif_halfyear_five_validator.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client.dart';
import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'financial_metrics.dart' show formatKrwLong;
import 'issuer_financial_source_registry.dart';
import 'own_annual_financial_source_registry.dart';
import 'fund_financials_card.dart';
import 'infrastructure_fund_financials_validator.dart';
import 'scanned_fund_financials_validator.dart';
import 'retrospective_fund_contract.dart';
import 'retrospective_fund_card.dart';

/// Stored alternate-source current observations; never substitutes regular reports.
class IssuerFinancialsSection extends StatefulWidget {
  const IssuerFinancialsSection({
    super.key,
    required this.corpCode,
    this.dataVersion = 0,
    this.loader,
    this.ownAnnual = false,
  });
  final String corpCode;
  final bool ownAnnual;
  final int dataVersion;
  final Future<String> Function(String, String)? loader;
  @override
  State<IssuerFinancialsSection> createState() =>
      _IssuerFinancialsSectionState();
}

class _IssuerFinancialsSectionState extends State<IssuerFinancialsSection> {
  List<Map<String, dynamic>>? _rows;
  Object? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant IssuerFinancialsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.corpCode != widget.corpCode ||
        oldWidget.dataVersion != widget.dataVersion ||
        oldWidget.ownAnnual != widget.ownAnnual) {
      _load();
    }
  }

  bool get _supported => widget.ownAnnual
      ? OwnAnnualFinancialSourceRegistry.supportsCorp(widget.corpCode)
      : IssuerFinancialSourceRegistry.supportsCorp(widget.corpCode);
  Future<void> _load() async {
    final request = ++_request;
    if (!_supported) return;
    setState(() {
      _rows = null;
      _error = null;
    });
    try {
      final value = jsonDecode(
        await (widget.loader ?? client.research.data)(
          widget.corpCode,
          widget.ownAnnual ? 'issuerAnnualFinancials' : 'issuerFinancials',
        ),
      ) as Map;
      if (!{'ready', 'notCollected'}.contains(value['state'])) {
        throw const FormatException('Alternate financial read state failed');
      }
      if (value['state'] == 'ready' &&
          (value['provider'] !=
                  (widget.ownAnnual
                      ? 'verified-own-annual-html-rule'
                      : {
                          '00600013',
                          '00435297',
                          '01880801',
                        }.contains(widget.corpCode)
                      ? 'verified-primary-pdf-text-rule'
                      : 'verified-primary-html-rule') ||
              value['source'] is! Map ||
              value['source']['kind'] != 'officialFile' ||
              value['source']['url'] !=
                  ({
                        '00600013',
                        '00435297',
                        '01880801',
                      }.contains(widget.corpCode)
                      ? {
                          '00600013': 'https://re1.miraeasset.com',
                          '00435297': 'https://www.mkif.com',
                          '01880801': 'https://kbif.co.kr',
                        }[widget.corpCode]
                      : 'https://dart.fss.or.kr'))) {
        throw const FormatException('Alternate snapshot source mismatch');
      }
      final rows = value['state'] == 'ready'
          ? validateIssuerFinancialRows(
              value['rows'],
              ownAnnual: widget.ownAnnual,
            )
          : <Map<String, dynamic>>[];
      if (rows.any((r) => r['corpCode'] != widget.corpCode)) {
        throw const FormatException('Alternate response issuer mismatch');
      }
      if (widget.ownAnnual &&
          value['state'] == 'ready' &&
          value['source']['reference'] !=
              'source-bound-own-annual-core;no-api-report-or-xbrl-assertion') {
        throw const FormatException('Own annual source reference mismatch');
      }
      if (!mounted || request != _request) return;
      setState(() => _rows = rows);
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const SizedBox.shrink();
    }
    final rows = _rows;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.ownAnnual ? '자체 연간 감사 원문 · 핵심 재무' : '별도 공식 원문 핵심 재무',
            style: context.typo.body(16),
          ),
          const SizedBox(height: AppSpace.sm),
          AppNotice(
            message: widget.ownAnnual
                ? '각 연도 자체 감사보고서의 현재기간만 추출합니다. 일반기업회계기준과 한국채택국제회계기준을 구분하며, 후속 보고서의 비교 숫자로 과거 연도를 덮어쓰지 않습니다. 전체 재무제표·주석·TTM은 미완료입니다.'
                : '공식 원문의 현재기간 핵심계정 일부입니다. 전체 재무제표·비교기간은 미추출이며 정기보고서 집계·TTM에 포함하지 않습니다. 각 문서의 현재기간만 표시하며, 문서 내 비교기간과 미확인 연간자료는 포함하지 않습니다.',
          ),
          const SizedBox(height: AppSpace.md),
          if (_error != null)
            ReadFailureNotice(subject: '별도 공식 원문 재무', retry: _load)
          else if (rows == null)
            const LinearProgressIndicator(minHeight: 2)
          else if (rows.isEmpty)
            Text(
              '별도 원문 핵심 재무 수집 전입니다.',
              style: context.typo.body(13, color: context.colors.textMuted),
            )
          else ...[
            if (widget.ownAnnual)
              Text(
                [
                  for (final year in [2021, 2022, 2023, 2024, 2025])
                    '$year: ${rows.any((r) => (r["periodEnd"] as String).startsWith("$year")) ? "자체 원문 핵심계정" : "자체 원문 미확인"}',
                ].join(' · '),
                style: context.typo.body(12),
              ),
            for (final row in rows)
              if ({
                'printedFundCategories',
                'printedInfrastructureFundCategories',
                MkifHalfYearFiveValidator.category,
                'printedScannedFundCategories',
                RetrospectiveFundContract.category,
              }.contains(row['categorySchema']))
                row['categorySchema'] == RetrospectiveFundContract.category
                    ? RetrospectiveFundCard(row: row)
                    : FundFinancialsCard(row: row)
              else
                _PeriodCard(row: row),
          ],
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> validateIssuerFinancialRows(
  dynamic raw, {
  bool ownAnnual = false,
}) {
  if (!ownAnnual &&
      raw is List &&
      raw.isNotEmpty &&
      raw.every(
        (r) =>
            r is Map &&
            {
              'printedInfrastructureFundCategories',
              MkifHalfYearFiveValidator.category,
              'printedScannedFundCategories',
              RetrospectiveFundContract.category,
            }.contains(r['categorySchema']),
      )) {
    if (raw.length > 5 ||
        raw.map((r) => r['corpCode']).toSet().length != 1 ||
        raw
                .map(
                  (r) =>
                      '${r['officialUrl']}|${r['periodStart']}|${r['periodEnd']}',
                )
                .toSet()
                .length !=
            raw.length) {
      throw const FormatException('Bound same-issuer fund years required');
    }
    final retrospective = raw
        .where((r) => r['categorySchema'] == RetrospectiveFundContract.category)
        .toList();
    final text = raw
            .where(
              (r) =>
                  r['categorySchema'] == 'printedInfrastructureFundCategories',
            )
            .toList(),
        scans = raw
            .where((r) => r['categorySchema'] == 'printedScannedFundCategories')
            .toList();
    return [
      if (raw.any(
        (r) => r['categorySchema'] == MkifHalfYearFiveValidator.category,
      ))
        ...MkifHalfYearFiveValidator.validateRows(
          raw
              .where(
                (r) =>
                    r['categorySchema'] == MkifHalfYearFiveValidator.category,
              )
              .toList(),
        ),
      if (text.isNotEmpty) ...validateInfrastructureFundRows(text),
      if (scans.isNotEmpty) ...validateScannedFundRows(scans),
      if (retrospective.isNotEmpty)
        ...RetrospectiveFundContract.validateRows(retrospective),
    ]..sort((a, b) => '${b['periodEnd']}'.compareTo('${a['periodEnd']}'));
  }
  if (raw is List &&
      raw.isNotEmpty &&
      raw.first is Map &&
      raw.first['categorySchema'] == 'printedFundCategories') {
    return validateFundFinancialRows(raw);
  }
  if (raw is! List || raw.isEmpty || raw.length > 5) {
    throw const FormatException('Missing alternate financial rows');
  }
  final seen = <String>{};
  final rows = raw.map((value) {
    final row = Map<String, dynamic>.from(value as Map);
    final matches =
        (ownAnnual
                ? OwnAnnualFinancialSourceRegistry.rows
                : IssuerFinancialSourceRegistry.rows)
            .where(
              (r) =>
                  r['corpCode'] == row['corpCode'] &&
                  r['providerReceipt'] == row['providerReceipt'],
            );
    if (matches.length != 1) {
      throw const FormatException('Unsupported alternate numeric issuer');
    }
    final pin = matches.single;
    if ([
          'corpCode',
          'providerReceipt',
          'periodStart',
          'periodEnd',
          'officialUrl',
          'sha256',
          'documentType',
          'periodKind',
          'auditStatus',
          if (ownAnnual) ...[
            'accountingStandard',
            'auditOpinionUrl',
            'auditOpinionSha256',
          ],
        ].any((k) => row[k] != pin[k]) ||
        !(pin['bases'] as List).contains(row['basis']) ||
        row['numericState'] != 'partialCore' ||
        row['extractedBy'] != 'fixedHtmlRule' ||
        row['currency'] != 'KRW' ||
        row['printedUnit'] != '원' ||
        row['precisionUnit'] != '1' ||
        row['regularReportCode'] != null ||
        row['xbrlAccountId'] != null ||
        row['publicContent'] != 'sourceLinkAndValues' ||
        !seen.add('${row['providerReceipt']}|${row['basis']}') ||
        row['accounts'] is! List ||
        (row['accounts'] as List).length != pin['accountCount']) {
      throw const FormatException('Alternate source/period mismatch');
    }
    for (final a in row['accounts'] as List) {
      if (a is! Map ||
          a['accountLabel'] is! String ||
          BigInt.tryParse('${a['amountInteger']}') == null ||
          a['printedAmount'] is! String ||
          !{'instant', 'cumulative'}.contains(a['amountScope'])) {
        throw const FormatException('Invalid printed account');
      }
    }
    return row;
  }).toList();
  rows.sort((a, b) {
    final date = '${b['periodEnd']}'.compareTo('${a['periodEnd']}');
    return date != 0 ? date : '${a['basis']}'.compareTo('${b['basis']}');
  });
  return rows;
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final annual = row['periodKind'] == 'ownAnnual';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          '${row['periodStart']} ~ ${row['periodEnd']} · ${row['basis'] == 'CFS' ? '연결' : '별도'}',
          style: context.typo.body(14),
        ),
        subtitle: Text(
          annual
              ? '자체 감사보고서 · 현재기간${row['accountingStandard'] == null
                    ? ''
                    : row['accountingStandard'] == 'KIFRS'
                    ? ' · 한국채택국제회계기준'
                    : ' · 일반기업회계기준'}'
              : '${row['documentType'] == 'prospectus' ? '투자설명서' : '증권신고서'} · ${row['periodKind'] == 'sinceIncorporation' ? '설립일부터 누적' : '반기 누적 6개월'} · ${row['auditStatus'] == 'reviewed'
                    ? '검토'
                    : row['auditStatus'] == 'audited'
                    ? '원문 적정 의견'
                    : '원문 의견 미표기'}',
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
        children: [
          for (final a in row['accounts'] as List)
            Tooltip(
              message: '${a['printedAmount']}원 · 원문 인쇄값',
              child: KeyValueRow(
                label: '${a['accountLabel']}',
                labelWidth: 136,
                value:
                    '${formatKrwLong(double.parse(a['amountInteger']))}${a['cashDirection'] == 'outflow'
                        ? ' (유출)'
                        : a['incomeDirection'] == 'lossMagnitude'
                        ? ' (손실)'
                        : ''}',
                numeric: true,
              ),
            ),
          if (row['unextractedMetrics'] is List &&
              (row['unextractedMetrics'] as List).isNotEmpty)
            Text(
              row['accountingStandard'] != null
                  ? '유형자산 전체 취득 총액은 원문 단일 셀로 인쇄되지 않아 추출하지 않았습니다. 세부 취득 내역을 임의 합산하지 않습니다.'
                  : '매출의 대시 표기와 확인되지 않은 유형자산 취득액은 0으로 채우지 않았습니다.',
              style: context.typo.body(12, color: context.colors.textMuted),
            ),
          Text(
            '금액은 원문 부호를 유지합니다. 자산·부채·자본은 기말, 손익·현금흐름은 누적입니다.',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(row['officialUrl']),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('DART 원문 재무 절 보기'),
          ),
          if (row['auditOpinionUrl'] != null)
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(row['auditOpinionUrl']),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('해당 연도 감사의견 원문 보기'),
            ),
        ],
      ),
    );
  }
}
