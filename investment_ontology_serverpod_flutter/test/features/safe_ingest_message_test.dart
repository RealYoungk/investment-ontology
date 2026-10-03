import 'package:flutter_test/flutter_test.dart';
import 'package:investment_ontology_serverpod_flutter/features/data_sync/safe_ingest_message.dart';

void main() {
  test('오류에서 요청 URL과 인증 파라미터를 숨긴다', () {
    final result = safeIngestMessage(
      '실패 https://example.test/api?crtfc_key=test-secret&x=1 ServiceKey=another-secret',
    );
    expect(result, isNot(contains('test-secret')));
    expect(result, isNot(contains('another-secret')));
    expect(result, contains('실패'));
  });
  test('일반 처리 기록은 유지한다', () {
    expect(safeIngestMessage('100건 완료'), '100건 완료');
  });
  test('재개 안내는 유지하고 내부 진행 위치는 화면에서 숨긴다', () {
    const note = '원접수 표지 확인 2건 다음 실행 재개 · 미시도 묶음 30초 후 정상 재개';
    final scope = List.filled(64, 'a').join();
    expect(
      safeIngestMessage('$note · metadata-progress-v1:$scope:eyJ2IjoxfQ=='),
      note,
    );
  });
}
