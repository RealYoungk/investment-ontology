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
}
