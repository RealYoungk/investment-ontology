BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
CREATE INDEX "financial_fact_report_idx" ON "financial_fact" USING btree ("reportId");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "dart_filing"
    ADD CONSTRAINT "dart_filing_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260917145440033-financial-facts', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260917145440033-financial-facts', "timestamp" = now();

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
