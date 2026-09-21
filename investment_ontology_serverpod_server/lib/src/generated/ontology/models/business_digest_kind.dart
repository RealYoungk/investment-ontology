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

/// 사업보고서 "사업의 내용"을 읽기 좋게 녹인 절의 종류. 화면에 이 순서로 놓는다.
enum BusinessDigestKind implements _is.SerializableModel {
  /// 무엇을 하는 회사인가 (사업 개요)
  overview,

  /// 주요 제품·서비스와 매출 구성
  products,

  /// 원재료·공급망·매입처
  supplyChain,

  /// 생산능력·가동률·설비
  production,

  /// 판매·수주·주요 매출처
  sales,

  /// 시장 환경·경쟁·점유율
  market,

  /// 연구개발·투자
  rnd,

  /// 위험 요인·규제
  risks,

  /// 그 밖에 투자자가 알아야 할 것
  other;

  static BusinessDigestKind fromJson(String name) {
    switch (name) {
      case 'overview':
        return BusinessDigestKind.overview;
      case 'products':
        return BusinessDigestKind.products;
      case 'supplyChain':
        return BusinessDigestKind.supplyChain;
      case 'production':
        return BusinessDigestKind.production;
      case 'sales':
        return BusinessDigestKind.sales;
      case 'market':
        return BusinessDigestKind.market;
      case 'rnd':
        return BusinessDigestKind.rnd;
      case 'risks':
        return BusinessDigestKind.risks;
      case 'other':
        return BusinessDigestKind.other;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "BusinessDigestKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
