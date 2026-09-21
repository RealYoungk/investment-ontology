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
import '../../ontology/models/company_ref.dart' as _id7z5ov5;
import '../../ontology/models/executive_entry.dart' as _idolfb48;
import '../../ontology/models/governance_link.dart' as _icazq9ky;
import '../../ontology/models/investment_entry.dart' as _iqr7dqno;
import '../../ontology/models/person.dart' as _ici34sqw;
import '../../ontology/models/shareholder_entry.dart' as _i2z9gcy6;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// 기업 상세의 지배구조: 한 사업연도 사업보고서의 최대주주 · 임원 · 타법인출자와 역방향 관계.
abstract class CompanyGovernance
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CompanyGovernance._({
    required this.corpCode,
    this.bsnsYear,
    this.settlementDate,
    required this.availableYears,
    required this.shareholders,
    required this.executives,
    required this.investments,
    required this.investors,
    required this.holdings,
    required this.companies,
    required this.persons,
    required this.sources,
  });

  factory CompanyGovernance({
    required String corpCode,
    int? bsnsYear,
    DateTime? settlementDate,
    required List<int> availableYears,
    required List<_i2z9gcy6.ShareholderEntry> shareholders,
    required List<_idolfb48.ExecutiveEntry> executives,
    required List<_iqr7dqno.InvestmentEntry> investments,
    required List<_icazq9ky.GovernanceLink> investors,
    required List<_icazq9ky.GovernanceLink> holdings,
    required List<_id7z5ov5.CompanyRef> companies,
    required List<_ici34sqw.Person> persons,
    required List<_i5ra8lvy.Source> sources,
  }) = _CompanyGovernanceImpl;

  factory CompanyGovernance.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyGovernance(
      corpCode: jsonSerialization['corpCode'] as String,
      bsnsYear: jsonSerialization['bsnsYear'] as int?,
      settlementDate: jsonSerialization['settlementDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['settlementDate'],
            ),
      availableYears: _ilkzeueu.Protocol().deserialize<List<int>>(
        jsonSerialization['availableYears'],
      ),
      shareholders: _ilkzeueu.Protocol()
          .deserialize<List<_i2z9gcy6.ShareholderEntry>>(
            jsonSerialization['shareholders'],
          ),
      executives: _ilkzeueu.Protocol()
          .deserialize<List<_idolfb48.ExecutiveEntry>>(
            jsonSerialization['executives'],
          ),
      investments: _ilkzeueu.Protocol()
          .deserialize<List<_iqr7dqno.InvestmentEntry>>(
            jsonSerialization['investments'],
          ),
      investors: _ilkzeueu.Protocol()
          .deserialize<List<_icazq9ky.GovernanceLink>>(
            jsonSerialization['investors'],
          ),
      holdings: _ilkzeueu.Protocol()
          .deserialize<List<_icazq9ky.GovernanceLink>>(
            jsonSerialization['holdings'],
          ),
      companies: _ilkzeueu.Protocol().deserialize<List<_id7z5ov5.CompanyRef>>(
        jsonSerialization['companies'],
      ),
      persons: _ilkzeueu.Protocol().deserialize<List<_ici34sqw.Person>>(
        jsonSerialization['persons'],
      ),
      sources: _ilkzeueu.Protocol().deserialize<List<_i5ra8lvy.Source>>(
        jsonSerialization['sources'],
      ),
    );
  }

  String corpCode;

  /// 보여 주는 사업연도. 자료가 없으면 null
  int? bsnsYear;

  DateTime? settlementDate;

  /// 자료가 있는 사업연도 (최근부터)
  List<int> availableYears;

  List<_i2z9gcy6.ShareholderEntry> shareholders;

  List<_idolfb48.ExecutiveEntry> executives;

  List<_iqr7dqno.InvestmentEntry> investments;

  /// 이 기업에 출자한 기업 (다른 기업의 타법인 출자현황)
  List<_icazq9ky.GovernanceLink> investors;

  /// 이 기업이 최대주주·특수관계인으로 있는 기업 (다른 기업의 최대주주 현황)
  List<_icazq9ky.GovernanceLink> holdings;

  /// 위 행들이 가리키는 기업·인물
  List<_id7z5ov5.CompanyRef> companies;

  List<_ici34sqw.Person> persons;

  List<_i5ra8lvy.Source> sources;

  /// Returns a shallow copy of this [CompanyGovernance]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CompanyGovernance copyWith({
    String? corpCode,
    int? bsnsYear,
    DateTime? settlementDate,
    List<int>? availableYears,
    List<_i2z9gcy6.ShareholderEntry>? shareholders,
    List<_idolfb48.ExecutiveEntry>? executives,
    List<_iqr7dqno.InvestmentEntry>? investments,
    List<_icazq9ky.GovernanceLink>? investors,
    List<_icazq9ky.GovernanceLink>? holdings,
    List<_id7z5ov5.CompanyRef>? companies,
    List<_ici34sqw.Person>? persons,
    List<_i5ra8lvy.Source>? sources,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyGovernance',
      'corpCode': corpCode,
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'availableYears': availableYears.toJson(),
      'shareholders': shareholders.toJson(valueToJson: (v) => v.toJson()),
      'executives': executives.toJson(valueToJson: (v) => v.toJson()),
      'investments': investments.toJson(valueToJson: (v) => v.toJson()),
      'investors': investors.toJson(valueToJson: (v) => v.toJson()),
      'holdings': holdings.toJson(valueToJson: (v) => v.toJson()),
      'companies': companies.toJson(valueToJson: (v) => v.toJson()),
      'persons': persons.toJson(valueToJson: (v) => v.toJson()),
      'sources': sources.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyGovernance',
      'corpCode': corpCode,
      if (bsnsYear != null) 'bsnsYear': bsnsYear,
      if (settlementDate != null) 'settlementDate': settlementDate?.toJson(),
      'availableYears': availableYears.toJson(),
      'shareholders': shareholders.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'executives': executives.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'investments': investments.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
      'investors': investors.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'holdings': holdings.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'companies': companies.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'persons': persons.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'sources': sources.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CompanyGovernanceImpl extends CompanyGovernance {
  _CompanyGovernanceImpl({
    required String corpCode,
    int? bsnsYear,
    DateTime? settlementDate,
    required List<int> availableYears,
    required List<_i2z9gcy6.ShareholderEntry> shareholders,
    required List<_idolfb48.ExecutiveEntry> executives,
    required List<_iqr7dqno.InvestmentEntry> investments,
    required List<_icazq9ky.GovernanceLink> investors,
    required List<_icazq9ky.GovernanceLink> holdings,
    required List<_id7z5ov5.CompanyRef> companies,
    required List<_ici34sqw.Person> persons,
    required List<_i5ra8lvy.Source> sources,
  }) : super._(
         corpCode: corpCode,
         bsnsYear: bsnsYear,
         settlementDate: settlementDate,
         availableYears: availableYears,
         shareholders: shareholders,
         executives: executives,
         investments: investments,
         investors: investors,
         holdings: holdings,
         companies: companies,
         persons: persons,
         sources: sources,
       );

  /// Returns a shallow copy of this [CompanyGovernance]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CompanyGovernance copyWith({
    String? corpCode,
    Object? bsnsYear = _Undefined,
    Object? settlementDate = _Undefined,
    List<int>? availableYears,
    List<_i2z9gcy6.ShareholderEntry>? shareholders,
    List<_idolfb48.ExecutiveEntry>? executives,
    List<_iqr7dqno.InvestmentEntry>? investments,
    List<_icazq9ky.GovernanceLink>? investors,
    List<_icazq9ky.GovernanceLink>? holdings,
    List<_id7z5ov5.CompanyRef>? companies,
    List<_ici34sqw.Person>? persons,
    List<_i5ra8lvy.Source>? sources,
  }) {
    return CompanyGovernance(
      corpCode: corpCode ?? this.corpCode,
      bsnsYear: bsnsYear is int? ? bsnsYear : this.bsnsYear,
      settlementDate: settlementDate is DateTime?
          ? settlementDate
          : this.settlementDate,
      availableYears:
          availableYears ?? this.availableYears.map((e0) => e0).toList(),
      shareholders:
          shareholders ?? this.shareholders.map((e0) => e0.copyWith()).toList(),
      executives:
          executives ?? this.executives.map((e0) => e0.copyWith()).toList(),
      investments:
          investments ?? this.investments.map((e0) => e0.copyWith()).toList(),
      investors:
          investors ?? this.investors.map((e0) => e0.copyWith()).toList(),
      holdings: holdings ?? this.holdings.map((e0) => e0.copyWith()).toList(),
      companies:
          companies ?? this.companies.map((e0) => e0.copyWith()).toList(),
      persons: persons ?? this.persons.map((e0) => e0.copyWith()).toList(),
      sources: sources ?? this.sources.map((e0) => e0.copyWith()).toList(),
    );
  }
}
