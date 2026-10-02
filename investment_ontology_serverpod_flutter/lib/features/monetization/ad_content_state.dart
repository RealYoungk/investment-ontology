/// Inventory is eligible only while actual publisher content is available.
/// This does not replace account, consent, membership or approval gates.
class AdContentState {
  const AdContentState({
    required this.loading,
    required this.failed,
    required this.itemCount,
  });
  final bool loading;
  final bool failed;
  final int itemCount;
  bool get allowsAd => !loading && !failed && itemCount > 0;
}
