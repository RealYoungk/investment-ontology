import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/issuer_documents_sync.dart';

void main() {
  test(
    'cancelled, running and preexisting resume queue block startup collection',
    () {
      for (final status in [null, ...IngestStatus.values]) {
        expect(
          IssuerDocumentsSync.canResumeAtStartup(
            latestStatus: status,
            rerunning: true,
            queued: false,
          ),
          isFalse,
        );
        expect(
          IssuerDocumentsSync.canResumeAtStartup(
            latestStatus: status,
            rerunning: false,
            queued: true,
          ),
          isFalse,
        );
        expect(
          IssuerDocumentsSync.canResumeAtStartup(
            latestStatus: status,
            rerunning: false,
            queued: false,
          ),
          status != IngestStatus.running && status != IngestStatus.cancelled,
        );
      }
    },
  );
}
