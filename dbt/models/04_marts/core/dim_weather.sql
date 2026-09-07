{{ config(materialized='table', tags=['dim'],
   description='Weather severity dimension. Bands are derived from combined rainfall, visibility, wind and temperature thresholds aligned to winter service decision making.') }}

select * from (
    values
      (1, 'Benign',  'No material weather impact expected',                              '#2E7D32', 0),
      (2, 'Adverse', 'Rain, reduced visibility, strong wind or near-freezing conditions', '#F9A825', 1),
      (3, 'Severe',  'Heavy rain, fog, gale force wind or sub-zero surface conditions',   '#C62828', 1)
) as t(weather_key, weather_severity_band, band_description,
       display_colour_hex, triggers_winter_service)
