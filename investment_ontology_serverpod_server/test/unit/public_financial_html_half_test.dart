import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

void main() {
  const dir = 'test/fixtures/financial_html/wonforyou-half-20260814002145';
  final cover = File('$dir/cover.html').readAsStringSync();
  final financial = File('$dir/financial-body.html').readAsStringSync();
  final coverSource = Uri.parse(
    (jsonDecode(File('$dir/cover-source-evidence.json').readAsStringSync())
            as Map)['source']
        as String,
  );
  final source = Uri.parse(
    (jsonDecode(File('$dir/source-evidence.json').readAsStringSync())
            as Map)['financialBodyUri']
        as String,
  );
  List<Map<String, dynamic>> parse({
    String? body,
    String? coverBody,
    Uri? uri,
    bool consolidated = false,
    DateTime? start,
    DateTime? end,
    String name = '원포유',
  }) => PublicFinancialHtml.parseHalfYear(
    coverHtml: coverBody ?? cover,
    statementHtml: body ?? financial,
    coverSource: coverSource,
    statementSource: uri ?? source,
    receipt: '20260814002145',
    corpCode: '00337296',
    companyName: name,
    periodStart: start ?? DateTime.utc(2026, 1, 1),
    periodEnd: end ?? DateTime.utc(2026, 6, 30),
    consolidated: consolidated,
  );
  test('actual source separates printed quarter and cumulative income and preserves eight null-ID core rows', () {
    final rows = parse();
    expect(rows.length, 8);
    expect(rows.every((r) => r['account_id'] == null), isTrue);
    Map<String, dynamic> row(String label) => rows.firstWhere(
      (r) =>
          (r['account_nm'] as String).replaceAll(RegExp(r'\s+'), '') == label,
    );
    expect(
      [
        row('자산총계')['thstrm_amount'],
        row('부채총계')['thstrm_amount'],
        row('자본총계')['thstrm_amount'],
      ],
      ['53813466290', '30364715736', '23448750554'],
    );
    expect(
      [
        row('매출액')['thstrm_amount'],
        row('영업이익')['thstrm_amount'],
        row('반기순이익')['thstrm_amount'],
      ],
      ['2095889269', '148858512', '417050487'],
    );
    expect(
      [
        row('매출액')['thstrm_add_amount'],
        row('영업이익')['thstrm_add_amount'],
        row('반기순이익')['thstrm_add_amount'],
      ],
      ['6919979049', '380535800', '672321812'],
    );
    expect(row('영업활동으로인한현금흐름')['thstrm_amount'], '840691078');
    expect(row('유형자산의취득')['thstrm_amount'], '8560814390');
    final facts = FinancialRows.toFacts(
      rows,
      reportId: 1,
      companyId: 1,
      bsnsYear: 2026,
      reportCode: FinancialReportCode.halfYear,
      fsDiv: FsDiv.separate,
      sourceId: 1,
    );
    expect(facts.facts.length, 8);
    expect(facts.invalidAmounts, 0);
    expect(facts.facts.every((f) => f.accountId == null), isTrue);
    expect(
      facts.facts.firstWhere((f) => f.accountName == '매출액').cumulativeAmount,
      BigInt.from(6919979049),
    );
  });
  test('cover company, half-year dates, receipt and unsupported consolidated basis fail closed', () {
    expect(() => parse(name: '다른회사'), throwsFormatException);
    expect(() => parse(consolidated: true), throwsFormatException);
    expect(() => parse(start: DateTime.utc(2026, 4, 1)), throwsFormatException);
    expect(() => parse(end: DateTime.utc(2026, 9, 30)), throwsFormatException);
    expect(
      () => parse(
        uri: source.replace(
          queryParameters: {
            ...source.queryParameters,
            'rcpNo': '20260814002146',
          },
        ),
      ),
      throwsFormatException,
    );
  });
  test(
    'unknown unit, broken balance and contradictory current titles reject',
    () {
      expect(
        () => parse(body: financial.replaceAll('단위: 원', '단위: 천원')),
        throwsFormatException,
      );
      expect(
        () => parse(
          body: financial.replaceAll('53,813,466,290', '53,813,466,291'),
        ),
        throwsFormatException,
      );
      expect(
        () => parse(
          body: financial.replaceAll('2026년 01월 01일부터', '2026년 02월 01일부터'),
        ),
        throwsFormatException,
      );
    },
  );
  test('quarter/cumulative header contradictions and multiple amounts in one total group reject', () {
    expect(
      () => parse(body: financial.replaceFirst('누적', '3개월')),
      throwsFormatException,
    );
    final total = RegExp(
      r'<TR\b[^>]*>.*?840,691,078.*?</TR>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(financial)!.group(0)!;
    // Mutate the current CF total's blank first subtotal cell, retaining both values.
    final specific =
        RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
            .allMatches(financial)
            .firstWhere((m) => m.group(0)!.contains('840,691,078'))
            .group(0)!;
    final currentSubtotal = RegExp(
      r'<TD\b[^>]*>.*?</TD>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(specific).elementAt(2).group(0)!;
    final altered = specific.replaceFirst(
      currentSubtotal,
      currentSubtotal.replaceFirst('<BR/>', '99'),
    );
    expect(
      () => parse(body: financial.replaceFirst(specific, altered)),
      throwsFormatException,
    );
    expect(total, isNotEmpty);
  });
  test('annual parser continues to reject this half-year cover', () {
    expect(
      () => PublicFinancialHtml.parse(
        coverHtml: cover,
        statementHtml: financial,
        coverSource: coverSource,
        statementSource: source,
        receipt: '20260814002145',
        corpCode: '00337296',
        companyName: '원포유',
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 6, 30),
        consolidated: false,
      ),
      throwsFormatException,
    );
  });
  test(
    'duplicate current period headers and spanning income values reject',
    () {
      final duplicate = financial.replaceFirst(
        '제 28 기 반기</TH>',
        '제 29 기 반기</TH>',
      );
      expect(duplicate, isNot(financial));
      expect(() => parse(body: duplicate), throwsFormatException);
      final row =
          RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
              .allMatches(financial)
              .firstWhere((m) => m.group(0)!.contains('6,919,979,049'))
              .group(0)!;
      final current = RegExp(
        r'<TD\b[^>]*>.*?</TD>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(row).elementAt(2).group(0)!;
      final spanning = row.replaceFirst(
        current,
        current.replaceFirst('<TD', '<TD colspan="2"'),
      );
      expect(
        () => parse(body: financial.replaceFirst(row, spanning)),
        throwsFormatException,
      );
    },
  );
  test(
    'statement notes and equity profit rows do not replace income values',
    () {
      final boundary = financial.indexOf('5. 재무제표 주석');
      expect(boundary, greaterThan(0));
      final altered =
          financial.substring(0, boundary) +
          financial
              .substring(boundary)
              .replaceAll('6,919,979,049', '99')
              .replaceAll('672,321,812', '99');
      final rows = parse(body: altered);
      expect(
        rows.firstWhere((r) => r['account_nm'] == '매출액')['thstrm_add_amount'],
        '6919979049',
      );
      expect(
        rows.firstWhere((r) => r['account_nm'] == '반기순이익')['thstrm_add_amount'],
        '672321812',
      );
      expect(
        rows.firstWhere((r) => r['sj_div'] == 'BS')['thstrm_nm'],
        '2026-06-30',
      );
      expect(
        rows
            .where((r) => r['sj_div'] == 'CF')
            .every(
              (r) =>
                  r['thstrm_nm'] == '2026-01-01~2026-06-30' &&
                  !r.containsKey('thstrm_add_amount'),
            ),
        isTrue,
      );
    },
  );
}
