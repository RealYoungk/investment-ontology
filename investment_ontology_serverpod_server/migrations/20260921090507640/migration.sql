BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "dart_disclosure" (
    "id" bigserial PRIMARY KEY,
    "rceptNo" text NOT NULL,
    "corpCode" text NOT NULL,
    "companyId" bigint,
    "corpName" text NOT NULL,
    "reportName" text NOT NULL,
    "receivedDate" timestamp without time zone NOT NULL,
    "filerName" text,
    "discoveredAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "dart_disclosure_rcept_idx" ON "dart_disclosure" USING btree ("rceptNo");
CREATE INDEX "dart_disclosure_company_idx" ON "dart_disclosure" USING btree ("companyId", "receivedDate");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "dart_disclosure"
    ADD CONSTRAINT "dart_disclosure_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260921090507640', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260921090507640', "timestamp" = now();

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
