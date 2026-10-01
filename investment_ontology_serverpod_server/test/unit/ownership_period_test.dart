import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/governance/ownership_period.dart';

void main() {
  test(
    'December and March closing companies retain their own fiscal boundary',
    () {
      expect(
        ownershipPeriodStart(DateTime.utc(2025, 12, 31), [
          DateTime.utc(2024, 12, 31),
        ]),
        DateTime.utc(2025, 1, 1),
      );
      expect(
        ownershipPeriodStart(DateTime.utc(2025, 3, 31), [
          DateTime.utc(2024, 3, 31),
        ]),
        DateTime.utc(2024, 4, 1),
      );
    },
  );
  test(
    'No invented dates for missing end, preceding filing or a reporting gap',
    () {
      expect(ownershipPeriodStart(null, [DateTime.utc(2024, 12, 31)]), isNull);
      expect(ownershipPeriodStart(DateTime.utc(2025, 12, 31), []), isNull);
      expect(
        ownershipPeriodStart(DateTime.utc(2025, 12, 31), [
          DateTime.utc(2023, 12, 31),
        ]),
        isNull,
      );
    },
  );
  test(
    'Leap year, shortened year, unordered filings and future boundaries',
    () {
      expect(
        ownershipPeriodStart(DateTime.utc(2024, 12, 31), [
          DateTime.utc(2025, 12, 31),
          DateTime.utc(2023, 12, 31),
          DateTime.utc(2022, 12, 31),
        ]),
        DateTime.utc(2024, 1, 1),
      );
      expect(
        ownershipPeriodStart(DateTime.utc(2025, 6, 30), [
          DateTime.utc(2024, 12, 31),
        ]),
        DateTime.utc(2025, 1, 1),
      );
    },
  );
}
