{{ config(materialized='table', tags=['agg'],
   description='Typical-day profile at site / hour / day-type grain. Used for the corridor profile visual, for peak spreading analysis and as the reference baseline for real-time exception detection.') }}

select
    f.site_key,
    s.site_code,
    s.city_name,
    s.road_id,
    s.corridor,
    s.road_type,
    s.urbanisation_band,
    f.time_key                                    as hour_of_day,
    d.day_type,

    count(*)                                      as observation_count,
    avg(f.vehicle_count)                          as mean_flow,
    median(f.vehicle_count)                       as median_flow,
    quantile_cont(f.vehicle_count, 0.95)          as p95_flow,
    avg(f.average_speed_kmh)                      as mean_speed_kmh,
    quantile_cont(f.average_speed_kmh, 0.15)      as p15_speed_kmh,
    avg(f.journey_time_index)                     as mean_journey_time_index,
    quantile_cont(f.journey_time_index, 0.95)     as p95_journey_time_index,
    -- planning time index: how much time a traveller must budget to arrive on time 19 times in 20
    quantile_cont(f.journey_time_index, 0.95)
        / nullif(avg(f.journey_time_index), 0)    as buffer_index,
    avg(f.delay_vehicle_hours)                    as mean_delay_vehicle_hours,
    sum(f.accident_flag)                          as accident_count,
    avg(f.air_quality_index)                      as mean_air_quality_index,
    sum(f.delay_cost_gbp)                         as delay_cost_gbp
from {{ ref('fct_traffic_observation') }} f
join {{ ref('dim_site') }} s on f.site_key = s.site_key
join {{ ref('dim_date') }} d on f.date_key = d.date_key
group by 1,2,3,4,5,6,7,8,9
