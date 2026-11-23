-- =====================================================================
-- dim_caso02_piloto
-- Caso de uso 2: ¿qué influye más para hacer podio, tener mecánico o que
-- el coche NO sea viejo? Dimensión piloto: nombre y si tiene mecánico.
-- =====================================================================

select
    id_piloto       as key_piloto,
    nombre          as nombre_piloto,
    licencia,
    mecanico        as tiene_mecanico
from {{ ref('slv_piloto') }}