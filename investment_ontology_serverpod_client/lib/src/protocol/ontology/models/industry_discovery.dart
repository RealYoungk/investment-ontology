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
import '../../ontology/models/industry_activity.dart' as _ilmexvt7;

abstract class IndustryDiscovery
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  IndustryDiscovery._({
    required this.activities,
    required this.listedCompanyCount,
    required this.documentCompanyCount,
    required this.classifiedCompanyCount,
    required this.ruleVersion,
    required this.computedAt,
  });

  factory IndustryDiscovery({
    required List<_ilmexvt7.IndustryActivity> activities,
    required int listedCompanyCount,
    required int documentCompanyCount,
    required int classifiedCompanyCount,
    required int ruleVersion,
    required DateTime computedAt,
  }) = _IndustryDiscoveryImpl;

  factory IndustryDiscovery.fromJson(Map<String, dynamic> jsonSerialization) {
    return IndustryDiscovery(
      activities: _ilkzeueu.Protocol()
          .deserialize<List<_ilmexvt7.IndustryActivity>>(
            jsonSerialization['activities'],
          ),
      listedCompanyCount: jsonSerialization['listedCompanyCount'] as int,
      documentCompanyCount: jsonSerialization['documentCompanyCount'] as int,
      classifiedCompanyCount:
          jsonSerialization['classifiedCompanyCount'] as int,
      ruleVersion: jsonSerialization['ruleVersion'] as int,
      computedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['computedAt'],
      ),
    );
  }

  List<_ilmexvt7.IndustryActivity> activities;

  int listedCompanyCount;

  int documentCompanyCount;

  int classifiedCompanyCount;

  int ruleVersion;

  DateTime computedAt;

  /// Returns a shallow copy of this [IndustryDiscovery]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  IndustryDiscovery copyWith({
    List<_ilmexvt7.IndustryActivity>? activities,
    int? listedCompanyCount,
    int? documentCompanyCount,
    int? classifiedCompanyCount,
    int? ruleVersion,
    DateTime? computedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IndustryDiscovery',
      'activities': activities.toJson(valueToJson: (v) => v.toJson()),
      'listedCompanyCount': listedCompanyCount,
      'documentCompanyCount': documentCompanyCount,
      'classifiedCompanyCount': classifiedCompanyCount,
      'ruleVersion': ruleVersion,
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IndustryDiscovery',
      'activities': activities.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'listedCompanyCount': listedCompanyCount,
      'documentCompanyCount': documentCompanyCount,
      'classifiedCompanyCount': classifiedCompanyCount,
      'ruleVersion': ruleVersion,
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _IndustryDiscoveryImpl extends IndustryDiscovery {
  _IndustryDiscoveryImpl({
    required List<_ilmexvt7.IndustryActivity> activities,
    required int listedCompanyCount,
    required int documentCompanyCount,
    required int classifiedCompanyCount,
    required int ruleVersion,
    required DateTime computedAt,
  }) : super._(
         activities: activities,
         listedCompanyCount: listedCompanyCount,
         documentCompanyCount: documentCompanyCount,
         classifiedCompanyCount: classifiedCompanyCount,
         ruleVersion: ruleVersion,
         computedAt: computedAt,
       );

  /// Returns a shallow copy of this [IndustryDiscovery]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  IndustryDiscovery copyWith({
    List<_ilmexvt7.IndustryActivity>? activities,
    int? listedCompanyCount,
    int? documentCompanyCount,
    int? classifiedCompanyCount,
    int? ruleVersion,
    DateTime? computedAt,
  }) {
    return IndustryDiscovery(
      activities:
          activities ?? this.activities.map((e0) => e0.copyWith()).toList(),
      listedCompanyCount: listedCompanyCount ?? this.listedCompanyCount,
      documentCompanyCount: documentCompanyCount ?? this.documentCompanyCount,
      classifiedCompanyCount:
          classifiedCompanyCount ?? this.classifiedCompanyCount,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      computedAt: computedAt ?? this.computedAt,
    );
  }
}
