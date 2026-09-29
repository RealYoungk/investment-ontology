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

abstract class ResearchArticle
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ResearchArticle._({
    this.id,
    required this.slug,
    required this.latestVersion,
    this.publishedVersion,
  });

  factory ResearchArticle({
    int? id,
    required String slug,
    required int latestVersion,
    int? publishedVersion,
  }) = _ResearchArticleImpl;

  factory ResearchArticle.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchArticle(
      id: jsonSerialization['id'] as int?,
      slug: jsonSerialization['slug'] as String,
      latestVersion: jsonSerialization['latestVersion'] as int,
      publishedVersion: jsonSerialization['publishedVersion'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String slug;

  int latestVersion;

  int? publishedVersion;

  /// Returns a shallow copy of this [ResearchArticle]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ResearchArticle copyWith({
    int? id,
    String? slug,
    int? latestVersion,
    int? publishedVersion,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchArticle',
      if (id != null) 'id': id,
      'slug': slug,
      'latestVersion': latestVersion,
      if (publishedVersion != null) 'publishedVersion': publishedVersion,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchArticle',
      if (id != null) 'id': id,
      'slug': slug,
      'latestVersion': latestVersion,
      if (publishedVersion != null) 'publishedVersion': publishedVersion,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchArticleImpl extends ResearchArticle {
  _ResearchArticleImpl({
    int? id,
    required String slug,
    required int latestVersion,
    int? publishedVersion,
  }) : super._(
         id: id,
         slug: slug,
         latestVersion: latestVersion,
         publishedVersion: publishedVersion,
       );

  /// Returns a shallow copy of this [ResearchArticle]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ResearchArticle copyWith({
    Object? id = _Undefined,
    String? slug,
    int? latestVersion,
    Object? publishedVersion = _Undefined,
  }) {
    return ResearchArticle(
      id: id is int? ? id : this.id,
      slug: slug ?? this.slug,
      latestVersion: latestVersion ?? this.latestVersion,
      publishedVersion: publishedVersion is int?
          ? publishedVersion
          : this.publishedVersion,
    );
  }
}
