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
import 'package:investment_ontology_serverpod_client/src/protocol/protocol.dart'
    as _ilkzeueu;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../ontology/models/business_section.dart' as _i5knl8hb;
import '../../ontology/models/business_table_insight.dart' as _ianehp6p;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 기업 상세의 사업의 내용 탭.
abstract class BusinessContent
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BusinessContent._({
    required this.bsnsYear,
    required this.rceptNo,
    required this.title,
    required this.sections,
    required this.charCount,
    required this.years,
    this.source,
    this.tableInsights,
  });

  factory BusinessContent({
    required int bsnsYear,
    required String rceptNo,
    required String title,
    required List<_i5knl8hb.BusinessSection> sections,
    required int charCount,
    required List<int> years,
    _i5ra8lvy.Source? source,
    List<_ianehp6p.BusinessTableInsight>? tableInsights,
  }) = _BusinessContentImpl;

  factory BusinessContent.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessContent(
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      title: jsonSerialization['title'] as String,
      sections: _ilkzeueu.Protocol()
          .deserialize<List<_i5knl8hb.BusinessSection>>(
            jsonSerialization['sections'],
          ),
      charCount: jsonSerialization['charCount'] as int,
      years: _ilkzeueu.Protocol().deserialize<List<int>>(
        jsonSerialization['years'],
      ),
      source: jsonSerialization['source'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
      tableInsights: jsonSerialization['tableInsights'] == null
          ? null
          : _ilkzeueu.Protocol()
                .deserialize<List<_ianehp6p.BusinessTableInsight>>(
                  jsonSerialization['tableInsights'],
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

  /// 추가 표 규칙으로 읽은 원재료·판매경로·계획·계약·위험 정보. 이전 서버 응답과 호환.
  List<_ianehp6p.BusinessTableInsight>? tableInsights;

  /// Returns a shallow copy of this [BusinessContent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BusinessContent copyWith({
    int? bsnsYear,
    String? rceptNo,
    String? title,
    List<_i5knl8hb.BusinessSection>? sections,
    int? charCount,
    List<int>? years,
    _i5ra8lvy.Source? source,
    List<_ianehp6p.BusinessTableInsight>? tableInsights,
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
      if (tableInsights != null)
        'tableInsights': tableInsights?.toJson(valueToJson: (v) => v.toJson()),
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
      if (tableInsights != null)
        'tableInsights': tableInsights?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
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
    List<_ianehp6p.BusinessTableInsight>? tableInsights,
  }) : super._(
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         title: title,
         sections: sections,
         charCount: charCount,
         years: years,
         source: source,
         tableInsights: tableInsights,
       );

  /// Returns a shallow copy of this [BusinessContent]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BusinessContent copyWith({
    int? bsnsYear,
    String? rceptNo,
    String? title,
    List<_i5knl8hb.BusinessSection>? sections,
    int? charCount,
    List<int>? years,
    Object? source = _Undefined,
    Object? tableInsights = _Undefined,
  }) {
    return BusinessContent(
      bsnsYear: bsnsYear ?? this.bsnsYear,
      rceptNo: rceptNo ?? this.rceptNo,
      title: title ?? this.title,
      sections: sections ?? this.sections.map((e0) => e0.copyWith()).toList(),
      charCount: charCount ?? this.charCount,
      years: years ?? this.years.map((e0) => e0).toList(),
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
      tableInsights: tableInsights is List<_ianehp6p.BusinessTableInsight>?
          ? tableInsights
          : this.tableInsights?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
