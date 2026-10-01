import '../../generated/protocol.dart';
import 'registered_offerings.dart';

/// A registered activity supplies a minimum classification, never a verified
/// product claim. Keep the original official row and its evidence intact.
abstract final class DiscoveryCoverage {
  static List<IndustryActivity> complete(List<IndustryActivity> activities) {
    final covered = activities
        .where(
          (a) =>
              a.classificationBasis != 'ksic' &&
              a.classificationBasis != 'unclassified',
        )
        .map((a) => a.corpCode)
        .toSet();
    return [
      ...activities,
      for (final a in activities)
        if (a.classificationBasis == 'ksic' &&
            a.industryKey != 'unclassified' &&
            !covered.contains(a.corpCode))
          a.copyWith(
            classificationBasis: 'registered_activity',
            role: _group(a)?.$1 ?? a.role.replaceFirst('ksic:', 'registered:'),
            groupName: _group(a)?.$2 ?? a.groupName,
            productName: _group(a)?.$2 ?? a.productName,
            productKey: a.productKey.replaceFirst('ksic:', 'registered:'),
          ),
    ];
  }

  static (String, String)? _group(IndustryActivity a) =>
      RegisteredOfferings.group(a);
}
