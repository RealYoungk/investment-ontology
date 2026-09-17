import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/data_go_kr/data_go_kr_client.dart';
import 'package:test/test.dart';

DataGoKrClient client(
  String body, {
  int status = 200,
  void Function(http.Request)? onRequest,
}) => DataGoKrClient(
  'dec/key+==',
  httpClient: MockClient((req) async {
    onRequest?.call(req);
    return http.Response.bytes(utf8.encode(body), status);
  }),
);

String page(Object? items, {int total = 1, int pageNo = 1}) => jsonEncode({
  'response': {
    'header': {'resultCode': '00', 'resultMsg': 'NORMAL SERVICE.'},
    'body': {
      'numOfRows': 1000,
      'pageNo': pageNo,
      'totalCount': total,
      'items': items,
    },
  },
});

void main() {
  group('DataGoKrClient', () {
    test('시세 목록과 요청 파라미터', () async {
      late Uri url;
      final result = await client(
        page({
          'item': [
            {
              'basDt': '20260916',
              'srtnCd': '005930',
              'isinCd': 'KR7005930003',
              'itmsNm': '삼성전자',
              'mrktCtg': 'KOSPI',
              'clpr': '71000',
              'mrktTotAmt': '423850000000000',
            },
          ],
        }),
        onRequest: (req) => url = req.url,
      ).fetchStockPrices(DateTime.utc(2026, 9, 16));

      expect(url.path, endsWith('getStockPriceInfo'));
      expect(url.queryParameters['serviceKey'], 'dec/key+==');
      expect(url.queryParameters['basDt'], '20260916');
      expect(url.queryParameters['resultType'], 'json');
      expect(result.items.single['isinCd'], 'KR7005930003');
      expect(result.isLast, isTrue);
    });

    test('항목이 한 건이면 객체, 없으면 빈 문자열로 온다', () async {
      final one = await client(
        page({
          'item': {'isinCd': 'KR7005930003'},
        }),
      ).fetchListedItems(DateTime.utc(2026, 9, 16));
      expect(one.items, hasLength(1));

      final none = await client(
        page('', total: 0),
      ).fetchStockPrices(DateTime.utc(2026, 9, 13));
      expect(none.items, isEmpty);
    });

    test('키 오류는 XML로 와도 치명적 오류', () async {
      await expectLater(
        client(
          '<OpenAPI_ServiceResponse><cmmMsgHeader><errMsg>SERVICE ERROR</errMsg>'
          '<returnAuthMsg>SERVICE_KEY_IS_NOT_REGISTERED_ERROR</returnAuthMsg>'
          '<returnReasonCode>30</returnReasonCode></cmmMsgHeader></OpenAPI_ServiceResponse>',
        ).fetchStockPrices(DateTime.utc(2026, 9, 16)),
        throwsA(
          isA<DataGoKrApiException>()
              .having((e) => e.code, 'code', '30')
              .having((e) => e.isFatal, 'isFatal', isTrue),
        ),
      );
    });

    test('HTTP 401은 치명적, 500은 계속 호출 가능', () async {
      await expectLater(
        client(
          'Unauthorized',
          status: 401,
        ).fetchStockPrices(DateTime.utc(2026, 9, 16)),
        throwsA(
          isA<DataGoKrApiException>().having(
            (e) => e.isFatal,
            'isFatal',
            isTrue,
          ),
        ),
      );
      await expectLater(
        client('err', status: 500).fetchStockPrices(DateTime.utc(2026, 9, 16)),
        throwsA(
          isA<DataGoKrApiException>().having(
            (e) => e.isFatal,
            'isFatal',
            isFalse,
          ),
        ),
      );
    });

    test('Source용 주소에는 서비스키가 없다', () {
      final url = DataGoKrClient.publicUrl(
        DataGoKrClient.stockPricePath,
        DateTime.utc(2026, 9, 16),
      );
      expect(url.queryParameters.keys, ['basDt']);
    });
  });
}
