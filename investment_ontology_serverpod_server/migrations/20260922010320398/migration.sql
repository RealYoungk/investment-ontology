BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "market_index_day" (
    "id" bigserial PRIMARY KEY,
    "baseDate" timestamp without time zone NOT NULL,
    "rowCount" bigint NOT NULL,
    "sourceId" bigint,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_index_day_date_idx" ON "market_index_day" USING btree ("baseDate");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "market_index_snapshot" (
    "id" bigserial PRIMARY KEY,
    "baseDate" timestamp without time zone NOT NULL,
    "series" text NOT NULL,
    "name" text NOT NULL,
    "close" double precision NOT NULL,
    "change" double precision,
    "changeRate" double precision,
    "open" double precision,
    "high" double precision,
    "low" double precision,
    "volume" text,
    "tradingValue" text,
    "marketCap" text,
    "constituentCount" bigint,
    "sourceId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_index_snapshot_key_idx" ON "market_index_snapshot" USING btree ("baseDate", "series", "name");
CREATE INDEX "market_index_snapshot_name_idx" ON "market_index_snapshot" USING btree ("series", "name", "baseDate");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "market_index_day"
    ADD CONSTRAINT "market_index_day_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "market_index_snapshot"
    ADD CONSTRAINT "market_index_snapshot_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260922010320398', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260922010320398', "timestamp" = now();

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
