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

abstract class BillingPaymentView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BillingPaymentView._({
    required this.attemptId,
    required this.orderId,
    required this.status,
    required this.amountKrw,
    required this.paidFromUtc,
    required this.paidThroughUtc,
  });

  factory BillingPaymentView({
    required int attemptId,
    required String orderId,
    required String status,
    required int amountKrw,
    required DateTime paidFromUtc,
    required DateTime paidThroughUtc,
  }) = _BillingPaymentViewImpl;

  factory BillingPaymentView.fromJson(Map<String, dynamic> jsonSerialization) {
    return BillingPaymentView(
      attemptId: jsonSerialization['attemptId'] as int,
      orderId: jsonSerialization['orderId'] as String,
      status: jsonSerialization['status'] as String,
      amountKrw: jsonSerialization['amountKrw'] as int,
      paidFromUtc: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['paidFromUtc'],
      ),
      paidThroughUtc: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['paidThroughUtc'],
      ),
    );
  }

  int attemptId;

  String orderId;

  String status;

  int amountKrw;

  DateTime paidFromUtc;

  DateTime paidThroughUtc;

  /// Returns a shallow copy of this [BillingPaymentView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BillingPaymentView copyWith({
    int? attemptId,
    String? orderId,
    String? status,
    int? amountKrw,
    DateTime? paidFromUtc,
    DateTime? paidThroughUtc,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BillingPaymentView',
      'attemptId': attemptId,
      'orderId': orderId,
      'status': status,
      'amountKrw': amountKrw,
      'paidFromUtc': paidFromUtc.toJson(),
      'paidThroughUtc': paidThroughUtc.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BillingPaymentView',
      'attemptId': attemptId,
      'orderId': orderId,
      'status': status,
      'amountKrw': amountKrw,
      'paidFromUtc': paidFromUtc.toJson(),
      'paidThroughUtc': paidThroughUtc.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _BillingPaymentViewImpl extends BillingPaymentView {
  _BillingPaymentViewImpl({
    required int attemptId,
    required String orderId,
    required String status,
    required int amountKrw,
    required DateTime paidFromUtc,
    required DateTime paidThroughUtc,
  }) : super._(
         attemptId: attemptId,
         orderId: orderId,
         status: status,
         amountKrw: amountKrw,
         paidFromUtc: paidFromUtc,
         paidThroughUtc: paidThroughUtc,
       );

  /// Returns a shallow copy of this [BillingPaymentView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BillingPaymentView copyWith({
    int? attemptId,
    String? orderId,
    String? status,
    int? amountKrw,
    DateTime? paidFromUtc,
    DateTime? paidThroughUtc,
  }) {
    return BillingPaymentView(
      attemptId: attemptId ?? this.attemptId,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      amountKrw: amountKrw ?? this.amountKrw,
      paidFromUtc: paidFromUtc ?? this.paidFromUtc,
      paidThroughUtc: paidThroughUtc ?? this.paidThroughUtc,
    );
  }
}
