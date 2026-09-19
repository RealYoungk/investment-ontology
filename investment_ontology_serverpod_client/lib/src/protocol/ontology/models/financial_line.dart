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
import '../../ontology/models/financial_statement_kind.dart' as _ibg3jdoa;

/// 화면에 쓰는 핵심 계정 값 하나. 원천 사실(FinancialFact)의 값을 그대로 옮긴다.
abstract class FinancialLine
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FinancialLine._({
    required this.key,
    required this.factId,
    required this.statement,
    this.accountId,
    required this.accountName,
    this.amount,
    this.cumulativeAmount,
  });

  factory FinancialLine({
    required String key,
    required int factId,
    required _ibg3jdoa.FinancialStatementKind statement,
    String? accountId,
    required String accountName,
    BigInt? amount,
    BigInt? cumulativeAmount,
  }) = _FinancialLineImpl;

  factory FinancialLine.fromJson(Map<String, dynamic> jsonSerialization) {
    return FinancialLine(
      key: jsonSerialization['key'] as String,
      factId: jsonSerialization['factId'] as int,
      statement: _ibg3jdoa.FinancialStatementKind.fromJson(
        (jsonSerialization['statement'] as String),
      ),
      accountId: jsonSerialization['accountId'] as String?,
      accountName: jsonSerialization['accountName'] as String,
      amount: jsonSerialization['amount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(jsonSerialization['amount']),
      cumulativeAmount: jsonSerialization['cumulativeAmount'] == null
          ? null
          : _isc.BigIntJsonExtension.fromJson(
              jsonSerialization['cumulativeAmount'],
            ),
    );
  }

  /// 화면 키 (revenue, operatingIncome, netIncome, ...)
  String key;

  int factId;

  _ibg3jdoa.FinancialStatementKind statement;

  String? accountId;

  String accountName;

  BigInt? amount;

  BigInt? cumulativeAmount;

  /// Returns a shallow copy of this [FinancialLine]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FinancialLine copyWith({
    String? key,
    int? factId,
    _ibg3jdoa.FinancialStatementKind? statement,
    String? accountId,
    String? accountName,
    BigInt? amount,
    BigInt? cumulativeAmount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FinancialLine',
      'key': key,
      'factId': factId,
      'statement': statement.toJson(),
      if (accountId != null) 'accountId': accountId,
      'accountName': accountName,
      if (amount != null) 'amount': amount?.toJson(),
      if (cumulativeAmount != null)
        'cumulativeAmount': cumulativeAmount?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FinancialLine',
      'key': key,
      'factId': factId,
      'statement': statement.toJson(),
      if (accountId != null) 'accountId': accountId,
      'accountName': accountName,
      if (amount != null) 'amount': amount?.toJson(),
      if (cumulativeAmount != null)
        'cumulativeAmount': cumulativeAmount?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FinancialLineImpl extends FinancialLine {
  _FinancialLineImpl({
    required String key,
    required int factId,
    required _ibg3jdoa.FinancialStatementKind statement,
    String? accountId,
    required String accountName,
    BigInt? amount,
    BigInt? cumulativeAmount,
  }) : super._(
         key: key,
         factId: factId,
         statement: statement,
         accountId: accountId,
         accountName: accountName,
         amount: amount,
         cumulativeAmount: cumulativeAmount,
       );

  /// Returns a shallow copy of this [FinancialLine]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FinancialLine copyWith({
    String? key,
    int? factId,
    _ibg3jdoa.FinancialStatementKind? statement,
    Object? accountId = _Undefined,
    String? accountName,
    Object? amount = _Undefined,
    Object? cumulativeAmount = _Undefined,
  }) {
    return FinancialLine(
      key: key ?? this.key,
      factId: factId ?? this.factId,
      statement: statement ?? this.statement,
      accountId: accountId is String? ? accountId : this.accountId,
      accountName: accountName ?? this.accountName,
      amount: amount is BigInt? ? amount : this.amount,
      cumulativeAmount: cumulativeAmount is BigInt?
          ? cumulativeAmount
          : this.cumulativeAmount,
    );
  }
}
