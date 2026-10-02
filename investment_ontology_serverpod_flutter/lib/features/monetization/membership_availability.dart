/// Explicit launch gate. Production builds stay view-only until enabled.
const membershipCheckoutEnabled = bool.fromEnvironment(
  'MEMBERSHIP_CHECKOUT_ENABLED',
  defaultValue: false,
);
