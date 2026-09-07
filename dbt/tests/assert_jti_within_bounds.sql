-- Journey Time Index is bounded below at free flow by definition.
select observation_id
from {{ ref('fct_traffic_observation') }}
where journey_time_index < 1.0 or journey_time_index > 12.0
