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

/// Validated immutable research feed batches. Ratios remain computed at read time.
abstract class ResearchSnapshot
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ResearchSnapshot._({
    this.id,
    required this.companyId,
    required this.kind,
    required this.provider,
    required this.payload,
    required this.sourceId,
    required this.digest,
    required this.createdAt,
  });

  factory ResearchSnapshot({
    int? id,
    required int companyId,
    required String kind,
    required String provider,
    required String payload,
    required int sourceId,
    required String digest,
    required DateTime createdAt,
  }) = _ResearchSnapshotImpl;

  factory ResearchSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return ResearchSnapshot(
      id: jsonSerialization['id'] as int?,
      companyId: jsonSerialization['companyId'] as int,
      kind: jsonSerialization['kind'] as String,
      provider: jsonSerialization['provider'] as String,
      payload: jsonSerialization['payload'] as String,
      sourceId: jsonSerialization['sourceId'] as int,
      digest: jsonSerialization['digest'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int companyId;

  String kind;

  String provider;

  String payload;

  int sourceId;

  String digest;

  DateTime createdAt;

  /// Returns a shallow copy of this [ResearchSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ResearchSnapshot copyWith({
    int? id,
    int? companyId,
    String? kind,
    String? provider,
    String? payload,
    int? sourceId,
    String? digest,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ResearchSnapshot',
      if (id != null) 'id': id,
      'companyId': companyId,
      'kind': kind,
      'provider': provider,
      'payload': payload,
      'sourceId': sourceId,
      'digest': digest,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ResearchSnapshot',
      if (id != null) 'id': id,
      'companyId': companyId,
      'kind': kind,
      'provider': provider,
      'payload': payload,
      'sourceId': sourceId,
      'digest': digest,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResearchSnapshotImpl extends ResearchSnapshot {
  _ResearchSnapshotImpl({
    int? id,
    required int companyId,
    required String kind,
    required String provider,
    required String payload,
    required int sourceId,
    required String digest,
    required DateTime createdAt,
  }) : super._(
         id: id,
         companyId: companyId,
         kind: kind,
         provider: provider,
         payload: payload,
         sourceId: sourceId,
         digest: digest,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ResearchSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ResearchSnapshot copyWith({
    Object? id = _Undefined,
    int? companyId,
    String? kind,
    String? provider,
    String? payload,
    int? sourceId,
    String? digest,
    DateTime? createdAt,
  }) {
    return ResearchSnapshot(
      id: id is int? ? id : this.id,
      companyId: companyId ?? this.companyId,
      kind: kind ?? this.kind,
      provider: provider ?? this.provider,
      payload: payload ?? this.payload,
      sourceId: sourceId ?? this.sourceId,
      digest: digest ?? this.digest,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
