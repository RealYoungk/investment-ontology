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

/// 검수 정확률 기록: 뽑아 둔 것을 원문과 하나씩 대조하고 그 결과를 숫자로 남긴다.
///
/// 모델이 스스로 매긴 확신도(confidence)와 다르다. 이건 실제로 몇 건이 맞았는지다.
abstract class ReviewCheck
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ReviewCheck._({
    this.id,
    required this.scope,
    required this.checked,
    required this.correct,
    required this.leftToPerson,
    required this.checkedBy,
    this.note,
    required this.createdAt,
  });

  factory ReviewCheck({
    int? id,
    required String scope,
    required int checked,
    required int correct,
    required int leftToPerson,
    required String checkedBy,
    String? note,
    required DateTime createdAt,
  }) = _ReviewCheckImpl;

  factory ReviewCheck.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewCheck(
      id: jsonSerialization['id'] as int?,
      scope: jsonSerialization['scope'] as String,
      checked: jsonSerialization['checked'] as int,
      correct: jsonSerialization['correct'] as int,
      leftToPerson: jsonSerialization['leftToPerson'] as int,
      checkedBy: jsonSerialization['checkedBy'] as String,
      note: jsonSerialization['note'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// relation · fact
  String scope;

  /// 대조한 건수
  int checked;

  /// 원문과 맞았던 건수
  int correct;

  /// 사람 판단으로 남긴 건수 (애매해서 넘긴 것)
  int leftToPerson;

  /// 누가 대조했는지
  String checkedBy;

  String? note;

  DateTime createdAt;

  /// Returns a shallow copy of this [ReviewCheck]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ReviewCheck copyWith({
    int? id,
    String? scope,
    int? checked,
    int? correct,
    int? leftToPerson,
    String? checkedBy,
    String? note,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewCheck',
      if (id != null) 'id': id,
      'scope': scope,
      'checked': checked,
      'correct': correct,
      'leftToPerson': leftToPerson,
      'checkedBy': checkedBy,
      if (note != null) 'note': note,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewCheck',
      if (id != null) 'id': id,
      'scope': scope,
      'checked': checked,
      'correct': correct,
      'leftToPerson': leftToPerson,
      'checkedBy': checkedBy,
      if (note != null) 'note': note,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReviewCheckImpl extends ReviewCheck {
  _ReviewCheckImpl({
    int? id,
    required String scope,
    required int checked,
    required int correct,
    required int leftToPerson,
    required String checkedBy,
    String? note,
    required DateTime createdAt,
  }) : super._(
         id: id,
         scope: scope,
         checked: checked,
         correct: correct,
         leftToPerson: leftToPerson,
         checkedBy: checkedBy,
         note: note,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ReviewCheck]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ReviewCheck copyWith({
    Object? id = _Undefined,
    String? scope,
    int? checked,
    int? correct,
    int? leftToPerson,
    String? checkedBy,
    Object? note = _Undefined,
    DateTime? createdAt,
  }) {
    return ReviewCheck(
      id: id is int? ? id : this.id,
      scope: scope ?? this.scope,
      checked: checked ?? this.checked,
      correct: correct ?? this.correct,
      leftToPerson: leftToPerson ?? this.leftToPerson,
      checkedBy: checkedBy ?? this.checkedBy,
      note: note is String? ? note : this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
