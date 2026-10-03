import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/located_own_current_source.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_cache.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/verified_annual_source_registry.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/financial/financial_accounts.dart';

import 'verified_annual_source_registry_test.dart' show company, filing;

void main() {
  test(
    'insurance7 preserves combined PPE and CE dash proof, no fabricated capex',
    () async {
      final e = VerifiedAnnualSourceRegistry.find(
        '20230314001218',
        FsDiv.consolidated,
      )!;
      final result = await VerifiedAnnualSourceCache(
        readAsset: (p) => File(p).readAsBytes(),
      ).verifyRegistered(filing(e), company(e), e.basis);
      final n = result.numeric!;
      final m = jsonDecode(
        File('${e.assetDirectory}/manifest.json').readAsStringSync(),
      ) as Map;
      expect(n.rows.length, 7);
      final opposite = await VerifiedAnnualSourceCache(
        readAsset: (p) => File(p).readAsBytes(),
      ).verifyRegistered(filing(e), company(e), FsDiv.separate);
      expect(opposite.numeric!.rows.length, 7);
      expect(
        opposite.numeric!.statementSource.toString(),
        'https://dart.fss.or.kr/report/viewer.do?rcpNo=20230314001218&dcmNo=9055696&eleId=19&offset=1314287&length=100281&dtd=dart3.xsd',
      );
      expect(m['checks'].length, 10);
      expect(m['ceMissingCurrentTotalCells'].single['literal'], '-');
      Map<String, dynamic>? project(List<Map<String, dynamic>> rows) =>
          LocatedOwnCurrentSource.storedScope(
            rows: rows,
            receipt: e.receipt,
            corp: e.corpCode,
            companyName: e.companyName,
            consolidated: true,
            source: n.statementSource,
            digest: n.sourceDigest,
          );
      expect(project(n.rows)!['coreRows'], 7);
      for (final key in [
        'combinedPPEAcquisition',
        'ceMissingCurrentTotalCells',
        'ceRollFullyNumericVerified',
        'fullyNumericMainEquationCount',
      ]) {
        final rows = (jsonDecode(jsonEncode(n.rows)) as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        rows.first['html_provenance'][key] = null;
        expect(project(rows), isNull, reason: key);
      }
      final facts = [
        for (final r in n.rows)
          FinancialFact(
            id: int.parse(r['ord']),
            reportId: 1,
            companyId: 1,
            sourceId: 1,
            bsnsYear: 2022,
            reportCode: FinancialReportCode.annual,
            fsDiv: FsDiv.consolidated,
            statement: r['sj_div'] == 'BS'
                ? FinancialStatementKind.balanceSheet
                : r['sj_div'] == 'CF'
                ? FinancialStatementKind.cashFlow
                : FinancialStatementKind.comprehensiveIncome,
            accountName: r['account_nm'],
            amount: BigInt.parse(r['thstrm_amount']),
          ),
      ];
      final lines = FinancialAccounts.pick(facts).toList();
      expect(lines.length, 7);
      expect(lines.any((l) => l.key == 'capex'), false);
      expect(
        lines.singleWhere((l) => l.key == 'netIncome').amount,
        BigInt.from(219230965661),
      );
    },
  );
}
