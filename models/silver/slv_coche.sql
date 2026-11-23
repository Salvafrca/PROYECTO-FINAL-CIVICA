-- =====================================================================
-- slv_coche
-- Capa: silver (3FN). Grano: un coche (un modelo concreto de un piloto).
-- El estado no varía a lo largo de la temporada (decisión 4): se toma
-- la moda de todas las carreras del coche.
-- =====================================================================

with base as (

    select * from {{ ref('int_set_up__limpio') }}

),

coche as (

    select
        id_coche                    as id_coche_origen,
        mode(id_piloto)             as id_piloto_origen,
        mode(id_modelo)             as id_modelo_origen,
        mode(estado_coche)          as estado
    from base
    group by id_coche

)

select
    {{ dbt_utils.generate_surrogate_key(['id_coche_origen']) }}  as id_coche,
    id_coche_origen,
    {{ dbt_utils.generate_surrogate_key(['id_piloto_origen']) }} as id_piloto,   -- FK a slv_piloto
    {{ dbt_utils.generate_surrogate_key(['id_modelo_origen']) }} as id_modelo,   -- FK a slv_modelo
    estado
from coche