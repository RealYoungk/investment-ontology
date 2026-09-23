import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../tokens.dart';

/// Inert, isolated HTML retains legacy charts/tables without executing old JS.
class ReportDocument extends StatelessWidget {
  const ReportDocument({
    super.key,
    required this.title,
    required this.summary,
    required this.date,
    required this.content,
    required this.legacy,
  });
  final String title, summary, date, content;
  final bool legacy;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String color(Color value) =>
        '#${value.toARGB32().toRadixString(16).substring(2)}';
    const escape = HtmlEscape();
    final toc = RegExp(r'<h2[^>]*id="([^"]+)"[^>]*>(.*?)</h2>', dotAll: true)
        .allMatches(content)
        .map(
          (m) =>
              '<a href="#${escape.convert(m[1]!)}">${escape.convert(m[2]!.replaceAll(RegExp('<[^>]*>'), ''))}</a>',
        )
        .join('');
    final origin = Uri.base.origin;
    final html =
        '''<!doctype html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline' $origin; img-src https: $origin; font-src $origin; base-uri about:; form-action 'none'">
<base href="about:srcdoc"><link rel="stylesheet" href="$origin/research-assets/legacy.css">
<style>
:root {color-scheme:light;--color-text:${color(c.textPrimary)};--color-text-secondary:${color(c.textSecondary)};--color-text-muted:${color(c.textMuted)};--color-navy-700:${color(c.accent)};--color-navy-900:${color(c.textPrimary)};--color-surface:${color(c.surfaceHover)};--color-card:${color(c.surface)};--color-border:${color(c.border)};}
html{scroll-behavior:smooth}body{margin:0;background:${color(c.surface)};color:${color(c.textPrimary)};font-family:system-ui,-apple-system,'Apple SD Gothic Neo',sans-serif;line-height:1.85;font-size:16px;overflow-wrap:anywhere}article{max-width:880px;margin:auto;padding:40px 44px 96px}header{border-bottom:1px solid ${color(c.border)};padding-bottom:28px;margin-bottom:32px}h1{font-size:36px;line-height:1.3;letter-spacing:-1.3px;font-weight:750;margin:16px 0}header p{font-size:19px;line-height:1.6;color:${color(c.textSecondary)}}small{color:${color(c.textMuted)};font-size:12px}nav{display:flex;flex-wrap:wrap;gap:8px 20px;margin:22px 0;font-size:13px}a{color:${color(c.accent)};text-decoration:underline;text-underline-offset:3px}h2{font-size:25px;margin:56px 0 20px;scroll-margin-top:24px}h3{font-size:19px;margin:32px 0 12px}p,.report-paragraph{margin:18px 0}img{max-width:100%;height:auto;border-radius:12px}figure{margin:28px 0}figcaption{font-size:12px;color:${color(c.textMuted)}}.report-table-scroll{overflow-x:auto;max-width:100%;margin:24px 0}table{display:table;width:100%;max-width:none;border-collapse:collapse;font-size:13px;margin:24px 0}th,td{padding:10px 14px;border-bottom:1px solid ${color(c.border)};white-space:nowrap;text-align:left}th{background:${color(c.surfaceHover)}}blockquote{border-left:3px solid ${color(c.accent)};padding:4px 20px;margin:24px 0;background:${color(c.surfaceHover)}}ul,ol{padding-left:24px}section{margin-bottom:36px}strong{font-weight:700}.not-prose{max-width:100%}svg{max-width:100%}button{display:none}
.report-glossary{display:inline;position:relative}.report-glossary>summary{display:inline;cursor:pointer;border-bottom:1px dotted currentColor;list-style:none}.report-glossary>summary::-webkit-details-marker{display:none}.report-glossary-body{display:block;background:#eef3f8;color:#263747;padding:14px 18px;margin:10px 0;border-radius:10px;font-size:14px;font-weight:400;line-height:1.8}.report-composition{margin:24px 0;padding:24px;border:1px solid #dce3eb;border-radius:12px}.report-composition-row{margin:14px 0;font-size:13px}.report-composition-row>div:first-child{display:flex;justify-content:space-between;gap:12px}.report-composition-track{margin-top:7px;background:#edf0f4;border-radius:4px} @media(max-width:600px){article{padding:24px 20px 72px}h1{font-size:28px}header p{font-size:17px}body{font-size:15px}h2{font-size:22px}.grid{grid-template-columns:repeat(2,minmax(0,1fr))!important}}
@media print{nav{display:none}article{max-width:none;padding:0}table{display:table;font-size:10px}body{font-size:12px}}
</style></head><body><article class="prose-alfinder"><header><small>${legacy ? '아카이브 · 원문 분석 기준' : '분석 기준'} ${escape.convert(date)}</small><h1>${escape.convert(title)}</h1><p>${escape.convert(summary)}</p>${legacy ? '<small>당시의 분석과 수치를 보존한 리포트입니다. 이후 공시와 실적은 기업 데이터에서 확인하세요.</small>' : ''}<nav aria-label="본문 목차">$toc</nav></header>${content.replaceAll('src="/research-assets/', 'src="$origin/research-assets/')}</article></body></html>''';
    return HtmlElementView.fromTagName(
      key: ValueKey(html),
      tagName: 'iframe',
      onElementCreated: (element) {
        final frame = element as web.HTMLIFrameElement;
        frame.title = '$title 리포트 본문';
        frame.setAttribute(
          'sandbox',
          'allow-popups allow-popups-to-escape-sandbox',
        );
        frame.style
          ..border = '0'
          ..width = '100%'
          ..height = '100%';
        frame.srcdoc = html.toJS;
      },
    );
  }
}
