-- =====================================================================
-- fct_caso02_resultado
-- Caso de uso 2. Grano: el resultado de un piloto (coche) en una carrera.
--
-- Medidas:
--   posicion  = orden por tiempo total dentro de la carrera (sin empates)
--   es_podio  = posicion <= 3
-- Los set-ups sin tiempo total (decisión 10) no se pueden clasificar y se excluyen.
--
-- Incremental (Día 5): delete+insert por carrera. La posición depende de
-- todos los pilotos de la carrera, así que un set-up nuevo o corregido
-- obliga a reclasificar su carrera ENTERA (se borra y se reinserta).
-- =====================================================================

{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key='key_carrera',
    on_schema_change='append_new_columns'
) }}

with resultado as (

    select * from {{ ref('slv_resultado') }}
    where tiempo_total_seg is not null
    {% if is_incremental() %}
      and id_carrera in (
          select id_carrera
          from {{ ref('slv_resultado') }}
          where _loaded_at > (select max(_loaded_at) from {{ this }})
      )
    {% endif %}

),

coche as (

    select id_coche, id_piloto from {{ ref('slv_coche') }}

),

clasificado as (

    select
        r.id_resultado,
        r.id_carrera,
        r.id_coche,
        co.id_piloto,
        r.tiempo_total_seg,
        row_number() over (partition by r.id_carrera
                           order by r.tiempo_total_seg)        as posicion,  -- no se consideran empates
        r._loaded_at
    from resultado r
    join coche co
        on r.id_coche = co.id_coche

)

select
    id_resultado        as key_resultado,
    id_carrera          as key_carrera,
    id_coche            as key_coche,
    id_piloto           as key_piloto,
    tiempo_total_seg,
    posicion,
    posicion <= 3       as es_podio,
    _loaded_at          -- cuándo llegó el set-up a bronze
from clasificado