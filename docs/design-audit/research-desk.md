# Research Desk redesign

## Preservation
- Work branch: codex/research-desk-design.
- Pre-redesign checkpoint: fdbc93b / codex/pre-research-desk. This includes previously uncommitted product work; main was not advanced.
- Local config/development.yaml remains outside design commits.
- Other concurrent screener/backend work appeared during this task and is not part of the design commit.
- Return to baseline only after preserving any later uncommitted work, then `git switch codex/pre-research-desk`. Do not reset the shared worktree. No database changes are required.

## Implemented
- New Research Desk brand, retained Ledger brand for comparison/rollback.
- Desktop charcoal sidebar and utility header; compact popup navigation below 1100px. Detail back remains router-driven.
- Sans-serif headings, semantic typography roles, quiet surfaces, subtle borders, rounded controls and custom dialog/menu theme.
- Shared actions support keyboard Enter/Space and visible focus; icon targets 44px.
- `/design` debug-only Flutter component gallery uses actual components.
- Home exploration flow preserved; reduced oversized headlines and gaps.
- Market mobile counters in one row; daily/week/month/year hierarchy preserved.
- Shareholder-return three charts fit at 920px content width instead of leaving a solitary third chart.
- Ownership-group long explanatory introduction moved to an expansion.
- Chart series use blue/ochre, distinct from red/blue market movement.

## Verification
- Flutter suite: 83 passed after the final mobile market-counter layout adjustment.
- Additional final palette checks cover text, gain/loss and both series at >=4.5 contrast on canvas and surface; keyboard/disabled action test passes.
- Static analysis and formatting performed; design-boundary tests included in suite.
- Browser screenshots inspected at desktop: home, market, company list, screener, graph empty/loaded, ownership group list/detail, theme list/detail, data, company overview/financials/business/governance/returns/disclosures, comparison, about, component gallery.
- Browser interactions checked: navigation to company and group/theme details, scrolling, component dialog open/close, mobile menu open.
- Mobile 390px screenshots inspected for home, data and market; home/about existing tests additionally cover 320/768/1440 and enlarged text.
- Flutter Driver DTD connected but commands timed out. CUA was used for actual visual checks. Development hot reload intermittently timed out with multiple tabs; MCP hot restart succeeded.
- Server recent market/graph/company/screen reads returned success.

## Scope limits
This is a shared design-system migration, not evidence that every control on every route has been exhaustively tested. Person/report/auth flows inherit the common theme; they were not individually navigated in this pass. No AI extraction, data ingestion, auth changes, production deployment or database migration was performed for the redesign.
