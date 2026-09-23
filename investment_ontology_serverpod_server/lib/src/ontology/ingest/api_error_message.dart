/// Transport exceptions can include the complete request URI, including keys.
/// Keep the diagnostic while removing credentials before persisting or logging it.
String redactApiError(Object error, {Iterable<String> secrets = const []}) {
  var message = error.toString().replaceAllMapped(
    RegExp(r'(crtfc_key|serviceKey)=([^&\s<>]+)', caseSensitive: false),
    (match) => '${match[1]}=[REDACTED]',
  );
  for (final secret in secrets.where((value) => value.isNotEmpty)) {
    for (final value in {
      secret,
      Uri.encodeComponent(secret),
      Uri.encodeQueryComponent(secret),
    }) {
      message = message.replaceAll(value, '[REDACTED]');
    }
  }
  return message;
}
