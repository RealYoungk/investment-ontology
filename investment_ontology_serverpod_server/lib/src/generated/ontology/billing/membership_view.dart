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
import 'package:serverpod/serverpod.dart' as _is;

abstract class MembershipView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  MembershipView._({
    required this.adFree,
    this.paidThroughUtc,
    required this.cancelAtPeriodEnd,
    bool? paymentAvailable,
    this.termsVersion,
    bool? isTest,
    int? currentPriceKrw,
    this.appliedPriceKrw,
    this.nextChargeUtc,
    this.graceThroughUtc,
    bool? priceProtected,
  }) : paymentAvailable = paymentAvailable ?? false,
       isTest = isTest ?? false,
       currentPriceKrw = currentPriceKrw ?? 4900,
       priceProtected = priceProtected ?? false;

  factory MembershipView({
    required bool adFree,
    DateTime? paidThroughUtc,
    required bool cancelAtPeriodEnd,
    bool? paymentAvailable,
    String? termsVersion,
    bool? isTest,
    int? currentPriceKrw,
    int? appliedPriceKrw,
    DateTime? nextChargeUtc,
    DateTime? graceThroughUtc,
    bool? priceProtected,
  }) = _MembershipViewImpl;

  factory MembershipView.fromJson(Map<String, dynamic> jsonSerialization) {
    return MembershipView(
      adFree: _is.BoolJsonExtension.fromJson(jsonSerialization['adFree']),
      paidThroughUtc: jsonSerialization['paidThroughUtc'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['paidThroughUtc'],
            ),
      cancelAtPeriodEnd: _is.BoolJsonExtension.fromJson(
        jsonSerialization['cancelAtPeriodEnd'],
      ),
      paymentAvailable: jsonSerialization['paymentAvailable'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(
              jsonSerialization['paymentAvailable'],
            ),
      termsVersion: jsonSerialization['termsVersion'] as String?,
      isTest: jsonSerialization['isTest'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['isTest']),
      currentPriceKrw: jsonSerialization['currentPriceKrw'] as int?,
      appliedPriceKrw: jsonSerialization['appliedPriceKrw'] as int?,
      nextChargeUtc: jsonSerialization['nextChargeUtc'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['nextChargeUtc'],
            ),
      graceThroughUtc: jsonSerialization['graceThroughUtc'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['graceThroughUtc'],
            ),
      priceProtected: jsonSerialization['priceProtected'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['priceProtected']),
    );
  }

  bool adFree;

  DateTime? paidThroughUtc;

  bool cancelAtPeriodEnd;

  bool paymentAvailable;

  String? termsVersion;

  bool isTest;

  int currentPriceKrw;

  int? appliedPriceKrw;

  DateTime? nextChargeUtc;

  DateTime? graceThroughUtc;

  bool priceProtected;

  /// Returns a shallow copy of this [MembershipView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MembershipView copyWith({
    bool? adFree,
    DateTime? paidThroughUtc,
    bool? cancelAtPeriodEnd,
    bool? paymentAvailable,
    String? termsVersion,
    bool? isTest,
    int? currentPriceKrw,
    int? appliedPriceKrw,
    DateTime? nextChargeUtc,
    DateTime? graceThroughUtc,
    bool? priceProtected,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MembershipView',
      'adFree': adFree,
      if (paidThroughUtc != null) 'paidThroughUtc': paidThroughUtc?.toJson(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'paymentAvailable': paymentAvailable,
      if (termsVersion != null) 'termsVersion': termsVersion,
      'isTest': isTest,
      'currentPriceKrw': currentPriceKrw,
      if (appliedPriceKrw != null) 'appliedPriceKrw': appliedPriceKrw,
      if (nextChargeUtc != null) 'nextChargeUtc': nextChargeUtc?.toJson(),
      if (graceThroughUtc != null) 'graceThroughUtc': graceThroughUtc?.toJson(),
      'priceProtected': priceProtected,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MembershipView',
      'adFree': adFree,
      if (paidThroughUtc != null) 'paidThroughUtc': paidThroughUtc?.toJson(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'paymentAvailable': paymentAvailable,
      if (termsVersion != null) 'termsVersion': termsVersion,
      'isTest': isTest,
      'currentPriceKrw': currentPriceKrw,
      if (appliedPriceKrw != null) 'appliedPriceKrw': appliedPriceKrw,
      if (nextChargeUtc != null) 'nextChargeUtc': nextChargeUtc?.toJson(),
      if (graceThroughUtc != null) 'graceThroughUtc': graceThroughUtc?.toJson(),
      'priceProtected': priceProtected,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MembershipViewImpl extends MembershipView {
  _MembershipViewImpl({
    required bool adFree,
    DateTime? paidThroughUtc,
    required bool cancelAtPeriodEnd,
    bool? paymentAvailable,
    String? termsVersion,
    bool? isTest,
    int? currentPriceKrw,
    int? appliedPriceKrw,
    DateTime? nextChargeUtc,
    DateTime? graceThroughUtc,
    bool? priceProtected,
  }) : super._(
         adFree: adFree,
         paidThroughUtc: paidThroughUtc,
         cancelAtPeriodEnd: cancelAtPeriodEnd,
         paymentAvailable: paymentAvailable,
         termsVersion: termsVersion,
         isTest: isTest,
         currentPriceKrw: currentPriceKrw,
         appliedPriceKrw: appliedPriceKrw,
         nextChargeUtc: nextChargeUtc,
         graceThroughUtc: graceThroughUtc,
         priceProtected: priceProtected,
       );

  /// Returns a shallow copy of this [MembershipView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MembershipView copyWith({
    bool? adFree,
    Object? paidThroughUtc = _Undefined,
    bool? cancelAtPeriodEnd,
    bool? paymentAvailable,
    Object? termsVersion = _Undefined,
    bool? isTest,
    int? currentPriceKrw,
    Object? appliedPriceKrw = _Undefined,
    Object? nextChargeUtc = _Undefined,
    Object? graceThroughUtc = _Undefined,
    bool? priceProtected,
  }) {
    return MembershipView(
      adFree: adFree ?? this.adFree,
      paidThroughUtc: paidThroughUtc is DateTime?
          ? paidThroughUtc
          : this.paidThroughUtc,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      paymentAvailable: paymentAvailable ?? this.paymentAvailable,
      termsVersion: termsVersion is String? ? termsVersion : this.termsVersion,
      isTest: isTest ?? this.isTest,
      currentPriceKrw: currentPriceKrw ?? this.currentPriceKrw,
      appliedPriceKrw: appliedPriceKrw is int?
          ? appliedPriceKrw
          : this.appliedPriceKrw,
      nextChargeUtc: nextChargeUtc is DateTime?
          ? nextChargeUtc
          : this.nextChargeUtc,
      graceThroughUtc: graceThroughUtc is DateTime?
          ? graceThroughUtc
          : this.graceThroughUtc,
      priceProtected: priceProtected ?? this.priceProtected,
    );
  }
}
