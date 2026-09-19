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
import 'package:serverpod/serverpod.dart' as _is;

/// 사업의 내용 하위 절 하나 (1. 사업의 개요, 2. 주요 제품 및 서비스 …).
abstract class BusinessSection
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BusinessSection._({
    required this.title,
    required this.text,
  });

  factory BusinessSection({
    required String title,
    required String text,
  }) = _BusinessSectionImpl;

  factory BusinessSection.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessSection(
      title: jsonSerialization['title'] as String,
      text: jsonSerialization['text'] as String,
    );
  }

  String title;

  String text;

  /// Returns a shallow copy of this [BusinessSection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BusinessSection copyWith({
    String? title,
    String? text,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessSection',
      'title': title,
      'text': text,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessSection',
      'title': title,
      'text': text,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _BusinessSectionImpl extends BusinessSection {
  _BusinessSectionImpl({
    required String title,
    required String text,
  }) : super._(
         title: title,
         text: text,
       );

  /// Returns a shallow copy of this [BusinessSection]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BusinessSection copyWith({
    String? title,
    String? text,
  }) {
    return BusinessSection(
      title: title ?? this.title,
      text: text ?? this.text,
    );
  }
}
