{{ config(materialized='table', tags=['agg'],
   description='Executive-level monthly rollup by strategic corridor. This is the grain the Transport Scotland board pack is written at.') }}

select
    d.year_month,
    d.calendar_year,
    d.month_number,
    d.month_year_label,
    d.fiscal_year,
    s.corridor,
    s.operating_unit,
    s.road_type,

    count(*)                                        as observation_count,
    count(distinct s.site_key)                      as site_count,
    sum(f.vehicle_count)                            as total_vehicles,
    avg(f.average_speed_kmh)                        as mean_speed_kmh,
    avg(f.journey_time_index)                       as mean_journey_time_index,
    sum(case when f.congestion_key >= 3 then 1 else 0 end) as congested_hours,
    round(100.0 * sum(case when f.congestion_key >= 3 then 1 else 0 end)
          / count(*), 2)                            as congested_hours_pct,
    sum(f.delay_vehicle_hours)                      as delay_vehicle_hours,
    sum(f.accident_flag)                            as accident_count,
    round(1e8 * sum(f.accident_flag)
          / nullif(sum(f.vehicle_count * coalesce(s.segment_length_km,0)), 0), 2)
                                                    as accidents_per_100m_vehicle_km,
    sum(f.co2_tonnes)                               as co2_tonnes,
    sum(f.total_economic_cost_gbp)                  as total_economic_cost_gbp,
    sum(f.annualised_cost_gbp)                      as annualised_cost_gbp
from {{ ref('fct_traffic_observation') }} f
join {{ ref('dim_date') }} d on f.date_key = d.date_key
join {{ ref('dim_site') }} s on f.site_key = s.site_key
group by 1,2,3,4,5,6,7,8
