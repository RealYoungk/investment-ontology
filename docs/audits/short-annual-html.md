# Source-declared short annual HTML

`fetchAnnual` and `parseStandardAnnual` accept an inclusive reporting interval of 1–367 days only after the unique official annual cover declares exactly that start/end. Annual report classification does not imply twelve months: EMT receipt 20260709000400 explicitly covers 2026-01-01 through 2026-03-31.

Official shell company/receipt/document binding, exact cover company/end, current term, each primary statement's current interval, whole-company basis, printed units/current columns/core rows and balance identity remain mandatory. A single-day interval requires start=end explicitly in cover and current statement dates. Reversed or over-367-day intervals fail. Legacy attachment-specific parser and half-year parser retain their prior bounds.

The fixture is the actual official EMT OFS HTML and cover, fetched read-only. Core amounts remain printed current amounts: no annualization or multiplying by four. Synthetic date mutations separately test date consistency and duration boundaries; they do not assert actual company periods.

This change supports source collection only. Twelve-month TTM/Q4/annual comparison eligibility must be assessed separately; a short annual income statement must not be presented as twelve-month earnings.

The prior upper bound was difference.inDays <=366 (inclusive367). This is preserved for compatibility; this change does not claim an actual367-day source was reviewed.
