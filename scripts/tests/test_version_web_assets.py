import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('version_web_assets', Path(__file__).parents[1] / 'version_web_assets.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class EntrypointTests(unittest.TestCase):
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
            self.assertTrue(all((root / name).exists() for name in [second[0].split('"')[1], second[1].split('"')[3]]))
