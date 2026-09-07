{{ config(materialized='table', tags=['dim'],
   description='Detector site dimension. One row per physical sensor location, enriched with strategic road network attributes from the reference seed and a derived urbanisation band based on distance from the city centroid.') }}

with site_base as (
    select
        site_natural_key,
        max(road_id)                        as road_id,
        max(road_type)                      as road_type,
        max(city_name)                      as city_name,
        max(council_area)                   as council_area,
        max(latitude)                       as latitude,
        max(longitude)                      as longitude,
        max(speed_limit_kmh)                as speed_limit_kmh,
        median(segment_length_km)           as segment_length_km,
        count(*)                            as source_observation_count,
        min(observation_date)               as first_observed_date,
        max(observation_date)               as last_observed_date
    from {{ ref('stg_its__observations') }}
    group by 1
),

city_centroid as (
    select city_name, avg(latitude) as centroid_lat, avg(longitude) as centroid_lon
    from site_base group by 1
),

distanced as (
    select
        s.*,
        -- haversine distance from the city centroid, kilometres
        6371.0 * 2 * asin(sqrt(
            pow(sin(radians(s.latitude - c.centroid_lat) / 2), 2)
          + cos(radians(c.centroid_lat)) * cos(radians(s.latitude))
          * pow(sin(radians(s.longitude - c.centroid_lon) / 2), 2)
        )) as km_from_city_centroid
    from site_base s
    join city_centroid c on s.city_name = c.city_name
)

select
    {{ surrogate_key(['d.site_natural_key']) }}                       as site_key,
    d.site_natural_key,
    d.road_id || '-' || upper(substr(d.city_name, 1, 3)) || '-'
      || lpad(cast(row_number() over (
             partition by d.road_id, d.city_name order by d.latitude) as varchar), 2, '0')
                                                                      as site_code,
    d.city_name,
    d.council_area,
    d.road_id,
    r.road_name,
    r.corridor,
    r.strategic_function,
    r.operating_unit,
    r.is_anglo_scottish,
    r.design_capacity_band,
    d.road_type,
    d.latitude,
    d.longitude,
    d.speed_limit_kmh,
    round(d.speed_limit_kmh / 1.60934)                                as speed_limit_mph,
    round(d.segment_length_km, 2)                                     as segment_length_km,
    round(d.km_from_city_centroid, 2)                                 as km_from_city_centroid,
    case when d.km_from_city_centroid < 6  then 'Urban Core'
         when d.km_from_city_centroid < 13 then 'Suburban'
         else 'Inter Urban' end                                       as urbanisation_band,
    case when d.city_name in ('Glasgow','Edinburgh') then 'Major Conurbation'
         when d.city_name in ('Aberdeen','Dundee')   then 'Regional City'
         else 'Smaller City' end                                      as settlement_tier,
    d.source_observation_count,
    d.first_observed_date,
    d.last_observed_date
from distanced d
left join {{ ref('ref_road_network') }} r on d.road_id = r.road_id
