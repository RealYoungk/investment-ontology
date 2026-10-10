BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "industry_catalog_snapshot" (
    "id" bigserial PRIMARY KEY,
    "snapshotKey" text NOT NULL,
    "sourceFingerprint" text NOT NULL,
    "builderVersion" bigint NOT NULL,
    "catalog" json NOT NULL,
    "pilot" json NOT NULL,
    "computedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "industry_catalog_snapshot_key_idx" ON "industry_catalog_snapshot" USING btree ("snapshotKey");


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261009120546476-stored-industry-classification', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261009120546476-stored-industry-classification', "timestamp" = now();

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
