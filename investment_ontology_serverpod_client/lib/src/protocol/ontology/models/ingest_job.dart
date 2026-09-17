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
import '../../ontology/models/ingest_status.dart' as _i281cs6p;

/// 외부 원천 수집 작업 기록.
abstract class IngestJob
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  IngestJob._({
    this.id,
    required this.kind,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    bool? fullRefresh,
    this.message,
  }) : total = total ?? 0,
       processed = processed ?? 0,
       updated = updated ?? 0,
       failed = failed ?? 0,
       apiCalls = apiCalls ?? 0,
       fullRefresh = fullRefresh ?? false;

  factory IngestJob({
    int? id,
    required String kind,
    required _i281cs6p.IngestStatus status,
    required DateTime startedAt,
    DateTime? finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    bool? fullRefresh,
    String? message,
  }) = _IngestJobImpl;

  factory IngestJob.fromJson(Map<String, dynamic> jsonSerialization) {
    return IngestJob(
      id: jsonSerialization['id'] as int?,
      kind: jsonSerialization['kind'] as String,
      status: _i281cs6p.IngestStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      startedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      finishedAt: jsonSerialization['finishedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['finishedAt'],
            ),
      total: jsonSerialization['total'] as int?,
      processed: jsonSerialization['processed'] as int?,
      updated: jsonSerialization['updated'] as int?,
      failed: jsonSerialization['failed'] as int?,
      apiCalls: jsonSerialization['apiCalls'] as int?,
      fullRefresh: jsonSerialization['fullRefresh'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['fullRefresh']),
      message: jsonSerialization['message'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// 예: "company_master"
  String kind;

  _i281cs6p.IngestStatus status;

  DateTime startedAt;

  DateTime? finishedAt;

  int total;

  int processed;

  int updated;

  int failed;

  int apiCalls;

  /// 변경일과 관계없이 모든 기업을 다시 받은 작업인지
  bool fullRefresh;

  String? message;

  /// Returns a shallow copy of this [IngestJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  IngestJob copyWith({
    int? id,
    String? kind,
    _i281cs6p.IngestStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    bool? fullRefresh,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IngestJob',
      if (id != null) 'id': id,
      'kind': kind,
      'status': status.toJson(),
      'startedAt': startedAt.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      'total': total,
      'processed': processed,
      'updated': updated,
      'failed': failed,
      'apiCalls': apiCalls,
      'fullRefresh': fullRefresh,
      if (message != null) 'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IngestJob',
      if (id != null) 'id': id,
      'kind': kind,
      'status': status.toJson(),
      'startedAt': startedAt.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      'total': total,
      'processed': processed,
      'updated': updated,
      'failed': failed,
      'apiCalls': apiCalls,
      'fullRefresh': fullRefresh,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IngestJobImpl extends IngestJob {
  _IngestJobImpl({
    int? id,
    required String kind,
    required _i281cs6p.IngestStatus status,
    required DateTime startedAt,
    DateTime? finishedAt,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    bool? fullRefresh,
    String? message,
  }) : super._(
         id: id,
         kind: kind,
         status: status,
         startedAt: startedAt,
         finishedAt: finishedAt,
         total: total,
         processed: processed,
         updated: updated,
         failed: failed,
         apiCalls: apiCalls,
         fullRefresh: fullRefresh,
         message: message,
       );

  /// Returns a shallow copy of this [IngestJob]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  IngestJob copyWith({
    Object? id = _Undefined,
    String? kind,
    _i281cs6p.IngestStatus? status,
    DateTime? startedAt,
    Object? finishedAt = _Undefined,
    int? total,
    int? processed,
    int? updated,
    int? failed,
    int? apiCalls,
    bool? fullRefresh,
    Object? message = _Undefined,
  }) {
    return IngestJob(
      id: id is int? ? id : this.id,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt is DateTime? ? finishedAt : this.finishedAt,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      updated: updated ?? this.updated,
      failed: failed ?? this.failed,
      apiCalls: apiCalls ?? this.apiCalls,
      fullRefresh: fullRefresh ?? this.fullRefresh,
      message: message is String? ? message : this.message,
    );
  }
}
