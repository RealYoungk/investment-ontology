BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "business_profile" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "ruleVersion" bigint NOT NULL,
    "products" json NOT NULL,
    "computedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "business_profile_document_idx" ON "business_profile" USING btree ("documentId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "business_profile"
    ADD CONSTRAINT "business_profile_fk_0"
    FOREIGN KEY("documentId")
    REFERENCES "business_document"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260929125016331-business_profiles', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260929125016331-business_profiles', "timestamp" = now();

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
