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

/// 주요정보의 이름을 기업·인물에 연결한 근거. 추정(ownershipCluster)은 화면에 따로 표시한다.
enum DisclosureLinkBasis implements _is.SerializableModel {
  /// 이름(법인 형태·각주·공백 제거)이 상장사 한 곳과 정확히 같음
  companyName,

  /// 같은 보고서의 임원 현황에 같은 이름의 임원이 한 명
  executiveSameReport,

  /// 지분으로 이어진 기업 묶음의 여러 회사 주주 명단에 같은 이름이 특수관계인으로 나옴 (추정)
  ownershipCluster;

  static DisclosureLinkBasis fromJson(String name) {
    switch (name) {
      case 'companyName':
        return DisclosureLinkBasis.companyName;
      case 'executiveSameReport':
        return DisclosureLinkBasis.executiveSameReport;
      case 'ownershipCluster':
        return DisclosureLinkBasis.ownershipCluster;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DisclosureLinkBasis"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
