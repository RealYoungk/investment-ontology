BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION ALTER TABLE
--
ALTER TABLE "ontology_relation" ADD COLUMN "evidence" text;
ALTER TABLE "ontology_relation" ADD COLUMN "confidence" double precision;
ALTER TABLE "ontology_relation" ADD COLUMN "extractorModel" text;
ALTER TABLE "ontology_relation" ADD COLUMN "reviewedAt" timestamp without time zone;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "ai_extraction"
    ADD CONSTRAINT "ai_extraction_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "business_document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260919064110065-ai-extraction', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919064110065-ai-extraction', "timestamp" = now();

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
