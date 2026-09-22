/// 수집 오류의 요청 주소와 인증 파라미터는 사용자 화면에 노출하지 않는다.
String safeIngestMessage(String message) => message
    .replaceAll(RegExp(r'https?://[^\s]+'), '[요청 주소 숨김]')
    .replaceAll(
      RegExp(r'(crtfc_key|servicekey|api_key)=[^&\s]+', caseSensitive: false),
      '인증키=[숨김]',
    );
