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

/// 사업보고서 본문에서 뽑는 값의 종류. API로는 받을 수 없고 글·표에만 있는 것들.
enum DocumentFactKind implements _is.SerializableModel {
  /// 수주총액 (계약 총액)
  orderTotal,

  /// 기납품액 (이미 매출로 인식한 부분)
  orderDelivered,

  /// 수주잔고 (남은 계약 잔액)
  orderBacklog,

  /// 생산능력
  capacity,

  /// 생산실적
  production,

  /// 가동률 (%)
  utilization,

  /// 시장점유율 (%)
  marketShare,

  /// 회사가 공시한 앞으로의 투자 계획 (CAPEX·R&D 등). 예측이 아니라 회사 발표다
  investmentPlan,

  /// 실제 집행한 투자액
  investmentActual;

  static DocumentFactKind fromJson(String name) {
    switch (name) {
      case 'orderTotal':
        return DocumentFactKind.orderTotal;
      case 'orderDelivered':
        return DocumentFactKind.orderDelivered;
      case 'orderBacklog':
        return DocumentFactKind.orderBacklog;
      case 'capacity':
        return DocumentFactKind.capacity;
      case 'production':
        return DocumentFactKind.production;
      case 'utilization':
        return DocumentFactKind.utilization;
      case 'marketShare':
        return DocumentFactKind.marketShare;
      case 'investmentPlan':
        return DocumentFactKind.investmentPlan;
      case 'investmentActual':
        return DocumentFactKind.investmentActual;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DocumentFactKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
