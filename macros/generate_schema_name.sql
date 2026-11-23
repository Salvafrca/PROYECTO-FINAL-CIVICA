-- =====================================================================
-- generate_schema_name: override de Cívica (Día 6).
-- Decide en qué esquema se crea cada modelo:
--   - Jobs de los entornos dev / pre / pro (target.name) -> el esquema tal cual: silver, caso_01...
--   - Jobs de CI                                         -> con prefijo: dbt_jobs_silver
--   - Desarrollo en el IDE (target default)              -> con prefijo personal: dbt_sfranco_silver
-- Así en PRO los esquemas se llaman igual que la capa, y en desarrollo
-- cada persona trabaja en los suyos sin pisar a nadie.
-- =====================================================================

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- set invocation_context = env_var('DBT_CLOUD_INVOCATION_CONTEXT', '') -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif invocation_context != 'ci' and target.name in ['dev', 'pre', 'pro'] -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}