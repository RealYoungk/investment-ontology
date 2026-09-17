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

/// 공시별 재무제표 수집 상태.
enum FilingFetchStatus implements _isc.SerializableModel {
  /// 아직 받지 않음
  pending,

  /// 저장함 (같은 접수번호를 이미 저장한 경우 포함)
  stored,

  /// DART에 해당 재무제표가 없음 (013)
  noData,

  /// 오류. 재시도 횟수 안에서 다시 받는다
  failed,

  /// 보고서 코드·사업연도를 판정할 수 없어 받지 않음 (리츠의 6개월 결산 등)
  unsupported;

  static FilingFetchStatus fromJson(String name) {
    switch (name) {
      case 'pending':
        return FilingFetchStatus.pending;
      case 'stored':
        return FilingFetchStatus.stored;
      case 'noData':
        return FilingFetchStatus.noData;
      case 'failed':
        return FilingFetchStatus.failed;
      case 'unsupported':
        return FilingFetchStatus.unsupported;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "FilingFetchStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
