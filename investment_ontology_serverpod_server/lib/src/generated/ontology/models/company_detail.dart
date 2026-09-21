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
import '../../ontology/models/company.dart' as _it2dbo0u;
import '../../ontology/models/company_change.dart' as _igec0di4;
import '../../ontology/models/industry.dart' as _ichk09h6;
import '../../ontology/models/source.dart' as _i5ra8lvy;

abstract class CompanyDetail
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CompanyDetail._({
    required this.company,
    required this.industryPath,
    this.profileSource,
    required this.changes,
  });

  factory CompanyDetail({
    required _it2dbo0u.Company company,
    required List<_ichk09h6.Industry> industryPath,
    _i5ra8lvy.Source? profileSource,
    required List<_igec0di4.CompanyChange> changes,
  }) = _CompanyDetailImpl;

  factory CompanyDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyDetail(
      company: _i4yshtjp.Protocol().deserialize<_it2dbo0u.Company>(
        jsonSerialization['company'],
      ),
      industryPath: _i4yshtjp.Protocol().deserialize<List<_ichk09h6.Industry>>(
        jsonSerialization['industryPath'],
      ),
      profileSource: jsonSerialization['profileSource'] == null
          ? null
          : _i4yshtjp.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['profileSource'],
            ),
      changes: _i4yshtjp.Protocol().deserialize<List<_igec0di4.CompanyChange>>(
        jsonSerialization['changes'],
      ),
    );
  }

  _it2dbo0u.Company company;

  /// 대분류 → 해당 코드까지의 KSIC 경로
  List<_ichk09h6.Industry> industryPath;

  _i5ra8lvy.Source? profileSource;

  /// 최근 변경 이력 (최신순)
  List<_igec0di4.CompanyChange> changes;

  /// Returns a shallow copy of this [CompanyDetail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CompanyDetail copyWith({
    _it2dbo0u.Company? company,
    List<_ichk09h6.Industry>? industryPath,
    _i5ra8lvy.Source? profileSource,
    List<_igec0di4.CompanyChange>? changes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyDetail',
      'company': company.toJson(),
      'industryPath': industryPath.toJson(valueToJson: (v) => v.toJson()),
      if (profileSource != null) 'profileSource': profileSource?.toJson(),
      'changes': changes.toJson(valueToJson: (v) => v.toJson()),
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
      'changes': changes.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyDetailImpl extends CompanyDetail {
  _CompanyDetailImpl({
    required _it2dbo0u.Company company,
    required List<_ichk09h6.Industry> industryPath,
    _i5ra8lvy.Source? profileSource,
    required List<_igec0di4.CompanyChange> changes,
  }) : super._(
         company: company,
         industryPath: industryPath,
         profileSource: profileSource,
         changes: changes,
       );

  /// Returns a shallow copy of this [CompanyDetail]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CompanyDetail copyWith({
    _it2dbo0u.Company? company,
    List<_ichk09h6.Industry>? industryPath,
    Object? profileSource = _Undefined,
    List<_igec0di4.CompanyChange>? changes,
  }) {
    return CompanyDetail(
      company: company ?? this.company.copyWith(),
      industryPath:
          industryPath ?? this.industryPath.map((e0) => e0.copyWith()).toList(),
      profileSource: profileSource is _i5ra8lvy.Source?
          ? profileSource
          : this.profileSource?.copyWith(),
      changes: changes ?? this.changes.map((e0) => e0.copyWith()).toList(),
    );
  }
}
