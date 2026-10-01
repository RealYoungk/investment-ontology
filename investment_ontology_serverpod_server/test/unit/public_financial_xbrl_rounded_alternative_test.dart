import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  final fixture = File('test/fixtures/financial_xbrl/sunjin_20250318001380.zip')
      .readAsBytesSync();
  List<int> mutate(void Function(XmlElement) change) {
    final a = ZipDecoder().decodeBytes(fixture);
    final f = a.files.singleWhere((v) => v.name.endsWith('.xbrl'));
    final root = XmlDocument.parse(utf8.decode(f.content)).rootElement;
    change(root);
    return ZipEncoder().encodeBytes(
      Archive()
        ..addFile(ArchiveFile.bytes(f.name, utf8.encode(root.toXmlString()))),
    );
  }

  List<Map<String, dynamic>> parse(List<int> zip, bool consolidated) =>
      PublicFinancialXbrl.parse(
        zip,
        receipt: '20250318001380',
        corpCode: '00855093',
        bsnsYear: 2024,
        periodEnd: DateTime.utc(2024, 12, 31),
        consolidated: consolidated,
      );
  String context(bool consolidated) =>
      'CFY2024dFY_ifrs-full_ConsolidatedAndSeparateFinancialStatementsAxis_ifrs-full_${consolidated ? 'ConsolidatedMember' : 'SeparateMember'}';
  XmlElement fact(XmlElement root, String name, bool consolidated) =>
      root.children.whereType<XmlElement>().singleWhere(
        (f) =>
            f.name.local == name &&
            f.getAttribute('contextRef') == context(consolidated),
      );
  for (final con in [true, false]) {
    test(
      'actual Sunjin current $con exact amounts survive rounded alternate',
      () {
        final rows = parse(fixture, con);
        final values = {
          for (final r in rows) r['account_id']: r['thstrm_amount'],
        };
        expect(
          values,
          containsPair(
            'ifrs-full_Assets',
            con ? '1284229686805' : '904888047067',
          ),
        );
        expect(
          values,
          containsPair(
            'ifrs-full_Liabilities',
            con ? '820884083784' : '447315816589',
          ),
        );
        expect(
          values,
          containsPair(
            'ifrs-full_Equity',
            con ? '463345603021' : '457572230478',
          ),
        );
        expect(
          values,
          containsPair(
            'ifrs-full_Revenue',
            con ? '1681370807177' : '1016312023275',
          ),
        );
        expect(
          values,
          containsPair(
            'dart_OperatingIncomeLoss',
            con ? '124085515096' : '48805191044',
          ),
        );
        expect(
          values,
          containsPair(
            'ifrs-full_ProfitLoss',
            con ? '6642150612' : '12958346777',
          ),
        );
        expect(
          values,
          containsPair(
            'ifrs-full_CashFlowsFromUsedInOperatingActivities',
            con ? '122582294279' : '103732650784',
          ),
        );
        expect(
          values.containsKey('ifrs-full_RevenueFromContractsWithCustomers'),
          isFalse,
        );
        expect(
          rows.every(
            (r) =>
                r['thstrm_nm'] == '2024-01-01~2024-12-31' &&
                r['corp_code'] == '00855093',
          ),
          isTrue,
        );
      },
    );
    test('$con rounded alternate alone is still rejected', () {
      expect(
        () => parse(
          mutate((root) => root.children.remove(fact(root, 'Revenue', con))),
          con,
        ),
        throwsFormatException,
      );
    });
    test(
      '$con precise Revenue in another context cannot rescue rounded alternate',
      () {
        expect(
          () => parse(
            mutate(
              (root) => fact(root, 'Revenue', con).setAttribute(
                'contextRef',
                'PFY2023dFY_ifrs-full_ConsolidatedAndSeparateFinancialStatementsAxis_ifrs-full_${con ? 'ConsolidatedMember' : 'SeparateMember'}',
              ),
            ),
            con,
          ),
          throwsFormatException,
        );
      },
    );
    test(
      '$con exact alternate conflicts cannot be hidden by precise Revenue',
      () {
        expect(
          () => parse(
            mutate((root) {
              final f = fact(root, 'RevenueFromContractsWithCustomers', con)
                ..setAttribute('decimals', '0');
              root.children.add(f.copy()..innerText = '1');
            }),
            con,
          ),
          throwsFormatException,
        );
      },
    );
    test('$con conflicting exact Revenue still rejects whole source', () {
      expect(
        () => parse(
          mutate(
            (root) => root.children.add(
              fact(root, 'Revenue', con).copy()..innerText = '1',
            ),
          ),
          con,
        ),
        throwsFormatException,
      );
    });
    test('$con foreign unit on rounded alternate cannot be ignored', () {
      expect(
        () => parse(
          mutate(
            (root) => fact(
              root,
              'RevenueFromContractsWithCustomers',
              con,
            ).setAttribute('unitRef', 'FOREIGN'),
          ),
          con,
        ),
        throwsFormatException,
      );
    });
    test('$con rounded mandatory assets remain rejected', () {
      expect(
        () => parse(
          mutate((root) {
            root.children
                .whereType<XmlElement>()
                .firstWhere(
                  (f) =>
                      f.name.local == 'Assets' &&
                      f.getAttribute('contextRef') ==
                          'CFY2024eFY_ifrs-full_ConsolidatedAndSeparateFinancialStatementsAxis_ifrs-full_${con ? 'ConsolidatedMember' : 'SeparateMember'}',
                )
                .setAttribute('decimals', '-3');
          }),
          con,
        ),
        throwsFormatException,
      );
    });
  }
}
