/// A direct issuer declaration in the opening business source, not an investee.
abstract final class HoldingSourceScope {
  static bool declaresHolding(String text) => RegExp(
    r'(?:당사|회사)(?:는|은)\s*(?:순수\s*|사업\s*|금융\s*)?지주회사(?:로서|입니다|로\s*(?:전환|출범))',
  ).hasMatch(text.substring(0, text.length < 4000 ? text.length : 4000));
}
