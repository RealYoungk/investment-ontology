BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "market_snapshot" (
    "id" bigserial PRIMARY KEY,
    "securityId" bigint NOT NULL,
    "baseDate" timestamp without time zone NOT NULL,
    "closePrice" text,
    "change" text,
    "openPrice" text,
    "highPrice" text,
    "lowPrice" text,
    "volume" text,
    "tradingValue" text,
    "listedShares" text,
    "marketCap" text,
    "sourceId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_snapshot_security_date_idx" ON "market_snapshot" USING btree ("securityId", "baseDate");
CREATE INDEX "market_snapshot_date_idx" ON "market_snapshot" USING btree ("baseDate");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "market_snapshot_day" (
    "id" bigserial PRIMARY KEY,
    "baseDate" timestamp without time zone NOT NULL,
    "rowCount" bigint NOT NULL,
    "sourceId" bigint,
    "fetchedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "market_snapshot_day_date_idx" ON "market_snapshot_day" USING btree ("baseDate");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "security" (
    "id" bigserial PRIMARY KEY,
    "isinCode" text NOT NULL,
    "shortCode" text NOT NULL,
    "name" text NOT NULL,
    "market" text,
    "crno" text,
    "corpName" text,
    "companyId" bigint,
    "lastSeenDate" timestamp without time zone NOT NULL,
    "sourceId" bigint
);

-- Indexes
CREATE UNIQUE INDEX "security_isin_idx" ON "security" USING btree ("isinCode");
CREATE INDEX "security_short_code_idx" ON "security" USING btree ("shortCode");
CREATE INDEX "security_company_idx" ON "security" USING btree ("companyId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "market_snapshot"
    ADD CONSTRAINT "market_snapshot_fk_0"
    FOREIGN KEY("securityId")
    REFERENCES "security"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "market_snapshot"
    ADD CONSTRAINT "market_snapshot_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "market_snapshot_day"
    ADD CONSTRAINT "market_snapshot_day_fk_0"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "security"
    ADD CONSTRAINT "security_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "security"
    ADD CONSTRAINT "security_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260917150331002-market-snapshot', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260917150331002-market-snapshot', "timestamp" = now();

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
