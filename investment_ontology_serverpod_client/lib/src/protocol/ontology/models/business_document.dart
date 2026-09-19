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

/// 사업보고서 본문 "II. 사업의 내용" (공시 원본 파일 document.xml에서 뽑은 글). 4단계 AI 관계 추출의 원천.
abstract class BusinessDocument
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BusinessDocument._({
    this.id,
    required this.reportId,
    required this.companyId,
    required this.bsnsYear,
    required this.rceptNo,
    required this.title,
    required this.text,
    required this.charCount,
  });

  factory BusinessDocument({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required String rceptNo,
    required String title,
    required String text,
    required int charCount,
  }) = _BusinessDocumentImpl;

  factory BusinessDocument.fromJson(Map<String, dynamic> jsonSerialization) {
    return BusinessDocument(
      id: jsonSerialization['id'] as int?,
      reportId: jsonSerialization['reportId'] as int,
      companyId: jsonSerialization['companyId'] as int,
      bsnsYear: jsonSerialization['bsnsYear'] as int,
      rceptNo: jsonSerialization['rceptNo'] as String,
      title: jsonSerialization['title'] as String,
      text: jsonSerialization['text'] as String,
      charCount: jsonSerialization['charCount'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int reportId;

  int companyId;

  int bsnsYear;

  String rceptNo;

  /// 원문 제목 (예: II. 사업의 내용)
  String title;

  /// 표는 칸을 ' | '로 이은 줄로, 하위 절 제목은 '## '로 시작하는 줄로 바꾼 글
  String text;

  int charCount;

  /// Returns a shallow copy of this [BusinessDocument]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BusinessDocument copyWith({
    int? id,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    String? rceptNo,
    String? title,
    String? text,
    int? charCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BusinessDocument',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      'title': title,
      'text': text,
      'charCount': charCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BusinessDocument',
      if (id != null) 'id': id,
      'reportId': reportId,
      'companyId': companyId,
      'bsnsYear': bsnsYear,
      'rceptNo': rceptNo,
      'title': title,
      'text': text,
      'charCount': charCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BusinessDocumentImpl extends BusinessDocument {
  _BusinessDocumentImpl({
    int? id,
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required String rceptNo,
    required String title,
    required String text,
    required int charCount,
  }) : super._(
         id: id,
         reportId: reportId,
         companyId: companyId,
         bsnsYear: bsnsYear,
         rceptNo: rceptNo,
         title: title,
         text: text,
         charCount: charCount,
       );

  /// Returns a shallow copy of this [BusinessDocument]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BusinessDocument copyWith({
    Object? id = _Undefined,
    int? reportId,
    int? companyId,
    int? bsnsYear,
    String? rceptNo,
    String? title,
    String? text,
    int? charCount,
  }) {
    return BusinessDocument(
      id: id is int? ? id : this.id,
      reportId: reportId ?? this.reportId,
      companyId: companyId ?? this.companyId,
      bsnsYear: bsnsYear ?? this.bsnsYear,
      rceptNo: rceptNo ?? this.rceptNo,
      title: title ?? this.title,
      text: text ?? this.text,
      charCount: charCount ?? this.charCount,
    );
  }
}
