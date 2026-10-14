import '../../generated/protocol.dart';
import 'scoped_order_fact_projection.dart';

/// Compatibility entrypoint; all implementation belongs to the scoped reader.
abstract final class StoredOrderFactProjection {
  static bool handles(DocumentFact fact) =>
      ScopedOrderFactProjection.handles(fact);
  static List<DocumentFact> revalidate(
    List<DocumentFact> facts,
    String text, {
    String? companyName,
  }) => ScopedOrderFactProjection.revalidate(
    facts,
    text,
    companyName: companyName,
  );
  static String? explicitScope(
    String text,
    String evidence, {
    String? companyName,
  }) => ScopedOrderFactProjection.explicitScope(
    text,
    evidence,
    companyName: companyName,
  );
}
