{{ config(
    materialized = 'view',
    tags = ['staging'],
    description = 'Conformed staging layer: snake_case naming, explicit typing, derived natural keys and a full-precision observation timestamp. One row per source record; nothing is filtered or repaired here.'
) }}

with source as (

    select * from {{ ref('bronze_its_observations') }}

),

renamed as (

    select
        -- ---------- identifiers -------------------------------------
        cast("Record_ID" as varchar)                        as record_id,

        -- ---------- temporal ----------------------------------------
        cast("Date" as date)                                as observation_date,
        cast("Time" as varchar)                             as observation_time_text,
        cast("Date" as date)
            + cast("Time" as time)                          as observation_ts,
        cast("Year"  as integer)                            as observation_year,
        cast("Month" as integer)                            as observation_month,
        cast("Quarter" as varchar)                          as observation_quarter,
        cast("Week"  as integer)                            as iso_week,
        cast("Day_of_Week" as varchar)                      as day_name,
        cast("Hour"  as integer)                            as hour_of_day,

        -- ---------- geography ---------------------------------------
        cast("City" as varchar)                             as city_name,
        cast("Council_Area" as varchar)                     as council_area,
        cast("Road_ID" as varchar)                          as road_id,
        cast("Road_Type" as varchar)                        as road_type,
        cast("Latitude"  as double)                         as latitude,
        cast("Longitude" as double)                         as longitude,

        -- natural key for a physical detector site
        cast("Road_ID" as varchar) || '|'
            || cast(round(cast("Latitude"  as double), 6) as varchar) || '|'
            || cast(round(cast("Longitude" as double), 6) as varchar)
                                                            as site_natural_key,

        -- ---------- traffic volumes ---------------------------------
        cast("Vehicle_Count"     as integer)                as vehicle_count,
        cast("Car_Count"         as integer)                as car_count,
        cast("Bus_Count"         as integer)                as bus_count,
        cast("HGV_Count"         as integer)                as hgv_count,
        cast("Motorcycle_Count"  as integer)                as motorcycle_count,
        cast("Van_Count"         as integer)                as van_count,

        -- ---------- performance -------------------------------------
        cast("Average_Speed_kmh"    as double)              as average_speed_kmh,
        cast("Speed_Limit_kmh"      as integer)             as speed_limit_kmh,
        cast("Congestion_Level"     as varchar)             as congestion_level_src,
        cast("Journey_Time_Minutes" as double)              as journey_time_minutes,
        cast("Journey_Time_Index"   as double)              as journey_time_index,

        -- ---------- environment -------------------------------------
        cast("Temperature_C"   as double)                   as temperature_c,
        cast("Rainfall_mm"     as double)                   as rainfall_mm,
        cast("Wind_Speed_kmh"  as double)                   as wind_speed_kmh,
        cast("Visibility_km"   as double)                   as visibility_km,
        cast("Air_Quality_Index" as integer)                as air_quality_index,
        cast("CO2_Emission_kg" as double)                   as co2_emission_kg,

        -- ---------- events and disruption ---------------------------
        cast("Accident_Flag"       as integer)              as accident_flag,
        cast("Incident_Type"       as varchar)              as incident_type,
        cast("Roadworks_Flag"      as integer)              as roadworks_flag,
        cast("Lane_Closure_Flag"   as integer)              as lane_closure_flag,
        cast("Public_Event_Flag"   as integer)              as public_event_flag,
        cast("Event_Type"          as varchar)              as event_type,
        cast("School_Holiday_Flag" as integer)              as school_holiday_flag,
        cast("Traffic_Sensor_Status" as varchar)            as sensor_status,

        -- ---------- lineage -----------------------------------------
        _dbt_batch_id,
        _ingested_at,
        _source_system

    from source

),

derived as (

    select
        *,
        -- free-flow journey time implied by the observed index
        case when journey_time_index > 0
             then journey_time_minutes / journey_time_index end   as free_flow_journey_time_minutes,

        -- monitored segment length implied by speed and journey time
        case when average_speed_kmh > 0
             then average_speed_kmh * journey_time_minutes / 60.0 end as segment_length_km,

        -- delay above free flow, per vehicle, in minutes
        case when journey_time_index > 0
             then journey_time_minutes - (journey_time_minutes / journey_time_index) end as delay_minutes_per_vehicle,

        case when day_name in ('Saturday','Sunday') then 1 else 0 end as is_weekend,
        case when hour_of_day in (7,8,16,17,18)     then 1 else 0 end as is_peak_hour,
        case when incident_type <> 'None' then 1 else 0 end           as has_incident,
        case when sensor_status = 'Active'  then 1 else 0 end         as is_sensor_active

    from renamed

)

select * from derived
