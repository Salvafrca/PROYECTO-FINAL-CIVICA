-- =====================================================================
-- dim_caso02_carrera
-- Caso de uso 2. Dimensión carrera: fecha y circuito (desnormalizado).
-- =====================================================================

select
    ca.id_carrera                   as key_carrera,
    ca.fecha,
    cl.nombre                       as nombre_club,
    ca.numero_pilotos
from {{ ref('slv_carrera') }} ca
join {{ ref('slv_club') }} cl
    on ca.id_club = cl.id_club