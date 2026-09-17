import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/dart_values.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/company_changes.dart';
import 'package:test/test.dart';

void main() {
  group('DartValues', () {
    test('text: 공백·빈 값·하이픈은 null', () {
      expect(DartValues.text('  삼성전자 '), '삼성전자');
      expect(DartValues.text(''), isNull);
      expect(DartValues.text('-'), isNull);
      expect(DartValues.text(null), isNull);
      expect(DartValues.text(12), isNull);
    });

    test('ymd: 유효한 날짜만 UTC 자정으로', () {
      expect(DartValues.ymd('19690113'), DateTime.utc(1969, 1, 13));
      expect(DartValues.ymd('00000000'), isNull);
      expect(DartValues.ymd('20230231'), isNull, reason: '존재하지 않는 날짜');
      expect(DartValues.ymd('20231301'), isNull);
      expect(DartValues.ymd('2023-01-01'), isNull);
      expect(DartValues.ymd(''), isNull);
    });

    test('month: 1~12만', () {
      expect(DartValues.month('12'), 12);
      expect(DartValues.month('03'), 3);
      expect(DartValues.month('13'), isNull);
      expect(DartValues.month('0'), isNull);
      expect(DartValues.month(null), isNull);
    });

    test('amount: 원 단위 정수만 BigInt로', () {
      expect(
        DartValues.amount('566942110000000'),
        BigInt.parse('566942110000000'),
      );
      expect(DartValues.amount('-1,234'), BigInt.from(-1234));
      expect(DartValues.amount('0'), BigInt.zero);
      expect(DartValues.amount(''), isNull);
      expect(DartValues.amount('-'), isNull);
      expect(DartValues.amount('12.5'), isNull, reason: '소수는 추측하지 않는다');
      expect(DartValues.amount(null), isNull);
      expect(DartValues.isInvalidAmount('12.5'), isTrue);
      expect(DartValues.isInvalidAmount(''), isFalse);
    });

    test('formatYmd', () {
      expect(DartValues.formatYmd(DateTime.utc(2026, 3, 1)), '20260301');
    });
  });

  group('CompanyChanges.diff', () {
    final before = Company(
      corpCode: '00126380',
      name: '삼성전자',
      ceoName: '갑',
      market: Market.kospi,
      establishedDate: DateTime.utc(1969, 1, 13),
      profileUpdatedAt: DateTime.utc(2026, 1, 1),
    );

    test('원천 필드 변경만 잡고 값은 정규화된 문자열로', () {
      final after = before.copyWith(
        ceoName: '을',
        market: Market.other,
        profileUpdatedAt: DateTime.utc(2026, 9, 1),
      );

      expect(CompanyChanges.diff(before, after), [
        (field: 'market', oldValue: 'kospi', newValue: 'other'),
        (field: 'ceoName', oldValue: '갑', newValue: '을'),
      ]);
    });

    test('날짜는 YYYY-MM-DD, 같으면 변경 없음', () {
      expect(CompanyChanges.diff(before, before.copyWith()), isEmpty);
      final after = before.copyWith(establishedDate: DateTime.utc(1969, 1, 14));
      expect(CompanyChanges.diff(before, after).single, (
        field: 'establishedDate',
        oldValue: '1969-01-13',
        newValue: '1969-01-14',
      ));
    });
  });
}
