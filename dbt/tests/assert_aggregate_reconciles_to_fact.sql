-- The daily aggregate must reproduce the fact table totals exactly.
with f as (
    select count(*) as n, sum(vehicle_count) as v, round(sum(delay_cost_gbp),2) as c
    from {{ ref('fct_traffic_observation') }}
),
a as (
    select sum(observation_count) as n, sum(total_vehicles) as v,
           round(sum(delay_cost_gbp),2) as c
    from {{ ref('agg_network_daily') }}
)
select 'mismatch' as failure
from f cross join a
where f.n <> a.n or f.v <> a.v or abs(f.c - a.c) > 0.05
