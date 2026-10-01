import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_report_name.dart';
import 'package:test/test.dart';

void main() {
  group('DartReportName', () {
    test('정기보고서 이름과 앞 표시를 읽는다', () {
      final r = DartReportName.parse('[기재정정][첨부추가]사업보고서 (2025.12)')!;
      expect(r.kind, DartReportKind.annual);
      expect(r.periodYear, 2025);
      expect(r.periodMonth, 12);
      expect(r.tags, ['기재정정', '첨부추가']);
      expect(DartReportName.parse('반기보고서 (2026.06)')!.tags, isEmpty);
    });

    test('정기보고서가 아니면 null', () {
      expect(DartReportName.parse('주요사항보고서(자기주식취득결정)'), isNull);
      expect(DartReportName.parse('사업보고서 (2025.13)'), isNull);
      expect(DartReportName.parse('소액공모법인결산서류 (2025.12)'), isNull);
    });

    test('12월 결산: 보고서 코드와 사업연도', () {
      ({String reportCode, int bsnsYear})? resolve(String name) =>
          DartReportName.parse(name)!.resolve(12);

      expect(resolve('사업보고서 (2025.12)'), (reportCode: '11011', bsnsYear: 2025));
      expect(resolve('분기보고서 (2026.03)'), (reportCode: '11013', bsnsYear: 2026));
      expect(resolve('반기보고서 (2026.06)'), (reportCode: '11012', bsnsYear: 2026));
      expect(resolve('분기보고서 (2025.09)'), (reportCode: '11014', bsnsYear: 2025));
    });

    test('4월 결산: 회계연도가 끝나는 해가 사업연도', () {
      ({String reportCode, int bsnsYear})? resolve(String name) =>
          DartReportName.parse(name)!.resolve(4);

      expect(resolve('사업보고서 (2026.04)'), (reportCode: '11011', bsnsYear: 2026));
      expect(resolve('반기보고서 (2025.10)'), (reportCode: '11012', bsnsYear: 2026));
      expect(resolve('분기보고서 (2026.01)'), (reportCode: '11014', bsnsYear: 2026));
    });

    test('과거 결산 변경과 리츠의 두 연간 기간은 현재 개황 결산월에 의존하지 않는다', () {
      for (final name in [
        '사업보고서 (2025.03)',
        '사업보고서 (2025.09)',
        '[기재정정]사업보고서 (2025.06)',
      ]) {
        expect(DartReportName.parse(name)!.resolve(12), (
          reportCode: '11011',
          bsnsYear: 2025,
        ));
      }
      expect(DartReportName.parse('사업보고서 (2024.06)')!.resolve(3), (
        reportCode: '11011',
        bsnsYear: 2024,
      ));
      expect(DartReportName.parse('분기보고서 (2025.06)')!.resolve(12), isNull);
    });
    test('결산월과 맞지 않으면 추측하지 않는다', () {
      expect(DartReportName.parse('반기보고서 (2026.03)')!.resolve(12), isNull);
      expect(DartReportName.parse('분기보고서 (2026.06)')!.resolve(12), isNull);
      expect(DartReportName.parse('반기보고서 (2026.06)')!.resolve(null), isNull);
      expect(
        DartReportName.parse('사업보고서 (2026.06)')!.resolve(null),
        (reportCode: '11011', bsnsYear: 2026),
      );
    });
  });
}
