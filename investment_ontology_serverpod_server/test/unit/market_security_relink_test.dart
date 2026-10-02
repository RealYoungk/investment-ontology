import 'package:investment_ontology_serverpod_server/src/generated/protocol.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/ingest/market_security_relink.dart';
import 'package:test/test.dart';

Company company(
  int id, {
  String? number = '123-45',
  String? code = '005930',
  Market market = Market.kospi,
}) => Company(
  id: id,
  corpCode: '$id',
  name: '기업',
  market: market,
  jurirNo: number,
  stockCode: code,
);
Security security(
  int id, {
  String? number = '12345',
  String code = '005930',
  int? companyId,
}) => Security(
  id: id,
  isinCode: 'KR$id',
  shortCode: code,
  name: '종목',
  crno: number,
  companyId: companyId,
  lastSeenDate: DateTime.utc(2026, 10, 1),
);

void main() {
  test(
    'both unique master identifiers agree; preferred shares link by crno',
    () {
      final securities = [security(11), security(12, code: '005935')];
      final companies = [company(1)];
      expect(MarketSecurityRelink.matches(companies, securities), {
        11: SecurityLinkBasis.crno,
        12: SecurityLinkBasis.crno,
      });
      expect(
        MarketSecurityRelink.companyFor(
          securities[1],
          companies,
          SecurityLinkBasis.crno,
        ),
        1,
      );
      expect(securities[0].companyId, isNull);
    },
  );
  test('stock-code fallback does not guess from name or ISIN', () {
    expect(
      MarketSecurityRelink.matches(
        [company(1, number: null)],
        [
          security(1, number: '0000'),
          security(2, code: '999999', number: null),
        ],
      ),
      {1: SecurityLinkBasis.dartStockCode},
    );
  });
  test('conflicting or duplicated identifiers remain unlinked', () {
    expect(
      MarketSecurityRelink.matches(
        [company(1, code: '111111'), company(2, number: '77777')],
        [security(1)],
      ),
      isEmpty,
    );
    expect(
      MarketSecurityRelink.matches(
        [company(1), company(2, code: '111111')],
        [security(1)],
      ),
      isEmpty,
    );
    expect(
      MarketSecurityRelink.matches(
        [company(1), company(2, number: null)],
        [security(1)],
      ),
      isEmpty,
    );
  });
  test('unlisted company and already linked security are never reassigned', () {
    expect(
      MarketSecurityRelink.matches(
        [company(1, market: Market.other)],
        [security(1)],
      ),
      isEmpty,
    );
    expect(
      MarketSecurityRelink.matches([company(1)], [security(1, companyId: 9)]),
      isEmpty,
    );
  });
}
