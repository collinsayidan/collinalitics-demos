# Dashboard Specifications
## Five Executive Dashboards — Scotland ITS Analytics Platform

| | |
|---|---|
| **Document reference** | ITS-BI-004 |
| **Version** | 1.0 |
| **Canvas** | 1280 × 720 px, 12-column grid, 88 px columns, 16 px gutters, 24 px margins |
| **Semantic model** | One shared certified dataset (ITS-BI-003) |
| **Theme** | `its_scotland_theme.json` |

Every dashboard follows the same anatomy so a user who learns one can read all five:

```
┌────────────────────────────────────────────────────────────┐ y=0
│ HEADER 64px   title · [Selected Period Label] · logo       │
├────────────────────────────────────────────────────────────┤ y=72
│ FILTER BAND 40px   Year · Corridor · City · Road · Band    │
├────────────────────────────────────────────────────────────┤ y=120
│ KPI STRIP 96px   five to six cards, 192×96 each            │
├────────────────────────────────────────────────────────────┤ y=232
│ CONTENT ROW 1  216px                                       │
├────────────────────────────────────────────────────────────┤ y=472
│ CONTENT ROW 2  216px                                       │
├────────────────────────────────────────────────────────────┤ y=688
│ FOOTER 32px   [Sampling Disclaimer] · refresh · batch id   │
└────────────────────────────────────────────────────────────┘ y=720
```

**Column x-positions:** 1:24 · 2:128 · 3:232 · 4:336 · 5:440 · 6:544 · 7:648 · 8:752 · 9:856 · 10:960 · 11:1064 · 12:1168
**Span widths:** 1:88 · 2:192 · 3:296 · 4:400 · 5:504 · 6:608 · 7:712 · 8:816 · 12:1232

**Universal design rules**

1. Every page opens with a headline answer, not a chart. The KPI strip is the answer; the content is the evidence.
2. Colour carries one meaning across all five pages: green good, amber caution, orange warning, red critical. Congestion colours are bound to `dim_congestion[display_colour_hex]` so the model owns the semantics.
3. Every monetary visual states whether it is **observed** or **annualised**. They are never mixed on one visual.
4. Every page carries the sampling disclaimer in the footer.
5. Accessibility: all charts readable without colour (shape, position or label carries the signal too); alt text on every visual; tab order set; minimum 10 pt type.

---

# Dashboard 1 — Executive Network Performance

| | |
|---|---|
| **Audience** | Director of Network Operations, Transport Scotland board, Finance |
| **Frequency** | Monthly board pack; live for ad hoc questions |
| **The one question** | *Is the strategic road network performing, what is it costing us, and where should we spend?* |
| **Primary source** | `agg_corridor_month` and `agg_network_daily` for speed; `fct_traffic_observation` for detail |

### Questions answered
1. What is network journey time reliability, and is it improving or deteriorating?
2. What is the total annual economic cost of under-performance, and how does it split?
3. Which corridors and cities carry the cost?
4. Is traffic growth outpacing our ability to manage it?
5. Where would intervention deliver most value?

### Layout

| # | Visual | Position (x, y, w, h) | Fields / measures | Notes |
|---|---|---|---|---|
| 1.1 | Text box — dynamic title | 24, 8, 816, 48 | `[Dynamic Title Network]` | Large title text class |
| 1.2 | Slicers (5, horizontal) | 24, 72, 1232, 40 | `dim_date[calendar_year]`, `dim_site[corridor]`, `dim_site[city_name]`, `dim_site[road_id]`, `dim_date[day_type]` | Dropdown style, single row |
| 1.3 | KPI card — Journey Time Index | 24, 120, 192, 96 | `[Journey Time Index]`, trend `[JTI Rolling 90 Day]`, target 1.15 | Callout 34 pt; red if > 1.15 |
| 1.4 | KPI card — Annualised Economic Cost | 232, 120, 192, 96 | `[Annualised Economic Cost]`, secondary `[Cost Growth YoY]` | Format `£#,##0,,.0"m"` |
| 1.5 | KPI card — Delay Vehicle Hours | 440, 120, 192, 96 | `[Annualised Delay Vehicle Hours]` | The Transport Scotland congestion measure |
| 1.6 | KPI card — Network CO₂ | 648, 120, 192, 96 | `[Annualised CO2 Megatonnes]` | Net Zero framing |
| 1.7 | KPI card — Collisions | 856, 120, 192, 96 | `[Collisions]`, secondary `[Collisions Per 100m Vehicle Km]` | |
| 1.8 | KPI card — Conformance | 1064, 120, 192, 96 | `[Conformance Rate %]`, `[DQ Status]` | Data trust indicator on the exec page — deliberate |
| 1.9 | **Line and clustered column — performance vs demand** | 24, 232, 816, 216 | Axis `dim_date[month_year_label]`; columns `[Total Vehicles]`; line `[Journey Time Index]` on secondary axis | The core executive story: demand rising, reliability falling. Constant line at 1.15 |
| 1.10 | **Waterfall — cost composition** | 856, 232, 400, 216 | Components `[Annualised Delay Cost]`, `[Annualised Carbon Cost]`, `[Annualised Collision Cost]`, `[Annualised Breakdown Cost]`, total `[Annualised Economic Cost]` | Reveals carbon as the largest component — the counter-intuitive finding |
| 1.11 | **Map — site cost and risk** | 24, 472, 504, 216 | Latitude `dim_site[latitude]`, Longitude `dim_site[longitude]`, Bubble size `[Annualised Economic Cost]`, colour `[Mean Collision Risk]` | Filled bubble map; tooltip = site card |
| 1.12 | **Bar — top 10 sites by annual cost** | 544, 472, 400, 216 | Axis `dim_site[site_code]`, value `[Annualised Economic Cost]`, Top N = 10 | Data labels on; drill-through to Site Detail |
| 1.13 | **Matrix — corridor scorecard** | 960, 472, 296, 216 | Rows `dim_site[corridor]`; values `[Journey Time Index]`, `[Congested Hours %]`, `[Annualised Economic Cost]` | Conditional formatting: JTI data bars, cost colour scale |
| 1.14 | Text box — narrative | 24, 688, 816, 32 | `[Executive Narrative]` | Auto-written summary that responds to filters |
| 1.15 | Text box — disclaimer | 856, 688, 400, 32 | `[Sampling Disclaimer]` | Small label text class |

### Interactions
- 1.11, 1.12 and 1.13 cross-filter 1.9 and 1.10; the KPI strip is set to **no cross-filter** so headline figures stay stable while exploring.
- Drill-through from 1.12 → *Site Detail* page, carrying `dim_site[site_code]`.
- Bookmarks: **Cost view** (default) / **Reliability view** (swaps 1.10 for a JTI distribution histogram).

### What this page is designed to make obvious
- **£1.35bn per year**, of which **44% is carbon** — reframing the network from a congestion problem to a carbon problem.
- **34% of cost sits in 10 of 74 sites** — intervention can be targeted, not universal.
- JTI rising ~1.3% per year while traffic rises ~2.5% — **doing nothing has a price of roughly £23m a year**.

---

# Dashboard 2 — Congestion and Reliability Intelligence

| | |
|---|---|
| **Audience** | Head of Traffic Operations, Traffic Scotland Control Centre, network planners |
| **Frequency** | Weekly operational review; daily during works seasons |
| **The one question** | *Where, when and why does the network fail, and what is within our control?* |
| **Primary source** | `agg_site_hour_profile`, `agg_network_daily`, `fct_traffic_observation` |

### Questions answered
1. What does a typical day look like on each corridor, and how has the peak shape changed?
2. How much delay is attributable to collisions, lane closures, roadworks, events and weather respectively?
3. Which sites are least *reliable*, as distinct from slowest on average?
4. What does the flow–speed relationship tell us about where capacity actually breaks down?
5. What is roadworks scheduling costing us?

### Layout

| # | Visual | Position (x, y, w, h) | Fields / measures | Notes |
|---|---|---|---|---|
| 2.1 | Title + period | 24, 8, 816, 48 | Static + `[Selected Period Label]` | |
| 2.2 | Slicers | 24, 72, 1232, 40 | Corridor, Road, City, `dim_time[time_band]`, `dim_weather[weather_severity_band]` | |
| 2.3 | KPI — Journey Time Index | 24, 120, 192, 96 | `[Journey Time Index]` vs `[JTI LY]` | |
| 2.4 | KPI — Congested Hours % | 232, 120, 192, 96 | `[Congested Hours %]`, target 5% | |
| 2.5 | KPI — Buffer Index | 440, 120, 192, 96 | `[Buffer Index]`, `[Reliability Rating]` | Reliability, not average |
| 2.6 | KPI — Delay Vehicle Hours | 648, 120, 192, 96 | `[Delay Vehicle Hours]` (observed) | |
| 2.7 | KPI — Harmonic Mean Speed | 856, 120, 192, 96 | `[Harmonic Mean Speed]` | |
| 2.8 | KPI — Roadworks Cost | 1064, 120, 192, 96 | `[Roadworks Attributable Cost]` | The controllable number |
| 2.9 | **Line — 24-hour profile by day type** | 24, 232, 608, 216 | Axis `dim_time[hour_label]`; lines `[Average Hourly Flow]` and `[Journey Time Index]` (secondary); small multiples or legend by `dim_date[day_type]` | The bimodal signature; shows PM peak broader and costlier than AM |
| 2.10 | **Scatter — flow vs speed (fundamental diagram)** | 648, 232, 608, 216 | X `[Average Hourly Flow]`, Y `[Average Speed]`, size `[Delay Cost]`, colour `dim_congestion[congestion_level]`, details `dim_site[site_code]` + `dim_time[hour_of_day]` | Reveals the hypercongestion branch — throughput falling while delay rises |
| 2.11 | **Stacked bar — delay attribution** | 24, 472, 504, 216 | Axis: calculated cause group (Collision / Lane closure / Planned event / Roadworks / No disruption); value `[Delay Cost]`; secondary label `[Cost Per Observed Hour]` | Add a `Disruption Cause` calculated column to the fact (see note below) |
| 2.12 | **Heat map matrix — hour × day of week** | 544, 472, 400, 216 | Rows `dim_time[hour_label]`, columns `dim_date[day_short_name]`, values `[Journey Time Index]` | Background colour scale green→red; the classic operations heat map |
| 2.13 | **Table — least reliable sites** | 960, 472, 296, 216 | `dim_site[site_code]`, `[Buffer Index]`, `[JTI P95]`, `[Congested Hours %]`, `[Reliability Rating]` | Sorted by Buffer Index desc; data bars |
| 2.14 | Footer | 24, 688, 1232, 32 | `[Sampling Disclaimer]` | |

**Calculated column required on `fct_traffic_observation`:**

```dax
Disruption Cause =
SWITCH ( TRUE (),
    fct_traffic_observation[accident_flag]     = 1, "1 Collision",
    fct_traffic_observation[lane_closure_flag] = 1, "2 Lane closure",
    fct_traffic_observation[public_event_flag] = 1, "3 Planned event",
    fct_traffic_observation[roadworks_flag]    = 1, "4 Roadworks",
    "5 No disruption"
)
```

### Interactions
- 2.12 cross-filters everything; clicking a cell isolates that hour/day combination across the page.
- Drill-down on 2.9 from day type → month → date.
- Bookmark toggle: **Volume view** / **Reliability view** on 2.9.
- Tooltip page: hovering any site shows a mini profile card (flow, JTI, top incident type, cost).

### What this page is designed to make obvious
- A **collision hour costs £7,820 against £846 for an undisrupted hour — 9.2×**. Clearance time is the highest-leverage operational lever available.
- The **PM peak carries 34.4% of delay cost against the AM peak's 22.3%**; afternoon peak-spreading is worth roughly 1.5× the morning equivalent.
- **Inter-peak now carries 23.2% of delay cost** — the traditional quiet period is gone.
- Roadworks are the largest **controllable** cost. Rescheduling out of peak is a scheduling decision with a price tag attached.

---

# Dashboard 3 — Safety and Incident Intelligence

| | |
|---|---|
| **Audience** | Road Safety Policy Lead, incident response planning, Police Scotland liaison |
| **Frequency** | Monthly safety board; quarterly against the Road Safety Framework to 2030 |
| **The one question** | *Where is collision risk concentrated, what drives it, and where should we position resources tomorrow?* |
| **Primary source** | `fct_traffic_observation`, `fct_risk_score`, `agg_site_risk_ranking`, `dim_model_metric` |

### Questions answered
1. How many collisions and incidents, by type, location and condition?
2. Does weather materially change collision risk, and by how much?
3. What is the exposure-adjusted collision rate by corridor?
4. Which site-hours will carry the highest risk, and how much of the real collision burden do they capture?
5. Can the model be trusted — how was it validated?

### Layout

| # | Visual | Position (x, y, w, h) | Fields / measures | Notes |
|---|---|---|---|---|
| 3.1 | Title + period | 24, 8, 816, 48 | | |
| 3.2 | Slicers | 24, 72, 1232, 40 | Year, Corridor, City, `dim_incident[incident_category]`, `dim_weather[weather_severity_band]` | |
| 3.3 | KPI — Collisions | 24, 120, 192, 96 | `[Collisions]` vs `[Collisions Rolling 12 Month]` | |
| 3.4 | KPI — Collision rate per 100m veh-km | 232, 120, 192, 96 | `[Collisions Per 100m Vehicle Km]` | Exposure-adjusted, internationally comparable |
| 3.5 | KPI — Weather uplift | 440, 120, 192, 96 | `[Weather Collision Uplift]` | Expect ≈ +42.7% |
| 3.6 | KPI — Priority hour capture | 648, 120, 192, 96 | `[Priority Hour Capture %]` | **The model's headline** |
| 3.7 | KPI — Model lift | 856, 120, 192, 96 | `[Model Lift]` | ≈ 13× |
| 3.8 | KPI — Collision cost | 1064, 120, 192, 96 | `[Collision Cost]` annualised | |
| 3.9 | **Column + line — collisions and rate by month** | 24, 232, 608, 216 | Axis `dim_date[month_year_label]`; columns `[Collisions]`; line `[Collisions Per 100m Vehicle Km]` | Seasonality: winter uplift visible |
| 3.10 | **Decomposition tree — collision drivers** | 648, 232, 608, 216 | Analyse `[Collision Rate %]`; explain by weather band → time band → road type → congestion level → roadworks flag | The single best diagnostic visual in Power BI; let the user find the path |
| 3.11 | **Risk map — priority site-hours** | 24, 472, 504, 216 | Map on `dim_site`; size `[Priority Risk Hours]`, colour `[Mean Collision Risk]` | Operational patrol positioning |
| 3.12 | **Gauge + bar — model risk band capture** | 544, 472, 400, 216 | Axis `fct_risk_score[collision_risk_band]`; values `[Scored Hours]` and actual collisions; line showing cumulative capture | Shows Priority band = 4,854 hours holding 64.1% of collisions |
| 3.13 | **Table — model validation register** | 960, 472, 296, 216 | `dim_model_metric[model_name]`, `[metric_name]`, `[data_split]`, `[metric_value]` | Publishing the validation, not just the answer — including the baselines beaten |
| 3.14 | Footer | 24, 688, 1232, 32 | Disclaimer + model version from `fct_risk_score[model_version]` | |

### Interactions
- 3.11 cross-filters 3.12 and 3.13.
- Drill-through to a *Site Safety Detail* page: incident type mix, hourly risk profile, weather conditioning, recent collision list.
- Bookmark: **Observed** (historic collisions) / **Predicted** (risk scores) — the same map, two lenses.

### What this page is designed to make obvious
- **Adverse and severe weather lift the collision rate from 0.335% to 0.478% (+42.7%)** — weather amplifies rather than causes, so the response should be conditional on weather *and* peak coincidence.
- **The top 5% of hours contain 64.1% of collisions (13.2× lift)** — patrols, gritting and VMS can be concentrated on a twentieth of the network-time and still cover two-thirds of the risk.
- The validation register is deliberately on the page. *Caveat carried in the information panel: on this synthetic source the collision process is a deterministic function of the model's own features, so this performance is an upper bound; expect materially lower PR-AUC on live STATS19-linked data.*

---

# Dashboard 4 — Environment and Net Zero

| | |
|---|---|
| **Audience** | Head of Sustainability, Net Zero policy leads, air quality officers, LEZ programme |
| **Frequency** | Quarterly Net Zero reporting; annual emissions statement |
| **The one question** | *What is the network emitting, where is air quality worst, and which levers actually move the number?* |
| **Primary source** | `fct_traffic_observation`, `agg_network_daily`, `agg_corridor_month` |

### Questions answered
1. What are network CO₂ emissions, by corridor, month and vehicle class?
2. Where and when does roadside air quality deteriorate, and what drives it?
3. What is the carbon cost of congestion specifically, over and above free-flow travel?
4. Which corridors are freight-dominated, and what does that imply for decarbonisation policy?
5. How does weather modulate measured air quality?

### Layout

| # | Visual | Position (x, y, w, h) | Fields / measures | Notes |
|---|---|---|---|---|
| 4.1 | Title + period | 24, 8, 816, 48 | | |
| 4.2 | Slicers | 24, 72, 1232, 40 | Year, Corridor, City, `dim_site[road_type]`, `dim_time[time_band]` | |
| 4.3 | KPI — Annual CO₂ | 24, 120, 192, 96 | `[Annualised CO2 Megatonnes]` | |
| 4.4 | KPI — Carbon cost | 232, 120, 192, 96 | `[Carbon Cost]` annualised | At £273/tCO₂e |
| 4.5 | KPI — CO₂ per vehicle-km | 440, 120, 192, 96 | `[CO2 Per Vehicle Km]` | Efficiency, not just volume |
| 4.6 | KPI — Mean AQI | 648, 120, 192, 96 | `[Average AQI]` | |
| 4.7 | KPI — AQI exceedance hours | 856, 120, 192, 96 | `[AQI Exceedance Hours]`, `[AQI Exceedance %]` | Threshold 100 |
| 4.8 | KPI — Freight CO₂ share | 1064, 120, 192, 96 | `[Freight CO2 Share %]` | Policy-relevant split |
| 4.9 | **Area chart — monthly CO₂ by vehicle class group** | 24, 232, 608, 216 | Axis `dim_date[month_year_label]`; values decomposed by class using the class CO₂ factors | Seasonality plus the freight floor that never goes away |
| 4.10 | **Ribbon / stacked bar — corridor emissions ranking** | 648, 232, 608, 216 | Axis `dim_site[corridor]`, value `[Annualised CO2 Tonnes]`, legend `dim_site[road_type]` | Where the tonnage actually is |
| 4.11 | **Scatter — congestion vs emissions intensity** | 24, 472, 504, 216 | X `[Journey Time Index]`, Y `[CO2 Per Vehicle Km]`, size `[Total Vehicles]`, colour `dim_site[urbanisation_band]`, details site | The congestion→emissions penalty made visible |
| 4.12 | **Heat map — AQI by hour × month** | 544, 472, 400, 216 | Rows `dim_time[hour_label]`, columns `dim_date[month_short_name]`, values `[Average AQI]` | Shows the summer photochemical and winter inversion patterns |
| 4.13 | **Table — air quality hot spots** | 960, 472, 296, 216 | `dim_site[site_code]`, `[Average AQI]`, `[AQI Exceedance %]`, `[HGV Share %]`, `[Annualised CO2 Tonnes]` | Candidate LEZ / monitoring sites |
| 4.14 | Footer | 24, 688, 1232, 32 | Disclaimer + note on overlapping segments | |

### Interactions
- 4.10 cross-filters 4.9, 4.11 and 4.13.
- Bookmark: **Absolute tonnes** / **Intensity per vehicle-km** on 4.9 — volume and efficiency tell different policy stories.
- Tooltip on 4.11 shows the site's class mix and speed distribution.

### What this page is designed to make obvious
- **Carbon at £599m per year exceeds delay at £550m.** Any appraisal counting only journey-time savings understates the case for demand management by roughly half.
- **Wind is the dominant meteorological control on measured AQI (r = −0.49)** — a monitoring-design insight: roadside AQI readings must be wind-normalised before they can be compared between sites or across days.
- Freight's share of CO₂ far exceeds its share of vehicles, concentrating decarbonisation value on the **M74 and A9 corridors** rather than on urban commuter routes.
- **Stated limitation on the page:** monitored segments are treated independently, so these are corridor-monitoring totals, not a de-duplicated national inventory.

---

# Dashboard 5 — Data Governance and Asset Health

| | |
|---|---|
| **Audience** | Asset & Data Governance Manager, trunk road operating companies, data engineering |
| **Frequency** | Daily monitoring; monthly SLA review with each operating company |
| **The one question** | *Can we trust today's data, which detectors are failing, and who owns the fix?* |
| **Primary source** | `fct_data_quality`, `agg_data_quality_daily`, `dim_sensor_status` |

This page is the reason the platform is credible. Most analytics projects hide their data quality; this one reports on it in front of the people responsible for it.

### Questions answered
1. What proportion of records is conformant, and are we meeting the 96% SLA?
2. Which rules are failing, and how has that changed?
3. Which detector sites and operating units are worst, and by how much?
4. Is missingness random, or concentrated in known-faulty assets?
5. What is the maintenance backlog in priority order?

### Layout

| # | Visual | Position (x, y, w, h) | Fields / measures | Notes |
|---|---|---|---|---|
| 5.1 | Title + period | 24, 8, 816, 48 | | |
| 5.2 | Slicers | 24, 72, 1232, 40 | Year/month, `dim_site[operating_unit]`, City, Road, `dim_sensor_status[sensor_status]` | |
| 5.3 | KPI — Records received | 24, 120, 192, 96 | `[Records Received]` | Full population, incl. quarantined |
| 5.4 | KPI — Conformance rate | 232, 120, 192, 96 | `[Conformance Rate %]`, `[DQ Status]` | Target 96% |
| 5.5 | KPI — Conformance vs SLA | 440, 120, 192, 96 | `[Conformance vs SLA]` | Signed variance |
| 5.6 | KPI — Quarantine rate | 648, 120, 192, 96 | `[Quarantine Rate %]` | Target ≤4% |
| 5.7 | KPI — Detector availability | 856, 120, 192, 96 | `[Detector Availability %]` | Target ≥95% (currently 92.1% — a live gap) |
| 5.8 | KPI — Sites below SLA | 1064, 120, 192, 96 | `[Sites Below SLA]`, `[Top Failure Reason]` | The action list length |
| 5.9 | **Line — daily conformance vs SLA** | 24, 232, 608, 216 | Axis `dim_date[full_date]`; line `[Conformance Rate %]`; constant line 96% | Control-chart style; shaded band below SLA |
| 5.10 | **Bar — failures by rule** | 648, 232, 400, 216 | Axis `fct_data_quality[dq_primary_failure]`; value `[Records Received]`, excluding "Passed" | Which rule fires most: duplicates lead at 1.64% |
| 5.11 | **Donut — disposition mix** | 1064, 232, 192, 216 | Legend `fct_data_quality[dq_disposition]`, value `[Records Received]` | Accepted / warning / quarantined |
| 5.12 | **Matrix — conformance by operating unit and status** | 24, 472, 504, 216 | Rows `dim_site[operating_unit]`; columns `dim_sensor_status[sensor_status]`; values `[Conformance Rate %]`, `[Records Quarantined]` | The SLA conversation, evidenced |
| 5.13 | **Table — detector maintenance backlog** | 544, 472, 400, 216 | `dim_site[site_code]`, city, `[Conformance Rate %]`, `[Quarantine Rate %]`, `[Records Received]`, `[Top Failure Reason]` | Sorted by quarantine rate desc; conditional icons |
| 5.14 | **Column — quarantine rate by sensor status** | 960, 472, 296, 216 | Axis `dim_sensor_status[sensor_status]`; value `[Quarantine Rate %]` | The MAR evidence: 1.8% / 11.4% / 24.9% |
| 5.15 | Footer | 24, 688, 1232, 32 | Batch id, refresh time, dbt test result | |

### Interactions
- 5.12 cross-filters 5.13, giving each operating company a filtered backlog.
- RLS applies here: each operating company sees only its own sites, but Transport Scotland sees all and can compare.
- Drill-through to *Site Detail* showing the failure timeline for a single detector.
- Alerting: set a data-driven alert on `[Conformance Rate %]` < 0.96 to notify the data engineering group.

### What this page is designed to make obvious
- **Quarantine rates of 1.8% / 11.4% / 24.9% across Active / Maintenance / Faulty detectors** prove missingness is Missing At Random conditional on asset status. That converts a statistical caveat into a maintenance prioritisation rule: fix the detectors that destroy the most analysis, not the ones that broke first.
- **South West runs 3.29% quarantine against South East's 2.73%** — the first evidenced, like-for-like SLA comparison between operating companies.
- Detector availability of **92.1% against a 95% target** is a standing gap with a named owner and a ranked backlog.

---

## Cross-cutting features

### Drill-through pages (hidden from navigation)

| Page | Entered from | Carries | Contents |
|---|---|---|---|
| **Site Detail** | 1.12, 2.13, 5.13 | `dim_site[site_code]` | Site card (road, corridor, limit, lanes, segment length, operating unit), 24-hour profile, monthly trend, incident mix, DQ timeline, cost breakdown |
| **Site Safety Detail** | 3.11 | `dim_site[site_code]` | Collision list, risk profile by hour, weather conditioning, priority-hour calendar |
| **Corridor Detail** | 1.13, 4.10 | `dim_site[corridor]` | Corridor scorecard, site league table, emissions and cost split |

### Tooltip report pages
A single 320 × 240 tooltip page bound to `dim_site` showing: site code, road, mean flow, JTI, congested hours %, mean collision risk and annualised cost. Referenced from every map and site-level visual.

### Bookmark navigation
A left-edge collapsible panel (bookmark-driven) with the five dashboard links plus an Information page. Selected state uses `#00539F`; unselected `#8A94A0`.

### Information page (required on every report)
- KPI definitions table from ITS-BRD-001 §9
- `[Sampling Disclaimer]`
- Data provenance, including the explicit statement that the source is synthetic
- Model version, validation summary and the upper-bound caveat
- Refresh schedule, dbt batch ID, and named metric owners

### Accessibility checklist
- [ ] Alt text on every visual
- [ ] Tab order set on every page
- [ ] Colour never the sole carrier of meaning (icons and labels duplicate the signal)
- [ ] Contrast ratio ≥ 4.5:1 for all text
- [ ] Slicers keyboard-navigable
- [ ] No visual relies on red/green discrimination alone

---

## Build order

1. Import model, set relationships, mark date table (ITS-BI-003 §2–4)
2. Load the measure library and organise the display folders
3. Apply the theme; build the page template (header, filter band, KPI strip, footer)
4. Build Dashboard 1 — it validates the model against §12 reconciliation
5. Build Dashboards 2–5 by duplicating the template page
6. Add drill-through and tooltip pages
7. Configure RLS and test every role
8. Run the accessibility checklist
9. Publish, certify the dataset, create the App with audience sections
