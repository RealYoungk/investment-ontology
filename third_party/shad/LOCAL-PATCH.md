# Local compatibility patch

Published shad 0.99.4, commit 8ea5a35bcdd350077cf5217964ede1ec4afd4d61.
All 300 published Dart sources preserved; only lib/src/components/input.dart differs.
The patch adds enabled/focus semantics at the actual editor, initializes an invalid selection before a semantic keyboard request, labels the editor from its visible Text top label (placeholder fallback), and prevents disabled focus.
See SOURCE.json and ../../docs/design-system/shad/input-accessibility.patch.
No external API or component styling changes. This is a patched path dependency, not an unmodified hosted dependency.
Original MIT LICENSE retained. Font notices are in fonts/OFL-*.txt; font binary hashes, embedded copyright/version/OFL metadata and published byte equality are recorded in fonts/PROVENANCE.json.
