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
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart'
    as _i4yshtjp;
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/business_product.dart' as _inhnrb3l;

abstract class BusinessUnderstanding
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BusinessUnderstanding._({
    required this.status,
    required this.products,
    this.bsnsYear,
    this.rceptNo,
    this.computedAt,
    required this.ruleVersion,
  });

  factory BusinessUnderstanding({
    required String status,
    required List<_inhnrb3l.BusinessProduct> products,
    int? bsnsYear,
    String? rceptNo,
    DateTime? computedAt,
    required int ruleVersion,
  }) = _BusinessUnderstandingImpl;

  factory BusinessUnderstanding.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return BusinessUnderstanding(
      status: jsonSerialization['status'] as String,
      products: _i4yshtjp.Protocol()
          .deserialize<List<_inhnrb3l.BusinessProduct>>(
            jsonSerialization['products'],
          ),
      bsnsYear: jsonSerialization['bsnsYear'] as int?,
      rceptNo: jsonSerialization['rceptNo'] as String?,
      computedAt: jsonSerialization['computedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['computedAt']),
      ruleVersion: jsonSerialization['ruleVersion'] as int,
    );
  }

  String status;

  List<_inhnrb3l.BusinessProduct> products;

  int? bsnsYear;

  String? rceptNo;

  DateTime? computedAt;

  int ruleVersion;

  /// Returns a shallow copy of this [BusinessUnderstanding]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessUnderstanding copyWith({
    String? status,
    List<_inhnrb3l.BusinessProduct>? products,
    int? bsnsYear,
    String? rceptNo,
    DateTime? computedAt,
    int? ruleVersion,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessUnderstanding',
      'status': status,
      'products': products.toJson(valueToJson: (v) => v.toJson()),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (rceptNo != null) 'rceptNo': rceptNo,
      if (computedAt != null) 'computedAt': computedAt?.toJson(),
      'ruleVersion': ruleVersion,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessUnderstanding',
      'status': status,
      'products': products.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (rceptNo != null) 'rceptNo': rceptNo,
      if (computedAt != null) 'computedAt': computedAt?.toJson(),
      'ruleVersion': ruleVersion,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessUnderstandingImpl extends BusinessUnderstanding {
  _BusinessUnderstandingImpl({
    required String status,
    required List<_inhnrb3l.BusinessProduct> products,
    int? bsnsYear,
    String? rceptNo,
    DateTime? computedAt,
    required int ruleVersion,
  }) : super._(
         status: status,
         products: products,
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         computedAt: computedAt,
         ruleVersion: ruleVersion,
       );

  /// Returns a shallow copy of this [BusinessUnderstanding]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessUnderstanding copyWith({
    String? status,
    List<_inhnrb3l.BusinessProduct>? products,
    Object? bsnsYear = _Undefined,
    Object? rceptNo = _Undefined,
    Object? computedAt = _Undefined,
    int? ruleVersion,
  }) {
    return BusinessUnderstanding(
      status: status ?? this.status,
      products: products ?? this.products.map((e0) => e0.copyWith()).toList(),
      bsnsYear: bsnsYear is int? ? bsnsYear : this.bsnsYear,
      rceptNo: rceptNo is String? ? rceptNo : this.rceptNo,
      computedAt: computedAt is DateTime? ? computedAt : this.computedAt,
      ruleVersion: ruleVersion ?? this.ruleVersion,
    );
  }
}
