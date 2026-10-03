import 'issuer_documents_feed.dart';
import 'issuer_financials_feed.dart';

/// Versioned, deliberately narrow interchange contract for licensed feeds.
/// Money is decimal strings in base currency, quantities are integer strings.
/// Ratios are calculated from these inputs, never supplied as opaque scores.
abstract final class ResearchFeed {
  static const kinds = {
    'issuerDocuments',
    'issuerFinancials',
    'consensus',
    'flows',
    'shorts',
    'insiders',
    'program',
    'credit',
    'lending',
  };

  static String text(Map row, String key, {int max = 160}) {
    final value = row[key];
    if (value is! String || value.trim().isEmpty || value.length > max) {
      throw FormatException('$key: 비어 있지 않은 문자열이 필요합니다.');
    }
    return value.trim();
  }

  static String date(Map row, String key) {
    final s = text(row, key, max: 10);
    final d = DateTime.tryParse(s);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) ||
        d == null ||
        d.toIso8601String().substring(0, 10) != s ||
        d.year < 1990 ||
        d.year > DateTime.now().year + 5) {
      throw FormatException('$key: 유효한 YYYY-MM-DD 날짜가 필요합니다.');
    }
    return s;
  }

  static String number(
    Map row,
    String key, {
    bool signed = true,
    bool integer = false,
  }) {
    final s = text(row, key, max: 40);
    final pattern = integer ? r'^-?\d+$' : r'^-?\d+(\.\d+)?$';
    final n = double.tryParse(s);
    if (!RegExp(pattern).hasMatch(s) ||
        n == null ||
        !n.isFinite ||
        (!signed && n < 0)) {
      throw FormatException('$key: ${signed ? "" : "0 이상 "}숫자 문자열이 필요합니다.');
    }
    return s;
  }

  static List<Map<String, dynamic>> validate(String kind, dynamic input) {
    if (kind == 'issuerDocuments') return IssuerDocumentsFeed.validate(input);
    if (kind == 'issuerFinancials') return IssuerFinancialsFeed.validate(input);
    if (!kinds.contains(kind)) throw const FormatException('지원하지 않는 자료 종류');
    if (input is! List || input.length > 5000) {
      throw const FormatException('rows는 최대 5,000개 배열이어야 합니다.');
    }
    final keys = <String>{};
    final rows = <Map<String, dynamic>>[];
    for (final raw in input) {
      if (raw is! Map) throw const FormatException('각 행은 객체여야 합니다.');
      final r = <String, dynamic>{'date': date(raw, 'date')};
      if (DateTime.parse(r['date']).isAfter(DateTime.now().toUtc())) {
        throw const FormatException('관측 기준일은 미래일 수 없습니다.');
      }
      switch (kind) {
        case 'consensus':
          r.addAll({
            'periodStart': date(raw, 'periodStart'),
            'periodEnd': date(raw, 'periodEnd'),
            'basis': text(raw, 'basis'),
            'metric': text(raw, 'metric'),
            'currency': text(raw, 'currency'),
            'contributors': raw['contributors'],
            'value': number(raw, 'value'),
          });
          if (!{'consolidated', 'separate'}.contains(r['basis']) ||
              !{
                'revenue',
                'operatingProfit',
                'netIncome',
                'eps',
                'targetPrice',
              }.contains(r['metric']) ||
              r['currency'] != 'KRW' ||
              r['contributors'] is! int ||
              r['contributors'] < 1 ||
              r['contributors'] > 1000 ||
              (r['periodStart'] as String).compareTo(r['periodEnd']) > 0 ||
              (r['metric'] == 'targetPrice' && double.parse(r['value']) <= 0)) {
            throw const FormatException('추정 기간·연결/별도·지표·KRW·참여기관 수를 확인하세요.');
          }
          // Share-specific estimates must identify the security.
          if ({'eps', 'targetPrice'}.contains(r['metric'])) {
            r['stockCode'] = text(raw, 'stockCode');
            if (!RegExp(r'^\d{6}$').hasMatch(r['stockCode'])) {
              throw const FormatException('주당 지표는 6자리 종목코드가 필요합니다.');
            }
          }
          if (raw['actual'] != null) {
            r['actual'] = number(raw, 'actual');
            r['announcedAt'] = date(raw, 'announcedAt');
            r['actualSourceUrl'] = text(raw, 'actualSourceUrl', max: 1000);
            final url = Uri.tryParse(r['actualSourceUrl']);
            if (url?.scheme != 'https' ||
                url?.host != 'dart.fss.or.kr' ||
                (r['date'] as String).compareTo(r['announcedAt']) >= 0 ||
                (r['announcedAt'] as String).compareTo(r['periodEnd']) < 0 ||
                DateTime.parse(r['announcedAt'])
                    .isAfter(DateTime.now().toUtc()) ||
                r['metric'] == 'targetPrice') {
              throw const FormatException(
                '서프라이즈는 발표 전 추정치와 발표 후 DART 실적 원문이 필요합니다.',
              );
            }
          }
        case 'flows':
          r['stockCode'] = text(raw, 'stockCode');
          for (final k in ['foreign', 'individual', 'institution']) {
            r[k] = number(raw, k, integer: true);
          }
        case 'shorts':
          r['stockCode'] = text(raw, 'stockCode');
          r['volume'] = number(raw, 'volume', signed: false, integer: true);
          r['totalVolume'] = number(
            raw,
            'totalVolume',
            signed: false,
            integer: true,
          );
          if (BigInt.parse(r['volume']) > BigInt.parse(r['totalVolume'])) {
            throw const FormatException('공매도 수량이 전체 거래량보다 큽니다.');
          }
        case 'program':
          r['stockCode'] = text(raw, 'stockCode');
          r['buyVolume'] = number(
            raw,
            'buyVolume',
            signed: false,
            integer: true,
          );
          r['sellVolume'] = number(
            raw,
            'sellVolume',
            signed: false,
            integer: true,
          );
          r['netVolume'] =
              (BigInt.parse(r['buyVolume']) - BigInt.parse(r['sellVolume']))
                  .toString();
        case 'credit':
        case 'lending':
          r['stockCode'] = text(raw, 'stockCode');
          r['balanceVolume'] = number(
            raw,
            'balanceVolume',
            signed: false,
            integer: true,
          );
        case 'insiders':
          r['reporter'] = text(raw, 'reporter');
          r['receipt'] = text(raw, 'receipt');
          if (!RegExp(r'^\d{14}$').hasMatch(r['receipt'])) {
            throw const FormatException('공시 접수번호가 올바르지 않습니다.');
          }
          r['holdings'] = number(raw, 'holdings', signed: false, integer: true);
          r['change'] = number(raw, 'change', integer: true);
      }
      if (r.containsKey('stockCode') &&
          !RegExp(r'^\d{6}$').hasMatch(r['stockCode'])) {
        throw const FormatException('6자리 종목코드가 필요합니다.');
      }
      final identity = [
        r['date'],
        r['periodStart'],
        r['periodEnd'],
        r['basis'],
        r['metric'],
        r['stockCode'],
        r['receipt'],
        r['reporter'],
      ].join('|');
      if (!keys.add(identity)) {
        throw const FormatException('같은 기준의 행이 중복되었습니다.');
      }
      rows.add(r);
    }
    rows.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return rows;
  }
}
