{{ config(materialized='table', tags=['intermediate','dq'],
   description='Robust per-site, per-hour flow baseline used by the implausible-spike data quality rule. Median and median absolute deviation are used rather than mean and standard deviation because the input deliberately contains outliers, and a mean-based rule would be dragged toward the very values it is meant to detect.') }}

with base as (
    select site_natural_key, hour_of_day, vehicle_count
    from {{ ref('stg_its__observations') }}
    where vehicle_count is not null and vehicle_count >= 0
),

central as (
    select
        site_natural_key,
        hour_of_day,
        count(*)                            as observation_count,
        median(vehicle_count)               as median_flow,
        quantile_cont(vehicle_count, 0.95)  as p95_flow
    from base
    group by 1, 2
),

deviation as (
    select
        b.site_natural_key,
        b.hour_of_day,
        median(abs(b.vehicle_count - c.median_flow)) as mad_flow
    from base b
    join central c
      on b.site_natural_key = c.site_natural_key
     and b.hour_of_day      = c.hour_of_day
    group by 1, 2
)

select
    c.site_natural_key,
    c.hour_of_day,
    c.observation_count,
    c.median_flow,
    c.p95_flow,
    d.mad_flow,
    -- robust upper control limit: median + 6 x scaled MAD
    c.median_flow + 6 * 1.4826 * nullif(d.mad_flow, 0) as robust_upper_limit
from central c
join deviation d
  on c.site_natural_key = d.site_natural_key
 and c.hour_of_day      = d.hour_of_day
