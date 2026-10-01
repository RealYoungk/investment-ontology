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

abstract class WatchlistUpdateView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WatchlistUpdateView._({
    required this.noticeId,
    required this.corpCode,
    required this.companyName,
    required this.title,
    required this.url,
    required this.publishedAt,
    required this.discoveredAt,
    required this.read,
  });

  factory WatchlistUpdateView({
    required int noticeId,
    required String corpCode,
    required String companyName,
    required String title,
    required String url,
    required DateTime publishedAt,
    required DateTime discoveredAt,
    required bool read,
  }) = _WatchlistUpdateViewImpl;

  factory WatchlistUpdateView.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchlistUpdateView(
      noticeId: jsonSerialization['noticeId'] as int,
      corpCode: jsonSerialization['corpCode'] as String,
      companyName: jsonSerialization['companyName'] as String,
      title: jsonSerialization['title'] as String,
      url: jsonSerialization['url'] as String,
      publishedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['publishedAt'],
      ),
      discoveredAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['discoveredAt'],
      ),
      read: _isc.BoolJsonExtension.fromJson(jsonSerialization['read']),
    );
  }

  int noticeId;

  String corpCode;

  String companyName;

  String title;

  String url;

  DateTime publishedAt;

  DateTime discoveredAt;

  bool read;

  /// Returns a shallow copy of this [WatchlistUpdateView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WatchlistUpdateView copyWith({
    int? noticeId,
    String? corpCode,
    String? companyName,
    String? title,
    String? url,
    DateTime? publishedAt,
    DateTime? discoveredAt,
    bool? read,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchlistUpdateView',
      'noticeId': noticeId,
      'corpCode': corpCode,
      'companyName': companyName,
      'title': title,
      'url': url,
      'publishedAt': publishedAt.toJson(),
      'discoveredAt': discoveredAt.toJson(),
      'read': read,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WatchlistUpdateView',
      'noticeId': noticeId,
      'corpCode': corpCode,
      'companyName': companyName,
      'title': title,
      'url': url,
      'publishedAt': publishedAt.toJson(),
      'discoveredAt': discoveredAt.toJson(),
      'read': read,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _WatchlistUpdateViewImpl extends WatchlistUpdateView {
  _WatchlistUpdateViewImpl({
    required int noticeId,
    required String corpCode,
    required String companyName,
    required String title,
    required String url,
    required DateTime publishedAt,
    required DateTime discoveredAt,
    required bool read,
  }) : super._(
         noticeId: noticeId,
         corpCode: corpCode,
         companyName: companyName,
         title: title,
         url: url,
         publishedAt: publishedAt,
         discoveredAt: discoveredAt,
         read: read,
       );

  /// Returns a shallow copy of this [WatchlistUpdateView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WatchlistUpdateView copyWith({
    int? noticeId,
    String? corpCode,
    String? companyName,
    String? title,
    String? url,
    DateTime? publishedAt,
    DateTime? discoveredAt,
    bool? read,
  }) {
    return WatchlistUpdateView(
      noticeId: noticeId ?? this.noticeId,
      corpCode: corpCode ?? this.corpCode,
      companyName: companyName ?? this.companyName,
      title: title ?? this.title,
      url: url ?? this.url,
      publishedAt: publishedAt ?? this.publishedAt,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      read: read ?? this.read,
    );
  }
}
