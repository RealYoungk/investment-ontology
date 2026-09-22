import '../../app/router.dart';

/// A question is carried from home to the corresponding existing view.
enum ExploreIntent {
  overview('기업 이해', '무엇으로 돈을 벌까요?', '사업과 실적을 한 곳에서 살펴보세요.', '기업 개요 보기'),
  financials('실적 확인', '사업이 나아지고 있을까요?', '매출·이익·현금흐름의 변화를 확인하세요.', '재무 추이 보기'),
  compare('기업 비교', '다른 기업과 무엇이 다를까요?', '첫 기업을 고른 뒤 비교할 기업을 추가하세요.', '비교 시작하기');

  const ExploreIntent(this.label, this.question, this.description, this.action);
  final String label;
  final String question;
  final String description;
  final String action;

  static ExploreIntent fromQuery(String? value) =>
      values.asNameMap()[value] ?? overview;

  String destination(String code) => switch (this) {
    overview => AppRoutes.company(code),
    financials => AppRoutes.company(code, tab: 'financials'),
    compare => AppRoutes.compare([code]),
  };
}
