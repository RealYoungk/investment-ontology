BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "dart_filing_section" (
    "id" bigserial PRIMARY KEY,
    "filingId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "bsnsYear" bigint NOT NULL,
    "section" text NOT NULL,
    "tier" bigint NOT NULL,
    "status" text NOT NULL,
    "attempts" bigint NOT NULL DEFAULT 0,
    "lastError" text,
    "fetchedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "dart_filing_section_filing_idx" ON "dart_filing_section" USING btree ("filingId", "section");
CREATE INDEX "dart_filing_section_queue_idx" ON "dart_filing_section" USING btree ("status", "bsnsYear", "tier");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
    "subjectBasis" text
);

-- Indexes
CREATE INDEX "ontology_relation_subject_company_idx" ON "ontology_relation" USING btree ("subjectCompanyId");
CREATE INDEX "ontology_relation_subject_person_idx" ON "ontology_relation" USING btree ("subjectPersonId");
CREATE INDEX "ontology_relation_object_company_idx" ON "ontology_relation" USING btree ("objectCompanyId");
CREATE INDEX "ontology_relation_fact_idx" ON "ontology_relation" USING btree ("factKind", "factId");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "dart_filing_section"
    ADD CONSTRAINT "dart_filing_section_fk_0"
    FOREIGN KEY("filingId")
    REFERENCES "dart_filing"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "disclosure_row"
    ADD CONSTRAINT "disclosure_row_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "dividend_entry"
    ADD CONSTRAINT "dividend_entry_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "person_link_rejection"
    ADD CONSTRAINT "person_link_rejection_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "treasury_stock_entry"
    ADD CONSTRAINT "treasury_stock_entry_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260919045832078-disclosures', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919045832078-disclosures', "timestamp" = now();

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
