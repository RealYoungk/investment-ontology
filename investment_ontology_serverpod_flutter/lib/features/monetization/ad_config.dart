/// IDs are public publisher identifiers, never billing credentials.
class AdConfig {
  const AdConfig({
    this.enabled = false,
    this.preview = false,
    this.publisher = '',
    this.slot = '',
    this.testMode = true,
  });
  const AdConfig.environment()
    : enabled = const bool.fromEnvironment('ADSENSE_ENABLED'),
      preview = const bool.fromEnvironment('AD_PLACEMENT_PREVIEW'),
      publisher = const String.fromEnvironment('ADSENSE_PUBLISHER_ID'),
      slot = const String.fromEnvironment('ADSENSE_SLOT_ID'),
      testMode = const bool.fromEnvironment(
        'ADSENSE_TEST_MODE',
        defaultValue: true,
      );
  final bool enabled;
  final bool preview;
  final String publisher;
  final String slot;
  final bool testMode;
  bool get configured =>
      RegExp(r'^ca-pub-[0-9]{16}$').hasMatch(publisher) &&
      RegExp(r'^[0-9]{10}$').hasMatch(slot);
  bool show({required bool adFree, required bool web}) =>
      !adFree && (preview || (enabled && configured && web));
}
