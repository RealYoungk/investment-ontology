import '../../generated/protocol.dart';

/// 바뀐 필드 하나.
typedef FieldChange = ({String field, String? oldValue, String? newValue});

/// 기업개황에서 온 필드의 변경 비교.
abstract final class CompanyChanges {
  /// 원천(DART 기업개황)에서 오는 필드만 비교한다. 수집 메타 필드는 제외.
  static final Map<String, Object? Function(Company)> _tracked = {
    'name': (c) => c.name,
    'nameEng': (c) => c.nameEng,
    'stockName': (c) => c.stockName,
    'stockCode': (c) => c.stockCode,
    'market': (c) => c.market,
    'ceoName': (c) => c.ceoName,
    'jurirNo': (c) => c.jurirNo,
    'bizrNo': (c) => c.bizrNo,
    'address': (c) => c.address,
    'homepageUrl': (c) => c.homepageUrl,
    'irUrl': (c) => c.irUrl,
    'phone': (c) => c.phone,
    'industryCode': (c) => c.industryCode,
    'establishedDate': (c) => c.establishedDate,
    'fiscalMonth': (c) => c.fiscalMonth,
  };

  static List<FieldChange> diff(Company before, Company after) => [
    for (final MapEntry(key: field, value: get) in _tracked.entries)
      if (_format(get(before)) != _format(get(after)))
        (
          field: field,
          oldValue: _format(get(before)),
          newValue: _format(get(after)),
        ),
  ];

  static String? _format(Object? value) => switch (value) {
    null => null,
    DateTime d =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}',
    Enum e => e.name,
    _ => '$value',
  };
}
