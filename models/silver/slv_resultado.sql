-- =====================================================================
-- slv_resultado
-- Capa: silver (3FN). Grano: el set-up de un coche en una carrera.
-- Los atributos del set-up son propios de cada fila: ya vienen limpios
-- del intermedio (reglas de unidades) y los que no se pueden recuperar
-- se quedan a NULL (decisiones 8, 10 y 11).
-- No se guardan derivados (vuelta media, posición): se calculan en gold.
-- =====================================================================

with base as (

    select * from {{ ref('int_set_up__limpio') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['id_resultado']) }} as id_resultado,
    id_resultado                                              as id_resultado_origen,
    {{ dbt_utils.generate_surrogate_key(['id_carrera']) }}   as id_carrera,   -- FK a slv_carrera
    {{ dbt_utils.generate_surrogate_key(['id_coche']) }}     as id_coche,     -- FK a slv_coche
    -- Set-up
    neumatico,
    grosor_muelle,
    altura_chasis,
    lleva_contrapesos                                         as contrapesos,
    densidad_silicona_diferencial,
    grado_inclinacion_aleron,
    -- Clasificación
    tiempo_total,
    tiempo_total_seg
from base