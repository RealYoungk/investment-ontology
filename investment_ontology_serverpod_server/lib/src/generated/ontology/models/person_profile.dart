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
import '../../ontology/models/person.dart' as _ici34sqw;
import '../../ontology/models/person_role.dart' as _i9dsdzhy;

abstract class PersonProfile
    implements _is.SerializableModel, _is.ProtocolSerialization {
  PersonProfile._({
    required this.person,
    required this.roles,
  });

  factory PersonProfile({
    required _ici34sqw.Person person,
    required List<_i9dsdzhy.PersonRole> roles,
  }) = _PersonProfileImpl;

  factory PersonProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return PersonProfile(
      person: _i4yshtjp.Protocol().deserialize<_ici34sqw.Person>(
        jsonSerialization['person'],
      ),
      roles: _i4yshtjp.Protocol().deserialize<List<_i9dsdzhy.PersonRole>>(
        jsonSerialization['roles'],
      ),
    );
  }

  _ici34sqw.Person person;

  List<_i9dsdzhy.PersonRole> roles;

  /// Returns a shallow copy of this [PersonProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PersonProfile copyWith({
    _ici34sqw.Person? person,
    List<_i9dsdzhy.PersonRole>? roles,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PersonProfile',
      'person': person.toJson(),
      'roles': roles.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PersonProfile',
      'person': person.toJsonForProtocol(),
      'roles': roles.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _PersonProfileImpl extends PersonProfile {
  _PersonProfileImpl({
    required _ici34sqw.Person person,
    required List<_i9dsdzhy.PersonRole> roles,
  }) : super._(
         person: person,
         roles: roles,
       );

  /// Returns a shallow copy of this [PersonProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PersonProfile copyWith({
    _ici34sqw.Person? person,
    List<_i9dsdzhy.PersonRole>? roles,
  }) {
    return PersonProfile(
      person: person ?? this.person.copyWith(),
      roles: roles ?? this.roles.map((e0) => e0.copyWith()).toList(),
    );
  }
}
