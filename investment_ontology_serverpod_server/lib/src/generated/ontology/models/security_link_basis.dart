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

/// 종목을 기업에 연결한 근거. 모두 1차 출처의 식별자이고, 위에서부터 차례로 쓴다.
enum SecurityLinkBasis implements _is.SerializableModel {
  /// KRX상장종목정보의 법인등록번호 = DART 기업개황의 법인등록번호
  crno,

  /// 종목의 단축코드 = DART 기업개황의 종목코드 (법인등록번호가 없는 외국 기업 등)
  dartStockCode,

  /// ISIN의 발행체 코드(KR7 뒤 5자리)가 이미 연결된 종목과 같음 (상장종목정보에 없는 우선주)
  isinIssuer;

  static SecurityLinkBasis fromJson(String name) {
    switch (name) {
      case 'crno':
        return SecurityLinkBasis.crno;
      case 'dartStockCode':
        return SecurityLinkBasis.dartStockCode;
      case 'isinIssuer':
        return SecurityLinkBasis.isinIssuer;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SecurityLinkBasis"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
