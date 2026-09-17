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
import '../../ontology/models/source_kind.dart' as _i64hjcpq;

/// 사실(수치·관계)의 출처. 출처 없는 사실은 저장하지 않는다.
abstract class Source
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Source._({
    this.id,
    required this.kind,
    required this.title,
    this.reference,
    this.url,
    required this.retrievedAt,
  });

  factory Source({
    int? id,
    required _i64hjcpq.SourceKind kind,
    required String title,
    String? reference,
    String? url,
    required DateTime retrievedAt,
  }) = _SourceImpl;

  factory Source.fromJson(Map<String, dynamic> jsonSerialization) {
    return Source(
      id: jsonSerialization['id'] as int?,
      kind: _i64hjcpq.SourceKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      title: jsonSerialization['title'] as String,
      reference: jsonSerialization['reference'] as String?,
      url: jsonSerialization['url'] as String?,
      retrievedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['retrievedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i64hjcpq.SourceKind kind;

  /// 예: "DART 기업개황 (company.json)"
  String title;

  /// 공시 접수번호, corp_code 등 원천에서의 식별자
  String? reference;

  String? url;

  DateTime retrievedAt;

  /// Returns a shallow copy of this [Source]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Source copyWith({
    int? id,
    _i64hjcpq.SourceKind? kind,
    String? title,
    String? reference,
    String? url,
    DateTime? retrievedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Source',
      if (id != null) 'id': id,
      'kind': kind.toJson(),
      'title': title,
      if (reference != null) 'reference': reference,
      if (url != null) 'url': url,
      'retrievedAt': retrievedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Source',
      if (id != null) 'id': id,
      'kind': kind.toJson(),
      'title': title,
      if (reference != null) 'reference': reference,
      if (url != null) 'url': url,
      'retrievedAt': retrievedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SourceImpl extends Source {
  _SourceImpl({
    int? id,
    required _i64hjcpq.SourceKind kind,
    required String title,
    String? reference,
    String? url,
    required DateTime retrievedAt,
  }) : super._(
         id: id,
         kind: kind,
         title: title,
         reference: reference,
         url: url,
         retrievedAt: retrievedAt,
       );

  /// Returns a shallow copy of this [Source]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Source copyWith({
    Object? id = _Undefined,
    _i64hjcpq.SourceKind? kind,
    String? title,
    Object? reference = _Undefined,
    Object? url = _Undefined,
    DateTime? retrievedAt,
  }) {
    return Source(
      id: id is int? ? id : this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      reference: reference is String? ? reference : this.reference,
      url: url is String? ? url : this.url,
      retrievedAt: retrievedAt ?? this.retrievedAt,
    );
  }
}
