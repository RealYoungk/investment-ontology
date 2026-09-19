BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "theme" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "theme_name_idx" ON "theme" USING btree ("name");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "theme_member" (
    "id" bigserial PRIMARY KEY,
    "themeId" bigint NOT NULL,
    "companyId" bigint NOT NULL,
    "note" text,
    "sourceId" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "theme_member_idx" ON "theme_member" USING btree ("themeId", "companyId");
CREATE INDEX "theme_member_company_idx" ON "theme_member" USING btree ("companyId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "theme_member"
    ADD CONSTRAINT "theme_member_fk_0"
    FOREIGN KEY("themeId")
    REFERENCES "theme"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "theme_member"
    ADD CONSTRAINT "theme_member_fk_1"
    FOREIGN KEY("companyId")
    REFERENCES "company"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "theme_member"
    ADD CONSTRAINT "theme_member_fk_2"
    FOREIGN KEY("sourceId")
    REFERENCES "source"("id")
    ON DELETE RESTRICT
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260919062249855-themes', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919062249855-themes', "timestamp" = now();

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
