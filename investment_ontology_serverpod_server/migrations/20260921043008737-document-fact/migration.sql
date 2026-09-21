BEGIN;

--
-- ACTION CREATE TABLE
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
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "document_fact_company_idx" ON "document_fact" USING btree ("companyId", "kind");
CREATE INDEX "document_fact_document_idx" ON "document_fact" USING btree ("documentId");

--
-- ACTION CREATE FOREIGN KEY
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
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260921043008737-document-fact', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260921043008737-document-fact', "timestamp" = now();

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
