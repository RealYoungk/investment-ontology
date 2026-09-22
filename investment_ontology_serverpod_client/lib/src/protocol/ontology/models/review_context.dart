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

/// 검수 항목의 근거 문장을 원문 앞뒤와 함께. 사람이 원문 탭으로 가지 않고 그 자리에서 판단하게.
abstract class ReviewContext
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ReviewContext._({
    required this.before,
    required this.evidence,
    required this.after,
    this.heading,
    required this.found,
  });

  factory ReviewContext({
    required String before,
    required String evidence,
    required String after,
    String? heading,
    required bool found,
  }) = _ReviewContextImpl;

  factory ReviewContext.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewContext(
      before: jsonSerialization['before'] as String,
      evidence: jsonSerialization['evidence'] as String,
      after: jsonSerialization['after'] as String,
      heading: jsonSerialization['heading'] as String?,
      found: _isc.BoolJsonExtension.fromJson(jsonSerialization['found']),
    );
  }

  /// 근거 앞의 원문 (몇백 자)
  String before;

  /// 근거 문장 (원문 그대로)
  String evidence;

  /// 근거 뒤의 원문
  String after;

  /// 근거가 든 절 제목 (`## ` 줄), 없으면 null
  String? heading;

  /// 원문에서 근거를 찾지 못했으면 false (그러면 before·after는 비어 있다)
  bool found;

  /// Returns a shallow copy of this [ReviewContext]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ReviewContext copyWith({
    String? before,
    String? evidence,
    String? after,
    String? heading,
    bool? found,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewContext',
      'before': before,
      'evidence': evidence,
      'after': after,
      if (heading != null) 'heading': heading,
      'found': found,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewContext',
      'before': before,
      'evidence': evidence,
      'after': after,
      if (heading != null) 'heading': heading,
      'found': found,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReviewContextImpl extends ReviewContext {
  _ReviewContextImpl({
    required String before,
    required String evidence,
    required String after,
    String? heading,
    required bool found,
  }) : super._(
         before: before,
         evidence: evidence,
         after: after,
         heading: heading,
         found: found,
       );

  /// Returns a shallow copy of this [ReviewContext]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ReviewContext copyWith({
    String? before,
    String? evidence,
    String? after,
    Object? heading = _Undefined,
    bool? found,
  }) {
    return ReviewContext(
      before: before ?? this.before,
      evidence: evidence ?? this.evidence,
      after: after ?? this.after,
      heading: heading is String? ? heading : this.heading,
      found: found ?? this.found,
    );
  }
}
