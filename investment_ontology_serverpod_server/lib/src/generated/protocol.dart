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
import 'package:investment_ontology_serverpod_server/src/generated/ontology/models/facet_count.dart'
    as _iee4t190;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'future_calls_generated_models/company_master_future_call_run_model.dart'
    as _i8298vau;
import 'future_calls_generated_models/financial_facts_future_call_run_model.dart'
    as _ijwdvc26;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'ontology/models/api_call_usage.dart' as _i3e42he1;
import 'ontology/models/api_provider.dart' as _i82zif2r;
import 'ontology/models/company.dart' as _ipen255x;
import 'ontology/models/company_change.dart' as _isfozywu;
import 'ontology/models/company_detail.dart' as _ire9jjud;
import 'ontology/models/company_list_item.dart' as _i0csqxj4;
import 'ontology/models/company_page.dart' as _iaj9eyri;
import 'ontology/models/company_sort.dart' as _ia2izjbq;
import 'ontology/models/dart_corp_status.dart' as _ir49pw6i;
import 'ontology/models/dart_filing.dart' as _itki3qdq;
import 'ontology/models/exceptions.dart' as _iqc95j34;
import 'ontology/models/facet_count.dart' as _iqbvehdv;
import 'ontology/models/filing_fetch_status.dart' as _i167q75d;
import 'ontology/models/financial_fact.dart' as _igykxm42;
import 'ontology/models/financial_report.dart' as _i1qwjg2x;
import 'ontology/models/financial_report_code.dart' as _idwohplt;
import 'ontology/models/financial_statement_kind.dart' as _im4itn08;
import 'ontology/models/fs_div.dart' as _i906z99z;
import 'ontology/models/industry.dart' as _i3hzx3f1;
import 'ontology/models/industry_revision_check.dart' as _i25uuckt;
import 'ontology/models/ingest_job.dart' as _iay1heal;
import 'ontology/models/ingest_status.dart' as _imojj26x;
import 'ontology/models/market.dart' as _iyzzhewo;
import 'ontology/models/overview.dart' as _iz31wbgv;
import 'ontology/models/source.dart' as _icm1zoh2;
import 'ontology/models/source_kind.dart' as _itk5lja3;
export 'greetings/greeting.dart';
export 'ontology/models/api_call_usage.dart';
export 'ontology/models/api_provider.dart';
export 'ontology/models/company.dart';
export 'ontology/models/company_change.dart';
export 'ontology/models/company_detail.dart';
export 'ontology/models/company_list_item.dart';
export 'ontology/models/company_page.dart';
export 'ontology/models/company_sort.dart';
export 'ontology/models/dart_corp_status.dart';
export 'ontology/models/dart_filing.dart';
export 'ontology/models/exceptions.dart';
export 'ontology/models/facet_count.dart';
export 'ontology/models/filing_fetch_status.dart';
export 'ontology/models/financial_fact.dart';
export 'ontology/models/financial_report.dart';
export 'ontology/models/financial_report_code.dart';
export 'ontology/models/financial_statement_kind.dart';
export 'ontology/models/fs_div.dart';
export 'ontology/models/industry.dart';
export 'ontology/models/industry_revision_check.dart';
export 'ontology/models/ingest_job.dart';
export 'ontology/models/ingest_status.dart';
export 'ontology/models/market.dart';
export 'ontology/models/overview.dart';
export 'ontology/models/source.dart';
export 'ontology/models/source_kind.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
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

    if (t == _i8298vau.CompanyMasterFutureCallRunModel) {
      return _i8298vau.CompanyMasterFutureCallRunModel.fromJson(data) as T;
    }
    if (t == _ijwdvc26.FinancialFactsFutureCallRunModel) {
      return _ijwdvc26.FinancialFactsFutureCallRunModel.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _i3e42he1.ApiCallUsage) {
      return _i3e42he1.ApiCallUsage.fromJson(data) as T;
    }
    if (t == _i82zif2r.ApiProvider) {
      return _i82zif2r.ApiProvider.fromJson(data) as T;
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
    if (t == _i0csqxj4.CompanyListItem) {
      return _i0csqxj4.CompanyListItem.fromJson(data) as T;
    }
    if (t == _iaj9eyri.CompanyPage) {
      return _iaj9eyri.CompanyPage.fromJson(data) as T;
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
    if (t == _iqc95j34.IngestException) {
      return _iqc95j34.IngestException.fromJson(data) as T;
    }
    if (t == _iqbvehdv.FacetCount) {
      return _iqbvehdv.FacetCount.fromJson(data) as T;
    }
    if (t == _i167q75d.FilingFetchStatus) {
      return _i167q75d.FilingFetchStatus.fromJson(data) as T;
    }
    if (t == _igykxm42.FinancialFact) {
      return _igykxm42.FinancialFact.fromJson(data) as T;
    }
    if (t == _i1qwjg2x.FinancialReport) {
      return _i1qwjg2x.FinancialReport.fromJson(data) as T;
    }
    if (t == _idwohplt.FinancialReportCode) {
      return _idwohplt.FinancialReportCode.fromJson(data) as T;
    }
    if (t == _im4itn08.FinancialStatementKind) {
      return _im4itn08.FinancialStatementKind.fromJson(data) as T;
    }
    if (t == _i906z99z.FsDiv) {
      return _i906z99z.FsDiv.fromJson(data) as T;
    }
    if (t == _i3hzx3f1.Industry) {
      return _i3hzx3f1.Industry.fromJson(data) as T;
    }
    if (t == _i25uuckt.IndustryRevisionCheck) {
      return _i25uuckt.IndustryRevisionCheck.fromJson(data) as T;
    }
    if (t == _iay1heal.IngestJob) {
      return _iay1heal.IngestJob.fromJson(data) as T;
    }
    if (t == _imojj26x.IngestStatus) {
      return _imojj26x.IngestStatus.fromJson(data) as T;
    }
    if (t == _iyzzhewo.Market) {
      return _iyzzhewo.Market.fromJson(data) as T;
    }
    if (t == _iz31wbgv.Overview) {
      return _iz31wbgv.Overview.fromJson(data) as T;
    }
    if (t == _icm1zoh2.Source) {
      return _icm1zoh2.Source.fromJson(data) as T;
    }
    if (t == _itk5lja3.SourceKind) {
      return _itk5lja3.SourceKind.fromJson(data) as T;
    }
    if (t == _is.getType<_i8298vau.CompanyMasterFutureCallRunModel?>()) {
      return (data != null
              ? _i8298vau.CompanyMasterFutureCallRunModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ijwdvc26.FinancialFactsFutureCallRunModel?>()) {
      return (data != null
              ? _ijwdvc26.FinancialFactsFutureCallRunModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3e42he1.ApiCallUsage?>()) {
      return (data != null ? _i3e42he1.ApiCallUsage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i82zif2r.ApiProvider?>()) {
      return (data != null ? _i82zif2r.ApiProvider.fromJson(data) : null) as T;
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
    if (t == _is.getType<_i0csqxj4.CompanyListItem?>()) {
      return (data != null ? _i0csqxj4.CompanyListItem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaj9eyri.CompanyPage?>()) {
      return (data != null ? _iaj9eyri.CompanyPage.fromJson(data) : null) as T;
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
    if (t == _is.getType<_iqc95j34.IngestException?>()) {
      return (data != null ? _iqc95j34.IngestException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iqbvehdv.FacetCount?>()) {
      return (data != null ? _iqbvehdv.FacetCount.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i167q75d.FilingFetchStatus?>()) {
      return (data != null ? _i167q75d.FilingFetchStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igykxm42.FinancialFact?>()) {
      return (data != null ? _igykxm42.FinancialFact.fromJson(data) : null)
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
    if (t == _is.getType<_im4itn08.FinancialStatementKind?>()) {
      return (data != null
              ? _im4itn08.FinancialStatementKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i906z99z.FsDiv?>()) {
      return (data != null ? _i906z99z.FsDiv.fromJson(data) : null) as T;
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
    if (t == _is.getType<_iay1heal.IngestJob?>()) {
      return (data != null ? _iay1heal.IngestJob.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_imojj26x.IngestStatus?>()) {
      return (data != null ? _imojj26x.IngestStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyzzhewo.Market?>()) {
      return (data != null ? _iyzzhewo.Market.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iz31wbgv.Overview?>()) {
      return (data != null ? _iz31wbgv.Overview.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_icm1zoh2.Source?>()) {
      return (data != null ? _icm1zoh2.Source.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itk5lja3.SourceKind?>()) {
      return (data != null ? _itk5lja3.SourceKind.fromJson(data) : null) as T;
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
    if (t == List<_i0csqxj4.CompanyListItem>) {
      return (data as List)
              .map((e) => deserialize<_i0csqxj4.CompanyListItem>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_iqbvehdv.FacetCount>) {
      return (data as List)
              .map((e) => deserialize<_iqbvehdv.FacetCount>(e))
              .toList()
          as T;
    }
    if (t == List<_iee4t190.FacetCount>) {
      return (data as List)
              .map((e) => deserialize<_iee4t190.FacetCount>(e))
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
      _i8298vau.CompanyMasterFutureCallRunModel =>
        'CompanyMasterFutureCallRunModel',
      _ijwdvc26.FinancialFactsFutureCallRunModel =>
        'FinancialFactsFutureCallRunModel',
      _izw8z7ou.Greeting => 'Greeting',
      _i3e42he1.ApiCallUsage => 'ApiCallUsage',
      _i82zif2r.ApiProvider => 'ApiProvider',
      _ipen255x.Company => 'Company',
      _isfozywu.CompanyChange => 'CompanyChange',
      _ire9jjud.CompanyDetail => 'CompanyDetail',
      _i0csqxj4.CompanyListItem => 'CompanyListItem',
      _iaj9eyri.CompanyPage => 'CompanyPage',
      _ia2izjbq.CompanySort => 'CompanySort',
      _ir49pw6i.DartCorpStatus => 'DartCorpStatus',
      _itki3qdq.DartFiling => 'DartFiling',
      _iqc95j34.IngestException => 'IngestException',
      _iqbvehdv.FacetCount => 'FacetCount',
      _i167q75d.FilingFetchStatus => 'FilingFetchStatus',
      _igykxm42.FinancialFact => 'FinancialFact',
      _i1qwjg2x.FinancialReport => 'FinancialReport',
      _idwohplt.FinancialReportCode => 'FinancialReportCode',
      _im4itn08.FinancialStatementKind => 'FinancialStatementKind',
      _i906z99z.FsDiv => 'FsDiv',
      _i3hzx3f1.Industry => 'Industry',
      _i25uuckt.IndustryRevisionCheck => 'IndustryRevisionCheck',
      _iay1heal.IngestJob => 'IngestJob',
      _imojj26x.IngestStatus => 'IngestStatus',
      _iyzzhewo.Market => 'Market',
      _iz31wbgv.Overview => 'Overview',
      _icm1zoh2.Source => 'Source',
      _itk5lja3.SourceKind => 'SourceKind',
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
      case _i8298vau.CompanyMasterFutureCallRunModel():
        return 'CompanyMasterFutureCallRunModel';
      case _ijwdvc26.FinancialFactsFutureCallRunModel():
        return 'FinancialFactsFutureCallRunModel';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _i3e42he1.ApiCallUsage():
        return 'ApiCallUsage';
      case _i82zif2r.ApiProvider():
        return 'ApiProvider';
      case _ipen255x.Company():
        return 'Company';
      case _isfozywu.CompanyChange():
        return 'CompanyChange';
      case _ire9jjud.CompanyDetail():
        return 'CompanyDetail';
      case _i0csqxj4.CompanyListItem():
        return 'CompanyListItem';
      case _iaj9eyri.CompanyPage():
        return 'CompanyPage';
      case _ia2izjbq.CompanySort():
        return 'CompanySort';
      case _ir49pw6i.DartCorpStatus():
        return 'DartCorpStatus';
      case _itki3qdq.DartFiling():
        return 'DartFiling';
      case _iqc95j34.IngestException():
        return 'IngestException';
      case _iqbvehdv.FacetCount():
        return 'FacetCount';
      case _i167q75d.FilingFetchStatus():
        return 'FilingFetchStatus';
      case _igykxm42.FinancialFact():
        return 'FinancialFact';
      case _i1qwjg2x.FinancialReport():
        return 'FinancialReport';
      case _idwohplt.FinancialReportCode():
        return 'FinancialReportCode';
      case _im4itn08.FinancialStatementKind():
        return 'FinancialStatementKind';
      case _i906z99z.FsDiv():
        return 'FsDiv';
      case _i3hzx3f1.Industry():
        return 'Industry';
      case _i25uuckt.IndustryRevisionCheck():
        return 'IndustryRevisionCheck';
      case _iay1heal.IngestJob():
        return 'IngestJob';
      case _imojj26x.IngestStatus():
        return 'IngestStatus';
      case _iyzzhewo.Market():
        return 'Market';
      case _iz31wbgv.Overview():
        return 'Overview';
      case _icm1zoh2.Source():
        return 'Source';
      case _itk5lja3.SourceKind():
        return 'SourceKind';
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
    if (dataClassName == 'CompanyMasterFutureCallRunModel') {
      return deserialize<_i8298vau.CompanyMasterFutureCallRunModel>(
        data['data'],
      );
    }
    if (dataClassName == 'FinancialFactsFutureCallRunModel') {
      return deserialize<_ijwdvc26.FinancialFactsFutureCallRunModel>(
        data['data'],
      );
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'ApiCallUsage') {
      return deserialize<_i3e42he1.ApiCallUsage>(data['data']);
    }
    if (dataClassName == 'ApiProvider') {
      return deserialize<_i82zif2r.ApiProvider>(data['data']);
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
    if (dataClassName == 'CompanyListItem') {
      return deserialize<_i0csqxj4.CompanyListItem>(data['data']);
    }
    if (dataClassName == 'CompanyPage') {
      return deserialize<_iaj9eyri.CompanyPage>(data['data']);
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
    if (dataClassName == 'IngestException') {
      return deserialize<_iqc95j34.IngestException>(data['data']);
    }
    if (dataClassName == 'FacetCount') {
      return deserialize<_iqbvehdv.FacetCount>(data['data']);
    }
    if (dataClassName == 'FilingFetchStatus') {
      return deserialize<_i167q75d.FilingFetchStatus>(data['data']);
    }
    if (dataClassName == 'FinancialFact') {
      return deserialize<_igykxm42.FinancialFact>(data['data']);
    }
    if (dataClassName == 'FinancialReport') {
      return deserialize<_i1qwjg2x.FinancialReport>(data['data']);
    }
    if (dataClassName == 'FinancialReportCode') {
      return deserialize<_idwohplt.FinancialReportCode>(data['data']);
    }
    if (dataClassName == 'FinancialStatementKind') {
      return deserialize<_im4itn08.FinancialStatementKind>(data['data']);
    }
    if (dataClassName == 'FsDiv') {
      return deserialize<_i906z99z.FsDiv>(data['data']);
    }
    if (dataClassName == 'Industry') {
      return deserialize<_i3hzx3f1.Industry>(data['data']);
    }
    if (dataClassName == 'IndustryRevisionCheck') {
      return deserialize<_i25uuckt.IndustryRevisionCheck>(data['data']);
    }
    if (dataClassName == 'IngestJob') {
      return deserialize<_iay1heal.IngestJob>(data['data']);
    }
    if (dataClassName == 'IngestStatus') {
      return deserialize<_imojj26x.IngestStatus>(data['data']);
    }
    if (dataClassName == 'Market') {
      return deserialize<_iyzzhewo.Market>(data['data']);
    }
    if (dataClassName == 'Overview') {
      return deserialize<_iz31wbgv.Overview>(data['data']);
    }
    if (dataClassName == 'Source') {
      return deserialize<_icm1zoh2.Source>(data['data']);
    }
    if (dataClassName == 'SourceKind') {
      return deserialize<_itk5lja3.SourceKind>(data['data']);
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
      case _i3e42he1.ApiCallUsage:
        return _i3e42he1.ApiCallUsage.t;
      case _ipen255x.Company:
        return _ipen255x.Company.t;
      case _isfozywu.CompanyChange:
        return _isfozywu.CompanyChange.t;
      case _ir49pw6i.DartCorpStatus:
        return _ir49pw6i.DartCorpStatus.t;
      case _itki3qdq.DartFiling:
        return _itki3qdq.DartFiling.t;
      case _igykxm42.FinancialFact:
        return _igykxm42.FinancialFact.t;
      case _i1qwjg2x.FinancialReport:
        return _i1qwjg2x.FinancialReport.t;
      case _i3hzx3f1.Industry:
        return _i3hzx3f1.Industry.t;
      case _iay1heal.IngestJob:
        return _iay1heal.IngestJob.t;
      case _icm1zoh2.Source:
        return _icm1zoh2.Source.t;
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
