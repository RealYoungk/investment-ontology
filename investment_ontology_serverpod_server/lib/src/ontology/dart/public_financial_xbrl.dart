import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// Exact-receipt official annual XBRL. This is a bounded fallback for API
/// period mismatches, not a substitute for an empty OpenDART response.
class PublicFinancialXbrl {
  PublicFinancialXbrl(this.client);
  final http.Client client;

  Future<({List<int> zip, Uri source})> fetch(String receipt) async {
    if (!RegExp(r'^\d{14}$').hasMatch(receipt)) {
      throw const FormatException('Invalid receipt');
    }
    String? cookie;
    Future<http.Response> get(Uri uri, {Uri? referer}) async {
      final response = await client
          .get(
            uri,
            headers: {
              'User-Agent': 'InvestmentOntology/1.0',
              if (cookie != null) 'Cookie': cookie!,
              if (referer != null) 'Referer': referer.toString(),
            },
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 ||
          (response.request?.url.host ?? uri.host) != 'dart.fss.or.kr') {
        throw const FormatException('Invalid official XBRL response');
      }
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) cookie = setCookie.split(';').first;
      return response;
    }

    final shellUri = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': receipt,
    });
    final shell = utf8.decode((await get(shellUri)).bodyBytes);
    final doc = RegExp("openPdfDownload\\('$receipt',\\s*'(\\d+)'\\)")
        .firstMatch(shell)
        ?.group(1);
    if (doc == null) throw const FormatException('No receipt-bound download');
    final listingUri = Uri.https('dart.fss.or.kr', '/pdf/download/main.do', {
      'rcp_no': receipt,
      'dcm_no': doc,
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    final listing = utf8.decode(
      (await get(listingUri, referer: shellUri)).bodyBytes,
    );
    final links = RegExp(r'href=["\x27]([^"\x27]+)["\x27]')
        .allMatches(listing)
        .map((m) => listingUri.resolve(m.group(1)!.replaceAll('&amp;', '&')))
        .where(
          (u) =>
              u.host == 'dart.fss.or.kr' &&
              u.path == '/pdf/download/ifrs.do' &&
              u.queryParameters['rcp_no'] == receipt &&
              u.queryParameters['dcm_no'] == doc,
        )
        .toList();
    if (links.length != 1) {
      throw const FormatException('Ambiguous exact XBRL download');
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    final zip = (await get(links.single, referer: listingUri)).bodyBytes;
    if (zip.length > 20 * 1024 * 1024) {
      throw const FormatException('XBRL archive too large');
    }
    return (zip: zip, source: links.single);
  }

  static String digest(List<int> zip) => sha256.convert(zip).toString();

  /// Only whole-company, unrounded KRW core-account facts are admitted.
  /// Extra segment/equity dimensions and nonannual contexts are excluded.
  static List<Map<String, dynamic>> parse(
    List<int> zip, {
    required String receipt,
    required String corpCode,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) {
    if (periodEnd.year != bsnsYear) {
      throw const FormatException('Annual fiscal year mismatch');
    }
    final archive = ZipDecoder().decodeBytes(zip);
    final instances = archive.files
        .where((f) => f.name.endsWith('.xbrl'))
        .toList();
    if (instances.length != 1 || instances.single.size > 20 * 1024 * 1024) {
      throw const FormatException('Expected one bounded XBRL instance');
    }
    final root = XmlDocument.parse(utf8.decode(instances.single.content))
        .rootElement;
    const xbrli = 'http://www.xbrl.org/2003/instance';
    if (root.name.local != 'xbrl' || root.namespaceUri != xbrli) {
      throw const FormatException('Not XBRL');
    }
    final end = periodEnd.toIso8601String().substring(0, 10);
    final start = DateTime.utc(
      periodEnd.year - 1,
      periodEnd.month + 1,
      1,
    ).toIso8601String().substring(0, 10);
    final expectedMember = consolidated
        ? 'ConsolidatedMember'
        : 'SeparateMember';
    final contexts = <String, bool>{};
    for (final c in root.findElements('context', namespaceUri: xbrli)) {
      final identifiers = c.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'identifier')
          .toList();
      if (identifiers.length != 1 ||
          identifiers.single.innerText != corpCode ||
          identifiers.single.getAttribute('scheme') !=
              'http://dart.fss.or.kr/ifrs/CIK') {
        throw const FormatException('XBRL entity mismatch');
      }
      final dimensions = c.descendants
          .whereType<XmlElement>()
          .where(
            (e) =>
                e.name.local == 'explicitMember' ||
                e.name.local == 'typedMember',
          )
          .toList();
      if (dimensions.length != 1) continue;
      final d = dimensions.single;
      String local(String value) => value.split(':').last;
      if (!((root.getAttribute('xmlns:ifrs-full') ?? '').startsWith(
            'http://xbrl.ifrs.org/taxonomy/',
          )) ||
          !(d.getAttribute('dimension') ?? '').startsWith('ifrs-full:') ||
          !d.innerText.startsWith('ifrs-full:') ||
          local(d.getAttribute('dimension') ?? '') !=
              'ConsolidatedAndSeparateFinancialStatementsAxis' ||
          local(d.innerText) != expectedMember) {
        continue;
      }
      final dates = {
        for (final e in c.descendants.whereType<XmlElement>())
          e.name.local: e.innerText,
      };
      final instant = dates['instant'];
      if (instant == end) contexts[c.getAttribute('id')!] = true;
      if (dates['startDate'] == start && dates['endDate'] == end) {
        contexts[c.getAttribute('id')!] = false;
      }
    }
    final units = {
      for (final u in root.findElements('unit', namespaceUri: xbrli))
        u.getAttribute('id')!: u.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'measure')
            .map((e) => e.innerText)
            .toList(),
    };
    const accounts = <String, (String, String, bool)>{
      'Assets': ('BS', '자산총계', true),
      'Liabilities': ('BS', '부채총계', true),
      'Equity': ('BS', '자본총계', true),
      'Revenue': ('CIS', '매출액', false),
      'RevenueFromContractsWithCustomers': ('CIS', '매출액', false),
      'OperatingIncomeLoss': ('CIS', '영업이익', false),
      'ProfitLossFromOperatingActivities': ('CIS', '영업이익', false),
      'ProfitLoss': ('CIS', '당기순이익', false),
      'CashFlowsFromUsedInOperatingActivities': ('CF', '영업활동 현금흐름', false),
      'PurchaseOfPropertyPlantAndEquipmentClassifiedAsInvestingActivities': (
        'CF',
        '유형자산의 취득',
        false,
      ),
    };
    final values = <String, Map<String, dynamic>>{};
    for (final f in root.children.whereType<XmlElement>()) {
      final account = accounts[f.name.local];
      final ns = f.namespaceUri ?? '';
      final isDart =
          ns.startsWith('http://dart.fss.or.kr/taxonomy/') &&
          ns.endsWith('/ifrs/dart');
      final isIfrs =
          ns.startsWith('http://xbrl.ifrs.org/taxonomy/') &&
          ns.endsWith('/ifrs-full');
      if (account == null ||
          (!isDart && !isIfrs) ||
          (f.name.local == 'OperatingIncomeLoss' && !isDart) ||
          contexts[f.getAttribute('contextRef')] != account.$3) {
        continue;
      }
      final measures = units[f.getAttribute('unitRef')];
      if (measures == null ||
          measures.length != 1 ||
          measures.single != 'iso4217:KRW' ||
          root.getAttribute('xmlns:iso4217') !=
              'http://www.xbrl.org/2003/iso4217' ||
          !const ['0', 'INF'].contains(f.getAttribute('decimals')) ||
          !RegExp(r'^-?\d+$').hasMatch(f.innerText.trim())) {
        throw const FormatException(
          'Unsupported XBRL monetary unit or precision',
        );
      }
      final id = '${isDart ? 'dart' : 'ifrs-full'}_${f.name.local}';
      final value = f.innerText.trim();
      if (values[id] case final previous?) {
        if (previous['thstrm_amount'] != value) {
          throw const FormatException('Conflicting whole-company XBRL facts');
        }
        continue;
      }
      values[id] = {
        'rcept_no': receipt,
        'corp_code': corpCode,
        'bsns_year': '$bsnsYear',
        'reprt_code': '11011',
        'account_id': id,
        'account_nm': account.$2,
        'account_detail': '-',
        'sj_div': account.$1,
        'thstrm_nm': '$start~$end',
        'thstrm_amount': value,
        'currency': 'KRW',
      };
    }
    if (!values.containsKey('ifrs-full_Assets') ||
        !values.containsKey('ifrs-full_ProfitLoss')) {
      throw const FormatException('Current annual core contexts missing');
    }
    return values.values.toList();
  }
}
