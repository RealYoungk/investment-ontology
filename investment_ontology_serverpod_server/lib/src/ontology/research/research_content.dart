import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
import 'package:markdown/markdown.dart' as md;

/// Only inert article markup survives. The web reader additionally uses a sandbox.
abstract final class ResearchContent {
  static String render(String input, String format) {
    if (input.length > 400000) throw ArgumentError('본문은 400,000자 이내로 입력하세요.');
    if (format != 'html' && format != 'markdown') {
      throw ArgumentError('지원하지 않는 본문 형식입니다.');
    }
    final markup = format == 'markdown'
        ? md.markdownToHtml(input, extensionSet: md.ExtensionSet.gitHubWeb)
        : input;
    // HTML details is flow content: inside p the browser would split sentences.
    final fragment = html.parseFragment(
      markup
          .replaceAllMapped(
            RegExp(r'<p(?=[\s>])', caseSensitive: false),
            (_) => '<div data-report-paragraph',
          )
          .replaceAll(RegExp(r'</p>', caseSensitive: false), '</div>'),
    );
    for (final paragraph in fragment.querySelectorAll(
      '[data-report-paragraph]',
    )) {
      paragraph.classes.add('report-paragraph');
      paragraph.attributes.remove('data-report-paragraph');
    }
    for (final e in fragment.querySelectorAll('*').toList()) {
      if ({
        'script',
        'iframe',
        'object',
        'embed',
        'form',
        'input',
        'button',
        'style',
        'link',
        'meta',
        'base',
        'foreignobject',
      }.contains(e.localName?.toLowerCase())) {
        e.remove();
        continue;
      }
      e.attributes.removeWhere((key, value) {
        final k = key.toString().toLowerCase();
        if (k.startsWith('on') || k == 'srcdoc') return true;
        if (k == 'href' || k == 'src' || k == 'xlink:href') {
          final v = value.trim();
          return !(v.startsWith('#') ||
              v.startsWith('/research-assets/') ||
              v.startsWith('https://'));
        }
        if (k == 'style') {
          return RegExp(
            r'url\s*\(|expression|@import|behavior|position\s*:\s*fixed',
            caseSensitive: false,
          ).hasMatch(value);
        }
        return false;
      });
      if (e.localName == 'a' && !(e.attributes['href'] ?? '').startsWith('#')) {
        e.attributes['target'] = '_blank';
        e.attributes['rel'] = 'noopener noreferrer';
      }
    }
    if (format == 'markdown') {
      var index = 0;
      for (final h in fragment.querySelectorAll('h2')) {
        h.id = 'section-${++index}';
      }
    }
    for (final table in fragment.querySelectorAll('table').toList()) {
      if (table.parent?.classes.contains('report-table-scroll') ?? false) {
        continue;
      }
      final wrapper = Element.tag('div')..classes.add('report-table-scroll');
      table.parentNode!.insertBefore(wrapper, table);
      wrapper.append(table);
    }
    return fragment.outerHtml;
  }

  static String text(String input) => html.parseFragment(input).text ?? '';
}
