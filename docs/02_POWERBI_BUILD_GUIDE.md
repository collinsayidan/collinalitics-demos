# Power BI Build Guide
## Scotland ITS Network Performance Analytics Platform

| | |
|---|---|
| **Document reference** | ITS-BI-003 |
| **Version** | 1.0 |
| **Companion files** | `powerbi/exports/*.csv` (17 mart tables) · `powerbi/dax_measure_library.dax` (101 measures) · `powerbi/its_scotland_theme.json` |
| **Target** | Power BI Desktop (Sept 2024 or later) → Power BI Service Premium/PPU workspace |

This guide takes you from the exported marts to a certified semantic model and five deployed dashboards. Follow it in order; §12 is the reconciliation checklist that proves the model is correct before anyone sees it.

---

## 1. Prerequisites

- Power BI Desktop, 64-bit
- The `powerbi/exports/` folder, which contains all 17 mart tables exported from the dbt warehouse
- The theme file `its_scotland_theme.json`
- The measure library `dax_measure_library.dax`
- Optional but recommended: [Tabular Editor 2](https://tabulareditor.com) (free) for bulk-loading the measure library, and DAX Studio for performance tracing

> **Production alternative.** For a live deployment, replace the CSV import with a DirectQuery or Import connection to the warehouse (`marts` schema). The table names, relationships and DAX are identical — only the source step changes. CSV import is used here so the model is reproducible without warehouse credentials.

---

## 2. Import the tables

**Home → Get Data → Text/CSV**, or **Get Data → Folder** and expand, selecting these 17 files:

| Table | Rows | Role | Storage |
|---|---:|---|---|
| `fct_traffic_observation` | 96,970 | Core fact | Import |
| `fct_data_quality` | 100,000 | DQ fact | Import |
| `fct_risk_score` | 96,970 | ML fact | Import |
| `dim_date` | 1,096 | Dimension | Import |
| `dim_time` | 24 | Dimension | Import |
| `dim_site` | 74 | Dimension | Import |
| `dim_congestion` | 4 | Dimension | Import |
| `dim_incident` | 6 | Dimension | Import |
| `dim_event` | 6 | Dimension | Import |
| `dim_sensor_status` | 3 | Dimension | Import |
| `dim_weather` | 3 | Dimension | Import |
| `dim_model_metric` | 21 | ML reference | Import |
| `agg_network_daily` | 22,838 | Aggregate | Import |
| `agg_site_hour_profile` | 3,551 | Aggregate | Import |
| `agg_corridor_month` | 324 | Aggregate | Import |
| `agg_data_quality_daily` | 59,481 | Aggregate | Import |
| `agg_site_risk_ranking` | 74 | ML aggregate | Import |

**In Power Query, before loading:**

1. Set `Date`/`full_date` columns to **Date** type and `observation_ts` to **Date/Time**.
2. Set `date_key`, `time_key`, `*_key` integer columns to **Whole Number**.
3. Confirm decimal columns use **Decimal Number**, not Fixed Decimal — journey time index needs three decimal places.
4. **Uncheck "Enable load"** on `fct_data_quality` columns you will not use per-record; keep the fact but drop `dq_primary_failure` duplicates if model size becomes an issue.
5. Rename the queries to exactly the table names above — the DAX library depends on them.

---

## 3. Relationships

Build these **13 relationships**. Every one is single-direction, many-to-one, from fact to dimension. Resist the temptation to set bi-directional filtering anywhere; the aggregate tables make it unnecessary and it is the leading cause of ambiguous-path errors.

| From (many) | Column | To (one) | Column | Direction | Active |
|---|---|---|---|---|---|
| `fct_traffic_observation` | `date_key` | `dim_date` | `date_key` | Single | ✅ |
| `fct_traffic_observation` | `time_key` | `dim_time` | `time_key` | Single | ✅ |
| `fct_traffic_observation` | `site_key` | `dim_site` | `site_key` | Single | ✅ |
| `fct_traffic_observation` | `congestion_key` | `dim_congestion` | `congestion_key` | Single | ✅ |
| `fct_traffic_observation` | `incident_key` | `dim_incident` | `incident_key` | Single | ✅ |
| `fct_traffic_observation` | `event_key` | `dim_event` | `event_key` | Single | ✅ |
| `fct_traffic_observation` | `sensor_status_key` | `dim_sensor_status` | `sensor_status_key` | Single | ✅ |
| `fct_traffic_observation` | `weather_key` | `dim_weather` | `weather_key` | Single | ✅ |
| `fct_data_quality` | `date_key` | `dim_date` | `date_key` | Single | ✅ |
| `fct_data_quality` | `site_key` | `dim_site` | `site_key` | Single | ✅ |
| `fct_data_quality` | `sensor_status_key` | `dim_sensor_status` | `sensor_status_key` | Single | ✅ |
| `fct_risk_score` | `observation_id` | `fct_traffic_observation` | `observation_id` | Single (1:1) | ✅ |
| `agg_site_risk_ranking` | `site_key` | `dim_site` | `site_key` | Single | ✅ |

**Aggregate tables** (`agg_network_daily`, `agg_corridor_month`, `agg_site_hour_profile`, `agg_data_quality_daily`) are used as **standalone sources for specific visuals**, not joined into the star. They already carry their descriptive columns. This keeps the model unambiguous. If you have Premium capacity, configure `agg_network_daily` as a formal **user-defined aggregation** over `fct_traffic_observation` on `date_key` + `site_key` instead.

---

## 4. Model configuration

### 4.1 Mark the date table
Select `dim_date` → **Table tools → Mark as date table** → date column `full_date`. Without this, all time-intelligence measures in folder 09 return incorrect results.

### 4.2 Sort-by columns
| Table | Column | Sort by |
|---|---|---|
| `dim_date` | `month_name` | `month_number` |
| `dim_date` | `day_name` | `day_of_week_number` |
| `dim_date` | `month_year_label` | `year_month` |
| `dim_time` | `time_band` | `time_band_order` |
| `dim_congestion` | `congestion_level` | `congestion_key` |
| `dim_weather` | `weather_severity_band` | `weather_key` |
| `dim_incident` | `incident_type` | `severity_rank` |

### 4.3 Data categories
| Table.Column | Category |
|---|---|
| `dim_site[latitude]` | Latitude |
| `dim_site[longitude]` | Longitude |
| `dim_site[city_name]` | City |
| `dim_site[council_area]` | County |
| `dim_congestion[display_colour_hex]` | *(leave uncategorised — used for conditional formatting by field value)* |

### 4.4 Hygiene
- **Hide every `*_key` column** on both facts and dimensions. Users should never see a surrogate key.
- Set **Summarization = Do not summarize** on all key columns, `latitude`, `longitude`, `speed_limit_kmh` and `hour_of_day`.
- Hide raw numeric columns on `fct_traffic_observation` once the measures exist — users should reach data only through measures.
- Apply format strings from the comment under each measure in the DAX file.

### 4.5 Measure table
Create an empty table: **Home → Enter data**, one column, one blank row, name it `_Measures`. Load, then move every measure to it and hide the placeholder column. Organise into the display folders numbered in the DAX file (00 Base → 10 UX and Narrative).

**Fast path with Tabular Editor:** open the model → paste the `.dax` file contents into a new C# script or create measures via the Advanced Scripting window, setting `DisplayFolder` from the folder comment. This takes about two minutes versus roughly an hour by hand.

---

## 5. Apply the theme

**View → Themes → Browse for themes** → `its_scotland_theme.json`.

The palette is built around Transport Scotland's institutional blue `#00539F`, with a fixed semantic set used consistently across all five dashboards:

| Meaning | Hex | Used for |
|---|---|---|
| Good / free flow / conformant | `#2E7D32` | Low congestion, benign weather, Active sensors |
| Caution / medium | `#F9A825` | Medium congestion, adverse weather, Maintenance |
| Warning / high | `#EF6C00` | High congestion |
| Critical / severe | `#C62828` | Severe congestion, Faulty sensors, SLA breach |
| Primary institutional | `#00539F` | Headline values, primary series |

For congestion visuals, set **Data colours → conditional formatting → Field value → `dim_congestion[display_colour_hex]`** so the colour semantics come from the model, not from a designer's choice on each page.

---

## 6. Page setup

- Canvas **1280 × 720**, page view **Fit to page**
- 12-column grid, 16 px gutter, 24 px outer margin
- Header band 64 px: title (left), period label using `[Selected Period Label]` (centre), Transport Scotland logo (right)
- Filter band 48 px directly under the header: Year → Corridor → City → Road → Time band → Day type
- KPI strip: 5 cards at 216 × 96 px
- Footer 32 px: `[Sampling Disclaimer]` and the data-refresh timestamp

---

## 7. Row-level security

**Modelling → Manage roles.**

| Role | Table | DAX filter |
|---|---|---|
| `Operating Unit – North West` | `dim_site` | `[operating_unit] = "North West"` |
| `Operating Unit – North East` | `dim_site` | `[operating_unit] = "North East"` |
| `Operating Unit – South East` | `dim_site` | `[operating_unit] = "South East"` |
| `Operating Unit – South West` | `dim_site` | `[operating_unit] = "South West"` |
| `Transport Scotland – All Network` | *(none)* | *(no filter — full visibility)* |

For dynamic RLS driven by the signed-in user, add a `dim_user_access` table mapping `user_email` → `operating_unit` and filter with:

```dax
dim_site[operating_unit] IN
    CALCULATETABLE (
        VALUES ( dim_user_access[operating_unit] ),
        dim_user_access[user_email] = USERPRINCIPALNAME ()
    )
```

Sites carrying a combined unit (for example `"South West / South East"`) must be split into a bridge table before dynamic RLS will filter them correctly — this is a known follow-up.

Test every role with **Modelling → View as** before publishing.

---

## 8. Performance

At 97k fact rows the model is small, but these practices are what make it scale to a live national feed:

1. **Import mode, star schema, no bi-directional filters.** The VertiPaq engine is optimised for exactly this shape.
2. **Serve trend and profile visuals from the aggregate tables** — `agg_network_daily` for daily trends, `agg_corridor_month` for the executive page, `agg_site_hour_profile` for the 24-hour profile. A monthly executive trend reads 324 rows instead of 96,970.
3. **Avoid `PERCENTILEX.INC` on the full fact in a visual with high cardinality on the axis.** `[JTI P95]` is pre-computed in `agg_site_hour_profile` and `agg_network_daily`; prefer those columns for site-level reliability visuals and reserve the measure for filtered contexts.
4. **Never put `observation_id` on a visual.** It is a 97k-cardinality column; use it for drill-through only.
5. **Disable Auto date/time** (File → Options → Data Load) — `dim_date` already exists and auto tables would add hidden date hierarchies to every date column.
6. **Limit visuals to 12–14 per page.** Each visual is a separate DAX query.
7. Trace with **Performance Analyzer**; target <2 s per visual on first render, <500 ms on cross-filter.

---

## 9. Deployment

| Stage | Action |
|---|---|
| Workspace | Create `ITS Analytics [Dev]`, `[Test]`, `[Prod]`; wire into a Deployment Pipeline |
| Dataset | Publish once; all five reports connect to the **same shared semantic model** via live connection — never republish a copy per report |
| Certification | Request **Certified** endorsement on the Prod dataset (Settings → Endorsement) so it appears as the authoritative source in the tenant |
| Gateway | On-premises data gateway if sourcing from the warehouse directly; not required for the CSV/parquet path |
| Refresh | Scheduled 05:30 daily, after the 04:00 dbt build; set failure notifications to the data engineering group |
| Apps | Publish as a Power BI App with audience-based sections so each stakeholder group lands on its own dashboard |
| Sensitivity | Apply the **OFFICIAL** sensitivity label |

---

## 10. Documentation surfaced to users

Because the dbt models set `persist_docs`, every model and column description flows into the exported metadata. Copy them into the Power BI field descriptions so users see the definition on hover. Add an **Information** page to every report containing:

- The KPI definitions table from ITS-BRD-001 §9
- The `[Sampling Disclaimer]` measure
- Data provenance and the synthetic-source statement
- Refresh time and dbt batch ID
- Named metric owners

---

## 11. Measure library summary

101 measures across 11 folders:

| Folder | Count | Highlights |
|---|---:|---|
| 00 Base | 4 | `Sampling Rate %` — guards against reading a sample as a census |
| 01 Volume | 10 | `Peak To Trough Ratio`, `Weekend Flow Index` |
| 02 Performance | 12 | `Journey Time Index`, **`Harmonic Mean Speed`** |
| 03 Reliability | 4 | `Buffer Index`, `Reliability Rating` |
| 04 Safety | 10 | `Collisions Per 100m Vehicle Km`, `Weather Collision Uplift` |
| 05 Environment | 8 | `Annualised CO2 Megatonnes`, `AQI Exceedance %` |
| 06 Economics | 16 | `Roadworks Attributable Cost`, `Cost Concentration Top 10 Sites %` |
| 07 Data Quality | 10 | `Conformance vs SLA`, `Sites Below SLA` |
| 08 Predictive | 12 | `Priority Hour Capture %`, `Model Lift` |
| 09 Time Intelligence | 9 | `JTI YoY %`, `JTI Rolling 90 Day` |
| 10 UX and Narrative | 6 | `Executive Narrative` — a written summary that updates with the filters |

**Three measures worth reading before you build anything:**

- **`Harmonic Mean Speed`** — space-mean speed must be averaged harmonically. Using `AVERAGE` overstates network speed and is the single most common error in traffic reporting. Both are in the library so the difference can be demonstrated.
- **`Roadworks Attributable Cost`** — a counterfactual, not a filter: cost during roadworks hours minus what those hours would have cost at the no-works baseline rate. This is the difference between "roadworks hours are expensive" (partly because they are scheduled at busy times) and "roadworks cost us this much".
- **`Priority Hour Capture %`** — the only honest headline for a 0.36%-positive-rate model. Accuracy would read 99.6% and mean nothing.

---

## 12. Reconciliation checklist

Run these before the model goes anywhere near a stakeholder. Each expected value comes from the verified dbt build.

| # | Check | Expected |
|---|---|---|
| 1 | `[Observations]` with no filters | **96,970** |
| 2 | `[Records Received]` with no filters | **100,000** |
| 3 | `[Sites Monitored]` | **74** |
| 4 | `[Journey Time Index]` | **1.167** |
| 5 | `[Congested Hours %]` | **8.14%** |
| 6 | `[Conformance Rate %]` | **96.02%** |
| 7 | `[Quarantine Rate %]` | **3.03%** |
| 8 | `[Annualised Economic Cost]` | **£1,348.8m** |
| 9 | `[Carbon Share Of Cost %]` (annualised basis) | **44.4%** |
| 10 | `[Priority Hour Capture %]` | **64.1%** |
| 11 | `[Macro F1 Test]` | **0.672** |
| 12 | Sum of `agg_network_daily[total_vehicles]` = `[Total Vehicles]` | Exact match |
| 13 | Glasgow `[Annualised Economic Cost]` | **£489.3m** |
| 14 | Top site by cost | **M8-EDI-02, £79.0m** |
| 15 | `[Detector Availability %]` | **92.1%** |

If any figure disagrees, the fault is in the model — a wrong relationship direction, a missed filter, or an arithmetic-versus-harmonic mean — not in the data. The warehouse figures are test-enforced.
