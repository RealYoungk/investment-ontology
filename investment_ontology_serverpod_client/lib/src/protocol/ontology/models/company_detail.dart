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
import '../../ontology/models/company.dart' as _it2dbo0u;
import '../../ontology/models/industry.dart' as _ichk09h6;
import '../../ontology/models/source.dart' as _i5ra8lvy;

abstract class CompanyDetail
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CompanyDetail._({
    required this.company,
    required this.industryPath,
    this.profileSource,
  });

  factory CompanyDetail({
    required _it2dbo0u.Company company,
    required List<_ichk09h6.Industry> industryPath,
    _i5ra8lvy.Source? profileSource,
  }) = _CompanyDetailImpl;

  factory CompanyDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyDetail(
      company: _ilkzeueu.Protocol().deserialize<_it2dbo0u.Company>(
        jsonSerialization['company'],
      ),
      industryPath: _ilkzeueu.Protocol().deserialize<List<_ichk09h6.Industry>>(
        jsonSerialization['industryPath'],
      ),
      profileSource: jsonSerialization['profileSource'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['profileSource'],
            ),
    );
  }

  _it2dbo0u.Company company;

  /// 대분류 → 해당 코드까지의 KSIC 경로
  List<_ichk09h6.Industry> industryPath;

  _i5ra8lvy.Source? profileSource;

  /// Returns a shallow copy of this [CompanyDetail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CompanyDetail copyWith({
    _it2dbo0u.Company? company,
    List<_ichk09h6.Industry>? industryPath,
    _i5ra8lvy.Source? profileSource,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyDetail',
      'company': company.toJson(),
      'industryPath': industryPath.toJson(valueToJson: (v) => v.toJson()),
      if (profileSource != null) 'profileSource': profileSource?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyDetail',
      'company': company.toJsonForProtocol(),
      'industryPath': industryPath.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      if (profileSource != null)
        'profileSource': profileSource?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyDetailImpl extends CompanyDetail {
  _CompanyDetailImpl({
    required _it2dbo0u.Company company,
    required List<_ichk09h6.Industry> industryPath,
    _i5ra8lvy.Source? profileSource,
  }) : super._(
         company: company,
         industryPath: industryPath,
         profileSource: profileSource,
       );

  /// Returns a shallow copy of this [CompanyDetail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CompanyDetail copyWith({
    _it2dbo0u.Company? company,
    List<_ichk09h6.Industry>? industryPath,
    Object? profileSource = _Undefined,
  }) {
    return CompanyDetail(
      company: company ?? this.company.copyWith(),
      industryPath:
          industryPath ?? this.industryPath.map((e0) => e0.copyWith()).toList(),
      profileSource: profileSource is _i5ra8lvy.Source?
          ? profileSource
          : this.profileSource?.copyWith(),
    );
  }
}
