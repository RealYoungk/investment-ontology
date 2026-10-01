/// IDs are public publisher identifiers, never billing credentials.
class AdConfig {
  const AdConfig({
    this.enabled = false,
    this.siteApproved = false,
    this.privacyReady = false,
    this.preview = false,
    this.publisher = '',
    this.slot = '',
    this.testMode = true,
  });
  const AdConfig.environment()
    : enabled = const bool.fromEnvironment('ADSENSE_ENABLED'),
      siteApproved = const bool.fromEnvironment('ADSENSE_SITE_APPROVED'),
      privacyReady = const bool.fromEnvironment('ADSENSE_PRIVACY_READY'),
      preview = const bool.fromEnvironment('AD_PLACEMENT_PREVIEW'),
      publisher = const String.fromEnvironment(
        'ADSENSE_PUBLISHER_ID',
        defaultValue: 'ca-pub-4209548390738211',
      ),
      slot = const String.fromEnvironment(
        'ADSENSE_SLOT_ID',
        defaultValue: '3239020318',
      ),
      testMode = const bool.fromEnvironment(
        'ADSENSE_TEST_MODE',
        defaultValue: true,
      );
  final bool enabled;
  final bool siteApproved;
  final bool privacyReady;
  final bool preview;
  final String publisher;
  final String slot;
  final bool testMode;
  bool get configured =>
      RegExp(r'^ca-pub-[0-9]{16}$').hasMatch(publisher) &&
      RegExp(r'^[0-9]{10}$').hasMatch(slot);
  bool show({required bool adFree, required bool web}) =>
      !adFree &&
      (preview ||
          (enabled && siteApproved && privacyReady && configured && web));
}
