/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class BillingCheckoutView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BillingCheckoutView._({
    required this.state,
    required this.customerKey,
    required this.clientKey,
    String? provider,
    this.storeId,
    this.channelKey,
    this.issueId,
    int? amountKrw,
    String? priceVersion,
  }) : provider = provider ?? 'toss',
       amountKrw = amountKrw ?? 2900,
       priceVersion = priceVersion ?? 'legacy-2900';

  factory BillingCheckoutView({
    required String state,
    required String customerKey,
    required String clientKey,
    String? provider,
    String? storeId,
    String? channelKey,
    String? issueId,
    int? amountKrw,
    String? priceVersion,
  }) = _BillingCheckoutViewImpl;

  factory BillingCheckoutView.fromJson(Map<String, dynamic> jsonSerialization) {
    return BillingCheckoutView(
      state: jsonSerialization['state'] as String,
      customerKey: jsonSerialization['customerKey'] as String,
      clientKey: jsonSerialization['clientKey'] as String,
      provider: jsonSerialization['provider'] as String?,
      storeId: jsonSerialization['storeId'] as String?,
      channelKey: jsonSerialization['channelKey'] as String?,
      issueId: jsonSerialization['issueId'] as String?,
      amountKrw: jsonSerialization['amountKrw'] as int?,
      priceVersion: jsonSerialization['priceVersion'] as String?,
    );
  }

  String state;

  String customerKey;

  String clientKey;

  String provider;

  String? storeId;

  String? channelKey;

  String? issueId;

  int amountKrw;

  String priceVersion;

  /// Returns a shallow copy of this [BillingCheckoutView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BillingCheckoutView copyWith({
    String? state,
    String? customerKey,
    String? clientKey,
    String? provider,
    String? storeId,
    String? channelKey,
    String? issueId,
    int? amountKrw,
    String? priceVersion,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BillingCheckoutView',
      'state': state,
      'customerKey': customerKey,
      'clientKey': clientKey,
      'provider': provider,
      if (storeId != null) 'storeId': storeId,
      if (channelKey != null) 'channelKey': channelKey,
      if (issueId != null) 'issueId': issueId,
      'amountKrw': amountKrw,
      'priceVersion': priceVersion,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BillingCheckoutView',
      'state': state,
      'customerKey': customerKey,
      'clientKey': clientKey,
      'provider': provider,
      if (storeId != null) 'storeId': storeId,
      if (channelKey != null) 'channelKey': channelKey,
      if (issueId != null) 'issueId': issueId,
      'amountKrw': amountKrw,
      'priceVersion': priceVersion,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BillingCheckoutViewImpl extends BillingCheckoutView {
  _BillingCheckoutViewImpl({
    required String state,
    required String customerKey,
    required String clientKey,
    String? provider,
    String? storeId,
    String? channelKey,
    String? issueId,
    int? amountKrw,
    String? priceVersion,
  }) : super._(
         state: state,
         customerKey: customerKey,
         clientKey: clientKey,
         provider: provider,
         storeId: storeId,
         channelKey: channelKey,
         issueId: issueId,
         amountKrw: amountKrw,
         priceVersion: priceVersion,
       );

  /// Returns a shallow copy of this [BillingCheckoutView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BillingCheckoutView copyWith({
    String? state,
    String? customerKey,
    String? clientKey,
    String? provider,
    Object? storeId = _Undefined,
    Object? channelKey = _Undefined,
    Object? issueId = _Undefined,
    int? amountKrw,
    String? priceVersion,
  }) {
    return BillingCheckoutView(
      state: state ?? this.state,
      customerKey: customerKey ?? this.customerKey,
      clientKey: clientKey ?? this.clientKey,
      provider: provider ?? this.provider,
      storeId: storeId is String? ? storeId : this.storeId,
      channelKey: channelKey is String? ? channelKey : this.channelKey,
      issueId: issueId is String? ? issueId : this.issueId,
      amountKrw: amountKrw ?? this.amountKrw,
      priceVersion: priceVersion ?? this.priceVersion,
    );
  }
}
