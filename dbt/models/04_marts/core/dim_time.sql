{{ config(materialized='table', tags=['dim'],
   description='Hour-of-day dimension carrying the operational time bands used by the Traffic Scotland control room (AM peak, inter peak, PM peak, evening, night).') }}

select
    t.hour_of_day                                             as time_key,
    t.hour_of_day,
    lpad(cast(t.hour_of_day as varchar), 2, '0') || ':00'     as hour_label,
    lpad(cast(t.hour_of_day as varchar), 2, '0') || ':00 - '
      || lpad(cast((t.hour_of_day + 1) % 24 as varchar), 2, '0') || ':00' as hour_range_label,
    t.time_band,
    t.time_band_order,
    t.is_peak,
    case when t.is_peak = 1 then 'Peak' else 'Off peak' end   as peak_flag_label,
    t.peak_direction,
    t.operational_shift,
    case when t.hour_of_day between 6 and 19 then 1 else 0 end as is_daytime
from {{ ref('ref_time_band') }} t
