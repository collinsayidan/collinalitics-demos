-- Every source record must appear exactly once in the data quality fact.
with src as (select count(*) as n from {{ ref('stg_its__observations') }}),
dq  as (select count(*) as n from {{ ref('fct_data_quality') }})
select 'population mismatch' as failure
from src cross join dq where src.n <> dq.n
