import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/components/components.dart';
import '../../design/tokens.dart';
import 'financial_metrics.dart' show formatKrwLong;
import 'fund_financial_source_registry.dart';

List<Map<String, dynamic>> validateFundFinancialRows(dynamic raw) {
  if (raw is! List || raw.isEmpty || raw.length > 6) {
    throw const FormatException('Fund periods required');
  }
  final seen = <String>{};
  return raw.map((v) {
      if (v is! Map) throw const FormatException('Fund row required');
      final r = Map<String, dynamic>.from(v),
          pins = FundFinancialSourceRegistry.rows.where(
            (p) => p['officialUrl'] == r['officialUrl'],
          );
      if (pins.length != 1) throw const FormatException('Unbound fund PDF');
      final pin = pins.single,
          quarantine = r['numericState'] == 'pendingCashScope';
      if (pin.entries.any((e) => r[e.key] != e.value) ||
          !seen.add(r['officialUrl']) ||
          r['categorySchema'] != 'printedFundCategories' ||
          r['basis'] != 'singleFundEntity' ||
          r['periodKind'] !=
              (r['periodEnd'] == '2026-06-30'
                  ? 'ownSixMonthFiscalYear'
                  : 'ownTwelveMonthFiscalYear') ||
          r['auditStatus'] != 'opinionNotExtracted' ||
          r['currency'] != 'KRW' ||
          r['printedUnit'] != '원' ||
          r['precisionUnit'] != '1' ||
          r['regularReportCode'] != null ||
          r['xbrlAccountId'] != null ||
          r['fullStatementCollected'] != false ||
          r['extractedBy'] != 'fixedPdfTextRule' ||
          r['parserVersion'] != 'mapps-printed-fund-current-v1' ||
          r['extractionTool'] != 'pdftotext 26.02.0 -layout -enc UTF-8' ||
          !{
            'pendingCashScope',
            'partialPrintedFundCategories',
          }.contains(r['numericState']) ||
          quarantine != {'2021-12-31', '2022-12-31'}.contains(r['periodEnd']) ||
          r['accounts'] is! List ||
          r['quarantinedAccounts'] is! List ||
          (r['accounts'] as List).length != (quarantine ? 0 : 7) ||
          (r['quarantinedAccounts'] as List).length != (quarantine ? 7 : 0) ||
          r['validation'] is! Map) {
        throw const FormatException('Fund source/fiscal contract mismatch');
      }
      final a = (quarantine ? r['quarantinedAccounts'] : r['accounts']) as List;
      const metrics = [
        'assets',
        'liabilities',
        'equity',
        'fundOperatingIncome',
        'netProfit',
        'assetManagementCashFlow',
        'investmentPropertyAcquisition',
      ];
      for (var i = 0; i < a.length; i++) {
        final c = a[i];
        if (c is! Map ||
            c['metric'] != metrics[i] ||
            c['accountLabel'] is! String ||
            c['printedAmount'] is! String ||
            c['pageOrdinal'] is! int ||
            c['lineOrdinal'] is! int ||
            c['amountScope'] !=
                (i < 3 ? 'stockAtPeriodEnd' : 'ownFiscalDuration') ||
            c['cashDirection'] != (i == 6 ? 'outflow' : null)) {
          throw const FormatException('Fund category proof mismatch');
        }
        final literal = c['printedAmount'] as String;
        if (!RegExp(
          r'^(?:-?\d{1,3}(?:,\d{3})*|-?\d+|\(\d{1,3}(?:,\d{3})*\)|\(\d+\))$',
        ).hasMatch(literal)) {
          throw const FormatException('Fund integer literal required');
        }
        final amount = literal.startsWith('(')
            ? '-${literal.substring(1, literal.length - 1).replaceAll(',', '')}'
            : literal.replaceAll(',', '');
        if (BigInt.parse(amount).toString() != c['amountInteger']) {
          throw const FormatException('Fund sign/literal mismatch');
        }
      }
      return r;
    }).toList()
    ..sort((a, b) => '${b['periodEnd']}'.compareTo('${a['periodEnd']}'));
}

class FundFinancialsCard extends StatelessWidget {
  const FundFinancialsCard({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) {
    final quarantine = row['numericState'] == 'pendingCashScope',
        v = row['validation'] as Map;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          '${row['periodStart']} ~ ${row['periodEnd']} · 단일 펀드',
          style: context.typo.body(14),
        ),
        subtitle: Text(
          '${row['periodKind'] == 'ownSixMonthFiscalYear' ? '자체 6개월 회계연도' : '자체 12개월 회계연도'} · ${quarantine ? '현금 범위 불일치로 격리' : '펀드 인쇄 계정 일부'} · 감사의견 미추출',
          style: context.typo.body(12, color: context.colors.textSecondary),
        ),
        children: [
          if (row['categorySchema'] == 'printedScannedFundCategories')
            AppNotice(
              message:
                  '원본 스캔 PDF의 당기 항목 일부입니다. 두 OCR의 숫자·부호와 3자리 천단위 구분자를 검증한 정수를 표시하며 원시 OCR은 보존합니다. 모든 항목이 숫자인 검산 ${v['fullyNumericEquationCount']}개, 인쇄 대시·빈칸을 제외한 부분합 검산 ${v['missingWitnessSubtotalCount']}개입니다. 누락 표시는 0원 금액이나 완전한 등식 검증으로 취급하지 않습니다. 주석·전체 재무제표는 미검증입니다.',
            ),
          if (row['categorySchema'] == 'printedInfrastructureFundCategories')
            const AppNotice(
              message: '지정된 재무 페이지의 인쇄 금액 일부입니다. 주석과 전체 글꼴은 검증하지 않았습니다. 현금 명칭의 동등성을 추정하지 않으며 일반 기업의 영업현금흐름·TTM으로 합산하지 않습니다.',
            ),
          if (quarantine)
            AppNotice(
              message:
                  '현금 범위를 확정하지 못해 이 기간의 금액 표시는 격리했습니다. 재무상태표 현금성자산 − 현금흐름표 기말현금: 당기 ${v['currentBSCashMinusCF']}원, 비교기 ${v['comparativeBSCashMinusCF']}원. 원문 값을 고치거나 현금·예치금으로 대체하지 않았습니다.',
            )
          else
            for (final a in row['accounts'] as List)
              Tooltip(
                message: row['categorySchema'] == 'printedScannedFundCategories'
                    ? '원시 OCR: ${a['ocrText']} / ${a['independentOcrText']} · 원본 PDF ${a['pageOrdinal']}쪽 · OCR observation ${a['ocrRowIndex']} · bbox ${a['koBoundingBox']}'
                    : '${a['printedAmount']}원 · 원문 PDF ${a['pageOrdinal']}쪽, 추출 ${a['lineOrdinal']}행',
                child: KeyValueRow(
                  label: '${a['accountLabel']}',
                  labelWidth: 136,
                  value:
                      '${formatKrwLong(double.parse(a['amountInteger']))}${a['cashDirection'] == 'outflow' ? ' (유출)' : ''}',
                  numeric: true,
                ),
              ),
          Text(
            {
                  'printedInfrastructureFundCategories',
                  'printedScannedFundCategories',
                }.contains(row['categorySchema'])
                ? '운용수익·자산운용 현금흐름·대출금 및 지분 취득은 펀드 원문 항목입니다. 산업 매출·영업현금흐름·유형자산 취득 또는 TTM으로 변환하지 않습니다.'
                : '운용수익·자산운용 현금흐름·부동산 취득은 펀드 원문 항목입니다. 산업 매출·영업현금흐름·유형자산 취득 또는 TTM으로 변환하지 않습니다.',
            style: context.typo.body(12, color: context.colors.textMuted),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(row['officialUrl']),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('공식 펀드 PDF 보기'),
          ),
        ],
      ),
    );
  }
}
