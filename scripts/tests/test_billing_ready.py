import base64
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('billing_ready', Path(__file__).parents[1] / 'check_billing_ready.py')
billing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(billing)


def ready():
    return {
        'ALFINDER_BILLING_PROVIDER': 'portone',
        'PORTONE_CONTRACT_PG': 'kcp_v2',
        'ALFINDER_BILLING_SANDBOX_ENABLED': 'false',
        'ALFINDER_BILLING_LIVE_ENABLED': 'true',
        'ALFINDER_PG_BILLING_APPROVED': 'true',
        'ALFINDER_BILLING_PRIVACY_READY': 'true',
        'PORTONE_LIVE_CHANNEL_VERIFIED': 'true',
        'ALFINDER_BILLING_CHARGES_PAUSED': 'false',
        'ALFINDER_BILLING_TERMS_VERSION': '2026-10-02',
        'ALFINDER_NEW_SUBSCRIPTION_PRICE_KRW': '4900',
        'PORTONE_LIVE_STORE_ID': 'store-fixture',
        'PORTONE_LIVE_CHANNEL_KEY': 'channel-key-fixture',
        'PORTONE_LIVE_API_SECRET': 'private-fixture-secret',
        'BILLING_ENCRYPTION_KEY': base64.b64encode(bytes(32)).decode(),
    }


class BillingReadinessTest(unittest.TestCase):
    def test_pending_template_never_ready_and_secrets_never_printed(self):
        self.assertTrue(billing.check(ready())['ready'])
        for key in ready():
            values = ready()
            values.pop(key)
            result = billing.check(values)
            self.assertFalse(result['ready'], key)
            self.assertNotIn('private-fixture-secret', json.dumps(result))

    def test_file_permissions_duplicates_and_shell_expansion_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'billing.env'
            path.write_text('KEY=value\n')
            os.chmod(path, 0o644)
            with self.assertRaises(ValueError):
                billing.read_env(path)
            os.chmod(path, 0o600)
            self.assertEqual(billing.read_env(path), {'KEY': 'value'})
            for content in ['KEY=a\nKEY=b', 'KEY=$(anything)', 'KEY=`anything`']:
                path.write_text(content)
                with self.assertRaises(ValueError):
                    billing.read_env(path)
