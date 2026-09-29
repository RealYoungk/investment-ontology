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

abstract class PeerSignal
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  PeerSignal._({
    required this.key,
    required this.label,
    required this.evidence,
  });

  factory PeerSignal({
    required String key,
    required String label,
    required String evidence,
  }) = _PeerSignalImpl;

  factory PeerSignal.fromJson(Map<String, dynamic> jsonSerialization) {
    return PeerSignal(
      key: jsonSerialization['key'] as String,
      label: jsonSerialization['label'] as String,
      evidence: jsonSerialization['evidence'] as String,
    );
  }

  String key;

  String label;

  String evidence;

  /// Returns a shallow copy of this [PeerSignal]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  PeerSignal copyWith({
    String? key,
    String? label,
    String? evidence,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PeerSignal',
      'key': key,
      'label': label,
      'evidence': evidence,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PeerSignal',
      'key': key,
      'label': label,
      'evidence': evidence,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _PeerSignalImpl extends PeerSignal {
  _PeerSignalImpl({
    required String key,
    required String label,
    required String evidence,
  }) : super._(
         key: key,
         label: label,
         evidence: evidence,
       );

  /// Returns a shallow copy of this [PeerSignal]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  PeerSignal copyWith({
    String? key,
    String? label,
    String? evidence,
  }) {
    return PeerSignal(
      key: key ?? this.key,
      label: label ?? this.label,
      evidence: evidence ?? this.evidence,
    );
  }
}
