-- =====================================================================
-- fct_caso02_resultado
-- Caso de uso 2. Grano: el resultado de un piloto (coche) en una carrera.
--
-- Medidas:
--   posicion  = orden por tiempo total dentro de la carrera (sin empates)
--   es_podio  = posicion <= 3
-- Los set-ups sin tiempo total (decisión 10) no se pueden clasificar y se excluyen.
-- =====================================================================

with resultado as (

    select * from {{ ref('slv_resultado') }}
    where tiempo_total_seg is not null

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
                           order by r.tiempo_total_seg)        as posicion   -- no se consideran empates
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
    posicion <= 3       as es_podio
from clasificado