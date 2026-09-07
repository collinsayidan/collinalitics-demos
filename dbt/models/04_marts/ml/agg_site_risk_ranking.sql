{{ config(materialized='table', tags=['ml','agg'],
   description='Site-level risk and value-at-stake ranking. This is the model output the network operations team actually acts on: which detector sites generate the most delay cost, carry the highest modelled collision risk and should therefore receive intervention first.') }}

with joined as (
    select
        r.site_key,
        r.collision_risk_score,
        r.is_priority_risk_hour,
        r.actual_accident_flag,
        f.delay_cost_gbp,
        f.total_economic_cost_gbp,
        f.annualised_cost_gbp,
        f.delay_vehicle_hours,
        f.journey_time_index,
        f.vehicle_count,
        f.co2_tonnes,
        case when f.congestion_key >= 3 then 1 else 0 end as is_congested_hour
    from {{ ref('fct_risk_score') }} r
    join {{ ref('fct_traffic_observation') }} f on r.observation_id = f.observation_id
),

ranked as (
    select
        j.site_key,
        s.site_code,
        s.city_name,
        s.council_area,
        s.road_id,
        s.road_name,
        s.corridor,
        s.operating_unit,
        s.road_type,
        s.urbanisation_band,
        count(*)                                        as scored_hours,
        avg(j.collision_risk_score)                     as mean_collision_risk,
        quantile_cont(j.collision_risk_score, 0.95)     as p95_collision_risk,
        sum(j.is_priority_risk_hour)                    as priority_risk_hours,
        sum(j.actual_accident_flag)                     as observed_accidents,
        avg(j.journey_time_index)                       as mean_journey_time_index,
        round(100.0 * sum(j.is_congested_hour) / count(*), 2) as congested_hours_pct,
        sum(j.vehicle_count)                            as total_vehicles,
        sum(j.delay_vehicle_hours)                      as delay_vehicle_hours,
        sum(j.delay_cost_gbp)                           as delay_cost_gbp,
        sum(j.total_economic_cost_gbp)                  as total_economic_cost_gbp,
        sum(j.annualised_cost_gbp)                      as annualised_cost_gbp,
        sum(j.co2_tonnes)                               as co2_tonnes
    from joined j
    join {{ ref('dim_site') }} s on j.site_key = s.site_key
    group by 1,2,3,4,5,6,7,8,9,10
)

select
    *,
    row_number() over (order by annualised_cost_gbp desc)   as rank_by_economic_cost,
    row_number() over (order by mean_collision_risk desc)   as rank_by_collision_risk,
    row_number() over (order by congested_hours_pct desc)   as rank_by_congestion,
    -- composite intervention priority: equal weight on cost, risk and congestion rank
    round((
        percent_rank() over (order by annualised_cost_gbp)
      + percent_rank() over (order by mean_collision_risk)
      + percent_rank() over (order by congested_hours_pct)
    ) / 3.0, 4)                                             as intervention_priority_score
from ranked
