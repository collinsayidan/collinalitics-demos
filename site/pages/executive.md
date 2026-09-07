---
title: Executive Network Performance
description: Is the strategic road network performing, what is it costing, and where should we spend?
---

# Executive Network Performance

*Is the strategic road network performing, what is it costing us, and where should
we spend?* Synthetic demonstration data — see [methodology](/methodology).

```sql cities
select 'All cities' as city_name, 0 as sort_order
union all
select distinct city_name, 1 from rpt_d1_executive
order by sort_order, city_name
```

```sql corridors
select 'All corridors' as corridor, 0 as sort_order
union all
select distinct corridor, 1 from rpt_d1_executive
order by sort_order, corridor
```

<Dropdown data={cities} name=city value=city_name defaultValue="All cities"/>
<Dropdown data={corridors} name=corridor value=corridor defaultValue="All corridors"/>

```sql kpis
select
    sum(annualised_cost_gbp) / 1e6                             as annual_cost_m,
    sum(mean_journey_time_index * observation_count)
        / sum(observation_count)                               as jti,
    sum(annualised_delay_vehicle_hours) / 1e6                  as delay_mhrs,
    sum(annualised_co2_tonnes) / 1e6                           as co2_mt,
    sum(collisions)                                            as collisions
from rpt_d1_executive
where ('${inputs.city.value}' = 'All cities' or city_name = '${inputs.city.value}')
  and ('${inputs.corridor.value}' = 'All corridors' or corridor = '${inputs.corridor.value}')
```

<BigValue data={kpis} value=jti fmt='num3' title="Journey Time Index" comparison=jti/>
<BigValue data={kpis} value=annual_cost_m fmt='num1' title="Annual cost (£m)"/>
<BigValue data={kpis} value=delay_mhrs fmt='num2' title="Delay (m vehicle-hrs/yr)"/>
<BigValue data={kpis} value=co2_mt fmt='num3' title="CO₂ (Mt/yr)"/>
<BigValue data={kpis} value=collisions fmt='num0' title="Collisions"/>

A Journey Time Index of **<Value data={kpis} value=jti fmt='num3'/>** means a typical
journey takes that multiple of its free-flow time. The Transport Scotland planning
threshold used here is 1.15.

## Demand against reliability

```sql monthly
select
    month_year_label,
    year_month,
    sum(total_vehicles)                                        as vehicles,
    sum(mean_journey_time_index * observation_count)
        / sum(observation_count)                               as jti,
    sum(annualised_cost_gbp) / 1e6                             as cost_m
from rpt_d1_executive
where ('${inputs.city.value}' = 'All cities' or city_name = '${inputs.city.value}')
  and ('${inputs.corridor.value}' = 'All corridors' or corridor = '${inputs.corridor.value}')
group by 1, 2
order by year_month
```

<LineChart
    data={monthly}
    x=month_year_label
    y=jti
    yAxisTitle="Journey Time Index"
    title="Reliability over time"
    yMin=1.0
>
    <ReferenceLine y=1.15 label="Planning threshold" color=negative/>
</LineChart>

<BarChart
    data={monthly}
    x=month_year_label
    y=vehicles
    yAxisTitle="Vehicles observed"
    title="Demand over time"
/>

Demand rises while reliability falls. The two lines diverging is the whole
executive argument: capacity is being consumed faster than it is being managed.

## Cost by corridor

```sql corridor_table
select
    corridor,
    count(distinct road_id)                                    as roads,
    sum(mean_journey_time_index * observation_count)
        / sum(observation_count)                               as jti,
    sum(annualised_cost_gbp) / 1e6                             as cost_m,
    sum(annualised_carbon_cost_gbp) / sum(annualised_cost_gbp) as carbon_share
from rpt_d1_executive
where ('${inputs.city.value}' = 'All cities' or city_name = '${inputs.city.value}')
group by 1
order by cost_m desc
```

<DataTable data={corridor_table}>
    <Column id=corridor title="Corridor"/>
    <Column id=roads title="Roads" fmt='num0'/>
    <Column id=jti title="JTI" fmt='num3' contentType=colorscale scaleColor=negative/>
    <Column id=cost_m title="£m / year" fmt='num1' contentType=bar/>
    <Column id=carbon_share title="Carbon share" fmt='pct0'/>
</DataTable>

## Sites by cost and risk

```sql sites
select
    s.site_code,
    s.road_name,
    s.city_name,
    s.corridor,
    s.latitude,
    s.longitude,
    r.annualised_cost_gbp / 1e6                                as cost_m,
    r.mean_collision_risk,
    r.mean_journey_time_index                                  as jti
from dim_site s
join agg_site_risk_ranking r on r.site_key = s.site_key
where ('${inputs.city.value}' = 'All cities' or s.city_name = '${inputs.city.value}')
  and ('${inputs.corridor.value}' = 'All corridors' or s.corridor = '${inputs.corridor.value}')
```

<PointMap
    data={sites}
    lat=latitude
    long=longitude
    value=cost_m
    valueFmt='num1'
    pointName=site_code
    height=420
    startingZoom=6
    title="Annual economic cost by site (£m)"
/>

---

<small>

**Sampling note.** The feed is a sample of site-hours, not a census. Figures
labelled *annualised* are expanded to a full-year equivalent using site-level
expansion factors; figures labelled *observed* are not. The two are never mixed
within a single chart. Synthetic data — see [methodology](/methodology).

</small>
