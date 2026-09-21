import '../../generated/protocol.dart';
import '../dart/dart_sections.dart';
import '../dart/dart_values.dart';
import 'disclosure_values.dart';

/// 응답 행 하나와 그 순서·합계 여부.
typedef SourceRow = ({int ord, bool isTotal, Map<String, dynamic> fields});

/// 주요정보 응답 → 원천 행([DisclosureRow])과 타입 층(주주·임원·출자·배당·자기주식).
abstract final class DisclosureRows {
  /// 빈 줄(값이 모두 `-`)을 빼고 순서·합계 여부를 붙인다.
  static ({List<SourceRow> rows, int empty}) prepare(
    List<Map<String, dynamic>> raw,
  ) {
    final rows = <SourceRow>[];
    var empty = 0;
    for (final (i, r) in raw.indexed) {
      if (DisclosureValues.isEmptyRow(r, DartSections.commonFields)) {
        empty++;
        continue;
      }
      rows.add((
        ord: i,
        isTotal: DisclosureValues.isTotalRow(r, DartSections.commonFields),
        fields: r,
      ));
    }
    return (rows: rows, empty: empty);
  }

  /// 이름이 정확히 한 상장사와 같으면 그 기업 id.
  static int? _company(Map<String, int> companiesByName, Object? name) {
    final key = DisclosureValues.companyName(name);
    return key.isEmpty ? null : companiesByName[key];
  }

  static List<ShareholderEntry> shareholders(
    List<SourceRow> rows, {
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required Map<String, int> companiesByName,
  }) => [
    for (final r in rows)
      () {
        final f = r.fields;
        final holderCompany = r.isTotal
            ? null
            : _company(companiesByName, f['nm']);
        return ShareholderEntry(
          reportId: reportId,
          companyId: companyId,
          bsnsYear: bsnsYear,
          ord: r.ord,
          holderName: DisclosureValues.displayName(f['nm']),
          relationText: DartValues.text(f['relate']),
          stockKind: DartValues.text(f['stock_knd']),
          sharesBegin: DisclosureValues.integer(f['bsis_posesn_stock_co']),
          ratioBegin: DisclosureValues.decimal(f['bsis_posesn_stock_qota_rt']),
          sharesEnd: DisclosureValues.integer(f['trmend_posesn_stock_co']),
          ratioEnd: DisclosureValues.decimal(f['trmend_posesn_stock_qota_rt']),
          remark: DartValues.text(f['rm']),
          isTotal: r.isTotal,
          // 자기 자신은 주주 연결에서 뺀다 (자사주를 회사 이름으로 적는 경우).
          holderCompanyId: holderCompany == companyId ? null : holderCompany,
          holderLinkBasis: holderCompany != null && holderCompany != companyId
              ? DisclosureLinkBasis.companyName
              : null,
        );
      }(),
  ];

  static ExecutiveRegistration registration(String? raw) {
    final v = raw?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (v.contains('사내이사')) return ExecutiveRegistration.inside;
    if (v.contains('사외이사')) return ExecutiveRegistration.outside;
    if (v.contains('기타비상무')) return ExecutiveRegistration.nonExecutive;
    if (v.contains('미등기')) return ExecutiveRegistration.unregistered;
    return ExecutiveRegistration.other;
  }

  static List<ExecutiveEntry> executives(
    List<SourceRow> rows, {
    required int reportId,
    required int companyId,
    required int bsnsYear,
  }) => [
    for (final r in rows)
      if (!r.isTotal)
        () {
          final f = r.fields;
          final birth = DisclosureValues.yearMonth(f['birth_ym']);
          final reg = DartValues.text(f['rgist_exctv_at']);
          return ExecutiveEntry(
            reportId: reportId,
            companyId: companyId,
            bsnsYear: bsnsYear,
            ord: r.ord,
            name: DisclosureValues.displayName(f['nm']),
            sex: DartValues.text(f['sexdstn']),
            birthYear: birth?.year,
            birthMonth: birth?.month,
            position: DartValues.text(f['ofcps']),
            registration: registration(reg),
            registrationRaw: reg,
            fullTime: DisclosureValues.fullTime(f['fte_at']),
            duties: DartValues.text(f['chrg_job']),
            career: DartValues.text(f['main_career']),
            relationToLargestHolder: DartValues.text(f['mxmm_shrholdr_relate']),
            tenureMonths: DisclosureValues.months(f['hffc_pd']),
            termEndDate: DisclosureValues.date(f['tenure_end_on']),
          );
        }(),
  ];

  static List<InvestmentEntry> investments(
    List<SourceRow> rows, {
    required int reportId,
    required int companyId,
    required int bsnsYear,
    required Map<String, int> companiesByName,
  }) => [
    for (final r in rows)
      () {
        final f = r.fields;
        final investee = r.isTotal
            ? null
            : _company(companiesByName, f['inv_prm']);
        final linked = investee != null && investee != companyId;
        return InvestmentEntry(
          reportId: reportId,
          companyId: companyId,
          bsnsYear: bsnsYear,
          ord: r.ord,
          investeeName: DisclosureValues.displayName(f['inv_prm']),
          purpose: DartValues.text(f['invstmnt_purps']),
          firstAcquiredOn: DisclosureValues.date(f['frst_acqs_de']),
          firstAcquiredAmount: DisclosureValues.integer(f['frst_acqs_amount']),
          sharesBegin: DisclosureValues.integer(f['bsis_blce_qy']),
          ratioBegin: DisclosureValues.decimal(f['bsis_blce_qota_rt']),
          bookValueBegin: DisclosureValues.integer(
            f['bsis_blce_acntbk_amount'],
          ),
          sharesChange: DisclosureValues.integer(f['incrs_dcrs_acqs_dsps_qy']),
          amountChange: DisclosureValues.integer(
            f['incrs_dcrs_acqs_dsps_amount'],
          ),
          valuationChange: DisclosureValues.integer(f['incrs_dcrs_evl_lstmn']),
          sharesEnd: DisclosureValues.integer(f['trmend_blce_qy']),
          ratioEnd: DisclosureValues.decimal(f['trmend_blce_qota_rt']),
          bookValueEnd: DisclosureValues.integer(
            f['trmend_blce_acntbk_amount'],
          ),
          investeeTotalAssets: DisclosureValues.integer(
            f['recent_bsns_year_fnnr_sttus_tot_assets'],
          ),
          investeeNetIncome: DisclosureValues.integer(
            f['recent_bsns_year_fnnr_sttus_thstrm_ntpf'],
          ),
          isTotal: r.isTotal,
          investeeCompanyId: linked ? investee : null,
          investeeLinkBasis: linked ? DisclosureLinkBasis.companyName : null,
        );
      }(),
  ];

  static List<DividendEntry> dividends(
    List<SourceRow> rows, {
    required int reportId,
    required int companyId,
    required int bsnsYear,
  }) => [
    for (final r in rows)
      () {
        final f = r.fields;
        final item = DisclosureValues.displayName(f['se']);
        return DividendEntry(
          reportId: reportId,
          companyId: companyId,
          bsnsYear: bsnsYear,
          ord: r.ord,
          item: item,
          unit: DisclosureValues.unitOf(item),
          stockKind: DartValues.text(f['stock_knd']),
          current: DisclosureValues.decimal(f['thstrm']),
          prior: DisclosureValues.decimal(f['frmtrm']),
          beforePrior: DisclosureValues.decimal(f['lwfr']),
        );
      }(),
  ];

  static List<TreasuryStockEntry> treasuryStock(
    List<SourceRow> rows, {
    required int reportId,
    required int companyId,
    required int bsnsYear,
  }) => [
    for (final r in rows)
      () {
        final f = r.fields;
        return TreasuryStockEntry(
          reportId: reportId,
          companyId: companyId,
          bsnsYear: bsnsYear,
          ord: r.ord,
          method1: DartValues.text(f['acqs_mth1']),
          method2: DartValues.text(f['acqs_mth2']),
          method3: DartValues.text(f['acqs_mth3']),
          stockKind: DartValues.text(f['stock_knd']),
          sharesBegin: DisclosureValues.integer(f['bsis_qy']),
          acquired: DisclosureValues.integer(f['change_qy_acqs']),
          disposed: DisclosureValues.integer(f['change_qy_dsps']),
          retired: DisclosureValues.integer(f['change_qy_incnr']),
          sharesEnd: DisclosureValues.integer(f['trmend_qy']),
          remark: DartValues.text(f['rm']),
          isTotal: r.isTotal,
        );
      }(),
  ];
}
