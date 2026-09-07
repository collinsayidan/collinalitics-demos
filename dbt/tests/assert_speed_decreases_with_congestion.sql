-- Business rule: mean speed must fall monotonically as congestion worsens.
with ranked as (
    select c.congestion_key,
           avg(f.average_speed_kmh) as mean_speed
    from {{ ref('fct_traffic_observation') }} f
    join {{ ref('dim_congestion') }} c on f.congestion_key = c.congestion_key
    group by 1
),
paired as (
    select congestion_key, mean_speed,
           lag(mean_speed) over (order by congestion_key) as prior_speed
    from ranked
)
select * from paired
where prior_speed is not null and mean_speed >= prior_speed
