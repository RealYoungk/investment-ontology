from html.parser import HTMLParser
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

WEB = Path(__file__).resolve().parents[2] / 'investment_ontology_serverpod_flutter/web'

class Content(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.article = False
        self.text = []
        self.scripts = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'article': self.article = True
        if tag == 'a': self.links.append(attrs.get('href', ''))
        if tag == 'script': self.scripts.append(attrs.get('src', 'inline'))
    def handle_endtag(self, tag):
        if tag == 'article': self.article = False
    def handle_data(self, data):
        if self.article: self.text.append(data)

class PublicResearchTests(unittest.TestCase):
    def test_article_body_and_navigation_do_not_depend_on_javascript_or_ads(self):
        for file in [WEB / 'start.html', *sorted((WEB / 'research').glob('*.html'))]:
            with self.subTest(file=file.name):
                document = Content()
                document.feed(file.read_text())
                self.assertGreater(len(''.join(document.text)), 900)
                self.assertFalse(document.scripts)
                self.assertIn('/companies', document.links)
                self.assertNotIn('adsbygoogle', file.read_text())
                for link in document.links:
                    if link.startswith('/') and link.endswith('.html'):
                        self.assertTrue((WEB / link.lstrip('/')).is_file(), link)
    def test_robots_and_sitemap_are_documents_instead_of_spa_fallback(self):
        self.assertIn('Allow: /', (WEB / 'robots.txt').read_text())
        urls = ET.parse(WEB / 'sitemap.xml').getroot()
        locations = [url[0].text for url in urls]
        self.assertIn('https://alfinder.kr/', locations)
        self.assertEqual(len(locations), len(set(locations)))
        self.assertIn('https://alfinder.kr/research/trailing-metrics', locations)

    def test_application_entry_has_readable_no_script_navigation_and_ownership(self):
        html = (WEB / 'index.html').read_text()
        fallback = html.split('<noscript>', 1)[1].split('</noscript>', 1)[0]
        document = Content()
        document.feed(fallback)
        self.assertIn('/start', document.links)
        self.assertIn('/research/filing-basics', document.links)
        self.assertIn('JavaScript', fallback)
        self.assertIn('#splash { display: none; }', fallback)
        self.assertIn('<meta name="google-adsense-account" content="ca-pub-4209548390738211">', html)
        self.assertEqual((WEB / 'ads.txt').read_text().strip(), 'google.com, pub-4209548390738211, DIRECT, f08c47fec0942fa0')
        self.assertIn('href="https://alfinder.kr/start"', (WEB / 'start.html').read_text())
