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

import '../../ontology/models/dart_section.dart' as _iy0bhrwp;

/// 기업이 가진 주요정보 항목 하나와 자료가 있는 사업연도.
abstract class DisclosureSectionInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DisclosureSectionInfo._({
    required this.section,
    required this.label,
    required this.group,
    required this.years,
  });

  factory DisclosureSectionInfo({
    required _iy0bhrwp.DartSection section,
    required String label,
    required String group,
    required List<int> years,
  }) = _DisclosureSectionInfoImpl;

  factory DisclosureSectionInfo.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DisclosureSectionInfo(
      section: _iy0bhrwp.DartSection.fromJson(
        (jsonSerialization['section'] as String),
      ),
      label: jsonSerialization['label'] as String,
      group: jsonSerialization['group'] as String,
      years: _i4yshtjp.Protocol().deserialize<List<int>>(
        jsonSerialization['years'],
      ),
    );
  }

  _iy0bhrwp.DartSection section;

  String label;

  String group;

  List<int> years;

  /// Returns a shallow copy of this [DisclosureSectionInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DisclosureSectionInfo copyWith({
    _iy0bhrwp.DartSection? section,
    String? label,
    String? group,
    List<int>? years,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureSectionInfo',
      'section': section.toJson(),
      'label': label,
      'group': group,
      'years': years.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DisclosureSectionInfo',
      'section': section.toJson(),
      'label': label,
      'group': group,
      'years': years.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DisclosureSectionInfoImpl extends DisclosureSectionInfo {
  _DisclosureSectionInfoImpl({
    required _iy0bhrwp.DartSection section,
    required String label,
    required String group,
    required List<int> years,
  }) : super._(
         section: section,
         label: label,
         group: group,
         years: years,
       );

  /// Returns a shallow copy of this [DisclosureSectionInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DisclosureSectionInfo copyWith({
    _iy0bhrwp.DartSection? section,
    String? label,
    String? group,
    List<int>? years,
  }) {
    return DisclosureSectionInfo(
      section: section ?? this.section,
      label: label ?? this.label,
      group: group ?? this.group,
      years: years ?? this.years.map((e0) => e0).toList(),
    );
  }
}
