{{ config(materialized='table', tags=['ml','fact'],
   description='Machine learning scoring fact. Grain: one row per clean observation. Congestion probabilities come from the operational congestion forecast; collision risk comes from the imbalanced binary risk model. In-sample rows carry cross-validated scores so no row is ever scored by a model that was fitted on it.') }}

with scored as (
    select * from read_parquet('{{ var("ml_output_path") }}/ml_risk_scores.parquet')
)

select
    s.observation_id,
    f.date_key,
    f.time_key,
    f.site_key,
    f.congestion_key                              as actual_congestion_key,
    s.model_version,
    s.data_split,
    s.predicted_congestion_level,
    c.congestion_level                            as actual_congestion_level,
    s.prob_low,
    s.prob_medium,
    s.prob_high,
    s.prob_severe,
    s.prob_congested,
    s.collision_risk_score,
    s.collision_risk_percentile,
    s.collision_risk_decile,
    s.collision_risk_band,
    s.is_congestion_prediction_correct,
    f.accident_flag                               as actual_accident_flag,
    case when s.collision_risk_percentile >= 0.95 then 1 else 0 end as is_priority_risk_hour,
    s.scored_at
from scored s
join {{ ref('fct_traffic_observation') }} f on s.observation_id = f.observation_id
join {{ ref('dim_congestion') }} c on f.congestion_key = c.congestion_key
