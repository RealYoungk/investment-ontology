BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "billing_payment_attempt" (
    "id" bigserial PRIMARY KEY,
    "subscriptionId" bigint NOT NULL,
    "period" bigint NOT NULL,
    "orderId" text NOT NULL,
    "idempotencyKey" text NOT NULL,
    "status" text NOT NULL,
    "paymentKey" text,
    "paidFromUtc" timestamp without time zone NOT NULL,
    "paidThroughUtc" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "billing_payment_period_idx" ON "billing_payment_attempt" USING btree ("subscriptionId", "period");
CREATE UNIQUE INDEX "billing_payment_order_idx" ON "billing_payment_attempt" USING btree ("orderId");
CREATE UNIQUE INDEX "billing_payment_idempotency_idx" ON "billing_payment_attempt" USING btree ("idempotencyKey");
CREATE UNIQUE INDEX "billing_payment_provider_idx" ON "billing_payment_attempt" USING btree ("paymentKey");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "billing_subscription" (
    "id" bigserial PRIMARY KEY,
    "ownerId" uuid NOT NULL,
    "originUtc" timestamp without time zone NOT NULL,
    "cancelAtPeriodEnd" boolean NOT NULL DEFAULT false,
    "deleted" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "billing_subscription_owner_idx" ON "billing_subscription" USING btree ("ownerId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "billing_payment_attempt"
    ADD CONSTRAINT "billing_payment_attempt_fk_0"
    FOREIGN KEY("subscriptionId")
    REFERENCES "billing_subscription"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261001073641025-membership-ledger', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261001073641025-membership-ledger', "timestamp" = now();

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
