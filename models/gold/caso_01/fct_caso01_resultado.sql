-- =====================================================================
-- fct_caso01_resultado
-- Caso de uso 1. Grano: el tiempo de un piloto (coche) en una carrera.
--
-- Medidas:
--   vuelta_media_seg          = tiempo_total_seg / numero_vueltas   (del piloto)
--   vuelta_media_carrera_seg  = media de las vueltas medias de los pilotos
--                               de ESA carrera (nunca se mezclan carreras)
--   es_rapido                 = vuelta media del piloto < vuelta media de su carrera
--
-- Se excluyen los set-ups sin tiempo total (decisión 10): sin tiempo no hay
-- vuelta media. El neumático se guarda como dimensión degenerada.
--
-- Incremental (Día 5): delete+insert por carrera. La vuelta media de la
-- carrera depende de todos sus pilotos, así que si llega un set-up nuevo o
-- corregido se reprocesa su carrera ENTERA: se borran sus filas y se
-- insertan recalculadas. Carreras afectadas = las que tienen algún set-up
-- llegado a bronze después de la última carga de esta tabla (_loaded_at).
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

carrera as (

    select id_carrera, id_club, numero_vueltas from {{ ref('slv_carrera') }}

),

vueltas as (

    select
        r.id_resultado,
        r.id_carrera,
        c.id_club,
        r.neumatico,
        r.tiempo_total_seg,
        c.numero_vueltas,
        r.tiempo_total_seg / c.numero_vueltas                                   as vuelta_media_seg,
        r._loaded_at
    from resultado r
    join carrera c
        on r.id_carrera = c.id_carrera

),

con_media_carrera as (

    select
        *,
        avg(vuelta_media_seg) over (partition by id_carrera)                    as vuelta_media_carrera_seg
    from vueltas

)

select
    id_resultado                                                                as key_resultado,
    id_carrera                                                                  as key_carrera,
    id_club                                                                     as key_club,
    neumatico,                                                                  -- dimensión degenerada
    tiempo_total_seg,
    numero_vueltas,
    round(vuelta_media_seg, 3)                                                  as vuelta_media_seg,
    round(vuelta_media_carrera_seg, 3)                                          as vuelta_media_carrera_seg,
    -- Mismo dato en formato mm:ss.sss para leerlo cómodamente
    time_from_parts(0, 0, floor(vuelta_media_seg),
                    round((vuelta_media_seg - floor(vuelta_media_seg)) * 1e9))  as vuelta_media,
    vuelta_media_seg < vuelta_media_carrera_seg                                 as es_rapido,
    _loaded_at                                                                  -- cuándo llegó el set-up a bronze
from con_media_carrera