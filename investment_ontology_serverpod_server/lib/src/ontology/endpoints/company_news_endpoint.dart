import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../api_secret.dart';
import '../dart/dart_api_key.dart';
import '../ingest/api_call_budget.dart';
import '../news/company_news_service.dart';
import '../news/google_news_service.dart';

class CompanyNewsEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;
  static final _service = CompanyNewsService();
  static const _id = ApiSecret(
    passwordName: 'naverClientId',
    envName: 'NAVER_CLIENT_ID',
  );
  static const _secret = ApiSecret(
    passwordName: 'naverClientSecret',
    envName: 'NAVER_CLIENT_SECRET',
  );

  Future<CompanyNewsFeed> recent(Session session, String corpCode) async {
    if (!RegExp(r'^\d{8}$').hasMatch(corpCode)) {
      throw ArgumentError('Invalid company code');
    }
    final company = await Company.db.findFirstRow(
      session,
      where: (t) => t.corpCode.equals(corpCode),
    );
    if (company == null) throw ArgumentError('Company not found');
    final id = _id.read(session),
        secret = _secret.read(session),
        dartKey = DartApiKey.read(session);
    // Credentials are never stored in the cache key or returned to the client.
    final key = '$corpCode:${id != null && secret != null}:${dartKey != null}';
    return _service.read(key, () async {
      final now = DateTime.now().toUtc();
      final newsClient = http.Client(),
          filingClient = http.Client(),
          googleClient = http.Client();
      var newsStatus = 'ok', filingStatus = 'ok';
      var googleSucceeded = false;
      final items = <CompanyNewsItem>[];
      try {
        await Future.wait([
          () async {
            if (id == null || secret == null) {
              newsStatus = 'notConfigured';
              return;
            }
            try {
              final name = (company.stockName ?? company.name)
                  .replaceAll(RegExp(r'주식회사|\(주\)|㈜'), '')
                  .trim();
              items.addAll(
                await CompanyNewsService.naver(
                  newsClient,
                  name,
                  id,
                  secret,
                  now,
                  stockCode: company.stockCode,
                  ceoName: company.ceoName,
                ),
              );
            } catch (_) {
              newsStatus = 'failed';
            }
          }(),
          () async {
            try {
              final name = (company.stockName ?? company.name)
                  .replaceAll(RegExp(r'주식회사|\(주\)|㈜'), '')
                  .trim();
              items.addAll(
                await GoogleNewsService.read(
                  googleClient,
                  name,
                  now,
                  stockCode: company.stockCode,
                  ceoName: company.ceoName,
                ),
              );
              googleSucceeded = true;
              session.log(
                'Company news RSS fetched for $corpCode: ${items.where((i) => i.publisher != 'DART').length} articles',
              );
            } catch (error) {
              session.log(
                'Company news RSS unavailable for $corpCode: ${error.runtimeType}',
              );
              // NAVER remains available when the supplementary RSS fails.
            }
          }(),
          () async {
            if (dartKey == null) {
              filingStatus = 'notConfigured';
              return;
            }
            try {
              if (await ApiCallBudget.reached(
                session,
                ApiProvider.dart,
                ApiCallBudget.dartDailyLimit,
              )) {
                filingStatus = 'failed';
                return;
              }
              await ApiCallBudget.record(session, ApiProvider.dart, 1);
              final res = await filingClient
                  .get(
                    Uri.https('opendart.fss.or.kr', '/api/list.json', {
                      'crtfc_key': dartKey,
                      'corp_code': corpCode,
                      'bgn_de': ApiCallBudget.kstDay(
                        now.subtract(const Duration(days: 90)),
                      ).replaceAll('-', ''),
                      'end_de': ApiCallBudget.kstDay(now).replaceAll('-', ''),
                      'sort': 'date',
                      'sort_mth': 'desc',
                      'page_count': '100',
                      'last_reprt_at': 'N',
                    }),
                  )
                  .timeout(const Duration(seconds: 8));
              if (res.statusCode != 200) {
                throw const FormatException('DART HTTP error');
              }
              final body = jsonDecode(res.body) as Map<String, dynamic>;
              if (body['status'] == '013') return;
              if (body['status'] != '000' || body['list'] is! List) {
                throw const FormatException('DART error');
              }
              for (final row in body['list'] as List) {
                if (row is! Map || row['corp_code'] != corpCode) continue;
                final receipt = row['rcept_no'],
                    date = row['rcept_dt'],
                    title = row['report_nm'];
                if (receipt is! String ||
                    !RegExp(r'^\d{14}$').hasMatch(receipt) ||
                    date is! String ||
                    title is! String) {
                  continue;
                }
                final published = DateTime.tryParse(date);
                if (published == null) continue;
                items.add(
                  CompanyNewsItem(
                    title: title,
                    excerpt: '',
                    url:
                        'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
                    publishedAt: DateTime.utc(
                      published.year,
                      published.month,
                      published.day,
                    ).subtract(const Duration(hours: 9)),
                    category: CompanyNewsService.category(title),
                    publisher: 'DART',
                    relatedUrls: [],
                  ),
                );
              }
            } catch (_) {
              filingStatus = 'failed';
            }
          }(),
        ]);
      } finally {
        newsClient.close();
        googleClient.close();
        filingClient.close();
      }
      return CompanyNewsFeed(
        items: [
          ...CompanyNewsService.organize(
            items.where((item) => item.publisher != 'DART').toList(),
          ),
          ...CompanyNewsService.organize(
            items.where((item) => item.publisher == 'DART').toList(),
          ).take(5),
        ],
        fetchedAt: DateTime.now().toUtc(),
        newsStatus: googleSucceeded ? 'ok' : newsStatus,
        filingStatus: filingStatus,
      );
    });
  }
}
