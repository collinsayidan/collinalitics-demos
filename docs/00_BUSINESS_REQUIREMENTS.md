# Business Requirements Document
## Scotland Intelligent Transport System — Network Performance Analytics Platform

| | |
|---|---|
| **Document reference** | ITS-BRD-001 |
| **Version** | 1.0 |
| **Status** | Approved for build |
| **Client** | Transport Scotland — Network Operations and Strategy |
| **Delivered by** | Senior Data Analyst / Business Analyst, ITS Analytics Programme |
| **Reporting period covered** | 1 January 2023 – 31 December 2025 |
| **Related documents** | ITS-ARC-002 Data Architecture · ITS-BI-003 Power BI Build Guide · ITS-BI-004 Dashboard Specifications · ITS-DQ-005 Data Quality Report |

---

## 1. Executive summary

Transport Scotland operates roadside detection across the strategic road network but the resulting data is consumed largely as raw counts, in isolated spreadsheets, after the fact. Network performance is described but rarely *valued*; disruption is recorded but rarely *attributed*; detector faults are known to exist but are not *managed*.

This programme delivers a governed, tested analytics platform over 100,000 detector-hours spanning 74 sites, 9 strategic roads and 7 cities, and five executive-grade Power BI dashboards built on it. Every operational fact is converted into a monetised figure using UK Government appraisal values, so that a congested hour on the M8 and a detector fault in Inverness can be compared on the same £ scale and ranked against each other for investment.

**The headline finding the platform produces:** the monitored network carries an estimated **£1.35 billion per year** of avoidable economic cost — £599m carbon, £550m delay, £189m collisions, £15m breakdown response. Just **10 of the 74 monitored sites account for £458.6m (34.0%)** of it. That concentration is the business case: intervention does not need to be network-wide to be material.

---

## 2. Problem statement

### 2.1 The situation

Scotland's strategic road network is simultaneously subject to three pressures that are currently measured by three different teams, on three different cadences, using three different definitions:

1. **Congestion and reliability** — journey times on the Central Belt motorway network degrade predictably twice a day, and unpredictably whenever an incident occurs. Reliability, not average speed, is what road users actually experience and complain about.
2. **Net Zero 2045** — surface transport is Scotland's largest emitting sector. Road network emissions are estimated from national fleet models, not observed from the network itself, so the emissions consequence of an operational decision is invisible at the point the decision is made.
3. **Road Safety Framework to 2030** — the framework commits to a 50% reduction in fatalities and serious injuries. Collision analysis today is retrospective and location-based; it is not conditioned on the traffic, weather and disruption state that existed at the time.

### 2.2 The problem

> **Transport Scotland can describe what happened on the network, but cannot reliably say what it cost, why it happened, where intervening would deliver most value, or what is likely to happen next.**

Five specific failures follow from this:

| # | Failure | Consequence |
|---|---|---|
| P1 | **No single version of network performance.** Congestion is variously defined as speed below a threshold, delay against a schedule, or a subjective control-room judgement. | Teams argue about the number instead of acting on it. Board papers are not comparable quarter to quarter. |
| P2 | **Operational data is never monetised.** Delay hours, tonnes of CO₂ and collision counts are reported in incompatible units. | Competing interventions cannot be ranked. Investment defaults to whoever argues loudest. |
| P3 | **Disruption is not attributed.** Roadworks, collisions, planned events and weather all degrade performance, but their separate contributions are not quantified. | Roadworks scheduling and event traffic management are planned on judgement, not evidence. |
| P4 | **Detector data quality is unmanaged.** Faults are discovered when an analyst notices an implausible number, not when the fault occurs. | Analysis is silently corrupted; maintenance is reactive; there is no SLA position against the operating companies. |
| P5 | **Analytics is entirely retrospective.** There is no forward view of where congestion or collision risk will concentrate. | Resources — patrols, gritting, variable message signing, incident response units — are positioned reactively. |

### 2.3 Cost of inaction

Applying the platform's own valuation to the observed network state: **£1.35bn per year** of delay, carbon and collision cost, of which the analysis shows **£23.8m per year is directly attributable to roadworks scheduling alone** — a decision variable entirely within Transport Scotland's control.

---

## 3. Aims

The programme has three aims, expressed as the outcome the organisation should be able to claim on completion.

> **Aim 1 — A single, trusted, governed view of strategic road network performance**, produced from one tested pipeline, using one set of published definitions, refreshed on a known schedule.

> **Aim 2 — Every network outcome expressed in pounds**, so that congestion, carbon and casualties can be compared, ranked and traded off against each other in the same conversation.

> **Aim 3 — A shift from retrospective reporting to forward-looking operational decision support**, so that the network is managed on where risk *will* concentrate, not only where it *did*.

---

## 4. Goals

Goals are the measurable, time-bound expressions of the aims.

| Goal | Aim | Measure | Target |
|---|---|---|---|
| **G1** Establish a certified single source of truth | 1 | Proportion of board-level network KPIs sourced from the certified semantic model | 100% within 2 quarters |
| **G2** Achieve auditable data quality | 1 | Automated test pass rate on every pipeline run; conformance rate published daily | 100% test pass; ≥96% conformance |
| **G3** Monetise the full network cost base | 2 | Proportion of reported operational measures with an attached, source-referenced £ value | 100% of delay, carbon and collision measures |
| **G4** Concentrate intervention on value | 2 | Share of annual economic cost addressable by the top 10 ranked sites, identified and published | ≥30% identified (achieved: 34%) |
| **G5** Deploy predictive decision support | 3 | Proportion of collisions captured within the model's top 5% risk hours | ≥50% (achieved: 64%) |
| **G6** Cut analyst effort | 1,3 | Time to produce the monthly network performance pack | From ~5 days manual to <1 hour automated |
| **G7** Make detector maintenance evidence-led | 1 | Detector sites with a published conformance rate and a ranked maintenance position | 100% of 74 sites |

---

## 5. Objectives

Objectives are the specific, deliverable-level commitments — what is actually built.

### 5.1 Data engineering objectives

- **O1** Implement a four-layer medallion architecture (bronze → staging → intermediate → marts) in dbt on a DuckDB warehouse, with every model documented and lineage automatically generated.
- **O2** Codify the twelve data quality rules from the Data Quality Report as executable pipeline logic, with an explicit disposition per rule (quarantine / impute / flag / fail).
- **O3** Quarantine rather than silently drop defective records, retaining the full population so that data quality is itself reportable.
- **O4** Deliver a Kimball star schema — one transactional fact, one data quality fact, one ML fact, eight conformed dimensions and four aggregate tables.
- **O5** Achieve and maintain a 100% pass rate across the automated test suite (**achieved: 116/116 tests passing**), covering uniqueness, referential integrity, accepted values, and six bespoke business-rule assertions.

### 5.2 Analytical objectives

- **O6** Attach survey-style expansion factors to every observation so that sampled site-hours can be grossed up to defensible network annual totals rather than being misread as a census.
- **O7** Monetise delay, carbon, collisions and breakdown response using published UK appraisal values held as a versioned, source-referenced reference table — never hard-coded in a report.
- **O8** Attribute journey time degradation separately to collisions, lane closures, roadworks, planned events and weather severity.
- **O9** Rank all 74 sites on a composite intervention priority score combining economic cost, modelled collision risk and congestion frequency.

### 5.3 Predictive objectives

- **O10** Build an *operational* congestion forecast that uses only information knowable in advance — calendar, site characteristics, forecast weather and planned disruption — deliberately excluding realised flow and speed, because a model that must observe congestion to predict congestion has no control-room value.
- **O11** Build a collision risk model on the same forward-looking basis and validate it on precision-recall, capture and lift rather than accuracy, given a 0.36% positive rate.
- **O12** Validate both models on a strict temporal hold-out (train 2023–24, test 2025) and publish every evaluation metric into the warehouse so dashboard users can see how the model was validated rather than trusting a headline number.

### 5.4 Business intelligence objectives

- **O13** Deliver five Power BI dashboards on one shared, certified semantic model: Executive Network Performance, Congestion & Reliability, Safety & Incident Intelligence, Environment & Net Zero, Data Governance & Asset Health.
- **O14** Deliver a complete DAX measure library with a consistent naming standard, folder organisation and format strings.
- **O15** Implement row-level security by operating unit so each trunk road operating company sees its own network.
- **O16** Design for sub-2-second visual response through pre-aggregated tables and star-schema discipline.

---

## 6. Scope

### 6.1 In scope

| Area | Included |
|---|---|
| Geography | Glasgow, Edinburgh, Aberdeen, Dundee, Inverness, Stirling, Perth |
| Network | M8, M74, M77, M90, A1, A9, A82, A90, A96 — 74 detector sites |
| Period | 1 Jan 2023 – 31 Dec 2025 (36 months, 1,096 days) |
| Grain | One detector site per hour |
| Domains | Traffic volume and composition, speed, journey time reliability, incidents, roadworks, planned events, weather, air quality, CO₂, detector health |
| Analytics | Descriptive, diagnostic, predictive, and economic valuation |
| Delivery | dbt warehouse, tested pipeline, Power BI semantic model, five dashboards, DAX library, theme |

### 6.2 Out of scope

| Excluded | Rationale |
|---|---|
| Real-time / sub-hourly streaming | Current feed is hourly batch. A streaming layer is a phase 2 candidate. |
| Network topology, route choice and queue spillback | Links are modelled independently; there is no upstream/downstream propagation in the source. |
| Individual vehicle or ANPR data | Privacy and information governance; not required for network-level KPIs. |
| Local authority roads | Strategic (trunk) network only. |
| Public transport punctuality, active travel and rail | Separate data domains and owners. |
| Automated intervention (signal or VMS control) | The platform informs decisions; it does not actuate. |

### 6.3 Key assumptions

1. Detector coverage is representative of the corridors it monitors; expansion factors are computed per site to correct for uneven sampling.
2. Published appraisal unit values are the correct basis for valuation and will be refreshed annually from the DfT TAG Databook and DESNZ carbon values.
3. Monitored segments are treated as independent; overlapping-segment de-duplication would be required before these emissions figures could be used as a national inventory submission.
4. The source dataset is synthetic and purpose-built; the architecture, logic and dashboards are production-shaped and would apply unchanged to a live Traffic Scotland feed.

---

## 7. Stakeholders

| Stakeholder | Role | Primary interest | Dashboard |
|---|---|---|---|
| Director of Network Operations | Executive sponsor | Is the network performing, and what is it costing? | 1 — Executive |
| Head of Traffic Operations (Traffic Scotland Control Centre) | Decision maker | Where and when does congestion concentrate; what caused it? | 2 — Congestion |
| Road Safety Policy Lead | Decision maker | Where is collision risk concentrated; is the 2030 trajectory on track? | 3 — Safety |
| Head of Sustainability / Net Zero Lead | Decision maker | Network emissions, air quality exceedance, decarbonisation levers | 4 — Environment |
| Asset & Data Governance Manager | Data owner | Detector reliability, conformance, SLA position against operating companies | 5 — Governance |
| Trunk Road Operating Companies (NW, NE, SE, SW) | Delivery partners | Own-network performance and maintenance backlog | RLS-filtered views |
| Scottish Government analysts / Transport Statistics | Consumer | Consistent, auditable, published statistics | Certified dataset |
| Finance / Investment Appraisal | Consumer | Value-for-money case for intervention | 1 and 4 |

---

## 8. Business questions the platform must answer

These are the questions the dashboards are designed around, grouped by analytical mode.

### Descriptive — *what happened?*

1. How much traffic uses each corridor, when, and of what composition?
2. What is average journey time reliability by road, city and month, and how has it moved year on year?
3. How many hours were spent in High or Severe congestion, and where?
4. How many collisions, breakdowns and obstructions occurred, and under what conditions?
5. What did the network emit, and how does air quality vary by location and time?

### Diagnostic — *why did it happen?*

6. How much of the delay is attributable to collisions, lane closures, roadworks, planned events and weather respectively?
7. Does adverse weather materially change congestion and collision risk, and by how much?
8. Which time bands and days concentrate delay cost, and is the peak spreading over time?
9. Are detector faults concentrated in particular sites, operating units or periods?
10. Is the difference between the AM and PM peak a demand effect or a capacity effect?

### Predictive — *what is likely to happen?*

11. Given the calendar, site, forecast weather and planned works, what congestion level should be expected?
12. Which site-hours carry the highest collision risk, and what share of actual collisions do they capture?
13. Which sites should be prioritised for intervention on a combined cost, risk and congestion basis?

### Prescriptive / economic — *what should we do?*

14. What is the annual economic cost of network under-performance, and how is it split between delay, carbon and casualties?
15. What is the value at stake at each site, and where would £1 of intervention return most?
16. What would rescheduling roadworks out of peak periods be worth?

---

## 9. Key performance indicators

Every KPI below has a single, published definition implemented once in the semantic model.

| KPI | Definition | Owner | Observed value | Target / direction |
|---|---|---|---|---|
| **Journey Time Index (JTI)** | Observed journey time ÷ free-flow journey time. 1.00 = free flow. | Network Operations | **1.167** network mean | ≤1.15 |
| **Congested hours %** | Share of detector-hours at High or Severe congestion (JTI ≥ 1.45). | Network Operations | **8.14%** | ≤5% |
| **Delay vehicle-hours** | Σ (vehicles × delay above free flow). Transport Scotland's stated congestion measure. | Network Operations | **24.5m per year** | ↓ 10% by 2028 |
| **Buffer Index** | P95 JTI ÷ mean JTI — the reliability, as opposed to average, measure. | Network Operations | Site-level | ↓ |
| **Collision rate** | Collisions per 100 million vehicle-kilometres. | Road Safety | Corridor-level | ↓ 50% by 2030 |
| **Priority-hour capture** | Share of collisions occurring in the model's top 5% risk hours. | Road Safety | **64.1%** | ≥50% |
| **Network CO₂** | Tonnes CO₂ from monitored links, grossed up and annualised. | Sustainability | **2.20 Mt per year** | ↓ toward Net Zero 2045 |
| **Mean Air Quality Index** | Mean roadside AQI. | Sustainability | **44.1** | ↓; no site sustained >100 |
| **Total economic cost** | Delay + carbon + collision + breakdown cost, annualised. | Finance / Exec | **£1,348.8m per year** | ↓ |
| **Detector conformance rate** | Share of records passing all error-severity DQ rules. | Data Governance | **96.02%** | ≥96% |
| **Quarantine rate** | Share of records failing an error-severity rule. | Data Governance | **3.03%** | ≤4% |
| **Detector availability** | Share of records from sensors in Active status. | Data Governance | **92.1%** | ≥95% |

---

## 10. What the data tells us — findings the platform surfaces

These are the deductions the analysis actually supports. They are the substance the dashboards exist to communicate.

### 10.1 Cost is dominated by carbon, not delay

| Cost component | Annualised | Share |
|---|---|---|
| Carbon | £599.4m | 44.4% |
| Delay | £550.3m | 40.8% |
| Collisions | £188.6m | 14.0% |
| Breakdown response | £15.0m | 1.1% |
| **Total** | **£1,348.8m** | **100%** |

**Deduction:** at the DESNZ central value of £273/tCO₂e, carbon overtakes delay as the largest monetised externality of the network. Any business case that counts only journey-time savings understates the value of demand management and mode shift by roughly a factor of two. This reframes the investment conversation.

### 10.2 Value is highly concentrated

The top 10 of 74 sites account for **£458.6m (34.0%)** of annualised cost. The single worst site, **M8-EDI-02, carries £79m per year** — 5.9% of the entire monitored network cost at one location.

**Deduction:** a targeted intervention programme at ten locations addresses a third of the problem. Network-wide schemes are not required to move the headline number.

### 10.3 Disruption attribution is unambiguous

| Condition | Hours | Mean JTI | Delay cost per hour |
|---|---|---|---|
| Collision | 348 | **2.708** | **£7,820** |
| Lane closure | 5,266 | 1.517 | £2,002 |
| Planned event | 2,579 | 1.311 | £2,430 |
| Roadworks (no closure) | 4,023 | 1.276 | £1,157 |
| No disruption | 84,754 | 1.130 | £846 |

**Deduction:** a collision hour costs **9.2× a normal hour**. Reducing mean incident clearance time is therefore the single highest-leverage operational lever available — higher than any capacity intervention, and far cheaper. Roadworks, at £23.8m per year of attributable extra cost, are the largest *controllable* cost: they are scheduled, not suffered.

### 10.4 Weather is a compounding, not dominant, factor

Adverse conditions raise mean JTI from 1.158 to 1.206 and the collision rate from 0.335% to 0.478% (**+42.7%**); severe conditions raise delay cost per hour by 54%.

**Deduction:** weather does not cause congestion, it amplifies it. The operational response is therefore conditional — pre-position resources when adverse weather coincides with peak periods, rather than responding to weather in isolation.

### 10.5 The PM peak is the expensive one

The PM peak carries **34.4% of all delay cost** against the AM peak's 22.3%, despite similar flows. The PM peak is broader (15:00–18:00 vs a sharp 07:00–09:00) and overlaps with discretionary and freight travel.

**Deduction:** peak-spreading measures targeted at the afternoon have roughly 1.5× the value of equivalent morning measures. Inter-peak now carries 23.2% of delay cost — the traditional "quiet" period is no longer quiet.

### 10.6 Performance is degrading year on year

| Year | Mean JTI | Annualised cost | Collision rate |
|---|---|---|---|
| 2023 | 1.1601 | £438.7m | 0.399% |
| 2024 | 1.1664 | £448.7m | 0.322% |
| 2025 | 1.1757 | £461.4m | 0.356% |

**Deduction:** demand growth of ~2.5% per year is translating into a **1.3% per year deterioration in journey time index and £22.7m per year of additional cost**. Doing nothing is not cost-neutral; it has a measurable and rising price.

### 10.7 Collision risk is concentrated and predictable

The collision risk model achieves **PR-AUC 0.222 against a 0.36% base rate (61× baseline)** and **ROC-AUC 0.832**. Its top 5% of hours, the "Priority" band, contains **64.1% of all collisions** — a **13.2× lift**.

**Deduction:** patrol positioning, gritting and VMS warning can be targeted at 5% of site-hours and still cover two-thirds of collisions. *Caveat for the award panel: this dataset is synthetic and its collision process is a deterministic function of the features supplied to the model, so this performance is an upper bound. On live STATS19-linked data, expect materially lower PR-AUC; the operational framing, validation design and capture-based evaluation remain valid.*

### 10.8 Data quality is a maintenance signal, not just a caveat

Quarantine rates are **24.9% for Faulty detectors, 11.4% for Maintenance and 1.8% for Active** — missingness is Missing At Random conditional on detector status.

**Deduction:** detector status predicts data loss, so the maintenance backlog can be prioritised by *analytical* impact rather than by fault age. The South West operating unit shows the highest quarantine rate (3.29%) against the South East's 2.73% — a defensible SLA conversation, and the first time such a comparison has been possible.

---

## 11. Success criteria and acceptance

| # | Acceptance criterion | Status |
|---|---|---|
| AC1 | Pipeline executes end to end from raw CSV to marts in a single command | ✅ `dbt build` — 23 models, 5 seeds, 87 tests |
| AC2 | 100% automated test pass rate | ✅ 116/116 |
| AC3 | Aggregates reconcile exactly to the fact table | ✅ enforced by singular test |
| AC4 | Full source population retained and reportable, not silently dropped | ✅ 100,000 rows in `fct_data_quality` |
| AC5 | Every monetary figure traceable to a published, versioned unit value | ✅ `ref_appraisal_parameters` seed with source column |
| AC6 | Predictive models validated on a temporal hold-out and metrics published to the warehouse | ✅ `dim_model_metric` |
| AC7 | Five dashboards specified to build-ready detail on one shared semantic model | ✅ ITS-BI-004 |
| AC8 | Row-level security design covering all four operating units | ✅ ITS-BI-003 §7 |
| AC9 | Complete data dictionary and lineage documentation | ✅ ITS-ARC-002 |

---

## 12. Risks and mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | Appraisal values become out of date, invalidating every £ figure | High | High | Values held in a versioned seed with `price_base_year` and `source_reference`; annual refresh task owned by Data Governance |
| R2 | Expansion factors misread as a census, overstating network totals | Medium | High | Both observed and annualised measures published side by side; every dashboard footer states the sampling rate |
| R3 | Detector fault rate rises, degrading conformance below 96% | Medium | Medium | Daily conformance monitoring with site-level alerting on Dashboard 5 |
| R4 | Predictive model degrades as demand patterns drift | Medium | Medium | Model metrics published by data split; retraining triggered on PSI drift in flow distribution |
| R5 | Stakeholders build competing local models from the raw extract | Medium | High | Semantic model certified in the Power BI tenant; raw extract access restricted to the engineering team |
| R6 | Overlapping monitored segments double-count emissions | Low | Medium | Documented limitation; segment de-duplication required before any national inventory use |
| R7 | Synthetic source is mistaken for observed data | Low | High | Provenance stated on the cover of every document and in the dashboard information panel |

---

## 13. Delivery approach

| Phase | Content | Artefact |
|---|---|---|
| 1 — Discovery | Problem framing, stakeholder map, KPI definitions | This document |
| 2 — Architecture | Medallion design, star schema, DQ framework | ITS-ARC-002 |
| 3 — Build | dbt models, seeds, tests, ML scoring layer | `dbt/`, `ml/` |
| 4 — Semantic layer | Star schema import, DAX library, theme, RLS | ITS-BI-003, `powerbi/` |
| 5 — Visualisation | Five dashboards to build-ready specification | ITS-BI-004 |
| 6 — Assurance | Test suite, reconciliation, verification report | `dbt test`, ITS-DQ-005 |

**Next phase candidates:** real-time streaming ingestion; STATS19 collision linkage for true severity weighting; network topology for spillback modelling; scenario simulator for mode shift and HGV rescheduling; automated VMS recommendation.
