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

import '../../ontology/models/business_section.dart' as _i5knl8hb;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 기업 상세의 사업의 내용 탭.
abstract class BusinessContent
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BusinessContent._({
    required this.bsnsYear,
    required this.rceptNo,
    required this.title,
    required this.sections,
    required this.charCount,
    required this.years,
    this.source,
  });

  factory BusinessContent({
    required int bsnsYear,
    required String rceptNo,
    required String title,
    required List<_i5knl8hb.BusinessSection> sections,
    required int charCount,
    required List<int> years,
    _i5ra8lvy.Source? source,
  }) = _BusinessContentImpl;

  factory BusinessContent.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessContent(
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      title: jsonSerialization['title'] as String,
      sections: _i4yshtjp.Protocol()
          .deserialize<List<_i5knl8hb.BusinessSection>>(
            jsonSerialization['sections'],
          ),
      charCount: jsonSerialization['charCount'] as int,
      years: _i4yshtjp.Protocol().deserialize<List<int>>(
        jsonSerialization['years'],
      ),
      source: jsonSerialization['source'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
    );
  }

  int bsnsYear;

  String rceptNo;

  String title;

  List<_i5knl8hb.BusinessSection> sections;

  int charCount;

  List<int> years;

  _i5ra8lvy.Source? source;

  /// Returns a shallow copy of this [BusinessContent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessContent copyWith({
    int? bsnsYear,
    String? rceptNo,
    String? title,
    List<_i5knl8hb.BusinessSection>? sections,
    int? charCount,
    List<int>? years,
    _i5ra8lvy.Source? source,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessContent',
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      'title': title,
      'sections': sections.toJson(valueToJson: (v) => v.toJson()),
      'charCount': charCount,
      'years': years.toJson(),
      if (source != null) 'source': source?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessContent',
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      'title': title,
      'sections': sections.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'charCount': charCount,
      'years': years.toJson(),
      if (source != null) 'source': source?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessContentImpl extends BusinessContent {
  _BusinessContentImpl({
    required int bsnsYear,
    required String rceptNo,
    required String title,
    required List<_i5knl8hb.BusinessSection> sections,
    required int charCount,
    required List<int> years,
    _i5ra8lvy.Source? source,
  }) : super._(
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         title: title,
         sections: sections,
         charCount: charCount,
         years: years,
         source: source,
       );

  /// Returns a shallow copy of this [BusinessContent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessContent copyWith({
    int? bsnsYear,
    String? rceptNo,
    String? title,
    List<_i5knl8hb.BusinessSection>? sections,
    int? charCount,
    List<int>? years,
    Object? source = _Undefined,
  }) {
    return BusinessContent(
      bsnsYear: bsnsYear ?? this.bsnsYear,
      rceptNo: rceptNo ?? this.rceptNo,
      title: title ?? this.title,
      sections: sections ?? this.sections.map((e0) => e0.copyWith()).toList(),
      charCount: charCount ?? this.charCount,
      years: years ?? this.years.map((e0) => e0).toList(),
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
    );
  }
}
