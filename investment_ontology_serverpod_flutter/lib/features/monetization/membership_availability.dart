/// Build-time emergency gate. Server paymentAvailable remains the live gate.
const membershipCheckoutEnabled = bool.fromEnvironment(
  'MEMBERSHIP_CHECKOUT_ENABLED',
  defaultValue: false,
);
