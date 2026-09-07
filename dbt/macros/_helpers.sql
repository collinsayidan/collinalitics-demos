{# ------------------------------------------------------------------ #}
{# Reusable macros. Deliberately dependency-free (no dbt_utils) so the #}
{# project runs in an air-gapped environment without `dbt deps`.       #}
{# ------------------------------------------------------------------ #}

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}


{% macro surrogate_key(field_list) -%}
    md5(cast(
        {%- for f in field_list %}
            coalesce(cast({{ f }} as varchar), '_NULL_')
            {%- if not loop.last %} || '||' || {% endif -%}
        {%- endfor %}
    as varchar))
{%- endmacro %}


{% macro safe_divide(numerator, denominator) -%}
    case when coalesce({{ denominator }}, 0) = 0 then null
         else ({{ numerator }}) / nullif({{ denominator }}, 0) end
{%- endmacro %}


{% macro congestion_band(jti_column) -%}
    case
        when {{ jti_column }} is null then 'Unknown'
        when {{ jti_column }} >= {{ var('jti_severe_threshold') }} then 'Severe'
        when {{ jti_column }} >= {{ var('jti_high_threshold')   }} then 'High'
        when {{ jti_column }} >= {{ var('jti_medium_threshold') }} then 'Medium'
        else 'Low'
    end
{%- endmacro %}


{% macro appraisal_param(code) -%}
    (select parameter_value from {{ ref('ref_appraisal_parameters') }}
      where parameter_code = '{{ code }}')
{%- endmacro %}


{% macro cents(expr) -%}
    round(cast({{ expr }} as double), 2)
{%- endmacro %}
