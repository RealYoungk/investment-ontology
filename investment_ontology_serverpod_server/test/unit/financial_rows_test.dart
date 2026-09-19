import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:test/test.dart';

FinancialFact fact(
  int id,
  String name, {
  String? detail,
  int? ord,
  FinancialStatementKind statement = FinancialStatementKind.equityChanges,
}) => FinancialFact(
  id: id,
  reportId: 1,
  companyId: 1,
  bsnsYear: 2025,
  reportCode: FinancialReportCode.annual,
  fsDiv: FsDiv.consolidated,
  statement: statement,
  accountName: name,
  accountDetail: detail,
  ord: ord,
  sourceId: 1,
);

void main() {
  group('FinancialRows', () {
    test('toFacts: 금액 열을 모두 담고 잘못된 금액을 센다', () {
      final result = FinancialRows.toFacts(
        [
          {
            'sj_div': 'IS',
            'account_id': 'dart_OperatingIncomeLoss',
            'account_nm': '영업이익',
            'account_detail': '-',
            'thstrm_nm': '제 58 기 반기',
            'thstrm_amount': '89492412000000',
            'thstrm_add_amount': '146725209000000',
            'frmtrm_q_nm': '제 57 기 반기',
            'frmtrm_q_amount': '4676057000000',
            'frmtrm_add_amount': '11361329000000',
            'ord': '6',
            'currency': 'KRW',
          },
          {'sj_div': 'XX', 'account_nm': '알 수 없음'},
          {
            'sj_div': 'BS',
            'account_id': '-표준계정코드 미사용-',
            'account_nm': '기타',
            'thstrm_amount': '1.5',
          },
        ],
        reportId: 1,
        companyId: 1,
        bsnsYear: 2026,
        reportCode: FinancialReportCode.halfYear,
        fsDiv: FsDiv.consolidated,
        sourceId: 1,
      );

      expect(result.skippedRows, 1);
      expect(result.invalidAmounts, 1);
      final op = result.facts.first;
      expect(op.statement, FinancialStatementKind.incomeStatement);
      expect(op.amount, BigInt.parse('89492412000000'));
      expect(op.cumulativeAmount, BigInt.parse('146725209000000'));
      expect(op.priorQuarterName, '제 57 기 반기');
      expect(op.priorQuarterAmount, BigInt.parse('4676057000000'));
      expect(op.priorCumulativeAmount, BigInt.parse('11361329000000'));
      expect(op.accountDetail, isNull);
      expect(op.ord, 6);
      expect(result.facts.last.accountId, isNull);
    });

    test('supersessions: 같은 칸끼리, 중복 키는 나온 순서대로 짝짓는다', () {
      final previous = [
        fact(1, '배당금', detail: '이익잉여금', ord: 2),
        fact(2, '배당금', detail: '이익잉여금', ord: 1),
        fact(3, '자기주식 취득'),
        fact(4, '배당금', detail: '자본금'),
      ];
      final next = [
        fact(11, '배당금', detail: '이익잉여금', ord: 1),
        fact(12, '배당금', detail: '이익잉여금', ord: 2),
        fact(13, '배당금', detail: '자본금'),
      ];

      expect(FinancialRows.supersessions(previous, next), {
        2: 11,
        1: 12,
        4: 13,
      });
    });
  });
}
