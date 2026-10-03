# Existing market-link source conflicts

The database-only market-security relink worker also checks existing linked securities against their linked listed company. Both nonempty normalized corporate numbers must agree. Missing or zero-only values remain unknown; no alternative issuer or identifier is inferred.

Safe unique unlinked candidates still connect. If existing linked conflicts remain, the same job finishes failed with conflict count and a bounded first20details containing security/company IDs, stockcode, both raw identifiers and both existing SourceIDs. This is a completed validation-job record, not a DB-enforced immutable source audit. Original identifiers, conflicted links, prices, Source records and financial values stay unchanged. No API call or conflict retry is scheduled. Subsequent startup/master changes can revalidate; concurrent requests retain the existing singleton guard.

The worker takes both ingest advisory locks before share-locking company/security reads; safe-link updates retain exact row identity and nullcompany checks. Existing data-page relink status displays failed state and message. No models/generated code/migrations are changed.

This detects uncertainty but does not resolve it: retained conflicting links can still feed company market cap and screen inputs. Whole collection completion must not be claimed while source conflicts remain. Independent source evidence is needed before correcting or quarantining a link. Neither side is presumed erroneous.

Focused regression covers exact ExicureHitron-style conflicting values, linkedrow/company/Source/price-ledger preservation, one safe link plus one conflict, singleton dispatch, API0, no conflict resume, failed replay no-op and success after independently changed evidence simulated only in isolated fixture. Existing relink authorization/cancel/market-lock/orphan tests remain in the focused gate. Validation outputs are held under outputs/filing-collection-priority/completion-status-review-20261003.
