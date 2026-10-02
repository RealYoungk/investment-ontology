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
import '../../ontology/models/index_point.dart' as _ipppabto;
import '../../ontology/models/source.dart' as _i5ra8lvy;

/// Official daily observations; cache only, no shared ontology mutation.
abstract class MacroSeriesView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MacroSeriesView._({
    required this.seriesId,
    required this.name,
    required this.group,
    required this.unit,
    required this.rate,
    this.source,
    required this.points,
    required this.status,
    this.message,
  });

  factory MacroSeriesView({
    required String seriesId,
    required String name,
    required String group,
    required String unit,
    required bool rate,
    _i5ra8lvy.Source? source,
    required List<_ipppabto.IndexPoint> points,
    required String status,
    String? message,
  }) = _MacroSeriesViewImpl;

  factory MacroSeriesView.fromJson(Map<String, dynamic> jsonSerialization) {
    return MacroSeriesView(
      seriesId: jsonSerialization['seriesId'] as String,
      name: jsonSerialization['name'] as String,
      group: jsonSerialization['group'] as String,
      unit: jsonSerialization['unit'] as String,
      rate: _isc.BoolJsonExtension.fromJson(jsonSerialization['rate']),
      source: jsonSerialization['source'] == null
          ? null
          : _ilkzeueu.Protocol().deserialize<_i5ra8lvy.Source>(
              jsonSerialization['source'],
            ),
      points: _ilkzeueu.Protocol().deserialize<List<_ipppabto.IndexPoint>>(
        jsonSerialization['points'],
      ),
      status: jsonSerialization['status'] as String,
      message: jsonSerialization['message'] as String?,
    );
  }

  String seriesId;

  String name;

  String group;

  String unit;

  bool rate;

  _i5ra8lvy.Source? source;

  List<_ipppabto.IndexPoint> points;

  String status;

  String? message;

  /// Returns a shallow copy of this [MacroSeriesView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MacroSeriesView copyWith({
    String? seriesId,
    String? name,
    String? group,
    String? unit,
    bool? rate,
    _i5ra8lvy.Source? source,
    List<_ipppabto.IndexPoint>? points,
    String? status,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MacroSeriesView',
      'seriesId': seriesId,
      'name': name,
      'group': group,
      'unit': unit,
      'rate': rate,
      if (source != null) 'source': source?.toJson(),
      'points': points.toJson(valueToJson: (v) => v.toJson()),
      'status': status,
      if (message != null) 'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MacroSeriesView',
      'seriesId': seriesId,
      'name': name,
      'group': group,
      'unit': unit,
      'rate': rate,
      if (source != null) 'source': source?.toJsonForProtocol(),
      'points': points.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'status': status,
      if (message != null) 'message': message,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MacroSeriesViewImpl extends MacroSeriesView {
  _MacroSeriesViewImpl({
    required String seriesId,
    required String name,
    required String group,
    required String unit,
    required bool rate,
    _i5ra8lvy.Source? source,
    required List<_ipppabto.IndexPoint> points,
    required String status,
    String? message,
  }) : super._(
         seriesId: seriesId,
         name: name,
         group: group,
         unit: unit,
         rate: rate,
         source: source,
         points: points,
         status: status,
         message: message,
       );

  /// Returns a shallow copy of this [MacroSeriesView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MacroSeriesView copyWith({
    String? seriesId,
    String? name,
    String? group,
    String? unit,
    bool? rate,
    Object? source = _Undefined,
    List<_ipppabto.IndexPoint>? points,
    String? status,
    Object? message = _Undefined,
  }) {
    return MacroSeriesView(
      seriesId: seriesId ?? this.seriesId,
      name: name ?? this.name,
      group: group ?? this.group,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      source: source is _i5ra8lvy.Source? ? source : this.source?.copyWith(),
      points: points ?? this.points.map((e0) => e0.copyWith()).toList(),
      status: status ?? this.status,
      message: message is String? ? message : this.message,
    );
  }
}
