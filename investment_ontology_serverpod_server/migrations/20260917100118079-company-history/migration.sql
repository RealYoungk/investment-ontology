BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "company" DROP COLUMN "establishedDate";
ALTER TABLE "company" DROP COLUMN "dartModifiedDate";
ALTER TABLE "company" ADD COLUMN "establishedDate" timestamp without time zone;
ALTER TABLE "company" ADD COLUMN "dartModifiedDate" timestamp without time zone;
--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
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
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260917100118079-company-history', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260917100118079-company-history', "timestamp" = now();

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
