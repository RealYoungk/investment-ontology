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
import '../../ontology/models/peer_signal.dart' as _i9d9glwe;

abstract class PeerProfile
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PeerProfile._({
    this.id,
    required this.documentId,
    required this.ruleVersion,
    required this.signals,
    required this.computedAt,
  });

  factory PeerProfile({
    int? id,
    required int documentId,
    required int ruleVersion,
    required List<_i9d9glwe.PeerSignal> signals,
    required DateTime computedAt,
  }) = _PeerProfileImpl;

  factory PeerProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return PeerProfile(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      ruleVersion: jsonSerialization['ruleVersion'] as int,
      signals: _ilkzeueu.Protocol().deserialize<List<_i9d9glwe.PeerSignal>>(
        jsonSerialization['signals'],
      ),
      computedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['computedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int documentId;

  int ruleVersion;

  List<_i9d9glwe.PeerSignal> signals;

  DateTime computedAt;

  /// Returns a shallow copy of this [PeerProfile]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PeerProfile copyWith({
    int? id,
    int? documentId,
    int? ruleVersion,
    List<_i9d9glwe.PeerSignal>? signals,
    DateTime? computedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PeerProfile',
      if (id != null) 'id': id,
      'documentId': documentId,
      'ruleVersion': ruleVersion,
      'signals': signals.toJson(valueToJson: (v) => v.toJson()),
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PeerProfile',
      if (id != null) 'id': id,
      'documentId': documentId,
      'ruleVersion': ruleVersion,
      'signals': signals.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PeerProfileImpl extends PeerProfile {
  _PeerProfileImpl({
    int? id,
    required int documentId,
    required int ruleVersion,
    required List<_i9d9glwe.PeerSignal> signals,
    required DateTime computedAt,
  }) : super._(
         id: id,
         documentId: documentId,
         ruleVersion: ruleVersion,
         signals: signals,
         computedAt: computedAt,
       );

  /// Returns a shallow copy of this [PeerProfile]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PeerProfile copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? ruleVersion,
    List<_i9d9glwe.PeerSignal>? signals,
    DateTime? computedAt,
  }) {
    return PeerProfile(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      signals: signals ?? this.signals.map((e0) => e0.copyWith()).toList(),
      computedAt: computedAt ?? this.computedAt,
    );
  }
}
