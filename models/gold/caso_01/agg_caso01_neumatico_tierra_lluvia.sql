-- =====================================================================
-- agg_caso01_neumatico_tierra_lluvia
-- Respuesta al caso de uso 1:
--   ¿Qué neumático es el más adecuado para ser rápido en un circuito de
--   tierra en condiciones de lluvia?
--
-- Método (guion del proyecto):
--   1. Solo carreras en circuito de Tierra y con condición Lluvia.
--   2. En CADA carrera se cuenta cuántos pilotos rápidos llevaban cada neumático.
--   3. Se suman los contadores de todas las carreras.
--   4. Gana el neumático con mayor contador.
-- Se añade el porcentaje sobre los pilotos que usaron ese neumático, porque
-- un neumático muy usado puede ganar en número sin ser el más eficaz.
-- =====================================================================

with hechos as (

    select f.*
    from {{ ref('fct_caso01_resultado') }} f
    join {{ ref('dim_caso01_club') }}    cl on f.key_club = cl.key_club
    join {{ ref('dim_caso01_carrera') }} ca on f.key_carrera = ca.key_carrera
    where cl.superficie = 'Tierra'
      and ca.condicion = 'Lluvia'
      and f.neumatico is not null

),

-- Paso 2: contador por carrera y neumático
por_carrera as (

    select
        key_carrera,
        neumatico,
        count_if(es_rapido)     as pilotos_rapidos,
        count(*)                as pilotos
    from hechos
    group by key_carrera, neumatico

)

-- Paso 3 y 4: suma de los contadores de todas las carreras y ranking
select
    neumatico,
    count(distinct key_carrera)                                     as carreras,
    sum(pilotos_rapidos)                                            as pilotos_rapidos,
    sum(pilotos)                                                    as pilotos_con_neumatico,
    round(100 * sum(pilotos_rapidos) / nullif(sum(pilotos), 0), 1)  as pct_rapidos,
    rank() over (order by sum(pilotos_rapidos) desc)                as ranking
from por_carrera
group by neumatico
order by ranking