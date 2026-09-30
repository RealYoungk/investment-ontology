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

abstract class CompanyNewsItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CompanyNewsItem._({
    required this.title,
    required this.excerpt,
    required this.url,
    required this.publishedAt,
    required this.category,
    required this.publisher,
    required this.relatedUrls,
  });

  factory CompanyNewsItem({
    required String title,
    required String excerpt,
    required String url,
    required DateTime publishedAt,
    required String category,
    required String publisher,
    required List<String> relatedUrls,
  }) = _CompanyNewsItemImpl;

  factory CompanyNewsItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyNewsItem(
      title: jsonSerialization['title'] as String,
      excerpt: jsonSerialization['excerpt'] as String,
      url: jsonSerialization['url'] as String,
      publishedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['publishedAt'],
      ),
      category: jsonSerialization['category'] as String,
      publisher: jsonSerialization['publisher'] as String,
      relatedUrls: _ilkzeueu.Protocol().deserialize<List<String>>(
        jsonSerialization['relatedUrls'],
      ),
    );
  }

  String title;

  String excerpt;

  String url;

  DateTime publishedAt;

  String category;

  String publisher;

  List<String> relatedUrls;

  /// Returns a shallow copy of this [CompanyNewsItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CompanyNewsItem copyWith({
    String? title,
    String? excerpt,
    String? url,
    DateTime? publishedAt,
    String? category,
    String? publisher,
    List<String>? relatedUrls,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyNewsItem',
      'title': title,
      'excerpt': excerpt,
      'url': url,
      'publishedAt': publishedAt.toJson(),
      'category': category,
      'publisher': publisher,
      'relatedUrls': relatedUrls.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyNewsItem',
      'title': title,
      'excerpt': excerpt,
      'url': url,
      'publishedAt': publishedAt.toJson(),
      'category': category,
      'publisher': publisher,
      'relatedUrls': relatedUrls.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _CompanyNewsItemImpl extends CompanyNewsItem {
  _CompanyNewsItemImpl({
    required String title,
    required String excerpt,
    required String url,
    required DateTime publishedAt,
    required String category,
    required String publisher,
    required List<String> relatedUrls,
  }) : super._(
         title: title,
         excerpt: excerpt,
         url: url,
         publishedAt: publishedAt,
         category: category,
         publisher: publisher,
         relatedUrls: relatedUrls,
       );

  /// Returns a shallow copy of this [CompanyNewsItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CompanyNewsItem copyWith({
    String? title,
    String? excerpt,
    String? url,
    DateTime? publishedAt,
    String? category,
    String? publisher,
    List<String>? relatedUrls,
  }) {
    return CompanyNewsItem(
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      url: url ?? this.url,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
      publisher: publisher ?? this.publisher,
      relatedUrls: relatedUrls ?? this.relatedUrls.map((e0) => e0).toList(),
    );
  }
}
