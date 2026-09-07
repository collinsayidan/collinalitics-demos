{{ config(materialized='table', tags=['dim'],
   description='Incident type dimension including the responsible operational owner and whether the incident is reportable under road safety statistics.') }}

select * from (
    values
      (1, 'None',           'No incident',      0, 0, 'Not applicable',          0),
      (2, 'Collision',      'Collision',        1, 1, 'Police Scotland / Trunk Road Operating Company', 4),
      (3, 'Breakdown',      'Non-collision',    1, 0, 'Trunk Road Operating Company', 2),
      (4, 'Debris',         'Non-collision',    1, 0, 'Trunk Road Operating Company', 2),
      (5, 'Severe Weather', 'Environmental',    1, 0, 'Traffic Scotland Control Centre', 3),
      (6, 'Vehicle Fire',   'Non-collision',    1, 0, 'Scottish Fire and Rescue Service', 4)
) as t(incident_key, incident_type, incident_category, is_disruptive,
       is_reportable_casualty_event, response_owner, severity_rank)
