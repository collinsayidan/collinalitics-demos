-- No clean observation may carry a negative physical measure.
select observation_id
from {{ ref('fct_traffic_observation') }}
where least(vehicle_count, car_count, bus_count, hgv_count,
            motorcycle_count, van_count, average_speed_kmh,
            journey_time_minutes) < 0
