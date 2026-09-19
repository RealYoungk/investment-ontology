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

/// 수집 장부: 전체 공시 목록(list.json)을 어느 구간까지 훑었는지. 한 행만 둔다.
/// 기업 하나만 받는 수집은 이 커서를 움직이지 않는다.
abstract class DartFilingScan
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DartFilingScan._({
    this.id,
    this.scannedFrom,
    required this.scannedThrough,
    required this.updatedAt,
  });

  factory DartFilingScan({
    int? id,
    DateTime? scannedFrom,
    required DateTime scannedThrough,
    required DateTime updatedAt,
  }) = _DartFilingScanImpl;

  factory DartFilingScan.fromJson(Map<String, dynamic> jsonSerialization) {
    return DartFilingScan(
      id: jsonSerialization['id'] as int?,
      scannedFrom: jsonSerialization['scannedFrom'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['scannedFrom'],
            ),
      scannedThrough: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['scannedThrough'],
      ),
      updatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// 훑기 시작한 날짜(UTC 자정). 수집 범위가 넓어져 이보다 이른 날짜가 필요하면 처음부터 다시 훑는다.
  /// 기록 전의 행은 null이고, 이 경우도 처음부터 다시 훑는다.
  DateTime? scannedFrom;

  /// 이 날짜(UTC 자정)까지의 구간을 끝까지 훑었다
  DateTime scannedThrough;

  DateTime updatedAt;

  /// Returns a shallow copy of this [DartFilingScan]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DartFilingScan copyWith({
    int? id,
    DateTime? scannedFrom,
    DateTime? scannedThrough,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DartFilingScan',
      if (id != null) 'id': id,
      if (scannedFrom != null) 'scannedFrom': scannedFrom?.toJson(),
      'scannedThrough': scannedThrough.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DartFilingScan',
      if (id != null) 'id': id,
      if (scannedFrom != null) 'scannedFrom': scannedFrom?.toJson(),
      'scannedThrough': scannedThrough.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DartFilingScanImpl extends DartFilingScan {
  _DartFilingScanImpl({
    int? id,
    DateTime? scannedFrom,
    required DateTime scannedThrough,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         scannedFrom: scannedFrom,
         scannedThrough: scannedThrough,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [DartFilingScan]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DartFilingScan copyWith({
    Object? id = _Undefined,
    Object? scannedFrom = _Undefined,
    DateTime? scannedThrough,
    DateTime? updatedAt,
  }) {
    return DartFilingScan(
      id: id is int? ? id : this.id,
      scannedFrom: scannedFrom is DateTime? ? scannedFrom : this.scannedFrom,
      scannedThrough: scannedThrough ?? this.scannedThrough,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
