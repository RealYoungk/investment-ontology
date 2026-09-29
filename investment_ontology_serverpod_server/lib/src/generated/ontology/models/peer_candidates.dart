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
import '../../ontology/models/peer_candidate.dart' as _icve8tkt;
import '../../ontology/models/peer_signal.dart' as _i9d9glwe;

abstract class PeerCandidates
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PeerCandidates._({
    required this.status,
    required this.anchorName,
    required this.signals,
    this.bsnsYear,
    this.rceptNo,
    this.computedAt,
    required this.ruleVersion,
    required this.items,
  });

  factory PeerCandidates({
    required String status,
    required String anchorName,
    required List<_i9d9glwe.PeerSignal> signals,
    int? bsnsYear,
    String? rceptNo,
    DateTime? computedAt,
    required int ruleVersion,
    required List<_icve8tkt.PeerCandidate> items,
  }) = _PeerCandidatesImpl;

  factory PeerCandidates.fromJson(Map<String, dynamic> jsonSerialization) {
    return PeerCandidates(
      status: jsonSerialization['status'] as String,
      anchorName: jsonSerialization['anchorName'] as String,
      signals: _i4yshtjp.Protocol().deserialize<List<_i9d9glwe.PeerSignal>>(
        jsonSerialization['signals'],
      ),
      bsnsYear: jsonSerialization['bsnsYear'] as int?,
      rceptNo: jsonSerialization['rceptNo'] as String?,
      computedAt: jsonSerialization['computedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['computedAt']),
      ruleVersion: jsonSerialization['ruleVersion'] as int,
      items: _i4yshtjp.Protocol().deserialize<List<_icve8tkt.PeerCandidate>>(
        jsonSerialization['items'],
      ),
    );
  }

  String status;

  String anchorName;

  List<_i9d9glwe.PeerSignal> signals;

  int? bsnsYear;

  String? rceptNo;

  DateTime? computedAt;

  int ruleVersion;

  List<_icve8tkt.PeerCandidate> items;

  /// Returns a shallow copy of this [PeerCandidates]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PeerCandidates copyWith({
    String? status,
    String? anchorName,
    List<_i9d9glwe.PeerSignal>? signals,
    int? bsnsYear,
    String? rceptNo,
    DateTime? computedAt,
    int? ruleVersion,
    List<_icve8tkt.PeerCandidate>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PeerCandidates',
      'status': status,
      'anchorName': anchorName,
      'signals': signals.toJson(valueToJson: (v) => v.toJson()),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (rceptNo != null) 'rceptNo': rceptNo,
      if (computedAt != null) 'computedAt': computedAt?.toJson(),
      'ruleVersion': ruleVersion,
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PeerCandidates',
      'status': status,
      'anchorName': anchorName,
      'signals': signals.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (rceptNo != null) 'rceptNo': rceptNo,
      if (computedAt != null) 'computedAt': computedAt?.toJson(),
      'ruleVersion': ruleVersion,
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PeerCandidatesImpl extends PeerCandidates {
  _PeerCandidatesImpl({
    required String status,
    required String anchorName,
    required List<_i9d9glwe.PeerSignal> signals,
    int? bsnsYear,
    String? rceptNo,
    DateTime? computedAt,
    required int ruleVersion,
    required List<_icve8tkt.PeerCandidate> items,
  }) : super._(
         status: status,
         anchorName: anchorName,
         signals: signals,
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         computedAt: computedAt,
         ruleVersion: ruleVersion,
         items: items,
       );

  /// Returns a shallow copy of this [PeerCandidates]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PeerCandidates copyWith({
    String? status,
    String? anchorName,
    List<_i9d9glwe.PeerSignal>? signals,
    Object? bsnsYear = _Undefined,
    Object? rceptNo = _Undefined,
    Object? computedAt = _Undefined,
    int? ruleVersion,
    List<_icve8tkt.PeerCandidate>? items,
  }) {
    return PeerCandidates(
      status: status ?? this.status,
      anchorName: anchorName ?? this.anchorName,
      signals: signals ?? this.signals.map((e0) => e0.copyWith()).toList(),
      bsnsYear: bsnsYear is int? ? bsnsYear : this.bsnsYear,
      rceptNo: rceptNo is String? ? rceptNo : this.rceptNo,
      computedAt: computedAt is DateTime? ? computedAt : this.computedAt,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
