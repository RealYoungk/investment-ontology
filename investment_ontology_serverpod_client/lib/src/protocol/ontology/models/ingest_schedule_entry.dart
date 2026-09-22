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
import '../../ontology/models/ingest_job.dart' as _iwr40u3f;

/// 자동 수집 한 종류의 예약과 마지막 실행. 데이터 화면의 "지금 상태".
abstract class IngestScheduleEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  IngestScheduleEntry._({
    required this.kind,
    required this.label,
    required this.timing,
    this.nextRunAt,
    required this.resuming,
    this.lastJob,
  });

  factory IngestScheduleEntry({
    required String kind,
    required String label,
    required String timing,
    DateTime? nextRunAt,
    required bool resuming,
    _iwr40u3f.IngestJob? lastJob,
  }) = _IngestScheduleEntryImpl;

  factory IngestScheduleEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return IngestScheduleEntry(
      kind: jsonSerialization['kind'] as String,
      label: jsonSerialization['label'] as String,
      timing: jsonSerialization['timing'] as String,
      nextRunAt: jsonSerialization['nextRunAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['nextRunAt']),
      resuming: _isc.BoolJsonExtension.fromJson(jsonSerialization['resuming']),
      lastJob: jsonSerialization['lastJob'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<_iwr40u3f.IngestJob>(
              jsonSerialization['lastJob'],
            ),
    );
  }

  /// 작업 종류 (`market_snapshot`, `financial_facts`, `disclosures`)
  String kind;

  String label;

  /// 예약 설명 ("매일 18:00")
  String timing;

  /// 다음 실행 예정 (예약이 없으면 null). 이어받기 예약이 있으면 그것이 더 이르다.
  DateTime? nextRunAt;

  /// 이어받기(한도 소진 뒤 다음 날) 예약인지
  bool resuming;

  /// 마지막 실행
  _iwr40u3f.IngestJob? lastJob;

  /// Returns a shallow copy of this [IngestScheduleEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  IngestScheduleEntry copyWith({
    String? kind,
    String? label,
    String? timing,
    DateTime? nextRunAt,
    bool? resuming,
    _iwr40u3f.IngestJob? lastJob,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IngestScheduleEntry',
      'kind': kind,
      'label': label,
      'timing': timing,
      if (nextRunAt != null) 'nextRunAt': nextRunAt?.toJson(),
      'resuming': resuming,
      if (lastJob != null) 'lastJob': lastJob?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IngestScheduleEntry',
      'kind': kind,
      'label': label,
      'timing': timing,
      if (nextRunAt != null) 'nextRunAt': nextRunAt?.toJson(),
      'resuming': resuming,
      if (lastJob != null) 'lastJob': lastJob?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IngestScheduleEntryImpl extends IngestScheduleEntry {
  _IngestScheduleEntryImpl({
    required String kind,
    required String label,
    required String timing,
    DateTime? nextRunAt,
    required bool resuming,
    _iwr40u3f.IngestJob? lastJob,
  }) : super._(
         kind: kind,
         label: label,
         timing: timing,
         nextRunAt: nextRunAt,
         resuming: resuming,
         lastJob: lastJob,
       );

  /// Returns a shallow copy of this [IngestScheduleEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  IngestScheduleEntry copyWith({
    String? kind,
    String? label,
    String? timing,
    Object? nextRunAt = _Undefined,
    bool? resuming,
    Object? lastJob = _Undefined,
  }) {
    return IngestScheduleEntry(
      kind: kind ?? this.kind,
      label: label ?? this.label,
      timing: timing ?? this.timing,
      nextRunAt: nextRunAt is DateTime? ? nextRunAt : this.nextRunAt,
      resuming: resuming ?? this.resuming,
      lastJob: lastJob is _iwr40u3f.IngestJob?
          ? lastJob
          : this.lastJob?.copyWith(),
    );
  }
}
