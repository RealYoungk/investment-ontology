/// Only our canonical authored-note URLs become internal app destinations.
String? investmentNotePath(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'alfinder.kr' ||
      uri.hasPort ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !RegExp(r'^/insights/[1-9][0-9]*$').hasMatch(uri.path)) {
    return null;
  }
  return uri.path;
}

String updateSourceLabel(String url) =>
    investmentNotePath(url) == null ? 'DART' : '투자 관점';
