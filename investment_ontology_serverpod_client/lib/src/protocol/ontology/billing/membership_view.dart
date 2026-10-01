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

abstract class MembershipView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MembershipView._({
    required this.adFree,
    this.paidThroughUtc,
    required this.cancelAtPeriodEnd,
    bool? paymentAvailable,
    this.termsVersion,
    bool? isTest,
  }) : paymentAvailable = paymentAvailable ?? false,
       isTest = isTest ?? false;

  factory MembershipView({
    required bool adFree,
    DateTime? paidThroughUtc,
    required bool cancelAtPeriodEnd,
    bool? paymentAvailable,
    String? termsVersion,
    bool? isTest,
  }) = _MembershipViewImpl;

  factory MembershipView.fromJson(Map<String, dynamic> jsonSerialization) {
    return MembershipView(
      adFree: _isc.BoolJsonExtension.fromJson(jsonSerialization['adFree']),
      paidThroughUtc: jsonSerialization['paidThroughUtc'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['paidThroughUtc'],
            ),
      cancelAtPeriodEnd: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['cancelAtPeriodEnd'],
      ),
      paymentAvailable: jsonSerialization['paymentAvailable'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(
              jsonSerialization['paymentAvailable'],
            ),
      termsVersion: jsonSerialization['termsVersion'] as String?,
      isTest: jsonSerialization['isTest'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['isTest']),
    );
  }

  bool adFree;

  DateTime? paidThroughUtc;

  bool cancelAtPeriodEnd;

  bool paymentAvailable;

  String? termsVersion;

  bool isTest;

  /// Returns a shallow copy of this [MembershipView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MembershipView copyWith({
    bool? adFree,
    DateTime? paidThroughUtc,
    bool? cancelAtPeriodEnd,
    bool? paymentAvailable,
    String? termsVersion,
    bool? isTest,
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
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
  }) : super._(
         adFree: adFree,
         paidThroughUtc: paidThroughUtc,
         cancelAtPeriodEnd: cancelAtPeriodEnd,
         paymentAvailable: paymentAvailable,
         termsVersion: termsVersion,
         isTest: isTest,
       );

  /// Returns a shallow copy of this [MembershipView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MembershipView copyWith({
    bool? adFree,
    Object? paidThroughUtc = _Undefined,
    bool? cancelAtPeriodEnd,
    bool? paymentAvailable,
    Object? termsVersion = _Undefined,
    bool? isTest,
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
    );
  }
}
