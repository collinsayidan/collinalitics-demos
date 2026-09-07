{{ config(
    materialized = 'table',
    tags = ['bronze','ingestion'],
    description = 'Immutable landing copy of the raw ITS detector feed with ingestion lineage columns appended. No business logic, no filtering, no type coercion beyond what the reader infers.'
) }}

select
    *,
    '{{ invocation_id }}'                       as _dbt_batch_id,
    current_timestamp                           as _ingested_at,
    'scotland_its_dataset.csv'                  as _source_file,
    'ITS_DETECTOR_FEED'                         as _source_system
from {{ source('its_raw', 'scotland_its_dataset') }}
