/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/billing/billing_payment_view.dart'
    as _isqvkvoy;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/account_view.dart'
    as _ih9nljg3;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/business_digest_section.dart'
    as _i5qsmr7t;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/business_document_ref.dart'
    as _id7v70oo;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/business_fact_period.dart'
    as _irhba4h9;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_group.dart'
    as _i7uvzrch;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/company_market_cap.dart'
    as _idnoq35n;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/dart_disclosure.dart'
    as _izt0hsdc;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/disclosure_section_info.dart'
    as _i39r1xmm;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/document_fact.dart'
    as _ip7x5uw8;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/facet_count.dart'
    as _icfgas7c;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/filing_feed_item.dart'
    as _iuq4bocx;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ingest_job.dart'
    as _i1paap7y;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ingest_schedule_entry.dart'
    as _idevncao;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/investment_theme.dart'
    as _izhmhfon;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/macro_series_view.dart'
    as _ijzi50sx;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/market_cap_point.dart'
    as _i140v7gk;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/new_company_view.dart'
    as _iodca1gh;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/ownership_snapshot.dart'
    as _iz9gjubn;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/person_hit.dart'
    as _i96d117e;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/review_check.dart'
    as _ixhvmecn;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/review_item.dart'
    as _ihqozc6p;
import 'package:investment_ontology_serverpod_client/src/protocol/ontology/models/theme_summary.dart'
    as _ihj01hrs;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'ontology/billing/billing_checkout_view.dart' as _iybkvk8h;
import 'ontology/billing/billing_payment_view.dart' as _i4b9wxd2;
import 'ontology/billing/membership_view.dart' as _ikugrjyl;
import 'ontology/models/account_view.dart' as _i7n6g9s8;
import 'ontology/models/ai_extraction.dart' as _idjojx8t;
import 'ontology/models/ai_status.dart' as _i7c6k6qa;
import 'ontology/models/api_call_usage.dart' as _i3e42he1;
import 'ontology/models/api_provider.dart' as _i82zif2r;
import 'ontology/models/business_content.dart' as _ik6lqqsr;
import 'ontology/models/business_digest_kind.dart' as _izxiijmh;
import 'ontology/models/business_digest_section.dart' as _iq2bjjp3;
import 'ontology/models/business_document.dart' as _imi0q911;
import 'ontology/models/business_document_ref.dart' as _is707pet;
import 'ontology/models/business_fact_period.dart' as _i1cpvxoo;
import 'ontology/models/business_product.dart' as _i3peg7yx;
import 'ontology/models/business_profile.dart' as _iegef18i;
import 'ontology/models/business_section.dart' as _inylkhjt;
import 'ontology/models/business_table_insight.dart' as _i0vnq5ds;
import 'ontology/models/business_table_measure.dart' as _ia821tg8;
import 'ontology/models/business_table_record.dart' as _i5mz554b;
import 'ontology/models/business_understanding.dart' as _iwkhf8pb;
import 'ontology/models/company.dart' as _ipen255x;
import 'ontology/models/company_change.dart' as _isfozywu;
import 'ontology/models/company_detail.dart' as _ire9jjud;
import 'ontology/models/company_financials.dart' as _iki0y6e6;
import 'ontology/models/company_governance.dart' as _ijqcijwd;
import 'ontology/models/company_graph.dart' as _ixtgihs0;
import 'ontology/models/company_group.dart' as _ihdcqaon;
import 'ontology/models/company_list_item.dart' as _i0csqxj4;
import 'ontology/models/company_market_cap.dart' as _it4u3ib3;
import 'ontology/models/company_news_feed.dart' as _izcvpxxd;
import 'ontology/models/company_news_item.dart' as _iiky47zh;
import 'ontology/models/company_page.dart' as _iaj9eyri;
import 'ontology/models/company_ref.dart' as _i4gnucl8;
import 'ontology/models/company_sort.dart' as _ia2izjbq;
import 'ontology/models/dart_corp_status.dart' as _ir49pw6i;
import 'ontology/models/dart_disclosure.dart' as _iw06ztex;
import 'ontology/models/dart_filing.dart' as _itki3qdq;
import 'ontology/models/dart_filing_scan.dart' as _ixr5w3gq;
import 'ontology/models/dart_filing_section.dart' as _isprzv4c;
import 'ontology/models/dart_section.dart' as _islomtus;
import 'ontology/models/disclosure_link_basis.dart' as _iffxd3r6;
import 'ontology/models/disclosure_report.dart' as _i4blf95b;
import 'ontology/models/disclosure_row.dart' as _irf27uzx;
import 'ontology/models/disclosure_section_info.dart' as _ij0mhdco;
import 'ontology/models/disclosure_table.dart' as _i7prd3sw;
import 'ontology/models/disclosure_table_row.dart' as _i98o73zd;
import 'ontology/models/dividend_entry.dart' as _ith4ion6;
import 'ontology/models/document_fact.dart' as _iy6p3omn;
import 'ontology/models/document_fact_kind.dart' as _iatg4403;
import 'ontology/models/exceptions.dart' as _iqc95j34;
import 'ontology/models/executive_entry.dart' as _i3df9cy5;
import 'ontology/models/executive_registration.dart' as _iz7k3x6v;
import 'ontology/models/facet_count.dart' as _iqbvehdv;
import 'ontology/models/fact_item.dart' as _iawn4ngl;
import 'ontology/models/fact_page.dart' as _iurbyopj;
import 'ontology/models/filing_feed_item.dart' as _iivg0zeh;
import 'ontology/models/filing_fetch_status.dart' as _i167q75d;
import 'ontology/models/financial_fact.dart' as _igykxm42;
import 'ontology/models/financial_line.dart' as _igzbjepn;
import 'ontology/models/financial_period.dart' as _itz8g04g;
import 'ontology/models/financial_report.dart' as _i1qwjg2x;
import 'ontology/models/financial_report_code.dart' as _idwohplt;
import 'ontology/models/financial_report_detail.dart' as _ia8vdu33;
import 'ontology/models/financial_statement_kind.dart' as _im4itn08;
import 'ontology/models/fs_div.dart' as _i906z99z;
import 'ontology/models/governance_link.dart' as _ikth1mft;
import 'ontology/models/graph_edge.dart' as _iamhnwn8;
import 'ontology/models/graph_node.dart' as _iqv6eyci;
import 'ontology/models/group_edge.dart' as _i1fyp5lv;
import 'ontology/models/group_member.dart' as _iyd2zx8r;
import 'ontology/models/group_person.dart' as _iklt0jfv;
import 'ontology/models/index_history.dart' as _iocwvagy;
import 'ontology/models/index_point.dart' as _it75qdkc;
import 'ontology/models/industry.dart' as _i3hzx3f1;
import 'ontology/models/industry_activity.dart' as _if5qperq;
import 'ontology/models/industry_discovery.dart' as _ixuxxo68;
import 'ontology/models/industry_revision_check.dart' as _i25uuckt;
import 'ontology/models/ingest_coverage.dart' as _il0sbv1h;
import 'ontology/models/ingest_job.dart' as _iay1heal;
import 'ontology/models/ingest_schedule_entry.dart' as _ilyxu1av;
import 'ontology/models/ingest_status.dart' as _imojj26x;
import 'ontology/models/investment_entry.dart' as _i9p8kpm7;
import 'ontology/models/investment_theme.dart' as _i57inxpq;
import 'ontology/models/macro_series_view.dart' as _id0q6lal;
import 'ontology/models/market.dart' as _iyzzhewo;
import 'ontology/models/market_cap_node.dart' as _i1tskjhh;
import 'ontology/models/market_cap_point.dart' as _igdvszti;
import 'ontology/models/market_cap_treemap.dart' as _iwodvuy1;
import 'ontology/models/market_index_day.dart' as _ihawso0m;
import 'ontology/models/market_index_snapshot.dart' as _i9c8jqc3;
import 'ontology/models/market_snapshot.dart' as _ibhowe7d;
import 'ontology/models/market_snapshot_day.dart' as _i3renazk;
import 'ontology/models/new_company_view.dart' as _ivtwhw6z;
import 'ontology/models/ontology_relation.dart' as _iejnlir1;
import 'ontology/models/overview.dart' as _iz31wbgv;
import 'ontology/models/ownership_snapshot.dart' as _ilc2cd4p;
import 'ontology/models/peer_candidate.dart' as _i6cusig8;
import 'ontology/models/peer_candidates.dart' as _i59onhk4;
import 'ontology/models/peer_comparison.dart' as _isobo9h5;
import 'ontology/models/peer_metric.dart' as _iihutb4k;
import 'ontology/models/peer_profile.dart' as _iwm08ow1;
import 'ontology/models/peer_signal.dart' as _i8bwgp5o;
import 'ontology/models/person.dart' as _i9gy9ys0;
import 'ontology/models/person_hit.dart' as _iyxi6nm4;
import 'ontology/models/person_link_rejection.dart' as _iffou6wp;
import 'ontology/models/person_profile.dart' as _i12ugm17;
import 'ontology/models/person_role.dart' as _ipnxekll;
import 'ontology/models/price_history.dart' as _i451wru0;
import 'ontology/models/price_point.dart' as _iyfyllvz;
import 'ontology/models/relation_fact_kind.dart' as _iy288i3j;
import 'ontology/models/relation_origin.dart' as _id1oen7t;
import 'ontology/models/relation_predicate.dart' as _idal2dwe;
import 'ontology/models/relation_status.dart' as _ih00v9tp;
import 'ontology/models/research_article.dart' as _i83xfi8m;
import 'ontology/models/research_bookmark.dart' as _iofl85o3;
import 'ontology/models/research_revision.dart' as _iwk8vi27;
import 'ontology/models/research_snapshot.dart' as _iwd80rqd;
import 'ontology/models/review_check.dart' as _iqdwyhyy;
import 'ontology/models/review_context.dart' as _ijdr1ucd;
import 'ontology/models/review_item.dart' as _i6uduqoi;
import 'ontology/models/review_page.dart' as _i22wlf7g;
import 'ontology/models/screen_page.dart' as _izca0w44;
import 'ontology/models/screen_row.dart' as _ie748vep;
import 'ontology/models/screen_sort.dart' as _igeg1iky;
import 'ontology/models/security.dart' as _ilujots3;
import 'ontology/models/security_link_basis.dart' as _ic799xum;
import 'ontology/models/security_quote.dart' as _ionn6cq2;
import 'ontology/models/shareholder_entry.dart' as _itljah4k;
import 'ontology/models/shareholder_return.dart' as _iiit8m20;
import 'ontology/models/source.dart' as _icm1zoh2;
import 'ontology/models/source_kind.dart' as _itk5lja3;
import 'ontology/models/stock_total_row.dart' as _i3sjboun;
import 'ontology/models/theme_detail.dart' as _ir3er3o6;
import 'ontology/models/theme_member.dart' as _irm69cop;
import 'ontology/models/theme_member_view.dart' as _irah5hi6;
import 'ontology/models/theme_summary.dart' as _i4ynus9k;
import 'ontology/models/treasury_stock_entry.dart' as _injn1qca;
import 'ontology/models/watchlist_company_view.dart' as _is2pxpv6;
import 'ontology/models/watchlist_error.dart' as _ivan2n9m;
import 'ontology/models/watchlist_update_view.dart' as _ijbmrc2g;
import 'ontology/models/watchlist_view.dart' as _iyb0jzxs;
export 'greetings/greeting.dart';
export 'ontology/billing/billing_checkout_view.dart';
export 'ontology/billing/billing_payment_view.dart';
export 'ontology/billing/membership_view.dart';
export 'ontology/models/account_view.dart';
export 'ontology/models/ai_extraction.dart';
export 'ontology/models/ai_status.dart';
export 'ontology/models/api_call_usage.dart';
export 'ontology/models/api_provider.dart';
export 'ontology/models/business_content.dart';
export 'ontology/models/business_digest_kind.dart';
export 'ontology/models/business_digest_section.dart';
export 'ontology/models/business_document.dart';
export 'ontology/models/business_document_ref.dart';
export 'ontology/models/business_fact_period.dart';
export 'ontology/models/business_product.dart';
export 'ontology/models/business_profile.dart';
export 'ontology/models/business_section.dart';
export 'ontology/models/business_table_insight.dart';
export 'ontology/models/business_table_measure.dart';
export 'ontology/models/business_table_record.dart';
export 'ontology/models/business_understanding.dart';
export 'ontology/models/company.dart';
export 'ontology/models/company_change.dart';
export 'ontology/models/company_detail.dart';
export 'ontology/models/company_financials.dart';
export 'ontology/models/company_governance.dart';
export 'ontology/models/company_graph.dart';
export 'ontology/models/company_group.dart';
export 'ontology/models/company_list_item.dart';
export 'ontology/models/company_market_cap.dart';
export 'ontology/models/company_news_feed.dart';
export 'ontology/models/company_news_item.dart';
export 'ontology/models/company_page.dart';
export 'ontology/models/company_ref.dart';
export 'ontology/models/company_sort.dart';
export 'ontology/models/dart_corp_status.dart';
export 'ontology/models/dart_disclosure.dart';
export 'ontology/models/dart_filing.dart';
export 'ontology/models/dart_filing_scan.dart';
export 'ontology/models/dart_filing_section.dart';
export 'ontology/models/dart_section.dart';
export 'ontology/models/disclosure_link_basis.dart';
export 'ontology/models/disclosure_report.dart';
export 'ontology/models/disclosure_row.dart';
export 'ontology/models/disclosure_section_info.dart';
export 'ontology/models/disclosure_table.dart';
export 'ontology/models/disclosure_table_row.dart';
export 'ontology/models/dividend_entry.dart';
export 'ontology/models/document_fact.dart';
export 'ontology/models/document_fact_kind.dart';
export 'ontology/models/exceptions.dart';
export 'ontology/models/executive_entry.dart';
export 'ontology/models/executive_registration.dart';
export 'ontology/models/facet_count.dart';
export 'ontology/models/fact_item.dart';
export 'ontology/models/fact_page.dart';
export 'ontology/models/filing_feed_item.dart';
export 'ontology/models/filing_fetch_status.dart';
export 'ontology/models/financial_fact.dart';
export 'ontology/models/financial_line.dart';
export 'ontology/models/financial_period.dart';
export 'ontology/models/financial_report.dart';
export 'ontology/models/financial_report_code.dart';
export 'ontology/models/financial_report_detail.dart';
export 'ontology/models/financial_statement_kind.dart';
export 'ontology/models/fs_div.dart';
export 'ontology/models/governance_link.dart';
export 'ontology/models/graph_edge.dart';
export 'ontology/models/graph_node.dart';
export 'ontology/models/group_edge.dart';
export 'ontology/models/group_member.dart';
export 'ontology/models/group_person.dart';
export 'ontology/models/index_history.dart';
export 'ontology/models/index_point.dart';
export 'ontology/models/industry.dart';
export 'ontology/models/industry_activity.dart';
export 'ontology/models/industry_discovery.dart';
export 'ontology/models/industry_revision_check.dart';
export 'ontology/models/ingest_coverage.dart';
export 'ontology/models/ingest_job.dart';
export 'ontology/models/ingest_schedule_entry.dart';
export 'ontology/models/ingest_status.dart';
export 'ontology/models/investment_entry.dart';
export 'ontology/models/investment_theme.dart';
export 'ontology/models/macro_series_view.dart';
export 'ontology/models/market.dart';
export 'ontology/models/market_cap_node.dart';
export 'ontology/models/market_cap_point.dart';
export 'ontology/models/market_cap_treemap.dart';
export 'ontology/models/market_index_day.dart';
export 'ontology/models/market_index_snapshot.dart';
export 'ontology/models/market_snapshot.dart';
export 'ontology/models/market_snapshot_day.dart';
export 'ontology/models/new_company_view.dart';
export 'ontology/models/ontology_relation.dart';
export 'ontology/models/overview.dart';
export 'ontology/models/ownership_snapshot.dart';
export 'ontology/models/peer_candidate.dart';
export 'ontology/models/peer_candidates.dart';
export 'ontology/models/peer_comparison.dart';
export 'ontology/models/peer_metric.dart';
export 'ontology/models/peer_profile.dart';
export 'ontology/models/peer_signal.dart';
export 'ontology/models/person.dart';
export 'ontology/models/person_hit.dart';
export 'ontology/models/person_link_rejection.dart';
export 'ontology/models/person_profile.dart';
export 'ontology/models/person_role.dart';
export 'ontology/models/price_history.dart';
export 'ontology/models/price_point.dart';
export 'ontology/models/relation_fact_kind.dart';
export 'ontology/models/relation_origin.dart';
export 'ontology/models/relation_predicate.dart';
export 'ontology/models/relation_status.dart';
export 'ontology/models/research_article.dart';
export 'ontology/models/research_bookmark.dart';
export 'ontology/models/research_revision.dart';
export 'ontology/models/research_snapshot.dart';
export 'ontology/models/review_check.dart';
export 'ontology/models/review_context.dart';
export 'ontology/models/review_item.dart';
export 'ontology/models/review_page.dart';
export 'ontology/models/screen_page.dart';
export 'ontology/models/screen_row.dart';
export 'ontology/models/screen_sort.dart';
export 'ontology/models/security.dart';
export 'ontology/models/security_link_basis.dart';
export 'ontology/models/security_quote.dart';
export 'ontology/models/shareholder_entry.dart';
export 'ontology/models/shareholder_return.dart';
export 'ontology/models/source.dart';
export 'ontology/models/source_kind.dart';
export 'ontology/models/stock_total_row.dart';
export 'ontology/models/theme_detail.dart';
export 'ontology/models/theme_member.dart';
export 'ontology/models/theme_member_view.dart';
export 'ontology/models/theme_summary.dart';
export 'ontology/models/treasury_stock_entry.dart';
export 'ontology/models/watchlist_company_view.dart';
export 'ontology/models/watchlist_error.dart';
export 'ontology/models/watchlist_update_view.dart';
export 'ontology/models/watchlist_view.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _iybkvk8h.BillingCheckoutView) {
      return _iybkvk8h.BillingCheckoutView.fromJson(data) as T;
    }
    if (t == _i4b9wxd2.BillingPaymentView) {
      return _i4b9wxd2.BillingPaymentView.fromJson(data) as T;
    }
    if (t == _ikugrjyl.MembershipView) {
      return _ikugrjyl.MembershipView.fromJson(data) as T;
    }
    if (t == _i7n6g9s8.AccountView) {
      return _i7n6g9s8.AccountView.fromJson(data) as T;
    }
    if (t == _idjojx8t.AiExtraction) {
      return _idjojx8t.AiExtraction.fromJson(data) as T;
    }
    if (t == _i7c6k6qa.AiStatus) {
      return _i7c6k6qa.AiStatus.fromJson(data) as T;
    }
    if (t == _i3e42he1.ApiCallUsage) {
      return _i3e42he1.ApiCallUsage.fromJson(data) as T;
    }
    if (t == _i82zif2r.ApiProvider) {
      return _i82zif2r.ApiProvider.fromJson(data) as T;
    }
    if (t == _ik6lqqsr.BusinessContent) {
      return _ik6lqqsr.BusinessContent.fromJson(data) as T;
    }
    if (t == _izxiijmh.BusinessDigestKind) {
      return _izxiijmh.BusinessDigestKind.fromJson(data) as T;
    }
    if (t == _iq2bjjp3.BusinessDigestSection) {
      return _iq2bjjp3.BusinessDigestSection.fromJson(data) as T;
    }
    if (t == _imi0q911.BusinessDocument) {
      return _imi0q911.BusinessDocument.fromJson(data) as T;
    }
    if (t == _is707pet.BusinessDocumentRef) {
      return _is707pet.BusinessDocumentRef.fromJson(data) as T;
    }
    if (t == _i1cpvxoo.BusinessFactPeriod) {
      return _i1cpvxoo.BusinessFactPeriod.fromJson(data) as T;
    }
    if (t == _i3peg7yx.BusinessProduct) {
      return _i3peg7yx.BusinessProduct.fromJson(data) as T;
    }
    if (t == _iegef18i.BusinessProfile) {
      return _iegef18i.BusinessProfile.fromJson(data) as T;
    }
    if (t == _inylkhjt.BusinessSection) {
      return _inylkhjt.BusinessSection.fromJson(data) as T;
    }
    if (t == _i0vnq5ds.BusinessTableInsight) {
      return _i0vnq5ds.BusinessTableInsight.fromJson(data) as T;
    }
    if (t == _ia821tg8.BusinessTableMeasure) {
      return _ia821tg8.BusinessTableMeasure.fromJson(data) as T;
    }
    if (t == _i5mz554b.BusinessTableRecord) {
      return _i5mz554b.BusinessTableRecord.fromJson(data) as T;
    }
    if (t == _iwkhf8pb.BusinessUnderstanding) {
      return _iwkhf8pb.BusinessUnderstanding.fromJson(data) as T;
    }
    if (t == _ipen255x.Company) {
      return _ipen255x.Company.fromJson(data) as T;
    }
    if (t == _isfozywu.CompanyChange) {
      return _isfozywu.CompanyChange.fromJson(data) as T;
    }
    if (t == _ire9jjud.CompanyDetail) {
      return _ire9jjud.CompanyDetail.fromJson(data) as T;
    }
    if (t == _iki0y6e6.CompanyFinancials) {
      return _iki0y6e6.CompanyFinancials.fromJson(data) as T;
    }
    if (t == _ijqcijwd.CompanyGovernance) {
      return _ijqcijwd.CompanyGovernance.fromJson(data) as T;
    }
    if (t == _ixtgihs0.CompanyGraph) {
      return _ixtgihs0.CompanyGraph.fromJson(data) as T;
    }
    if (t == _ihdcqaon.CompanyGroup) {
      return _ihdcqaon.CompanyGroup.fromJson(data) as T;
    }
    if (t == _i0csqxj4.CompanyListItem) {
      return _i0csqxj4.CompanyListItem.fromJson(data) as T;
    }
    if (t == _it4u3ib3.CompanyMarketCap) {
      return _it4u3ib3.CompanyMarketCap.fromJson(data) as T;
    }
    if (t == _izcvpxxd.CompanyNewsFeed) {
      return _izcvpxxd.CompanyNewsFeed.fromJson(data) as T;
    }
    if (t == _iiky47zh.CompanyNewsItem) {
      return _iiky47zh.CompanyNewsItem.fromJson(data) as T;
    }
    if (t == _iaj9eyri.CompanyPage) {
      return _iaj9eyri.CompanyPage.fromJson(data) as T;
    }
    if (t == _i4gnucl8.CompanyRef) {
      return _i4gnucl8.CompanyRef.fromJson(data) as T;
    }
    if (t == _ia2izjbq.CompanySort) {
      return _ia2izjbq.CompanySort.fromJson(data) as T;
    }
    if (t == _ir49pw6i.DartCorpStatus) {
      return _ir49pw6i.DartCorpStatus.fromJson(data) as T;
    }
    if (t == _iw06ztex.DartDisclosure) {
      return _iw06ztex.DartDisclosure.fromJson(data) as T;
    }
    if (t == _itki3qdq.DartFiling) {
      return _itki3qdq.DartFiling.fromJson(data) as T;
    }
    if (t == _ixr5w3gq.DartFilingScan) {
      return _ixr5w3gq.DartFilingScan.fromJson(data) as T;
    }
    if (t == _isprzv4c.DartFilingSection) {
      return _isprzv4c.DartFilingSection.fromJson(data) as T;
    }
    if (t == _islomtus.DartSection) {
      return _islomtus.DartSection.fromJson(data) as T;
    }
    if (t == _iffxd3r6.DisclosureLinkBasis) {
      return _iffxd3r6.DisclosureLinkBasis.fromJson(data) as T;
    }
    if (t == _i4blf95b.DisclosureReport) {
      return _i4blf95b.DisclosureReport.fromJson(data) as T;
    }
    if (t == _irf27uzx.DisclosureRow) {
      return _irf27uzx.DisclosureRow.fromJson(data) as T;
    }
    if (t == _ij0mhdco.DisclosureSectionInfo) {
      return _ij0mhdco.DisclosureSectionInfo.fromJson(data) as T;
    }
    if (t == _i7prd3sw.DisclosureTable) {
      return _i7prd3sw.DisclosureTable.fromJson(data) as T;
    }
    if (t == _i98o73zd.DisclosureTableRow) {
      return _i98o73zd.DisclosureTableRow.fromJson(data) as T;
    }
    if (t == _ith4ion6.DividendEntry) {
      return _ith4ion6.DividendEntry.fromJson(data) as T;
    }
    if (t == _iy6p3omn.DocumentFact) {
      return _iy6p3omn.DocumentFact.fromJson(data) as T;
    }
    if (t == _iatg4403.DocumentFactKind) {
      return _iatg4403.DocumentFactKind.fromJson(data) as T;
    }
    if (t == _iqc95j34.IngestException) {
      return _iqc95j34.IngestException.fromJson(data) as T;
    }
    if (t == _i3df9cy5.ExecutiveEntry) {
      return _i3df9cy5.ExecutiveEntry.fromJson(data) as T;
    }
    if (t == _iz7k3x6v.ExecutiveRegistration) {
      return _iz7k3x6v.ExecutiveRegistration.fromJson(data) as T;
    }
    if (t == _iqbvehdv.FacetCount) {
      return _iqbvehdv.FacetCount.fromJson(data) as T;
    }
    if (t == _iawn4ngl.FactItem) {
      return _iawn4ngl.FactItem.fromJson(data) as T;
    }
    if (t == _iurbyopj.FactPage) {
      return _iurbyopj.FactPage.fromJson(data) as T;
    }
    if (t == _iivg0zeh.FilingFeedItem) {
      return _iivg0zeh.FilingFeedItem.fromJson(data) as T;
    }
    if (t == _i167q75d.FilingFetchStatus) {
      return _i167q75d.FilingFetchStatus.fromJson(data) as T;
    }
    if (t == _igykxm42.FinancialFact) {
      return _igykxm42.FinancialFact.fromJson(data) as T;
    }
    if (t == _igzbjepn.FinancialLine) {
      return _igzbjepn.FinancialLine.fromJson(data) as T;
    }
    if (t == _itz8g04g.FinancialPeriod) {
      return _itz8g04g.FinancialPeriod.fromJson(data) as T;
    }
    if (t == _i1qwjg2x.FinancialReport) {
      return _i1qwjg2x.FinancialReport.fromJson(data) as T;
    }
    if (t == _idwohplt.FinancialReportCode) {
      return _idwohplt.FinancialReportCode.fromJson(data) as T;
    }
    if (t == _ia8vdu33.FinancialReportDetail) {
      return _ia8vdu33.FinancialReportDetail.fromJson(data) as T;
    }
    if (t == _im4itn08.FinancialStatementKind) {
      return _im4itn08.FinancialStatementKind.fromJson(data) as T;
    }
    if (t == _i906z99z.FsDiv) {
      return _i906z99z.FsDiv.fromJson(data) as T;
    }
    if (t == _ikth1mft.GovernanceLink) {
      return _ikth1mft.GovernanceLink.fromJson(data) as T;
    }
    if (t == _iamhnwn8.GraphEdge) {
      return _iamhnwn8.GraphEdge.fromJson(data) as T;
    }
    if (t == _iqv6eyci.GraphNode) {
      return _iqv6eyci.GraphNode.fromJson(data) as T;
    }
    if (t == _i1fyp5lv.GroupEdge) {
      return _i1fyp5lv.GroupEdge.fromJson(data) as T;
    }
    if (t == _iyd2zx8r.GroupMember) {
      return _iyd2zx8r.GroupMember.fromJson(data) as T;
    }
    if (t == _iklt0jfv.GroupPerson) {
      return _iklt0jfv.GroupPerson.fromJson(data) as T;
    }
    if (t == _iocwvagy.IndexHistory) {
      return _iocwvagy.IndexHistory.fromJson(data) as T;
    }
    if (t == _it75qdkc.IndexPoint) {
      return _it75qdkc.IndexPoint.fromJson(data) as T;
    }
    if (t == _i3hzx3f1.Industry) {
      return _i3hzx3f1.Industry.fromJson(data) as T;
    }
    if (t == _if5qperq.IndustryActivity) {
      return _if5qperq.IndustryActivity.fromJson(data) as T;
    }
    if (t == _ixuxxo68.IndustryDiscovery) {
      return _ixuxxo68.IndustryDiscovery.fromJson(data) as T;
    }
    if (t == _i25uuckt.IndustryRevisionCheck) {
      return _i25uuckt.IndustryRevisionCheck.fromJson(data) as T;
    }
    if (t == _il0sbv1h.IngestCoverage) {
      return _il0sbv1h.IngestCoverage.fromJson(data) as T;
    }
    if (t == _iay1heal.IngestJob) {
      return _iay1heal.IngestJob.fromJson(data) as T;
    }
    if (t == _ilyxu1av.IngestScheduleEntry) {
      return _ilyxu1av.IngestScheduleEntry.fromJson(data) as T;
    }
    if (t == _imojj26x.IngestStatus) {
      return _imojj26x.IngestStatus.fromJson(data) as T;
    }
    if (t == _i9p8kpm7.InvestmentEntry) {
      return _i9p8kpm7.InvestmentEntry.fromJson(data) as T;
    }
    if (t == _i57inxpq.InvestmentTheme) {
      return _i57inxpq.InvestmentTheme.fromJson(data) as T;
    }
    if (t == _id0q6lal.MacroSeriesView) {
      return _id0q6lal.MacroSeriesView.fromJson(data) as T;
    }
    if (t == _iyzzhewo.Market) {
      return _iyzzhewo.Market.fromJson(data) as T;
    }
    if (t == _i1tskjhh.MarketCapNode) {
      return _i1tskjhh.MarketCapNode.fromJson(data) as T;
    }
    if (t == _igdvszti.MarketCapPoint) {
      return _igdvszti.MarketCapPoint.fromJson(data) as T;
    }
    if (t == _iwodvuy1.MarketCapTreemap) {
      return _iwodvuy1.MarketCapTreemap.fromJson(data) as T;
    }
    if (t == _ihawso0m.MarketIndexDay) {
      return _ihawso0m.MarketIndexDay.fromJson(data) as T;
    }
    if (t == _i9c8jqc3.MarketIndexSnapshot) {
      return _i9c8jqc3.MarketIndexSnapshot.fromJson(data) as T;
    }
    if (t == _ibhowe7d.MarketSnapshot) {
      return _ibhowe7d.MarketSnapshot.fromJson(data) as T;
    }
    if (t == _i3renazk.MarketSnapshotDay) {
      return _i3renazk.MarketSnapshotDay.fromJson(data) as T;
    }
    if (t == _ivtwhw6z.NewCompanyView) {
      return _ivtwhw6z.NewCompanyView.fromJson(data) as T;
    }
    if (t == _iejnlir1.OntologyRelation) {
      return _iejnlir1.OntologyRelation.fromJson(data) as T;
    }
    if (t == _iz31wbgv.Overview) {
      return _iz31wbgv.Overview.fromJson(data) as T;
    }
    if (t == _ilc2cd4p.OwnershipSnapshot) {
      return _ilc2cd4p.OwnershipSnapshot.fromJson(data) as T;
    }
    if (t == _i6cusig8.PeerCandidate) {
      return _i6cusig8.PeerCandidate.fromJson(data) as T;
    }
    if (t == _i59onhk4.PeerCandidates) {
      return _i59onhk4.PeerCandidates.fromJson(data) as T;
    }
    if (t == _isobo9h5.PeerComparison) {
      return _isobo9h5.PeerComparison.fromJson(data) as T;
    }
    if (t == _iihutb4k.PeerMetric) {
      return _iihutb4k.PeerMetric.fromJson(data) as T;
    }
    if (t == _iwm08ow1.PeerProfile) {
      return _iwm08ow1.PeerProfile.fromJson(data) as T;
    }
    if (t == _i8bwgp5o.PeerSignal) {
      return _i8bwgp5o.PeerSignal.fromJson(data) as T;
    }
    if (t == _i9gy9ys0.Person) {
      return _i9gy9ys0.Person.fromJson(data) as T;
    }
    if (t == _iyxi6nm4.PersonHit) {
      return _iyxi6nm4.PersonHit.fromJson(data) as T;
    }
    if (t == _iffou6wp.PersonLinkRejection) {
      return _iffou6wp.PersonLinkRejection.fromJson(data) as T;
    }
    if (t == _i12ugm17.PersonProfile) {
      return _i12ugm17.PersonProfile.fromJson(data) as T;
    }
    if (t == _ipnxekll.PersonRole) {
      return _ipnxekll.PersonRole.fromJson(data) as T;
    }
    if (t == _i451wru0.PriceHistory) {
      return _i451wru0.PriceHistory.fromJson(data) as T;
    }
    if (t == _iyfyllvz.PricePoint) {
      return _iyfyllvz.PricePoint.fromJson(data) as T;
    }
    if (t == _iy288i3j.RelationFactKind) {
      return _iy288i3j.RelationFactKind.fromJson(data) as T;
    }
    if (t == _id1oen7t.RelationOrigin) {
      return _id1oen7t.RelationOrigin.fromJson(data) as T;
    }
    if (t == _idal2dwe.RelationPredicate) {
      return _idal2dwe.RelationPredicate.fromJson(data) as T;
    }
    if (t == _ih00v9tp.RelationStatus) {
      return _ih00v9tp.RelationStatus.fromJson(data) as T;
    }
    if (t == _i83xfi8m.ResearchArticle) {
      return _i83xfi8m.ResearchArticle.fromJson(data) as T;
    }
    if (t == _iofl85o3.ResearchBookmark) {
      return _iofl85o3.ResearchBookmark.fromJson(data) as T;
    }
    if (t == _iwk8vi27.ResearchRevision) {
      return _iwk8vi27.ResearchRevision.fromJson(data) as T;
    }
    if (t == _iwd80rqd.ResearchSnapshot) {
      return _iwd80rqd.ResearchSnapshot.fromJson(data) as T;
    }
    if (t == _iqdwyhyy.ReviewCheck) {
      return _iqdwyhyy.ReviewCheck.fromJson(data) as T;
    }
    if (t == _ijdr1ucd.ReviewContext) {
      return _ijdr1ucd.ReviewContext.fromJson(data) as T;
    }
    if (t == _i6uduqoi.ReviewItem) {
      return _i6uduqoi.ReviewItem.fromJson(data) as T;
    }
    if (t == _i22wlf7g.ReviewPage) {
      return _i22wlf7g.ReviewPage.fromJson(data) as T;
    }
    if (t == _izca0w44.ScreenPage) {
      return _izca0w44.ScreenPage.fromJson(data) as T;
    }
    if (t == _ie748vep.ScreenRow) {
      return _ie748vep.ScreenRow.fromJson(data) as T;
    }
    if (t == _igeg1iky.ScreenSort) {
      return _igeg1iky.ScreenSort.fromJson(data) as T;
    }
    if (t == _ilujots3.Security) {
      return _ilujots3.Security.fromJson(data) as T;
    }
    if (t == _ic799xum.SecurityLinkBasis) {
      return _ic799xum.SecurityLinkBasis.fromJson(data) as T;
    }
    if (t == _ionn6cq2.SecurityQuote) {
      return _ionn6cq2.SecurityQuote.fromJson(data) as T;
    }
    if (t == _itljah4k.ShareholderEntry) {
      return _itljah4k.ShareholderEntry.fromJson(data) as T;
    }
    if (t == _iiit8m20.ShareholderReturn) {
      return _iiit8m20.ShareholderReturn.fromJson(data) as T;
    }
    if (t == _icm1zoh2.Source) {
      return _icm1zoh2.Source.fromJson(data) as T;
    }
    if (t == _itk5lja3.SourceKind) {
      return _itk5lja3.SourceKind.fromJson(data) as T;
    }
    if (t == _i3sjboun.StockTotalRow) {
      return _i3sjboun.StockTotalRow.fromJson(data) as T;
    }
    if (t == _ir3er3o6.ThemeDetail) {
      return _ir3er3o6.ThemeDetail.fromJson(data) as T;
    }
    if (t == _irm69cop.ThemeMember) {
      return _irm69cop.ThemeMember.fromJson(data) as T;
    }
    if (t == _irah5hi6.ThemeMemberView) {
      return _irah5hi6.ThemeMemberView.fromJson(data) as T;
    }
    if (t == _i4ynus9k.ThemeSummary) {
      return _i4ynus9k.ThemeSummary.fromJson(data) as T;
    }
    if (t == _injn1qca.TreasuryStockEntry) {
      return _injn1qca.TreasuryStockEntry.fromJson(data) as T;
    }
    if (t == _is2pxpv6.WatchlistCompanyView) {
      return _is2pxpv6.WatchlistCompanyView.fromJson(data) as T;
    }
    if (t == _ivan2n9m.WatchlistError) {
      return _ivan2n9m.WatchlistError.fromJson(data) as T;
    }
    if (t == _ijbmrc2g.WatchlistUpdateView) {
      return _ijbmrc2g.WatchlistUpdateView.fromJson(data) as T;
    }
    if (t == _iyb0jzxs.WatchlistView) {
      return _iyb0jzxs.WatchlistView.fromJson(data) as T;
    }
    if (t == _isc.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iybkvk8h.BillingCheckoutView?>()) {
      return (data != null
              ? _iybkvk8h.BillingCheckoutView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4b9wxd2.BillingPaymentView?>()) {
      return (data != null ? _i4b9wxd2.BillingPaymentView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ikugrjyl.MembershipView?>()) {
      return (data != null ? _ikugrjyl.MembershipView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i7n6g9s8.AccountView?>()) {
      return (data != null ? _i7n6g9s8.AccountView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_idjojx8t.AiExtraction?>()) {
      return (data != null ? _idjojx8t.AiExtraction.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i7c6k6qa.AiStatus?>()) {
      return (data != null ? _i7c6k6qa.AiStatus.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i3e42he1.ApiCallUsage?>()) {
      return (data != null ? _i3e42he1.ApiCallUsage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i82zif2r.ApiProvider?>()) {
      return (data != null ? _i82zif2r.ApiProvider.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ik6lqqsr.BusinessContent?>()) {
      return (data != null ? _ik6lqqsr.BusinessContent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izxiijmh.BusinessDigestKind?>()) {
      return (data != null ? _izxiijmh.BusinessDigestKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iq2bjjp3.BusinessDigestSection?>()) {
      return (data != null
              ? _iq2bjjp3.BusinessDigestSection.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_imi0q911.BusinessDocument?>()) {
      return (data != null ? _imi0q911.BusinessDocument.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_is707pet.BusinessDocumentRef?>()) {
      return (data != null
              ? _is707pet.BusinessDocumentRef.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i1cpvxoo.BusinessFactPeriod?>()) {
      return (data != null ? _i1cpvxoo.BusinessFactPeriod.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3peg7yx.BusinessProduct?>()) {
      return (data != null ? _i3peg7yx.BusinessProduct.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iegef18i.BusinessProfile?>()) {
      return (data != null ? _iegef18i.BusinessProfile.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_inylkhjt.BusinessSection?>()) {
      return (data != null ? _inylkhjt.BusinessSection.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0vnq5ds.BusinessTableInsight?>()) {
      return (data != null
              ? _i0vnq5ds.BusinessTableInsight.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ia821tg8.BusinessTableMeasure?>()) {
      return (data != null
              ? _ia821tg8.BusinessTableMeasure.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i5mz554b.BusinessTableRecord?>()) {
      return (data != null
              ? _i5mz554b.BusinessTableRecord.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iwkhf8pb.BusinessUnderstanding?>()) {
      return (data != null
              ? _iwkhf8pb.BusinessUnderstanding.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ipen255x.Company?>()) {
      return (data != null ? _ipen255x.Company.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_isfozywu.CompanyChange?>()) {
      return (data != null ? _isfozywu.CompanyChange.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ire9jjud.CompanyDetail?>()) {
      return (data != null ? _ire9jjud.CompanyDetail.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iki0y6e6.CompanyFinancials?>()) {
      return (data != null ? _iki0y6e6.CompanyFinancials.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ijqcijwd.CompanyGovernance?>()) {
      return (data != null ? _ijqcijwd.CompanyGovernance.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ixtgihs0.CompanyGraph?>()) {
      return (data != null ? _ixtgihs0.CompanyGraph.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihdcqaon.CompanyGroup?>()) {
      return (data != null ? _ihdcqaon.CompanyGroup.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i0csqxj4.CompanyListItem?>()) {
      return (data != null ? _i0csqxj4.CompanyListItem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_it4u3ib3.CompanyMarketCap?>()) {
      return (data != null ? _it4u3ib3.CompanyMarketCap.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_izcvpxxd.CompanyNewsFeed?>()) {
      return (data != null ? _izcvpxxd.CompanyNewsFeed.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iiky47zh.CompanyNewsItem?>()) {
      return (data != null ? _iiky47zh.CompanyNewsItem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iaj9eyri.CompanyPage?>()) {
      return (data != null ? _iaj9eyri.CompanyPage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i4gnucl8.CompanyRef?>()) {
      return (data != null ? _i4gnucl8.CompanyRef.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ia2izjbq.CompanySort?>()) {
      return (data != null ? _ia2izjbq.CompanySort.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ir49pw6i.DartCorpStatus?>()) {
      return (data != null ? _ir49pw6i.DartCorpStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iw06ztex.DartDisclosure?>()) {
      return (data != null ? _iw06ztex.DartDisclosure.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_itki3qdq.DartFiling?>()) {
      return (data != null ? _itki3qdq.DartFiling.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ixr5w3gq.DartFilingScan?>()) {
      return (data != null ? _ixr5w3gq.DartFilingScan.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isprzv4c.DartFilingSection?>()) {
      return (data != null ? _isprzv4c.DartFilingSection.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_islomtus.DartSection?>()) {
      return (data != null ? _islomtus.DartSection.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iffxd3r6.DisclosureLinkBasis?>()) {
      return (data != null
              ? _iffxd3r6.DisclosureLinkBasis.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i4blf95b.DisclosureReport?>()) {
      return (data != null ? _i4blf95b.DisclosureReport.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_irf27uzx.DisclosureRow?>()) {
      return (data != null ? _irf27uzx.DisclosureRow.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ij0mhdco.DisclosureSectionInfo?>()) {
      return (data != null
              ? _ij0mhdco.DisclosureSectionInfo.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7prd3sw.DisclosureTable?>()) {
      return (data != null ? _i7prd3sw.DisclosureTable.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i98o73zd.DisclosureTableRow?>()) {
      return (data != null ? _i98o73zd.DisclosureTableRow.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ith4ion6.DividendEntry?>()) {
      return (data != null ? _ith4ion6.DividendEntry.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iy6p3omn.DocumentFact?>()) {
      return (data != null ? _iy6p3omn.DocumentFact.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iatg4403.DocumentFactKind?>()) {
      return (data != null ? _iatg4403.DocumentFactKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iqc95j34.IngestException?>()) {
      return (data != null ? _iqc95j34.IngestException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3df9cy5.ExecutiveEntry?>()) {
      return (data != null ? _i3df9cy5.ExecutiveEntry.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iz7k3x6v.ExecutiveRegistration?>()) {
      return (data != null
              ? _iz7k3x6v.ExecutiveRegistration.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iqbvehdv.FacetCount?>()) {
      return (data != null ? _iqbvehdv.FacetCount.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iawn4ngl.FactItem?>()) {
      return (data != null ? _iawn4ngl.FactItem.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iurbyopj.FactPage?>()) {
      return (data != null ? _iurbyopj.FactPage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iivg0zeh.FilingFeedItem?>()) {
      return (data != null ? _iivg0zeh.FilingFeedItem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i167q75d.FilingFetchStatus?>()) {
      return (data != null ? _i167q75d.FilingFetchStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igykxm42.FinancialFact?>()) {
      return (data != null ? _igykxm42.FinancialFact.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igzbjepn.FinancialLine?>()) {
      return (data != null ? _igzbjepn.FinancialLine.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_itz8g04g.FinancialPeriod?>()) {
      return (data != null ? _itz8g04g.FinancialPeriod.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i1qwjg2x.FinancialReport?>()) {
      return (data != null ? _i1qwjg2x.FinancialReport.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idwohplt.FinancialReportCode?>()) {
      return (data != null
              ? _idwohplt.FinancialReportCode.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ia8vdu33.FinancialReportDetail?>()) {
      return (data != null
              ? _ia8vdu33.FinancialReportDetail.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_im4itn08.FinancialStatementKind?>()) {
      return (data != null
              ? _im4itn08.FinancialStatementKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i906z99z.FsDiv?>()) {
      return (data != null ? _i906z99z.FsDiv.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ikth1mft.GovernanceLink?>()) {
      return (data != null ? _ikth1mft.GovernanceLink.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iamhnwn8.GraphEdge?>()) {
      return (data != null ? _iamhnwn8.GraphEdge.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iqv6eyci.GraphNode?>()) {
      return (data != null ? _iqv6eyci.GraphNode.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i1fyp5lv.GroupEdge?>()) {
      return (data != null ? _i1fyp5lv.GroupEdge.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iyd2zx8r.GroupMember?>()) {
      return (data != null ? _iyd2zx8r.GroupMember.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iklt0jfv.GroupPerson?>()) {
      return (data != null ? _iklt0jfv.GroupPerson.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iocwvagy.IndexHistory?>()) {
      return (data != null ? _iocwvagy.IndexHistory.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_it75qdkc.IndexPoint?>()) {
      return (data != null ? _it75qdkc.IndexPoint.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i3hzx3f1.Industry?>()) {
      return (data != null ? _i3hzx3f1.Industry.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_if5qperq.IndustryActivity?>()) {
      return (data != null ? _if5qperq.IndustryActivity.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ixuxxo68.IndustryDiscovery?>()) {
      return (data != null ? _ixuxxo68.IndustryDiscovery.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i25uuckt.IndustryRevisionCheck?>()) {
      return (data != null
              ? _i25uuckt.IndustryRevisionCheck.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_il0sbv1h.IngestCoverage?>()) {
      return (data != null ? _il0sbv1h.IngestCoverage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iay1heal.IngestJob?>()) {
      return (data != null ? _iay1heal.IngestJob.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilyxu1av.IngestScheduleEntry?>()) {
      return (data != null
              ? _ilyxu1av.IngestScheduleEntry.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_imojj26x.IngestStatus?>()) {
      return (data != null ? _imojj26x.IngestStatus.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i9p8kpm7.InvestmentEntry?>()) {
      return (data != null ? _i9p8kpm7.InvestmentEntry.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i57inxpq.InvestmentTheme?>()) {
      return (data != null ? _i57inxpq.InvestmentTheme.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_id0q6lal.MacroSeriesView?>()) {
      return (data != null ? _id0q6lal.MacroSeriesView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iyzzhewo.Market?>()) {
      return (data != null ? _iyzzhewo.Market.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i1tskjhh.MarketCapNode?>()) {
      return (data != null ? _i1tskjhh.MarketCapNode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igdvszti.MarketCapPoint?>()) {
      return (data != null ? _igdvszti.MarketCapPoint.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iwodvuy1.MarketCapTreemap?>()) {
      return (data != null ? _iwodvuy1.MarketCapTreemap.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ihawso0m.MarketIndexDay?>()) {
      return (data != null ? _ihawso0m.MarketIndexDay.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i9c8jqc3.MarketIndexSnapshot?>()) {
      return (data != null
              ? _i9c8jqc3.MarketIndexSnapshot.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ibhowe7d.MarketSnapshot?>()) {
      return (data != null ? _ibhowe7d.MarketSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3renazk.MarketSnapshotDay?>()) {
      return (data != null ? _i3renazk.MarketSnapshotDay.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivtwhw6z.NewCompanyView?>()) {
      return (data != null ? _ivtwhw6z.NewCompanyView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iejnlir1.OntologyRelation?>()) {
      return (data != null ? _iejnlir1.OntologyRelation.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iz31wbgv.Overview?>()) {
      return (data != null ? _iz31wbgv.Overview.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilc2cd4p.OwnershipSnapshot?>()) {
      return (data != null ? _ilc2cd4p.OwnershipSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6cusig8.PeerCandidate?>()) {
      return (data != null ? _i6cusig8.PeerCandidate.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i59onhk4.PeerCandidates?>()) {
      return (data != null ? _i59onhk4.PeerCandidates.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isobo9h5.PeerComparison?>()) {
      return (data != null ? _isobo9h5.PeerComparison.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iihutb4k.PeerMetric?>()) {
      return (data != null ? _iihutb4k.PeerMetric.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iwm08ow1.PeerProfile?>()) {
      return (data != null ? _iwm08ow1.PeerProfile.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8bwgp5o.PeerSignal?>()) {
      return (data != null ? _i8bwgp5o.PeerSignal.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i9gy9ys0.Person?>()) {
      return (data != null ? _i9gy9ys0.Person.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iyxi6nm4.PersonHit?>()) {
      return (data != null ? _iyxi6nm4.PersonHit.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iffou6wp.PersonLinkRejection?>()) {
      return (data != null
              ? _iffou6wp.PersonLinkRejection.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i12ugm17.PersonProfile?>()) {
      return (data != null ? _i12ugm17.PersonProfile.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ipnxekll.PersonRole?>()) {
      return (data != null ? _ipnxekll.PersonRole.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i451wru0.PriceHistory?>()) {
      return (data != null ? _i451wru0.PriceHistory.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iyfyllvz.PricePoint?>()) {
      return (data != null ? _iyfyllvz.PricePoint.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iy288i3j.RelationFactKind?>()) {
      return (data != null ? _iy288i3j.RelationFactKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_id1oen7t.RelationOrigin?>()) {
      return (data != null ? _id1oen7t.RelationOrigin.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idal2dwe.RelationPredicate?>()) {
      return (data != null ? _idal2dwe.RelationPredicate.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ih00v9tp.RelationStatus?>()) {
      return (data != null ? _ih00v9tp.RelationStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i83xfi8m.ResearchArticle?>()) {
      return (data != null ? _i83xfi8m.ResearchArticle.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iofl85o3.ResearchBookmark?>()) {
      return (data != null ? _iofl85o3.ResearchBookmark.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iwk8vi27.ResearchRevision?>()) {
      return (data != null ? _iwk8vi27.ResearchRevision.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iwd80rqd.ResearchSnapshot?>()) {
      return (data != null ? _iwd80rqd.ResearchSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iqdwyhyy.ReviewCheck?>()) {
      return (data != null ? _iqdwyhyy.ReviewCheck.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ijdr1ucd.ReviewContext?>()) {
      return (data != null ? _ijdr1ucd.ReviewContext.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6uduqoi.ReviewItem?>()) {
      return (data != null ? _i6uduqoi.ReviewItem.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i22wlf7g.ReviewPage?>()) {
      return (data != null ? _i22wlf7g.ReviewPage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_izca0w44.ScreenPage?>()) {
      return (data != null ? _izca0w44.ScreenPage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ie748vep.ScreenRow?>()) {
      return (data != null ? _ie748vep.ScreenRow.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_igeg1iky.ScreenSort?>()) {
      return (data != null ? _igeg1iky.ScreenSort.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilujots3.Security?>()) {
      return (data != null ? _ilujots3.Security.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ic799xum.SecurityLinkBasis?>()) {
      return (data != null ? _ic799xum.SecurityLinkBasis.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ionn6cq2.SecurityQuote?>()) {
      return (data != null ? _ionn6cq2.SecurityQuote.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_itljah4k.ShareholderEntry?>()) {
      return (data != null ? _itljah4k.ShareholderEntry.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iiit8m20.ShareholderReturn?>()) {
      return (data != null ? _iiit8m20.ShareholderReturn.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_icm1zoh2.Source?>()) {
      return (data != null ? _icm1zoh2.Source.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_itk5lja3.SourceKind?>()) {
      return (data != null ? _itk5lja3.SourceKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i3sjboun.StockTotalRow?>()) {
      return (data != null ? _i3sjboun.StockTotalRow.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ir3er3o6.ThemeDetail?>()) {
      return (data != null ? _ir3er3o6.ThemeDetail.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_irm69cop.ThemeMember?>()) {
      return (data != null ? _irm69cop.ThemeMember.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_irah5hi6.ThemeMemberView?>()) {
      return (data != null ? _irah5hi6.ThemeMemberView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4ynus9k.ThemeSummary?>()) {
      return (data != null ? _i4ynus9k.ThemeSummary.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_injn1qca.TreasuryStockEntry?>()) {
      return (data != null ? _injn1qca.TreasuryStockEntry.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_is2pxpv6.WatchlistCompanyView?>()) {
      return (data != null
              ? _is2pxpv6.WatchlistCompanyView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ivan2n9m.WatchlistError?>()) {
      return (data != null ? _ivan2n9m.WatchlistError.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ijbmrc2g.WatchlistUpdateView?>()) {
      return (data != null
              ? _ijbmrc2g.WatchlistUpdateView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iyb0jzxs.WatchlistView?>()) {
      return (data != null ? _iyb0jzxs.WatchlistView.fromJson(data) : null)
          as T;
    }
    if (t == List<_inylkhjt.BusinessSection>) {
      return (data as List)
              .map((e) => deserialize<_inylkhjt.BusinessSection>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i0vnq5ds.BusinessTableInsight>) {
      return (data as List)
              .map((e) => deserialize<_i0vnq5ds.BusinessTableInsight>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_i0vnq5ds.BusinessTableInsight>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i0vnq5ds.BusinessTableInsight>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i3peg7yx.BusinessProduct>) {
      return (data as List)
              .map((e) => deserialize<_i3peg7yx.BusinessProduct>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i5mz554b.BusinessTableRecord>) {
      return (data as List)
              .map((e) => deserialize<_i5mz554b.BusinessTableRecord>(e))
              .toList()
          as T;
    }
    if (t == List<_ia821tg8.BusinessTableMeasure>) {
      return (data as List)
              .map((e) => deserialize<_ia821tg8.BusinessTableMeasure>(e))
              .toList()
          as T;
    }
    if (t == List<_i3hzx3f1.Industry>) {
      return (data as List)
              .map((e) => deserialize<_i3hzx3f1.Industry>(e))
              .toList()
          as T;
    }
    if (t == List<_isfozywu.CompanyChange>) {
      return (data as List)
              .map((e) => deserialize<_isfozywu.CompanyChange>(e))
              .toList()
          as T;
    }
    if (t == List<_i906z99z.FsDiv>) {
      return (data as List).map((e) => deserialize<_i906z99z.FsDiv>(e)).toList()
          as T;
    }
    if (t == List<_itz8g04g.FinancialPeriod>) {
      return (data as List)
              .map((e) => deserialize<_itz8g04g.FinancialPeriod>(e))
              .toList()
          as T;
    }
    if (t == List<_icm1zoh2.Source>) {
      return (data as List)
              .map((e) => deserialize<_icm1zoh2.Source>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_icm1zoh2.Source>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_icm1zoh2.Source>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_itljah4k.ShareholderEntry>) {
      return (data as List)
              .map((e) => deserialize<_itljah4k.ShareholderEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i3df9cy5.ExecutiveEntry>) {
      return (data as List)
              .map((e) => deserialize<_i3df9cy5.ExecutiveEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i9p8kpm7.InvestmentEntry>) {
      return (data as List)
              .map((e) => deserialize<_i9p8kpm7.InvestmentEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_ikth1mft.GovernanceLink>) {
      return (data as List)
              .map((e) => deserialize<_ikth1mft.GovernanceLink>(e))
              .toList()
          as T;
    }
    if (t == List<_i4gnucl8.CompanyRef>) {
      return (data as List)
              .map((e) => deserialize<_i4gnucl8.CompanyRef>(e))
              .toList()
          as T;
    }
    if (t == List<_i9gy9ys0.Person>) {
      return (data as List)
              .map((e) => deserialize<_i9gy9ys0.Person>(e))
              .toList()
          as T;
    }
    if (t == List<_iqv6eyci.GraphNode>) {
      return (data as List)
              .map((e) => deserialize<_iqv6eyci.GraphNode>(e))
              .toList()
          as T;
    }
    if (t == List<_iamhnwn8.GraphEdge>) {
      return (data as List)
              .map((e) => deserialize<_iamhnwn8.GraphEdge>(e))
              .toList()
          as T;
    }
    if (t == List<_iyd2zx8r.GroupMember>) {
      return (data as List)
              .map((e) => deserialize<_iyd2zx8r.GroupMember>(e))
              .toList()
          as T;
    }
    if (t == List<_i1fyp5lv.GroupEdge>) {
      return (data as List)
              .map((e) => deserialize<_i1fyp5lv.GroupEdge>(e))
              .toList()
          as T;
    }
    if (t == List<_iklt0jfv.GroupPerson>) {
      return (data as List)
              .map((e) => deserialize<_iklt0jfv.GroupPerson>(e))
              .toList()
          as T;
    }
    if (t == List<_ionn6cq2.SecurityQuote>) {
      return (data as List)
              .map((e) => deserialize<_ionn6cq2.SecurityQuote>(e))
              .toList()
          as T;
    }
    if (t == List<_iiky47zh.CompanyNewsItem>) {
      return (data as List)
              .map((e) => deserialize<_iiky47zh.CompanyNewsItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i0csqxj4.CompanyListItem>) {
      return (data as List)
              .map((e) => deserialize<_i0csqxj4.CompanyListItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i98o73zd.DisclosureTableRow>) {
      return (data as List)
              .map((e) => deserialize<_i98o73zd.DisclosureTableRow>(e))
              .toList()
          as T;
    }
    if (t == List<String?>) {
      return (data as List).map((e) => deserialize<String?>(e)).toList() as T;
    }
    if (t == List<_iawn4ngl.FactItem>) {
      return (data as List)
              .map((e) => deserialize<_iawn4ngl.FactItem>(e))
              .toList()
          as T;
    }
    if (t == List<_igzbjepn.FinancialLine>) {
      return (data as List)
              .map((e) => deserialize<_igzbjepn.FinancialLine>(e))
              .toList()
          as T;
    }
    if (t == List<_igykxm42.FinancialFact>) {
      return (data as List)
              .map((e) => deserialize<_igykxm42.FinancialFact>(e))
              .toList()
          as T;
    }
    if (t == List<_i1qwjg2x.FinancialReport>) {
      return (data as List)
              .map((e) => deserialize<_i1qwjg2x.FinancialReport>(e))
              .toList()
          as T;
    }
    if (t == List<_it75qdkc.IndexPoint>) {
      return (data as List)
              .map((e) => deserialize<_it75qdkc.IndexPoint>(e))
              .toList()
          as T;
    }
    if (t == List<_if5qperq.IndustryActivity>) {
      return (data as List)
              .map((e) => deserialize<_if5qperq.IndustryActivity>(e))
              .toList()
          as T;
    }
    if (t == List<_i1tskjhh.MarketCapNode>) {
      return (data as List)
              .map((e) => deserialize<_i1tskjhh.MarketCapNode>(e))
              .toList()
          as T;
    }
    if (t == List<_iqbvehdv.FacetCount>) {
      return (data as List)
              .map((e) => deserialize<_iqbvehdv.FacetCount>(e))
              .toList()
          as T;
    }
    if (t == List<_i8bwgp5o.PeerSignal>) {
      return (data as List)
              .map((e) => deserialize<_i8bwgp5o.PeerSignal>(e))
              .toList()
          as T;
    }
    if (t == List<_i6cusig8.PeerCandidate>) {
      return (data as List)
              .map((e) => deserialize<_i6cusig8.PeerCandidate>(e))
              .toList()
          as T;
    }
    if (t == List<_iihutb4k.PeerMetric>) {
      return (data as List)
              .map((e) => deserialize<_iihutb4k.PeerMetric>(e))
              .toList()
          as T;
    }
    if (t == List<_ipnxekll.PersonRole>) {
      return (data as List)
              .map((e) => deserialize<_ipnxekll.PersonRole>(e))
              .toList()
          as T;
    }
    if (t == List<_iyfyllvz.PricePoint>) {
      return (data as List)
              .map((e) => deserialize<_iyfyllvz.PricePoint>(e))
              .toList()
          as T;
    }
    if (t == List<_i6uduqoi.ReviewItem>) {
      return (data as List)
              .map((e) => deserialize<_i6uduqoi.ReviewItem>(e))
              .toList()
          as T;
    }
    if (t == List<_ie748vep.ScreenRow>) {
      return (data as List)
              .map((e) => deserialize<_ie748vep.ScreenRow>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == _isc.getType<Map<String, String>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<String>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_ith4ion6.DividendEntry>) {
      return (data as List)
              .map((e) => deserialize<_ith4ion6.DividendEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_injn1qca.TreasuryStockEntry>) {
      return (data as List)
              .map((e) => deserialize<_injn1qca.TreasuryStockEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i3sjboun.StockTotalRow>) {
      return (data as List)
              .map((e) => deserialize<_i3sjboun.StockTotalRow>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_ith4ion6.DividendEntry>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ith4ion6.DividendEntry>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _isc.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_irah5hi6.ThemeMemberView>) {
      return (data as List)
              .map((e) => deserialize<_irah5hi6.ThemeMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_is2pxpv6.WatchlistCompanyView>) {
      return (data as List)
              .map((e) => deserialize<_is2pxpv6.WatchlistCompanyView>(e))
              .toList()
          as T;
    }
    if (t == List<_ijbmrc2g.WatchlistUpdateView>) {
      return (data as List)
              .map((e) => deserialize<_ijbmrc2g.WatchlistUpdateView>(e))
              .toList()
          as T;
    }
    if (t == List<_ih9nljg3.AccountView>) {
      return (data as List)
              .map((e) => deserialize<_ih9nljg3.AccountView>(e))
              .toList()
          as T;
    }
    if (t == List<_id7v70oo.BusinessDocumentRef>) {
      return (data as List)
              .map((e) => deserialize<_id7v70oo.BusinessDocumentRef>(e))
              .toList()
          as T;
    }
    if (t == List<_icfgas7c.FacetCount>) {
      return (data as List)
              .map((e) => deserialize<_icfgas7c.FacetCount>(e))
              .toList()
          as T;
    }
    if (t == List<_i39r1xmm.DisclosureSectionInfo>) {
      return (data as List)
              .map((e) => deserialize<_i39r1xmm.DisclosureSectionInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_ip7x5uw8.DocumentFact>) {
      return (data as List)
              .map((e) => deserialize<_ip7x5uw8.DocumentFact>(e))
              .toList()
          as T;
    }
    if (t == List<_irhba4h9.BusinessFactPeriod>) {
      return (data as List)
              .map((e) => deserialize<_irhba4h9.BusinessFactPeriod>(e))
              .toList()
          as T;
    }
    if (t == List<_izt0hsdc.DartDisclosure>) {
      return (data as List)
              .map((e) => deserialize<_izt0hsdc.DartDisclosure>(e))
              .toList()
          as T;
    }
    if (t == List<_i5qsmr7t.BusinessDigestSection>) {
      return (data as List)
              .map((e) => deserialize<_i5qsmr7t.BusinessDigestSection>(e))
              .toList()
          as T;
    }
    if (t == List<_iuq4bocx.FilingFeedItem>) {
      return (data as List)
              .map((e) => deserialize<_iuq4bocx.FilingFeedItem>(e))
              .toList()
          as T;
    }
    if (t == List<_iz9gjubn.OwnershipSnapshot>) {
      return (data as List)
              .map((e) => deserialize<_iz9gjubn.OwnershipSnapshot>(e))
              .toList()
          as T;
    }
    if (t == List<_i96d117e.PersonHit>) {
      return (data as List)
              .map((e) => deserialize<_i96d117e.PersonHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i7uvzrch.CompanyGroup>) {
      return (data as List)
              .map((e) => deserialize<_i7uvzrch.CompanyGroup>(e))
              .toList()
          as T;
    }
    if (t == List<_idevncao.IngestScheduleEntry>) {
      return (data as List)
              .map((e) => deserialize<_idevncao.IngestScheduleEntry>(e))
              .toList()
          as T;
    }
    if (t == List<_i1paap7y.IngestJob>) {
      return (data as List)
              .map((e) => deserialize<_i1paap7y.IngestJob>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_ijzi50sx.MacroSeriesView>) {
      return (data as List)
              .map((e) => deserialize<_ijzi50sx.MacroSeriesView>(e))
              .toList()
          as T;
    }
    if (t == List<_iodca1gh.NewCompanyView>) {
      return (data as List)
              .map((e) => deserialize<_iodca1gh.NewCompanyView>(e))
              .toList()
          as T;
    }
    if (t == List<_idnoq35n.CompanyMarketCap>) {
      return (data as List)
              .map((e) => deserialize<_idnoq35n.CompanyMarketCap>(e))
              .toList()
          as T;
    }
    if (t == List<_i140v7gk.MarketCapPoint>) {
      return (data as List)
              .map((e) => deserialize<_i140v7gk.MarketCapPoint>(e))
              .toList()
          as T;
    }
    if (t == List<_isqvkvoy.BillingPaymentView>) {
      return (data as List)
              .map((e) => deserialize<_isqvkvoy.BillingPaymentView>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_ixhvmecn.ReviewCheck>) {
      return (data as List)
              .map((e) => deserialize<_ixhvmecn.ReviewCheck>(e))
              .toList()
          as T;
    }
    if (t == List<_ihqozc6p.ReviewItem>) {
      return (data as List)
              .map((e) => deserialize<_ihqozc6p.ReviewItem>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_ihj01hrs.ThemeSummary>) {
      return (data as List)
              .map((e) => deserialize<_ihj01hrs.ThemeSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_izhmhfon.InvestmentTheme>) {
      return (data as List)
              .map((e) => deserialize<_izhmhfon.InvestmentTheme>(e))
              .toList()
          as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _izw8z7ou.Greeting => 'Greeting',
      _iybkvk8h.BillingCheckoutView => 'BillingCheckoutView',
      _i4b9wxd2.BillingPaymentView => 'BillingPaymentView',
      _ikugrjyl.MembershipView => 'MembershipView',
      _i7n6g9s8.AccountView => 'AccountView',
      _idjojx8t.AiExtraction => 'AiExtraction',
      _i7c6k6qa.AiStatus => 'AiStatus',
      _i3e42he1.ApiCallUsage => 'ApiCallUsage',
      _i82zif2r.ApiProvider => 'ApiProvider',
      _ik6lqqsr.BusinessContent => 'BusinessContent',
      _izxiijmh.BusinessDigestKind => 'BusinessDigestKind',
      _iq2bjjp3.BusinessDigestSection => 'BusinessDigestSection',
      _imi0q911.BusinessDocument => 'BusinessDocument',
      _is707pet.BusinessDocumentRef => 'BusinessDocumentRef',
      _i1cpvxoo.BusinessFactPeriod => 'BusinessFactPeriod',
      _i3peg7yx.BusinessProduct => 'BusinessProduct',
      _iegef18i.BusinessProfile => 'BusinessProfile',
      _inylkhjt.BusinessSection => 'BusinessSection',
      _i0vnq5ds.BusinessTableInsight => 'BusinessTableInsight',
      _ia821tg8.BusinessTableMeasure => 'BusinessTableMeasure',
      _i5mz554b.BusinessTableRecord => 'BusinessTableRecord',
      _iwkhf8pb.BusinessUnderstanding => 'BusinessUnderstanding',
      _ipen255x.Company => 'Company',
      _isfozywu.CompanyChange => 'CompanyChange',
      _ire9jjud.CompanyDetail => 'CompanyDetail',
      _iki0y6e6.CompanyFinancials => 'CompanyFinancials',
      _ijqcijwd.CompanyGovernance => 'CompanyGovernance',
      _ixtgihs0.CompanyGraph => 'CompanyGraph',
      _ihdcqaon.CompanyGroup => 'CompanyGroup',
      _i0csqxj4.CompanyListItem => 'CompanyListItem',
      _it4u3ib3.CompanyMarketCap => 'CompanyMarketCap',
      _izcvpxxd.CompanyNewsFeed => 'CompanyNewsFeed',
      _iiky47zh.CompanyNewsItem => 'CompanyNewsItem',
      _iaj9eyri.CompanyPage => 'CompanyPage',
      _i4gnucl8.CompanyRef => 'CompanyRef',
      _ia2izjbq.CompanySort => 'CompanySort',
      _ir49pw6i.DartCorpStatus => 'DartCorpStatus',
      _iw06ztex.DartDisclosure => 'DartDisclosure',
      _itki3qdq.DartFiling => 'DartFiling',
      _ixr5w3gq.DartFilingScan => 'DartFilingScan',
      _isprzv4c.DartFilingSection => 'DartFilingSection',
      _islomtus.DartSection => 'DartSection',
      _iffxd3r6.DisclosureLinkBasis => 'DisclosureLinkBasis',
      _i4blf95b.DisclosureReport => 'DisclosureReport',
      _irf27uzx.DisclosureRow => 'DisclosureRow',
      _ij0mhdco.DisclosureSectionInfo => 'DisclosureSectionInfo',
      _i7prd3sw.DisclosureTable => 'DisclosureTable',
      _i98o73zd.DisclosureTableRow => 'DisclosureTableRow',
      _ith4ion6.DividendEntry => 'DividendEntry',
      _iy6p3omn.DocumentFact => 'DocumentFact',
      _iatg4403.DocumentFactKind => 'DocumentFactKind',
      _iqc95j34.IngestException => 'IngestException',
      _i3df9cy5.ExecutiveEntry => 'ExecutiveEntry',
      _iz7k3x6v.ExecutiveRegistration => 'ExecutiveRegistration',
      _iqbvehdv.FacetCount => 'FacetCount',
      _iawn4ngl.FactItem => 'FactItem',
      _iurbyopj.FactPage => 'FactPage',
      _iivg0zeh.FilingFeedItem => 'FilingFeedItem',
      _i167q75d.FilingFetchStatus => 'FilingFetchStatus',
      _igykxm42.FinancialFact => 'FinancialFact',
      _igzbjepn.FinancialLine => 'FinancialLine',
      _itz8g04g.FinancialPeriod => 'FinancialPeriod',
      _i1qwjg2x.FinancialReport => 'FinancialReport',
      _idwohplt.FinancialReportCode => 'FinancialReportCode',
      _ia8vdu33.FinancialReportDetail => 'FinancialReportDetail',
      _im4itn08.FinancialStatementKind => 'FinancialStatementKind',
      _i906z99z.FsDiv => 'FsDiv',
      _ikth1mft.GovernanceLink => 'GovernanceLink',
      _iamhnwn8.GraphEdge => 'GraphEdge',
      _iqv6eyci.GraphNode => 'GraphNode',
      _i1fyp5lv.GroupEdge => 'GroupEdge',
      _iyd2zx8r.GroupMember => 'GroupMember',
      _iklt0jfv.GroupPerson => 'GroupPerson',
      _iocwvagy.IndexHistory => 'IndexHistory',
      _it75qdkc.IndexPoint => 'IndexPoint',
      _i3hzx3f1.Industry => 'Industry',
      _if5qperq.IndustryActivity => 'IndustryActivity',
      _ixuxxo68.IndustryDiscovery => 'IndustryDiscovery',
      _i25uuckt.IndustryRevisionCheck => 'IndustryRevisionCheck',
      _il0sbv1h.IngestCoverage => 'IngestCoverage',
      _iay1heal.IngestJob => 'IngestJob',
      _ilyxu1av.IngestScheduleEntry => 'IngestScheduleEntry',
      _imojj26x.IngestStatus => 'IngestStatus',
      _i9p8kpm7.InvestmentEntry => 'InvestmentEntry',
      _i57inxpq.InvestmentTheme => 'InvestmentTheme',
      _id0q6lal.MacroSeriesView => 'MacroSeriesView',
      _iyzzhewo.Market => 'Market',
      _i1tskjhh.MarketCapNode => 'MarketCapNode',
      _igdvszti.MarketCapPoint => 'MarketCapPoint',
      _iwodvuy1.MarketCapTreemap => 'MarketCapTreemap',
      _ihawso0m.MarketIndexDay => 'MarketIndexDay',
      _i9c8jqc3.MarketIndexSnapshot => 'MarketIndexSnapshot',
      _ibhowe7d.MarketSnapshot => 'MarketSnapshot',
      _i3renazk.MarketSnapshotDay => 'MarketSnapshotDay',
      _ivtwhw6z.NewCompanyView => 'NewCompanyView',
      _iejnlir1.OntologyRelation => 'OntologyRelation',
      _iz31wbgv.Overview => 'Overview',
      _ilc2cd4p.OwnershipSnapshot => 'OwnershipSnapshot',
      _i6cusig8.PeerCandidate => 'PeerCandidate',
      _i59onhk4.PeerCandidates => 'PeerCandidates',
      _isobo9h5.PeerComparison => 'PeerComparison',
      _iihutb4k.PeerMetric => 'PeerMetric',
      _iwm08ow1.PeerProfile => 'PeerProfile',
      _i8bwgp5o.PeerSignal => 'PeerSignal',
      _i9gy9ys0.Person => 'Person',
      _iyxi6nm4.PersonHit => 'PersonHit',
      _iffou6wp.PersonLinkRejection => 'PersonLinkRejection',
      _i12ugm17.PersonProfile => 'PersonProfile',
      _ipnxekll.PersonRole => 'PersonRole',
      _i451wru0.PriceHistory => 'PriceHistory',
      _iyfyllvz.PricePoint => 'PricePoint',
      _iy288i3j.RelationFactKind => 'RelationFactKind',
      _id1oen7t.RelationOrigin => 'RelationOrigin',
      _idal2dwe.RelationPredicate => 'RelationPredicate',
      _ih00v9tp.RelationStatus => 'RelationStatus',
      _i83xfi8m.ResearchArticle => 'ResearchArticle',
      _iofl85o3.ResearchBookmark => 'ResearchBookmark',
      _iwk8vi27.ResearchRevision => 'ResearchRevision',
      _iwd80rqd.ResearchSnapshot => 'ResearchSnapshot',
      _iqdwyhyy.ReviewCheck => 'ReviewCheck',
      _ijdr1ucd.ReviewContext => 'ReviewContext',
      _i6uduqoi.ReviewItem => 'ReviewItem',
      _i22wlf7g.ReviewPage => 'ReviewPage',
      _izca0w44.ScreenPage => 'ScreenPage',
      _ie748vep.ScreenRow => 'ScreenRow',
      _igeg1iky.ScreenSort => 'ScreenSort',
      _ilujots3.Security => 'Security',
      _ic799xum.SecurityLinkBasis => 'SecurityLinkBasis',
      _ionn6cq2.SecurityQuote => 'SecurityQuote',
      _itljah4k.ShareholderEntry => 'ShareholderEntry',
      _iiit8m20.ShareholderReturn => 'ShareholderReturn',
      _icm1zoh2.Source => 'Source',
      _itk5lja3.SourceKind => 'SourceKind',
      _i3sjboun.StockTotalRow => 'StockTotalRow',
      _ir3er3o6.ThemeDetail => 'ThemeDetail',
      _irm69cop.ThemeMember => 'ThemeMember',
      _irah5hi6.ThemeMemberView => 'ThemeMemberView',
      _i4ynus9k.ThemeSummary => 'ThemeSummary',
      _injn1qca.TreasuryStockEntry => 'TreasuryStockEntry',
      _is2pxpv6.WatchlistCompanyView => 'WatchlistCompanyView',
      _ivan2n9m.WatchlistError => 'WatchlistError',
      _ijbmrc2g.WatchlistUpdateView => 'WatchlistUpdateView',
      _iyb0jzxs.WatchlistView => 'WatchlistView',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'investment_ontology_serverpod.',
        '',
      );
    }

    switch (data) {
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _iybkvk8h.BillingCheckoutView():
        return 'BillingCheckoutView';
      case _i4b9wxd2.BillingPaymentView():
        return 'BillingPaymentView';
      case _ikugrjyl.MembershipView():
        return 'MembershipView';
      case _i7n6g9s8.AccountView():
        return 'AccountView';
      case _idjojx8t.AiExtraction():
        return 'AiExtraction';
      case _i7c6k6qa.AiStatus():
        return 'AiStatus';
      case _i3e42he1.ApiCallUsage():
        return 'ApiCallUsage';
      case _i82zif2r.ApiProvider():
        return 'ApiProvider';
      case _ik6lqqsr.BusinessContent():
        return 'BusinessContent';
      case _izxiijmh.BusinessDigestKind():
        return 'BusinessDigestKind';
      case _iq2bjjp3.BusinessDigestSection():
        return 'BusinessDigestSection';
      case _imi0q911.BusinessDocument():
        return 'BusinessDocument';
      case _is707pet.BusinessDocumentRef():
        return 'BusinessDocumentRef';
      case _i1cpvxoo.BusinessFactPeriod():
        return 'BusinessFactPeriod';
      case _i3peg7yx.BusinessProduct():
        return 'BusinessProduct';
      case _iegef18i.BusinessProfile():
        return 'BusinessProfile';
      case _inylkhjt.BusinessSection():
        return 'BusinessSection';
      case _i0vnq5ds.BusinessTableInsight():
        return 'BusinessTableInsight';
      case _ia821tg8.BusinessTableMeasure():
        return 'BusinessTableMeasure';
      case _i5mz554b.BusinessTableRecord():
        return 'BusinessTableRecord';
      case _iwkhf8pb.BusinessUnderstanding():
        return 'BusinessUnderstanding';
      case _ipen255x.Company():
        return 'Company';
      case _isfozywu.CompanyChange():
        return 'CompanyChange';
      case _ire9jjud.CompanyDetail():
        return 'CompanyDetail';
      case _iki0y6e6.CompanyFinancials():
        return 'CompanyFinancials';
      case _ijqcijwd.CompanyGovernance():
        return 'CompanyGovernance';
      case _ixtgihs0.CompanyGraph():
        return 'CompanyGraph';
      case _ihdcqaon.CompanyGroup():
        return 'CompanyGroup';
      case _i0csqxj4.CompanyListItem():
        return 'CompanyListItem';
      case _it4u3ib3.CompanyMarketCap():
        return 'CompanyMarketCap';
      case _izcvpxxd.CompanyNewsFeed():
        return 'CompanyNewsFeed';
      case _iiky47zh.CompanyNewsItem():
        return 'CompanyNewsItem';
      case _iaj9eyri.CompanyPage():
        return 'CompanyPage';
      case _i4gnucl8.CompanyRef():
        return 'CompanyRef';
      case _ia2izjbq.CompanySort():
        return 'CompanySort';
      case _ir49pw6i.DartCorpStatus():
        return 'DartCorpStatus';
      case _iw06ztex.DartDisclosure():
        return 'DartDisclosure';
      case _itki3qdq.DartFiling():
        return 'DartFiling';
      case _ixr5w3gq.DartFilingScan():
        return 'DartFilingScan';
      case _isprzv4c.DartFilingSection():
        return 'DartFilingSection';
      case _islomtus.DartSection():
        return 'DartSection';
      case _iffxd3r6.DisclosureLinkBasis():
        return 'DisclosureLinkBasis';
      case _i4blf95b.DisclosureReport():
        return 'DisclosureReport';
      case _irf27uzx.DisclosureRow():
        return 'DisclosureRow';
      case _ij0mhdco.DisclosureSectionInfo():
        return 'DisclosureSectionInfo';
      case _i7prd3sw.DisclosureTable():
        return 'DisclosureTable';
      case _i98o73zd.DisclosureTableRow():
        return 'DisclosureTableRow';
      case _ith4ion6.DividendEntry():
        return 'DividendEntry';
      case _iy6p3omn.DocumentFact():
        return 'DocumentFact';
      case _iatg4403.DocumentFactKind():
        return 'DocumentFactKind';
      case _iqc95j34.IngestException():
        return 'IngestException';
      case _i3df9cy5.ExecutiveEntry():
        return 'ExecutiveEntry';
      case _iz7k3x6v.ExecutiveRegistration():
        return 'ExecutiveRegistration';
      case _iqbvehdv.FacetCount():
        return 'FacetCount';
      case _iawn4ngl.FactItem():
        return 'FactItem';
      case _iurbyopj.FactPage():
        return 'FactPage';
      case _iivg0zeh.FilingFeedItem():
        return 'FilingFeedItem';
      case _i167q75d.FilingFetchStatus():
        return 'FilingFetchStatus';
      case _igykxm42.FinancialFact():
        return 'FinancialFact';
      case _igzbjepn.FinancialLine():
        return 'FinancialLine';
      case _itz8g04g.FinancialPeriod():
        return 'FinancialPeriod';
      case _i1qwjg2x.FinancialReport():
        return 'FinancialReport';
      case _idwohplt.FinancialReportCode():
        return 'FinancialReportCode';
      case _ia8vdu33.FinancialReportDetail():
        return 'FinancialReportDetail';
      case _im4itn08.FinancialStatementKind():
        return 'FinancialStatementKind';
      case _i906z99z.FsDiv():
        return 'FsDiv';
      case _ikth1mft.GovernanceLink():
        return 'GovernanceLink';
      case _iamhnwn8.GraphEdge():
        return 'GraphEdge';
      case _iqv6eyci.GraphNode():
        return 'GraphNode';
      case _i1fyp5lv.GroupEdge():
        return 'GroupEdge';
      case _iyd2zx8r.GroupMember():
        return 'GroupMember';
      case _iklt0jfv.GroupPerson():
        return 'GroupPerson';
      case _iocwvagy.IndexHistory():
        return 'IndexHistory';
      case _it75qdkc.IndexPoint():
        return 'IndexPoint';
      case _i3hzx3f1.Industry():
        return 'Industry';
      case _if5qperq.IndustryActivity():
        return 'IndustryActivity';
      case _ixuxxo68.IndustryDiscovery():
        return 'IndustryDiscovery';
      case _i25uuckt.IndustryRevisionCheck():
        return 'IndustryRevisionCheck';
      case _il0sbv1h.IngestCoverage():
        return 'IngestCoverage';
      case _iay1heal.IngestJob():
        return 'IngestJob';
      case _ilyxu1av.IngestScheduleEntry():
        return 'IngestScheduleEntry';
      case _imojj26x.IngestStatus():
        return 'IngestStatus';
      case _i9p8kpm7.InvestmentEntry():
        return 'InvestmentEntry';
      case _i57inxpq.InvestmentTheme():
        return 'InvestmentTheme';
      case _id0q6lal.MacroSeriesView():
        return 'MacroSeriesView';
      case _iyzzhewo.Market():
        return 'Market';
      case _i1tskjhh.MarketCapNode():
        return 'MarketCapNode';
      case _igdvszti.MarketCapPoint():
        return 'MarketCapPoint';
      case _iwodvuy1.MarketCapTreemap():
        return 'MarketCapTreemap';
      case _ihawso0m.MarketIndexDay():
        return 'MarketIndexDay';
      case _i9c8jqc3.MarketIndexSnapshot():
        return 'MarketIndexSnapshot';
      case _ibhowe7d.MarketSnapshot():
        return 'MarketSnapshot';
      case _i3renazk.MarketSnapshotDay():
        return 'MarketSnapshotDay';
      case _ivtwhw6z.NewCompanyView():
        return 'NewCompanyView';
      case _iejnlir1.OntologyRelation():
        return 'OntologyRelation';
      case _iz31wbgv.Overview():
        return 'Overview';
      case _ilc2cd4p.OwnershipSnapshot():
        return 'OwnershipSnapshot';
      case _i6cusig8.PeerCandidate():
        return 'PeerCandidate';
      case _i59onhk4.PeerCandidates():
        return 'PeerCandidates';
      case _isobo9h5.PeerComparison():
        return 'PeerComparison';
      case _iihutb4k.PeerMetric():
        return 'PeerMetric';
      case _iwm08ow1.PeerProfile():
        return 'PeerProfile';
      case _i8bwgp5o.PeerSignal():
        return 'PeerSignal';
      case _i9gy9ys0.Person():
        return 'Person';
      case _iyxi6nm4.PersonHit():
        return 'PersonHit';
      case _iffou6wp.PersonLinkRejection():
        return 'PersonLinkRejection';
      case _i12ugm17.PersonProfile():
        return 'PersonProfile';
      case _ipnxekll.PersonRole():
        return 'PersonRole';
      case _i451wru0.PriceHistory():
        return 'PriceHistory';
      case _iyfyllvz.PricePoint():
        return 'PricePoint';
      case _iy288i3j.RelationFactKind():
        return 'RelationFactKind';
      case _id1oen7t.RelationOrigin():
        return 'RelationOrigin';
      case _idal2dwe.RelationPredicate():
        return 'RelationPredicate';
      case _ih00v9tp.RelationStatus():
        return 'RelationStatus';
      case _i83xfi8m.ResearchArticle():
        return 'ResearchArticle';
      case _iofl85o3.ResearchBookmark():
        return 'ResearchBookmark';
      case _iwk8vi27.ResearchRevision():
        return 'ResearchRevision';
      case _iwd80rqd.ResearchSnapshot():
        return 'ResearchSnapshot';
      case _iqdwyhyy.ReviewCheck():
        return 'ReviewCheck';
      case _ijdr1ucd.ReviewContext():
        return 'ReviewContext';
      case _i6uduqoi.ReviewItem():
        return 'ReviewItem';
      case _i22wlf7g.ReviewPage():
        return 'ReviewPage';
      case _izca0w44.ScreenPage():
        return 'ScreenPage';
      case _ie748vep.ScreenRow():
        return 'ScreenRow';
      case _igeg1iky.ScreenSort():
        return 'ScreenSort';
      case _ilujots3.Security():
        return 'Security';
      case _ic799xum.SecurityLinkBasis():
        return 'SecurityLinkBasis';
      case _ionn6cq2.SecurityQuote():
        return 'SecurityQuote';
      case _itljah4k.ShareholderEntry():
        return 'ShareholderEntry';
      case _iiit8m20.ShareholderReturn():
        return 'ShareholderReturn';
      case _icm1zoh2.Source():
        return 'Source';
      case _itk5lja3.SourceKind():
        return 'SourceKind';
      case _i3sjboun.StockTotalRow():
        return 'StockTotalRow';
      case _ir3er3o6.ThemeDetail():
        return 'ThemeDetail';
      case _irm69cop.ThemeMember():
        return 'ThemeMember';
      case _irah5hi6.ThemeMemberView():
        return 'ThemeMemberView';
      case _i4ynus9k.ThemeSummary():
        return 'ThemeSummary';
      case _injn1qca.TreasuryStockEntry():
        return 'TreasuryStockEntry';
      case _is2pxpv6.WatchlistCompanyView():
        return 'WatchlistCompanyView';
      case _ivan2n9m.WatchlistError():
        return 'WatchlistError';
      case _ijbmrc2g.WatchlistUpdateView():
        return 'WatchlistUpdateView';
      case _iyb0jzxs.WatchlistView():
        return 'WatchlistView';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'BillingCheckoutView') {
      return deserialize<_iybkvk8h.BillingCheckoutView>(data['data']);
    }
    if (dataClassName == 'BillingPaymentView') {
      return deserialize<_i4b9wxd2.BillingPaymentView>(data['data']);
    }
    if (dataClassName == 'MembershipView') {
      return deserialize<_ikugrjyl.MembershipView>(data['data']);
    }
    if (dataClassName == 'AccountView') {
      return deserialize<_i7n6g9s8.AccountView>(data['data']);
    }
    if (dataClassName == 'AiExtraction') {
      return deserialize<_idjojx8t.AiExtraction>(data['data']);
    }
    if (dataClassName == 'AiStatus') {
      return deserialize<_i7c6k6qa.AiStatus>(data['data']);
    }
    if (dataClassName == 'ApiCallUsage') {
      return deserialize<_i3e42he1.ApiCallUsage>(data['data']);
    }
    if (dataClassName == 'ApiProvider') {
      return deserialize<_i82zif2r.ApiProvider>(data['data']);
    }
    if (dataClassName == 'BusinessContent') {
      return deserialize<_ik6lqqsr.BusinessContent>(data['data']);
    }
    if (dataClassName == 'BusinessDigestKind') {
      return deserialize<_izxiijmh.BusinessDigestKind>(data['data']);
    }
    if (dataClassName == 'BusinessDigestSection') {
      return deserialize<_iq2bjjp3.BusinessDigestSection>(data['data']);
    }
    if (dataClassName == 'BusinessDocument') {
      return deserialize<_imi0q911.BusinessDocument>(data['data']);
    }
    if (dataClassName == 'BusinessDocumentRef') {
      return deserialize<_is707pet.BusinessDocumentRef>(data['data']);
    }
    if (dataClassName == 'BusinessFactPeriod') {
      return deserialize<_i1cpvxoo.BusinessFactPeriod>(data['data']);
    }
    if (dataClassName == 'BusinessProduct') {
      return deserialize<_i3peg7yx.BusinessProduct>(data['data']);
    }
    if (dataClassName == 'BusinessProfile') {
      return deserialize<_iegef18i.BusinessProfile>(data['data']);
    }
    if (dataClassName == 'BusinessSection') {
      return deserialize<_inylkhjt.BusinessSection>(data['data']);
    }
    if (dataClassName == 'BusinessTableInsight') {
      return deserialize<_i0vnq5ds.BusinessTableInsight>(data['data']);
    }
    if (dataClassName == 'BusinessTableMeasure') {
      return deserialize<_ia821tg8.BusinessTableMeasure>(data['data']);
    }
    if (dataClassName == 'BusinessTableRecord') {
      return deserialize<_i5mz554b.BusinessTableRecord>(data['data']);
    }
    if (dataClassName == 'BusinessUnderstanding') {
      return deserialize<_iwkhf8pb.BusinessUnderstanding>(data['data']);
    }
    if (dataClassName == 'Company') {
      return deserialize<_ipen255x.Company>(data['data']);
    }
    if (dataClassName == 'CompanyChange') {
      return deserialize<_isfozywu.CompanyChange>(data['data']);
    }
    if (dataClassName == 'CompanyDetail') {
      return deserialize<_ire9jjud.CompanyDetail>(data['data']);
    }
    if (dataClassName == 'CompanyFinancials') {
      return deserialize<_iki0y6e6.CompanyFinancials>(data['data']);
    }
    if (dataClassName == 'CompanyGovernance') {
      return deserialize<_ijqcijwd.CompanyGovernance>(data['data']);
    }
    if (dataClassName == 'CompanyGraph') {
      return deserialize<_ixtgihs0.CompanyGraph>(data['data']);
    }
    if (dataClassName == 'CompanyGroup') {
      return deserialize<_ihdcqaon.CompanyGroup>(data['data']);
    }
    if (dataClassName == 'CompanyListItem') {
      return deserialize<_i0csqxj4.CompanyListItem>(data['data']);
    }
    if (dataClassName == 'CompanyMarketCap') {
      return deserialize<_it4u3ib3.CompanyMarketCap>(data['data']);
    }
    if (dataClassName == 'CompanyNewsFeed') {
      return deserialize<_izcvpxxd.CompanyNewsFeed>(data['data']);
    }
    if (dataClassName == 'CompanyNewsItem') {
      return deserialize<_iiky47zh.CompanyNewsItem>(data['data']);
    }
    if (dataClassName == 'CompanyPage') {
      return deserialize<_iaj9eyri.CompanyPage>(data['data']);
    }
    if (dataClassName == 'CompanyRef') {
      return deserialize<_i4gnucl8.CompanyRef>(data['data']);
    }
    if (dataClassName == 'CompanySort') {
      return deserialize<_ia2izjbq.CompanySort>(data['data']);
    }
    if (dataClassName == 'DartCorpStatus') {
      return deserialize<_ir49pw6i.DartCorpStatus>(data['data']);
    }
    if (dataClassName == 'DartDisclosure') {
      return deserialize<_iw06ztex.DartDisclosure>(data['data']);
    }
    if (dataClassName == 'DartFiling') {
      return deserialize<_itki3qdq.DartFiling>(data['data']);
    }
    if (dataClassName == 'DartFilingScan') {
      return deserialize<_ixr5w3gq.DartFilingScan>(data['data']);
    }
    if (dataClassName == 'DartFilingSection') {
      return deserialize<_isprzv4c.DartFilingSection>(data['data']);
    }
    if (dataClassName == 'DartSection') {
      return deserialize<_islomtus.DartSection>(data['data']);
    }
    if (dataClassName == 'DisclosureLinkBasis') {
      return deserialize<_iffxd3r6.DisclosureLinkBasis>(data['data']);
    }
    if (dataClassName == 'DisclosureReport') {
      return deserialize<_i4blf95b.DisclosureReport>(data['data']);
    }
    if (dataClassName == 'DisclosureRow') {
      return deserialize<_irf27uzx.DisclosureRow>(data['data']);
    }
    if (dataClassName == 'DisclosureSectionInfo') {
      return deserialize<_ij0mhdco.DisclosureSectionInfo>(data['data']);
    }
    if (dataClassName == 'DisclosureTable') {
      return deserialize<_i7prd3sw.DisclosureTable>(data['data']);
    }
    if (dataClassName == 'DisclosureTableRow') {
      return deserialize<_i98o73zd.DisclosureTableRow>(data['data']);
    }
    if (dataClassName == 'DividendEntry') {
      return deserialize<_ith4ion6.DividendEntry>(data['data']);
    }
    if (dataClassName == 'DocumentFact') {
      return deserialize<_iy6p3omn.DocumentFact>(data['data']);
    }
    if (dataClassName == 'DocumentFactKind') {
      return deserialize<_iatg4403.DocumentFactKind>(data['data']);
    }
    if (dataClassName == 'IngestException') {
      return deserialize<_iqc95j34.IngestException>(data['data']);
    }
    if (dataClassName == 'ExecutiveEntry') {
      return deserialize<_i3df9cy5.ExecutiveEntry>(data['data']);
    }
    if (dataClassName == 'ExecutiveRegistration') {
      return deserialize<_iz7k3x6v.ExecutiveRegistration>(data['data']);
    }
    if (dataClassName == 'FacetCount') {
      return deserialize<_iqbvehdv.FacetCount>(data['data']);
    }
    if (dataClassName == 'FactItem') {
      return deserialize<_iawn4ngl.FactItem>(data['data']);
    }
    if (dataClassName == 'FactPage') {
      return deserialize<_iurbyopj.FactPage>(data['data']);
    }
    if (dataClassName == 'FilingFeedItem') {
      return deserialize<_iivg0zeh.FilingFeedItem>(data['data']);
    }
    if (dataClassName == 'FilingFetchStatus') {
      return deserialize<_i167q75d.FilingFetchStatus>(data['data']);
    }
    if (dataClassName == 'FinancialFact') {
      return deserialize<_igykxm42.FinancialFact>(data['data']);
    }
    if (dataClassName == 'FinancialLine') {
      return deserialize<_igzbjepn.FinancialLine>(data['data']);
    }
    if (dataClassName == 'FinancialPeriod') {
      return deserialize<_itz8g04g.FinancialPeriod>(data['data']);
    }
    if (dataClassName == 'FinancialReport') {
      return deserialize<_i1qwjg2x.FinancialReport>(data['data']);
    }
    if (dataClassName == 'FinancialReportCode') {
      return deserialize<_idwohplt.FinancialReportCode>(data['data']);
    }
    if (dataClassName == 'FinancialReportDetail') {
      return deserialize<_ia8vdu33.FinancialReportDetail>(data['data']);
    }
    if (dataClassName == 'FinancialStatementKind') {
      return deserialize<_im4itn08.FinancialStatementKind>(data['data']);
    }
    if (dataClassName == 'FsDiv') {
      return deserialize<_i906z99z.FsDiv>(data['data']);
    }
    if (dataClassName == 'GovernanceLink') {
      return deserialize<_ikth1mft.GovernanceLink>(data['data']);
    }
    if (dataClassName == 'GraphEdge') {
      return deserialize<_iamhnwn8.GraphEdge>(data['data']);
    }
    if (dataClassName == 'GraphNode') {
      return deserialize<_iqv6eyci.GraphNode>(data['data']);
    }
    if (dataClassName == 'GroupEdge') {
      return deserialize<_i1fyp5lv.GroupEdge>(data['data']);
    }
    if (dataClassName == 'GroupMember') {
      return deserialize<_iyd2zx8r.GroupMember>(data['data']);
    }
    if (dataClassName == 'GroupPerson') {
      return deserialize<_iklt0jfv.GroupPerson>(data['data']);
    }
    if (dataClassName == 'IndexHistory') {
      return deserialize<_iocwvagy.IndexHistory>(data['data']);
    }
    if (dataClassName == 'IndexPoint') {
      return deserialize<_it75qdkc.IndexPoint>(data['data']);
    }
    if (dataClassName == 'Industry') {
      return deserialize<_i3hzx3f1.Industry>(data['data']);
    }
    if (dataClassName == 'IndustryActivity') {
      return deserialize<_if5qperq.IndustryActivity>(data['data']);
    }
    if (dataClassName == 'IndustryDiscovery') {
      return deserialize<_ixuxxo68.IndustryDiscovery>(data['data']);
    }
    if (dataClassName == 'IndustryRevisionCheck') {
      return deserialize<_i25uuckt.IndustryRevisionCheck>(data['data']);
    }
    if (dataClassName == 'IngestCoverage') {
      return deserialize<_il0sbv1h.IngestCoverage>(data['data']);
    }
    if (dataClassName == 'IngestJob') {
      return deserialize<_iay1heal.IngestJob>(data['data']);
    }
    if (dataClassName == 'IngestScheduleEntry') {
      return deserialize<_ilyxu1av.IngestScheduleEntry>(data['data']);
    }
    if (dataClassName == 'IngestStatus') {
      return deserialize<_imojj26x.IngestStatus>(data['data']);
    }
    if (dataClassName == 'InvestmentEntry') {
      return deserialize<_i9p8kpm7.InvestmentEntry>(data['data']);
    }
    if (dataClassName == 'InvestmentTheme') {
      return deserialize<_i57inxpq.InvestmentTheme>(data['data']);
    }
    if (dataClassName == 'MacroSeriesView') {
      return deserialize<_id0q6lal.MacroSeriesView>(data['data']);
    }
    if (dataClassName == 'Market') {
      return deserialize<_iyzzhewo.Market>(data['data']);
    }
    if (dataClassName == 'MarketCapNode') {
      return deserialize<_i1tskjhh.MarketCapNode>(data['data']);
    }
    if (dataClassName == 'MarketCapPoint') {
      return deserialize<_igdvszti.MarketCapPoint>(data['data']);
    }
    if (dataClassName == 'MarketCapTreemap') {
      return deserialize<_iwodvuy1.MarketCapTreemap>(data['data']);
    }
    if (dataClassName == 'MarketIndexDay') {
      return deserialize<_ihawso0m.MarketIndexDay>(data['data']);
    }
    if (dataClassName == 'MarketIndexSnapshot') {
      return deserialize<_i9c8jqc3.MarketIndexSnapshot>(data['data']);
    }
    if (dataClassName == 'MarketSnapshot') {
      return deserialize<_ibhowe7d.MarketSnapshot>(data['data']);
    }
    if (dataClassName == 'MarketSnapshotDay') {
      return deserialize<_i3renazk.MarketSnapshotDay>(data['data']);
    }
    if (dataClassName == 'NewCompanyView') {
      return deserialize<_ivtwhw6z.NewCompanyView>(data['data']);
    }
    if (dataClassName == 'OntologyRelation') {
      return deserialize<_iejnlir1.OntologyRelation>(data['data']);
    }
    if (dataClassName == 'Overview') {
      return deserialize<_iz31wbgv.Overview>(data['data']);
    }
    if (dataClassName == 'OwnershipSnapshot') {
      return deserialize<_ilc2cd4p.OwnershipSnapshot>(data['data']);
    }
    if (dataClassName == 'PeerCandidate') {
      return deserialize<_i6cusig8.PeerCandidate>(data['data']);
    }
    if (dataClassName == 'PeerCandidates') {
      return deserialize<_i59onhk4.PeerCandidates>(data['data']);
    }
    if (dataClassName == 'PeerComparison') {
      return deserialize<_isobo9h5.PeerComparison>(data['data']);
    }
    if (dataClassName == 'PeerMetric') {
      return deserialize<_iihutb4k.PeerMetric>(data['data']);
    }
    if (dataClassName == 'PeerProfile') {
      return deserialize<_iwm08ow1.PeerProfile>(data['data']);
    }
    if (dataClassName == 'PeerSignal') {
      return deserialize<_i8bwgp5o.PeerSignal>(data['data']);
    }
    if (dataClassName == 'Person') {
      return deserialize<_i9gy9ys0.Person>(data['data']);
    }
    if (dataClassName == 'PersonHit') {
      return deserialize<_iyxi6nm4.PersonHit>(data['data']);
    }
    if (dataClassName == 'PersonLinkRejection') {
      return deserialize<_iffou6wp.PersonLinkRejection>(data['data']);
    }
    if (dataClassName == 'PersonProfile') {
      return deserialize<_i12ugm17.PersonProfile>(data['data']);
    }
    if (dataClassName == 'PersonRole') {
      return deserialize<_ipnxekll.PersonRole>(data['data']);
    }
    if (dataClassName == 'PriceHistory') {
      return deserialize<_i451wru0.PriceHistory>(data['data']);
    }
    if (dataClassName == 'PricePoint') {
      return deserialize<_iyfyllvz.PricePoint>(data['data']);
    }
    if (dataClassName == 'RelationFactKind') {
      return deserialize<_iy288i3j.RelationFactKind>(data['data']);
    }
    if (dataClassName == 'RelationOrigin') {
      return deserialize<_id1oen7t.RelationOrigin>(data['data']);
    }
    if (dataClassName == 'RelationPredicate') {
      return deserialize<_idal2dwe.RelationPredicate>(data['data']);
    }
    if (dataClassName == 'RelationStatus') {
      return deserialize<_ih00v9tp.RelationStatus>(data['data']);
    }
    if (dataClassName == 'ResearchArticle') {
      return deserialize<_i83xfi8m.ResearchArticle>(data['data']);
    }
    if (dataClassName == 'ResearchBookmark') {
      return deserialize<_iofl85o3.ResearchBookmark>(data['data']);
    }
    if (dataClassName == 'ResearchRevision') {
      return deserialize<_iwk8vi27.ResearchRevision>(data['data']);
    }
    if (dataClassName == 'ResearchSnapshot') {
      return deserialize<_iwd80rqd.ResearchSnapshot>(data['data']);
    }
    if (dataClassName == 'ReviewCheck') {
      return deserialize<_iqdwyhyy.ReviewCheck>(data['data']);
    }
    if (dataClassName == 'ReviewContext') {
      return deserialize<_ijdr1ucd.ReviewContext>(data['data']);
    }
    if (dataClassName == 'ReviewItem') {
      return deserialize<_i6uduqoi.ReviewItem>(data['data']);
    }
    if (dataClassName == 'ReviewPage') {
      return deserialize<_i22wlf7g.ReviewPage>(data['data']);
    }
    if (dataClassName == 'ScreenPage') {
      return deserialize<_izca0w44.ScreenPage>(data['data']);
    }
    if (dataClassName == 'ScreenRow') {
      return deserialize<_ie748vep.ScreenRow>(data['data']);
    }
    if (dataClassName == 'ScreenSort') {
      return deserialize<_igeg1iky.ScreenSort>(data['data']);
    }
    if (dataClassName == 'Security') {
      return deserialize<_ilujots3.Security>(data['data']);
    }
    if (dataClassName == 'SecurityLinkBasis') {
      return deserialize<_ic799xum.SecurityLinkBasis>(data['data']);
    }
    if (dataClassName == 'SecurityQuote') {
      return deserialize<_ionn6cq2.SecurityQuote>(data['data']);
    }
    if (dataClassName == 'ShareholderEntry') {
      return deserialize<_itljah4k.ShareholderEntry>(data['data']);
    }
    if (dataClassName == 'ShareholderReturn') {
      return deserialize<_iiit8m20.ShareholderReturn>(data['data']);
    }
    if (dataClassName == 'Source') {
      return deserialize<_icm1zoh2.Source>(data['data']);
    }
    if (dataClassName == 'SourceKind') {
      return deserialize<_itk5lja3.SourceKind>(data['data']);
    }
    if (dataClassName == 'StockTotalRow') {
      return deserialize<_i3sjboun.StockTotalRow>(data['data']);
    }
    if (dataClassName == 'ThemeDetail') {
      return deserialize<_ir3er3o6.ThemeDetail>(data['data']);
    }
    if (dataClassName == 'ThemeMember') {
      return deserialize<_irm69cop.ThemeMember>(data['data']);
    }
    if (dataClassName == 'ThemeMemberView') {
      return deserialize<_irah5hi6.ThemeMemberView>(data['data']);
    }
    if (dataClassName == 'ThemeSummary') {
      return deserialize<_i4ynus9k.ThemeSummary>(data['data']);
    }
    if (dataClassName == 'TreasuryStockEntry') {
      return deserialize<_injn1qca.TreasuryStockEntry>(data['data']);
    }
    if (dataClassName == 'WatchlistCompanyView') {
      return deserialize<_is2pxpv6.WatchlistCompanyView>(data['data']);
    }
    if (dataClassName == 'WatchlistError') {
      return deserialize<_ivan2n9m.WatchlistError>(data['data']);
    }
    if (dataClassName == 'WatchlistUpdateView') {
      return deserialize<_ijbmrc2g.WatchlistUpdateView>(data['data']);
    }
    if (dataClassName == 'WatchlistView') {
      return deserialize<_iyb0jzxs.WatchlistView>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol(
      'investment_ontology_serverpod',
      this,
    );
    _iacc.Protocol().registerHostProtocol(
      'investment_ontology_serverpod',
      this,
    );
  }

  @override
  String getModuleName() => 'investment_ontology_serverpod';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
