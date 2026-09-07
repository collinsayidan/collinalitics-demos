---
title: Explore the Network
description: Filter and sort all 74 sensor sites by cost, congestion and collision risk.
---

# Explore the Network

Every one of the 74 sites, filterable. These queries run **in your browser** —
DuckDB compiled to WebAssembly, no server involved. Synthetic data, see
[methodology](/methodology).

```sql filter_city
select 'All' as city_name, 0 as sort_order
union all
select distinct city_name, 1 from agg_site_risk_ranking
order by sort_order, city_name
```

```sql filter_road
select 'All' as road_id, 0 as sort_order
union all
select distinct road_id, 1 from agg_site_risk_ranking
order by sort_order, road_id
```

```sql filter_urban
select 'All' as urbanisation_band, 0 as sort_order
union all
select distinct urbanisation_band, 1 from agg_site_risk_ranking
order by sort_order, urbanisation_band
```

<Dropdown data={filter_city} name=city value=city_name defaultValue="All" title="City"/>
<Dropdown data={filter_road} name=road value=road_id defaultValue="All" title="Road"/>
<Dropdown data={filter_urban} name=urban value=urbanisation_band defaultValue="All" title="Setting"/>

```sql site_detail
select
    site_code,
    road_name,
    city_name,
    corridor,
    urbanisation_band,
    road_type,
    mean_journey_time_index                as jti,
    congested_hours_pct,
    mean_collision_risk,
    observed_accidents,
    total_vehicles,
    annualised_cost_gbp / 1e6              as cost_m,
    rank_by_economic_cost,
    intervention_priority_score
from agg_site_risk_ranking
where ('${inputs.city.value}'  = 'All' or city_name = '${inputs.city.value}')
  and ('${inputs.road.value}'  = 'All' or road_id   = '${inputs.road.value}')
  and ('${inputs.urban.value}' = 'All' or urbanisation_band = '${inputs.urban.value}')
order by annualised_cost_gbp desc
```

<DataTable data={site_detail} rows=20 search=true>
    <Column id=site_code title="Site"/>
    <Column id=road_name title="Road"/>
    <Column id=city_name title="City"/>
    <Column id=urbanisation_band title="Setting"/>
    <Column id=jti title="JTI" fmt='num3' contentType=colorscale scaleColor=negative/>
    <Column id=congested_hours_pct title="Congested" fmt='pct0'/>
    <Column id=mean_collision_risk title="Risk" fmt='num4'/>
    <Column id=observed_accidents title="Collisions" fmt='num0'/>
    <Column id=cost_m title="£m / yr" fmt='num2' contentType=bar/>
    <Column id=intervention_priority_score title="Priority" fmt='num1'/>
</DataTable>

## Cost against risk

Where a site sits on these two axes decides what kind of intervention it needs.
High cost with low risk is a capacity problem. High risk with low cost is a safety
problem. Sites in the upper right are both.

<ScatterPlot
    data={site_detail}
    x=mean_collision_risk
    y=cost_m
    series=corridor
    xAxisTitle="Mean collision risk"
    yAxisTitle="Annual cost (£m)"
    tooltipTitle=site_code
    height=420
/>

## Congestion against journey time

```sql profile
select
    site_code,
    corridor,
    city_name,
    mean_journey_time_index as jti,
    congested_hours_pct,
    total_vehicles
from agg_site_risk_ranking
where ('${inputs.city.value}'  = 'All' or city_name = '${inputs.city.value}')
  and ('${inputs.road.value}'  = 'All' or road_id   = '${inputs.road.value}')
  and ('${inputs.urban.value}' = 'All' or urbanisation_band = '${inputs.urban.value}')
```

<BubbleChart
    data={profile}
    x=congested_hours_pct
    y=jti
    size=total_vehicles
    series=corridor
    xAxisTitle="Share of hours congested"
    yAxisTitle="Journey Time Index"
    tooltipTitle=site_code
    height=420
/>

The relationship is not linear. Sites past roughly 30% congested hours show journey
times rising far faster than the congestion share alone would suggest — the
hypercongestion branch of the fundamental diagram, where throughput falls while
delay keeps climbing. Those are the sites where an extra 1% of demand is most
expensive, and where intervention returns most.

---

<small>Synthetic demonstration data · Collinalitics Ltd ·
[methodology](/methodology)</small>
