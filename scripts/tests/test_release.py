import io
import json
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import release
import release_bundle


class ReleaseGuardTests(unittest.TestCase):
    def test_sealed_release_records_executed_and_reused_checks(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = root / 'output/public-deploy'
            static = output / '.vercel/output/static'
            static.mkdir(parents=True)
            (static / 'main.dart.js').write_text('compiled app')
            (root / 'output/validation-results.json').write_text(json.dumps([
                {'origin': 'executed'}, {'origin': 'reused'}, {'origin': 'reused'},
            ]))
            def git(*args):
                return '' if args[0] == 'status' else ('b' * 40 if args[-1] == 'HEAD^{tree}' else 'a' * 40)
            with patch.object(release_bundle, 'ROOT', root), patch.object(release_bundle, 'git', side_effect=git), patch.dict(release_bundle.os.environ, {'ALFINDER_BUILD_COMMIT': 'a' * 40}, clear=True):
                release_bundle.seal(output)
            public = json.loads((static / 'release.json').read_text())
            self.assertEqual(public['validationCache'], {'executed': 1, 'reused': 2})
            release_bundle.verify_bundle(output, 'a' * 40)

    def candidate(self, **changes):
        return dict({'conclusion': 'success', 'status': 'completed', 'event': 'push',
                     'head_branch': 'main', 'head_repository': {'full_name': release.REPO},
                     'path': '.github/workflows/release.yml', 'head_sha': 'a' * 40}, **changes)

    def test_only_successful_main_release_runs_allowed(self):
        release.check_run(self.candidate())
        for changes in ({'event': 'pull_request'}, {'event': 'pull_request_target'},
                        {'head_branch': 'feature'}, {'conclusion': 'failure'},
                        {'status': 'in_progress'}, {'path': '.github/workflows/tests.yml'},
                        {'head_repository': {'full_name': 'someone/fork'}},
                        {'head_sha': 'main'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                release.check_run(self.candidate(**changes))

    def test_stale_main_is_rejected(self):
        with patch.object(release, 'gh_api', return_value={'sha': 'b' * 40}):
            with self.assertRaises(ValueError):
                release.require_head('a' * 40)

    def test_modified_or_extra_files_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            static = root / '.vercel/output/static'
            static.mkdir(parents=True)
            (static / 'main.dart.js').write_text('compiled app')
            public = {'commit': 'a' * 40, 'tree': 'b' * 40}
            (static / 'release.json').write_text(json.dumps(public))
            manifest = dict(public, files=release_bundle.inventory(root / '.vercel/output'))
            (root / 'manifest.json').write_text(json.dumps(manifest))
            release_bundle.verify_bundle(root, 'a' * 40)
            with self.assertRaises(ValueError):
                release_bundle.verify_bundle(root, 'c' * 40)
            (static / 'unexpected.txt').write_text('not in manifest')
            with self.assertRaises(ValueError):
                release_bundle.verify_bundle(root, 'a' * 40)
            (static / 'unexpected.txt').unlink()
            (static / 'main.dart.js').write_text('modified app')
            with self.assertRaises(ValueError):
                release_bundle.verify_bundle(root, 'a' * 40)

    def test_archive_escape_and_links_are_rejected(self):
        for name, kind in [('../escape', tarfile.REGTYPE),
                           ('/absolute', tarfile.REGTYPE),
                           ('.vercel/output/link', tarfile.SYMTYPE),
                           ('.vercel/output-evil/file', tarfile.REGTYPE)]:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                archive = root / 'test.tar.gz'
                with tarfile.open(archive, 'w:gz') as bundle:
                    entry = tarfile.TarInfo(name)
                    entry.type = kind
                    entry.linkname = '/tmp/escape' if kind == tarfile.SYMTYPE else ''
                    bundle.addfile(entry, io.BytesIO())
                with self.assertRaises(ValueError):
                    release.unpack(archive, root / 'unpacked')

    def test_dirty_tree_cannot_claim_a_commit(self):
        with patch.object(release_bundle, 'git', return_value=' M source.dart'):
            with self.assertRaises(SystemExit):
                release_bundle.seal(Path('/unused'))

    def test_commit_change_during_build_is_rejected(self):
        with patch.object(release_bundle, 'git', side_effect=['', 'b' * 40]), \
             patch.dict(release_bundle.os.environ, {'ALFINDER_BUILD_COMMIT': 'a' * 40}):
            with self.assertRaises(SystemExit):
                release_bundle.seal(Path('/unused'))

    def test_safe_bundle_extracts(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / 'test.tar.gz'
            with tarfile.open(archive, 'w:gz') as bundle:
                for name in ('manifest.json', '.vercel/output/static/index.html'):
                    entry = tarfile.TarInfo(name)
                    entry.size = 2
                    bundle.addfile(entry, io.BytesIO(b'{}'))
            release.unpack(archive, root / 'unpacked')
            self.assertEqual((root / 'unpacked/manifest.json').read_text(), '{}')

    def test_backend_change_prevents_rollback(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'record.json'
            path.write_text(json.dumps({'provider':'cloudflare-pages','projectName':release.pages.PROJECT,'accountId':release.pages.ACCOUNT,'deployment': {'id': 'current'}, 'backend': 'old'}))
            with patch.object(release, 'production', return_value={'id': 'current'}), \
                 patch.object(release, 'backend', return_value='new'), \
                 patch.object(release, 'run') as command:
                with self.assertRaises(ValueError):
                    release.rollback(path)
                command.assert_not_called()

    def test_foreign_production_prevents_rollback(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'record.json'
            path.write_text(json.dumps({'provider':'cloudflare-pages','projectName':release.pages.PROJECT,'accountId':release.pages.ACCOUNT,'deployment': {'id': 'old'}}))
            with patch.object(release, 'production', return_value={'id': 'new'}), \
                 patch.object(release, 'run') as command:
                with self.assertRaises(ValueError):
                    release.rollback(path)
                command.assert_not_called()


if __name__ == '__main__':
    unittest.main()
