BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "business_document"
    ADD CONSTRAINT "business_document_fk_0"
    FOREIGN KEY("reportId")
    REFERENCES "disclosure_report"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260919063539057-business-document', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919063539057-business-document', "timestamp" = now();

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
