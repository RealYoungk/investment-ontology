/// Inventory is eligible only while actual publisher content is available.
/// This does not replace account, consent, membership or approval gates.
class AdContentState {
  const AdContentState({
    required this.loading,
    required this.failed,
    required this.itemCount,
    this.contentRemainsVisible = false,
  });
  final bool loading;
  final bool failed;
  final int itemCount;

  /// Existing publisher rows may remain visible during a background refresh.
  /// Keeping their mounted slot prevents automatic inventory refresh.
  final bool contentRemainsVisible;
  bool get allowsAd =>
      !failed && itemCount > 0 && (!loading || contentRemainsVisible);
}
