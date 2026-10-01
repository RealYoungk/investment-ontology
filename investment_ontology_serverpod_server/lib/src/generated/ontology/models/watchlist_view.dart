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
import '../../ontology/models/watchlist_company_view.dart' as _in75d37p;
import '../../ontology/models/watchlist_update_view.dart' as _i906i6r3;

abstract class WatchlistView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WatchlistView._({
    required this.companies,
    required this.updates,
    required this.limit,
    required this.paid,
    required this.scanStatus,
    required this.workerEnabled,
    this.lastCheckedAt,
    required this.pushConfigured,
    this.vapidPublicKey,
  });

  factory WatchlistView({
    required List<_in75d37p.WatchlistCompanyView> companies,
    required List<_i906i6r3.WatchlistUpdateView> updates,
    required int limit,
    required bool paid,
    required String scanStatus,
    required bool workerEnabled,
    DateTime? lastCheckedAt,
    required bool pushConfigured,
    String? vapidPublicKey,
  }) = _WatchlistViewImpl;

  factory WatchlistView.fromJson(Map<String, dynamic> jsonSerialization) {
    return WatchlistView(
      companies: _i4yshtjp.Protocol()
          .deserialize<List<_in75d37p.WatchlistCompanyView>>(
            jsonSerialization['companies'],
          ),
      updates: _i4yshtjp.Protocol()
          .deserialize<List<_i906i6r3.WatchlistUpdateView>>(
            jsonSerialization['updates'],
          ),
      limit: jsonSerialization['limit'] as int,
      paid: _is.BoolJsonExtension.fromJson(jsonSerialization['paid']),
      scanStatus: jsonSerialization['scanStatus'] as String,
      workerEnabled: _is.BoolJsonExtension.fromJson(
        jsonSerialization['workerEnabled'],
      ),
      lastCheckedAt: jsonSerialization['lastCheckedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastCheckedAt'],
            ),
      pushConfigured: _is.BoolJsonExtension.fromJson(
        jsonSerialization['pushConfigured'],
      ),
      vapidPublicKey: jsonSerialization['vapidPublicKey'] as String?,
    );
  }

  List<_in75d37p.WatchlistCompanyView> companies;

  List<_i906i6r3.WatchlistUpdateView> updates;

  int limit;

  bool paid;

  String scanStatus;

  bool workerEnabled;

  DateTime? lastCheckedAt;

  bool pushConfigured;

  String? vapidPublicKey;

  /// Returns a shallow copy of this [WatchlistView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WatchlistView copyWith({
    List<_in75d37p.WatchlistCompanyView>? companies,
    List<_i906i6r3.WatchlistUpdateView>? updates,
    int? limit,
    bool? paid,
    String? scanStatus,
    bool? workerEnabled,
    DateTime? lastCheckedAt,
    bool? pushConfigured,
    String? vapidPublicKey,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WatchlistView',
      'companies': companies.toJson(valueToJson: (v) => v.toJson()),
      'updates': updates.toJson(valueToJson: (v) => v.toJson()),
      'limit': limit,
      'paid': paid,
      'scanStatus': scanStatus,
      'workerEnabled': workerEnabled,
      if (lastCheckedAt != null) 'lastCheckedAt': lastCheckedAt?.toJson(),
      'pushConfigured': pushConfigured,
      if (vapidPublicKey != null) 'vapidPublicKey': vapidPublicKey,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WatchlistView',
      'companies': companies.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'updates': updates.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'limit': limit,
      'paid': paid,
      'scanStatus': scanStatus,
      'workerEnabled': workerEnabled,
      if (lastCheckedAt != null) 'lastCheckedAt': lastCheckedAt?.toJson(),
      'pushConfigured': pushConfigured,
      if (vapidPublicKey != null) 'vapidPublicKey': vapidPublicKey,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WatchlistViewImpl extends WatchlistView {
  _WatchlistViewImpl({
    required List<_in75d37p.WatchlistCompanyView> companies,
    required List<_i906i6r3.WatchlistUpdateView> updates,
    required int limit,
    required bool paid,
    required String scanStatus,
    required bool workerEnabled,
    DateTime? lastCheckedAt,
    required bool pushConfigured,
    String? vapidPublicKey,
  }) : super._(
         companies: companies,
         updates: updates,
         limit: limit,
         paid: paid,
         scanStatus: scanStatus,
         workerEnabled: workerEnabled,
         lastCheckedAt: lastCheckedAt,
         pushConfigured: pushConfigured,
         vapidPublicKey: vapidPublicKey,
       );

  /// Returns a shallow copy of this [WatchlistView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WatchlistView copyWith({
    List<_in75d37p.WatchlistCompanyView>? companies,
    List<_i906i6r3.WatchlistUpdateView>? updates,
    int? limit,
    bool? paid,
    String? scanStatus,
    bool? workerEnabled,
    Object? lastCheckedAt = _Undefined,
    bool? pushConfigured,
    Object? vapidPublicKey = _Undefined,
  }) {
    return WatchlistView(
      companies:
          companies ?? this.companies.map((e0) => e0.copyWith()).toList(),
      updates: updates ?? this.updates.map((e0) => e0.copyWith()).toList(),
      limit: limit ?? this.limit,
      paid: paid ?? this.paid,
      scanStatus: scanStatus ?? this.scanStatus,
      workerEnabled: workerEnabled ?? this.workerEnabled,
      lastCheckedAt: lastCheckedAt is DateTime?
          ? lastCheckedAt
          : this.lastCheckedAt,
      pushConfigured: pushConfigured ?? this.pushConfigured,
      vapidPublicKey: vapidPublicKey is String?
          ? vapidPublicKey
          : this.vapidPublicKey,
    );
  }
}
