-- Run only against the confirmed Alfinder operating database.
-- No writes, no credentials, no business-row contents.
\set ON_ERROR_STOP on
BEGIN READ ONLY;
SET LOCAL statement_timeout = '30s';

SELECT current_database() AS database_name,
       current_setting('server_version') AS postgres_version,
       pg_database_size(current_database()) AS bytes,
       pg_size_pretty(pg_database_size(current_database())) AS database_size;

SELECT relname AS table_name,
       pg_size_pretty(pg_table_size(relid)) AS table_and_toast_size,
       pg_size_pretty(pg_indexes_size(relid)) AS index_size,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
       n_live_tup AS estimated_rows
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 25;

SELECT count(*) AS filings_total,
       count(*) FILTER (
         WHERE "consolidatedStatus" = 'pending'
            OR "separateStatus" = 'pending'
       ) AS filings_pending
FROM dart_filing;

SELECT tier, status, count(*) AS sections
FROM dart_filing_section
GROUP BY tier, status
ORDER BY tier, status;

SELECT "bsnsYear", count(*) AS reports
FROM financial_report
GROUP BY "bsnsYear"
ORDER BY "bsnsYear";

SELECT "bsnsYear", count(*) AS documents
FROM business_document
GROUP BY "bsnsYear"
ORDER BY "bsnsYear";
ROLLBACK;
