{{ config(materialized='table', tags=['intermediate','statistics'],
   description='Survey-style expansion factors. The detector feed is a sample of site-hours, not a census, so every monetised figure must be grossed up before it can be read as a network total. weight = hours in the reporting period / clean observations available for that site.') }}

with clean as (
    select site_natural_key, count(*) as clean_observation_count
    from {{ ref('int_observations_clean') }}
    group by 1
)

select
    site_natural_key,
    clean_observation_count,
    {{ var('period_hours') }}                                       as period_hours,
    cast({{ var('period_hours') }} as double) / clean_observation_count as expansion_factor,
    cast({{ var('period_hours') }} as double)
        / clean_observation_count / {{ var('period_years') }}        as annualisation_factor,
    round(100.0 * clean_observation_count / {{ var('period_hours') }}, 3) as sampling_rate_pct
from clean
