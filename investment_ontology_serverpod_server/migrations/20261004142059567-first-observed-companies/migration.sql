BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "security" DROP CONSTRAINT IF EXISTS "security_fk_1";
ALTER TABLE "security" ADD COLUMN "firstObservedDate" timestamp without time zone;
ALTER TABLE "security" ADD COLUMN "firstObservedSourceId" bigint;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "security"
    ADD CONSTRAINT "security_fk_2"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "security"
    ADD CONSTRAINT "security_fk_1"
    FOREIGN KEY("firstObservedSourceId")
    REFERENCES "source"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261004142059567-first-observed-companies', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004142059567-first-observed-companies', "timestamp" = now();

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
