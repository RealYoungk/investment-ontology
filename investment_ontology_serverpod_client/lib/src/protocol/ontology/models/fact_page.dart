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
import '../../ontology/models/fact_item.dart' as _ine9j7ol;

/// 본문에서 뽑은 값의 검수 목록.
abstract class FactPage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  FactPage._({
    required this.items,
    required this.total,
    required this.draftCount,
    required this.verifiedCount,
    required this.rejectedCount,
  });

  factory FactPage({
    required List<_ine9j7ol.FactItem> items,
    required int total,
    required int draftCount,
    required int verifiedCount,
    required int rejectedCount,
  }) = _FactPageImpl;

  factory FactPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return FactPage(
      items: _ilkzeueu.Protocol().deserialize<List<_ine9j7ol.FactItem>>(
        jsonSerialization['items'],
      ),
      total: jsonSerialization['total'] as int,
      draftCount: jsonSerialization['draftCount'] as int,
      verifiedCount: jsonSerialization['verifiedCount'] as int,
      rejectedCount: jsonSerialization['rejectedCount'] as int,
    );
  }

  List<_ine9j7ol.FactItem> items;

  int total;

  int draftCount;

  int verifiedCount;

  int rejectedCount;

  /// Returns a shallow copy of this [FactPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  FactPage copyWith({
    List<_ine9j7ol.FactItem>? items,
    int? total,
    int? draftCount,
    int? verifiedCount,
    int? rejectedCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FactPage',
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
      '__className__': 'FactPage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'total': total,
      'draftCount': draftCount,
      'verifiedCount': verifiedCount,
      'rejectedCount': rejectedCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _FactPageImpl extends FactPage {
  _FactPageImpl({
    required List<_ine9j7ol.FactItem> items,
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

  /// Returns a shallow copy of this [FactPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  FactPage copyWith({
    List<_ine9j7ol.FactItem>? items,
    int? total,
    int? draftCount,
    int? verifiedCount,
    int? rejectedCount,
  }) {
    return FactPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      total: total ?? this.total,
      draftCount: draftCount ?? this.draftCount,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
    );
  }
}
