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

/// 사용자에게 보여줄 수 있는 수집 오류.
abstract class IngestException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  IngestException._({required this.message});

  factory IngestException({required String message}) = _IngestExceptionImpl;

  factory IngestException.fromJson(Map<String, dynamic> jsonSerialization) {
    return IngestException(message: jsonSerialization['message'] as String);
  }

  String message;

  /// Returns a shallow copy of this [IngestException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  IngestException copyWith({String? message});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IngestException',
      'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IngestException',
      'message': message,
    };
  }

  @override
  String toString() {
    return 'IngestException(message: $message)';
  }
}

class _IngestExceptionImpl extends IngestException {
  _IngestExceptionImpl({required String message}) : super._(message: message);

  /// Returns a shallow copy of this [IngestException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  IngestException copyWith({String? message}) {
    return IngestException(message: message ?? this.message);
  }
}
