{{ config(materialized='table', tags=['dim'],
   description='Conformed calendar dimension covering the full reporting window. Includes UK fiscal year (April to March), meteorological season and a school-holiday attribute sourced from the detector feed.') }}

with spine as (
    select unnest(generate_series(
        date '{{ var("period_start") }}',
        date '{{ var("period_end") }}',
        interval 1 day
    ))::date as full_date
),

holidays as (
    select observation_date, max(school_holiday_flag) as school_holiday_flag
    from {{ ref('stg_its__observations') }}
    group by 1
)

select
    cast(strftime(s.full_date, '%Y%m%d') as integer)          as date_key,
    s.full_date,
    extract(year   from s.full_date)                          as calendar_year,
    extract(month  from s.full_date)                          as month_number,
    strftime(s.full_date, '%B')                               as month_name,
    strftime(s.full_date, '%b')                               as month_short_name,
    strftime(s.full_date, '%Y-%m')                            as year_month,
    strftime(s.full_date, '%b %Y')                            as month_year_label,
    'Q' || cast(extract(quarter from s.full_date) as varchar) as calendar_quarter,
    extract(quarter from s.full_date)                         as quarter_number,
    extract(week   from s.full_date)                          as iso_week_number,
    date_trunc('week',  s.full_date)                          as week_start_date,
    date_trunc('month', s.full_date)                          as month_start_date,
    extract(day    from s.full_date)                          as day_of_month,
    extract(isodow from s.full_date)                          as day_of_week_number,
    strftime(s.full_date, '%A')                               as day_name,
    strftime(s.full_date, '%a')                               as day_short_name,
    case when extract(isodow from s.full_date) >= 6 then 1 else 0 end as is_weekend,
    case when extract(isodow from s.full_date) >= 6 then 'Weekend' else 'Weekday' end as day_type,

    -- UK fiscal year runs April to March
    case when extract(month from s.full_date) >= 4
         then cast(extract(year from s.full_date) as varchar) || '/' ||
              cast(extract(year from s.full_date) + 1 as varchar)
         else cast(extract(year from s.full_date) - 1 as varchar) || '/' ||
              cast(extract(year from s.full_date) as varchar) end     as fiscal_year,
    case when extract(month from s.full_date) in (4,5,6)   then 'FQ1'
         when extract(month from s.full_date) in (7,8,9)   then 'FQ2'
         when extract(month from s.full_date) in (10,11,12) then 'FQ3'
         else 'FQ4' end                                               as fiscal_quarter,

    case when extract(month from s.full_date) in (12,1,2) then 'Winter'
         when extract(month from s.full_date) in (3,4,5)  then 'Spring'
         when extract(month from s.full_date) in (6,7,8)  then 'Summer'
         else 'Autumn' end                                            as meteorological_season,

    coalesce(h.school_holiday_flag, 0)                                as is_school_holiday,
    case when coalesce(h.school_holiday_flag,0) = 1
         then 'School holiday' else 'Term time' end                   as school_period,

    date_diff('day', date '{{ var("period_start") }}', s.full_date)   as days_from_period_start,
    case when s.full_date = last_day(s.full_date) then 1 else 0 end   as is_month_end
from spine s
left join holidays h on s.full_date = h.observation_date
