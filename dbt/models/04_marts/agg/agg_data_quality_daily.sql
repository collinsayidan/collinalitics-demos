{{ config(materialized='table', tags=['agg','dq'],
   description='Daily data quality scorecard by site. Supports the governance dashboard, the detector maintenance backlog and the monthly SLA report to the operating companies.') }}

select
    q.date_key,
    d.full_date,
    d.year_month,
    q.site_key,
    s.site_code,
    s.city_name,
    s.road_id,
    s.operating_unit,
    q.sensor_status,

    count(*)                                                  as records_received,
    sum(q.is_fully_conformant)                                as records_conformant,
    sum(q.is_quarantined)                                     as records_quarantined,
    sum(q.has_warning)                                        as records_with_warning,
    round(100.0 * sum(q.is_fully_conformant) / count(*), 2)   as conformance_rate_pct,
    round(100.0 * sum(q.is_quarantined)      / count(*), 2)   as quarantine_rate_pct,

    sum(q.fail_dq01_traffic_null)      as fail_dq01,
    sum(q.fail_dq02_environment_null)  as fail_dq02,
    sum(q.fail_dq03_speed_invalid)     as fail_dq03,
    sum(q.fail_dq04_negative_count)    as fail_dq04,
    sum(q.fail_dq05_sum_mismatch)      as fail_dq05,
    sum(q.fail_dq06_dead_zero)         as fail_dq06,
    sum(q.fail_dq07_flow_spike)        as fail_dq07,
    sum(q.fail_dq08_duplicate)         as fail_dq08
from {{ ref('fct_data_quality') }} q
join {{ ref('dim_date') }} d on q.date_key = d.date_key
left join {{ ref('dim_site') }} s on q.site_key = s.site_key
group by 1,2,3,4,5,6,7,8,9
