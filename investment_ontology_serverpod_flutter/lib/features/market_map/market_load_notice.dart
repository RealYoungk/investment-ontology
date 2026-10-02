import '../../design/components/read_failure_notice.dart';

/// Compatibility name for market sections using the shared recovery UI.
class MarketLoadNotice extends ReadFailureNotice {
  const MarketLoadNotice({
    super.key,
    required super.subject,
    required super.retry,
  });
}
