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

abstract class IndustryActivity
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  IndustryActivity._({
    required this.corpCode,
    required this.companyName,
    required this.market,
    this.industryCode,
    required this.productKey,
    required this.productName,
    required this.role,
    required this.process,
    this.target,
    this.method,
    required this.evidence,
    required this.bsnsYear,
    required this.rceptNo,
    this.industryKey,
    this.industryName,
    this.groupName,
    this.classificationBasis,
  });

  factory IndustryActivity({
    required String corpCode,
    required String companyName,
    required String market,
    String? industryCode,
    required String productKey,
    required String productName,
    required String role,
    required String process,
    String? target,
    String? method,
    required String evidence,
    required int bsnsYear,
    required String rceptNo,
    String? industryKey,
    String? industryName,
    String? groupName,
    String? classificationBasis,
  }) = _IndustryActivityImpl;

  factory IndustryActivity.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndustryActivity(
      corpCode: jsonSerialization['corpCode'] as String,
      companyName: jsonSerialization['companyName'] as String,
      market: jsonSerialization['market'] as String,
      industryCode: jsonSerialization['industryCode'] as String?,
      productKey: jsonSerialization['productKey'] as String,
      productName: jsonSerialization['productName'] as String,
      role: jsonSerialization['role'] as String,
      process: jsonSerialization['process'] as String,
      target: jsonSerialization['target'] as String?,
      method: jsonSerialization['method'] as String?,
      evidence: jsonSerialization['evidence'] as String,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      industryKey: jsonSerialization['industryKey'] as String?,
      industryName: jsonSerialization['industryName'] as String?,
      groupName: jsonSerialization['groupName'] as String?,
      classificationBasis: jsonSerialization['classificationBasis'] as String?,
    );
  }

  String corpCode;

  String companyName;

  String market;

  String? industryCode;

  String productKey;

  String productName;

  String role;

  String process;

  String? target;

  String? method;

  String evidence;

  int bsnsYear;

  String rceptNo;

  /// Alfinder navigation category, not an assigned GICS code.
  String? industryKey;

  String? industryName;

  String? groupName;

  /// filing or ksic or unclassified. KSIC does not establish product evidence.
  String? classificationBasis;

  /// Returns a shallow copy of this [IndustryActivity]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  IndustryActivity copyWith({
    String? corpCode,
    String? companyName,
    String? market,
    String? industryCode,
    String? productKey,
    String? productName,
    String? role,
    String? process,
    String? target,
    String? method,
    String? evidence,
    int? bsnsYear,
    String? rceptNo,
    String? industryKey,
    String? industryName,
    String? groupName,
    String? classificationBasis,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndustryActivity',
      'corpCode': corpCode,
      'companyName': companyName,
      'market': market,
      if (industryCode != null) 'industryCode': industryCode,
      'productKey': productKey,
      'productName': productName,
      'role': role,
      'process': process,
      if (target != null) 'target': target,
      if (method != null) 'method': method,
      'evidence': evidence,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      if (industryKey != null) 'industryKey': industryKey,
      if (industryName != null) 'industryName': industryName,
      if (groupName != null) 'groupName': groupName,
      if (classificationBasis != null)
        'classificationBasis': classificationBasis,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndustryActivity',
      'corpCode': corpCode,
      'companyName': companyName,
      'market': market,
      if (industryCode != null) 'industryCode': industryCode,
      'productKey': productKey,
      'productName': productName,
      'role': role,
      'process': process,
      if (target != null) 'target': target,
      if (method != null) 'method': method,
      'evidence': evidence,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      if (industryKey != null) 'industryKey': industryKey,
      if (industryName != null) 'industryName': industryName,
      if (groupName != null) 'groupName': groupName,
      if (classificationBasis != null)
        'classificationBasis': classificationBasis,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IndustryActivityImpl extends IndustryActivity {
  _IndustryActivityImpl({
    required String corpCode,
    required String companyName,
    required String market,
    String? industryCode,
    required String productKey,
    required String productName,
    required String role,
    required String process,
    String? target,
    String? method,
    required String evidence,
    required int bsnsYear,
    required String rceptNo,
    String? industryKey,
    String? industryName,
    String? groupName,
    String? classificationBasis,
  }) : super._(
         corpCode: corpCode,
         companyName: companyName,
         market: market,
         industryCode: industryCode,
         productKey: productKey,
         productName: productName,
         role: role,
         process: process,
         target: target,
         method: method,
         evidence: evidence,
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         industryKey: industryKey,
         industryName: industryName,
         groupName: groupName,
         classificationBasis: classificationBasis,
       );

  /// Returns a shallow copy of this [IndustryActivity]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  IndustryActivity copyWith({
    String? corpCode,
    String? companyName,
    String? market,
    Object? industryCode = _Undefined,
    String? productKey,
    String? productName,
    String? role,
    String? process,
    Object? target = _Undefined,
    Object? method = _Undefined,
    String? evidence,
    int? bsnsYear,
    String? rceptNo,
    Object? industryKey = _Undefined,
    Object? industryName = _Undefined,
    Object? groupName = _Undefined,
    Object? classificationBasis = _Undefined,
  }) {
    return IndustryActivity(
      corpCode: corpCode ?? this.corpCode,
      companyName: companyName ?? this.companyName,
      market: market ?? this.market,
      industryCode: industryCode is String? ? industryCode : this.industryCode,
      productKey: productKey ?? this.productKey,
      productName: productName ?? this.productName,
      role: role ?? this.role,
      process: process ?? this.process,
      target: target is String? ? target : this.target,
      method: method is String? ? method : this.method,
      evidence: evidence ?? this.evidence,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      rceptNo: rceptNo ?? this.rceptNo,
      industryKey: industryKey is String? ? industryKey : this.industryKey,
      industryName: industryName is String? ? industryName : this.industryName,
      groupName: groupName is String? ? groupName : this.groupName,
      classificationBasis: classificationBasis is String?
          ? classificationBasis
          : this.classificationBasis,
    );
  }
}
