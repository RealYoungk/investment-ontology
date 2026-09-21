BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "document_fact" ADD COLUMN "reviewedBy" text;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "ontology_relation" ADD COLUMN "reviewedBy" text;
--
-- ACTION CREATE TABLE
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
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260921063837652', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260921063837652', "timestamp" = now();

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
