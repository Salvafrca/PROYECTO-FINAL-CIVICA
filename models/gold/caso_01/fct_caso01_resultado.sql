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
-- =====================================================================

with resultado as (

    select * from {{ ref('slv_resultado') }}
    where tiempo_total_seg is not null

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
        r.tiempo_total_seg / c.numero_vueltas                                   as vuelta_media_seg
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
    vuelta_media_seg < vuelta_media_carrera_seg                                 as es_rapido
from con_media_carrera