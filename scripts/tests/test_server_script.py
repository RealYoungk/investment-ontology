"""No Dart/compiler/database is launched: mock transport tests for the gate."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'test-server.sh'


class ServerTestScriptTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'scripts').mkdir()
        shutil.copyfile(SCRIPT, self.root / 'scripts/test-server.sh')
        self.server = self.root / 'investment_ontology_serverpod_server'
        (self.server / 'test/nested').mkdir(parents=True)
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        mock = self.bin / 'flutter'
        mock.write_text('#!/usr/bin/env python3\nimport json,os,sys\nwith open(os.environ["CALLS"],"a") as f: f.write(json.dumps(sys.argv[1:])+"\\n")\nsys.exit(7 if os.environ.get("FAIL") else 0)\n')
        mock.chmod(0o755)
        self.calls = self.root / 'calls.jsonl'
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'], CALLS=str(self.calls))

    def files(self, count):
        names = [f'test/nested/case {i:03}_test.dart' for i in range(count)]
        for name in names:
            (self.server / name).touch()
        subprocess.run(['git', '-C', str(self.root), 'add', '.'], check=True)
        return names

    def run_script(self, *args):
        return subprocess.run(['bash', str(self.root / 'scripts/test-server.sh'), *args], env=self.env, capture_output=True, text=True)

    def read_calls(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []

    def test_full_gate_visits_every_tracked_and_untracked_file_once_in_bounded_batches(self):
        names = self.files(53)
        extra = 'test/new_test.dart'
        (self.server / extra).touch()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.read_calls()
        self.assertEqual([len(x) - 3 for x in calls], [25, 25, 4])
        flattened = [name for call in calls for name in call[3:]]
        self.assertCountEqual(flattened, names + [extra])
        self.assertEqual(len(set(flattened)), 54)
        self.assertTrue(all(x[:3] == ['pub', 'run', 'test'] for x in calls))

    def test_focused_arguments_unchanged(self):
        self.assertEqual(self.run_script('test/a_test.dart', '--plain-name', 'a b').returncode, 0)
        self.assertEqual(self.read_calls(), [['pub', 'run', 'test', 'test/a_test.dart', '--plain-name', 'a b']])

    def test_failed_batch_stops_before_next_batch(self):
        self.files(53)
        self.env['FAIL'] = '1'
        self.assertEqual(self.run_script().returncode, 7)
        self.assertEqual(len(self.read_calls()), 1)

    def test_missing_tracked_file_fails_before_dart(self):
        names = self.files(2)
        (self.server / names[0]).unlink()
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertEqual(self.read_calls(), [])

    def test_empty_gate_fails(self):
        self.assertNotEqual(self.run_script().returncode, 0)
        self.assertEqual(self.read_calls(), [])


if __name__ == '__main__':
    unittest.main()
