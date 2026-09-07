---
title: Methodology and Limitations
description: How this platform was built, what it can support, and what it cannot.
---

# Methodology and Limitations

## What this is

A demonstration analytics platform built by **Collinalitics Ltd** to show how we
take a raw sensor feed through to board-level economics. It uses a synthetic
dataset because client data is confidential.

## What this is not

This is **not** Transport Scotland data. Collinalitics Ltd has no affiliation with,
commission from, or endorsement by Transport Scotland, Transport Scotland's operating
companies, or any other public body. The road identifiers, city names, geography and
appraisal values are real and publicly sourced. **Every traffic measurement is
generated.** No figure on this site describes an actual road.

Nothing here should be used to inform a real investment, operational or policy
decision about the Scottish road network.

## The data

100,000 hourly observations across 74 sensor sites on 9 roads (M8, M74, M77, M90,
A9, A90, A82, A1, A96) serving 7 cities, spanning April 2023 to September 2025.

The generator is not a random-number exercise. It models:

- **Demand** by site, hour, day type and season, with morning and evening peaks and a
  weekday/weekend split that shifts commuter volume into leisure volume
- **Speed** through a Bureau of Public Roads curve, `JTI = 1 + 0.52·(v/c)^2.9`,
  so that speed falls as volume approaches capacity rather than by assignment
- **Weather** on per-city climatology, with winter visibility loss and rainfall
  feeding through to both congestion and collision probability
- **Disruption** from collisions, lane closures, roadworks and planned events, each
  with its own effect on journey time
- **Sensor behaviour**, including seven distinct classes of fault seeded at 2–5% of
  records: dropouts, stuck readings, implausible speeds, missing values, duplicate
  timestamps and extreme spikes

The faults are deliberate. A platform that only works on clean data is not a
platform.

## The pipeline

| Layer | Technology | What happens |
|---|---|---|
| Generation | Python | Seeded generator, reproducible from `SEED = 20260809` |
| Warehouse | dbt + DuckDB | 33 models across bronze → staging → intermediate → marts |
| Storage | PostgreSQL | Star schema, 8 dimensions, 3 facts, 5 aggregates |
| Quality | dbt tests | 120 tests, 12 explicit rules with stated dispositions |
| ML | scikit-learn | Gradient boosting, temporal hold-out |
| Internal BI | Power BI | Governed semantic model, 232 measures |
| This site | Evidence + DuckDB | Static build over Parquet |

## Data quality

Of 100,000 raw records, **96,652 (95.7%) pass all twelve quality rules** and enter
the analytical layer. The remainder are quarantined, imputed or flagged according to
a documented disposition per rule — never silently dropped.

```sql dq
select
    'Records generated' as stage, 100000 as records
union all
select 'Records passing all rules', sum(observation_count) from rpt_d1_executive
```

<DataTable data={dq}>
    <Column id=stage title=""/>
    <Column id=records title="Records" fmt='num0'/>
</DataTable>

One quality bug was found in build by the pipeline's own reconciliation test: 318
records carried a null vehicle-class count, which excluded them from component cost
sums while leaving their totals intact. The rule set did not check class counts, and
the reconciliation test used `<>`, which is never true against null. Both were
fixed. Every figure on this site is post-fix.

We mention it because a data platform that has never caught anything has not been
tested.

## Economic values

| Item | Source | Value |
|---|---|---|
| Value of time | DfT TAG data book | By journey purpose |
| Fatal casualty | DfT RAS4001 | £2,411,659 |
| Serious casualty | DfT RAS4001 | £271,003 |
| Slight casualty | DfT RAS4001 | £20,892 |
| Carbon | DESNZ central non-traded, 2022 prices | £273 / tCO₂e (±50%) |

The carbon value carries a wide official sensitivity range. Since carbon is the
largest cost component here, the total is correspondingly sensitive: at the low
bound the annual figure falls to roughly £1.05bn, at the high bound it rises to
about £1.65bn. We state this rather than presenting a single number as precise.

## Sampling and annualisation

The feed represents a sample of site-hours rather than a continuous census. Each
site carries an expansion factor of `period_hours / clean_observations_at_site`, and
an annualisation factor dividing that by the period length in years.

**Observed** figures describe what the sensors recorded. **Annualised** figures are
expanded to full-year equivalents. Mixing the two produces nonsense, so they are
never combined within a chart, and every monetary visual states which it is showing.

## Known limitations

1. **Synthetic data.** Relationships are as modelled, so the analysis validates the
   method, not any claim about Scotland's roads.
2. **Carbon sensitivity.** The headline is dominated by a value with a ±50% official
   range.
3. **No origin-destination data.** Site-level counts cannot support routing or
   diversion analysis.
4. **Speed is space-mean.** Harmonic means are used where appropriate; the arithmetic
   mean of 88.7 km/h overstates the correct space-mean speed of 82.7 km/h, and this
   distinction is preserved through the model.
5. **The risk model is a forecast, not a fit.** Realised flow and speed are
   deliberately excluded from the features, so the model predicts collision risk from
   conditions known in advance. This costs accuracy and buys operational usefulness.
6. **Static build.** The site reflects the last pipeline run, appropriate for a fixed
   historical dataset.

---

<small>Collinalitics Ltd · [collinalitics.co.uk](https://collinalitics.co.uk)</small>
