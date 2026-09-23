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
import '../../ontology/models/research_article.dart' as _iev4u9zs;
import '../../ontology/models/research_revision.dart' as _i0ihc5oa;

abstract class ResearchEntry
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ResearchEntry._({
    required this.article,
    required this.revision,
    this.corpCode,
    required this.saved,
  });

  factory ResearchEntry({
    required _iev4u9zs.ResearchArticle article,
    required _i0ihc5oa.ResearchRevision revision,
    String? corpCode,
    required bool saved,
  }) = _ResearchEntryImpl;

  factory ResearchEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchEntry(
      article: _i4yshtjp.Protocol().deserialize<_iev4u9zs.ResearchArticle>(
        jsonSerialization['article'],
      ),
      revision: _i4yshtjp.Protocol().deserialize<_i0ihc5oa.ResearchRevision>(
        jsonSerialization['revision'],
      ),
      corpCode: jsonSerialization['corpCode'] as String?,
      saved: _is.BoolJsonExtension.fromJson(jsonSerialization['saved']),
    );
  }

  _iev4u9zs.ResearchArticle article;

  _i0ihc5oa.ResearchRevision revision;

  String? corpCode;

  bool saved;

  /// Returns a shallow copy of this [ResearchEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ResearchEntry copyWith({
    _iev4u9zs.ResearchArticle? article,
    _i0ihc5oa.ResearchRevision? revision,
    String? corpCode,
    bool? saved,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchEntry',
      'article': article.toJson(),
      'revision': revision.toJson(),
      if (corpCode != null) 'corpCode': corpCode,
      'saved': saved,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchEntry',
      'article': article.toJsonForProtocol(),
      'revision': revision.toJsonForProtocol(),
      if (corpCode != null) 'corpCode': corpCode,
      'saved': saved,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchEntryImpl extends ResearchEntry {
  _ResearchEntryImpl({
    required _iev4u9zs.ResearchArticle article,
    required _i0ihc5oa.ResearchRevision revision,
    String? corpCode,
    required bool saved,
  }) : super._(
         article: article,
         revision: revision,
         corpCode: corpCode,
         saved: saved,
       );

  /// Returns a shallow copy of this [ResearchEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ResearchEntry copyWith({
    _iev4u9zs.ResearchArticle? article,
    _i0ihc5oa.ResearchRevision? revision,
    Object? corpCode = _Undefined,
    bool? saved,
  }) {
    return ResearchEntry(
      article: article ?? this.article.copyWith(),
      revision: revision ?? this.revision.copyWith(),
      corpCode: corpCode is String? ? corpCode : this.corpCode,
      saved: saved ?? this.saved,
    );
  }
}
