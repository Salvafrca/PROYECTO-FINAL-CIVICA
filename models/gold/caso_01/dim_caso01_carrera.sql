-- =====================================================================
-- dim_caso01_carrera
-- Caso de uso 1. Dimensión carrera: fecha y condiciones del día.
-- La condición filtra las carreras con lluvia; la temperatura se conserva
-- porque distingue dos carreras con lluvia en el mismo circuito.
-- =====================================================================

select
    id_carrera      as key_carrera,
    fecha,
    condicion,
    temperatura,
    numero_vueltas
from {{ ref('slv_carrera') }}