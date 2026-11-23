-- =====================================================================
-- agg_caso02_podio
-- Respuesta al caso de uso 2:
--   ¿Qué influye más a los pilotos para hacer podio: tener mecánico o que
--   el coche NO sea viejo?
--
-- Método: tasa de podio (podios / participaciones) de cada grupo y la
-- diferencia en puntos porcentuales entre tener y no tener el factor.
-- El factor con mayor diferencia es el que más influye.
-- =====================================================================

with hechos as (

    select
        f.es_podio,
        p.tiene_mecanico,
        not c.es_viejo                  as coche_no_viejo
    from {{ ref('fct_caso02_resultado') }} f
    join {{ ref('dim_caso02_piloto') }} p on f.key_piloto = p.key_piloto
    join {{ ref('dim_caso02_coche') }}  c on f.key_coche  = c.key_coche

),

factores as (

    select
        'Tener mecánico'                                                        as factor,
        count_if(tiene_mecanico)                                                as participaciones_con,
        count_if(tiene_mecanico and es_podio)                                   as podios_con,
        count_if(not tiene_mecanico)                                            as participaciones_sin,
        count_if(not tiene_mecanico and es_podio)                               as podios_sin
    from hechos

    union all

    select
        'Coche no viejo',
        count_if(coche_no_viejo),
        count_if(coche_no_viejo and es_podio),
        count_if(not coche_no_viejo),
        count_if(not coche_no_viejo and es_podio)
    from hechos

)

select
    factor,
    participaciones_con,
    podios_con,
    round(100 * podios_con / nullif(participaciones_con, 0), 2)                 as tasa_podio_con_pct,
    participaciones_sin,
    podios_sin,
    round(100 * podios_sin / nullif(participaciones_sin, 0), 2)                 as tasa_podio_sin_pct,
    round(100 * podios_con / nullif(participaciones_con, 0)
        - 100 * podios_sin / nullif(participaciones_sin, 0), 2)                 as diferencia_pp,
    rank() over (order by
        100 * podios_con / nullif(participaciones_con, 0)
      - 100 * podios_sin / nullif(participaciones_sin, 0) desc)                 as ranking
from factores
order by ranking