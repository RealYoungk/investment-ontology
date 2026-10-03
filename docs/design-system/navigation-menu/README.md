# Navigation Menu Flutter adaptation

User authorized this component-only port on 2026-10-03. No vendor shad changes.
Reference: shadcn/ui Base Navigation Menu, commit 295a1f114a138f23b5dfee0e0c6812394dfeb90c. Source snapshot and MIT notice in upstream/. Base UI supplies React interaction primitives; snapshot alone does not contain them.

Current implemented slice: horizontal direct links, current-route selected state, 36px reference height, shad ghost/accent/focus tokens, left/right wrapping (RTL aware), Home/End, Enter activation. AppShell preserves existing route callbacks and auth contracts. Uses independent AppNavigationMenu composition, not ShadTabs. Service basic widgets remain directly from shad.

Optional disclosure scaffold uses ShadPopover; not certified as full Base UI parity. Hover grace regions, focus entry/return, expanded semantics, shared viewport size/directional animation and pointer intent need dedicated implementation and tests before exposing dropdowns in production. Current app uses direct links only; More retains the existing drawer. Flutter does not supply DOM anchor/history semantics: go_router callback navigates, browser modifier-click/open-in-new-tab is not implemented. Full component parity is NOT claimed.

Reference page: https://ui.shadcn.com/docs/components/base/navigation-menu
