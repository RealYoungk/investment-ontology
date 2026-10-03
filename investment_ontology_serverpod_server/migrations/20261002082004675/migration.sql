BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "billing_checkout" ADD COLUMN "amountKrw" bigint NOT NULL DEFAULT 2900;
ALTER TABLE "billing_checkout" ADD COLUMN "priceVersion" text NOT NULL DEFAULT 'legacy-2900'::text;
ALTER TABLE "billing_checkout" ADD COLUMN "provider" text NOT NULL DEFAULT 'toss'::text;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "billing_payment_attempt" ADD COLUMN "amountKrw" bigint NOT NULL DEFAULT 2900;
ALTER TABLE "billing_payment_attempt" ADD COLUMN "priceVersion" text NOT NULL DEFAULT 'legacy-2900'::text;
ALTER TABLE "billing_payment_attempt" ADD COLUMN "provider" text NOT NULL DEFAULT 'toss'::text;
ALTER TABLE "billing_payment_attempt" ADD COLUMN "retryCount" bigint NOT NULL DEFAULT 0;
ALTER TABLE "billing_payment_attempt" ADD COLUMN "chargeStartedUtc" timestamp without time zone;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "billing_subscription" ADD COLUMN "priceKrw" bigint NOT NULL DEFAULT 2900;
ALTER TABLE "billing_subscription" ADD COLUMN "priceVersion" text NOT NULL DEFAULT 'legacy-2900'::text;
ALTER TABLE "billing_subscription" ADD COLUMN "provider" text NOT NULL DEFAULT 'toss'::text;
ALTER TABLE "billing_subscription" ADD COLUMN "graceThroughUtc" timestamp without time zone;
ALTER TABLE "billing_subscription" ADD COLUMN "retryAfterUtc" timestamp without time zone;

--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261002082004675', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261002082004675', "timestamp" = now();

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
