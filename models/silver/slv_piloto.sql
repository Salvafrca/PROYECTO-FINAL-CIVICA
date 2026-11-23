-- =====================================================================
-- slv_piloto
-- Capa: silver (3FN). Grano: un piloto.
-- Moda de cada atributo entre todas sus carreras: recupera licencias,
-- emails, teléfonos, maletas y mecánico que faltaban en algunas filas.
-- El club del piloto se guarda como clave foránea a slv_club
-- (NULL = piloto independiente).
-- =====================================================================

with base as (

    select * from {{ ref('int_set_up__limpio') }}

),

clubes as (

    select id_club, nombre from {{ ref('slv_club') }}

),

piloto as (

    select
        id_piloto                   as id_piloto_origen,
        mode(licencia)              as licencia,
        mode(nombre_piloto)         as nombre,
        mode(email)                 as email,
        mode(telefono)              as telefono,
        mode(nombre_club_piloto)    as nombre_club_piloto,
        mode(maleta)                as maleta,
        mode(tiene_mecanico)        as mecanico
    from base
    group by id_piloto

)

select
    {{ dbt_utils.generate_surrogate_key(['p.id_piloto_origen']) }} as id_piloto,
    p.id_piloto_origen,
    p.licencia,
    p.nombre,
    p.email,
    p.telefono,
    c.id_club,                                  -- FK a slv_club; NULL = independiente
    p.nombre_club_piloto,                       -- se conserva para comprobar el cruce
    p.maleta,
    p.mecanico
from piloto p
left join clubes c
    on p.nombre_club_piloto = c.nombre