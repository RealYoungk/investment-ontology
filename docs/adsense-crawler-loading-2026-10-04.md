# AdSense crawler loading diagnosis — 2026-10-04

Live AdSense Sites reports `게시자 콘텐츠가 없는 화면에 Google 게재 광고`
(updated 02:16 KST); ads.txt is approved. This does not identify the offending
URL or prove that framework selection caused rejection.

Search Console live tests at 20:40–20:42 KST:
- `/`: market indices and charts render; rendered HTML includes application
  text in Flutter semantics nodes.
- `/company/00126380`: HTTP 200 and technically indexable, but the captured
  image remains on splash. Main JS and external CanvasKit JS/WASM fail to load;
  console reports Failed to fetch. Relative splash image requests expand into
  `/company/brand/brand/...`. One failed test is evidence of render failure,
  not proof of deterministic failure or AdSense's own crawl result.
- That company URL is unknown to Google's existing index. Current sitemap
  lists general routes and articles, not company detail URLs. Discovery is a
  separate remaining issue; search indexing is not an AdSense approval gate.

Changes: root-relative HTML resource references and versioned bootstrap URL;
custom Flutter bootstrap pins entrypoint, assets and CanvasKit to the origin
root. Release uses the official `--no-web-resources-cdn` option and packages
CanvasKit, removing the external CDN dependency. Shared/personal access,
Serverpod, data, live advertising and payment gates are unchanged.

Validation and deployment evidence will be appended after completion. Do not
claim AdSense approval or resubmit based solely on a passing unit test.
