BEGIN;

--
-- ACTION CREATE TABLE
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
    "establishedDate" text,
    "fiscalMonth" bigint,
    "dartModifiedDate" text,
    "profileSourceId" bigint,
    "profileUpdatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "company_corp_code_idx" ON "company" USING btree ("corpCode");
CREATE INDEX "company_stock_code_idx" ON "company" USING btree ("stockCode");
CREATE INDEX "company_market_idx" ON "company" USING btree ("market");
CREATE INDEX "company_section_idx" ON "company" USING btree ("sectionCode", "divisionCode");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "industry" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "name" text NOT NULL,
    "level" bigint NOT NULL,
    "parentCode" text,
    "revision" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "industry_code_idx" ON "industry" USING btree ("code");

--
-- ACTION CREATE TABLE
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
    "message" text
);

-- Indexes
CREATE INDEX "ingest_job_kind_idx" ON "ingest_job" USING btree ("kind", "startedAt");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "company"
    ADD CONSTRAINT "company_fk_0"
    FOREIGN KEY("profileSourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260917085040771-company-master', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260917085040771-company-master', "timestamp" = now();

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
