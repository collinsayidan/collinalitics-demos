{{ config(materialized='table', tags=['dim'],
   description='Congestion severity dimension with the Journey Time Index bands, presentation colours and the operational response expected at each level.') }}

select * from (
    values
      (1, 'Low',    1.00, {{ var('jti_medium_threshold') }}, '#2E7D32', 'Free flow or near free flow. No intervention required.',                 0),
      (2, 'Medium', {{ var('jti_medium_threshold') }}, {{ var('jti_high_threshold') }},  '#F9A825', 'Journey times 15 to 45 per cent above free flow. Monitor.',   0),
      (3, 'High',   {{ var('jti_high_threshold') }},   {{ var('jti_severe_threshold') }},'#EF6C00', 'Journey times 45 to 100 per cent above free flow. Active traffic management triggered.', 1),
      (4, 'Severe', {{ var('jti_severe_threshold') }}, 99.00, '#C62828', 'Journey times at least double free flow. Incident response and variable message signing.', 1)
) as t(congestion_key, congestion_level, jti_lower_bound, jti_upper_bound,
       display_colour_hex, operational_response, is_target_breach)
