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
import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart'
    as _i4yshtjp;
import 'package:serverpod/serverpod.dart' as _is;
import '../../ontology/models/review_item.dart' as _ivhufo2l;

abstract class ReviewPage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ReviewPage._({
    required this.items,
    required this.total,
    required this.draftCount,
    required this.verifiedCount,
    required this.rejectedCount,
  });

  factory ReviewPage({
    required List<_ivhufo2l.ReviewItem> items,
    required int total,
    required int draftCount,
    required int verifiedCount,
    required int rejectedCount,
  }) = _ReviewPageImpl;

  factory ReviewPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReviewPage(
      items: _i4yshtjp.Protocol().deserialize<List<_ivhufo2l.ReviewItem>>(
        jsonSerialization['items'],
      ),
      total: jsonSerialization['total'] as int,
      draftCount: jsonSerialization['draftCount'] as int,
      verifiedCount: jsonSerialization['verifiedCount'] as int,
      rejectedCount: jsonSerialization['rejectedCount'] as int,
    );
  }

  List<_ivhufo2l.ReviewItem> items;

  int total;

  int draftCount;

  int verifiedCount;

  int rejectedCount;

  /// Returns a shallow copy of this [ReviewPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ReviewPage copyWith({
    List<_ivhufo2l.ReviewItem>? items,
    int? total,
    int? draftCount,
    int? verifiedCount,
    int? rejectedCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReviewPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'total': total,
      'draftCount': draftCount,
      'verifiedCount': verifiedCount,
      'rejectedCount': rejectedCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReviewPage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'total': total,
      'draftCount': draftCount,
      'verifiedCount': verifiedCount,
      'rejectedCount': rejectedCount,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _ReviewPageImpl extends ReviewPage {
  _ReviewPageImpl({
    required List<_ivhufo2l.ReviewItem> items,
    required int total,
    required int draftCount,
    required int verifiedCount,
    required int rejectedCount,
  }) : super._(
         items: items,
         total: total,
         draftCount: draftCount,
         verifiedCount: verifiedCount,
         rejectedCount: rejectedCount,
       );

  /// Returns a shallow copy of this [ReviewPage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ReviewPage copyWith({
    List<_ivhufo2l.ReviewItem>? items,
    int? total,
    int? draftCount,
    int? verifiedCount,
    int? rejectedCount,
  }) {
    return ReviewPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      total: total ?? this.total,
      draftCount: draftCount ?? this.draftCount,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
    );
  }
}
