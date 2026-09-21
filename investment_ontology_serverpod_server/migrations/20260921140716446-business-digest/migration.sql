BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
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
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260921140716446-business-digest', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260921140716446-business-digest', "timestamp" = now();

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
