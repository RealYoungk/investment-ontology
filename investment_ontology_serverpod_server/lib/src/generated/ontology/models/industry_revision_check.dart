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

/// DART 업종코드가 어느 KSIC 개정 차수를 따르는지 판정한 결과.
abstract class IndustryRevisionCheck
    implements _is.SerializableModel, _is.ProtocolSerialization {
  IndustryRevisionCheck._({
    required this.revision,
    required this.distinctCodes,
    required this.unmatchedCodes,
    required this.evidenceCodes,
    required this.confirmed,
  });

  factory IndustryRevisionCheck({
    required String revision,
    required int distinctCodes,
    required List<String> unmatchedCodes,
    required List<String> evidenceCodes,
    required bool confirmed,
  }) = _IndustryRevisionCheckImpl;

  factory IndustryRevisionCheck.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return IndustryRevisionCheck(
      revision: jsonSerialization['revision'] as String,
      distinctCodes: jsonSerialization['distinctCodes'] as int,
      unmatchedCodes: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['unmatchedCodes'],
      ),
      evidenceCodes: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['evidenceCodes'],
      ),
      confirmed: _is.BoolJsonExtension.fromJson(jsonSerialization['confirmed']),
    );
  }

  /// 화면에 업종명을 보여줄 때 쓰는 차수 (예: "KSIC 11")
  String revision;

  /// 판정에 쓴 서로 다른 업종코드 수
  int distinctCodes;

  /// 이 차수 분류표에 없는 업종코드
  List<String> unmatchedCodes;

  /// 이 차수에만 있는 코드 중 실제로 쓰인 것 (판정 근거)
  List<String> evidenceCodes;

  /// 근거 코드로 차수를 확정했는지. false면 두 차수 모두 맞아서 최신 차수를 기본으로 씀
  bool confirmed;

  /// Returns a shallow copy of this [IndustryRevisionCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  IndustryRevisionCheck copyWith({
    String? revision,
    int? distinctCodes,
    List<String>? unmatchedCodes,
    List<String>? evidenceCodes,
    bool? confirmed,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndustryRevisionCheck',
      'revision': revision,
      'distinctCodes': distinctCodes,
      'unmatchedCodes': unmatchedCodes.toJson(),
      'evidenceCodes': evidenceCodes.toJson(),
      'confirmed': confirmed,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndustryRevisionCheck',
      'revision': revision,
      'distinctCodes': distinctCodes,
      'unmatchedCodes': unmatchedCodes.toJson(),
      'evidenceCodes': evidenceCodes.toJson(),
      'confirmed': confirmed,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _IndustryRevisionCheckImpl extends IndustryRevisionCheck {
  _IndustryRevisionCheckImpl({
    required String revision,
    required int distinctCodes,
    required List<String> unmatchedCodes,
    required List<String> evidenceCodes,
    required bool confirmed,
  }) : super._(
         revision: revision,
         distinctCodes: distinctCodes,
         unmatchedCodes: unmatchedCodes,
         evidenceCodes: evidenceCodes,
         confirmed: confirmed,
       );

  /// Returns a shallow copy of this [IndustryRevisionCheck]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  IndustryRevisionCheck copyWith({
    String? revision,
    int? distinctCodes,
    List<String>? unmatchedCodes,
    List<String>? evidenceCodes,
    bool? confirmed,
  }) {
    return IndustryRevisionCheck(
      revision: revision ?? this.revision,
      distinctCodes: distinctCodes ?? this.distinctCodes,
      unmatchedCodes:
          unmatchedCodes ?? this.unmatchedCodes.map((e0) => e0).toList(),
      evidenceCodes:
          evidenceCodes ?? this.evidenceCodes.map((e0) => e0).toList(),
      confirmed: confirmed ?? this.confirmed,
    );
  }
}
