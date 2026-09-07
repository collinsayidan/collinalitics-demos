{{ config(materialized='table', tags=['ml'],
   description='Model evaluation register. Every published metric is stored with its data split and model version so dashboard consumers can see exactly how the model was validated rather than taking a single headline number on trust.') }}

select
    row_number() over (order by model_name, data_split, metric_name) as metric_key,
    model_name,
    model_version,
    data_split,
    metric_name,
    metric_value,
    note,
    training_rows,
    test_rows,
    trained_at,
    case
        when metric_name like 'Recall%'    then 'Recall'
        when metric_name like 'Precision%' then 'Precision'
        when metric_name like 'Capture%'   then 'Capture'
        when metric_name like 'Lift%'      then 'Lift'
        else metric_name
    end                                                             as metric_family
from read_parquet('{{ var("ml_output_path") }}/ml_model_metrics.parquet')
