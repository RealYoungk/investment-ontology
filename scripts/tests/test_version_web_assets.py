import importlib.util
from pathlib import Path
import tempfile
import unittest
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse

spec = importlib.util.spec_from_file_location('version_web_assets', Path(__file__).parents[1] / 'version_web_assets.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class EntrypointTests(unittest.TestCase):
    def test_deep_link_resources_resolve_without_a_base_tag(self):
        class Resources(HTMLParser):
            urls = []
            def handle_starttag(self, tag, attrs):
                if tag in ('script', 'img', 'link'):
                    self.urls.extend(value for key, value in attrs if key in ('src', 'href'))
        html = (Path(__file__).parents[2] / 'investment_ontology_serverpod_flutter/web/index.html').read_text()
        parser = Resources()
        parser.feed(html)
        for resource in parser.urls:
            if resource.startswith('https:'):
                continue
            self.assertEqual(urljoin('https://alfinder.kr/company/00126380', resource),
                             urljoin('https://alfinder.kr/', resource), resource)

    def test_versioned_entrypoints_remain_root_relative_for_deep_links(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'main.dart.js').write_text('application')
            (root / 'flutter_bootstrap.js').write_text('{"mainJsPath":"main.dart.js"}')
            (root / 'index.html').write_text('<script src="/flutter_bootstrap.js"></script>')
            module.version_entrypoints(root)
            html = (root / 'index.html').read_text()
            resource = html.split('"')[1]
            self.assertEqual(urlparse(urljoin('https://alfinder.kr/company/00126380', resource)).path,
                             '/' + resource.lstrip('/'))
            self.assertTrue((root / resource.lstrip('/')).is_file())

    def test_new_app_uses_new_urls_and_keeps_legacy_entrypoint(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            def prepare(app):
                (root / 'main.dart.js').write_text(app)
                (root / 'flutter_bootstrap.js').write_text('{"mainJsPath":"main.dart.js"}')
                (root / 'index.html').write_text('<script src="flutter_bootstrap.js"></script>')
                module.version_entrypoints(root)
                return (root / 'index.html').read_text(), (root / 'flutter_bootstrap.js').read_text()
            first = prepare('old application')
            second = prepare('new application')
            self.assertNotEqual(first, second)
            self.assertIn('main.dart.', second[1])
            self.assertEqual((root / 'main.dart.js').read_text(), 'new application')
            self.assertTrue(all((root / name.lstrip('/')).exists() for name in [second[0].split('"')[1], second[1].split('"')[3]]))
