/// Completion signal only. It does not retain a request/ingestion session.
abstract final class IndustryCatalogHooks {
  static void Function()? changed;

  static void onSaved(String kind, String status) {
    if (status == 'running') return;
    if (const {
      'company_master',
      'disclosures',
      'disclosures_company',
      'business_documents',
    }.contains(kind)) {
      changed?.call();
    }
  }
}
