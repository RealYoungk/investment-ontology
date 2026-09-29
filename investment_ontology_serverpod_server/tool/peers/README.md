# Peer coverage audit (read only)

Run from the server package with an authorized local database connection. The export contains public filing-derived company/product evidence, never credentials. Supply the current `PeerRules.version`; do not silently combine versions.

```sh
psql "$DATABASE_URL" -t -A -v rule_version=7 -f tool/peers/export.sql > /tmp/peer-profiles.json
dart run tool/peers/audit.dart /tmp/peer-profiles.json /tmp/peer-audit.json
```

`companiesWithCandidates` uses the production default focus and matching rules. It does not measure accuracy or coverage for every selectable product. Inspect `matches` and product distribution when extending a rule; add positive and negative regression cases. Unknown/ambiguous rows should stay unclassified rather than widen the same-industry fallback. Increment the rule version after changing extraction, then let the existing startup backfill process current documents. No AI or manual peer lists are required.
