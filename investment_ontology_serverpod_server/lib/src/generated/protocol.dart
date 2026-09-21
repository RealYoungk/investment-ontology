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
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/company_group.dart'
    as _i4udlom4;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/disclosure_section_info.dart'
    as _itpltonf;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/document_fact.dart'
    as _ihq2wng4;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/facet_count.dart'
    as _iee4t190;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/filing_feed_item.dart'
    as _iwgt3edw;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/ingest_job.dart'
    as _idt86amb;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/investment_theme.dart'
    as _in6y0ur2;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/person_hit.dart'
    as _iqw74hrd;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/review_check.dart'
    as _iwp9ei5l;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/review_item.dart'
    as _ip1s5ejx;
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/theme_summary.dart'
    as _iy65bs9o;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'future_calls_generated_models/ai_extraction_future_call_run_model.dart'
    as _iskveedf;
import 'future_calls_generated_models/company_master_future_call_run_model.dart'
    as _i8298vau;
import 'future_calls_generated_models/disclosure_future_call_run_company_model.dart'
    as _iln8mnkp;
import 'future_calls_generated_models/disclosure_future_call_run_model.dart'
    as _i9swl9ej;
import 'future_calls_generated_models/financial_facts_future_call_run_company_model.dart'
    as _in9ocduk;
import 'future_calls_generated_models/financial_facts_future_call_run_model.dart'
    as _ijwdvc26;
import 'future_calls_generated_models/market_snapshot_future_call_run_model.dart'
    as _i7jjkv72;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'ontology/models/ai_extraction.dart' as _idjojx8t;
import 'ontology/models/ai_status.dart' as _i7c6k6qa;
import 'ontology/models/api_call_usage.dart' as _i3e42he1;
import 'ontology/models/api_provider.dart' as _i82zif2r;
import 'ontology/models/business_content.dart' as _ik6lqqsr;
import 'ontology/models/business_document.dart' as _imi0q911;
import 'ontology/models/business_document_ref.dart' as _is707pet;
import 'ontology/models/business_section.dart' as _inylkhjt;
import 'ontology/models/company.dart' as _ipen255x;
import 'ontology/models/company_change.dart' as _isfozywu;
import 'ontology/models/company_detail.dart' as _ire9jjud;
import 'ontology/models/company_financials.dart' as _iki0y6e6;
import 'ontology/models/company_governance.dart' as _ijqcijwd;
import 'ontology/models/company_graph.dart' as _ixtgihs0;
import 'ontology/models/company_group.dart' as _ihdcqaon;
import 'ontology/models/company_list_item.dart' as _i0csqxj4;
import 'ontology/models/company_market_cap.dart' as _it4u3ib3;
import 'ontology/models/company_page.dart' as _iaj9eyri;
import 'ontology/models/company_ref.dart' as _i4gnucl8;
import 'ontology/models/company_sort.dart' as _ia2izjbq;
import 'ontology/models/dart_corp_status.dart' as _ir49pw6i;
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
import 'ontology/models/industry.dart' as _i3hzx3f1;
import 'ontology/models/industry_revision_check.dart' as _i25uuckt;
import 'ontology/models/ingest_coverage.dart' as _il0sbv1h;
import 'ontology/models/ingest_job.dart' as _iay1heal;
import 'ontology/models/ingest_status.dart' as _imojj26x;
import 'ontology/models/investment_entry.dart' as _i9p8kpm7;
import 'ontology/models/investment_theme.dart' as _i57inxpq;
import 'ontology/models/market.dart' as _iyzzhewo;
import 'ontology/models/market_cap_node.dart' as _i1tskjhh;
import 'ontology/models/market_cap_treemap.dart' as _iwodvuy1;
import 'ontology/models/market_snapshot.dart' as _ibhowe7d;
import 'ontology/models/market_snapshot_day.dart' as _i3renazk;
import 'ontology/models/ontology_relation.dart' as _iejnlir1;
import 'ontology/models/overview.dart' as _iz31wbgv;
import 'ontology/models/peer_comparison.dart' as _isobo9h5;
import 'ontology/models/peer_metric.dart' as _iihutb4k;
import 'ontology/models/person.dart' as _i9gy9ys0;
import 'ontology/models/person_hit.dart' as _iyxi6nm4;
import 'ontology/models/person_link_rejection.dart' as _iffou6wp;
import 'ontology/models/person_profile.dart' as _i12ugm17;
import 'ontology/models/person_role.dart' as _ipnxekll;
import 'ontology/models/relation_fact_kind.dart' as _iy288i3j;
import 'ontology/models/relation_origin.dart' as _id1oen7t;
import 'ontology/models/relation_predicate.dart' as _idal2dwe;
import 'ontology/models/relation_status.dart' as _ih00v9tp;
import 'ontology/models/review_check.dart' as _iqdwyhyy;
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
export 'greetings/greeting.dart';
export 'ontology/models/ai_extraction.dart';
export 'ontology/models/ai_status.dart';
export 'ontology/models/api_call_usage.dart';
export 'ontology/models/api_provider.dart';
export 'ontology/models/business_content.dart';
export 'ontology/models/business_document.dart';
export 'ontology/models/business_document_ref.dart';
export 'ontology/models/business_section.dart';
export 'ontology/models/company.dart';
export 'ontology/models/company_change.dart';
export 'ontology/models/company_detail.dart';
export 'ontology/models/company_financials.dart';
export 'ontology/models/company_governance.dart';
export 'ontology/models/company_graph.dart';
export 'ontology/models/company_group.dart';
export 'ontology/models/company_list_item.dart';
export 'ontology/models/company_market_cap.dart';
export 'ontology/models/company_page.dart';
export 'ontology/models/company_ref.dart';
export 'ontology/models/company_sort.dart';
export 'ontology/models/dart_corp_status.dart';
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
export 'ontology/models/industry.dart';
export 'ontology/models/industry_revision_check.dart';
export 'ontology/models/ingest_coverage.dart';
export 'ontology/models/ingest_job.dart';
export 'ontology/models/ingest_status.dart';
export 'ontology/models/investment_entry.dart';
export 'ontology/models/investment_theme.dart';
export 'ontology/models/market.dart';
export 'ontology/models/market_cap_node.dart';
export 'ontology/models/market_cap_treemap.dart';
export 'ontology/models/market_snapshot.dart';
export 'ontology/models/market_snapshot_day.dart';
export 'ontology/models/ontology_relation.dart';
export 'ontology/models/overview.dart';
export 'ontology/models/peer_comparison.dart';
export 'ontology/models/peer_metric.dart';
export 'ontology/models/person.dart';
export 'ontology/models/person_hit.dart';
export 'ontology/models/person_link_rejection.dart';
export 'ontology/models/person_profile.dart';
export 'ontology/models/person_role.dart';
export 'ontology/models/relation_fact_kind.dart';
export 'ontology/models/relation_origin.dart';
export 'ontology/models/relation_predicate.dart';
export 'ontology/models/relation_status.dart';
export 'ontology/models/review_check.dart';
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

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'ai_extraction',
      dartName: 'AiExtraction',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'model',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'succeeded',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'relationCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'droppedCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'error',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'ai_extraction_fk_0',
          columns: ['documentId'],
          referenceTable: 'business_document',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ai_extraction_document_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'ai_extraction_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'api_call_usage',
      dartName: 'ApiCallUsage',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'provider',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ApiProvider',
        ),
        _isp.ColumnDefinition(
          name: 'day',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'calls',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'api_call_usage_provider_day_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'provider',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'day',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'business_document',
      dartName: 'BusinessDocument',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'rceptNo',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'text',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'charCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'business_document_fk_0',
          columns: ['reportId'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'business_document_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'business_document_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'company',
      dartName: 'Company',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'corpCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'nameEng',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stockName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stockCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'market',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:Market?',
        ),
        _isp.ColumnDefinition(
          name: 'ceoName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'jurirNo',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'bizrNo',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'address',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'homepageUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'irUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'phone',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'industryCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sectionCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'divisionCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'establishedDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'fiscalMonth',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'dartModifiedDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'profileSourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'profileUpdatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'company_fk_0',
          columns: ['profileSourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'company_corp_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'corpCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'company_stock_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'stockCode',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'company_market_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'market',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'company_section_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sectionCode',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'divisionCode',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'company_change',
      dartName: 'CompanyChange',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'field',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'oldValue',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'newValue',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'changedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'company_change_fk_0',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'company_change_fk_1',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'company_change_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'changedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dart_corp_status',
      dartName: 'DartCorpStatus',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'corpCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'corpCls',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'modifiedDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'checkedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'dart_corp_status_corp_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'corpCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dart_filing',
      dartName: 'DartFiling',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'rceptNo',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'corpCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'reportName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'receivedDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'reportCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:FinancialReportCode?',
        ),
        _isp.ColumnDefinition(
          name: 'consolidatedStatus',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FilingFetchStatus',
        ),
        _isp.ColumnDefinition(
          name: 'separateStatus',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FilingFetchStatus',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'lastError',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'discoveredAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'checkedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'dart_filing_fk_0',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'dart_filing_rcept_no_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'rceptNo',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'dart_filing_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportCode',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'dart_filing_received_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'receivedDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dart_filing_scan',
      dartName: 'DartFilingScan',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'scannedFrom',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'scannedThrough',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dart_filing_section',
      dartName: 'DartFilingSection',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'filingId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'yearRank',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'section',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DartSection',
        ),
        _isp.ColumnDefinition(
          name: 'tier',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FilingFetchStatus',
        ),
        _isp.ColumnDefinition(
          name: 'attempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'lastError',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'dart_filing_section_fk_0',
          columns: ['filingId'],
          referenceTable: 'dart_filing',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'dart_filing_section_filing_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'filingId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'section',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'dart_filing_section_queue_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'yearRank',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tier',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'disclosure_report',
      dartName: 'DisclosureReport',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'section',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DartSection',
        ),
        _isp.ColumnDefinition(
          name: 'rceptNo',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'reportCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FinancialReportCode',
        ),
        _isp.ColumnDefinition(
          name: 'settlementDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'rowCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'emptyRowCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'supersededById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'disclosure_report_fk_0',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'disclosure_report_fk_1',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'disclosure_report_fk_2',
          columns: ['supersededById'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'disclosure_report_rcept_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'rceptNo',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'section',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'disclosure_report_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'section',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'disclosure_row',
      dartName: 'DisclosureRow',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ord',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'isTotal',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'rowJson',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'disclosure_row_fk_0',
          columns: ['reportId'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'disclosure_row_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dividend_entry',
      dartName: 'DividendEntry',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ord',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'item',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'unit',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stockKind',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'current',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'prior',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'beforePrior',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'dividend_entry_fk_0',
          columns: ['reportId'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'dividend_entry_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'dividend_entry_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'document_fact',
      dartName: 'DocumentFact',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'documentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DocumentFactKind',
        ),
        _isp.ColumnDefinition(
          name: 'label',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'value',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'unit',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'asOf',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'evidence',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'extractedBy',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RelationOrigin',
        ),
        _isp.ColumnDefinition(
          name: 'extractorModel',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'confidence',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RelationStatus',
        ),
        _isp.ColumnDefinition(
          name: 'reviewedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewedBy',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'document_fact_fk_0',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'document_fact_fk_1',
          columns: ['documentId'],
          referenceTable: 'business_document',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'document_fact_fk_2',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'document_fact_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'kind',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'document_fact_document_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'documentId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'executive_entry',
      dartName: 'ExecutiveEntry',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ord',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sex',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'birthYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'birthMonth',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'position',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'registration',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ExecutiveRegistration',
        ),
        _isp.ColumnDefinition(
          name: 'registrationRaw',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'fullTime',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'duties',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'career',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'relationToLargestHolder',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'tenureMonths',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'termEndDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'personId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'executive_entry_fk_0',
          columns: ['reportId'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'executive_entry_fk_1',
          columns: ['personId'],
          referenceTable: 'person',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'executive_entry_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'executive_entry_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'executive_entry_person_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'personId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'financial_fact',
      dartName: 'FinancialFact',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'reportCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FinancialReportCode',
        ),
        _isp.ColumnDefinition(
          name: 'fsDiv',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FsDiv',
        ),
        _isp.ColumnDefinition(
          name: 'statement',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FinancialStatementKind',
        ),
        _isp.ColumnDefinition(
          name: 'accountId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'accountName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'accountDetail',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'ord',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'periodName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'amount',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'cumulativeAmount',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'priorPeriodName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'priorAmount',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'priorCumulativeAmount',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'priorQuarterName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'priorQuarterAmount',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'beforePriorPeriodName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'beforePriorAmount',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'currency',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'supersededById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'financial_fact_fk_0',
          columns: ['reportId'],
          referenceTable: 'financial_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'financial_fact_fk_1',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'financial_fact_fk_2',
          columns: ['supersededById'],
          referenceTable: 'financial_fact',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'financial_fact_series_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'statement',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'accountId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportCode',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'financial_fact_account_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'accountId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportCode',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fsDiv',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'financial_fact_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'financial_report',
      dartName: 'FinancialReport',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'rceptNo',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'fsDiv',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FsDiv',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'reportCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:FinancialReportCode',
        ),
        _isp.ColumnDefinition(
          name: 'reportName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'receivedDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'factCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'invalidAmountCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'supersededById',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'financial_report_fk_0',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'financial_report_fk_1',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'financial_report_fk_2',
          columns: ['supersededById'],
          referenceTable: 'financial_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'financial_report_rcept_no_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'rceptNo',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fsDiv',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'financial_report_period_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportCode',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'fsDiv',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'industry',
      dartName: 'Industry',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'code',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'level',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'parentCode',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'revision',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'industry_fk_0',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'industry_revision_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'revision',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'code',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ingest_job',
      dartName: 'IngestJob',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:IngestStatus',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'finishedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'total',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'processed',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'updated',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'failed',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'apiCalls',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'fullRefresh',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'message',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ingest_job_kind_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'kind',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'startedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'investment_entry',
      dartName: 'InvestmentEntry',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ord',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'investeeName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'purpose',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'firstAcquiredOn',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'firstAcquiredAmount',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'sharesBegin',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'ratioBegin',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'bookValueBegin',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'sharesChange',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'amountChange',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'valuationChange',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'sharesEnd',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'ratioEnd',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'bookValueEnd',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'investeeTotalAssets',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'investeeNetIncome',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'isTotal',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'investeeCompanyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'investeeLinkBasis',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:DisclosureLinkBasis?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'investment_entry_fk_0',
          columns: ['reportId'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'investment_entry_fk_1',
          columns: ['investeeCompanyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'investment_entry_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'investment_entry_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'investment_entry_investee_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'investeeCompanyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'market_snapshot',
      dartName: 'MarketSnapshot',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'securityId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'baseDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'closePrice',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'change',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'openPrice',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'highPrice',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'lowPrice',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'volume',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'tradingValue',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'listedShares',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'marketCap',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'market_snapshot_fk_0',
          columns: ['securityId'],
          referenceTable: 'security',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'market_snapshot_fk_1',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'market_snapshot_security_date_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'securityId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'baseDate',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'market_snapshot_date_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'baseDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'market_snapshot_day',
      dartName: 'MarketSnapshotDay',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'baseDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'rowCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'fetchedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'market_snapshot_day_fk_0',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'market_snapshot_day_date_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'baseDate',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'ontology_relation',
      dartName: 'OntologyRelation',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'predicate',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RelationPredicate',
        ),
        _isp.ColumnDefinition(
          name: 'subjectCompanyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'subjectPersonId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'subjectName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'objectCompanyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'objectName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'asOf',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'weight',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'factKind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RelationFactKind',
        ),
        _isp.ColumnDefinition(
          name: 'factId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'extractedBy',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RelationOrigin',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RelationStatus',
        ),
        _isp.ColumnDefinition(
          name: 'subjectBasis',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:DisclosureLinkBasis?',
        ),
        _isp.ColumnDefinition(
          name: 'evidence',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'confidence',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'extractorModel',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewedBy',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'ontology_relation_fk_0',
          columns: ['subjectCompanyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'ontology_relation_fk_1',
          columns: ['subjectPersonId'],
          referenceTable: 'person',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'ontology_relation_fk_2',
          columns: ['objectCompanyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'ontology_relation_fk_3',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'ontology_relation_subject_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'subjectCompanyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'ontology_relation_subject_person_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'subjectPersonId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'ontology_relation_object_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'objectCompanyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'ontology_relation_fact_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'factKind',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'factId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'person',
      dartName: 'Person',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'birthYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'birthMonth',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'sex',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'personKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'estimated',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'person_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'personKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'person_name_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'person_link_rejection',
      dartName: 'PersonLinkRejection',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'person_link_rejection_fk_0',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'person_link_rejection_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'review_check',
      dartName: 'ReviewCheck',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'scope',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'checked',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'correct',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'leftToPerson',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'checkedBy',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'note',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'review_check_scope_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'scope',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'security',
      dartName: 'Security',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'isinCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'shortCode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'market',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:Market?',
        ),
        _isp.ColumnDefinition(
          name: 'crno',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'corpName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'linkBasis',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:SecurityLinkBasis?',
        ),
        _isp.ColumnDefinition(
          name: 'lastSeenDate',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'security_fk_0',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'security_fk_1',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'security_isin_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'isinCode',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'security_short_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'shortCode',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'security_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'shareholder_entry',
      dartName: 'ShareholderEntry',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ord',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'holderName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'relationText',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stockKind',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sharesBegin',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'ratioBegin',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'sharesEnd',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'ratioEnd',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _isp.ColumnDefinition(
          name: 'remark',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'isTotal',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'holderCompanyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'holderPersonId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'holderLinkBasis',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:DisclosureLinkBasis?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'shareholder_entry_fk_0',
          columns: ['reportId'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'shareholder_entry_fk_1',
          columns: ['holderCompanyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'shareholder_entry_fk_2',
          columns: ['holderPersonId'],
          referenceTable: 'person',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'shareholder_entry_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'shareholder_entry_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'shareholder_entry_holder_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'holderCompanyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'shareholder_entry_holder_person_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'holderPersonId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'source',
      dartName: 'Source',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:SourceKind',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'reference',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'url',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'retrievedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'theme',
      dartName: 'InvestmentTheme',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'theme_name_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'theme_member',
      dartName: 'ThemeMember',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'themeId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'note',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sourceId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'theme_member_fk_0',
          columns: ['themeId'],
          referenceTable: 'theme',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'theme_member_fk_1',
          columns: ['companyId'],
          referenceTable: 'company',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'theme_member_fk_2',
          columns: ['sourceId'],
          referenceTable: 'source',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.restrict,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'theme_member_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'themeId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'theme_member_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'treasury_stock_entry',
      dartName: 'TreasuryStockEntry',
      schema: 'public',
      module: 'investment_ontology_serverpod',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'reportId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'companyId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'bsnsYear',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'ord',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'method1',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'method2',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'method3',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'stockKind',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'sharesBegin',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'acquired',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'disposed',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'retired',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'sharesEnd',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'BigInt?',
        ),
        _isp.ColumnDefinition(
          name: 'remark',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'isTotal',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'treasury_stock_entry_fk_0',
          columns: ['reportId'],
          referenceTable: 'disclosure_report',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'treasury_stock_entry_report_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reportId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'treasury_stock_entry_company_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'companyId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'bsnsYear',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _iskveedf.AiExtractionFutureCallRunModel) {
      return _iskveedf.AiExtractionFutureCallRunModel.fromJson(data) as T;
    }
    if (t == _i8298vau.CompanyMasterFutureCallRunModel) {
      return _i8298vau.CompanyMasterFutureCallRunModel.fromJson(data) as T;
    }
    if (t == _iln8mnkp.DisclosureFutureCallRunCompanyModel) {
      return _iln8mnkp.DisclosureFutureCallRunCompanyModel.fromJson(data) as T;
    }
    if (t == _i9swl9ej.DisclosureFutureCallRunModel) {
      return _i9swl9ej.DisclosureFutureCallRunModel.fromJson(data) as T;
    }
    if (t == _in9ocduk.FinancialFactsFutureCallRunCompanyModel) {
      return _in9ocduk.FinancialFactsFutureCallRunCompanyModel.fromJson(data)
          as T;
    }
    if (t == _ijwdvc26.FinancialFactsFutureCallRunModel) {
      return _ijwdvc26.FinancialFactsFutureCallRunModel.fromJson(data) as T;
    }
    if (t == _i7jjkv72.MarketSnapshotFutureCallRunModel) {
      return _i7jjkv72.MarketSnapshotFutureCallRunModel.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
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
    if (t == _imi0q911.BusinessDocument) {
      return _imi0q911.BusinessDocument.fromJson(data) as T;
    }
    if (t == _is707pet.BusinessDocumentRef) {
      return _is707pet.BusinessDocumentRef.fromJson(data) as T;
    }
    if (t == _inylkhjt.BusinessSection) {
      return _inylkhjt.BusinessSection.fromJson(data) as T;
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
    if (t == _i3hzx3f1.Industry) {
      return _i3hzx3f1.Industry.fromJson(data) as T;
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
    if (t == _imojj26x.IngestStatus) {
      return _imojj26x.IngestStatus.fromJson(data) as T;
    }
    if (t == _i9p8kpm7.InvestmentEntry) {
      return _i9p8kpm7.InvestmentEntry.fromJson(data) as T;
    }
    if (t == _i57inxpq.InvestmentTheme) {
      return _i57inxpq.InvestmentTheme.fromJson(data) as T;
    }
    if (t == _iyzzhewo.Market) {
      return _iyzzhewo.Market.fromJson(data) as T;
    }
    if (t == _i1tskjhh.MarketCapNode) {
      return _i1tskjhh.MarketCapNode.fromJson(data) as T;
    }
    if (t == _iwodvuy1.MarketCapTreemap) {
      return _iwodvuy1.MarketCapTreemap.fromJson(data) as T;
    }
    if (t == _ibhowe7d.MarketSnapshot) {
      return _ibhowe7d.MarketSnapshot.fromJson(data) as T;
    }
    if (t == _i3renazk.MarketSnapshotDay) {
      return _i3renazk.MarketSnapshotDay.fromJson(data) as T;
    }
    if (t == _iejnlir1.OntologyRelation) {
      return _iejnlir1.OntologyRelation.fromJson(data) as T;
    }
    if (t == _iz31wbgv.Overview) {
      return _iz31wbgv.Overview.fromJson(data) as T;
    }
    if (t == _isobo9h5.PeerComparison) {
      return _isobo9h5.PeerComparison.fromJson(data) as T;
    }
    if (t == _iihutb4k.PeerMetric) {
      return _iihutb4k.PeerMetric.fromJson(data) as T;
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
    if (t == _iqdwyhyy.ReviewCheck) {
      return _iqdwyhyy.ReviewCheck.fromJson(data) as T;
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
    if (t == _is.getType<_iskveedf.AiExtractionFutureCallRunModel?>()) {
      return (data != null
              ? _iskveedf.AiExtractionFutureCallRunModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i8298vau.CompanyMasterFutureCallRunModel?>()) {
      return (data != null
              ? _i8298vau.CompanyMasterFutureCallRunModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iln8mnkp.DisclosureFutureCallRunCompanyModel?>()) {
      return (data != null
              ? _iln8mnkp.DisclosureFutureCallRunCompanyModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i9swl9ej.DisclosureFutureCallRunModel?>()) {
      return (data != null
              ? _i9swl9ej.DisclosureFutureCallRunModel.fromJson(data)
              : null)
          as T;
    }
    if (t ==
        _is.getType<_in9ocduk.FinancialFactsFutureCallRunCompanyModel?>()) {
      return (data != null
              ? _in9ocduk.FinancialFactsFutureCallRunCompanyModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijwdvc26.FinancialFactsFutureCallRunModel?>()) {
      return (data != null
              ? _ijwdvc26.FinancialFactsFutureCallRunModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i7jjkv72.MarketSnapshotFutureCallRunModel?>()) {
      return (data != null
              ? _i7jjkv72.MarketSnapshotFutureCallRunModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_idjojx8t.AiExtraction?>()) {
      return (data != null ? _idjojx8t.AiExtraction.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i7c6k6qa.AiStatus?>()) {
      return (data != null ? _i7c6k6qa.AiStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3e42he1.ApiCallUsage?>()) {
      return (data != null ? _i3e42he1.ApiCallUsage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i82zif2r.ApiProvider?>()) {
      return (data != null ? _i82zif2r.ApiProvider.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ik6lqqsr.BusinessContent?>()) {
      return (data != null ? _ik6lqqsr.BusinessContent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imi0q911.BusinessDocument?>()) {
      return (data != null ? _imi0q911.BusinessDocument.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_is707pet.BusinessDocumentRef?>()) {
      return (data != null
              ? _is707pet.BusinessDocumentRef.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_inylkhjt.BusinessSection?>()) {
      return (data != null ? _inylkhjt.BusinessSection.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipen255x.Company?>()) {
      return (data != null ? _ipen255x.Company.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_isfozywu.CompanyChange?>()) {
      return (data != null ? _isfozywu.CompanyChange.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ire9jjud.CompanyDetail?>()) {
      return (data != null ? _ire9jjud.CompanyDetail.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iki0y6e6.CompanyFinancials?>()) {
      return (data != null ? _iki0y6e6.CompanyFinancials.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijqcijwd.CompanyGovernance?>()) {
      return (data != null ? _ijqcijwd.CompanyGovernance.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixtgihs0.CompanyGraph?>()) {
      return (data != null ? _ixtgihs0.CompanyGraph.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihdcqaon.CompanyGroup?>()) {
      return (data != null ? _ihdcqaon.CompanyGroup.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i0csqxj4.CompanyListItem?>()) {
      return (data != null ? _i0csqxj4.CompanyListItem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_it4u3ib3.CompanyMarketCap?>()) {
      return (data != null ? _it4u3ib3.CompanyMarketCap.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaj9eyri.CompanyPage?>()) {
      return (data != null ? _iaj9eyri.CompanyPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i4gnucl8.CompanyRef?>()) {
      return (data != null ? _i4gnucl8.CompanyRef.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ia2izjbq.CompanySort?>()) {
      return (data != null ? _ia2izjbq.CompanySort.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ir49pw6i.DartCorpStatus?>()) {
      return (data != null ? _ir49pw6i.DartCorpStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_itki3qdq.DartFiling?>()) {
      return (data != null ? _itki3qdq.DartFiling.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixr5w3gq.DartFilingScan?>()) {
      return (data != null ? _ixr5w3gq.DartFilingScan.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_isprzv4c.DartFilingSection?>()) {
      return (data != null ? _isprzv4c.DartFilingSection.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_islomtus.DartSection?>()) {
      return (data != null ? _islomtus.DartSection.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iffxd3r6.DisclosureLinkBasis?>()) {
      return (data != null
              ? _iffxd3r6.DisclosureLinkBasis.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i4blf95b.DisclosureReport?>()) {
      return (data != null ? _i4blf95b.DisclosureReport.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_irf27uzx.DisclosureRow?>()) {
      return (data != null ? _irf27uzx.DisclosureRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ij0mhdco.DisclosureSectionInfo?>()) {
      return (data != null
              ? _ij0mhdco.DisclosureSectionInfo.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i7prd3sw.DisclosureTable?>()) {
      return (data != null ? _i7prd3sw.DisclosureTable.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i98o73zd.DisclosureTableRow?>()) {
      return (data != null ? _i98o73zd.DisclosureTableRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ith4ion6.DividendEntry?>()) {
      return (data != null ? _ith4ion6.DividendEntry.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iy6p3omn.DocumentFact?>()) {
      return (data != null ? _iy6p3omn.DocumentFact.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iatg4403.DocumentFactKind?>()) {
      return (data != null ? _iatg4403.DocumentFactKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iqc95j34.IngestException?>()) {
      return (data != null ? _iqc95j34.IngestException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3df9cy5.ExecutiveEntry?>()) {
      return (data != null ? _i3df9cy5.ExecutiveEntry.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iz7k3x6v.ExecutiveRegistration?>()) {
      return (data != null
              ? _iz7k3x6v.ExecutiveRegistration.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqbvehdv.FacetCount?>()) {
      return (data != null ? _iqbvehdv.FacetCount.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iawn4ngl.FactItem?>()) {
      return (data != null ? _iawn4ngl.FactItem.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iurbyopj.FactPage?>()) {
      return (data != null ? _iurbyopj.FactPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iivg0zeh.FilingFeedItem?>()) {
      return (data != null ? _iivg0zeh.FilingFeedItem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i167q75d.FilingFetchStatus?>()) {
      return (data != null ? _i167q75d.FilingFetchStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igykxm42.FinancialFact?>()) {
      return (data != null ? _igykxm42.FinancialFact.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igzbjepn.FinancialLine?>()) {
      return (data != null ? _igzbjepn.FinancialLine.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_itz8g04g.FinancialPeriod?>()) {
      return (data != null ? _itz8g04g.FinancialPeriod.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i1qwjg2x.FinancialReport?>()) {
      return (data != null ? _i1qwjg2x.FinancialReport.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idwohplt.FinancialReportCode?>()) {
      return (data != null
              ? _idwohplt.FinancialReportCode.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ia8vdu33.FinancialReportDetail?>()) {
      return (data != null
              ? _ia8vdu33.FinancialReportDetail.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_im4itn08.FinancialStatementKind?>()) {
      return (data != null
              ? _im4itn08.FinancialStatementKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i906z99z.FsDiv?>()) {
      return (data != null ? _i906z99z.FsDiv.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ikth1mft.GovernanceLink?>()) {
      return (data != null ? _ikth1mft.GovernanceLink.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iamhnwn8.GraphEdge?>()) {
      return (data != null ? _iamhnwn8.GraphEdge.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iqv6eyci.GraphNode?>()) {
      return (data != null ? _iqv6eyci.GraphNode.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1fyp5lv.GroupEdge?>()) {
      return (data != null ? _i1fyp5lv.GroupEdge.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyd2zx8r.GroupMember?>()) {
      return (data != null ? _iyd2zx8r.GroupMember.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iklt0jfv.GroupPerson?>()) {
      return (data != null ? _iklt0jfv.GroupPerson.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3hzx3f1.Industry?>()) {
      return (data != null ? _i3hzx3f1.Industry.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i25uuckt.IndustryRevisionCheck?>()) {
      return (data != null
              ? _i25uuckt.IndustryRevisionCheck.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_il0sbv1h.IngestCoverage?>()) {
      return (data != null ? _il0sbv1h.IngestCoverage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iay1heal.IngestJob?>()) {
      return (data != null ? _iay1heal.IngestJob.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_imojj26x.IngestStatus?>()) {
      return (data != null ? _imojj26x.IngestStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i9p8kpm7.InvestmentEntry?>()) {
      return (data != null ? _i9p8kpm7.InvestmentEntry.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i57inxpq.InvestmentTheme?>()) {
      return (data != null ? _i57inxpq.InvestmentTheme.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iyzzhewo.Market?>()) {
      return (data != null ? _iyzzhewo.Market.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1tskjhh.MarketCapNode?>()) {
      return (data != null ? _i1tskjhh.MarketCapNode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iwodvuy1.MarketCapTreemap?>()) {
      return (data != null ? _iwodvuy1.MarketCapTreemap.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibhowe7d.MarketSnapshot?>()) {
      return (data != null ? _ibhowe7d.MarketSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i3renazk.MarketSnapshotDay?>()) {
      return (data != null ? _i3renazk.MarketSnapshotDay.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iejnlir1.OntologyRelation?>()) {
      return (data != null ? _iejnlir1.OntologyRelation.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iz31wbgv.Overview?>()) {
      return (data != null ? _iz31wbgv.Overview.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_isobo9h5.PeerComparison?>()) {
      return (data != null ? _isobo9h5.PeerComparison.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iihutb4k.PeerMetric?>()) {
      return (data != null ? _iihutb4k.PeerMetric.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i9gy9ys0.Person?>()) {
      return (data != null ? _i9gy9ys0.Person.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyxi6nm4.PersonHit?>()) {
      return (data != null ? _iyxi6nm4.PersonHit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iffou6wp.PersonLinkRejection?>()) {
      return (data != null
              ? _iffou6wp.PersonLinkRejection.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i12ugm17.PersonProfile?>()) {
      return (data != null ? _i12ugm17.PersonProfile.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipnxekll.PersonRole?>()) {
      return (data != null ? _ipnxekll.PersonRole.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iy288i3j.RelationFactKind?>()) {
      return (data != null ? _iy288i3j.RelationFactKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_id1oen7t.RelationOrigin?>()) {
      return (data != null ? _id1oen7t.RelationOrigin.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idal2dwe.RelationPredicate?>()) {
      return (data != null ? _idal2dwe.RelationPredicate.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ih00v9tp.RelationStatus?>()) {
      return (data != null ? _ih00v9tp.RelationStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iqdwyhyy.ReviewCheck?>()) {
      return (data != null ? _iqdwyhyy.ReviewCheck.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6uduqoi.ReviewItem?>()) {
      return (data != null ? _i6uduqoi.ReviewItem.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i22wlf7g.ReviewPage?>()) {
      return (data != null ? _i22wlf7g.ReviewPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_izca0w44.ScreenPage?>()) {
      return (data != null ? _izca0w44.ScreenPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ie748vep.ScreenRow?>()) {
      return (data != null ? _ie748vep.ScreenRow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_igeg1iky.ScreenSort?>()) {
      return (data != null ? _igeg1iky.ScreenSort.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ilujots3.Security?>()) {
      return (data != null ? _ilujots3.Security.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ic799xum.SecurityLinkBasis?>()) {
      return (data != null ? _ic799xum.SecurityLinkBasis.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ionn6cq2.SecurityQuote?>()) {
      return (data != null ? _ionn6cq2.SecurityQuote.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_itljah4k.ShareholderEntry?>()) {
      return (data != null ? _itljah4k.ShareholderEntry.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iiit8m20.ShareholderReturn?>()) {
      return (data != null ? _iiit8m20.ShareholderReturn.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_icm1zoh2.Source?>()) {
      return (data != null ? _icm1zoh2.Source.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itk5lja3.SourceKind?>()) {
      return (data != null ? _itk5lja3.SourceKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3sjboun.StockTotalRow?>()) {
      return (data != null ? _i3sjboun.StockTotalRow.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ir3er3o6.ThemeDetail?>()) {
      return (data != null ? _ir3er3o6.ThemeDetail.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_irm69cop.ThemeMember?>()) {
      return (data != null ? _irm69cop.ThemeMember.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_irah5hi6.ThemeMemberView?>()) {
      return (data != null ? _irah5hi6.ThemeMemberView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4ynus9k.ThemeSummary?>()) {
      return (data != null ? _i4ynus9k.ThemeSummary.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_injn1qca.TreasuryStockEntry?>()) {
      return (data != null ? _injn1qca.TreasuryStockEntry.fromJson(data) : null)
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
    if (t == List<_icm1zoh2.Source>) {
      return (data as List)
              .map((e) => deserialize<_icm1zoh2.Source>(e))
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
    if (t == List<_i0csqxj4.CompanyListItem>) {
      return (data as List)
              .map((e) => deserialize<_i0csqxj4.CompanyListItem>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
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
    if (t == List<_irah5hi6.ThemeMemberView>) {
      return (data as List)
              .map((e) => deserialize<_irah5hi6.ThemeMemberView>(e))
              .toList()
          as T;
    }
    if (t == List<_iee4t190.FacetCount>) {
      return (data as List)
              .map((e) => deserialize<_iee4t190.FacetCount>(e))
              .toList()
          as T;
    }
    if (t == List<_itpltonf.DisclosureSectionInfo>) {
      return (data as List)
              .map((e) => deserialize<_itpltonf.DisclosureSectionInfo>(e))
              .toList()
          as T;
    }
    if (t == List<_ihq2wng4.DocumentFact>) {
      return (data as List)
              .map((e) => deserialize<_ihq2wng4.DocumentFact>(e))
              .toList()
          as T;
    }
    if (t == List<_iwgt3edw.FilingFeedItem>) {
      return (data as List)
              .map((e) => deserialize<_iwgt3edw.FilingFeedItem>(e))
              .toList()
          as T;
    }
    if (t == List<_iqw74hrd.PersonHit>) {
      return (data as List)
              .map((e) => deserialize<_iqw74hrd.PersonHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i4udlom4.CompanyGroup>) {
      return (data as List)
              .map((e) => deserialize<_i4udlom4.CompanyGroup>(e))
              .toList()
          as T;
    }
    if (t == List<_idt86amb.IngestJob>) {
      return (data as List)
              .map((e) => deserialize<_idt86amb.IngestJob>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_iwp9ei5l.ReviewCheck>) {
      return (data as List)
              .map((e) => deserialize<_iwp9ei5l.ReviewCheck>(e))
              .toList()
          as T;
    }
    if (t == List<_ip1s5ejx.ReviewItem>) {
      return (data as List)
              .map((e) => deserialize<_ip1s5ejx.ReviewItem>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_iy65bs9o.ThemeSummary>) {
      return (data as List)
              .map((e) => deserialize<_iy65bs9o.ThemeSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_in6y0ur2.InvestmentTheme>) {
      return (data as List)
              .map((e) => deserialize<_in6y0ur2.InvestmentTheme>(e))
              .toList()
          as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _iskveedf.AiExtractionFutureCallRunModel =>
        'AiExtractionFutureCallRunModel',
      _i8298vau.CompanyMasterFutureCallRunModel =>
        'CompanyMasterFutureCallRunModel',
      _iln8mnkp.DisclosureFutureCallRunCompanyModel =>
        'DisclosureFutureCallRunCompanyModel',
      _i9swl9ej.DisclosureFutureCallRunModel => 'DisclosureFutureCallRunModel',
      _in9ocduk.FinancialFactsFutureCallRunCompanyModel =>
        'FinancialFactsFutureCallRunCompanyModel',
      _ijwdvc26.FinancialFactsFutureCallRunModel =>
        'FinancialFactsFutureCallRunModel',
      _i7jjkv72.MarketSnapshotFutureCallRunModel =>
        'MarketSnapshotFutureCallRunModel',
      _izw8z7ou.Greeting => 'Greeting',
      _idjojx8t.AiExtraction => 'AiExtraction',
      _i7c6k6qa.AiStatus => 'AiStatus',
      _i3e42he1.ApiCallUsage => 'ApiCallUsage',
      _i82zif2r.ApiProvider => 'ApiProvider',
      _ik6lqqsr.BusinessContent => 'BusinessContent',
      _imi0q911.BusinessDocument => 'BusinessDocument',
      _is707pet.BusinessDocumentRef => 'BusinessDocumentRef',
      _inylkhjt.BusinessSection => 'BusinessSection',
      _ipen255x.Company => 'Company',
      _isfozywu.CompanyChange => 'CompanyChange',
      _ire9jjud.CompanyDetail => 'CompanyDetail',
      _iki0y6e6.CompanyFinancials => 'CompanyFinancials',
      _ijqcijwd.CompanyGovernance => 'CompanyGovernance',
      _ixtgihs0.CompanyGraph => 'CompanyGraph',
      _ihdcqaon.CompanyGroup => 'CompanyGroup',
      _i0csqxj4.CompanyListItem => 'CompanyListItem',
      _it4u3ib3.CompanyMarketCap => 'CompanyMarketCap',
      _iaj9eyri.CompanyPage => 'CompanyPage',
      _i4gnucl8.CompanyRef => 'CompanyRef',
      _ia2izjbq.CompanySort => 'CompanySort',
      _ir49pw6i.DartCorpStatus => 'DartCorpStatus',
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
      _i3hzx3f1.Industry => 'Industry',
      _i25uuckt.IndustryRevisionCheck => 'IndustryRevisionCheck',
      _il0sbv1h.IngestCoverage => 'IngestCoverage',
      _iay1heal.IngestJob => 'IngestJob',
      _imojj26x.IngestStatus => 'IngestStatus',
      _i9p8kpm7.InvestmentEntry => 'InvestmentEntry',
      _i57inxpq.InvestmentTheme => 'InvestmentTheme',
      _iyzzhewo.Market => 'Market',
      _i1tskjhh.MarketCapNode => 'MarketCapNode',
      _iwodvuy1.MarketCapTreemap => 'MarketCapTreemap',
      _ibhowe7d.MarketSnapshot => 'MarketSnapshot',
      _i3renazk.MarketSnapshotDay => 'MarketSnapshotDay',
      _iejnlir1.OntologyRelation => 'OntologyRelation',
      _iz31wbgv.Overview => 'Overview',
      _isobo9h5.PeerComparison => 'PeerComparison',
      _iihutb4k.PeerMetric => 'PeerMetric',
      _i9gy9ys0.Person => 'Person',
      _iyxi6nm4.PersonHit => 'PersonHit',
      _iffou6wp.PersonLinkRejection => 'PersonLinkRejection',
      _i12ugm17.PersonProfile => 'PersonProfile',
      _ipnxekll.PersonRole => 'PersonRole',
      _iy288i3j.RelationFactKind => 'RelationFactKind',
      _id1oen7t.RelationOrigin => 'RelationOrigin',
      _idal2dwe.RelationPredicate => 'RelationPredicate',
      _ih00v9tp.RelationStatus => 'RelationStatus',
      _iqdwyhyy.ReviewCheck => 'ReviewCheck',
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
      case _iskveedf.AiExtractionFutureCallRunModel():
        return 'AiExtractionFutureCallRunModel';
      case _i8298vau.CompanyMasterFutureCallRunModel():
        return 'CompanyMasterFutureCallRunModel';
      case _iln8mnkp.DisclosureFutureCallRunCompanyModel():
        return 'DisclosureFutureCallRunCompanyModel';
      case _i9swl9ej.DisclosureFutureCallRunModel():
        return 'DisclosureFutureCallRunModel';
      case _in9ocduk.FinancialFactsFutureCallRunCompanyModel():
        return 'FinancialFactsFutureCallRunCompanyModel';
      case _ijwdvc26.FinancialFactsFutureCallRunModel():
        return 'FinancialFactsFutureCallRunModel';
      case _i7jjkv72.MarketSnapshotFutureCallRunModel():
        return 'MarketSnapshotFutureCallRunModel';
      case _izw8z7ou.Greeting():
        return 'Greeting';
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
      case _imi0q911.BusinessDocument():
        return 'BusinessDocument';
      case _is707pet.BusinessDocumentRef():
        return 'BusinessDocumentRef';
      case _inylkhjt.BusinessSection():
        return 'BusinessSection';
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
      case _iaj9eyri.CompanyPage():
        return 'CompanyPage';
      case _i4gnucl8.CompanyRef():
        return 'CompanyRef';
      case _ia2izjbq.CompanySort():
        return 'CompanySort';
      case _ir49pw6i.DartCorpStatus():
        return 'DartCorpStatus';
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
      case _i3hzx3f1.Industry():
        return 'Industry';
      case _i25uuckt.IndustryRevisionCheck():
        return 'IndustryRevisionCheck';
      case _il0sbv1h.IngestCoverage():
        return 'IngestCoverage';
      case _iay1heal.IngestJob():
        return 'IngestJob';
      case _imojj26x.IngestStatus():
        return 'IngestStatus';
      case _i9p8kpm7.InvestmentEntry():
        return 'InvestmentEntry';
      case _i57inxpq.InvestmentTheme():
        return 'InvestmentTheme';
      case _iyzzhewo.Market():
        return 'Market';
      case _i1tskjhh.MarketCapNode():
        return 'MarketCapNode';
      case _iwodvuy1.MarketCapTreemap():
        return 'MarketCapTreemap';
      case _ibhowe7d.MarketSnapshot():
        return 'MarketSnapshot';
      case _i3renazk.MarketSnapshotDay():
        return 'MarketSnapshotDay';
      case _iejnlir1.OntologyRelation():
        return 'OntologyRelation';
      case _iz31wbgv.Overview():
        return 'Overview';
      case _isobo9h5.PeerComparison():
        return 'PeerComparison';
      case _iihutb4k.PeerMetric():
        return 'PeerMetric';
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
      case _iy288i3j.RelationFactKind():
        return 'RelationFactKind';
      case _id1oen7t.RelationOrigin():
        return 'RelationOrigin';
      case _idal2dwe.RelationPredicate():
        return 'RelationPredicate';
      case _ih00v9tp.RelationStatus():
        return 'RelationStatus';
      case _iqdwyhyy.ReviewCheck():
        return 'ReviewCheck';
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
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AiExtractionFutureCallRunModel') {
      return deserialize<_iskveedf.AiExtractionFutureCallRunModel>(
        data['data'],
      );
    }
    if (dataClassName == 'CompanyMasterFutureCallRunModel') {
      return deserialize<_i8298vau.CompanyMasterFutureCallRunModel>(
        data['data'],
      );
    }
    if (dataClassName == 'DisclosureFutureCallRunCompanyModel') {
      return deserialize<_iln8mnkp.DisclosureFutureCallRunCompanyModel>(
        data['data'],
      );
    }
    if (dataClassName == 'DisclosureFutureCallRunModel') {
      return deserialize<_i9swl9ej.DisclosureFutureCallRunModel>(data['data']);
    }
    if (dataClassName == 'FinancialFactsFutureCallRunCompanyModel') {
      return deserialize<_in9ocduk.FinancialFactsFutureCallRunCompanyModel>(
        data['data'],
      );
    }
    if (dataClassName == 'FinancialFactsFutureCallRunModel') {
      return deserialize<_ijwdvc26.FinancialFactsFutureCallRunModel>(
        data['data'],
      );
    }
    if (dataClassName == 'MarketSnapshotFutureCallRunModel') {
      return deserialize<_i7jjkv72.MarketSnapshotFutureCallRunModel>(
        data['data'],
      );
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
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
    if (dataClassName == 'BusinessDocument') {
      return deserialize<_imi0q911.BusinessDocument>(data['data']);
    }
    if (dataClassName == 'BusinessDocumentRef') {
      return deserialize<_is707pet.BusinessDocumentRef>(data['data']);
    }
    if (dataClassName == 'BusinessSection') {
      return deserialize<_inylkhjt.BusinessSection>(data['data']);
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
    if (dataClassName == 'Industry') {
      return deserialize<_i3hzx3f1.Industry>(data['data']);
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
    if (dataClassName == 'IngestStatus') {
      return deserialize<_imojj26x.IngestStatus>(data['data']);
    }
    if (dataClassName == 'InvestmentEntry') {
      return deserialize<_i9p8kpm7.InvestmentEntry>(data['data']);
    }
    if (dataClassName == 'InvestmentTheme') {
      return deserialize<_i57inxpq.InvestmentTheme>(data['data']);
    }
    if (dataClassName == 'Market') {
      return deserialize<_iyzzhewo.Market>(data['data']);
    }
    if (dataClassName == 'MarketCapNode') {
      return deserialize<_i1tskjhh.MarketCapNode>(data['data']);
    }
    if (dataClassName == 'MarketCapTreemap') {
      return deserialize<_iwodvuy1.MarketCapTreemap>(data['data']);
    }
    if (dataClassName == 'MarketSnapshot') {
      return deserialize<_ibhowe7d.MarketSnapshot>(data['data']);
    }
    if (dataClassName == 'MarketSnapshotDay') {
      return deserialize<_i3renazk.MarketSnapshotDay>(data['data']);
    }
    if (dataClassName == 'OntologyRelation') {
      return deserialize<_iejnlir1.OntologyRelation>(data['data']);
    }
    if (dataClassName == 'Overview') {
      return deserialize<_iz31wbgv.Overview>(data['data']);
    }
    if (dataClassName == 'PeerComparison') {
      return deserialize<_isobo9h5.PeerComparison>(data['data']);
    }
    if (dataClassName == 'PeerMetric') {
      return deserialize<_iihutb4k.PeerMetric>(data['data']);
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
    if (dataClassName == 'ReviewCheck') {
      return deserialize<_iqdwyhyy.ReviewCheck>(data['data']);
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
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol(
      'investment_ontology_serverpod',
      this,
    );
    _iacs.Protocol().registerHostProtocol(
      'investment_ontology_serverpod',
      this,
    );
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _idjojx8t.AiExtraction:
        return _idjojx8t.AiExtraction.t;
      case _i3e42he1.ApiCallUsage:
        return _i3e42he1.ApiCallUsage.t;
      case _imi0q911.BusinessDocument:
        return _imi0q911.BusinessDocument.t;
      case _ipen255x.Company:
        return _ipen255x.Company.t;
      case _isfozywu.CompanyChange:
        return _isfozywu.CompanyChange.t;
      case _ir49pw6i.DartCorpStatus:
        return _ir49pw6i.DartCorpStatus.t;
      case _itki3qdq.DartFiling:
        return _itki3qdq.DartFiling.t;
      case _ixr5w3gq.DartFilingScan:
        return _ixr5w3gq.DartFilingScan.t;
      case _isprzv4c.DartFilingSection:
        return _isprzv4c.DartFilingSection.t;
      case _i4blf95b.DisclosureReport:
        return _i4blf95b.DisclosureReport.t;
      case _irf27uzx.DisclosureRow:
        return _irf27uzx.DisclosureRow.t;
      case _ith4ion6.DividendEntry:
        return _ith4ion6.DividendEntry.t;
      case _iy6p3omn.DocumentFact:
        return _iy6p3omn.DocumentFact.t;
      case _i3df9cy5.ExecutiveEntry:
        return _i3df9cy5.ExecutiveEntry.t;
      case _igykxm42.FinancialFact:
        return _igykxm42.FinancialFact.t;
      case _i1qwjg2x.FinancialReport:
        return _i1qwjg2x.FinancialReport.t;
      case _i3hzx3f1.Industry:
        return _i3hzx3f1.Industry.t;
      case _iay1heal.IngestJob:
        return _iay1heal.IngestJob.t;
      case _i9p8kpm7.InvestmentEntry:
        return _i9p8kpm7.InvestmentEntry.t;
      case _i57inxpq.InvestmentTheme:
        return _i57inxpq.InvestmentTheme.t;
      case _ibhowe7d.MarketSnapshot:
        return _ibhowe7d.MarketSnapshot.t;
      case _i3renazk.MarketSnapshotDay:
        return _i3renazk.MarketSnapshotDay.t;
      case _iejnlir1.OntologyRelation:
        return _iejnlir1.OntologyRelation.t;
      case _i9gy9ys0.Person:
        return _i9gy9ys0.Person.t;
      case _iffou6wp.PersonLinkRejection:
        return _iffou6wp.PersonLinkRejection.t;
      case _iqdwyhyy.ReviewCheck:
        return _iqdwyhyy.ReviewCheck.t;
      case _ilujots3.Security:
        return _ilujots3.Security.t;
      case _itljah4k.ShareholderEntry:
        return _itljah4k.ShareholderEntry.t;
      case _icm1zoh2.Source:
        return _icm1zoh2.Source.t;
      case _irm69cop.ThemeMember:
        return _irm69cop.ThemeMember.t;
      case _injn1qca.TreasuryStockEntry:
        return _injn1qca.TreasuryStockEntry.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
