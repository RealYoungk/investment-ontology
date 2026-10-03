# 선택적 Astra 검토 자료

모델 변경이나 별도 채팅은 실행하지 않았다. 필요할 때 아래 자료로 검토한다.

질문: published shad 0.99.4의 입력 단일 파일 패치가 Flutter 3.47.5의 enabled/focus/selection semantics 계약에 충분한가? readOnly/disabled 전환, semantics 병합, Focus restoration의 위험과 upstream 수정 제안은?

자료: third_party/shad/SOURCE.json, input-accessibility.patch, lib/src/components/input.dart, 앱 test/design/shad_input_accessibility_test.dart, outputs/design/shad-review/input-accessibility-tests.log.

실제 Chrome에서 enabled textbox와 포커스 후 한국어 필터링 성공. 자동 fill 최초 focus 직후 문자 누락, Meta+A 선택 미동작은 남아 있다. 외부 render-node 패치는 제거했다. VM 성공을 OS IME/VoiceOver 성공으로 해석하지 않는다.

추가 검토: nullable 선택 어댑터 AppSelect, overlay InheritedTheme.captureAll과 Material interop, 재무표 기존 폭/가변행 유지 전략.
