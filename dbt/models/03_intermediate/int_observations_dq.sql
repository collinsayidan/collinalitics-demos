{{ config(materialized='table', tags=['intermediate','dq'],
   description='Applies the twelve documented data quality rules to every staged observation. Produces one boolean column per rule plus an overall disposition. No rows are removed here - quarantine is a downstream decision, so the DQ dashboard can report on the full population.') }}

with obs as (
    select * from {{ ref('stg_its__observations') }}
),

baseline as (
    select * from {{ ref('int_site_hour_baseline') }}
),

joined as (
    select
        o.*,
        b.median_flow,
        b.p95_flow,
        -- surplus copies of the same site-hour reading
        row_number() over (
            partition by o.site_natural_key, o.observation_ts
            order by
                case o.sensor_status when 'Active' then 0 when 'Maintenance' then 1 else 2 end,
                case when o.vehicle_count is null then 1 else 0 end,
                o.record_id
        ) as site_hour_sequence,
        count(*) over (
            partition by o.site_natural_key, o.observation_ts
        ) as site_hour_reading_count
    from obs o
    left join baseline b
      on  o.site_natural_key = b.site_natural_key
      and o.hour_of_day      = b.hour_of_day
),

flagged as (
    select
        *,
        -- DQ01 Completeness : core traffic measures
        (vehicle_count is null or average_speed_kmh is null)                  as dq01_traffic_null,

        -- DQ02 Completeness : environmental measures
        (temperature_c is null or rainfall_mm is null or wind_speed_kmh is null
         or visibility_km is null or air_quality_index is null)               as dq02_environment_null,

        -- DQ03 Validity : speed physically plausible
        (average_speed_kmh is not null
         and (average_speed_kmh > speed_limit_kmh * {{ var('speed_tolerance_factor') }}
              or average_speed_kmh <= 0))                                     as dq03_speed_invalid,

        -- DQ04 Validity : counts non negative
        (least(coalesce(vehicle_count,0), coalesce(car_count,0), coalesce(bus_count,0),
               coalesce(hgv_count,0), coalesce(motorcycle_count,0),
               coalesce(van_count,0)) < 0)                                    as dq04_negative_count,

        -- DQ05 Consistency : class counts reconcile
        (vehicle_count is not null and car_count is not null and bus_count is not null
         and hgv_count is not null and motorcycle_count is not null and van_count is not null
         and vehicle_count <> car_count + bus_count + hgv_count
                                       + motorcycle_count + van_count)        as dq05_sum_mismatch,

        -- DQ06 Accuracy : dead-zero sensor during the active window
        (vehicle_count = 0 and hour_of_day between 6 and 20)                  as dq06_dead_zero,

        -- DQ07 Accuracy : implausible flow spike
        (vehicle_count is not null and median_flow is not null
         and vehicle_count > {{ var('spike_multiple') }} * median_flow)       as dq07_flow_spike,

        -- DQ08 Uniqueness : duplicate site-hour reading
        (site_hour_reading_count > 1)                                         as dq08_duplicate_group,
        (site_hour_sequence > 1)                                              as dq08_surplus_copy,

        -- DQ10 Timeliness : inside the declared reporting window
        (observation_date < date '{{ var("period_start") }}'
         or observation_date > date '{{ var("period_end") }}')                as dq10_out_of_window

    from joined
)

select
    *,
    -- Error-severity rules drive quarantine
    (dq01_traffic_null or dq03_speed_invalid or dq04_negative_count
     or dq05_sum_mismatch or dq06_dead_zero or dq08_surplus_copy
     or dq10_out_of_window)                                                   as dq_is_quarantined,

    -- Warning-severity rules are flagged but retained
    (dq02_environment_null or dq07_flow_spike)                                as dq_has_warning,

    case
        when dq10_out_of_window   then 'DQ10 Out of reporting window'
        when dq08_surplus_copy    then 'DQ08 Duplicate site-hour reading'
        when dq04_negative_count  then 'DQ04 Negative vehicle count'
        when dq05_sum_mismatch    then 'DQ05 Class counts do not reconcile'
        when dq03_speed_invalid   then 'DQ03 Implausible speed'
        when dq06_dead_zero       then 'DQ06 Dead-zero sensor'
        when dq01_traffic_null    then 'DQ01 Missing traffic measure'
        when dq07_flow_spike      then 'DQ07 Implausible flow spike'
        when dq02_environment_null then 'DQ02 Missing environmental measure'
        else 'Passed'
    end                                                                       as dq_primary_failure,

    case
        when (dq01_traffic_null or dq03_speed_invalid or dq04_negative_count
              or dq05_sum_mismatch or dq06_dead_zero or dq08_surplus_copy
              or dq10_out_of_window) then 'Quarantined'
        when (dq02_environment_null or dq07_flow_spike) then 'Accepted with warning'
        else 'Accepted'
    end                                                                       as dq_disposition
from flagged
