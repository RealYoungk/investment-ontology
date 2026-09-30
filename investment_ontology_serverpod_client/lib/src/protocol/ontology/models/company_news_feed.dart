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
import '../../ontology/models/company_news_item.dart' as _izok16oh;

abstract class CompanyNewsFeed
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CompanyNewsFeed._({
    required this.items,
    required this.fetchedAt,
    required this.newsStatus,
    required this.filingStatus,
  });

  factory CompanyNewsFeed({
    required List<_izok16oh.CompanyNewsItem> items,
    required DateTime fetchedAt,
    required String newsStatus,
    required String filingStatus,
  }) = _CompanyNewsFeedImpl;

  factory CompanyNewsFeed.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyNewsFeed(
      items: _ilkzeueu.Protocol().deserialize<List<_izok16oh.CompanyNewsItem>>(
        jsonSerialization['items'],
      ),
      fetchedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
      newsStatus: jsonSerialization['newsStatus'] as String,
      filingStatus: jsonSerialization['filingStatus'] as String,
    );
  }

  List<_izok16oh.CompanyNewsItem> items;

  DateTime fetchedAt;

  String newsStatus;

  String filingStatus;

  /// Returns a shallow copy of this [CompanyNewsFeed]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CompanyNewsFeed copyWith({
    List<_izok16oh.CompanyNewsItem>? items,
    DateTime? fetchedAt,
    String? newsStatus,
    String? filingStatus,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyNewsFeed',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'fetchedAt': fetchedAt.toJson(),
      'newsStatus': newsStatus,
      'filingStatus': filingStatus,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyNewsFeed',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'fetchedAt': fetchedAt.toJson(),
      'newsStatus': newsStatus,
      'filingStatus': filingStatus,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _CompanyNewsFeedImpl extends CompanyNewsFeed {
  _CompanyNewsFeedImpl({
    required List<_izok16oh.CompanyNewsItem> items,
    required DateTime fetchedAt,
    required String newsStatus,
    required String filingStatus,
  }) : super._(
         items: items,
         fetchedAt: fetchedAt,
         newsStatus: newsStatus,
         filingStatus: filingStatus,
       );

  /// Returns a shallow copy of this [CompanyNewsFeed]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CompanyNewsFeed copyWith({
    List<_izok16oh.CompanyNewsItem>? items,
    DateTime? fetchedAt,
    String? newsStatus,
    String? filingStatus,
  }) {
    return CompanyNewsFeed(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      fetchedAt: fetchedAt ?? this.fetchedAt,
      newsStatus: newsStatus ?? this.newsStatus,
      filingStatus: filingStatus ?? this.filingStatus,
    );
  }
}
