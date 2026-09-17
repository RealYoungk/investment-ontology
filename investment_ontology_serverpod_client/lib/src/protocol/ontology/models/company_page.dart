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
import '../../ontology/models/company_list_item.dart' as _i5wxl3z7;

abstract class CompanyPage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  CompanyPage._({
    required this.items,
    required this.total,
  });

  factory CompanyPage({
    required List<_i5wxl3z7.CompanyListItem> items,
    required int total,
  }) = _CompanyPageImpl;

  factory CompanyPage.fromJson(Map<String, dynamic> jsonSerialization) {
    return CompanyPage(
      items: _ilkzeueu.Protocol().deserialize<List<_i5wxl3z7.CompanyListItem>>(
        jsonSerialization['items'],
      ),
      total: jsonSerialization['total'] as int,
    );
  }

  List<_i5wxl3z7.CompanyListItem> items;

  int total;

  /// Returns a shallow copy of this [CompanyPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  CompanyPage copyWith({
    List<_i5wxl3z7.CompanyListItem>? items,
    int? total,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CompanyPage',
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'total': total,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CompanyPage',
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'total': total,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _CompanyPageImpl extends CompanyPage {
  _CompanyPageImpl({
    required List<_i5wxl3z7.CompanyListItem> items,
    required int total,
  }) : super._(
         items: items,
         total: total,
       );

  /// Returns a shallow copy of this [CompanyPage]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  CompanyPage copyWith({
    List<_i5wxl3z7.CompanyListItem>? items,
    int? total,
  }) {
    return CompanyPage(
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      total: total ?? this.total,
    );
  }
}
