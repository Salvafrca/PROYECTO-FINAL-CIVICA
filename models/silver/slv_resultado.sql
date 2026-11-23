-- =====================================================================
-- slv_resultado
-- Capa: silver (3FN). Grano: el set-up de un coche en una carrera.
-- Los atributos del set-up son propios de cada fila: ya vienen limpios
-- del intermedio (reglas de unidades) y los que no se pueden recuperar
-- se quedan a NULL (decisiones 8, 10 y 11).
-- No se guardan derivados (vuelta media, posición): se calculan en gold.
--
-- Incremental (Día 2 y Día 5): es la tabla que crece con cada carrera.
-- Solo procesa las filas que han llegado a bronze después de la última
-- ejecución (_loaded_at) y hace merge por id_resultado: si el set-up ya
-- existe lo actualiza, si no lo inserta.
-- Sin lookback: _loaded_at lo pone Snowflake al cargar, no hay datos tardíos.
-- =====================================================================

{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='id_resultado',
    on_schema_change='append_new_columns'
) }}

with base as (

    select * from {{ ref('int_set_up__limpio') }}

    {% if is_incremental() %}
    -- solo lo llegado después de la última carga ya procesada
    where _loaded_at > (select max(_loaded_at) from {{ this }})
    {% endif %}

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
    tiempo_total_seg,
    -- Metadato de carga (lo usa el filtro incremental)
    _loaded_at
from base