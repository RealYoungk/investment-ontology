import 'dart:js_interop';

import 'package:investment_ontology_serverpod_client/investment_ontology_serverpod_client.dart';

@JS('alfinderBilling.start')
external JSPromise<JSAny?> _start(
  JSString key,
  JSString customer,
  JSString state,
  JSString provider,
  JSString storeId,
  JSString channelKey,
  JSString issueId,
);
@JS('alfinderBilling.clearQuery')
external void _clear();
Future<void> openBilling(BillingCheckoutView view) => _start(
  view.clientKey.toJS,
  view.customerKey.toJS,
  view.state.toJS,
  view.provider.toJS,
  (view.storeId ?? '').toJS,
  (view.channelKey ?? '').toJS,
  (view.issueId ?? '').toJS,
).toDart;
void clearBillingQuery() => _clear();
