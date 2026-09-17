BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "api_call_usage" (
    "id" bigserial PRIMARY KEY,
    "provider" text NOT NULL,
    "day" text NOT NULL,
    "calls" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "api_call_usage_provider_day_idx" ON "api_call_usage" USING btree ("provider", "day");


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260917145246595-api-call-usage', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260917145246595-api-call-usage', "timestamp" = now();

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
