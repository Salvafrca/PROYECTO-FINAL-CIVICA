-- =====================================================================
-- slv_carrera
-- Capa: silver (3FN). Grano: una carrera (club + fecha).
-- Las ~25 filas de una carrera comparten la meteorología: la moda de
-- cada atributo corrige temperaturas imposibles (999), humedades fuera
-- de 0-100, vientos negativos y condiciones fuera de lista o vacías.
-- =====================================================================

with base as (

    select * from {{ ref('int_set_up__limpio') }}

),

carrera as (

    select
        id_carrera                  as id_carrera_origen,
        mode(id_club)               as id_club_origen,
        mode(fecha_carrera)         as fecha,
        mode(numero_vueltas)        as numero_vueltas,
        mode(numero_pilotos)        as numero_pilotos,
        mode(temperatura)           as temperatura,
        mode(humedad)               as humedad,
        mode(condicion_meteo)       as condicion,
        mode(viento)                as viento
    from base
    group by id_carrera

)

select
    {{ dbt_utils.generate_surrogate_key(['id_carrera_origen']) }} as id_carrera,
    id_carrera_origen,
    {{ dbt_utils.generate_surrogate_key(['id_club_origen']) }}    as id_club,    -- FK a slv_club
    fecha,
    numero_vueltas,
    numero_pilotos,
    temperatura,
    humedad,
    condicion,
    viento
from carrera