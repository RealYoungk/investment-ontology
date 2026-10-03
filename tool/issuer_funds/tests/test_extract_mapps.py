import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('extract_mapps', HERE.parent / 'extract_mapps.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
DOCS = {d['metadata']['periodEnd']: d['metadata'] for d in json.loads(module.MANIFEST.read_text())['documents']
        if d['metadata']['corpCode'] == '00600013'}


class ActualOwnFundStatements(unittest.TestCase):
    def text(self, end='2026-06-30'):
        return (HERE / 'fixtures' / f'mapps-{end}.txt').read_text()

    def parse(self, text=None, end='2026-06-30', metadata=None):
        return module.parse_current(metadata or DOCS[end], text or self.text(end))

    def test_all_six_actual_statement_fixtures(self):
        for end in DOCS:
            with self.subTest(end=end):
                r = self.parse(end=end)
                self.assertEqual(len(r['observations']), 7)
                for key in ('balanceDifference', 'cashRollDifference', 'cashActivityDifference',
                            'equityCloseDifference', 'equityMovementDifference', 'wholeProfitDifference'):
                    self.assertEqual(r['validation'][key], '0')
                self.assertFalse(r['automaticPosting'])
                self.assertFalse(r['fullStatementCollected'])
                self.assertIsNone(r['regularReportCode'])
                self.assertIsNone(r['xbrlAccountId'])

    def test_six_month_fiscal_year_stays_annual_fiscal_period(self):
        r = self.parse()
        self.assertEqual(r['periodKind'], 'ownSixMonthFiscalYear')
        self.assertEqual(r['periodStart'], '2026-01-01')
        self.assertEqual(r['periodEnd'], '2026-06-30')
        self.assertNotIn('operatingCashFlow', [x['metric'] for x in r['observations']])
        self.assertNotIn('propertyPlantEquipmentAcquisitions', [x['metric'] for x in r['observations']])

    def test_old_cash_definitions_are_not_silently_equated(self):
        for end in ['2021-12-31', '2022-12-31']:
            r = self.parse(end=end)
            self.assertEqual(r['numericState'], 'pendingCashScope')
            self.assertNotEqual(r['validation']['comparativeBSCashMinusCF'], '0')

    def test_wrong_issuer_and_document_type_rejected(self):
        for key, value in [('corpCode', '00435297'), ('documentType', 'assetManagementReport'),
                           ('periodStart', '2026-04-01'), ('periodEnd', '2026-12-31')]:
            m = copy.deepcopy(DOCS['2026-06-30'])
            m[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.parse(metadata=m)

    def test_statement_unit_cannot_be_changed(self):
        with self.assertRaises(ValueError):
            self.parse(self.text().replace('단위 : 원', '단위 : 천원'))

    def test_current_date_must_precede_comparative(self):
        text = self.text().replace('제 20 기 2026년 6월 30일 현재', '제 19 기 2025년 12월 31일 현재', 1)
        with self.assertRaises(ValueError):
            self.parse(text)

    def test_wrong_balance_cell_rejected(self):
        raw = self.parse()['observations'][0]['printedAmount']
        with self.assertRaises(ValueError):
            self.parse(self.text().replace(raw, '1', 1))

    def test_whole_equity_profit_cell_cannot_drift(self):
        r = self.parse()
        profit = next(x for x in r['observations'] if x['metric'] == 'netProfit')['printedAmount']
        pages = self.text().split('\f')
        for i, page in enumerate(pages):
            if page.strip().startswith('자본변동표'):
                pages[i] = page.replace(profit, '1', 1)
        with self.assertRaises(ValueError):
            self.parse('\f'.join(pages))

    def test_missing_current_never_uses_prior_or_zero(self):
        r = self.parse()
        target = next(x for x in r['observations'] if x['metric'] == 'investmentPropertyAcquisition')
        changed = target['rawLine'].replace(target['printedAmount'], '-', 1)
        with self.assertRaises(ValueError):
            self.parse(self.text().replace(target['rawLine'], changed, 1))

    def test_unreviewed_original_pdf_bytes_rejected_before_extractor(self):
        with tempfile.TemporaryDirectory() as directory:
            p = Path(directory) / 'different.pdf'
            p.write_bytes(b'%PDF-unreviewed')
            with self.assertRaisesRegex(ValueError, 'reviewed own audit'):
                module.extract_pdf(p)


if __name__ == '__main__':
    unittest.main()
