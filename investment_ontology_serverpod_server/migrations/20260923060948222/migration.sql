BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "research_article" (
    "id" bigserial PRIMARY KEY,
    "slug" text NOT NULL,
    "latestVersion" bigint NOT NULL,
    "publishedVersion" bigint
);

-- Indexes
CREATE UNIQUE INDEX "research_article_slug_idx" ON "research_article" USING btree ("slug");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "research_bookmark" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "articleId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "research_bookmark_user_article_idx" ON "research_bookmark" USING btree ("userId", "articleId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "research_revision" (
    "id" bigserial PRIMARY KEY,
    "articleId" bigint NOT NULL,
    "version" bigint NOT NULL,
    "title" text NOT NULL,
    "summary" text NOT NULL,
    "ticker" text NOT NULL,
    "market" text NOT NULL,
    "content" text NOT NULL,
    "format" text NOT NULL,
    "searchText" text NOT NULL,
    "dataAsOf" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "note" text NOT NULL,
    "legacy" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "research_revision_version_idx" ON "research_revision" USING btree ("articleId", "version");


--
-- MIGRATION VERSION FOR investment_ontology_serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('investment_ontology_serverpod', '20260923060948222', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260923060948222', "timestamp" = now();

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
