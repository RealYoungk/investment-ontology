BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "billing_payment_attempt" ADD COLUMN "failedOrderIds" json;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "billing_subscription" ADD COLUMN "priceLocked" boolean NOT NULL DEFAULT false;

-- Preserve established subscription prices and conservatively reconcile old
-- in-flight orders that predate the atomic dispatch marker.
UPDATE "billing_subscription" s SET "priceLocked" = true
WHERE EXISTS (SELECT 1 FROM "billing_payment_attempt" p
 WHERE p."subscriptionId" = s.id AND p.period >= s."cycleStartPeriod"
 AND p.status IN ('paid', 'refundRequested'));
UPDATE "billing_payment_attempt" p SET status = 'unknown'
FROM "billing_subscription" s WHERE p."subscriptionId" = s.id
 AND p.status = 'pending' AND p.provider = 'toss'
 AND s."encryptedBillingKey" IS NOT NULL;

--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261002082440218', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261002082440218', "timestamp" = now();

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
