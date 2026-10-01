import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';

void main() {
  final zip = File('test/fixtures/financial_xbrl/duksan-half/original.zip')
      .readAsBytesSync();
  List<Map<String, dynamic>> parse(
    List<int> data, {
    String corp = '00960623',
    int year = 2026,
    bool cfs = false,
    String receipt = '20260813000889',
  }) => PublicFinancialXbrl.parseHalfYear(
    data,
    receipt: receipt,
    corpCode: corp,
    bsnsYear: year,
    periodEnd: DateTime.utc(2026, 6, 30),
    consolidated: cfs,
    sourceUri: Uri.parse(
      'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=20260813000889&dcm_no=11523776&lang=ko',
    ),
  );
  List<int> mutate(String Function(String) transform) {
    final archive = ZipDecoder().decodeBytes(zip);
    final file = archive.files.singleWhere((f) => f.name.endsWith('.xbrl'));
    final text = transform(utf8.decode(file.content));
    archive.removeFile(file);
    archive.addFile(
      ArchiveFile(file.name, utf8.encode(text).length, utf8.encode(text)),
    );
    return ZipEncoder().encode(archive);
  }

  test('actual whole OFS quarter and cumulative amounts and contexts', () {
    final rows = parse(zip);
    expect(rows.length, 7);
    expect(rows.map((r) => r['thstrm_amount']).toList(), [
      '62819162719',
      '31242471301',
      '31576691418',
      '11795577500',
      '523580344',
      '482854478',
      '-4053641467',
    ]);
    expect(
      rows
          .where((r) => r['sj_div'] == 'CIS')
          .map((r) => r['thstrm_add_amount'])
          .toList(),
      ['23769258694', '750396681', '725163143'],
    );
    expect(
      rows.every(
        (r) =>
            r['reprt_code'] == '11012' &&
            r['account_id'] != null &&
            r['currency'] == 'KRW',
      ),
      true,
    );
  });
  test('wrong source receipt/entity/year/basis rejected', () {
    expect(() => parse(zip, receipt: '20260813000888'), throwsFormatException);
    expect(() => parse(zip, corp: '00960624'), throwsFormatException);
    expect(() => parse(zip, year: 2027), throwsFormatException);
    expect(() => parse(zip, cfs: true), throwsFormatException);
  });
  test(
    'duplicate whole current fact and misleading account labels are rejected',
    () {
      expect(
        () => parse(
          mutate((s) {
            final fact = RegExp(
              r'<ifrs-full:Assets\b[^>]*>[^<]+</ifrs-full:Assets>',
            ).firstMatch(s)!.group(0)!;
            return s.replaceFirst(fact, '$fact$fact');
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => parse(
          mutate(
            (s) => s
                .replaceAll('ifrs-full:Revenue ', 'ifrs-full:OwnerRevenue ')
                .replaceAll(
                  '</ifrs-full:Revenue>',
                  '</ifrs-full:OwnerRevenue>',
                ),
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => parse(
          mutate(
            (s) => s.replaceFirst(
              '62819162719</ifrs-full:Assets>',
              '62819162720</ifrs-full:Assets>',
            ),
          ),
        ),
        throwsFormatException,
      );
    },
  );
  for (final (name, transform) in <(String, String Function(String))>[
    (
      'duplicate unit',
      (s) => s.replaceFirst(
        '<xbrli:unit id="KRW">',
        '<xbrli:unit id="KRW"><xbrli:measure>iso4217:KRW</xbrli:measure></xbrli:unit><xbrli:unit id="KRW">',
      ),
    ),
    (
      'missing unit id',
      (s) => s.replaceFirst('<xbrli:unit id="KRW">', '<xbrli:unit>'),
    ),
    (
      'duplicate current start',
      (s) => s.replaceAll(
        '<xbrli:startDate>2026-04-01</xbrli:startDate>',
        '<xbrli:startDate>2026-04-01</xbrli:startDate><xbrli:startDate>2026-04-01</xbrli:startDate>',
      ),
    ),
    (
      'mixed instant duration',
      (s) => s.replaceAll(
        '<xbrli:instant>2026-06-30</xbrli:instant>',
        '<xbrli:instant>2026-06-30</xbrli:instant><xbrli:startDate>2026-01-01</xbrli:startDate><xbrli:endDate>2026-06-30</xbrli:endDate>',
      ),
    ),
    ('wrong quarter', (s) => s.replaceAll('2026-04-01', '2026-03-01')),
    ('wrong report kind', (s) => s.replaceAll('반기보고서', '사업보고서')),
    ('wrong currency', (s) => s.replaceAll('iso4217:KRW', 'iso4217:USD')),
    ('rounded current', (s) => s.replaceAll('decimals="0"', 'decimals="-3"')),
    (
      'wrong cumulative period',
      (s) => s.replaceAll('2026-01-01', '2026-02-01'),
    ),
  ]) {
    test(
      name,
      () => expect(() => parse(mutate(transform)), throwsFormatException),
    );
  }
}
