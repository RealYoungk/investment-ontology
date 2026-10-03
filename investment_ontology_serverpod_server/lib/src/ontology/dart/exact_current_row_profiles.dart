import '../../generated/protocol.dart';

typedef ExactCurrentRowProfile = ({
  String sha,
  int tableCount,
  List<(String, int, int, int, List<int>)> mappings,
  List<String> ceDetails,
  List<(int, int)> labelOnlyRows,
});

/// Independently checked physical coordinates of five specific source bodies.
/// No amount literals, inferred historical columns, or general parser permission.
abstract final class ExactCurrentRowProfiles {
  static const receipts = {
    '20240320001114',
    '20250314001145',
    '20250321000964',
    '20250321001653',
    '20250321001825',
  };
  static ExactCurrentRowProfile? find(String receipt, FsDiv basis) =>
      profiles['$receipt:${basis.name}'];
  static const profiles = <String, ExactCurrentRowProfile>{
    '20240320001114:separate': (
      sha: '9110f37f8661c11afa7d6f6f58e6e82e3ce5a9f0238714615e4e702bad7a3fe7',
      tableCount: 8,
      labelOnlyRows: [],
      mappings: [
        ('BS', 1, 1, 35, [1]),
        ('CIS', 3, 1, 26, [1]),
        ('SCE', 5, 22, 34, [1, 2, 3, 4, 5, 6, 7, 8]),
        ('CF', 7, 1, 29, [1]),
      ],
      ceDetails: [
        '지배기업의 소유주지분 > 자본금',
        '지배기업의 소유주지분 > 자본잉여금',
        '지배기업의 소유주지분 > 결손금',
        '지배기업의 소유주지분 > 기타포괄손익 누계액',
        '지배기업의 소유주지분 > 기타자본항목',
        '지배기업의 소유주지분 > 합계',
        '비지배지분',
        '자본 총계',
      ],
    ),
    '20250314001145:separate': (
      sha: 'a701d4cd0384c426d5e0ae44a2241c3ada604bc22bbf96956f3215c8cbb9ddfa',
      tableCount: 8,
      labelOnlyRows: [],
      mappings: [
        ('BS', 1, 1, 33, [1]),
        ('CIS', 3, 1, 26, [1]),
        ('SCE', 5, 25, 35, [1, 2, 3, 4, 5, 6, 7, 8]),
        ('CF', 7, 1, 27, [1]),
      ],
      ceDetails: [
        '지배기업의 소유주지분 > 자본금',
        '지배기업의 소유주지분 > 자본잉여금',
        '지배기업의 소유주지분 > 결손금',
        '지배기업의 소유주지분 > 기타포괄손익 누계액',
        '지배기업의 소유주지분 > 기타자본항목',
        '지배기업의 소유주지분 > 합계',
        '비지배지분',
        '자본 총계',
      ],
    ),
    '20250321000964:separate': (
      sha: '545fbbf353e384b73d1cd1085abbbe3ab00bce7832630071adb169d5dacb8a16',
      tableCount: 8,
      labelOnlyRows: [],
      mappings: [
        ('BS', 1, 1, 65, [1]),
        ('CIS', 3, 1, 66, [1]),
        ('SCE', 5, 11, 16, [1, 2, 3, 4, 5]),
        ('CF', 7, 1, 74, [1]),
      ],
      ceDetails: ['자 본 금', '자 본 잉여금', '자 본 조 정', '이 익 잉여금', '총 계'],
    ),
    '20250321001653:consolidated': (
      sha: 'd828c8db802a4c6ebff53a6ef24d076f9598d5dd6886517ad134c8ca74f5390b',
      tableCount: 8,
      labelOnlyRows: [(5, 22), (5, 24), (5, 28)],
      mappings: [
        ('BS', 1, 1, 46, [1]),
        ('CIS', 3, 1, 30, [1]),
        ('SCE', 5, 21, 31, [1, 2, 3, 4, 5, 6]),
        ('CF', 7, 1, 41, [1]),
      ],
      ceDetails: [
        '지배기업 소유주지분 > 자본금',
        '지배기업 소유주지분 > 자본잉여금',
        '지배기업 소유주지분 > 기타자본구성요소',
        '지배기업 소유주지분 > 결손금',
        '비지배지분',
        '총 계',
      ],
    ),
    '20250321001825:separate': (
      sha: 'c63592b1a91cd5bf858bbcde8f9855ca971f2cb0325aa1d7037d1265f22036b4',
      tableCount: 8,
      labelOnlyRows: [],
      mappings: [
        ('BS', 1, 1, 47, [1]),
        ('CIS', 3, 1, 21, [1]),
        ('SCE', 5, 16, 22, [1, 2, 3, 4, 5, 6]),
        ('CF', 7, 1, 33, [1]),
      ],
      ceDetails: ['자본금', '자본잉여금', '기타자본', '기타포괄손익', '이익잉여금 (결손금)', '합 계'],
    ),
  };
}
