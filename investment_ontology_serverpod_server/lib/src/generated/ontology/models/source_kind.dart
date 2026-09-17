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

enum SourceKind implements _is.SerializableModel {
  dartApi,
  dartReport,
  krxApi,

  /// 공공데이터포털 (금융위원회 주식시세정보·KRX상장종목정보)
  dataGoKrApi,
  officialFile,
  manual;

  static SourceKind fromJson(String name) {
    switch (name) {
      case 'dartApi':
        return SourceKind.dartApi;
      case 'dartReport':
        return SourceKind.dartReport;
      case 'krxApi':
        return SourceKind.krxApi;
      case 'dataGoKrApi':
        return SourceKind.dataGoKrApi;
      case 'officialFile':
        return SourceKind.officialFile;
      case 'manual':
        return SourceKind.manual;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SourceKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
