import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/research_content.dart';

void main() {
  test('scripts, active embeds, handlers and unsafe URLs are removed', () {
    final result = ResearchContent.render(
      '<script>alert(1)</script><iframe src="https://evil.test"></iframe><img src="javascript:bad" onerror="bad()"><a href="javascript:bad">link</a><div style="background:url(https://evil.test)">text</div>',
      'html',
    );
    expect(result, isNot(contains('<script')));
    expect(result, isNot(contains('iframe')));
    expect(result, isNot(contains('javascript:')));
    expect(result, isNot(contains('onerror')));
    expect(result, isNot(contains('url(')));
  });
  test('tables, images and source links survive', () {
    final result = ResearchContent.render(
      '<table><tr><td>100</td></tr></table><img src="/research-assets/images/a.png"><a href="https://dart.fss.or.kr">출처</a>',
      'html',
    );
    expect(result, contains('<table>'));
    expect(result, contains('report-table-scroll'));
    expect(result, contains('/research-assets/'));
    expect(result, contains('noopener noreferrer'));
  });
  test('inline glossary stays within its paragraph', () {
    final result = ResearchContent.render(
      '<p>앞 <details><summary>용어</summary>설명</details> 뒤</p>',
      'html',
    );
    expect(result, contains('class="report-paragraph"'));
    expect(result, contains('</details> 뒤</div>'));
  });
  test('Korean headings receive distinct stable anchors', () {
    final result = ResearchContent.render('## 근거\n본문\n## 전망\n내용', 'markdown');
    expect(result, contains('id="section-1"'));
    expect(result, contains('id="section-2"'));
  });
  test('markdown renders headings and links without executing HTML', () {
    expect(
      ResearchContent.render('## 근거\n[공시](https://dart.fss.or.kr)', 'markdown'),
      matches(RegExp(r'<h2[^>]*>근거</h2>')),
    );
    expect(
      () => ResearchContent.render('a' * 400001, 'html'),
      throwsArgumentError,
    );
  });
}
