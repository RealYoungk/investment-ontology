import '../dart/dart_values.dart';

/// Primary-source field mappings. Decisions are never labelled executed trades.
abstract final class DartResearch {
  static const apis = <String, List<String>>{
    'insiders': ['elestock'],
    'majorHoldings': ['majorstock'],
    'capital': ['piicDecsn', 'cvbdIsDecsn', 'bdwtIsDecsn', 'exbdIsDecsn'],
    'treasury': [
      'tsstkAqDecsn',
      'tsstkDpDecsn',
      'tsstkAqTrctrCnsDecsn',
      'tsstkAqTrctrCcDecsn',
    ],
  };
  static const labels = {
    'piicDecsn': '유상증자 결정',
    'cvbdIsDecsn': '전환사채 발행 결정',
    'bdwtIsDecsn': '신주인수권부사채 발행 결정',
    'exbdIsDecsn': '교환사채 발행 결정',
    'tsstkAqDecsn': '자사주 취득 결정',
    'tsstkDpDecsn': '자사주 처분 결정',
    'tsstkAqTrctrCnsDecsn': '자사주 신탁계약 체결 결정',
    'tsstkAqTrctrCcDecsn': '자사주 신탁계약 해지 결정',
  };
  static const purposes = {
    'fdpp_fclt': '시설투자',
    'fdpp_bsninh': '영업양수',
    'fdpp_op': '운영자금',
    'fdpp_dtrp': '채무상환',
    'fdpp_ocsa': '타법인 증권 취득',
    'fdpp_etc': '기타',
  };
  static String? number(dynamic value, {bool signed = false}) {
    var s = value?.toString().trim().replaceAll(',', '').replaceAll('−', '-');
    if (s == null) return null;
    if (s.startsWith('+')) s = s.substring(1);
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(s)) return null;
    final n = double.tryParse(s);
    return n == null || !n.isFinite || (!signed && n < 0) ? null : s;
  }

  static String? date(dynamic v) {
    final s = v?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (s.length != 8) return null;
    final d = DartValues.ymd(s);
    if (d == null || DartValues.formatYmd(d) != s) return null;
    return d.toIso8601String().substring(0, 10);
  }

  static Map<String, dynamic> normalize(String api, Map<String, dynamic> raw) {
    final receipt = raw['rcept_no']?.toString() ?? '';
    if (!RegExp(r'^\d{14}$').hasMatch(receipt)) {
      throw const FormatException('DART 접수번호 오류');
    }
    final observed = date(raw['rcept_dt']) ?? date(receipt.substring(0, 8));
    if (observed == null) throw const FormatException('DART 접수일 오류');
    final r = <String, dynamic>{
      'date': observed,
      'receipt': receipt,
      'api': api,
      'sourceUrl': 'https://dart.fss.or.kr/dsaf001/main.do?rcpNo=$receipt',
      'raw': raw,
    };
    void n(String target, String field, {bool signed = false}) {
      r[target] = number(raw[field], signed: signed);
    }

    if (api == 'elestock' || api == 'majorstock') {
      final major = api == 'majorstock';
      r['reporter'] = DartValues.text(raw['repror']) ?? '보고자 미확인';
      r['label'] = major ? '대량보유 보고' : '임원·주요주주 소유보고';
      r['reason'] = DartValues.text(
        raw[major ? 'report_resn' : 'isu_exctv_ofcps'],
      );
      r['reportType'] = DartValues.text(raw['report_tp']);
      n('holdings', major ? 'stkqy' : 'sp_stock_lmp_cnt');
      n('change', major ? 'stkqy_irds' : 'sp_stock_lmp_irds_cnt', signed: true);
      n('ratio', major ? 'stkrt' : 'sp_stock_lmp_rate');
      n(
        'ratioChange',
        major ? 'stkrt_irds' : 'sp_stock_lmp_irds_rate',
        signed: true,
      );
      // Ownership change may be a gift, inheritance, conversion or correction.
      r['stage'] = 'reported';
      return r;
    }
    if (!labels.containsKey(api)) {
      throw const FormatException('지원하지 않는 DART 항목');
    }
    r['label'] = labels[api];
    r['stage'] = 'decision';
    r['decisionDate'] =
        date(raw['bddd']) ?? date(raw['aq_dd']) ?? date(raw['dp_dd']);
    r['purposes'] = [
      for (final p in purposes.entries)
        if (number(raw[p.key]) != null)
          {'label': p.value, 'amount': number(raw[p.key])},
    ];
    r['series'] = DartValues.text(raw['bd_tm']);
    n('amount', 'bd_fta');
    n('coupon', 'bd_intr_ex');
    n('maturityRate', 'bd_intr_sf');
    r['maturityDate'] = date(raw['bd_mtd']);
    r['paymentDate'] = date(raw['pymd']);
    if (api == 'piicDecsn') {
      n('shares', 'nstk_ostk_cnt');
      n('otherShares', 'nstk_estk_cnt');
      n('existingShares', 'bfic_tisstk_ostk');
      r['method'] = DartValues.text(raw['ic_mthn']);
    } else if (api == 'cvbdIsDecsn' ||
        api == 'bdwtIsDecsn' ||
        api == 'exbdIsDecsn') {
      final prefix = api == 'cvbdIsDecsn'
          ? 'cvisstk'
          : api == 'bdwtIsDecsn'
          ? 'nstk_isstk'
          : 'extg';
      n('shares', prefix == 'extg' ? 'extg_stkcnt' : '${prefix}_cnt');
      n('ratioToExisting', '${prefix}_tisstk_vs');
      n('conversionPrice', api == 'cvbdIsDecsn' ? 'cv_prc' : 'ex_prc');
      r['stockKind'] = DartValues.text(
        raw[prefix == 'extg' ? 'extg' : '${prefix}_knd'],
      );
      r['exerciseStart'] = date(
        raw[api == 'cvbdIsDecsn' ? 'cvrqpd_bgd' : 'exrqpd_bgd'],
      );
      r['exerciseEnd'] = date(
        raw[api == 'cvbdIsDecsn' ? 'cvrqpd_edd' : 'exrqpd_edd'],
      );
      // EB exchanges existing shares; do not present it as new-share dilution.
      r['newShares'] = api != 'exbdIsDecsn';
    } else {
      final acquire = api == 'tsstkAqDecsn', dispose = api == 'tsstkDpDecsn';
      if (acquire || dispose) {
        final prefix = acquire ? 'aqpln' : 'dppln';
        n('shares', '${prefix}_stk_ostk');
        n('otherShares', '${prefix}_stk_estk');
        n('amount', '${prefix}_prc_ostk');
        n('otherAmount', '${prefix}_prc_estk');
        r['periodStart'] = date(raw[acquire ? 'aqexpd_bgd' : 'dpprpd_bgd']);
        r['periodEnd'] = date(raw[acquire ? 'aqexpd_edd' : 'dpprpd_edd']);
        r['reason'] = DartValues.text(raw[acquire ? 'aq_pp' : 'dp_pp']);
      } else {
        final cancel = api == 'tsstkAqTrctrCcDecsn';
        n('amount', cancel ? 'ctr_prc_bfcc' : 'ctr_prc');
        n('remainingAmount', 'ctr_prc_atcc');
        r['periodStart'] = date(raw[cancel ? 'ctr_pd_bfcc_bgd' : 'ctr_pd_bgd']);
        r['periodEnd'] = date(raw[cancel ? 'ctr_pd_bfcc_edd' : 'ctr_pd_edd']);
        r['reason'] = DartValues.text(raw[cancel ? 'cc_pp' : 'ctr_pp']);
      }
    }
    return r;
  }
}
