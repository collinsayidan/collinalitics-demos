{{ config(materialized='table', tags=['intermediate','silver'],
   description='The analysis-ready silver table: every observation that passed all error-severity data quality rules, with warning-level environmental gaps imputed from the site / month / hour median. This is the single source of truth for all performance reporting.') }}

with accepted as (
    select * from {{ ref('int_observations_dq') }}
    where not dq_is_quarantined
),

imputation_basis as (
    select
        city_name, observation_month, hour_of_day,
        median(temperature_c)     as med_temperature_c,
        median(wind_speed_kmh)    as med_wind_speed_kmh,
        median(visibility_km)     as med_visibility_km,
        median(air_quality_index) as med_air_quality_index
    from accepted
    group by 1,2,3
),

imputed as (
    select
        a.* exclude (temperature_c, wind_speed_kmh, visibility_km,
                     air_quality_index, rainfall_mm),

        coalesce(a.temperature_c,     i.med_temperature_c)     as temperature_c,
        coalesce(a.wind_speed_kmh,    i.med_wind_speed_kmh)    as wind_speed_kmh,
        coalesce(a.visibility_km,     i.med_visibility_km)     as visibility_km,
        coalesce(a.air_quality_index, i.med_air_quality_index) as air_quality_index,
        coalesce(a.rainfall_mm, 0.0)                           as rainfall_mm,

        case when a.temperature_c is null or a.wind_speed_kmh is null
                  or a.visibility_km is null or a.air_quality_index is null
             then 1 else 0 end                                 as is_environment_imputed
    from accepted a
    left join imputation_basis i
      on  a.city_name         = i.city_name
      and a.observation_month = i.observation_month
      and a.hour_of_day       = i.hour_of_day
)

select
    *,
    {{ congestion_band('journey_time_index') }}      as congestion_level,
    case when rainfall_mm  > 0    then 1 else 0 end  as is_wet,
    case when visibility_km < 5   then 1 else 0 end  as is_low_visibility,
    case when temperature_c <= 0  then 1 else 0 end  as is_freezing,
    case when wind_speed_kmh > 60 then 1 else 0 end  as is_high_wind,
    case
        when rainfall_mm > 2 or visibility_km < 2 or wind_speed_kmh > 70 or temperature_c <= -2
             then 'Severe'
        when rainfall_mm > 0.5 or visibility_km < 8 or wind_speed_kmh > 45 or temperature_c <= 1
             then 'Adverse'
        else 'Benign'
    end                                              as weather_severity_band
from imputed
