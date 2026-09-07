# Data Architecture
## Scotland ITS Network Performance Analytics Platform

| | |
|---|---|
| **Document reference** | ITS-ARC-002 |
| **Version** | 1.0 |
| **Status** | Built and verified |
| **Stack** | dbt-core 1.8.9 · dbt-duckdb 1.8.4 · DuckDB · scikit-learn 1.7 · Power BI |
| **Build result** | 23 models · 5 seeds · 87 dbt tests · **116/116 passing** |

---

## 1. Architectural principles

Seven principles govern every design decision in this platform. Where a trade-off arose, the principle listed first won.

1. **ELT, not ETL.** Land the data unchanged, then transform in the warehouse where the logic is versioned, tested and inspectable. No transformation happens in the BI tool.
2. **Quarantine, never silently drop.** A defective record is evidence about an asset. Every one of the 100,000 source rows survives to the marts — 96,970 as analysis-ready facts, 3,030 as quarantined records that drive the maintenance backlog.
3. **One definition, one place.** Journey Time Index, congestion bands and every unit value are defined once, in the warehouse or the semantic model, never in a visual.
4. **Parameters are data.** Appraisal values, congestion thresholds and DQ tolerances live in seeds and `dbt_project.yml` vars — versioned, source-referenced and changeable without editing SQL.
5. **Test the business rule, not just the schema.** Uniqueness and not-null are table stakes. The suite also asserts that speed falls monotonically with congestion and that aggregates reconcile to the fact.
6. **The sample is not the census.** The feed samples site-hours. Survey expansion factors are computed per site and carried on the fact, so no one can accidentally read a sample total as a network total.
7. **Star schema, no exceptions.** One fact per grain, conformed dimensions, surrogate keys, no snowflaking into the BI layer.

---

## 2. End-to-end architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SOURCE                                                                     │
│  Traffic Scotland roadside detector feed  →  scotland_its_dataset.csv       │
│  100,000 rows · 40 columns · hourly grain · 74 sites · 2023-2025            │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │  read in place (DuckDB external source)
┌───────────────────────────────▼─────────────────────────────────────────────┐
│  🥉 BRONZE — schema: bronze                            IMMUTABLE LANDING     │
│  bronze_its_observations                                      100,000 rows   │
│  • byte-faithful copy, zero business logic                                   │
│  • lineage columns: _dbt_batch_id, _ingested_at, _source_file, _source_system│
└───────────────────────────────┬─────────────────────────────────────────────┘
┌───────────────────────────────▼─────────────────────────────────────────────┐
│  🥈 STAGING — schema: staging                          CONFORM (view)        │
│  stg_its__observations                                        100,000 rows   │
│  • snake_case naming standard, explicit CAST on every column                 │
│  • observation_ts = date + time; site_natural_key = road|lat|lon             │
│  • derived: free_flow_journey_time, delay_minutes_per_vehicle, segment_km    │
│  • still no filtering — the population is intact                             │
└───────────────────────────────┬─────────────────────────────────────────────┘
┌───────────────────────────────▼─────────────────────────────────────────────┐
│  🥈 INTERMEDIATE — schema: intermediate                CLEANSE + ENRICH      │
│                                                                              │
│  int_site_hour_baseline      robust median / MAD control limits per site-hour│
│  int_observations_dq         12 rules applied → disposition per row (100,000)│
│  int_observations_clean      passes all error rules; weather imputed (96,970)│
│  int_site_sample_weight      survey expansion factors per site (74)          │
│  int_observation_economics   delay / carbon / collision valuation (96,970)   │
└───────────────────────────────┬─────────────────────────────────────────────┘
┌───────────────────────────────▼─────────────────────────────────────────────┐
│  🥇 GOLD MARTS — schema: marts                         STAR SCHEMA           │
│                                                                              │
│  CORE      fct_traffic_observation   96,970   fct_data_quality      100,000  │
│  DIM       dim_date 1,096 · dim_time 24 · dim_site 74 · dim_congestion 4     │
│            dim_incident 6 · dim_event 6 · dim_sensor_status 3 · dim_weather 3│
│  AGG       agg_network_daily 22,838 · agg_site_hour_profile 3,551            │
│            agg_data_quality_daily 59,481 · agg_corridor_month 324            │
│  ML        fct_risk_score 96,970 · dim_model_metric 21 · agg_site_risk 74    │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │
        ┌───────────────────────┴────────────────────────┐
        ▼                                                ▼
┌───────────────────────┐                    ┌────────────────────────────┐
│  ML SCORING           │                    │  POWER BI SEMANTIC MODEL   │
│  train_score.py       │───── parquet ─────▶│  certified dataset         │
│  temporal hold-out    │                    │  5 dashboards · RLS by     │
│  CV in-sample scores  │                    │  operating unit            │
└───────────────────────┘                    └────────────────────────────┘
```

### Why medallion and not a single transformation step

Each boundary exists to answer a different question when something goes wrong:

| Boundary | Question it answers |
|---|---|
| Source → Bronze | *Did we receive what we expected?* |
| Bronze → Staging | *Did we interpret it correctly?* |
| Staging → Intermediate | *Is it fit to analyse, and if not, why not?* |
| Intermediate → Marts | *Is it shaped for the question being asked?* |

Collapsing these layers saves a few minutes of build time and costs hours of debugging on every incident.

---

## 3. The star schema

```
                            ┌──────────────┐
                            │   dim_date   │
                            │  1,096 rows  │
                            └──────┬───────┘
                                   │ date_key
      ┌──────────────┐             │             ┌────────────────┐
      │   dim_time   │─time_key────┤             │  dim_congestion│
      │    24 rows   │             │             │     4 rows     │
      └──────────────┘             │             └───────┬────────┘
                                   │                     │ congestion_key
      ┌──────────────┐      ┌──────▼──────────────────────▼──────┐
      │   dim_site   │──────▶      fct_traffic_observation       │
      │    74 rows   │site_ │            96,970 rows             │
      └──────────────┘key   │  GRAIN: one detector site-hour     │
                            └──┬────────┬───────────┬────────────┘
                               │        │           │
                 incident_key  │  event_key    weather_key / sensor_status_key
                               │        │           │
                      ┌────────▼──┐ ┌───▼─────┐ ┌───▼──────────┐
                      │dim_incident│ │dim_event│ │ dim_weather  │
                      │   6 rows   │ │ 6 rows  │ │  3 rows      │
                      └────────────┘ └─────────┘ └──────────────┘
                                                 ┌────────────────┐
                                                 │dim_sensor_status│
                                                 │     3 rows      │
                                                 └────────────────┘

  Additional facts sharing the same conformed dimensions:
  • fct_data_quality  (100,000) — full population, incl. quarantined
  • fct_risk_score     (96,970) — 1:1 with fct_traffic_observation
```

**Grain statements** — the single most important line in any dimensional design:

| Table | Grain |
|---|---|
| `fct_traffic_observation` | One **clean** detector observation: one site, one hour |
| `fct_data_quality` | One **source** record, whatever its disposition |
| `fct_risk_score` | One clean observation, one model version |
| `agg_network_daily` | Date × city × road |
| `agg_site_hour_profile` | Site × hour of day × day type |
| `agg_corridor_month` | Corridor × month |
| `agg_data_quality_daily` | Date × site |

### Dimension design notes

- **`dim_date`** is a proper date spine generated over the declared reporting window (not derived by `DISTINCT` from the fact, which would silently hide gap days). Carries UK fiscal year (April–March), meteorological season and the school-holiday attribute.
- **`dim_site`** is the platform's most valuable dimension: it joins the physical detector to the strategic road reference data (corridor, strategic function, operating unit, Anglo-Scottish flag) and derives an urbanisation band from the haversine distance to the city centroid. This is what lets a road-safety question and an asset-management question share one filter.
- **Junk-style dimensions** (`dim_congestion`, `dim_weather`, `dim_sensor_status`) carry presentation colours and the operational response expected at each level, so that colour semantics live in the model rather than being re-picked in every visual.
- **Degenerate dimension**: `observation_id` remains on the fact for drill-through to source.
- **Slowly changing dimensions**: not required in this release — site attributes are static across the window. `dim_site` is SCD Type 1 shaped and would extend to Type 2 with `valid_from` / `valid_to` / `is_current` if speed limits or lane counts began to change.

---

## 4. Cleaning and data quality framework

### 4.1 The twelve rules

Held as data in `seeds/ref_dq_rules.csv` and implemented in `int_observations_dq.sql`. Every rule has an explicit **disposition** — the pipeline never has to guess what to do with a failure.

| Rule | Dimension | Severity | Disposition | Hit rate |
|---|---|---|---|---|
| DQ01 Missing traffic measure | Completeness | Error | Quarantine | 0.25% |
| DQ02 Missing environmental measure | Completeness | Warning | **Impute** | 0.69% |
| DQ03 Implausible speed | Validity | Error | Quarantine | 0.61% |
| DQ04 Negative vehicle count | Validity | Error | Quarantine | 0.16% |
| DQ05 Class counts do not reconcile | Consistency | Error | Quarantine | (within DQ04) |
| DQ06 Dead-zero sensor | Accuracy | Error | Quarantine | 0.38% |
| DQ07 Implausible flow spike | Accuracy | Warning | **Flag and retain** | 0.26% |
| DQ08 Duplicate site-hour reading | Uniqueness | Error | **Deduplicate** | 1.64% |
| DQ09 Record identifier unique | Uniqueness | Error | Fail pipeline | 0.00% |
| DQ10 Outside reporting window | Timeliness | Error | Fail pipeline | 0.00% |
| DQ11 Site attributes stable | Integrity | Error | Fail pipeline | 0.00% |
| DQ12 Collision implies accident flag | Integrity | Error | Fail pipeline | 0.00% |

**Outcome: 96.02% fully conformant, 3.03% quarantined, 0.95% accepted with a warning.**

### 4.2 Three design decisions worth defending

**Robust statistics for outlier detection.** The spike rule uses the site-hour **median and median absolute deviation**, not mean and standard deviation. The input deliberately contains extreme outliers; a mean-based control limit is dragged toward the very values it is meant to catch. The robust upper limit is `median + 6 × 1.4826 × MAD`.

**Deduplication is a rule, not an accident.** Duplicate site-hour readings are resolved deterministically: prefer `Active` sensor status, then a non-null flow, then lowest `record_id`. The surplus copy is quarantined and counted, so double-reporting is visible as an asset issue rather than quietly averaged away.

**Imputation is bounded and declared.** Only warning-severity environmental gaps are imputed, from the city × month × hour median, and every imputed row is stamped `is_environment_imputed = 1`. Traffic measures are **never** imputed: missingness is concentrated in Faulty detectors (24.9% quarantine rate vs 1.8% for Active), so imputing flow would inject bias exactly where the signal is weakest.

### 4.3 Missingness is informative

| Sensor status | Records | Quarantine rate |
|---|---|---|
| Active | 92,132 | **1.81%** |
| Maintenance | 4,396 | **11.42%** |
| Faulty | 3,472 | **24.91%** |

Missingness is Missing At Random conditional on detector status. This is not a caveat — it is the maintenance signal that drives Dashboard 5.

---

## 5. Statistical weighting: turning a sample into a network figure

The feed observes 100,000 of a possible 74 × 26,304 = 1,946,496 site-hours — a **4.98% sample**. Reporting `SUM(delay_cost)` over the sample would understate network cost by roughly 20×; reporting it without saying so would be worse.

`int_site_sample_weight` computes, per site:

```
expansion_factor     = period_hours / clean_observations_at_site
annualisation_factor = expansion_factor / period_years
```

Both factors are carried on `fct_traffic_observation`, and every monetary measure is published in two forms:

- **Observed** — what the sampled hours actually cost (`£95.6m` delay across the window)
- **Annualised** — the grossed-up network estimate (`£550.3m` delay per year)

Dashboards label these explicitly and never mix them in a single visual.

---

## 6. Economic valuation layer

`int_observation_economics` monetises each observation using parameters from `ref_appraisal_parameters` — a seed with `parameter_value`, `unit`, `price_base_year` and `source_reference` on every row.

| Component | Method |
|---|---|
| **Delay** | `(delay_minutes / 60) × Σ(class_count × class_value_of_time)`. Class-specific values from the DfT TAG Databook: car £16.00, van £24.00, HGV £35.00, bus £150.00, motorcycle £14.00 per vehicle-hour. |
| **Carbon** | `CO₂ tonnes × £273/tCO₂e` — DESNZ central non-traded value, 2025, 2022 prices. Low/high sensitivities (±50%) also held as parameters. |
| **Collisions** | `accident_flag × £82,000` — derived from DfT RAS4001 average value of prevention (fatal £2,411,659, serious £271,003, slight £20,892) at the GB trunk-road severity mix and 1.30 casualties per collision. |
| **Breakdown** | `£1,400` per breakdown event — recovery plus residual delay not captured in link journey time. |

Because these are parameters rather than literals, the annual TAG refresh is a one-line seed edit and a `dbt seed` — not a code change, and not a hunt through report definitions.

---

## 7. Naming and modelling standards

| Object | Convention | Example |
|---|---|---|
| Source | `<system>_raw` | `its_raw` |
| Bronze | `bronze_<entity>` | `bronze_its_observations` |
| Staging | `stg_<source>__<entity>` | `stg_its__observations` |
| Intermediate | `int_<subject>_<verb>` | `int_observations_clean` |
| Dimension | `dim_<noun>` | `dim_site` |
| Fact | `fct_<business_process>` | `fct_traffic_observation` |
| Aggregate | `agg_<grain>` | `agg_corridor_month` |
| Reference seed | `ref_<subject>` | `ref_appraisal_parameters` |
| Surrogate key | `<entity>_key` | `site_key` |
| Natural key | `<entity>_natural_key` | `site_natural_key` |
| Boolean | `is_` / `has_` prefix | `is_peak_hour`, `has_incident` |
| Measure | `<measure>_<unit>` | `delay_cost_gbp`, `co2_tonnes` |
| Lineage | `_` prefix | `_ingested_at` |

Columns are `snake_case`; tables are singular for dimensions and singular-process for facts; every model carries a `description` that flows through to `dbt docs` and to Power BI field descriptions via `persist_docs`.

---

## 8. Testing strategy

87 dbt tests plus 29 seed/source tests — **116 executing, 116 passing**.

**Generic tests (schema-level)**
- `unique` + `not_null` on every primary and surrogate key
- `relationships` on all nine foreign keys from `fct_traffic_observation` — genuine referential integrity, enforced on every run
- `accepted_values` on all twelve categorical domains

**Singular tests (business rules)** — these are what separate a tested pipeline from a type-checked one:

| Test | Assertion |
|---|---|
| `assert_vehicle_counts_reconcile` | `vehicle_count = car + bus + hgv + motorcycle + van` for every fact row |
| `assert_speed_decreases_with_congestion` | Mean speed falls monotonically Low → Medium → High → Severe |
| `assert_no_negative_measures` | No negative physical measure survives to the fact |
| `assert_aggregate_reconciles_to_fact` | `agg_network_daily` reproduces fact counts, volumes and cost to within £0.05 |
| `assert_jti_within_bounds` | Journey Time Index ∈ [1.0, 12.0] |
| `assert_dq_population_complete` | `fct_data_quality` row count equals the staged source count exactly |

**Test severity policy:** integrity and reconciliation tests are `error` and stop the build. Threshold-style checks would be `warn` with a documented tolerance — a pipeline that cries wolf gets ignored.

---

## 9. The predictive layer

Trained by `ml/train_score.py`, reading the marts and writing parquet consumed by three dbt models.

| | Model A — Congestion Forecast | Model B — Collision Risk |
|---|---|---|
| Type | Multi-class, 4 levels | Binary, 0.36% positive rate |
| Algorithm | HistGradientBoosting, balanced class weights | HistGradientBoosting, balanced class weights |
| Features | Calendar, site characteristics, **forecast** weather, planned roadworks and events | Same |
| Deliberately excluded | Realised flow, speed, journey time | Realised congestion outcome |
| Validation | Temporal hold-out: train 2023–24 (64,702), test 2025 (32,268) | Same |
| Headline | **Macro F1 0.672** vs 0.206 majority baseline | **PR-AUC 0.222** vs 0.0036 base rate (**61×**), ROC-AUC 0.832 |
| Operational metric | Severe recall 0.591, High recall 0.588 | **64.1% of collisions in the top 5% of hours (13.2× lift)** |

**The framing decision that matters.** Both models exclude realised traffic state. A model that needs to observe congestion in order to predict congestion is a definition, not a forecast, and is worthless to a control room planning tomorrow's shift. Excluding flow and speed costs accuracy and buys operational relevance.

**Leakage control.** In-sample rows are scored with 3-fold cross-validated predictions, so no published score comes from a model fitted on that row. Out-of-sample rows are scored by the model trained only on prior years.

**Honesty control.** Every evaluation metric — including the baselines the models beat — is written to `dim_model_metric` and surfaced on the dashboard. Users see the validation, not just the answer.

---

## 10. Orchestration and operations

```bash
# 1. reference data
dbt seed

# 2. bronze → staging → intermediate → core marts → aggregates
dbt run --exclude tag:ml

# 3. train and score (reads marts, writes parquet)
python ml/train_score.py

# 4. ML marts
dbt run --select tag:ml

# 5. full assurance sweep
dbt test

# 6. lineage and documentation site
dbt docs generate && dbt docs serve
```

`run_pipeline.sh` wraps all six steps. In production this is a single Airflow/Dagster DAG with the same six task boundaries, so a failure is attributable to a stage rather than to "the pipeline".

| Concern | Position |
|---|---|
| **Refresh cadence** | Nightly full rebuild (~40 s at this volume). Beyond ~50m rows, convert `fct_traffic_observation` to a dbt incremental model keyed on `observation_id` with a lookback window. |
| **Idempotency** | Every model is a full-refresh `table`; reruns are safe and produce identical output. |
| **Environments** | `dev` and `prod` targets in `profiles.yml`; warehouse path overridable via `ITS_DUCKDB_PATH` so CI writes to scratch. |
| **Portability** | Standard SQL with one DuckDB-specific reader (`read_csv_auto` / `read_parquet`). Migrating to Snowflake, BigQuery or Databricks means changing the adapter and the source macro, not the models. |
| **Lineage** | Auto-generated by `dbt docs` from `ref()` and `source()` — never hand-maintained, therefore never stale. |
| **Dependency posture** | No `dbt deps`. All macros are local, so the project builds air-gapped. |

---

## 11. Governance, security and privacy

| Control | Implementation |
|---|---|
| **Data classification** | OFFICIAL. Aggregated network measurements; no personal data, no vehicle identifiers, no ANPR. |
| **GDPR position** | Out of scope — no natural persons are identifiable at any layer. |
| **Row-level security** | Power BI RLS by `operating_unit` on `dim_site`, so each trunk road operating company sees only its own network. Executive and policy roles see all. |
| **Certification** | The Power BI semantic model is the only certified dataset; the raw extract is restricted to the engineering team to prevent competing local models (risk R5). |
| **Ownership** | Data owner: Asset & Data Governance Manager. Pipeline owner: ITS Analytics Programme. Metric owners named per KPI in ITS-BRD-001 §9. |
| **Auditability** | Every fact row carries `_dbt_batch_id` and `_ingested_at`; every published number is reproducible from raw CSV by one command. |
| **Change control** | Metric definition changes require a semantic-model version bump and a note in the dashboard information panel. |
| **Retention** | Bronze retained 7 years for audit; marts rebuilt on demand from bronze. |

---

## 12. Known architectural limitations

Stated so that nobody over-claims from this platform:

1. **No temporal autocorrelation.** Observations are independently sampled site-hours, so there is no lag structure at a single detector. True time-series forecasting requires aggregation to city-hour or city-day grain first.
2. **No network topology.** Links are independent; there is no upstream/downstream propagation, route choice or queue spillback.
3. **Overlapping segments.** Monitored segments are treated independently. Emissions totals are corridor-monitoring figures, not a de-duplicated national inventory.
4. **Static dimensions.** No SCD Type 2 history; site attributes are assumed constant across the window.
5. **Synthetic source.** The collision generating process is a deterministic function of the features supplied to the risk model, so predictive performance is an upper bound. Architecture, logic, validation design and dashboards transfer unchanged to a live feed; the metric values would not.
6. **Batch only.** Hourly batch; no streaming path in this release.
