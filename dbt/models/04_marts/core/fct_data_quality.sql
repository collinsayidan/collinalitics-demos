{{ config(materialized='table', tags=['fact','dq'],
   description='Data quality fact at source-record grain, covering the entire raw population including quarantined rows. Drives the Data Governance dashboard and the SLA reporting on detector reliability.') }}

select
    d.record_id                                                as observation_id,
    cast(strftime(d.observation_date, '%Y%m%d') as integer)    as date_key,
    d.hour_of_day                                              as time_key,
    s.site_key,
    ss.sensor_status_key,
    d.observation_date,
    d.city_name,
    d.road_id,
    d.sensor_status,
    d.dq_disposition,
    d.dq_primary_failure,
    case when d.dq_is_quarantined then 1 else 0 end            as is_quarantined,
    case when d.dq_has_warning    then 1 else 0 end            as has_warning,
    case when d.dq_is_quarantined or d.dq_has_warning then 0 else 1 end as is_fully_conformant,

    case when d.dq01_traffic_null     then 1 else 0 end        as fail_dq01_traffic_null,
    case when d.dq02_environment_null then 1 else 0 end        as fail_dq02_environment_null,
    case when d.dq03_speed_invalid    then 1 else 0 end        as fail_dq03_speed_invalid,
    case when d.dq04_negative_count   then 1 else 0 end        as fail_dq04_negative_count,
    case when d.dq05_sum_mismatch     then 1 else 0 end        as fail_dq05_sum_mismatch,
    case when d.dq06_dead_zero        then 1 else 0 end        as fail_dq06_dead_zero,
    case when d.dq07_flow_spike       then 1 else 0 end        as fail_dq07_flow_spike,
    case when d.dq08_surplus_copy     then 1 else 0 end        as fail_dq08_duplicate,
    case when d.dq10_out_of_window    then 1 else 0 end        as fail_dq10_out_of_window,
    1                                                          as record_count
from {{ ref('int_observations_dq') }} d
left join {{ ref('dim_site') }} s          on d.site_natural_key = s.site_natural_key
left join {{ ref('dim_sensor_status') }} ss on d.sensor_status   = ss.sensor_status
