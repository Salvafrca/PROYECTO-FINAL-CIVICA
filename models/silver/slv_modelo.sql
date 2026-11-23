-- =====================================================================
-- slv_modelo
-- Capa: silver (3FN). Grano: un modelo de coche.
-- Cada atributo, su valor válido más repetido (moda) entre todas las
-- filas del modelo: corrige Bugy, Nitro/Gas, escala 1/10, años imposibles.
-- =====================================================================

with base as (

    select * from {{ ref('int_set_up__limpio') }}

),

modelo as (

    select
        id_modelo                   as id_modelo_origen,
        mode(modelo)                as modelo,
        mode(clase)                 as clase,
        mode(marca)                 as marca,
        mode(escala)                as escala,
        mode(anio_produccion)       as anio_produccion,
        mode(motorizacion)          as motorizacion
    from base
    group by id_modelo

)

select
    {{ dbt_utils.generate_surrogate_key(['id_modelo_origen']) }} as id_modelo,
    id_modelo_origen,
    modelo,
    clase,
    marca,
    escala,
    anio_produccion,
    motorizacion
from modelo