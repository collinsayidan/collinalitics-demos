-- Rule 1: total flow must equal the sum of the five vehicle classes.
-- Any row returned by this query is a failure.
select observation_id
from {{ ref('fct_traffic_observation') }}
where vehicle_count <> car_count + bus_count + hgv_count
                      + motorcycle_count + van_count
