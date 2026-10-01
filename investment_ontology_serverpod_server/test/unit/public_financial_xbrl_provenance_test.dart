import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';

void main() {
  for (final item in [
    (
      'cosnine_20250409002838.zip',
      '20250409002838',
      '00442455',
      2024,
      DateTime.utc(2024, 12, 31),
      '2024-01-01',
      '2024-12-31',
      true,
    ),
    (
      '20250110000545.zip',
      '20250110000545',
      '01669226',
      2024,
      DateTime.utc(2024, 10, 31),
      '2024-05-01',
      '2024-10-31',
      false,
    ),
  ]) {
    final zip = File('test/fixtures/financial_xbrl/${item.$1}')
        .readAsBytesSync();
    final uri = Uri.parse(
      'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=${item.$2}&dcm_no=1&lang=ko',
    );
    List<Map<String, dynamic>> parse(List<int> bytes, {Uri? source}) =>
        PublicFinancialXbrl.parse(
          bytes,
          receipt: item.$2,
          corpCode: item.$3,
          bsnsYear: item.$4,
          periodEnd: item.$5,
          consolidated: item.$8,
          sourceUri: source ?? uri,
        );
    test(
      'actual full/short XBRL contexts preserve declared filing duration and source ${item.$2}',
      () {
        final rows = parse(zip);
        expect(rows.length, item.$2 == '20250409002838' ? 8 : 7);
        for (final row in rows) {
          final p = row['xbrl_provenance'] as Map;
          expect(p['receipt'], item.$2);
          expect(p['corpCode'], item.$3);
          expect(p['source'], uri.toString());
          expect(p['basis'], item.$8 ? 'CFS' : 'OFS');
          expect(p['periodStart'], item.$6);
          expect(p['periodEnd'], item.$7);
          expect(p['rawAmount'], row['thstrm_amount']);
          expect(p['contextId'], isNotEmpty);
          expect(p['currency'], 'KRW');
          if (row['sj_div'] == 'BS') {
            expect(p['contextInstant'], item.$7);
            expect(p['contextStart'], isNull);
          } else {
            expect(p['contextInstant'], isNull);
            expect(p['contextStart'], item.$6);
            expect(p['contextEnd'], item.$7);
          }
        }
      },
    );
    test(
      'wrong transport receipt cannot become filing-duration proof ${item.$2}',
      () {
        expect(
          () => parse(
            zip,
            source: Uri.parse(
              'https://dart.fss.or.kr/pdf/download/ifrs.do?rcp_no=20250101000001',
            ),
          ),
          throwsFormatException,
        );
      },
    );
    test(
      'mixed current context end is rejected rather than labeled as the declared period ${item.$2}',
      () {
        final archive = ZipDecoder().decodeBytes(zip);
        final f = archive.files.singleWhere((f) => f.name.endsWith('.xbrl'));
        final xml = utf8
            .decode(f.content)
            .replaceAll(
              '<xbrli:instant>${item.$7}</xbrli:instant>',
              '<xbrli:instant>2023-01-01</xbrli:instant>',
            )
            .replaceAll(
              '<instant>${item.$7}</instant>',
              '<instant>2023-01-01</instant>',
            );
        expect(xml, isNot(utf8.decode(f.content)));
        final changed = ZipEncoder().encodeBytes(
          Archive()..addFile(ArchiveFile.bytes(f.name, utf8.encode(xml))),
        );
        expect(() => parse(changed), throwsFormatException);
      },
    );
  }
}
