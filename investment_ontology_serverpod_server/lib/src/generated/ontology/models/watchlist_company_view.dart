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
import 'package:serverpod/serverpod.dart' as _is;

abstract class WatchlistCompanyView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WatchlistCompanyView._({
    required this.corpCode,
    required this.name,
    this.stockCode,
    required this.muted,
    required this.monitoringReady,
    required this.active,
    required this.unreadCount,
  });

  factory WatchlistCompanyView({
    required String corpCode,
    required String name,
    String? stockCode,
    required bool muted,
    required bool monitoringReady,
    required bool active,
    required int unreadCount,
  }) = _WatchlistCompanyViewImpl;

  factory WatchlistCompanyView.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WatchlistCompanyView(
      corpCode: jsonSerialization['corpCode'] as String,
      name: jsonSerialization['name'] as String,
      stockCode: jsonSerialization['stockCode'] as String?,
      muted: _is.BoolJsonExtension.fromJson(jsonSerialization['muted']),
      monitoringReady: _is.BoolJsonExtension.fromJson(
        jsonSerialization['monitoringReady'],
      ),
      active: _is.BoolJsonExtension.fromJson(jsonSerialization['active']),
      unreadCount: jsonSerialization['unreadCount'] as int,
    );
  }

  String corpCode;

  String name;

  String? stockCode;

  bool muted;

  bool monitoringReady;

  bool active;

  int unreadCount;

  /// Returns a shallow copy of this [WatchlistCompanyView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WatchlistCompanyView copyWith({
    String? corpCode,
    String? name,
    String? stockCode,
    bool? muted,
    bool? monitoringReady,
    bool? active,
    int? unreadCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchlistCompanyView',
      'corpCode': corpCode,
      'name': name,
      if (stockCode != null) 'stockCode': stockCode,
      'muted': muted,
      'monitoringReady': monitoringReady,
      'active': active,
      'unreadCount': unreadCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WatchlistCompanyView',
      'corpCode': corpCode,
      'name': name,
      if (stockCode != null) 'stockCode': stockCode,
      'muted': muted,
      'monitoringReady': monitoringReady,
      'active': active,
      'unreadCount': unreadCount,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchlistCompanyViewImpl extends WatchlistCompanyView {
  _WatchlistCompanyViewImpl({
    required String corpCode,
    required String name,
    String? stockCode,
    required bool muted,
    required bool monitoringReady,
    required bool active,
    required int unreadCount,
  }) : super._(
         corpCode: corpCode,
         name: name,
         stockCode: stockCode,
         muted: muted,
         monitoringReady: monitoringReady,
         active: active,
         unreadCount: unreadCount,
       );

  /// Returns a shallow copy of this [WatchlistCompanyView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WatchlistCompanyView copyWith({
    String? corpCode,
    String? name,
    Object? stockCode = _Undefined,
    bool? muted,
    bool? monitoringReady,
    bool? active,
    int? unreadCount,
  }) {
    return WatchlistCompanyView(
      corpCode: corpCode ?? this.corpCode,
      name: name ?? this.name,
      stockCode: stockCode is String? ? stockCode : this.stockCode,
      muted: muted ?? this.muted,
      monitoringReady: monitoringReady ?? this.monitoringReady,
      active: active ?? this.active,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
