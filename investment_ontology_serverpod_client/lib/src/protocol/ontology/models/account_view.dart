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

/// Public account metadata; never exposes passwords or authentication tokens.
abstract class AccountView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AccountView._({
    required this.userId,
    required this.email,
    required this.createdAt,
    required this.isAdmin,
    required this.blocked,
  });

  factory AccountView({
    required String userId,
    required String email,
    required DateTime createdAt,
    required bool isAdmin,
    required bool blocked,
  }) = _AccountViewImpl;

  factory AccountView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountView(
      userId: jsonSerialization['userId'] as String,
      email: jsonSerialization['email'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      isAdmin: _isc.BoolJsonExtension.fromJson(jsonSerialization['isAdmin']),
      blocked: _isc.BoolJsonExtension.fromJson(jsonSerialization['blocked']),
    );
  }

  String userId;

  String email;

  DateTime createdAt;

  bool isAdmin;

  bool blocked;

  /// Returns a shallow copy of this [AccountView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AccountView copyWith({
    String? userId,
    String? email,
    DateTime? createdAt,
    bool? isAdmin,
    bool? blocked,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountView',
      'userId': userId,
      'email': email,
      'createdAt': createdAt.toJson(),
      'isAdmin': isAdmin,
      'blocked': blocked,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AccountView',
      'userId': userId,
      'email': email,
      'createdAt': createdAt.toJson(),
      'isAdmin': isAdmin,
      'blocked': blocked,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _AccountViewImpl extends AccountView {
  _AccountViewImpl({
    required String userId,
    required String email,
    required DateTime createdAt,
    required bool isAdmin,
    required bool blocked,
  }) : super._(
         userId: userId,
         email: email,
         createdAt: createdAt,
         isAdmin: isAdmin,
         blocked: blocked,
       );

  /// Returns a shallow copy of this [AccountView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AccountView copyWith({
    String? userId,
    String? email,
    DateTime? createdAt,
    bool? isAdmin,
    bool? blocked,
  }) {
    return AccountView(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
      blocked: blocked ?? this.blocked,
    );
  }
}
