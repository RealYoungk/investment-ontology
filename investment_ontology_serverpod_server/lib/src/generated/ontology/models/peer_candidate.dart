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
import '../../ontology/models/peer_signal.dart' as _i9d9glwe;

abstract class PeerCandidate
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PeerCandidate._({
    required this.corpCode,
    required this.name,
    required this.tier,
    required this.reasons,
    required this.differences,
    required this.signals,
    required this.bsnsYear,
    required this.rceptNo,
  });

  factory PeerCandidate({
    required String corpCode,
    required String name,
    required String tier,
    required List<String> reasons,
    required List<String> differences,
    required List<_i9d9glwe.PeerSignal> signals,
    required int bsnsYear,
    required String rceptNo,
  }) = _PeerCandidateImpl;

  factory PeerCandidate.fromJson(Map<String, dynamic> jsonSerialization) {
    return PeerCandidate(
      corpCode: jsonSerialization['corpCode'] as String,
      name: jsonSerialization['name'] as String,
      tier: jsonSerialization['tier'] as String,
      reasons: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['reasons'],
      ),
      differences: _i4yshtjp.Protocol().deserialize<List<String>>(
        jsonSerialization['differences'],
      ),
      signals: _i4yshtjp.Protocol().deserialize<List<_i9d9glwe.PeerSignal>>(
        jsonSerialization['signals'],
      ),
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
    );
  }

  String corpCode;

  String name;

  String tier;

  List<String> reasons;

  List<String> differences;

  List<_i9d9glwe.PeerSignal> signals;

  int bsnsYear;

  String rceptNo;

  /// Returns a shallow copy of this [PeerCandidate]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PeerCandidate copyWith({
    String? corpCode,
    String? name,
    String? tier,
    List<String>? reasons,
    List<String>? differences,
    List<_i9d9glwe.PeerSignal>? signals,
    int? bsnsYear,
    String? rceptNo,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PeerCandidate',
      'corpCode': corpCode,
      'name': name,
      'tier': tier,
      'reasons': reasons.toJson(),
      'differences': differences.toJson(),
      'signals': signals.toJson(valueToJson: (v) => v.toJson()),
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PeerCandidate',
      'corpCode': corpCode,
      'name': name,
      'tier': tier,
      'reasons': reasons.toJson(),
      'differences': differences.toJson(),
      'signals': signals.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PeerCandidateImpl extends PeerCandidate {
  _PeerCandidateImpl({
    required String corpCode,
    required String name,
    required String tier,
    required List<String> reasons,
    required List<String> differences,
    required List<_i9d9glwe.PeerSignal> signals,
    required int bsnsYear,
    required String rceptNo,
  }) : super._(
         corpCode: corpCode,
         name: name,
         tier: tier,
         reasons: reasons,
         differences: differences,
         signals: signals,
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
       );

  /// Returns a shallow copy of this [PeerCandidate]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PeerCandidate copyWith({
    String? corpCode,
    String? name,
    String? tier,
    List<String>? reasons,
    List<String>? differences,
    List<_i9d9glwe.PeerSignal>? signals,
    int? bsnsYear,
    String? rceptNo,
  }) {
    return PeerCandidate(
      corpCode: corpCode ?? this.corpCode,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      reasons: reasons ?? this.reasons.map((e0) => e0).toList(),
      differences: differences ?? this.differences.map((e0) => e0).toList(),
      signals: signals ?? this.signals.map((e0) => e0.copyWith()).toList(),
      bsnsYear: bsnsYear ?? this.bsnsYear,
      rceptNo: rceptNo ?? this.rceptNo,
    );
  }
}
