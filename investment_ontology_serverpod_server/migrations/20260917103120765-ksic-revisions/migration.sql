BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "industry_code_idx";
ALTER TABLE "industry" ADD COLUMN "sourceId" bigint;
CREATE UNIQUE INDEX "industry_revision_code_idx" ON "industry" USING btree ("revision", "code");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "ingest_job" ADD COLUMN "fullRefresh" boolean NOT NULL DEFAULT false;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "industry"
    ADD CONSTRAINT "industry_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260917103120765-ksic-revisions', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260917103120765-ksic-revisions', "timestamp" = now();

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
