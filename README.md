# Scotland ITS Network Performance Analytics Platform

An end-to-end analytics platform over 100,000 Intelligent Transport System detector
observations from Scotland's strategic road network, 2023-2025. Built as a portfolio /
award submission demonstrating the full senior data analyst and business analyst stack:
business case, data architecture, tested transformation pipeline, dimensional model,
predictive layer, economic valuation and five executive dashboards.

**Hypothetical stakeholder for this simulated case study:** Transport Scotland - Network Operations and Strategy. This is a demonstration scenario only. Collinalitics has no contract, commission, affiliation or endorsement from Transport Scotland or another public body.

---

## Headline result

> **Synthetic demonstration only.** The costs, collisions and traffic measurements below are model outputs from generated data. They do not describe actual conditions, public-sector liabilities or real investment recommendations. See the demonstration's method and limitations.

The monitored network carries an estimated **GBP 1.35 billion per year** of avoidable
economic cost. Carbon (44%) now exceeds delay (41%) as the largest monetised
externality. **34% of that cost sits in 10 of the 74 monitored sites.** The collision
risk model concentrates **64% of real collisions into the top 5% of site-hours**.

---

## Build status

| | |
|---|---|
| dbt models | 23 (bronze 1, staging 1, intermediate 5, marts 16) |
| Seeds | 5 reference tables |
| Tests | **116 / 116 passing** |
| Fact rows | 96,970 clean + 100,000 data quality + 96,970 scored |
| Conformance | 96.02% |
| Congestion forecast | Macro F1 **0.672** vs 0.206 majority baseline |
| Collision risk | PR-AUC **0.222** vs 0.0036 base rate (**61x**), 13.2x lift at top 5% |

---

## Repository layout

```
its_analytics_platform/
├── README.md                     this file
├── run_pipeline.sh               six-stage end-to-end build
├── docs/
│   ├── 00_BUSINESS_REQUIREMENTS.md    ITS-BRD-001  problem, aims, goals, objectives, KPIs, findings
│   ├── 01_DATA_ARCHITECTURE.md        ITS-ARC-002  medallion design, star schema, DQ framework, governance
│   ├── 02_POWERBI_BUILD_GUIDE.md      ITS-BI-003   model import, relationships, RLS, reconciliation
│   ├── 03_DASHBOARD_SPECIFICATIONS.md ITS-BI-004   five dashboards, visual by visual
│   ├── 1_DATA_DICTIONARY.md           source dataset reference
│   ├── 2_STATISTICAL_SUMMARY.md       source dataset profile
│   ├── 3_DATA_QUALITY_REPORT.md       ITS-DQ-005   defect catalogue
│   └── 4_ML_USE_CASES.md              twelve modelling briefs
├── dbt/
│   ├── dbt_project.yml           parameterised: thresholds, tolerances, appraisal window
│   ├── profiles.yml              dev / prod targets, path overridable via ITS_DUCKDB_PATH
│   ├── seeds/                    appraisal parameters, road network, DQ rules, time bands
│   ├── models/01_bronze/         immutable landing + source declaration
│   ├── models/02_staging/        conformed, typed, derived
│   ├── models/03_intermediate/   DQ rules, cleansing, weighting, economics
│   ├── models/04_marts/core/     8 dimensions + 2 facts
│   ├── models/04_marts/agg/      4 aggregates
│   ├── models/04_marts/ml/       scoring fact, metric register, site risk ranking
│   ├── macros/                   dependency-free helpers
│   └── tests/                    6 singular business-rule assertions
├── ml/train_score.py             congestion forecast + collision risk, temporal hold-out
├── powerbi/
│   ├── dax_measure_library.dax   101 measures in 11 display folders
│   ├── its_scotland_theme.json   accessible institutional theme
│   └── exports/                  17 mart tables ready for import
└── data/
    ├── scotland_its_dataset.csv  source extract (100,000 rows)
    ├── its_warehouse.duckdb      built warehouse
    └── ml/                       model scores and metric register
```

---

## Quick start

```bash
pip install dbt-core==1.8.9 dbt-duckdb==1.8.4 duckdb scikit-learn pandas
./run_pipeline.sh
```

Then open the warehouse directly:

```sql
-- duckdb data/its_warehouse.duckdb
select city_name,
       round(avg(journey_time_index), 3)          as jti,
       round(sum(annualised_cost_gbp)/1e6, 1)     as annual_cost_gbp_m
from marts.fct_traffic_observation f
join marts.dim_site s using (site_key)
group by 1 order by 3 desc;
```

Or build the dashboards by following `docs/02_POWERBI_BUILD_GUIDE.md`.

---

## Design decisions worth reading

1. **Quarantine, never silently drop.** All 100,000 source rows survive to the marts.
   Data quality is a reportable asset-health signal, not a footnote.
2. **The sample is not the census.** Survey expansion factors are computed per site;
   every monetary measure is published as both observed and annualised.
3. **Parameters are data.** Appraisal values live in a seed with `price_base_year` and
   `source_reference`. The annual TAG refresh is a seed edit, not a code change.
4. **Forecasts exclude realised state.** Both models are denied flow, speed and journey
   time. A model that must observe congestion to predict congestion has no control-room
   value.
5. **Report capture, not accuracy.** At a 0.36% positive rate, accuracy reads 99.6% and
   means nothing. The published headline is the share of collisions captured in the top
   5% of hours.
6. **Test the business rule.** Six singular tests assert that speed falls monotonically
   with congestion, that class counts reconcile and that aggregates match the fact.

## Known limitations

Stated in full in `docs/01_DATA_ARCHITECTURE.md` section 12. In short: the source is
synthetic, observations are independently sampled site-hours (so there is no
autocorrelation at a single detector), there is no network topology, and monitored
segments are not de-duplicated for inventory use. The architecture, logic, validation
design and dashboards transfer unchanged to a live Traffic Scotland feed; the metric
values would not.
