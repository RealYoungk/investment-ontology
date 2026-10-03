/// 요청 주소·인증 파라미터와 내부 진행 위치는 사용자 화면에 노출하지 않는다.
String safeIngestMessage(String message) => message
    .replaceAll(
      RegExp(r' · metadata-progress-v1:[a-f0-9]{64}:[A-Za-z0-9_=-]+$'),
      '',
    )
    .replaceAll(RegExp(r'https?://[^\s]+'), '[요청 주소 숨김]')
    .replaceAll(
      RegExp(r'(crtfc_key|servicekey|api_key)=[^&\s]+', caseSensitive: false),
      '인증키=[숨김]',
    );
