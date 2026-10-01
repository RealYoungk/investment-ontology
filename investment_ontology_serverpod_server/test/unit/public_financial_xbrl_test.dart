import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/dart/public_financial_xbrl.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xml/xml.dart';

void main() {
  final fixture = File(
    'test/fixtures/financial_xbrl/cosnine_20250409002838.zip',
  ).readAsBytesSync();
  List<Map<String, dynamic>> parse(
    List<int> zip, {
    String corp = '00442455',
    DateTime? end,
    bool cfs = true,
  }) => PublicFinancialXbrl.parse(
    zip,
    receipt: '20250409002838',
    corpCode: corp,
    bsnsYear: 2024,
    periodEnd: end ?? DateTime.utc(2024, 12, 31),
    consolidated: cfs,
  );
  List<int> change(String from, String to) {
    final archive = ZipDecoder().decodeBytes(fixture);
    final instance = archive.files.singleWhere((f) => f.name.endsWith('.xbrl'));
    final xml = utf8.decode(instance.content).replaceAll(from, to);
    return ZipEncoder().encodeBytes(
      Archive()..addFile(ArchiveFile.bytes(instance.name, utf8.encode(xml))),
    );
  }

  test(
    'public transport binds receipt and forwards the download session',
    () async {
      final requests = <http.Request>[];
      final reader = PublicFinancialXbrl(
        MockClient((request) async {
          requests.add(request);
          expect(request.url.host, 'dart.fss.or.kr');
          expect(request.url.queryParameters.containsKey('crtfc_key'), isFalse);
          if (request.url.path == '/dsaf001/main.do') {
            return http.Response(
              "openPdfDownload('20250409002838', '10571658')",
              200,
              headers: {'set-cookie': 'JSESSIONID=fixture; Path=/'},
            );
          }
          expect(request.headers['Cookie'], 'JSESSIONID=fixture');
          expect(request.headers['Referer'], isNotNull);
          if (request.url.path == '/pdf/download/main.do') {
            return http.Response(
              '<a href="/pdf/download/ifrs.do?rcp_no=20250409002838&amp;dcm_no=10571658&amp;lang=ko">XBRL</a>',
              200,
            );
          }
          return http.Response.bytes(fixture, 200);
        }),
      );
      final original = await reader.fetch('20250409002838');
      expect(original.source.queryParameters['rcp_no'], '20250409002838');
      expect(original.source.queryParameters['dcm_no'], '10571658');
      expect(parse(original.zip), isNotEmpty);
      expect(requests, hasLength(3));
    },
  );
  test('wrong receipt shell cannot redirect the original fallback', () async {
    final reader = PublicFinancialXbrl(
      MockClient(
        (_) async =>
            http.Response("openPdfDownload('20250409002839', '10571658')", 200),
      ),
    );
    await expectLater(reader.fetch('20250409002838'), throwsFormatException);
  });
  test(
    'actual exact-receipt XBRL matches printed current-year CFS and OFS tables',
    () {
      final cfs = {
        for (final r in parse(fixture)) r['account_id']: r['thstrm_amount'],
      };
      final ofs = {
        for (final r in parse(fixture, cfs: false))
          r['account_id']: r['thstrm_amount'],
      };
      expect(cfs['ifrs-full_Assets'], '39024201117');
      expect(cfs['ifrs-full_Revenue'], '9745770767');
      expect(cfs['dart_OperatingIncomeLoss'], '-8285302600');
      expect(cfs['ifrs-full_ProfitLoss'], '-19463045883');
      expect(
        cfs['ifrs-full_CashFlowsFromUsedInOperatingActivities'],
        '-12117877327',
      );
      expect(ofs['ifrs-full_Assets'], '39283113892');
      expect(ofs['ifrs-full_Revenue'], '9741301967');
      expect(ofs['ifrs-full_ProfitLoss'], '-19406159233');
    },
  );
  test('entity and requested actual period cannot be relabelled', () {
    expect(() => parse(fixture, corp: '00000001'), throwsFormatException);
    expect(
      () => parse(fixture, end: DateTime.utc(2025, 12, 31)),
      throwsFormatException,
    );
  });
  test('nonKRW and rounded amounts are rejected', () {
    expect(
      () => parse(change('iso4217:KRW', 'iso4217:USD')),
      throwsFormatException,
    );
    expect(
      () => parse(change('decimals="0"', 'decimals="-3"')),
      throwsFormatException,
    );
  });
  test('metadata-absent full annual retains strict twelve-month behavior', () {
    final archive = ZipDecoder().decodeBytes(fixture);
    final instance = archive.files.singleWhere((f) => f.name.endsWith('.xbrl'));
    final document = XmlDocument.parse(utf8.decode(instance.content));
    document.rootElement.children.removeWhere(
      (e) =>
          e is XmlElement &&
          [
            'DocumentPeriodStartDate',
            'DocumentPeriodEndDate',
          ].contains(e.name.local),
    );
    final original = ZipEncoder().encodeBytes(
      Archive()..addFile(
        ArchiveFile.bytes(instance.name, utf8.encode(document.toXmlString())),
      ),
    );
    expect(
      parse(original).singleWhere(
        (r) => r['account_id'] == 'ifrs-full_ProfitLoss',
      )['thstrm_amount'],
      '-19463045883',
    );
  });

  group('declared short annual source periods', () {
    final samples = [
      (
        'ereit_20260908000319.zip',
        '20260908000319',
        '00544452',
        '2026-01-01',
        DateTime.utc(2026, 6, 30),
        ['665904748347', '6751516568', '23340504029', '11862749130'],
        ['552723448981', '7940335766', '18634585896', '11643467064'],
      ),
      (
        'daishin_reit_20260805000514.zip',
        '20260805000514',
        '01885222',
        '2026-03-01',
        DateTime.utc(2026, 5, 31),
        ['717936418538', '1954674479', '8368056710', '3117070097'],
        ['296918401209', '4386592338', '4474414279', '4373769678'],
      ),
    ];
    const member =
        'PeriodCoveredbytheReportofCurrentFiscalYearorQuarterorHalfYearMember';
    for (final s in samples) {
      final zip = File('test/fixtures/financial_xbrl/${s.$1}')
          .readAsBytesSync();
      List<Map<String, dynamic>> read(
        List<int> data, {
        bool cfs = true,
        DateTime? end,
      }) => PublicFinancialXbrl.parse(
        data,
        receipt: s.$2,
        corpCode: s.$3,
        bsnsYear: 2026,
        periodEnd: end ?? s.$5,
        consolidated: cfs,
      );
      List<int> mutate(void Function(XmlElement) edit) {
        final a = ZipDecoder().decodeBytes(zip);
        final i = a.files.singleWhere((f) => f.name.endsWith('.xbrl'));
        final d = XmlDocument.parse(utf8.decode(i.content));
        edit(d.rootElement);
        return ZipEncoder().encodeBytes(
          Archive()
            ..addFile(ArchiveFile.bytes(i.name, utf8.encode(d.toXmlString()))),
        );
      }

      XmlElement declaration(XmlElement r, String name) =>
          r.children.whereType<XmlElement>().singleWhere(
            (e) =>
                e.name.local == name &&
                (e.getAttribute('contextRef') ?? '').contains(member),
          );
      XmlElement context(XmlElement r) {
        final id = declaration(
          r,
          'DocumentPeriodStartDate',
        ).getAttribute('contextRef');
        return r.children.whereType<XmlElement>().singleWhere(
          (e) => e.name.local == 'context' && e.getAttribute('id') == id,
        );
      }

      XmlElement child(XmlElement r, String name) => r.descendants
          .whereType<XmlElement>()
          .singleWhere((e) => e.name.local == name);
      test(
        '${s.$1}: exact CFS/OFS core values use current metadata after comparisons',
        () {
          for (final cfs in [true, false]) {
            final rows = read(zip, cfs: cfs);
            final vals = {
              for (final r in rows) r['account_id']: r['thstrm_amount'],
            };
            final expected = cfs ? s.$6 : s.$7;
            for (final (index, id) in [
              'ifrs-full_Assets',
              'ifrs-full_ProfitLoss',
              'ifrs-full_Revenue',
              'ifrs-full_CashFlowsFromUsedInOperatingActivities',
            ].indexed) {
              expect(vals[id], expected[index]);
            }
            expect(
              rows.every(
                (r) =>
                    r['thstrm_nm'] ==
                    '${s.$4}~${s.$5.toIso8601String().substring(0, 10)}',
              ),
              isTrue,
            );
            expect(
              rows.every(
                (r) =>
                    r['corp_code'] == s.$3 &&
                    r['rcept_no'] == s.$2 &&
                    r['currency'] == 'KRW',
              ),
              isTrue,
            );
          }
        },
      );
      test('${s.$1}: duplicate current declaration rejected even if equal', () {
        expect(
          () => read(
            mutate(
              (r) => r.children.add(
                declaration(r, 'DocumentPeriodStartDate').copy(),
              ),
            ),
          ),
          throwsFormatException,
        );
      });
      test('${s.$1}: wrong member cannot select short period', () {
        expect(
          () => read(
            mutate(
              (r) => child(context(r), 'explicitMember').innerText =
                  'dart-gcd:PeriodCoveredbyLastFiscalYearMember',
            ),
          ),
          throwsFormatException,
        );
      });
      test('${s.$1}: declaration must equal context and requested end', () {
        expect(
          () => read(zip, end: DateTime.utc(2026, 12, 31)),
          throwsFormatException,
        );
        expect(
          () => read(
            mutate(
              (r) => declaration(r, 'DocumentPeriodEndDate').innerText =
                  '2026-12-31',
            ),
          ),
          throwsFormatException,
        );
        expect(
          () => read(
            mutate(
              (r) => child(context(r), 'startDate').innerText = '2026-02-01',
            ),
          ),
          throwsFormatException,
        );
      });
      test('${s.$1}: foreign company and metadata namespace rejected', () {
        expect(
          () => read(
            mutate(
              (r) => child(context(r), 'identifier').innerText = '00000001',
            ),
          ),
          throwsFormatException,
        );
        expect(
          () => read(
            mutate(
              (r) => r.setAttribute(
                'xmlns:dart-gcd',
                'https://dart.fss.or.kr.evil/taxonomy/2026-01-31/ifrs/dart-gcd',
              ),
            ),
          ),
          throwsFormatException,
        );
      });
      test('${s.$1}: current annual title and KRW declaration required', () {
        for (final (name, value) in [
          ('DocumentTitle', 'Quarterly Report'),
          ('EntityReportingCurrencyISOCode', 'USD'),
        ]) {
          expect(
            () => read(
              mutate((r) {
                for (final e in r.children.whereType<XmlElement>().where(
                  (e) => e.name.local == name,
                )) {
                  e.innerText = value;
                }
              }),
            ),
            throwsFormatException,
          );
        }
      });
      test('${s.$1}: absent short-period metadata never infers start', () {
        expect(
          () => read(
            mutate(
              (r) => r.children.removeWhere(
                (e) =>
                    e is XmlElement &&
                    [
                      'DocumentPeriodStartDate',
                      'DocumentPeriodEndDate',
                    ].contains(e.name.local),
              ),
            ),
          ),
          throwsFormatException,
        );
      });
      test(
        '${s.$1}: official IFRS http/https allowed; host and path spoof rejected',
        () {
          final a = ZipDecoder().decodeBytes(zip);
          final r = XmlDocument.parse(
            utf8.decode(
              a.files.singleWhere((f) => f.name.endsWith('.xbrl')).content,
            ),
          ).rootElement;
          final ns = r.getAttribute('xmlns:ifrs-full')!;
          for (final scheme in ['http', 'https']) {
            expect(
              read(
                mutate(
                  (r) => r.setAttribute(
                    'xmlns:ifrs-full',
                    ns.replaceFirst(RegExp(r'^https?'), scheme),
                  ),
                ),
              ),
              isNotEmpty,
            );
          }
          for (final bad in [
            ns.replaceFirst('xbrl.ifrs.org', 'xbrl.ifrs.org.evil'),
            '$ns/extra',
          ]) {
            expect(
              () => read(mutate((r) => r.setAttribute('xmlns:ifrs-full', bad))),
              throwsFormatException,
            );
          }
        },
      );
      test(
        '${s.$1}: whole-company conflicting values rejected; extra dimensions dropped',
        () {
          expect(
            () => read(
              mutate((r) {
                final fact = r.children.whereType<XmlElement>().singleWhere(
                  (e) =>
                      e.name.local == 'ProfitLoss' &&
                      (e.getAttribute('contextRef') ?? '') == 'CFY2026dFY_ifrs-full_ConsolidatedAndSeparateFinancialStatementsAxis_ifrs-full_ConsolidatedMember',
                );
                r.children.add(fact.copy()..innerText = '1');
              }),
            ),
            throwsFormatException,
          );
          expect(
            read(zip).where((r) => r['account_id'] == 'ifrs-full_ProfitLoss'),
            hasLength(1),
          );
        },
      );
      test('${s.$1}: monetary precision and KRW unit guards remain strict', () {
        expect(
          () => read(
            mutate((r) {
              for (final e in r.children.whereType<XmlElement>().where(
                (e) => e.name.local == 'ProfitLoss',
              )) {
                e.setAttribute('decimals', '-3');
              }
            }),
          ),
          throwsFormatException,
        );
        expect(
          () => read(
            mutate((r) {
              for (final e in r.descendants.whereType<XmlElement>().where(
                (e) =>
                    e.name.local == 'measure' && e.innerText == 'iso4217:KRW',
              )) {
                e.innerText = 'iso4217:USD';
              }
            }),
          ),
          throwsFormatException,
        );
      });
    }
  });
  group('official explicit attachment originals', () {
    final examples = [
      (
        '20250321001370',
        '20250110000545',
        '01669226',
        2024,
        DateTime.utc(2024, 10, 31),
        '1586401656876',
        '2799718358',
      ),
      (
        '20240118000263',
        '20240118000098',
        '01688896',
        2023,
        DateTime.utc(2023, 10, 31),
        '742411662610',
        '458296429',
      ),
    ];
    for (final s in examples) {
      final correctionShell = File(
        'test/fixtures/financial_xbrl/${s.$1}-shell.html',
      ).readAsStringSync();
      final originalShell = File(
        'test/fixtures/financial_xbrl/${s.$2}-shell.html',
      ).readAsStringSync();
      final original = File('test/fixtures/financial_xbrl/${s.$2}.zip')
          .readAsBytesSync();
      final requests = <http.Request>[];
      PublicFinancialXbrl reader(String shell) => PublicFinancialXbrl(
        MockClient((request) async {
          requests.add(request);
          expect(request.url.host, 'dart.fss.or.kr');
          expect(request.url.queryParameters.containsKey('crtfc_key'), isFalse);
          if (request.url.path == '/dsaf001/main.do') {
            return http.Response(
              request.url.queryParameters['rcpNo'] == s.$1
                  ? shell
                  : originalShell,
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          }
          if (request.url.path == '/pdf/download/main.do') {
            final dcm = request.url.queryParameters['dcm_no'];
            return http.Response(
              '<a href="/pdf/download/ifrs.do?rcp_no=${s.$2}&amp;dcm_no=$dcm&amp;lang=ko">XBRL</a>',
              200,
            );
          }
          return http.Response.bytes(original, 200);
        }),
      );
      Future<
        ({
          List<int> zip,
          Uri source,
          String receipt,
          String correctionReceipt,
          Uri correctionSource,
        })
      >
      resolve(String shell, {String? corp, DateTime? end, String? name}) =>
          reader(shell).fetchLinkedAnnual(
            s.$1,
            reportName: name ?? '[첨부정정]사업보고서',
            corpCode: corp ?? s.$3,
            bsnsYear: s.$4,
            periodEnd: end ?? s.$5,
            consolidated: false,
          );
      test(
        '${s.$1}: official main option retains source receipt and proven current OFS values',
        () async {
          requests.clear();
          final result = await resolve(correctionShell);
          expect(result.receipt, s.$2);
          expect(result.correctionReceipt, s.$1);
          expect(result.source.queryParameters['rcp_no'], s.$2);
          expect(result.correctionSource.queryParameters['rcpNo'], s.$1);
          final rows = PublicFinancialXbrl.parse(
            result.zip,
            receipt: result.receipt,
            corpCode: s.$3,
            bsnsYear: s.$4,
            periodEnd: s.$5,
            consolidated: false,
          );
          expect(
            rows.singleWhere(
              (r) => r['account_id'] == 'ifrs-full_Assets',
            )['thstrm_amount'],
            s.$6,
          );
          expect(
            rows.singleWhere(
              (r) => r['account_id'] == 'ifrs-full_ProfitLoss',
            )['thstrm_amount'],
            s.$7,
          );
          expect(rows.every((r) => r['rcept_no'] == s.$2), isTrue);
          expect(requests, hasLength(4));
        },
      );
      test(
        '${s.$1}: nonattachment report cannot resolve another receipt',
        () async {
          requests.clear();
          await expectLater(
            resolve(correctionShell, name: '[기재정정]사업보고서'),
            throwsFormatException,
          );
          expect(requests, isEmpty);
        },
      );
      test('${s.$1}: ambiguous or nonprior original and external URL rejected', () async {
        for (final option in [
          '<option value="rcpNo=${s.$2}" title="사업보고서">duplicate</option>',
          '<option value="rcpNo=${s.$1}" title="사업보고서">current</option>',
          '<option value="https://evil.test/?rcpNo=${s.$2}" title="사업보고서">foreign</option>',
        ]) {
          requests.clear();
          final shell = correctionShell.replaceFirst(
            '</select>',
            '$option</select>',
          );
          await expectLater(resolve(shell), throwsFormatException);
          expect(requests, hasLength(1));
        }
      });
      test(
        '${s.$1}: older original from wrong source period rejected',
        () async {
          await expectLater(
            resolve(correctionShell, end: DateTime.utc(s.$4, 12, 31)),
            throwsFormatException,
          );
        },
      );
      test('${s.$1}: foreign original company rejected', () async {
        await expectLater(
          resolve(correctionShell, corp: '00000001'),
          throwsFormatException,
        );
      });
    }
  });
  group('declared source partial OFS core subset', () {
    final bytes = File(
      'test/fixtures/financial_xbrl/daishin_value_20250811000434.zip',
    ).readAsBytesSync();
    List<Map<String, dynamic>> read(List<int> zip, {bool cfs = false}) =>
        PublicFinancialXbrl.parse(
          zip,
          receipt: '20250811000434',
          corpCode: '01885222',
          bsnsYear: 2025,
          periodEnd: DateTime.utc(2025, 5, 31),
          consolidated: cfs,
        );
    List<int> mutate(void Function(XmlElement) edit) {
      final archive = ZipDecoder().decodeBytes(bytes);
      final instance = archive.files.singleWhere(
        (f) => f.name.endsWith('.xbrl'),
      );
      final d = XmlDocument.parse(utf8.decode(instance.content));
      edit(d.rootElement);
      return ZipEncoder().encodeBytes(
        Archive()..addFile(
          ArchiveFile.bytes(instance.name, utf8.encode(d.toXmlString())),
        ),
      );
    }

    XmlElement fact(XmlElement r, String name) =>
        r.children.whereType<XmlElement>().singleWhere(
          (e) =>
              e.name.local == name &&
              (e.getAttribute('contextRef') ?? '').startsWith('CFY') &&
              (e.getAttribute('contextRef') ?? '').split('_').length == 5 &&
              (e.getAttribute('contextRef') ?? '').endsWith(
                '_ifrs-full_SeparateMember',
              ),
        );
    test('actual CFS has seven core facts; OFS has six individually sourced facts and no inferred profit', () {
      final cfs = read(bytes, cfs: true);
      expect(cfs, hasLength(7));
      expect(
        cfs.singleWhere(
          (r) => r['account_id'] == 'ifrs-full_ProfitLoss',
        )['thstrm_amount'],
        '-976838894',
      );
      expect(cfs.any((r) => r['xbrl_partial_core'] == true), isFalse);
      final rows = read(bytes);
      expect(rows, hasLength(6));
      expect(
        {for (final r in rows) r['account_id']: r['thstrm_amount']},
        {
          'ifrs-full_Assets': '291152619288',
          'ifrs-full_Liabilities': '142776521854',
          'ifrs-full_Equity': '148376097434',
          'ifrs-full_Revenue': '0',
          'dart_OperatingIncomeLoss': '-189811627',
          'ifrs-full_CashFlowsFromUsedInOperatingActivities': '-1015309351',
        },
      );
      expect(
        rows.every(
          (r) =>
              r['xbrl_partial_core'] == true &&
              r['xbrl_collection_note'] == '순손익 wholecontext 미확보, 부분 핵심계정',
        ),
        isTrue,
      );
      expect(
        rows.every((r) => r['thstrm_nm'] == '2024-10-23~2025-05-31'),
        isTrue,
      );
    });
    test(
      'equity component ProfitLoss is never promoted to whole-company fact',
      () {
        final rows = read(
          mutate((r) {
            for (final e in r.children.whereType<XmlElement>().where(
              (e) =>
                  e.name.local == 'ProfitLoss' &&
                  (e.getAttribute('contextRef') ?? '').contains(
                    'SeparateMember',
                  ),
            )) {
              e.innerText = '123456789';
            }
          }),
        );
        expect(
          rows.any((r) => r['account_id'] == 'ifrs-full_ProfitLoss'),
          isFalse,
        );
        expect(rows, hasLength(6));
      },
    );
    test('broken source balance identity cannot yield partial facts', () {
      expect(
        () => read(mutate((r) => fact(r, 'Equity').innerText = '148376097435')),
        throwsFormatException,
      );
    });
    test('missing declared metadata cannot activate partial subset', () {
      expect(
        () => read(
          mutate(
            (r) => r.children.removeWhere(
              (e) =>
                  e is XmlElement &&
                  [
                    'DocumentPeriodStartDate',
                    'DocumentPeriodEndDate',
                  ].contains(e.name.local),
            ),
          ),
        ),
        throwsFormatException,
      );
    });
    test(
      'missing sixth fact or extra dimension cannot yield partial facts',
      () {
        expect(
          () => read(
            mutate(
              (r) => fact(r, 'CashFlowsFromUsedInOperatingActivities')
                  .parent!
                  .children
                  .remove(fact(r, 'CashFlowsFromUsedInOperatingActivities')),
            ),
          ),
          throwsFormatException,
        );
        expect(
          () => read(
            mutate((r) {
              final id = fact(r, 'Revenue').getAttribute('contextRef');
              final context = r.children.whereType<XmlElement>().singleWhere(
                (e) => e.name.local == 'context' && e.getAttribute('id') == id,
              );
              final member = context.descendants
                  .whereType<XmlElement>()
                  .singleWhere((e) => e.name.local == 'explicitMember');
              member.parent!.children.add(member.copy());
            }),
          ),
          throwsFormatException,
        );
      },
    );
  });
}
