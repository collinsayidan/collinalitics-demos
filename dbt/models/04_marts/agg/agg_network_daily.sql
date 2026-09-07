{{ config(materialized='table', tags=['agg'],
   description='Daily network performance aggregate at date / city / road grain. Pre-aggregated for dashboard responsiveness; every measure reconciles exactly to fct_traffic_observation.') }}

select
    f.date_key,
    d.full_date,
    d.calendar_year,
    d.year_month,
    d.day_type,
    d.meteorological_season,
    d.is_school_holiday,
    s.city_name,
    s.council_area,
    s.road_id,
    s.corridor,
    s.road_type,
    s.operating_unit,

    count(*)                                              as observation_count,
    count(distinct s.site_key)                            as active_site_count,
    sum(f.vehicle_count)                                  as total_vehicles,
    sum(f.pcu_count)                                      as total_pcu,
    sum(f.hgv_count)                                      as total_hgv,
    avg(f.average_speed_kmh)                              as mean_speed_kmh,
    -- harmonic mean is the correct average for space-mean speed
    count(*) / nullif(sum(1.0 / nullif(f.average_speed_kmh, 0)), 0) as harmonic_mean_speed_kmh,
    avg(f.journey_time_index)                             as mean_journey_time_index,
    quantile_cont(f.journey_time_index, 0.95)             as p95_journey_time_index,
    sum(f.delay_vehicle_hours)                            as delay_vehicle_hours,
    sum(case when f.congestion_key >= 3 then 1 else 0 end) as congested_hour_count,
    sum(f.accident_flag)                                  as accident_count,
    sum(f.has_incident)                                   as incident_count,
    sum(f.roadworks_flag)                                 as roadworks_hour_count,
    sum(f.lane_closure_flag)                              as lane_closure_hour_count,
    avg(f.air_quality_index)                              as mean_air_quality_index,
    sum(f.co2_tonnes)                                     as co2_tonnes,
    sum(f.delay_cost_gbp)                                 as delay_cost_gbp,
    sum(f.carbon_cost_gbp)                                as carbon_cost_gbp,
    sum(f.collision_cost_gbp)                             as collision_cost_gbp,
    sum(f.total_economic_cost_gbp)                        as total_economic_cost_gbp,
    sum(f.annualised_cost_gbp)                            as annualised_cost_gbp,
    sum(f.annualised_delay_vehicle_hours)                 as annualised_delay_vehicle_hours,
    sum(f.annualised_co2_tonnes)                          as annualised_co2_tonnes
from {{ ref('fct_traffic_observation') }} f
join {{ ref('dim_date') }} d on f.date_key = d.date_key
join {{ ref('dim_site') }} s on f.site_key = s.site_key
group by 1,2,3,4,5,6,7,8,9,10,11,12,13
