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

  /// Resolve only an explicitly attachment-corrected report's unique official
  /// main-document option. Returned financial facts retain the original receipt;
  /// the correction receipt and its viewer remain separate provenance.
  Future<
    ({
      List<int> zip,
      Uri source,
      String receipt,
      String correctionReceipt,
      Uri correctionSource,
    })
  >
  fetchLinkedAnnual(
    String correctionReceipt, {
    required String reportName,
    required String corpCode,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
  }) async {
    if (!RegExp(r'^\d{14}$').hasMatch(correctionReceipt) ||
        !reportName.startsWith('[첨부정정]사업보고서')) {
      throw const FormatException(
        'Not an explicit annual attachment correction',
      );
    }
    final correctionSource = Uri.https('dart.fss.or.kr', '/dsaf001/main.do', {
      'rcpNo': correctionReceipt,
    });
    final response = await client
        .get(
          correctionSource,
          headers: {
            'User-Agent': 'InvestmentOntology/1.0',
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 ||
        (response.request?.url.host ?? correctionSource.host) !=
            'dart.fss.or.kr') {
      throw const FormatException('Invalid official correction response');
    }
    final shell = utf8.decode(response.bodyBytes);
    if (!RegExp("openPdfDownload\\('$correctionReceipt',\\s*'\\d+'\\)")
        .hasMatch(shell)) {
      throw const FormatException('Correction shell receipt mismatch');
    }
    final families = RegExp(
      r'<select\b[^>]*\bid=["\x27]family["\x27][^>]*>(.*?)</select>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(shell).toList();
    if (families.length != 1) {
      throw const FormatException('Ambiguous original document selection');
    }
    final candidates = <String>[];
    for (final option in RegExp(
      r'<option\b([^>]*)>',
      caseSensitive: false,
    ).allMatches(families.single.group(1)!)) {
      final attrs = <String, String>{};
      for (final attr in RegExp(
        r'([\w-]+)\s*=\s*["\x27]([^"\x27]*)["\x27]',
      ).allMatches(option.group(1)!)) {
        if (attrs.containsKey(attr.group(1))) {
          throw const FormatException('Duplicate original option attribute');
        }
        attrs[attr.group(1)!] = attr.group(2)!;
      }
      if (attrs['title'] != '사업보고서') continue;
      final value = attrs['value'] ?? '';
      if (!RegExp(r'^rcpNo=\d{14}$').hasMatch(value)) {
        throw const FormatException('Invalid original document option');
      }
      candidates.add(value.substring(6));
    }
    if (candidates.length != 1 ||
        candidates.single.compareTo(correctionReceipt) >= 0) {
      throw const FormatException('Ambiguous or nonprior original receipt');
    }
    final receipt = candidates.single;
    await Future<void>.delayed(const Duration(seconds: 1));
    final original = await fetch(receipt);
    // Validates trusted source metadata, requested period, entity and basis.
    parse(
      original.zip,
      receipt: receipt,
      corpCode: corpCode,
      bsnsYear: bsnsYear,
      periodEnd: periodEnd,
      consolidated: consolidated,
    );
    return (
      zip: original.zip,
      source: original.source,
      receipt: receipt,
      correctionReceipt: correctionReceipt,
      correctionSource: correctionSource,
    );
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
    Uri? sourceUri,
  }) {
    if (periodEnd.year != bsnsYear) {
      throw const FormatException('Annual fiscal year mismatch');
    }
    if (sourceUri != null &&
        (sourceUri.scheme != 'https' ||
            sourceUri.host != 'dart.fss.or.kr' ||
            sourceUri.path != '/pdf/download/ifrs.do' ||
            sourceUri.queryParameters['rcp_no'] != receipt)) {
      throw const FormatException('XBRL source receipt mismatch');
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
    final legacyStart = DateTime.utc(
      periodEnd.year - 1,
      periodEnd.month + 1,
      1,
    ).toIso8601String().substring(0, 10);
    final declaredStart = _declaredAnnualStart(root, corpCode, end);
    final start = declaredStart ?? legacyStart;
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
      final axis = _qname(d, d.getAttribute('dimension') ?? '');
      final member = _qname(d, d.innerText);
      if (d.namespaceUri != 'http://xbrl.org/2006/xbrldi' ||
          d.name.local != 'explicitMember' ||
          axis == null ||
          member == null ||
          !_taxonomy(axis.$1, 'ifrs-full') ||
          axis.$1 != member.$1 ||
          axis.$2 != 'ConsolidatedAndSeparateFinancialStatementsAxis' ||
          member.$2 != expectedMember) {
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
      final isDart = _taxonomy(ns, 'dart');
      final isIfrs = _taxonomy(ns, 'ifrs-full');
      if (account == null ||
          (!isDart && !isIfrs) ||
          (f.name.local == 'OperatingIncomeLoss' && !isDart) ||
          contexts[f.getAttribute('contextRef')] != account.$3) {
        continue;
      }
      final measures = units[f.getAttribute('unitRef')];
      final validMoney =
          measures != null &&
          measures.length == 1 &&
          measures.single == 'iso4217:KRW' &&
          root.getAttribute('xmlns:iso4217') ==
              'http://www.xbrl.org/2003/iso4217' &&
          RegExp(r'^-?\d+$').hasMatch(f.innerText.trim());
      final decimals = int.tryParse(f.getAttribute('decimals') ?? '');
      // Some reports also print a rounded contracts-only revenue concept.
      // Never round it or replace exact total revenue with this alternate.
      // It may be omitted only when the identical whole-current context,
      // taxonomy and currency contain an exact total Revenue fact.
      if (validMoney &&
          isIfrs &&
          f.name.local == 'RevenueFromContractsWithCustomers' &&
          decimals != null &&
          decimals < 0 &&
          root.children.whereType<XmlElement>().any(
            (candidate) =>
                candidate.name.local == 'Revenue' &&
                candidate.namespaceUri == f.namespaceUri &&
                candidate.getAttribute('contextRef') ==
                    f.getAttribute('contextRef') &&
                candidate.getAttribute('unitRef') ==
                    f.getAttribute('unitRef') &&
                candidate.getAttribute('decimals') == '0' &&
                RegExp(r'^-?\d+$').hasMatch(candidate.innerText.trim()),
          )) {
        continue;
      }
      if (!validMoney ||
          !const ['0', 'INF'].contains(f.getAttribute('decimals'))) {
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
        'xbrl_provenance': {
          'source': sourceUri?.toString(),
          'receipt': receipt,
          'corpCode': corpCode,
          'basis': consolidated ? 'CFS' : 'OFS',
          'periodStart': start,
          'periodEnd': end,
          'contextId': f.getAttribute('contextRef'),
          'contextInstant': account.$3 ? end : null,
          'contextStart': account.$3 ? null : start,
          'contextEnd': end,
          'taxonomyNamespace': f.namespaceUri,
          'factLocalName': f.name.local,
          'rawAmount': value,
          'unitRef': f.getAttribute('unitRef'),
          'currency': 'KRW',
          'decimals': f.getAttribute('decimals'),
        },
      };
    }
    if (!values.containsKey('ifrs-full_Assets')) {
      throw const FormatException('Current annual core contexts missing');
    }
    if (!values.containsKey('ifrs-full_ProfitLoss')) {
      // A bounded partial OFS subset is admitted only with explicit annual
      // metadata and a complete, internally consistent whole-company subset.
      // Equity-component ProfitLoss facts are never used to infer net income.
      if (consolidated || declaredStart == null) {
        throw const FormatException('Current annual core contexts missing');
      }
      Map<String, dynamic> requiredFact(String id) {
        final fact = values[id];
        if (fact == null) {
          throw const FormatException('Partial annual core subset incomplete');
        }
        return fact;
      }

      Map<String, dynamic> uniqueAccount(List<String> ids) {
        final facts = ids
            .where(values.containsKey)
            .map((id) => values[id]!)
            .toList();
        if (facts.isEmpty ||
            facts.map((f) => f['thstrm_amount']).toSet().length != 1) {
          throw const FormatException(
            'Partial annual account ambiguous or missing',
          );
        }
        return facts.first;
      }

      final assets = requiredFact('ifrs-full_Assets');
      final liabilities = requiredFact('ifrs-full_Liabilities');
      final equity = requiredFact('ifrs-full_Equity');
      if (BigInt.parse(assets['thstrm_amount'] as String) !=
          BigInt.parse(liabilities['thstrm_amount'] as String) +
              BigInt.parse(equity['thstrm_amount'] as String)) {
        throw const FormatException('Partial annual balance identity mismatch');
      }
      final subset = [
        assets,
        liabilities,
        equity,
        uniqueAccount([
          'ifrs-full_Revenue',
          'ifrs-full_RevenueFromContractsWithCustomers',
        ]),
        uniqueAccount([
          'dart_OperatingIncomeLoss',
          'ifrs-full_ProfitLossFromOperatingActivities',
        ]),
        requiredFact('ifrs-full_CashFlowsFromUsedInOperatingActivities'),
      ];
      return [
        for (final fact in subset)
          {
            ...fact,
            'xbrl_partial_core': true,
            'xbrl_collection_note': '순손익 wholecontext 미확보, 부분 핵심계정',
          },
      ];
    }
    return values.values.toList();
  }

  /// Strict primary half-year core, with distinct quarter and cumulative PL.
  static List<Map<String, dynamic>> parseHalfYear(
    List<int> zip, {
    required String receipt,
    required String corpCode,
    required int bsnsYear,
    required DateTime periodEnd,
    required bool consolidated,
    Uri? sourceUri,
  }) {
    if (periodEnd.year != bsnsYear) {
      throw const FormatException('Annual fiscal year mismatch');
    }
    if (sourceUri != null &&
        (sourceUri.scheme != 'https' ||
            sourceUri.host != 'dart.fss.or.kr' ||
            sourceUri.path != '/pdf/download/ifrs.do' ||
            sourceUri.queryParameters['rcp_no'] != receipt)) {
      throw const FormatException('XBRL source receipt mismatch');
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
    final declaredStart = _declaredAnnualStart(
      root,
      corpCode,
      end,
      halfYear: true,
    );
    if (declaredStart == null) {
      throw const FormatException('Half-year metadata required');
    }
    final expectedStart = DateTime.utc(
      periodEnd.year,
      periodEnd.month - 5,
      1,
    ).toIso8601String().substring(0, 10);
    if (declaredStart != expectedStart ||
        periodEnd.day !=
            DateTime.utc(periodEnd.year, periodEnd.month + 1, 0).day) {
      throw const FormatException('Half-year exact six-month period required');
    }
    final quarterStart = DateTime.utc(
      periodEnd.year,
      periodEnd.month - 2,
      1,
    ).toIso8601String().substring(0, 10);
    final quarterContexts = <String>{};
    final start = declaredStart;
    final expectedMember = consolidated
        ? 'ConsolidatedMember'
        : 'SeparateMember';
    final contexts = <String, bool>{};
    final contextIds = <String>{};
    for (final c in root.findElements('context', namespaceUri: xbrli)) {
      final contextId = c.getAttribute('id');
      if (contextId == null || !contextIds.add(contextId)) {
        throw const FormatException('Duplicate half-year context');
      }
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
      final axis = _qname(d, d.getAttribute('dimension') ?? '');
      final member = _qname(d, d.innerText);
      if (d.namespaceUri != 'http://xbrl.org/2006/xbrldi' ||
          d.name.local != 'explicitMember' ||
          axis == null ||
          member == null ||
          !_taxonomy(axis.$1, 'ifrs-full') ||
          axis.$1 != member.$1 ||
          axis.$2 != 'ConsolidatedAndSeparateFinancialStatementsAxis' ||
          member.$2 != expectedMember) {
        continue;
      }
      final periods = c.findElements('period', namespaceUri: xbrli).toList();
      if (periods.length != 1) {
        throw const FormatException('Half-year context period ambiguous');
      }
      final dates = <String, String>{};
      for (final date in periods.single.children.whereType<XmlElement>()) {
        if (date.namespaceUri != xbrli ||
            !const [
              'startDate',
              'endDate',
              'instant',
            ].contains(date.name.local) ||
            dates.containsKey(date.name.local)) {
          throw const FormatException(
            'Duplicate or unsupported half-year date',
          );
        }
        final value = date.innerText;
        final parsed = DateTime.tryParse(value);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
            parsed == null ||
            parsed.toIso8601String().substring(0, 10) != value) {
          throw const FormatException('Invalid half-year date');
        }
        dates[date.name.local] = value;
      }
      if (!((dates.length == 1 && dates.containsKey('instant')) ||
          (dates.length == 2 &&
              dates.containsKey('startDate') &&
              dates.containsKey('endDate') &&
              dates['startDate']!.compareTo(dates['endDate']!) <= 0))) {
        throw const FormatException(
          'Mixed or incomplete half-year context dates',
        );
      }
      final instant = dates['instant'];
      if (instant == end) contexts[c.getAttribute('id')!] = true;
      if (dates['startDate'] == quarterStart && dates['endDate'] == end) {
        contexts[c.getAttribute('id')!] = false;
        quarterContexts.add(c.getAttribute('id')!);
      }
      if (dates['startDate'] == start && dates['endDate'] == end) {
        contexts[c.getAttribute('id')!] = false;
      }
    }
    final units = <String, List<String>>{};
    for (final unit in root.findElements('unit', namespaceUri: xbrli)) {
      final id = unit.getAttribute('id');
      if (id == null || id.isEmpty || units.containsKey(id)) {
        throw const FormatException('Duplicate or missing half-year unit ID');
      }
      units[id] = unit.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'measure')
          .map((e) => e.innerText)
          .toList();
    }
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
    final quarterValues = <String, Map<String, dynamic>>{};
    for (final f in root.children.whereType<XmlElement>()) {
      final account = accounts[f.name.local];
      final ns = f.namespaceUri ?? '';
      final isDart = _taxonomy(ns, 'dart');
      final isIfrs = _taxonomy(ns, 'ifrs-full');
      if (account == null ||
          (!isDart && !isIfrs) ||
          (f.name.local == 'OperatingIncomeLoss' && !isDart) ||
          contexts[f.getAttribute('contextRef')] != account.$3) {
        continue;
      }
      final isQuarter = quarterContexts.contains(f.getAttribute('contextRef'));
      if (isQuarter && account.$1 != 'CIS') continue;
      final targetValues = isQuarter ? quarterValues : values;
      final measures = units[f.getAttribute('unitRef')];
      final validMoney =
          measures != null &&
          measures.length == 1 &&
          measures.single == 'iso4217:KRW' &&
          root.getAttribute('xmlns:iso4217') ==
              'http://www.xbrl.org/2003/iso4217' &&
          RegExp(r'^-?\d+$').hasMatch(f.innerText.trim());
      final decimals = int.tryParse(f.getAttribute('decimals') ?? '');
      // Some reports also print a rounded contracts-only revenue concept.
      // Never round it or replace exact total revenue with this alternate.
      // It may be omitted only when the identical whole-current context,
      // taxonomy and currency contain an exact total Revenue fact.
      if (validMoney &&
          isIfrs &&
          f.name.local == 'RevenueFromContractsWithCustomers' &&
          decimals != null &&
          decimals < 0 &&
          root.children.whereType<XmlElement>().any(
            (candidate) =>
                candidate.name.local == 'Revenue' &&
                candidate.namespaceUri == f.namespaceUri &&
                candidate.getAttribute('contextRef') ==
                    f.getAttribute('contextRef') &&
                candidate.getAttribute('unitRef') ==
                    f.getAttribute('unitRef') &&
                candidate.getAttribute('decimals') == '0' &&
                RegExp(r'^-?\d+$').hasMatch(candidate.innerText.trim()),
          )) {
        continue;
      }
      if (!validMoney ||
          !const ['0', 'INF'].contains(f.getAttribute('decimals'))) {
        throw const FormatException(
          'Unsupported XBRL monetary unit or precision',
        );
      }
      final id = '${isDart ? 'dart' : 'ifrs-full'}_${f.name.local}';
      final value = f.innerText.trim();
      if (targetValues.containsKey(id)) {
        throw const FormatException('Duplicate whole half-year fact');
      }
      targetValues[id] = {
        'rcept_no': receipt,
        'corp_code': corpCode,
        'bsns_year': '$bsnsYear',
        'reprt_code': '11012',
        'account_id': id,
        'account_nm': account.$2,
        'account_detail': '-',
        'sj_div': account.$1,
        'thstrm_nm': account.$3
            ? end
            : '${isQuarter ? quarterStart : start}~$end',
        'thstrm_amount': value,
        'currency': 'KRW',
        'xbrl_provenance': {
          'source': sourceUri?.toString(),
          'receipt': receipt,
          'corpCode': corpCode,
          'basis': consolidated ? 'CFS' : 'OFS',
          'periodStart': start,
          'periodEnd': end,
          'contextId': f.getAttribute('contextRef'),
          'contextInstant': account.$3 ? end : null,
          'contextStart': account.$3
              ? null
              : (isQuarter ? quarterStart : start),
          'contextEnd': end,
          'taxonomyNamespace': f.namespaceUri,
          'factLocalName': f.name.local,
          'rawAmount': value,
          'unitRef': f.getAttribute('unitRef'),
          'currency': 'KRW',
          'decimals': f.getAttribute('decimals'),
        },
      };
    }
    Map<String, dynamic> exact(
      Map<String, Map<String, dynamic>> facts,
      List<String> ids,
    ) {
      final found = ids
          .where(facts.containsKey)
          .map((id) => facts[id]!)
          .toList();
      if (found.length != 1) {
        throw const FormatException(
          'Half-year core account missing or ambiguous',
        );
      }
      return found.single;
    }

    final assets = exact(values, ['ifrs-full_Assets']);
    final liabilities = exact(values, ['ifrs-full_Liabilities']);
    final equity = exact(values, ['ifrs-full_Equity']);
    if (BigInt.parse(assets['thstrm_amount']) !=
        BigInt.parse(liabilities['thstrm_amount']) +
            BigInt.parse(equity['thstrm_amount'])) {
      throw const FormatException('Half-year balance identity mismatch');
    }
    final result = [assets, liabilities, equity];
    for (final ids in [
      ['ifrs-full_Revenue', 'ifrs-full_RevenueFromContractsWithCustomers'],
      [
        'dart_OperatingIncomeLoss',
        'ifrs-full_ProfitLossFromOperatingActivities',
      ],
      ['ifrs-full_ProfitLoss'],
    ]) {
      final cumulative = exact(values, ids),
          quarter = exact(quarterValues, ids);
      if (cumulative['account_id'] != quarter['account_id']) {
        throw const FormatException(
          'Half-year quarter/cumulative concept mismatch',
        );
      }
      result.add({
        ...quarter,
        'thstrm_add_amount': cumulative['thstrm_amount'],
        'xbrl_provenance': {
          ...quarter['xbrl_provenance'] as Map,
          'cumulativeContextId':
              (cumulative['xbrl_provenance'] as Map)['contextId'],
          'cumulativeRawAmount': cumulative['thstrm_amount'],
          'quarterPeriodStart': quarterStart,
        },
      });
    }
    result.add(
      exact(values, ['ifrs-full_CashFlowsFromUsedInOperatingActivities']),
    );
    return result;
  }

  static bool _taxonomy(String namespace, String kind) {
    final uri = Uri.tryParse(namespace);
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment) {
      return false;
    }
    final host = kind == 'ifrs-full' ? 'xbrl.ifrs.org' : 'dart.fss.or.kr';
    final suffix = kind == 'ifrs-full' ? 'ifrs-full' : 'ifrs/$kind';
    return uri.host == host &&
        RegExp('^/taxonomy/\\d{4}-\\d{2}-\\d{2}/$suffix\$').hasMatch(uri.path);
  }

  static (String, String)? _qname(XmlElement element, String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) return null;
    for (XmlNode? node = element; node != null; node = node.parent) {
      if (node is XmlElement) {
        final namespace = node.getAttribute('xmlns:${parts.first}');
        if (namespace != null) return (namespace, parts.last);
      }
    }
    return null;
  }

  /// Metadata is optional only for the legacy strict twelve-month path.
  /// A present declaration must uniquely identify the source's current annual
  /// period; comparative values and context naming conventions are not used.
  static String? _declaredAnnualStart(
    XmlElement root,
    String corpCode,
    String end, {
    bool halfYear = false,
  }) {
    const xbrli = 'http://www.xbrl.org/2003/instance';
    const xbrldi = 'http://xbrl.org/2006/xbrldi';
    final declarations = root.children
        .whereType<XmlElement>()
        .where(
          (e) => const [
            'DocumentPeriodStartDate',
            'DocumentPeriodEndDate',
          ].contains(e.name.local),
        )
        .toList();
    if (declarations.isEmpty) return null;
    final contexts = <String, XmlElement>{};
    for (final context in root.findElements('context', namespaceUri: xbrli)) {
      final id = context.getAttribute('id');
      if (id == null || contexts.containsKey(id)) {
        throw const FormatException('Ambiguous XBRL context');
      }
      contexts[id] = context;
    }
    XmlElement contextOf(XmlElement fact) {
      final context = contexts[fact.getAttribute('contextRef')];
      if (context == null) {
        throw const FormatException('Missing metadata context');
      }
      final identifiers = context.descendants
          .whereType<XmlElement>()
          .where((e) => e.name.local == 'identifier')
          .toList();
      if (identifiers.length != 1 ||
          identifiers.single.namespaceUri != xbrli ||
          identifiers.single.innerText != corpCode ||
          identifiers.single.getAttribute('scheme') !=
              'http://dart.fss.or.kr/ifrs/CIK') {
        throw const FormatException('XBRL metadata entity mismatch');
      }
      return context;
    }

    List<XmlElement> dimensions(XmlElement context) => context.descendants
        .whereType<XmlElement>()
        .where(
          (e) =>
              e.name.local == 'explicitMember' || e.name.local == 'typedMember',
        )
        .toList();
    bool current(XmlElement context, String namespace) {
      final dims = dimensions(context);
      if (dims.length != 1 ||
          dims.single.namespaceUri != xbrldi ||
          dims.single.name.local != 'explicitMember') {
        return false;
      }
      final axis = _qname(
        dims.single,
        dims.single.getAttribute('dimension') ?? '',
      );
      final member = _qname(dims.single, dims.single.innerText);
      return axis == (namespace, 'PeriodAxis') &&
          member ==
              (
                namespace,
                'PeriodCoveredbytheReportofCurrentFiscalYearorQuarterorHalfYearMember',
              );
    }

    String dateOf(XmlElement context, String name) {
      final periods = context
          .findElements('period', namespaceUri: xbrli)
          .toList();
      if (periods.length != 1) {
        throw const FormatException('Invalid metadata period');
      }
      final dates = periods.single
          .findElements(name, namespaceUri: xbrli)
          .toList();
      if (dates.length != 1) {
        throw const FormatException('Ambiguous metadata date');
      }
      final value = dates.single.innerText;
      final parsed = DateTime.tryParse(value);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
          parsed == null ||
          parsed.toIso8601String().substring(0, 10) != value) {
        throw const FormatException('Invalid metadata date');
      }
      return value;
    }

    final currentFacts = <String, XmlElement>{};
    String? metadataNamespace;
    for (final fact in declarations) {
      final namespace = fact.namespaceUri ?? '';
      if (!_taxonomy(namespace, 'dart-gcd')) {
        throw const FormatException('Untrusted reporting period metadata');
      }
      final context = contextOf(fact);
      if (!current(context, namespace)) continue;
      if (currentFacts.containsKey(fact.name.local) ||
          (metadataNamespace != null && metadataNamespace != namespace)) {
        throw const FormatException('Ambiguous current reporting period');
      }
      metadataNamespace = namespace;
      currentFacts[fact.name.local] = fact;
    }
    final startFact = currentFacts['DocumentPeriodStartDate'];
    final endFact = currentFacts['DocumentPeriodEndDate'];
    if (startFact == null || endFact == null || metadataNamespace == null) {
      throw const FormatException('Current reporting period metadata missing');
    }
    final start = startFact.innerText;
    final declaredEnd = endFact.innerText;
    for (final fact in [startFact, endFact]) {
      final context = contextOf(fact);
      if (dateOf(context, 'startDate') != start ||
          dateOf(context, 'endDate') != declaredEnd) {
        throw const FormatException('Declared period and context disagree');
      }
    }
    if (declaredEnd != end || start.compareTo(end) > 0) {
      throw const FormatException('Declared annual period mismatch');
    }
    final titles = <String>{};
    final currencies = <String>{};
    for (final fact in root.children.whereType<XmlElement>()) {
      if (!const [
        'DocumentTitle',
        'EntityReportingCurrencyISOCode',
      ].contains(fact.name.local)) {
        continue;
      }
      if (fact.namespaceUri != metadataNamespace) {
        throw const FormatException('Untrusted annual metadata');
      }
      final context = contextOf(fact);
      final validDimensions = fact.name.local == 'DocumentTitle'
          ? current(context, metadataNamespace)
          : dimensions(context).isEmpty;
      if (!validDimensions ||
          dateOf(context, 'startDate') != start ||
          dateOf(context, 'endDate') != end) {
        throw const FormatException('Annual metadata context mismatch');
      }
      (fact.name.local == 'DocumentTitle' ? titles : currencies).add(
        fact.innerText,
      );
    }
    if (titles.isEmpty ||
        titles.any(
          (t) =>
              !(halfYear
                      ? const ['Half Year Report', '반기보고서']
                      : const ['Annual Report', '사업보고서'])
                  .contains(t),
        ) ||
        currencies.length != 1 ||
        currencies.single != 'KRW') {
      throw const FormatException('Annual title or reporting currency missing');
    }
    return start;
  }
}
