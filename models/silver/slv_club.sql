-- =====================================================================
-- slv_club
-- Capa: silver (modelo en 3FN). Grano: un club.
--
-- Los datos de un club se repiten en todas las filas de sus carreras.
-- Cada atributo se queda con su valor válido más repetido (moda):
-- así se corrigen nulos, valores fuera de lista (Hormigon, Cesped) y
-- longitudes imposibles con los datos del propio club.
-- =====================================================================

with base as (

    select * from {{ ref('int_set_up__limpio') }}

),

club as (

    select
        id_club                     as id_club_origen,   -- clave natural del sistema origen
        mode(nombre_club)           as nombre,
        mode(numero_socios)         as numero_socios,
        mode(numero_curvas)         as numero_curvas,
        mode(numero_saltos)         as numero_saltos,
        mode(superficie)            as superficie,
        mode(longitud_circuito)     as longitud
    from base
    group by id_club

)

select
    {{ dbt_utils.generate_surrogate_key(['id_club_origen']) }} as id_club,   -- clave subrogada
    id_club_origen,
    nombre,
    numero_socios,
    numero_curvas,
    numero_saltos,
    superficie,
    longitud
from club