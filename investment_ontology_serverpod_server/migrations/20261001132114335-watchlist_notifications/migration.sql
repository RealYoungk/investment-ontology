BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "company_update_event" (
    "id" bigserial PRIMARY KEY,
    "corpCode" text NOT NULL,
    "receipt" text NOT NULL,
    "title" text NOT NULL,
    "url" text NOT NULL,
    "publishedAt" timestamp without time zone NOT NULL,
    "discoveredAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "company_update_receipt_idx" ON "company_update_event" USING btree ("receipt");
CREATE INDEX "company_update_company_idx" ON "company_update_event" USING btree ("corpCode", "discoveredAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "watchlist_entry" (
    "id" bigserial PRIMARY KEY,
    "ownerId" uuid NOT NULL,
    "corpCode" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "baselineAt" timestamp without time zone,
    "muted" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "watchlist_owner_company_idx" ON "watchlist_entry" USING btree ("ownerId", "corpCode");
CREATE INDEX "watchlist_company_idx" ON "watchlist_entry" USING btree ("corpCode");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "watchlist_notice" (
    "id" bigserial PRIMARY KEY,
    "ownerId" uuid NOT NULL,
    "eventId" bigint NOT NULL,
    "corpCode" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "readAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "watchlist_notice_owner_event_idx" ON "watchlist_notice" USING btree ("ownerId", "eventId");
CREATE INDEX "watchlist_notice_owner_idx" ON "watchlist_notice" USING btree ("ownerId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "watchlist_scan_state" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL,
    "lastSuccessAt" timestamp without time zone,
    "leaseUntil" timestamp without time zone,
    "status" text NOT NULL DEFAULT 'waiting'::text
);

-- Indexes
CREATE UNIQUE INDEX "watchlist_scan_key_idx" ON "watchlist_scan_state" USING btree ("key");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "web_push_delivery" (
    "id" bigserial PRIMARY KEY,
    "noticeId" bigint NOT NULL,
    "subscriptionId" bigint NOT NULL,
    "status" text NOT NULL DEFAULT 'pending'::text,
    "attempts" bigint NOT NULL DEFAULT 0,
    "nextAttemptAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "web_push_delivery_unique_idx" ON "web_push_delivery" USING btree ("noticeId", "subscriptionId");
CREATE INDEX "web_push_delivery_pending_idx" ON "web_push_delivery" USING btree ("status", "nextAttemptAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "web_push_subscription" (
    "id" bigserial PRIMARY KEY,
    "ownerId" uuid NOT NULL,
    "endpoint" text NOT NULL,
    "p256dh" text NOT NULL,
    "auth" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "web_push_endpoint_idx" ON "web_push_subscription" USING btree ("endpoint");
CREATE INDEX "web_push_owner_idx" ON "web_push_subscription" USING btree ("ownerId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "watchlist_notice"
    ADD CONSTRAINT "watchlist_notice_fk_0"
    FOREIGN KEY("eventId")
    REFERENCES "company_update_event"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "web_push_delivery"
    ADD CONSTRAINT "web_push_delivery_fk_0"
    FOREIGN KEY("noticeId")
    REFERENCES "watchlist_notice"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "web_push_delivery"
    ADD CONSTRAINT "web_push_delivery_fk_1"
    FOREIGN KEY("subscriptionId")
    REFERENCES "web_push_subscription"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261001132114335-watchlist_notifications', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261001132114335-watchlist_notifications', "timestamp" = now();

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
