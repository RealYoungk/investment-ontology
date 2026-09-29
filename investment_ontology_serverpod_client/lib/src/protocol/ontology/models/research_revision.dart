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

abstract class ResearchRevision
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ResearchRevision._({
    this.id,
    required this.articleId,
    required this.version,
    required this.title,
    required this.summary,
    required this.ticker,
    required this.market,
    required this.content,
    required this.format,
    required this.searchText,
    required this.dataAsOf,
    this.publishedAt,
    required this.createdAt,
    required this.note,
    required this.legacy,
  });

  factory ResearchRevision({
    int? id,
    required int articleId,
    required int version,
    required String title,
    required String summary,
    required String ticker,
    required String market,
    required String content,
    required String format,
    required String searchText,
    required DateTime dataAsOf,
    DateTime? publishedAt,
    required DateTime createdAt,
    required String note,
    required bool legacy,
  }) = _ResearchRevisionImpl;

  factory ResearchRevision.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchRevision(
      id: jsonSerialization['id'] as int?,
      articleId: jsonSerialization['articleId'] as int,
      version: jsonSerialization['version'] as int,
      title: jsonSerialization['title'] as String,
      summary: jsonSerialization['summary'] as String,
      ticker: jsonSerialization['ticker'] as String,
      market: jsonSerialization['market'] as String,
      content: jsonSerialization['content'] as String,
      format: jsonSerialization['format'] as String,
      searchText: jsonSerialization['searchText'] as String,
      dataAsOf: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['dataAsOf'],
      ),
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      note: jsonSerialization['note'] as String,
      legacy: _isc.BoolJsonExtension.fromJson(jsonSerialization['legacy']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int articleId;

  int version;

  String title;

  String summary;

  String ticker;

  String market;

  String content;

  String format;

  String searchText;

  DateTime dataAsOf;

  DateTime? publishedAt;

  DateTime createdAt;

  String note;

  bool legacy;

  /// Returns a shallow copy of this [ResearchRevision]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ResearchRevision copyWith({
    int? id,
    int? articleId,
    int? version,
    String? title,
    String? summary,
    String? ticker,
    String? market,
    String? content,
    String? format,
    String? searchText,
    DateTime? dataAsOf,
    DateTime? publishedAt,
    DateTime? createdAt,
    String? note,
    bool? legacy,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchRevision',
      if (id != null) 'id': id,
      'articleId': articleId,
      'version': version,
      'title': title,
      'summary': summary,
      'ticker': ticker,
      'market': market,
      'content': content,
      'format': format,
      'searchText': searchText,
      'dataAsOf': dataAsOf.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'note': note,
      'legacy': legacy,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchRevision',
      if (id != null) 'id': id,
      'articleId': articleId,
      'version': version,
      'title': title,
      'summary': summary,
      'ticker': ticker,
      'market': market,
      'content': content,
      'format': format,
      'searchText': searchText,
      'dataAsOf': dataAsOf.toJson(),
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'note': note,
      'legacy': legacy,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchRevisionImpl extends ResearchRevision {
  _ResearchRevisionImpl({
    int? id,
    required int articleId,
    required int version,
    required String title,
    required String summary,
    required String ticker,
    required String market,
    required String content,
    required String format,
    required String searchText,
    required DateTime dataAsOf,
    DateTime? publishedAt,
    required DateTime createdAt,
    required String note,
    required bool legacy,
  }) : super._(
         id: id,
         articleId: articleId,
         version: version,
         title: title,
         summary: summary,
         ticker: ticker,
         market: market,
         content: content,
         format: format,
         searchText: searchText,
         dataAsOf: dataAsOf,
         publishedAt: publishedAt,
         createdAt: createdAt,
         note: note,
         legacy: legacy,
       );

  /// Returns a shallow copy of this [ResearchRevision]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ResearchRevision copyWith({
    Object? id = _Undefined,
    int? articleId,
    int? version,
    String? title,
    String? summary,
    String? ticker,
    String? market,
    String? content,
    String? format,
    String? searchText,
    DateTime? dataAsOf,
    Object? publishedAt = _Undefined,
    DateTime? createdAt,
    String? note,
    bool? legacy,
  }) {
    return ResearchRevision(
      id: id is int? ? id : this.id,
      articleId: articleId ?? this.articleId,
      version: version ?? this.version,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      ticker: ticker ?? this.ticker,
      market: market ?? this.market,
      content: content ?? this.content,
      format: format ?? this.format,
      searchText: searchText ?? this.searchText,
      dataAsOf: dataAsOf ?? this.dataAsOf,
      publishedAt: publishedAt is DateTime? ? publishedAt : this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      legacy: legacy ?? this.legacy,
    );
  }
}
