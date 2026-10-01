import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_html.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/financial_rows.dart';
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';

void main() {
  const dir = 'test/fixtures/financial_html/standard-annual';
  final sources =
      jsonDecode(File('$dir/evidence.json').readAsStringSync()) as List;
  final reviewed = jsonDecode(
    File('$dir/reviewed-current-core-evidence.json').readAsStringSync(),
  ) as List;
  String html(String rec, String name) =>
      File('$dir/$rec/$name.html').readAsStringSync();
  List<Map<String, dynamic>> parse(
    Map evidence, {
    String? body,
    String? cover,
    Uri? uri,
    String? name,
    DateTime? start,
    DateTime? end,
  }) {
    final rec = evidence['receipt'] as String;
    final source = sources.firstWhere((s) => s['receipt'] == rec) as Map;
    final annualEnd = DateTime.utc(
      int.parse((source['sourcePeriod'] as String).substring(0, 4)),
      int.parse((source['sourcePeriod'] as String).substring(5)) + 1,
      0,
    );
    final annualStart = rec == '20260922000230'
        ? DateTime.utc(2025, 7, 1)
        : DateTime.utc(annualEnd.year, 1, 1);
    return PublicFinancialHtml.parseStandardAnnual(
      coverHtml: cover ?? html(rec, 'cover'),
      statementHtml: body ?? html(rec, '${evidence['basis']}-statement'),
      coverSource: Uri.parse(source['coverUrl'] as String),
      statementSource: uri ?? Uri.parse(evidence['url'] as String),
      receipt: rec,
      corpCode: source['corpCode'] as String,
      companyName: name ?? source['name'] as String,
      periodStart: start ?? annualStart,
      periodEnd: end ?? annualEnd,
      consolidated: evidence['basis'] == 'consolidated',
    );
  }

  test(
    'actual EMT 90-day annual current amounts and interval remain exact',
    () {
      const rec = '20260709000400';
      final rows = PublicFinancialHtml.parseStandardAnnual(
        coverHtml: html(rec, 'cover'),
        statementHtml: html(rec, 'separate-statement'),
        coverSource: Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260709000400&dcmNo=11470039&eleId=1&offset=951&length=4480&dtd=dart4.xsd',
        ),
        statementSource: Uri.parse(
          'https://dart.fss.or.kr/report/viewer.do?rcpNo=20260709000400&dcmNo=11470039&eleId=21&offset=109130&length=43771&dtd=dart4.xsd',
        ),
        receipt: rec,
        corpCode: '00925967',
        companyName: '이엠티',
        periodStart: DateTime.utc(2026, 1, 1),
        periodEnd: DateTime.utc(2026, 3, 31),
        consolidated: false,
      );
      final amounts = {
        for (final r in rows) r['account_nm']: r['thstrm_amount'],
      };
      expect(amounts['자산총계'], '165992336930');
      expect(amounts['부채총계'], '152359058867');
      expect(amounts['자본총계'], '13633278063');
      expect(amounts.values, contains('22224597290'));
      expect(amounts.values, contains('3708129672'));
      expect(rows.every((r) => r['account_id'] == null), isTrue);
    },
  );

  test('source-declared short annual retains amounts without annualizing', () {
    final e = reviewed.cast<Map>().firstWhere(
      (e) => e['receipt'] == '20250324000440' && e['basis'] == 'separate',
    );
    final rec = e['receipt'] as String;
    final originalCover = html(rec, 'cover');
    final originalBody = html(rec, 'separate-statement');
    final baseline = parse(e);
    for (final start in [
      DateTime.utc(2024, 10, 1),
      DateTime.utc(2024, 12, 31),
    ]) {
      final printedStart =
          '${start.year}년${start.month.toString().padLeft(2, '0')}월${start.day.toString().padLeft(2, '0')}일';
      String changed(String raw) => raw.replaceAll(
        RegExp(r'2024년\s*0?1월\s*0?1일'),
        printedStart,
      );
      final cover = changed(originalCover), body = changed(originalBody);
      expect(cover, isNot(originalCover));
      expect(body, isNot(originalBody));
      final rows = parse(e, cover: cover, body: body, start: start);
      expect(
        rows.map((r) => r['thstrm_amount']).toList(),
        baseline.map((r) => r['thstrm_amount']).toList(),
      );
      expect(
        () => parse(e, cover: cover, body: originalBody, start: start),
        throwsFormatException,
      );
    }
  });

  test(
    'short annual requires exact cover interval and bounded positive days',
    () {
      final e = reviewed.cast<Map>().firstWhere(
        (e) => e['receipt'] == '20250324000440' && e['basis'] == 'separate',
      );
      final rec = e['receipt'] as String;
      final cover = html(rec, 'cover'), body = html(rec, 'separate-statement');
      for (final replacement in ['2023년12월30일', '2025년01월01일']) {
        String changed(String raw) =>
            raw.replaceAll(RegExp(r'2024년\s*0?1월\s*0?1일'), replacement);
        final start = replacement.startsWith('2023')
            ? DateTime.utc(2023, 12, 30)
            : DateTime.utc(2025, 1, 1);
        expect(
          () => parse(
            e,
            cover: changed(cover),
            body: changed(body),
            start: start,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('printed scaled monetary units normalize exactly with provenance', () {
    final evidence = reviewed.cast<Map>().firstWhere(
      (e) => (e['rawCurrentCoreRows'] as List).isNotEmpty,
    );
    final original = html(
      evidence['receipt'] as String,
      '${evidence['basis']}-statement',
    );
    final baseline = parse(evidence);
    for (final scale in {'천원': 1000, '백만원': 1000000}.entries) {
      final changed = original.replaceAll(
        RegExp(r'단위\s*:\s*원'),
        '단위 : ${scale.key}',
      );
      expect(changed, isNot(original));
      final rows = parse(evidence, body: changed);
      for (var i = 0; i < rows.length; i++) {
        final printed = BigInt.parse(baseline[i]['thstrm_amount'] as String);
        expect(
          rows[i]['thstrm_amount'],
          (printed * BigInt.from(scale.value)).toString(),
        );
        final provenance = rows[i]['html_provenance'] as Map;
        expect(provenance['unit'], scale.key);
        expect(provenance['unitMultiplier'], '${scale.value}');
        expect(provenance['printedAmount'], printed.toString());
        expect(provenance['normalizedUnit'], '원');
      }
    }
    expect(
      () => parse(
        evidence,
        body: original.replaceAll(RegExp(r'단위\s*:\s*원'), '단위 : 천원, USD'),
      ),
      throwsFormatException,
    );
  });

  for (final evidence in reviewed.cast<Map>()) {
    final expected = evidence['rawCurrentCoreRows'] as List;
    if (expected.isEmpty) {
      test(
        'actual explicit non-consolidated source rejects numeric success',
        () {
          expect(() => parse(evidence), throwsFormatException);
        },
      );
      continue;
    }
    test(
      'primary ${evidence['receipt']} ${evidence['basis']} retains eight actual current amounts and printed labels',
      () {
        final rows = parse(evidence);
        expect(rows.length, 8);
        expect(rows.every((r) => r['account_id'] == null), isTrue);
        String compact(String value) => value.replaceAll(RegExp(r'\s+'), '');
        for (final e in expected.cast<Map>()) {
          final row = rows.singleWhere(
            (r) =>
                compact(r['account_nm'] as String) ==
                compact(e['printedAccountName'] as String),
          );
          expect(row['thstrm_amount'], e['currentAmount']);
          expect(row['currency'], 'KRW');
          expect((row['html_provenance'] as Map)['source'], evidence['url']);
        }
        final converted = FinancialRows.toFacts(
          rows,
          reportId: 1,
          companyId: 1,
          bsnsYear: int.parse(
            (evidence['sourcePeriod'] as String).substring(0, 4),
          ),
          reportCode: FinancialReportCode.annual,
          fsDiv: evidence['basis'] == 'consolidated'
              ? FsDiv.consolidated
              : FsDiv.separate,
          sourceId: 1,
        );
        expect(converted.facts.length, 8);
        expect(converted.invalidAmounts, 0);
        expect(converted.facts.every((f) => f.accountId == null), isTrue);
      },
    );
  }
  final sgi = reviewed.first as Map;
  final sgiBody = html('20250324000440', 'consolidated-statement');
  test('wrong company, basis, closing month, receipt and unknown money unit reject', () {
    expect(() => parse(sgi, name: '서울보증'), throwsFormatException);
    expect(
      () => parse(sgi, end: DateTime.utc(2024, 6, 30)),
      throwsFormatException,
    );
    expect(
      () => parse(sgi, body: html('20250324000440', 'separate-statement')),
      throwsFormatException,
    );
    final uri = Uri.parse(sgi['url'] as String);
    expect(
      () => parse(
        sgi,
        uri: uri.replace(
          queryParameters: {...uri.queryParameters, 'rcpNo': '20250324000441'},
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => parse(sgi, body: sgiBody.replaceAll('단위 : 원', '단위 : USD')),
      throwsFormatException,
    );
  });
  test('contradictory balance sheet, duplicate current group and conflicting whole-income rows reject', () {
    expect(
      () => parse(
        sgi,
        body: sgiBody.replaceAll('9,333,598,065,076', '9,333,598,065,077'),
      ),
      throwsFormatException,
    );
    final headerAltered = sgiBody.replaceAll('제 57(전)기 기말', '제 58(당)기 기말');
    expect(headerAltered, isNot(sgiBody));
    expect(() => parse(sgi, body: headerAltered), throwsFormatException);
    final profit =
        RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
            .allMatches(sgiBody)
            .firstWhere((r) => r.group(0)!.contains('213,274,020,304'))
            .group(0)!;
    expect(
      () => parse(
        sgi,
        body: sgiBody.replaceFirst(
          profit,
          '$profit${profit.replaceAll('213,274,020,304', '213,274,020,305')}',
        ),
      ),
      throwsFormatException,
    );
  });
  test(
    'whole profit is mandatory; continuing-operations profit cannot substitute',
    () {
      final poled = reviewed.firstWhere(
        (r) => r['receipt'] == '20260330001188' && r['basis'] == 'consolidated',
      ) as Map;
      final original = html('20260330001188', 'consolidated-statement');
      final row =
          RegExp(r'<TR\b[^>]*>(.*?)</TR>', caseSensitive: false, dotAll: true)
              .allMatches(original)
              .firstWhere((r) => r.group(0)!.contains('8,362,410,126'))
              .group(0)!;
      expect(
        () => parse(
          poled,
          body: original.replaceFirst(
            row,
            row.replaceAll('당기순이익', '계속영업당기순이익'),
          ),
        ),
        throwsFormatException,
      );
    },
  );
  test('ascending three-year columns bind current declared period, not the first number', () {
    final dd = reviewed.firstWhere(
      (r) => r['receipt'] == '20260922000230' && r['basis'] == 'separate',
    ) as Map;
    final original = html('20260922000230', 'separate-statement');
    expect(parse(dd).first['thstrm_amount'], '68666288952');
    final altered = original.replaceAll('(25.07~26.06)', '(24.07~25.06)');
    expect(altered, isNot(original));
    expect(() => parse(dd, body: altered), throwsFormatException);
  });
  test(
    'each primary statement needs its own current period title and unit',
    () {
      final tables = RegExp(
        r'<TABLE\b[^>]*>.*?</TABLE>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(sgiBody).toList();
      final caption = tables
          .firstWhere(
            (m) => m
                .group(0)!
                .replaceAll(RegExp(r'<[^>]*>|\s+'), '')
                .contains('현금흐름표'),
          )
          .group(0)!;
      final altered = caption.replaceAll(
        RegExp(r'제 58[^<]*?2024년[^<]*?까지'),
        '',
      );
      expect(altered, isNot(caption));
      expect(
        () => parse(sgi, body: sgiBody.replaceFirst(caption, altered)),
        throwsFormatException,
      );
    },
  );
}
