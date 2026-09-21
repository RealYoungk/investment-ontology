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
import '../../ontology/models/executive_registration.dart' as _i5x1kqvd;

/// 임원 한 행 (임원 현황 exctvSttus). 회사마다 미등기 임원을 내는지가 다르다.
abstract class ExecutiveEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ExecutiveEntry._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.ord,
    required this.name,
    this.sex,
    this.birthYear,
    this.birthMonth,
    this.position,
    required this.registration,
    this.registrationRaw,
    this.fullTime,
    this.duties,
    this.career,
    this.relationToLargestHolder,
    this.tenureMonths,
    this.termEndDate,
    this.personId,
  });

  factory ExecutiveEntry({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String name,
    String? sex,
    int? birthYear,
    int? birthMonth,
    String? position,
    required _i5x1kqvd.ExecutiveRegistration registration,
    String? registrationRaw,
    bool? fullTime,
    String? duties,
    String? career,
    String? relationToLargestHolder,
    int? tenureMonths,
    DateTime? termEndDate,
    int? personId,
  }) = _ExecutiveEntryImpl;

  factory ExecutiveEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return ExecutiveEntry(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      ord: jsonSerialization['ord'] as int,
      name: jsonSerialization['name'] as String,
      sex: jsonSerialization['sex'] as String?,
      birthYear: jsonSerialization['birthYear'] as int?,
      birthMonth: jsonSerialization['birthMonth'] as int?,
      position: jsonSerialization['position'] as String?,
      registration: _i5x1kqvd.ExecutiveRegistration.fromJson(
        (jsonSerialization['registration'] as String),
      ),
      registrationRaw: jsonSerialization['registrationRaw'] as String?,
      fullTime: jsonSerialization['fullTime'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['fullTime']),
      duties: jsonSerialization['duties'] as String?,
      career: jsonSerialization['career'] as String?,
      relationToLargestHolder:
          jsonSerialization['relationToLargestHolder'] as String?,
      tenureMonths: jsonSerialization['tenureMonths'] as int?,
      termEndDate: jsonSerialization['termEndDate'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['termEndDate'],
            ),
      personId: jsonSerialization['personId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  int ord;

  /// 줄바꿈·겹공백을 정리한 이름
  String name;

  String? sex;

  int? birthYear;

  int? birthMonth;

  /// 직위 원문
  String? position;

  _i5x1kqvd.ExecutiveRegistration registration;

  String? registrationRaw;

  /// 상근 여부
  bool? fullTime;

  String? duties;

  String? career;

  String? relationToLargestHolder;

  /// 재직기간 (개월)
  int? tenureMonths;

  DateTime? termEndDate;

  int? personId;

  /// Returns a shallow copy of this [ExecutiveEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ExecutiveEntry copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? name,
    String? sex,
    int? birthYear,
    int? birthMonth,
    String? position,
    _i5x1kqvd.ExecutiveRegistration? registration,
    String? registrationRaw,
    bool? fullTime,
    String? duties,
    String? career,
    String? relationToLargestHolder,
    int? tenureMonths,
    DateTime? termEndDate,
    int? personId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ExecutiveEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'name': name,
      if (sex != null) 'sex': sex,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (position != null) 'position': position,
      'registration': registration.toJson(),
      if (registrationRaw != null) 'registrationRaw': registrationRaw,
      if (fullTime != null) 'fullTime': fullTime,
      if (duties != null) 'duties': duties,
      if (career != null) 'career': career,
      if (relationToLargestHolder != null)
        'relationToLargestHolder': relationToLargestHolder,
      if (tenureMonths != null) 'tenureMonths': tenureMonths,
      if (termEndDate != null) 'termEndDate': termEndDate?.toJson(),
      if (personId != null) 'personId': personId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ExecutiveEntry',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'ord': ord,
      'name': name,
      if (sex != null) 'sex': sex,
      if (birthYear != null) 'birthYear': birthYear,
      if (birthMonth != null) 'birthMonth': birthMonth,
      if (position != null) 'position': position,
      'registration': registration.toJson(),
      if (registrationRaw != null) 'registrationRaw': registrationRaw,
      if (fullTime != null) 'fullTime': fullTime,
      if (duties != null) 'duties': duties,
      if (career != null) 'career': career,
      if (relationToLargestHolder != null)
        'relationToLargestHolder': relationToLargestHolder,
      if (tenureMonths != null) 'tenureMonths': tenureMonths,
      if (termEndDate != null) 'termEndDate': termEndDate?.toJson(),
      if (personId != null) 'personId': personId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ExecutiveEntryImpl extends ExecutiveEntry {
  _ExecutiveEntryImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required int ord,
    required String name,
    String? sex,
    int? birthYear,
    int? birthMonth,
    String? position,
    required _i5x1kqvd.ExecutiveRegistration registration,
    String? registrationRaw,
    bool? fullTime,
    String? duties,
    String? career,
    String? relationToLargestHolder,
    int? tenureMonths,
    DateTime? termEndDate,
    int? personId,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         ord: ord,
         name: name,
         sex: sex,
         birthYear: birthYear,
         birthMonth: birthMonth,
         position: position,
         registration: registration,
         registrationRaw: registrationRaw,
         fullTime: fullTime,
         duties: duties,
         career: career,
         relationToLargestHolder: relationToLargestHolder,
         tenureMonths: tenureMonths,
         termEndDate: termEndDate,
         personId: personId,
       );

  /// Returns a shallow copy of this [ExecutiveEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ExecutiveEntry copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    int? ord,
    String? name,
    Object? sex = _Undefined,
    Object? birthYear = _Undefined,
    Object? birthMonth = _Undefined,
    Object? position = _Undefined,
    _i5x1kqvd.ExecutiveRegistration? registration,
    Object? registrationRaw = _Undefined,
    Object? fullTime = _Undefined,
    Object? duties = _Undefined,
    Object? career = _Undefined,
    Object? relationToLargestHolder = _Undefined,
    Object? tenureMonths = _Undefined,
    Object? termEndDate = _Undefined,
    Object? personId = _Undefined,
  }) {
    return ExecutiveEntry(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      ord: ord ?? this.ord,
      name: name ?? this.name,
      sex: sex is String? ? sex : this.sex,
      birthYear: birthYear is int? ? birthYear : this.birthYear,
      birthMonth: birthMonth is int? ? birthMonth : this.birthMonth,
      position: position is String? ? position : this.position,
      registration: registration ?? this.registration,
      registrationRaw: registrationRaw is String?
          ? registrationRaw
          : this.registrationRaw,
      fullTime: fullTime is bool? ? fullTime : this.fullTime,
      duties: duties is String? ? duties : this.duties,
      career: career is String? ? career : this.career,
      relationToLargestHolder: relationToLargestHolder is String?
          ? relationToLargestHolder
          : this.relationToLargestHolder,
      tenureMonths: tenureMonths is int? ? tenureMonths : this.tenureMonths,
      termEndDate: termEndDate is DateTime? ? termEndDate : this.termEndDate,
      personId: personId is int? ? personId : this.personId,
    );
  }
}
