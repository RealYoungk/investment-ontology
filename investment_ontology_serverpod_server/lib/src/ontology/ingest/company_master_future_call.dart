import 'package:serverpod/serverpod.dart';

import '../dart/dart_client.dart';
import 'company_master_sync.dart';

class CompanyMasterFutureCall extends FutureCall {
  Future<void> run(Session session, int jobId, bool force) async {
    final key = session.passwords['dartApiKey'];
    if (key == null || key.isEmpty) {
      await CompanyMasterSync.fail(session, jobId, 'DART API 키가 설정되지 않았습니다.');
      return;
    }
    await CompanyMasterSync(session, DartClient(key), jobId).run(force: force);
  }
}
