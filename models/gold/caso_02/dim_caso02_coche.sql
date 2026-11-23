-- =====================================================================
-- dim_caso02_coche
-- Caso de uso 2. Dimensión coche: estado y si es viejo.
-- Se desnormaliza el nombre del modelo (estrella, no copo de nieve).
-- =====================================================================

select
    co.id_coche                     as key_coche,
    mo.modelo,
    mo.marca,
    co.estado,
    co.estado = 'Viejo'             as es_viejo
from {{ ref('slv_coche') }} co
join {{ ref('slv_modelo') }} mo
    on co.id_modelo = mo.id_modelo