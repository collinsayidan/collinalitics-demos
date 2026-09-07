{{ config(materialized='table', tags=['fact','core'],
   description='Central transactional fact. Grain: one row per clean detector observation (site-hour). Carries conformed foreign keys to every dimension, the physical traffic measures, the environmental context and the monetised delay, carbon and safety cost of that hour.') }}

with obs as (
    select * from {{ ref('int_observations_clean') }}
),
econ as (
    select * from {{ ref('int_observation_economics') }}
),
site as (
    select site_key, site_natural_key, segment_length_km as site_segment_length_km
    from {{ ref('dim_site') }}
)

select
    -- ---------- degenerate + surrogate keys --------------------------
    o.record_id                                                as observation_id,
    cast(strftime(o.observation_date, '%Y%m%d') as integer)    as date_key,
    o.hour_of_day                                              as time_key,
    s.site_key,
    c.congestion_key,
    i.incident_key,
    e.event_key,
    ss.sensor_status_key,
    w.weather_key,

    o.observation_ts,
    o.observation_date,

    -- ---------- volume measures --------------------------------------
    o.vehicle_count,
    o.car_count,
    o.van_count,
    o.hgv_count,
    o.bus_count,
    o.motorcycle_count,
    o.hgv_count + o.van_count                                  as freight_vehicle_count,
    o.car_count + o.van_count + o.motorcycle_count
        + 2.5 * o.hgv_count + 2.0 * o.bus_count                as pcu_count,

    -- ---------- performance measures ---------------------------------
    o.average_speed_kmh,
    o.speed_limit_kmh,
    o.journey_time_minutes,
    o.free_flow_journey_time_minutes,
    o.journey_time_index,
    o.delay_minutes_per_vehicle,
    ec.total_delay_vehicle_hours                               as delay_vehicle_hours,
    o.average_speed_kmh / nullif(o.speed_limit_kmh, 0)         as speed_compliance_ratio,

    -- ---------- environmental measures -------------------------------
    o.temperature_c,
    o.rainfall_mm,
    o.wind_speed_kmh,
    o.visibility_km,
    o.air_quality_index,
    o.co2_emission_kg,
    ec.co2_tonnes,

    -- ---------- event and disruption flags ---------------------------
    o.accident_flag,
    o.roadworks_flag,
    o.lane_closure_flag,
    o.public_event_flag,
    o.school_holiday_flag,
    o.has_incident,
    o.is_weekend,
    o.is_peak_hour,
    o.is_environment_imputed,
    case when o.dq_has_warning then 1 else 0 end               as has_dq_warning,

    -- ---------- monetised measures -----------------------------------
    ec.delay_cost_gbp,
    ec.carbon_cost_gbp,
    ec.collision_cost_gbp,
    ec.breakdown_cost_gbp,
    ec.total_economic_cost_gbp,

    -- ---------- survey weighting -------------------------------------
    ec.expansion_factor,
    ec.annualisation_factor,
    ec.annualised_cost_gbp,
    ec.annualised_delay_vehicle_hours,
    ec.annualised_co2_tonnes

from obs o
join econ ec               on o.record_id = ec.record_id
join site s                on o.site_natural_key = s.site_natural_key
join {{ ref('dim_congestion') }}    c  on o.congestion_level        = c.congestion_level
join {{ ref('dim_incident') }}      i  on o.incident_type           = i.incident_type
join {{ ref('dim_event') }}         e  on o.event_type              = e.event_type
join {{ ref('dim_sensor_status') }} ss on o.sensor_status           = ss.sensor_status
join {{ ref('dim_weather') }}       w  on o.weather_severity_band   = w.weather_severity_band
