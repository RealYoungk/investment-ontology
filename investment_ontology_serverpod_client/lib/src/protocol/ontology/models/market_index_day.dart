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

/// 수집 장부: 지수를 받은 기준일. 휴장일(0건)도 기록해 다시 조회하지 않는다.
abstract class MarketIndexDay
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MarketIndexDay._({
    this.id,
    required this.baseDate,
    required this.rowCount,
    this.sourceId,
    required this.fetchedAt,
  });

  factory MarketIndexDay({
    int? id,
    required DateTime baseDate,
    required int rowCount,
    int? sourceId,
    required DateTime fetchedAt,
  }) = _MarketIndexDayImpl;

  factory MarketIndexDay.fromJson(Map<String, dynamic> jsonSerialization) {
    return MarketIndexDay(
      id: jsonSerialization['id'] as int?,
      baseDate: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['baseDate'],
      ),
      rowCount: jsonSerialization['rowCount'] as int,
      sourceId: jsonSerialization['sourceId'] as int?,
      fetchedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['fetchedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// 기준일 (UTC 자정)
  DateTime baseDate;

  int rowCount;

  int? sourceId;

  DateTime fetchedAt;

  /// Returns a shallow copy of this [MarketIndexDay]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MarketIndexDay copyWith({
    int? id,
    DateTime? baseDate,
    int? rowCount,
    int? sourceId,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MarketIndexDay',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'rowCount': rowCount,
      if (sourceId != null) 'sourceId': sourceId,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MarketIndexDay',
      if (id != null) 'id': id,
      'baseDate': baseDate.toJson(),
      'rowCount': rowCount,
      if (sourceId != null) 'sourceId': sourceId,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MarketIndexDayImpl extends MarketIndexDay {
  _MarketIndexDayImpl({
    int? id,
    required DateTime baseDate,
    required int rowCount,
    int? sourceId,
    required DateTime fetchedAt,
  }) : super._(
         id: id,
         baseDate: baseDate,
         rowCount: rowCount,
         sourceId: sourceId,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [MarketIndexDay]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MarketIndexDay copyWith({
    Object? id = _Undefined,
    DateTime? baseDate,
    int? rowCount,
    Object? sourceId = _Undefined,
    DateTime? fetchedAt,
  }) {
    return MarketIndexDay(
      id: id is int? ? id : this.id,
      baseDate: baseDate ?? this.baseDate,
      rowCount: rowCount ?? this.rowCount,
      sourceId: sourceId is int? ? sourceId : this.sourceId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
