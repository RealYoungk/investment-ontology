import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html_fetch.dart';

const fixture = 'test/fixtures/financial_html/bs-duration';
List<Map<String, dynamic>> rows(
  String receipt,
  String corp,
  String name,
  int year, {
  String? body,
}) {
  final p = '$fixture/$receipt';
  final proof = jsonDecode(File('$p/proof.json').readAsStringSync());
  Uri uri(String label) => Uri.parse(
    (proof['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
  );
  return PublicFinancialHtml.parseStandardAnnual(
    coverHtml: File('$p/cover.html').readAsStringSync(),
    statementHtml: body ?? File('$p/ofs.html').readAsStringSync(),
    coverSource: uri('cover'),
    statementSource: uri('ofs'),
    receipt: receipt,
    corpCode: corp,
    companyName: name,
    periodStart: DateTime.utc(year),
    periodEnd: DateTime.utc(year, 12, 31),
    consolidated: false,
  );
}

PublicFinancialHtmlSource actualSource(int index) {
  final a = index == 0
      ? ('20250318000596', '01352575', '바이오텐(주)', 2024)
      : ('20260320001385', '00925967', '(주)이엠티', 2025);
  final p = '$fixture/${a.$1}';
  final proof = jsonDecode(File('$p/proof.json').readAsStringSync());
  Uri uri(String label) => Uri.parse(
    (proof['sources'] as List).singleWhere((s) => s['label'] == label)['url'],
  );
  return PublicFinancialHtmlSource(
    sourceReceipt: a.$1,
    correctionReceipt: null,
    correctionSource: null,
    coverHtml: File('$p/cover.html').readAsStringSync(),
    coverSource: uri('cover'),
    statementHtml: File('$p/ofs.html').readAsStringSync(),
    statementSource: uri('ofs'),
    periodStart: DateTime.utc(a.$4),
    periodEnd: DateTime.utc(a.$4, 12, 31),
    rows: rows(a.$1, a.$2, a.$3, a.$4),
  );
}

void main() {
  for (final mutation in [
    ('<P>(제14기)</P>', '<P>(제13기)</P>'),
    (
      '제14기 2024년 01월 01일부터 2024년 12월 31일까지',
      '제14기 2024년 01월 02일부터 2024년 12월 31일까지',
    ),
  ]) {
    test(
      'explicit current header/duration conflict cannot be overridden ${mutation.$1}',
      () {
        final b = File('$fixture/20250318000596/ofs.html').readAsStringSync();
        final changed = b.replaceAll(mutation.$1, mutation.$2);
        expect(changed == b, isFalse);
        expect(
          () => rows(
            '20250318000596',
            '01352575',
            '바이오텐(주)',
            2024,
            body: changed,
          ),
          throwsFormatException,
        );
      },
    );
  }

  for (final mutation in [
    '2024년 1월 1일(당기초)',
    '2024년 12월 31일(당기말)',
    '2,215,008,905',
  ]) {
    test('independent CE actual proof required $mutation', () {
      final body = File('$fixture/20250318000596/ofs.html').readAsStringSync();
      final changed = body.replaceAll(
        mutation,
        mutation == '2,215,008,905' ? '2,215,008,906' : '1999년1월1일(당기초)',
      );
      expect(changed == body, isFalse);
      expect(
        () =>
            rows('20250318000596', '01352575', '바이오텐(주)', 2024, body: changed),
        throwsFormatException,
      );
    });
  }

  test('Bioten annual BS duration requires printed CE current totals', () {
    final r = rows('20250318000596', '01352575', '바이오텐(주)', 2024);
    expect(
      r.map((r) => r['thstrm_amount']),
      containsAll([
        '7338251534',
        '5123242629',
        '2215008905',
        '5487917430',
        '-915886780',
        '-1203958296',
        '-636599148',
      ]),
    );
    expect(
      (r.first['html_provenance'] as Map)['supportingPeriodEvidence']['mode'],
      'primary-bs-duration-equity-corroboration',
    );
  });
  test('EMT keeps actual mixed profit/loss names and signed whole values', () {
    final r = rows('20260320001385', '00925967', '(주)이엠티', 2025);
    expect(
      r.map((r) => r['thstrm_amount']),
      containsAll([
        '78428968071',
        '77010449723',
        '1418518348',
        '36396610263',
        '4871967882',
        '2683100337',
        '10964990775',
      ]),
    );
    expect(r.every((r) => r['account_id'] == null), isTrue);
  });
  for (final x in [
    ('20260309001820', '01205514', '큐라켐', 2025),
    ('20250321000725', '01262023', '루트락', 2024),
    ('20250318000780', '01060735', '로지스몬', 2024),
  ]) {
    test(
      'actual conflicting term/date/unit stays rejected ${x.$1}',
      () => expect(
        () => rows(x.$1, x.$2, x.$3, x.$4),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'period rejection',
            contains('Annual current statement title period mismatch'),
          ),
        ),
      ),
    );
  }
  test('actual undated Daeju primary captions require independent dated whole equity', () {
    final result = rows('20250407004206', '00414540', '대주이엔티', 2024);
    expect(result.length, 8);
    final evidence =
        result.first['html_provenance']['supportingPeriodEvidence'];
    expect(evidence['periodStart'], '2024-01-01');
    expect(evidence['periodEnd'], '2024-12-31');
    expect(evidence['mode'], 'separate-independent-printed-equity-period-v1');
  });
}
