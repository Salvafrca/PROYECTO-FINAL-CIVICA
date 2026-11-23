-- =====================================================================
-- agg_caso02_podio_cruzado
-- Caso de uso 2, tabla 2x2: tasa de podio cruzando los dos factores.
--
-- agg_caso02_podio mide cada factor por separado. Aquí se fija uno para
-- medir el otro (como se fija una variable en un experimento):
--   efecto del mecánico  = tasa con mecánico - tasa sin mecánico, con el MISMO coche
--   efecto del coche     = tasa coche no viejo - tasa coche viejo, con el MISMO mecánico
-- Una fila por casilla de la tabla 2x2 (4 grupos).
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

grupos as (

    select
        tiene_mecanico,
        coche_no_viejo,
        count(*)                                        as participaciones,
        count_if(es_podio)                              as podios,
        100 * count_if(es_podio) / count(*)             as tasa_podio_pct
    from hechos
    group by tiene_mecanico, coche_no_viejo

)

select
    iff(tiene_mecanico, 'Con mecánico', 'Sin mecánico')         as mecanico,
    iff(coche_no_viejo, 'Coche no viejo', 'Coche viejo')        as coche,
    tiene_mecanico,
    coche_no_viejo,
    participaciones,
    podios,
    round(tasa_podio_pct, 2)                                    as tasa_podio_pct,
    -- Efecto del mecánico manteniendo fijo el tipo de coche (solo en la fila "con mecánico")
    round(tasa_podio_pct - lag(tasa_podio_pct) over (
            partition by coche_no_viejo order by tiene_mecanico), 2)
                                                                as efecto_mecanico_pp,
    -- Efecto del coche no viejo manteniendo fijo el mecánico (solo en la fila "coche no viejo")
    round(tasa_podio_pct - lag(tasa_podio_pct) over (
            partition by tiene_mecanico order by coche_no_viejo), 2)
                                                                as efecto_coche_no_viejo_pp
from grupos
order by tiene_mecanico desc, coche_no_viejo desc