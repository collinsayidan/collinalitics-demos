{{ config(materialized='table', tags=['dim'],
   description='Detector operating status dimension, used by the asset health dashboard to drive maintenance prioritisation.') }}

select * from (
    values
      (1, 'Active',      1, 'Operational',           'None',   '#2E7D32'),
      (2, 'Maintenance', 0, 'Planned outage',        'Low',    '#F9A825'),
      (3, 'Faulty',      0, 'Unplanned outage',      'High',   '#C62828')
) as t(sensor_status_key, sensor_status, is_operational,
       status_description, maintenance_priority, display_colour_hex)
