"""Pure checks of candidate identity/index invariants; no HTTP or database."""
import copy
import json
import unittest
from verify_header18_packages import ASSETS, verify


class Packages(unittest.TestCase):
    def setUp(self):
        self.entries = json.loads((ASSETS / 'assets/financial_source_cache/header18-candidates.json').read_text())

    def test_actual_18_byte_exact_packages(self):
        self.assertEqual(13, sum(entry['numeric'] for entry in self.entries))
        self.assertEqual(5, sum(not entry['numeric'] for entry in self.entries))
        for entry in self.entries:
            with self.subTest(receipt=entry['targetReceipt'], basis=entry['basis']):
                self.assertTrue(verify(entry)['byteVerified'])

    def test_index_identity_and_digest_cannot_be_replaced(self):
        for field, value in [('targetReceipt', '20260101000001'), ('originalReceipt', '20200101000001'),
                             ('corpCode', '00000000'), ('basis', 'cfs'), ('year', 2025),
                             ('sourceRole', 'unproven'), ('manifestSha256', '0' * 64)]:
            entry = copy.deepcopy(self.entries[0])
            entry[field] = value
            with self.subTest(field=field), self.assertRaises(AssertionError):
                verify(entry)

    def test_corrected_audit_money_receipt_differs_from_original_cover(self):
        entry = next(e for e in self.entries if e['targetReceipt'] == '20220328000884' and e['basis'] == 'ofs')
        manifest = json.loads((ASSETS / entry['directory'] / 'manifest.json').read_text())
        self.assertEqual(entry['targetReceipt'], manifest['numericSourceReceipt'])
        self.assertNotEqual(manifest['originalReceipt'], manifest['numericSourceReceipt'])


if __name__ == '__main__':
    unittest.main()
