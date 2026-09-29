BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- Class AiExtraction as table ai_extraction
--
CREATE TABLE "ai_extraction" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "model" text NOT NULL,
    "succeeded" boolean NOT NULL,
    "relationCount" bigint NOT NULL,
    "droppedCount" bigint NOT NULL,
    "error" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "ai_extraction_document_idx" ON "ai_extraction" USING btree ("documentId");
CREATE INDEX "ai_extraction_company_idx" ON "ai_extraction" USING btree ("companyId");

--
-- Class ApiCallUsage as table api_call_usage
--
CREATE TABLE "api_call_usage" (
    "id" bigserial PRIMARY KEY,
    "provider" text NOT NULL,
    "day" text NOT NULL,
    "calls" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "api_call_usage_provider_day_idx" ON "api_call_usage" USING btree ("provider", "day");

--
-- Class BusinessDigestSection as table business_digest_section
--
CREATE TABLE "business_digest_section" (
    "id" bigserial PRIMARY KEY,
    "companyId" bigint NOT NULL,
    "documentId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "ord" bigint NOT NULL,
    "kind" text NOT NULL,
    "title" text NOT NULL,
    "summary" text NOT NULL,
    "evidence" text NOT NULL,
    "extractorModel" text NOT NULL,
    "sourceId" bigint,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "business_digest_document_idx" ON "business_digest_section" USING btree ("documentId", "ord");
CREATE INDEX "business_digest_company_idx" ON "business_digest_section" USING btree ("companyId", "bsnsYear");

--
-- Class BusinessDocument as table business_document
--
CREATE TABLE "business_document" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "rceptNo" text NOT NULL,
    "title" text NOT NULL,
    "text" text NOT NULL,
    "charCount" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "business_document_report_idx" ON "business_document" USING btree ("reportId");
CREATE INDEX "business_document_company_idx" ON "business_document" USING btree ("companyId", "bsnsYear");

--
-- Class Company as table company
--
CREATE TABLE "company" (
    "id" bigserial PRIMARY KEY,
    "corpCode" text NOT NULL,
    "name" text NOT NULL,
    "nameEng" text,
    "stockName" text,
    "stockCode" text,
    "market" text,
    "ceoName" text,
    "jurirNo" text,
    "bizrNo" text,
    "address" text,
    "homepageUrl" text,
    "irUrl" text,
    "phone" text,
    "industryCode" text,
    "sectionCode" text,
    "divisionCode" text,
    "establishedDate" timestamp without time zone,
    "fiscalMonth" bigint,
    "dartModifiedDate" timestamp without time zone,
    "profileSourceId" bigint,
    "profileUpdatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "company_corp_code_idx" ON "company" USING btree ("corpCode");
CREATE INDEX "company_stock_code_idx" ON "company" USING btree ("stockCode");
CREATE INDEX "company_market_idx" ON "company" USING btree ("market");
CREATE INDEX "company_section_idx" ON "company" USING btree ("sectionCode", "divisionCode");

--
-- Class CompanyChange as table company_change
--
CREATE TABLE "company_change" (
    "id" bigserial PRIMARY KEY,
    "companyId" bigint NOT NULL,
    "field" text NOT NULL,
    "oldValue" text,
    "newValue" text,
    "sourceId" bigint,
    "changedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "company_change_company_idx" ON "company_change" USING btree ("companyId", "changedAt");

--
-- Class DartCorpStatus as table dart_corp_status
--
CREATE TABLE "dart_corp_status" (
    "id" bigserial PRIMARY KEY,
    "corpCode" text NOT NULL,
    "corpCls" text NOT NULL,
    "modifiedDate" timestamp without time zone,
    "checkedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "dart_corp_status_corp_code_idx" ON "dart_corp_status" USING btree ("corpCode");

--
-- Class DartDisclosure as table dart_disclosure
--
CREATE TABLE "dart_disclosure" (
    "id" bigserial PRIMARY KEY,
    "rceptNo" text NOT NULL,
    "corpCode" text NOT NULL,
    "companyId" bigint,
    "corpName" text NOT NULL,
    "reportName" text NOT NULL,
    "receivedDate" timestamp without time zone NOT NULL,
    "filerName" text,
    "discoveredAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "dart_disclosure_rcept_idx" ON "dart_disclosure" USING btree ("rceptNo");
CREATE INDEX "dart_disclosure_company_idx" ON "dart_disclosure" USING btree ("companyId", "receivedDate");

--
-- Class DartFiling as table dart_filing
--
CREATE TABLE "dart_filing" (
    "id" bigserial PRIMARY KEY,
    "rceptNo" text NOT NULL,
    "corpCode" text NOT NULL,
    "companyId" bigint,
    "reportName" text NOT NULL,
    "receivedDate" timestamp without time zone,
    "bsnsYear" bigint,
    "reportCode" text,
    "consolidatedStatus" text NOT NULL,
    "separateStatus" text NOT NULL,
    "attempts" bigint NOT NULL DEFAULT 0,
    "lastError" text,
    "discoveredAt" timestamp without time zone NOT NULL,
    "checkedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "dart_filing_rcept_no_idx" ON "dart_filing" USING btree ("rceptNo");
CREATE INDEX "dart_filing_company_idx" ON "dart_filing" USING btree ("companyId", "bsnsYear", "reportCode");
CREATE INDEX "dart_filing_received_idx" ON "dart_filing" USING btree ("receivedDate");

--
-- Class DartFilingScan as table dart_filing_scan
--
CREATE TABLE "dart_filing_scan" (
    "id" bigserial PRIMARY KEY,
    "scannedFrom" timestamp without time zone,
    "scannedThrough" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

--
-- Class DartFilingSection as table dart_filing_section
--
CREATE TABLE "dart_filing_section" (
    "id" bigserial PRIMARY KEY,
    "filingId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "yearRank" bigint NOT NULL DEFAULT 0,
    "section" text NOT NULL,
    "tier" bigint NOT NULL,
    "status" text NOT NULL,
    "attempts" bigint NOT NULL DEFAULT 0,
    "lastError" text,
    "fetchedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "dart_filing_section_filing_idx" ON "dart_filing_section" USING btree ("filingId", "section");
CREATE INDEX "dart_filing_section_queue_idx" ON "dart_filing_section" USING btree ("status", "yearRank", "tier");

--
-- Class DisclosureReport as table disclosure_report
--
CREATE TABLE "disclosure_report" (
    "id" bigserial PRIMARY KEY,
    "companyId" bigint NOT NULL,
    "section" text NOT NULL,
    "rceptNo" text NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "reportCode" text NOT NULL,
    "settlementDate" timestamp without time zone,
    "rowCount" bigint NOT NULL,
    "emptyRowCount" bigint NOT NULL DEFAULT 0,
    "sourceId" bigint NOT NULL,
    "supersededById" bigint,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "disclosure_report_rcept_idx" ON "disclosure_report" USING btree ("rceptNo", "section");
CREATE INDEX "disclosure_report_company_idx" ON "disclosure_report" USING btree ("companyId", "section", "bsnsYear");

--
-- Class DisclosureRow as table disclosure_row
--
CREATE TABLE "disclosure_row" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "ord" bigint NOT NULL,
    "isTotal" boolean NOT NULL,
    "rowJson" text NOT NULL
);

-- Indexes
CREATE INDEX "disclosure_row_report_idx" ON "disclosure_row" USING btree ("reportId");

--
-- Class DividendEntry as table dividend_entry
--
CREATE TABLE "dividend_entry" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "ord" bigint NOT NULL,
    "item" text NOT NULL,
    "unit" text,
    "stockKind" text,
    "current" double precision,
    "prior" double precision,
    "beforePrior" double precision
);

-- Indexes
CREATE INDEX "dividend_entry_report_idx" ON "dividend_entry" USING btree ("reportId");
CREATE INDEX "dividend_entry_company_idx" ON "dividend_entry" USING btree ("companyId", "bsnsYear");

--
-- Class DocumentFact as table document_fact
--
CREATE TABLE "document_fact" (
    "id" bigserial PRIMARY KEY,
    "companyId" bigint NOT NULL,
    "documentId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "kind" text NOT NULL,
    "label" text NOT NULL,
    "value" double precision NOT NULL,
    "unit" text NOT NULL,
    "asOf" timestamp without time zone,
    "evidence" text NOT NULL,
    "sourceId" bigint,
    "extractedBy" text NOT NULL,
    "extractorModel" text,
    "confidence" double precision,
    "status" text NOT NULL,
    "reviewedAt" timestamp without time zone,
    "reviewedBy" text,
    "recommendation" text,
    "reviewNote" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "document_fact_company_idx" ON "document_fact" USING btree ("companyId", "kind");
CREATE INDEX "document_fact_document_idx" ON "document_fact" USING btree ("documentId");

--
-- Class ExecutiveEntry as table executive_entry
--
CREATE TABLE "executive_entry" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "ord" bigint NOT NULL,
    "name" text NOT NULL,
    "sex" text,
    "birthYear" bigint,
    "birthMonth" bigint,
    "position" text,
    "registration" text NOT NULL,
    "registrationRaw" text,
    "fullTime" boolean,
    "duties" text,
    "career" text,
    "relationToLargestHolder" text,
    "tenureMonths" bigint,
    "termEndDate" timestamp without time zone,
    "personId" bigint
);

-- Indexes
CREATE INDEX "executive_entry_report_idx" ON "executive_entry" USING btree ("reportId");
CREATE INDEX "executive_entry_company_idx" ON "executive_entry" USING btree ("companyId", "bsnsYear");
CREATE INDEX "executive_entry_person_idx" ON "executive_entry" USING btree ("personId");

--
-- Class FinancialFact as table financial_fact
--
CREATE TABLE "financial_fact" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "reportCode" text NOT NULL,
    "fsDiv" text NOT NULL,
    "statement" text NOT NULL,
    "accountId" text,
    "accountName" text NOT NULL,
    "accountDetail" text,
    "ord" bigint,
    "periodName" text,
    "amount" text,
    "cumulativeAmount" text,
    "priorPeriodName" text,
    "priorAmount" text,
    "priorCumulativeAmount" text,
    "priorQuarterName" text,
    "priorQuarterAmount" text,
    "beforePriorPeriodName" text,
    "beforePriorAmount" text,
    "currency" text,
    "sourceId" bigint NOT NULL,
    "supersededById" bigint
);

-- Indexes
CREATE INDEX "financial_fact_series_idx" ON "financial_fact" USING btree ("companyId", "statement", "accountId", "bsnsYear", "reportCode");
CREATE INDEX "financial_fact_account_idx" ON "financial_fact" USING btree ("accountId", "reportCode", "fsDiv");
CREATE INDEX "financial_fact_report_idx" ON "financial_fact" USING btree ("reportId");

--
-- Class FinancialReport as table financial_report
--
CREATE TABLE "financial_report" (
    "id" bigserial PRIMARY KEY,
    "companyId" bigint NOT NULL,
    "rceptNo" text NOT NULL,
    "fsDiv" text NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "reportCode" text NOT NULL,
    "reportName" text NOT NULL,
    "receivedDate" timestamp without time zone,
    "factCount" bigint NOT NULL,
    "invalidAmountCount" bigint NOT NULL DEFAULT 0,
    "sourceId" bigint NOT NULL,
    "supersededById" bigint,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "financial_report_rcept_no_idx" ON "financial_report" USING btree ("rceptNo", "fsDiv");
CREATE INDEX "financial_report_period_idx" ON "financial_report" USING btree ("companyId", "bsnsYear", "reportCode", "fsDiv");

--
-- Class Industry as table industry
--
CREATE TABLE "industry" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "name" text NOT NULL,
    "level" bigint NOT NULL,
    "parentCode" text,
    "revision" text NOT NULL,
    "sourceId" bigint
);

-- Indexes
CREATE UNIQUE INDEX "industry_revision_code_idx" ON "industry" USING btree ("revision", "code");

--
-- Class IngestJob as table ingest_job
--
CREATE TABLE "ingest_job" (
    "id" bigserial PRIMARY KEY,
    "kind" text NOT NULL,
    "status" text NOT NULL,
    "startedAt" timestamp without time zone NOT NULL,
    "finishedAt" timestamp without time zone,
    "total" bigint NOT NULL DEFAULT 0,
    "processed" bigint NOT NULL DEFAULT 0,
    "updated" bigint NOT NULL DEFAULT 0,
    "failed" bigint NOT NULL DEFAULT 0,
    "apiCalls" bigint NOT NULL DEFAULT 0,
    "fullRefresh" boolean NOT NULL DEFAULT false,
    "message" text
);

-- Indexes
CREATE INDEX "ingest_job_kind_idx" ON "ingest_job" USING btree ("kind", "startedAt");

--
-- Class InvestmentEntry as table investment_entry
--
CREATE TABLE "investment_entry" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "ord" bigint NOT NULL,
    "investeeName" text NOT NULL,
    "purpose" text,
    "firstAcquiredOn" timestamp without time zone,
    "firstAcquiredAmount" text,
    "sharesBegin" text,
    "ratioBegin" double precision,
    "bookValueBegin" text,
    "sharesChange" text,
    "amountChange" text,
    "valuationChange" text,
    "sharesEnd" text,
    "ratioEnd" double precision,
    "bookValueEnd" text,
    "investeeTotalAssets" text,
    "investeeNetIncome" text,
    "isTotal" boolean NOT NULL,
    "investeeCompanyId" bigint,
    "investeeLinkBasis" text
);

-- Indexes
CREATE INDEX "investment_entry_report_idx" ON "investment_entry" USING btree ("reportId");
CREATE INDEX "investment_entry_company_idx" ON "investment_entry" USING btree ("companyId", "bsnsYear");
CREATE INDEX "investment_entry_investee_idx" ON "investment_entry" USING btree ("investeeCompanyId");

--
-- Class MarketIndexDay as table market_index_day
--
CREATE TABLE "market_index_day" (
    "id" bigserial PRIMARY KEY,
    "baseDate" timestamp without time zone NOT NULL,
    "rowCount" bigint NOT NULL,
    "sourceId" bigint,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_index_day_date_idx" ON "market_index_day" USING btree ("baseDate");

--
-- Class MarketIndexSnapshot as table market_index_snapshot
--
CREATE TABLE "market_index_snapshot" (
    "id" bigserial PRIMARY KEY,
    "baseDate" timestamp without time zone NOT NULL,
    "series" text NOT NULL,
    "name" text NOT NULL,
    "close" double precision NOT NULL,
    "change" double precision,
    "changeRate" double precision,
    "open" double precision,
    "high" double precision,
    "low" double precision,
    "volume" text,
    "tradingValue" text,
    "marketCap" text,
    "constituentCount" bigint,
    "sourceId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_index_snapshot_key_idx" ON "market_index_snapshot" USING btree ("baseDate", "series", "name");
CREATE INDEX "market_index_snapshot_name_idx" ON "market_index_snapshot" USING btree ("series", "name", "baseDate");

--
-- Class MarketSnapshot as table market_snapshot
--
CREATE TABLE "market_snapshot" (
    "id" bigserial PRIMARY KEY,
    "securityId" bigint NOT NULL,
    "baseDate" timestamp without time zone NOT NULL,
    "closePrice" text,
    "change" text,
    "openPrice" text,
    "highPrice" text,
    "lowPrice" text,
    "volume" text,
    "tradingValue" text,
    "listedShares" text,
    "marketCap" text,
    "sourceId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_snapshot_security_date_idx" ON "market_snapshot" USING btree ("securityId", "baseDate");
CREATE INDEX "market_snapshot_date_idx" ON "market_snapshot" USING btree ("baseDate");

--
-- Class MarketSnapshotDay as table market_snapshot_day
--
CREATE TABLE "market_snapshot_day" (
    "id" bigserial PRIMARY KEY,
    "baseDate" timestamp without time zone NOT NULL,
    "rowCount" bigint NOT NULL,
    "sourceId" bigint,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_snapshot_day_date_idx" ON "market_snapshot_day" USING btree ("baseDate");

--
-- Class OntologyRelation as table ontology_relation
--
CREATE TABLE "ontology_relation" (
    "id" bigserial PRIMARY KEY,
    "predicate" text NOT NULL,
    "subjectCompanyId" bigint,
    "subjectPersonId" bigint,
    "subjectName" text NOT NULL,
    "objectCompanyId" bigint,
    "objectName" text NOT NULL,
    "asOf" timestamp without time zone,
    "bsnsYear" bigint NOT NULL,
    "weight" double precision,
    "sourceId" bigint,
    "factKind" text NOT NULL,
    "factId" bigint NOT NULL,
    "extractedBy" text NOT NULL,
    "status" text NOT NULL,
    "subjectBasis" text,
    "evidence" text,
    "confidence" double precision,
    "extractorModel" text,
    "reviewedAt" timestamp without time zone,
    "reviewedBy" text,
    "recommendation" text,
    "reviewNote" text
);

-- Indexes
CREATE INDEX "ontology_relation_subject_company_idx" ON "ontology_relation" USING btree ("subjectCompanyId");
CREATE INDEX "ontology_relation_subject_person_idx" ON "ontology_relation" USING btree ("subjectPersonId");
CREATE INDEX "ontology_relation_object_company_idx" ON "ontology_relation" USING btree ("objectCompanyId");
CREATE INDEX "ontology_relation_fact_idx" ON "ontology_relation" USING btree ("factKind", "factId");

--
-- Class Person as table person
--
CREATE TABLE "person" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "birthYear" bigint,
    "birthMonth" bigint,
    "sex" text,
    "personKey" text NOT NULL,
    "estimated" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "person_key_idx" ON "person" USING btree ("personKey");
CREATE INDEX "person_name_idx" ON "person" USING btree ("name");

--
-- Class PersonLinkRejection as table person_link_rejection
--
CREATE TABLE "person_link_rejection" (
    "id" bigserial PRIMARY KEY,
    "companyId" bigint NOT NULL,
    "name" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "person_link_rejection_idx" ON "person_link_rejection" USING btree ("companyId", "name");

--
-- Class ResearchArticle as table research_article
--
CREATE TABLE "research_article" (
    "id" bigserial PRIMARY KEY,
    "slug" text NOT NULL,
    "latestVersion" bigint NOT NULL,
    "publishedVersion" bigint
);

-- Indexes
CREATE UNIQUE INDEX "research_article_slug_idx" ON "research_article" USING btree ("slug");

--
-- Class ResearchBookmark as table research_bookmark
--
CREATE TABLE "research_bookmark" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "articleId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "research_bookmark_user_article_idx" ON "research_bookmark" USING btree ("userId", "articleId");

--
-- Class ResearchRevision as table research_revision
--
CREATE TABLE "research_revision" (
    "id" bigserial PRIMARY KEY,
    "articleId" bigint NOT NULL,
    "version" bigint NOT NULL,
    "title" text NOT NULL,
    "summary" text NOT NULL,
    "ticker" text NOT NULL,
    "market" text NOT NULL,
    "content" text NOT NULL,
    "format" text NOT NULL,
    "searchText" text NOT NULL,
    "dataAsOf" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "note" text NOT NULL,
    "legacy" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "research_revision_version_idx" ON "research_revision" USING btree ("articleId", "version");

--
-- Class ReviewCheck as table review_check
--
CREATE TABLE "review_check" (
    "id" bigserial PRIMARY KEY,
    "scope" text NOT NULL,
    "checked" bigint NOT NULL,
    "correct" bigint NOT NULL,
    "leftToPerson" bigint NOT NULL,
    "checkedBy" text NOT NULL,
    "note" text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "review_check_scope_idx" ON "review_check" USING btree ("scope", "createdAt");

--
-- Class Security as table security
--
CREATE TABLE "security" (
    "id" bigserial PRIMARY KEY,
    "isinCode" text NOT NULL,
    "shortCode" text NOT NULL,
    "name" text NOT NULL,
    "market" text,
    "crno" text,
    "corpName" text,
    "companyId" bigint,
    "linkBasis" text,
    "lastSeenDate" timestamp without time zone NOT NULL,
    "sourceId" bigint
);

-- Indexes
CREATE UNIQUE INDEX "security_isin_idx" ON "security" USING btree ("isinCode");
CREATE INDEX "security_short_code_idx" ON "security" USING btree ("shortCode");
CREATE INDEX "security_company_idx" ON "security" USING btree ("companyId");

--
-- Class ShareholderEntry as table shareholder_entry
--
CREATE TABLE "shareholder_entry" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "ord" bigint NOT NULL,
    "holderName" text NOT NULL,
    "relationText" text,
    "stockKind" text,
    "sharesBegin" text,
    "ratioBegin" double precision,
    "sharesEnd" text,
    "ratioEnd" double precision,
    "remark" text,
    "isTotal" boolean NOT NULL,
    "holderCompanyId" bigint,
    "holderPersonId" bigint,
    "holderLinkBasis" text
);

-- Indexes
CREATE INDEX "shareholder_entry_report_idx" ON "shareholder_entry" USING btree ("reportId");
CREATE INDEX "shareholder_entry_company_idx" ON "shareholder_entry" USING btree ("companyId", "bsnsYear");
CREATE INDEX "shareholder_entry_holder_company_idx" ON "shareholder_entry" USING btree ("holderCompanyId");
CREATE INDEX "shareholder_entry_holder_person_idx" ON "shareholder_entry" USING btree ("holderPersonId");

--
-- Class Source as table source
--
CREATE TABLE "source" (
    "id" bigserial PRIMARY KEY,
    "kind" text NOT NULL,
    "title" text NOT NULL,
    "reference" text,
    "url" text,
    "retrievedAt" timestamp without time zone NOT NULL
);

--
-- Class InvestmentTheme as table theme
--
CREATE TABLE "theme" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "theme_name_idx" ON "theme" USING btree ("name");

--
-- Class ThemeMember as table theme_member
--
CREATE TABLE "theme_member" (
    "id" bigserial PRIMARY KEY,
    "themeId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "note" text,
    "sourceId" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "theme_member_idx" ON "theme_member" USING btree ("themeId", "companyId");
CREATE INDEX "theme_member_company_idx" ON "theme_member" USING btree ("companyId");

--
-- Class TreasuryStockEntry as table treasury_stock_entry
--
CREATE TABLE "treasury_stock_entry" (
    "id" bigserial PRIMARY KEY,
    "reportId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "ord" bigint NOT NULL,
    "method1" text,
    "method2" text,
    "method3" text,
    "stockKind" text,
    "sharesBegin" text,
    "acquired" text,
    "disposed" text,
    "retired" text,
    "sharesEnd" text,
    "remark" text,
    "isTotal" boolean NOT NULL
);

-- Indexes
CREATE INDEX "treasury_stock_entry_report_idx" ON "treasury_stock_entry" USING btree ("reportId");
CREATE INDEX "treasury_stock_entry_company_idx" ON "treasury_stock_entry" USING btree ("companyId", "bsnsYear");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectDownloadEntry as table serverpod_cloud_storage_direct_download
--
CREATE TABLE "serverpod_cloud_storage_direct_download" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "downloadFileName" text,
    "contentType" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_download_auth_key" ON "serverpod_cloud_storage_direct_download" USING btree ("authKey");
CREATE INDEX "serverpod_cloud_storage_direct_download_expiration" ON "serverpod_cloud_storage_direct_download" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL,
    "maxFileSize" bigint NOT NULL DEFAULT 10485760,
    "contentLength" bigint,
    "preventOverwrite" boolean NOT NULL DEFAULT false,
    "contentType" text,
    "cacheControl" text,
    "contentDisposition" text,
    "contentEncoding" text,
    "customMetadata" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text,
    "scheduling" json
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class FutureCallClaimEntry as table serverpod_future_call_claim
--
CREATE TABLE "serverpod_future_call_claim" (
    "id" bigserial PRIMARY KEY,
    "futureCallId" bigint,
    "lastHeartbeatTime" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "future_call_unique_idx" ON "serverpod_future_call_claim" USING btree ("futureCallId");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId", "order");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_message_log_sessionLogId_idx" ON "serverpod_message_log" USING btree ("sessionLogId", "order");

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId", "order");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Class AnonymousAccount as table serverpod_auth_idp_anonymous_account
--
CREATE TABLE "serverpod_auth_idp_anonymous_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- Class AppleAccount as table serverpod_auth_idp_apple_account
--
CREATE TABLE "serverpod_auth_idp_apple_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userIdentifier" text NOT NULL,
    "refreshToken" text NOT NULL,
    "refreshTokenRequestedWithBundleIdentifier" boolean NOT NULL,
    "lastRefreshedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text,
    "isEmailVerified" boolean,
    "isPrivateEmail" boolean,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_apple_account_identifier" ON "serverpod_auth_idp_apple_account" USING btree ("userIdentifier");

--
-- Class EmailAccount as table serverpod_auth_idp_email_account
--
CREATE TABLE "serverpod_auth_idp_email_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_email" ON "serverpod_auth_idp_email_account" USING btree ("email");

--
-- Class EmailAccountPasswordResetRequest as table serverpod_auth_idp_email_account_password_reset_request
--
CREATE TABLE "serverpod_auth_idp_email_account_password_reset_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "emailAccountId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "challengeId" uuid NOT NULL,
    "setPasswordChallengeId" uuid
);

--
-- Class EmailAccountRequest as table serverpod_auth_idp_email_account_request
--
CREATE TABLE "serverpod_auth_idp_email_account_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" text NOT NULL,
    "challengeId" uuid NOT NULL,
    "createAccountChallengeId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_request_email" ON "serverpod_auth_idp_email_account_request" USING btree ("email");

--
-- Class FacebookAccount as table serverpod_auth_idp_facebook_account
--
CREATE TABLE "serverpod_auth_idp_facebook_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "fullName" text,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_facebook_account_user_identifier" ON "serverpod_auth_idp_facebook_account" USING btree ("userIdentifier");

--
-- Class FirebaseAccount as table serverpod_auth_idp_firebase_account
--
CREATE TABLE "serverpod_auth_idp_firebase_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text,
    "phone" text,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_firebase_account_user_identifier" ON "serverpod_auth_idp_firebase_account" USING btree ("userIdentifier");

--
-- Class GitHubAccount as table serverpod_auth_idp_github_account
--
CREATE TABLE "serverpod_auth_idp_github_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_github_account_user_identifier" ON "serverpod_auth_idp_github_account" USING btree ("userIdentifier");

--
-- Class GoogleAccount as table serverpod_auth_idp_google_account
--
CREATE TABLE "serverpod_auth_idp_google_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_google_account_user_identifier" ON "serverpod_auth_idp_google_account" USING btree ("userIdentifier");

--
-- Class MicrosoftAccount as table serverpod_auth_idp_microsoft_account
--
CREATE TABLE "serverpod_auth_idp_microsoft_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_microsoft_account_user_identifier" ON "serverpod_auth_idp_microsoft_account" USING btree ("userIdentifier");

--
-- Class PasskeyAccount as table serverpod_auth_idp_passkey_account
--
CREATE TABLE "serverpod_auth_idp_passkey_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "keyId" bytea NOT NULL,
    "keyIdBase64" text NOT NULL,
    "clientDataJSON" bytea NOT NULL,
    "attestationObject" bytea NOT NULL,
    "originalChallenge" bytea NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_passkey_account_key_id_base64" ON "serverpod_auth_idp_passkey_account" USING btree ("keyIdBase64");

--
-- Class PasskeyChallenge as table serverpod_auth_idp_passkey_challenge
--
CREATE TABLE "serverpod_auth_idp_passkey_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "challenge" bytea NOT NULL
);

--
-- Class RateLimitedRequestAttempt as table serverpod_auth_idp_rate_limited_request_attempt
--
CREATE TABLE "serverpod_auth_idp_rate_limited_request_attempt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "domain" text NOT NULL,
    "source" text NOT NULL,
    "key" text NOT NULL,
    "ipAddress" text,
    "attemptedAt" timestamp without time zone NOT NULL,
    "extraData" json
);

-- Indexes
CREATE INDEX "serverpod_auth_idp_rate_limited_request_attempt_composite" ON "serverpod_auth_idp_rate_limited_request_attempt" USING btree ("domain", "source", "key", "attemptedAt");

--
-- Class SecretChallenge as table serverpod_auth_idp_secret_challenge
--
CREATE TABLE "serverpod_auth_idp_secret_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "challengeCodeHash" text NOT NULL
);

--
-- Class RefreshToken as table serverpod_auth_core_jwt_refresh_token
--
CREATE TABLE "serverpod_auth_core_jwt_refresh_token" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "extraClaims" text,
    "method" text NOT NULL,
    "fixedSecret" bytea NOT NULL,
    "rotatingSecretHash" text NOT NULL,
    "lastUpdatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "serverpod_auth_core_jwt_refresh_token_last_updated_at" ON "serverpod_auth_core_jwt_refresh_token" USING btree ("lastUpdatedAt");

--
-- Class UserProfile as table serverpod_auth_core_profile
--
CREATE TABLE "serverpod_auth_core_profile" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userName" text,
    "fullName" text,
    "email" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "imageId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_profile_user_profile_email_auth_user_id" ON "serverpod_auth_core_profile" USING btree ("authUserId");

--
-- Class UserProfileImage as table serverpod_auth_core_profile_image
--
CREATE TABLE "serverpod_auth_core_profile_image" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userProfileId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "url" text NOT NULL
);

--
-- Class ServerSideSession as table serverpod_auth_core_session
--
CREATE TABLE "serverpod_auth_core_session" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" timestamp without time zone,
    "expireAfterUnusedFor" bigint,
    "sessionKeyHash" bytea NOT NULL,
    "sessionKeySalt" bytea NOT NULL,
    "method" text NOT NULL
);

--
-- Class AuthUser as table serverpod_auth_core_user
--
CREATE TABLE "serverpod_auth_core_user" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "scopeNames" json NOT NULL,
    "blocked" boolean NOT NULL
);

--
-- Foreign relations for "ai_extraction" table
--
ALTER TABLE ONLY "ai_extraction"
    ADD CONSTRAINT "ai_extraction_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "business_document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "business_digest_section" table
--
ALTER TABLE ONLY "business_digest_section"
    ADD CONSTRAINT "business_digest_section_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "business_digest_section"
    ADD CONSTRAINT "business_digest_section_fk_1"
    FOREIGN KEY("documentId")
    REFERENCES "business_document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "business_digest_section"
    ADD CONSTRAINT "business_digest_section_fk_2"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "business_document" table
--
ALTER TABLE ONLY "business_document"
    ADD CONSTRAINT "business_document_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "company" table
--
ALTER TABLE ONLY "company"
    ADD CONSTRAINT "company_fk_0"
    FOREIGN KEY("profileSourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "company_change" table
--
ALTER TABLE ONLY "company_change"
    ADD CONSTRAINT "company_change_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "company_change"
    ADD CONSTRAINT "company_change_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "dart_disclosure" table
--
ALTER TABLE ONLY "dart_disclosure"
    ADD CONSTRAINT "dart_disclosure_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "dart_filing" table
--
ALTER TABLE ONLY "dart_filing"
    ADD CONSTRAINT "dart_filing_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "dart_filing_section" table
--
ALTER TABLE ONLY "dart_filing_section"
    ADD CONSTRAINT "dart_filing_section_fk_0"
    FOREIGN KEY("filingId")
    REFERENCES "dart_filing"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "disclosure_report" table
--
ALTER TABLE ONLY "disclosure_report"
    ADD CONSTRAINT "disclosure_report_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "disclosure_report"
    ADD CONSTRAINT "disclosure_report_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "disclosure_report"
    ADD CONSTRAINT "disclosure_report_fk_2"
    FOREIGN KEY("supersededById")
    REFERENCES "disclosure_report"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "disclosure_row" table
--
ALTER TABLE ONLY "disclosure_row"
    ADD CONSTRAINT "disclosure_row_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "dividend_entry" table
--
ALTER TABLE ONLY "dividend_entry"
    ADD CONSTRAINT "dividend_entry_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "document_fact" table
--
ALTER TABLE ONLY "document_fact"
    ADD CONSTRAINT "document_fact_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "document_fact"
    ADD CONSTRAINT "document_fact_fk_1"
    FOREIGN KEY("documentId")
    REFERENCES "business_document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "document_fact"
    ADD CONSTRAINT "document_fact_fk_2"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "executive_entry" table
--
ALTER TABLE ONLY "executive_entry"
    ADD CONSTRAINT "executive_entry_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "executive_entry"
    ADD CONSTRAINT "executive_entry_fk_1"
    FOREIGN KEY("personId")
    REFERENCES "person"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "financial_fact" table
--
ALTER TABLE ONLY "financial_fact"
    ADD CONSTRAINT "financial_fact_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "financial_report"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "financial_fact"
    ADD CONSTRAINT "financial_fact_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "financial_fact"
    ADD CONSTRAINT "financial_fact_fk_2"
    FOREIGN KEY("supersededById")
    REFERENCES "financial_fact"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "financial_report" table
--
ALTER TABLE ONLY "financial_report"
    ADD CONSTRAINT "financial_report_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "financial_report"
    ADD CONSTRAINT "financial_report_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "financial_report"
    ADD CONSTRAINT "financial_report_fk_2"
    FOREIGN KEY("supersededById")
    REFERENCES "financial_report"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "industry" table
--
ALTER TABLE ONLY "industry"
    ADD CONSTRAINT "industry_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "investment_entry" table
--
ALTER TABLE ONLY "investment_entry"
    ADD CONSTRAINT "investment_entry_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "investment_entry"
    ADD CONSTRAINT "investment_entry_fk_1"
    FOREIGN KEY("investeeCompanyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "market_index_day" table
--
ALTER TABLE ONLY "market_index_day"
    ADD CONSTRAINT "market_index_day_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "market_index_snapshot" table
--
ALTER TABLE ONLY "market_index_snapshot"
    ADD CONSTRAINT "market_index_snapshot_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- Foreign relations for "market_snapshot" table
--
ALTER TABLE ONLY "market_snapshot"
    ADD CONSTRAINT "market_snapshot_fk_0"
    FOREIGN KEY("securityId")
    REFERENCES "security"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "market_snapshot"
    ADD CONSTRAINT "market_snapshot_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- Foreign relations for "market_snapshot_day" table
--
ALTER TABLE ONLY "market_snapshot_day"
    ADD CONSTRAINT "market_snapshot_day_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "ontology_relation" table
--
ALTER TABLE ONLY "ontology_relation"
    ADD CONSTRAINT "ontology_relation_fk_0"
    FOREIGN KEY("subjectCompanyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "ontology_relation"
    ADD CONSTRAINT "ontology_relation_fk_1"
    FOREIGN KEY("subjectPersonId")
    REFERENCES "person"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "ontology_relation"
    ADD CONSTRAINT "ontology_relation_fk_2"
    FOREIGN KEY("objectCompanyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "ontology_relation"
    ADD CONSTRAINT "ontology_relation_fk_3"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "person_link_rejection" table
--
ALTER TABLE ONLY "person_link_rejection"
    ADD CONSTRAINT "person_link_rejection_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "security" table
--
ALTER TABLE ONLY "security"
    ADD CONSTRAINT "security_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "security"
    ADD CONSTRAINT "security_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "shareholder_entry" table
--
ALTER TABLE ONLY "shareholder_entry"
    ADD CONSTRAINT "shareholder_entry_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "shareholder_entry"
    ADD CONSTRAINT "shareholder_entry_fk_1"
    FOREIGN KEY("holderCompanyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "shareholder_entry"
    ADD CONSTRAINT "shareholder_entry_fk_2"
    FOREIGN KEY("holderPersonId")
    REFERENCES "person"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- Foreign relations for "theme_member" table
--
ALTER TABLE ONLY "theme_member"
    ADD CONSTRAINT "theme_member_fk_0"
    FOREIGN KEY("themeId")
    REFERENCES "theme"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "theme_member"
    ADD CONSTRAINT "theme_member_fk_1"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "theme_member"
    ADD CONSTRAINT "theme_member_fk_2"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- Foreign relations for "treasury_stock_entry" table
--
ALTER TABLE ONLY "treasury_stock_entry"
    ADD CONSTRAINT "treasury_stock_entry_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_future_call_claim" table
--
ALTER TABLE ONLY "serverpod_future_call_claim"
    ADD CONSTRAINT "serverpod_future_call_claim_fk_0"
    FOREIGN KEY("futureCallId")
    REFERENCES "serverpod_future_call"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_anonymous_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_anonymous_account"
    ADD CONSTRAINT "serverpod_auth_idp_anonymous_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_apple_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_apple_account"
    ADD CONSTRAINT "serverpod_auth_idp_apple_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_password_reset_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_0"
    FOREIGN KEY("emailAccountId")
    REFERENCES "serverpod_auth_idp_email_account"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_1"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_2"
    FOREIGN KEY("setPasswordChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_0"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_1"
    FOREIGN KEY("createAccountChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_facebook_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_facebook_account"
    ADD CONSTRAINT "serverpod_auth_idp_facebook_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_firebase_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_firebase_account"
    ADD CONSTRAINT "serverpod_auth_idp_firebase_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_github_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_github_account"
    ADD CONSTRAINT "serverpod_auth_idp_github_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_google_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_google_account"
    ADD CONSTRAINT "serverpod_auth_idp_google_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_microsoft_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_microsoft_account"
    ADD CONSTRAINT "serverpod_auth_idp_microsoft_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_passkey_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_passkey_account"
    ADD CONSTRAINT "serverpod_auth_idp_passkey_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_jwt_refresh_token" table
--
ALTER TABLE ONLY "serverpod_auth_core_jwt_refresh_token"
    ADD CONSTRAINT "serverpod_auth_core_jwt_refresh_token_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_profile" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_1"
    FOREIGN KEY("imageId")
    REFERENCES "serverpod_auth_core_profile_image"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_profile_image" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile_image"
    ADD CONSTRAINT "serverpod_auth_core_profile_image_fk_0"
    FOREIGN KEY("userProfileId")
    REFERENCES "serverpod_auth_core_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_session" table
--
ALTER TABLE ONLY "serverpod_auth_core_session"
    ADD CONSTRAINT "serverpod_auth_core_session_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260923060948222', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260923060948222', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260910193913364-string-rate-limit-keys', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260910193913364-string-rate-limit-keys', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260824182354731', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182354731', "timestamp" = now();


COMMIT;
