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

abstract class DisclosureTableRow
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DisclosureTableRow._({
    required this.isTotal,
    required this.cells,
  });

  factory DisclosureTableRow({
    required bool isTotal,
    required List<String?> cells,
  }) = _DisclosureTableRowImpl;

  factory DisclosureTableRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return DisclosureTableRow(
      isTotal: _is.BoolJsonExtension.fromJson(jsonSerialization['isTotal']),
      cells: _i4yshtjp.Protocol().deserialize<List<String?>>(
        jsonSerialization['cells'],
      ),
    );
  }

  bool isTotal;

  List<String?> cells;

  /// Returns a shallow copy of this [DisclosureTableRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DisclosureTableRow copyWith({
    bool? isTotal,
    List<String?>? cells,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DisclosureTableRow',
      'isTotal': isTotal,
      'cells': cells.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DisclosureTableRow',
      'isTotal': isTotal,
      'cells': cells.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DisclosureTableRowImpl extends DisclosureTableRow {
  _DisclosureTableRowImpl({
    required bool isTotal,
    required List<String?> cells,
  }) : super._(
         isTotal: isTotal,
         cells: cells,
       );

  /// Returns a shallow copy of this [DisclosureTableRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DisclosureTableRow copyWith({
    bool? isTotal,
    List<String?>? cells,
  }) {
    return DisclosureTableRow(
      isTotal: isTotal ?? this.isTotal,
      cells: cells ?? this.cells.map((e0) => e0).toList(),
    );
  }
}
