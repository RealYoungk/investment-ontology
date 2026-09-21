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
import '../../ontology/models/document_fact.dart' as _i7vmevlg;

/// 검수 화면에 보여 줄 값 하나 (어느 기업의 무엇인지 포함).
abstract class FactItem
    implements _is.SerializableModel, _is.ProtocolSerialization {
  FactItem._({
    required this.fact,
    required this.corpCode,
    required this.companyName,
  });

  factory FactItem({
    required _i7vmevlg.DocumentFact fact,
    required String corpCode,
    required String companyName,
  }) = _FactItemImpl;

  factory FactItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return FactItem(
      fact: _i4yshtjp.Protocol().deserialize<_i7vmevlg.DocumentFact>(
        jsonSerialization['fact'],
      ),
      corpCode: jsonSerialization['corpCode'] as String,
      companyName: jsonSerialization['companyName'] as String,
    );
  }

  _i7vmevlg.DocumentFact fact;

  String corpCode;

  String companyName;

  /// Returns a shallow copy of this [FactItem]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FactItem copyWith({
    _i7vmevlg.DocumentFact? fact,
    String? corpCode,
    String? companyName,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FactItem',
      'fact': fact.toJson(),
      'corpCode': corpCode,
      'companyName': companyName,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FactItem',
      'fact': fact.toJsonForProtocol(),
      'corpCode': corpCode,
      'companyName': companyName,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _FactItemImpl extends FactItem {
  _FactItemImpl({
    required _i7vmevlg.DocumentFact fact,
    required String corpCode,
    required String companyName,
  }) : super._(
         fact: fact,
         corpCode: corpCode,
         companyName: companyName,
       );

  /// Returns a shallow copy of this [FactItem]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FactItem copyWith({
    _i7vmevlg.DocumentFact? fact,
    String? corpCode,
    String? companyName,
  }) {
    return FactItem(
      fact: fact ?? this.fact.copyWith(),
      corpCode: corpCode ?? this.corpCode,
      companyName: companyName ?? this.companyName,
    );
  }
}
