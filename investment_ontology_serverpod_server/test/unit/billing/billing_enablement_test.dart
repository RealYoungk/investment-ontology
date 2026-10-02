import 'package:investment_ontology_serverpod_server/src/ontology/billing/billing_provider_config.dart';
import 'package:test/test.dart';

void main() {
  test(
    'pause disables new charges without disabling reconciliation credentials',
    () {
      final environment = {
        'ALFINDER_BILLING_SANDBOX_ENABLED': 'true',
        'ALFINDER_BILLING_CHARGES_PAUSED': 'true',
      };
      expect(BillingSandboxConfig.enabledInMode('test', environment), true);
      expect(
        BillingSandboxConfig.chargesEnabledInMode('test', environment),
        false,
      );
      expect(
        BillingSandboxConfig.chargesEnabledInMode('production', environment),
        false,
      );
    },
  );

  const ready = {
    'ALFINDER_BILLING_LIVE_ENABLED': 'true',
    'ALFINDER_PG_BILLING_APPROVED': 'true',
    'ALFINDER_BILLING_PRIVACY_READY': 'true',
    'ALFINDER_BILLING_TERMS_VERSION': 'approved-version',
  };
  test('production stays off unless all launch conditions are explicit', () {
    expect(BillingSandboxConfig.enabledInMode('production', {}), false);
    expect(
      BillingSandboxConfig.enabledInMode('production', {
        'ALFINDER_BILLING_SANDBOX_ENABLED': 'true',
      }),
      false,
    );
    for (final key in ready.keys) {
      expect(
        BillingSandboxConfig.enabledInMode(
          'production',
          {...ready}..remove(key),
        ),
        false,
      );
    }
    expect(
      BillingSandboxConfig.enabledInMode('production', {
        ...ready,
        'ALFINDER_BILLING_TERMS_VERSION': '  ',
      }),
      false,
    );
    expect(BillingSandboxConfig.enabledInMode('production', ready), true);
  });
  test('test mode requires its own flag and never uses production flag', () {
    for (final mode in ['development', 'test', 'staging']) {
      expect(BillingSandboxConfig.enabledInMode(mode, ready), false);
      expect(
        BillingSandboxConfig.enabledInMode(mode, {
          'ALFINDER_BILLING_SANDBOX_ENABLED': 'true',
        }),
        true,
      );
    }
  });
}
