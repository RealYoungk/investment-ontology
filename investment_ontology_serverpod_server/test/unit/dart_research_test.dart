import 'package:test/test.dart';
import 'package:investment_ontology_serverpod_server/src/ontology/research/dart_research.dart';

void main() {
  const base = {'rcept_no': '20260901000001', 'corp_code': '00126380'};
  test('ownership dates, signed changes, missing values remain distinct', () {
    final r = DartResearch.normalize('majorstock', {
      ...base,
      'rcept_dt': '20260901',
      'repror': '주주',
      'stkqy': '1,000',
      'stkqy_irds': '-100',
      'stkrt': '5.01',
      'stkrt_irds': '-0.20',
      'report_resn': '증여',
    });
    expect(r['date'], '2026-09-01');
    expect(r['holdings'], '1000');
    expect(r['change'], '-100');
    expect(r['reason'], '증여');
    expect(r['stage'], 'reported');
    expect(DartResearch.number('-'), isNull);
    expect(DartResearch.number('0'), '0');
    expect(DartResearch.date('20260230'), isNull);
  });
  test('rights issue preserves share classes and purpose amounts without inferring total', () {
    final r = DartResearch.normalize('piicDecsn', {
      ...base,
      'nstk_ostk_cnt': '100',
      'nstk_estk_cnt': '20',
      'bfic_tisstk_ostk': '1,000',
      'fdpp_op': '50,000',
      'fdpp_dtrp': '-',
    });
    expect(r['shares'], '100');
    expect(r['otherShares'], '20');
    expect(r['amount'], isNull);
    expect((r['purposes'] as List).single, {
      'label': '운영자금',
      'amount': '50000',
    });
    expect(r['stage'], 'decision');
  });
  test(
    'EB is exchange, never new-share dilution; CB retains stated share count',
    () {
      final eb = DartResearch.normalize('exbdIsDecsn', {
        ...base,
        'extg_stkcnt': '200',
        'extg_tisstk_vs': '10',
      });
      expect(eb['newShares'], false);
      expect(eb['shares'], '200');
      final cb = DartResearch.normalize('cvbdIsDecsn', {
        ...base,
        'bd_fta': '10000',
        'cv_prc': '3',
        'cvisstk_cnt': '3333',
      });
      expect(cb['shares'], '3333');
      expect(cb['newShares'], true);
    },
  );
  test('trust termination is a decision, never claimed completed purchase', () {
    final r = DartResearch.normalize('tsstkAqTrctrCcDecsn', {
      ...base,
      'ctr_prc_bfcc': '10000',
      'ctr_prc_atcc': '0',
    });
    expect(r['amount'], '10000');
    expect(r['remainingAmount'], '0');
    expect(r['stage'], 'decision');
    expect(r.containsKey('executed'), false);
  });
  test(
    'missing board date falls back to disclosed acquisition decision date',
    () {
      final r = DartResearch.normalize('tsstkAqDecsn', {
        ...base,
        'bddd': '-',
        'aq_dd': '2026년 08월 31일',
      });
      expect(r['decisionDate'], '2026-08-31');
    },
  );
  test('bad receipts and arbitrary endpoints rejected', () {
    expect(
      () => DartResearch.normalize('elestock', {'rcept_no': '../evil'}),
      throwsFormatException,
    );
    expect(
      () => DartResearch.normalize('unknown', base),
      throwsFormatException,
    );
  });
}
