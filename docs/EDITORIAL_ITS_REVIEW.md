# Scotland ITS / Editorial 2.0 (draft review)

The site's original logo and synthetic data remain unchanged. All five pages now
load a scoped editorial stylesheet after the original CSS, adopting Collinalitics
navy #0E2240, teal #0B7E7C and seafoam #E8F1F0.

Upgrades: editorial header and footers, stronger hierarchy, clearer KPI cards,
responsive charts, accessible focus indicators and filter labels, explorer reset
and a CSV export of the currently filtered synthetic-data records (with
CSV-formula protection), plus a network filter reset.

## Unresolved data-build discrepancies
Do not assert that the pipeline's reported counts are verified until a
reproducible rebuild reconciles the following values:
- Models: README 23 vs demo methodology 33
- Automated tests: README 116 vs demo methodology 120
- Conformance: README 96.02% vs bundled demo 95.70%
- Clean records: README 96,970 vs demo methodology 96,652

Displayed demo metrics are taken from the bundled demos/scotland-its/data.js.
These remain SIMULATED, not Transport Scotland measurements. No claim of actual
Transport Scotland affiliation is made.

## Preview in Codespaces
Switch to branch design/its-editorial-v2, then from repository root run:

    python3 -m http.server 8000 --directory demos

Open forwarded port 8000 and review:
- /  (example work)
- /scotland-its/index.html
- /scotland-its/executive.html (filters and reset)
- /scotland-its/explore.html (filters, sort, reset and filtered CSV)
- /scotland-its/methodology.html

Check 390px, 768px and desktop. Chart.js is loaded from its CDN, so preview
requires an internet connection. Validate all numbers and disclosures before
merging; the source check in CI is not a substitute for browser QA.

Draft PR only. No deployment, production data or secrets.
