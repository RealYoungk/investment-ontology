import 'dart:convert';

import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/notes/investment_note_content.dart';

Map<String, dynamic> fixture({String tier = 'watchlist'}) => {
  'schemaVersion': 1,
  'corpCode': '00123456',
  'tier': tier,
  'author': '작성자',
  'title': '기업 기술 검증',
  'introduction': '무료 소개',
  'dataAsOf': '2026-10-05T00:00:00Z',
  'sources': [
    {
      'id': 'p',
      'title': '논문',
      'url': 'https://example.com/paper',
      'kind': 'paper',
    },
  ],
  'sections': [
    {
      'heading': '투자 관점',
      'text': '유료 기술 분석 SECRET',
      'sourceIds': ['p'],
    },
  ],
};
void main() {
  test('free projection drops all nested premium body and source data', () {
    final data = InvestmentNoteContent.parse(jsonEncode(fixture()));
    final free = InvestmentNoteContent.readerView(
      data,
      member: false,
      id: 1,
      publishedAt: DateTime.utc(2026),
      companyName: '기업',
    );
    expect(free['introduction'], '무료 소개');
    expect(free['locked'], true);
    expect(jsonEncode(free), isNot(contains('SECRET')));
    expect(free.containsKey('sources'), false);
    final paid = InvestmentNoteContent.readerView(
      data,
      member: true,
      id: 1,
      publishedAt: DateTime.utc(2026),
      companyName: '기업',
    );
    expect(jsonEncode(paid), contains('SECRET'));
  });
  test(
    'free top-pick teaser does not disclose selected company or author view',
    () {
      final data = InvestmentNoteContent.parse(
        jsonEncode(fixture(tier: 'topPick')),
      );
      final free = InvestmentNoteContent.readerView(
        data,
        member: false,
        id: 1,
        publishedAt: DateTime.utc(2026),
        companyName: '숨긴기업',
      );
      for (final secret in [
        '숨긴기업',
        '00123456',
        '기업 기술 검증',
        '무료 소개',
        'SECRET',
      ]) {
        expect(jsonEncode(free), isNot(contains(secret)));
      }
    },
  );
  test(
    'rejects unsupported tiers, missing sources and broken provenance links',
    () {
      for (final data in [
        fixture(tier: 'autoTopPick'),
        {...fixture(), 'sources': []},
        {
          ...fixture(),
          'sections': [
            {
              'heading': '주장',
              'text': '값',
              'sourceIds': ['missing'],
            },
          ],
        },
      ]) {
        expect(
          () => InvestmentNoteContent.parse(jsonEncode(data)),
          throwsFormatException,
        );
      }
    },
  );
  test('rejects script URLs and strips undeclared imported fields', () {
    final data = fixture();
    (data['sources'] as List)[0]['url'] = 'javascript:alert(1)';
    expect(
      () => InvestmentNoteContent.parse(jsonEncode(data)),
      throwsFormatException,
    );
    final normalized = InvestmentNoteContent.parse(
      jsonEncode({...fixture(), 'published': true, 'membership': true}),
    );
    expect(normalized.containsKey('published'), false);
    expect(normalized.containsKey('membership'), false);
  });
  test('approval digest binds exact content, article and version', () {
    final body = jsonEncode(fixture());
    final hash = InvestmentNoteContent.digest(1, 1, body);
    expect(InvestmentNoteContent.digest(1, 2, body), isNot(hash));
    expect(InvestmentNoteContent.digest(2, 1, body), isNot(hash));
    expect(InvestmentNoteContent.digest(1, 1, '$body '), isNot(hash));
  });
}
