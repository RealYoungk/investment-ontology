#!/usr/bin/env python3
"""Extract already-published static articles without executing their JavaScript."""
import argparse, ast, hashlib, json, re, shutil, subprocess, tempfile, html
from html.parser import HTMLParser
from pathlib import Path

class ArticleSections(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.in_article = False
        self.depth = 0
        self.parts = []
        self.images = set()
    def handle_starttag(self, tag, attrs):
        if tag == 'article': self.in_article = True
        if self.in_article and tag == 'section': self.depth += 1
        if self.depth:
            raw = self.get_starttag_text()
            if tag == 'img':
                src = dict(attrs).get('src', '')
                if src.startswith('/images/'):
                    self.images.add(src)
                    raw = raw.replace(src, '/research-assets' + src)
            raw = re.sub(r'href="/reports/([a-zA-Z0-9]+)"', r'href="https://alfinder.kr/research/\1"', raw)
            self.parts.append(raw)
    def handle_endtag(self, tag):
        if self.depth: self.parts.append('</' + tag + '>')
        if self.in_article and tag == 'section': self.depth -= 1
        if tag == 'article': self.in_article = False
    def handle_data(self, data):
        if self.depth: self.parts.append(data)
    def handle_entityref(self, name):
        if self.depth: self.parts.append('&' + name + ';')
    def handle_charref(self, name):
        if self.depth: self.parts.append('&#' + name + ';')

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('source', type=Path)
    args = ap.parse_args(); root = Path(__file__).resolve().parents[1]
    src = args.source / 'apps/research'; out = src / 'out'
    dest = root / 'investment_ontology_serverpod_server/assets/research'
    web = root / 'investment_ontology_serverpod_flutter/web/research-assets'
    dest.mkdir(parents=True, exist_ok=True); web.mkdir(parents=True, exist_ok=True)
    rendered = Path(tempfile.mkdtemp(prefix="alfinder-reports-"))
    subprocess.run(["node", str(root / "scripts/render_legacy_reports.cjs"), str(args.source), str(rendered)], check=True)
    manifest = []; records = []
    for page in sorted(rendered.glob('*.html')):
        ticker = page.stem
        meta_path = src / 'app/reports' / ticker / 'meta.ts'
        if not meta_path.exists(): continue
        meta = meta_path.read_text()
        def field(key):
            m = re.search(r'\b'+key+r"\s*:\s*('(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\")",meta)
            return ast.literal_eval(m.group(1)) if m else ''
        parser = ArticleSections(); raw = page.read_text(); parser.feed(raw)
        content = ''.join(parser.parts)
        video = field('videoUrl')
        if video.startswith('https://'):
            content = '<p><a href="' + html.escape(video, quote=True) + '">이 리포트, 영상으로 보기 ↗</a></p>' + content
        if not content or not field('name') or not field('updatedAt'):
            raise ValueError('Missing article/metadata: '+ticker)
        # Prevent silently joining a newer source title/date with an older export.
        for image in parser.images:
            source = out / image.lstrip('/'); target = web / image.lstrip('/')
            if not source.is_file(): raise ValueError('Missing image: '+str(source))
            target.parent.mkdir(parents=True, exist_ok=True); shutil.copyfile(source,target)
        records.append(dict(slug=ticker,title=field('name'),summary=field('oneLiner') or field('description'),ticker=ticker,market=field('market'),content=content,format='html',dataAsOf=field('updatedAt'),note='기존 알파인더 리포트 · 최초 '+field('createdAt')+' · 원문 수정 '+field('updatedAt')))
        manifest.append(dict(slug=ticker,sha256=hashlib.sha256(raw.encode()).hexdigest(),images=len(parser.images),source=str((src / 'app/reports' / ticker / 'page.tsx').relative_to(args.source)),sourceSha256=hashlib.sha256((src / 'app/reports' / ticker / 'page.tsx').read_bytes()).hexdigest(),glossary=content.count('report-glossary')))
    css = list((out / '_next/static/chunks').glob('*.css'))
    (web / 'legacy.css').write_text('\n'.join(p.read_text() for p in css))
    routes = root / 'investment_ontology_serverpod_flutter/lib/features/research/legacy_report_slugs.dart'
    routes.write_text('// Original public report paths; numeric financial IDs must not be guessed as tickers.\nconst legacyReportSlugs = <String>{\n' + ''.join('  '+repr(r['slug'])+',\n' for r in records) + '};\n')
    (dest / 'legacy.json').write_text(json.dumps(records,ensure_ascii=False))
    (dest / 'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
    print(f'{len(records)} reports, {sum(x["images"] for x in manifest)} image references; originals preserved.')
if __name__ == '__main__': main()
