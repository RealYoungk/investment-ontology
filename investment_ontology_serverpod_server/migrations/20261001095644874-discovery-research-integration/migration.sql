BEGIN;

--
-- The research branch may already have installed this identical table locally.
-- Production advanced along the billing branch and still needs it. Preserve data.
DO $integration$
BEGIN
  IF to_regclass('public.research_snapshot') IS NULL THEN
CREATE TABLE "research_snapshot" (
    "id" bigserial PRIMARY KEY,
    "companyId" bigint NOT NULL,
    "kind" text NOT NULL,
    "provider" text NOT NULL,
    "payload" text NOT NULL,
    "sourceId" bigint NOT NULL,
    "digest" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "research_snapshot_company_kind_idx" ON "research_snapshot" USING btree ("companyId", "kind", "createdAt");
CREATE UNIQUE INDEX "research_snapshot_digest_idx" ON "research_snapshot" USING btree ("companyId", "kind", "digest");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "research_snapshot"
    ADD CONSTRAINT "research_snapshot_fk_0"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "research_snapshot"
    ADD CONSTRAINT "research_snapshot_fk_1"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


  END IF;
END
$integration$;

--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20261001095644874-discovery-research-integration', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261001095644874-discovery-research-integration', "timestamp" = now();

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
