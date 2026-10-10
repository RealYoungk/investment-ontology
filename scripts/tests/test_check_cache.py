import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from check_cache import CheckCache, cacheable, check_environment, environment_key


class CacheTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'source'
        self.root.mkdir()
        self.cache_dir = Path(self.temp.name) / 'cache'
        self.git('init', '-q')
        self.git('config', 'user.name', 'Cache test')
        self.git('config', 'user.email', 'cache@example.invalid')
        self.git('config', 'core.hooksPath', '/dev/null')
        (self.root / 'source.txt').write_text('original\n')
        self.commit()
        self.command = ('dart', 'analyze', '--fatal-infos')

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, text=True).strip()

    def commit(self):
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')

    def cache(self, **env):
        cache = CheckCache(self.root, {'PATH': os.environ['PATH'], **env}, self.cache_dir)
        cache.runtime = 'runtime-1'
        return cache

    def test_success_reused_across_commit_labels_with_identical_tree(self):
        with patch('check_cache.execute') as run:
            first = self.cache(ALFINDER_BUILD_COMMIT='one').run(self.command)
            self.git('commit', '--allow-empty', '-qm', 'merge label')
            second = self.cache(ALFINDER_BUILD_COMMIT='two').run(self.command)
        self.assertEqual(first['origin'], 'executed')
        self.assertEqual(second['origin'], 'reused')
        self.assertEqual(run.call_count, 1)

    def test_source_environment_and_runtime_changes_invalidate_success(self):
        with patch('check_cache.execute') as run:
            self.cache(TEST_MODE='one').run(self.command)
            self.cache(TEST_MODE='two').run(self.command)
            changed = self.cache(TEST_MODE='two')
            changed.runtime = 'runtime-2'
            changed.run(self.command)
            (self.root / 'source.txt').write_text('changed\n')
            self.commit()
            changed.run(self.command)
        self.assertEqual(run.call_count, 4)

    def test_selected_server_checks_cannot_replace_full_server_check(self):
        with patch('check_cache.execute') as run:
            self.cache().run(('bash', 'scripts/test-server.sh', 'test/unit/example_test.dart'))
            self.cache().run(('bash', 'scripts/test-server.sh'))
        self.assertEqual(run.call_count, 2)

    def test_failed_check_never_records_success(self):
        with patch('check_cache.execute', side_effect=subprocess.CalledProcessError(1, self.command)):
            with self.assertRaises(subprocess.CalledProcessError):
                self.cache().run(self.command)
        self.assertEqual(list(self.cache_dir.glob('*.json')), [])
        with patch('check_cache.execute') as run:
            self.assertEqual(self.cache().run(self.command)['origin'], 'executed')
            self.assertEqual(run.call_count, 1)

    def test_dirty_and_disabled_checks_execute_without_cache(self):
        with patch('check_cache.execute') as run:
            self.cache().run(self.command)
            (self.root / 'untracked.txt').write_text('unreviewed')
            self.assertEqual(self.cache().run(self.command)['origin'], 'executed')
            (self.root / 'untracked.txt').unlink()
            self.assertEqual(self.cache(ALFINDER_CHECK_CACHE='off').run(self.command)['origin'], 'executed')
        self.assertEqual(run.call_count, 3)
        self.assertEqual(len(list(self.cache_dir.glob('*.json'))), 1)

    def test_source_change_during_check_is_not_success(self):
        def mutate(*args, **kwargs):
            (self.root / 'source.txt').write_text('changed while running\n')
        with patch('check_cache.execute', side_effect=mutate):
            with self.assertRaisesRegex(ValueError, 'inputs changed'):
                self.cache().run(self.command)
        self.assertEqual(list(self.cache_dir.glob('*.json')), [])

    def test_corrupt_expired_or_failed_records_are_reexecuted(self):
        with patch('check_cache.execute') as run:
            self.cache().run(self.command)
            record = next(self.cache_dir.glob('*.json'))
            record.write_text('broken json')
            self.cache().run(self.command)
            value = json.loads(record.read_text())
            value['completedAt'] = time.time() - 8 * 24 * 60 * 60
            record.write_text(json.dumps(value))
            self.cache().run(self.command)
            value = json.loads(record.read_text())
            value['status'] = 'failed'
            record.write_text(json.dumps(value))
            self.cache().run(self.command)
        self.assertEqual(run.call_count, 4)

    def test_secrets_are_not_persisted(self):
        with patch('check_cache.execute'):
            self.cache(TEST_SECRET='a-secret-never-write').run(self.command)
        text = next(self.cache_dir.glob('*.json')).read_text()
        self.assertNotIn('a-secret-never-write', text)
        self.assertNotIn('TEST_SECRET', text)

    def test_same_tree_in_another_checkout_reuses_success(self):
        clone = Path(self.temp.name) / 'release-clone'
        self.git('clone', '--quiet', str(self.root), str(clone))
        cache = CheckCache(clone, {'PATH': os.environ['PATH']}, self.cache_dir)
        cache.runtime = 'runtime-1'
        with patch('check_cache.execute') as run:
            self.cache().run(self.command)
            self.assertEqual(cache.run(self.command)['origin'], 'reused')
        self.assertEqual(run.call_count, 1)

    def test_concurrent_identical_checks_execute_only_once(self):
        from concurrent.futures import ThreadPoolExecutor
        with patch('check_cache.execute', side_effect=lambda *args: time.sleep(0.1)) as run:
            with ThreadPoolExecutor(max_workers=2) as pool:
                results = list(pool.map(lambda _: self.cache().run(self.command), range(2)))
        self.assertEqual(run.call_count, 1)
        self.assertEqual(sorted(row['origin'] for row in results), ['executed', 'reused'])

    def test_symlink_entry_is_rejected(self):
        with patch('check_cache.execute'):
            self.cache().run(self.command)
        record = next(self.cache_dir.glob('*.json'))
        saved = record.read_text()
        record.unlink()
        target = Path(self.temp.name) / 'foreign.json'
        target.write_text(saved)
        record.symlink_to(target)
        with self.assertRaisesRegex(ValueError, 'symlinks'):
            self.cache().run(self.command)


class PolicyTest(unittest.TestCase):
    def test_macos_hook_defaults_match_cli_but_preserve_explicit_overrides(self):
        def response(command, **kwargs):
            return '/tool/git-core\n' if command[0] == 'git' else '/tool/sdk\n'
        cli = {'PATH': '/bin'}
        hook = {'PATH': '/tool/git-core:/bin', 'GIT_EXEC_PATH': '/tool/git-core',
                'SDKROOT': '/tool/sdk', 'CPATH': '/usr/local/include',
                'LIBRARY_PATH': '/usr/local/lib', 'MANPATH': '/tool/man'}
        with patch('check_cache.sys.platform', 'darwin'), patch('check_cache.subprocess.check_output', side_effect=response):
            self.assertEqual(environment_key(check_environment('.', cli)),
                             environment_key(check_environment('.', hook)))
            custom = check_environment('.', dict(cli, SDKROOT='/custom/sdk', CPATH='/custom/include'))
        self.assertEqual(custom['SDKROOT'], '/custom/sdk')
        self.assertEqual(custom['CPATH'], '/custom/include')

    def test_setup_builds_browser_checks_and_unknown_commands_are_uncached(self):
        for command in [('flutter', 'pub', 'get', '--enforce-lockfile'),
                        ('flutter', 'build', 'web'),
                        ('bash', 'scripts/test-billing-browser.sh'),
                        ('python3', 'scripts/anything.py')]:
            self.assertFalse(cacheable(command, '.'))
        self.assertFalse(cacheable(('flutter', 'test', '--platform', 'chrome'),
                                   'investment_ontology_serverpod_flutter'))

    def test_run_labels_are_ignored_but_real_environment_changes_are_not(self):
        self.assertEqual(environment_key({'GITHUB_SHA': 'one', 'LANG': 'ko_KR'}),
                         environment_key({'GITHUB_SHA': 'two', 'LANG': 'ko_KR'}))
        self.assertNotEqual(environment_key({'LANG': 'ko_KR'}), environment_key({'LANG': 'en_US'}))


if __name__ == '__main__':
    unittest.main()
