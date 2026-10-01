BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "billing_checkout" (
    "id" bigserial PRIMARY KEY,
    "ownerId" uuid NOT NULL,
    "subscriptionId" bigint NOT NULL,
    "stateHash" text NOT NULL,
    "expiresUtc" timestamp without time zone NOT NULL,
    "status" text NOT NULL,
    "issueIdempotencyKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "billing_checkout_state_idx" ON "billing_checkout" USING btree ("stateHash");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "billing_checkout"
    ADD CONSTRAINT "billing_checkout_fk_0"
    FOREIGN KEY("subscriptionId")
    REFERENCES "billing_subscription"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261001075019232-billing-checkout-state', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261001075019232-billing-checkout-state', "timestamp" = now();

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
