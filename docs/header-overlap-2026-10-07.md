# Company header follow-up

Follow-up: issuer logo now moves with the title and stays visible at 36px in the compact header. Compact top spacing increased from 8px to 24px; identity region increased to 96px so the numerical row and tabs remain separate. Confirmed on desktop and 390px mobile. All 15 focused tests passed and changed-file analysis was clean.

Preserved the scroll-driven company name, ticker, price and market-cap movement into the compact app bar. The expanded header now uses its natural layout height, with a separate pinned navigation region so metrics and tabs do not overlap. Source text is painted once through anchored overlays. Overlay measurement includes inherited text styles and is refreshed when viewport constraints change; mobile market-cap text scales to its column.

Validation: 15 focused header/frame/tab widget tests passed; the final frame width adjustment passed the five frame tests. Changed frame and company page analysis passed. Browser checks covered expanded, intermediate and collapsed desktop states, plus 390px mobile expanded/collapsed states. Screenshots are in output/company-branding/header-*-fixed.jpg. Local running app updated; no production deployment.
