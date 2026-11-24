-- =====================================================================
-- dim_caso02_piloto_historia
-- Caso de uso 2. Historia del piloto (SCD tipo 2) a partir de piloto_snapshot.
-- dim_caso02_piloto guarda el estado actual; esta tabla guarda todas las
-- versiones y desde cuándo hasta cuándo fue válida cada una.
-- Se expone en gold para que Power BI la lea con REPORTING_ROLE, que no
-- tiene acceso a silver ni al snapshot (mínimo privilegio).
-- Las fechas del snapshot van en UTC: se pasan a hora de Madrid.
-- =====================================================================

select
    dbt_scd_id                                                          as key_version,
    id_piloto                                                           as key_piloto,
    nombre                                                              as nombre_piloto,
    licencia,
    coalesce(nombre_club_piloto, 'Independiente')                       as club,
    mecanico                                                            as tiene_mecanico,
    convert_timezone('UTC', 'Europe/Madrid', dbt_valid_from)::timestamp_ntz as valido_desde,
    convert_timezone('UTC', 'Europe/Madrid', dbt_valid_to)::timestamp_ntz   as valido_hasta,
    dbt_valid_to is null                                                as es_vigente,
    dbt_is_deleted = 'True'                                             as esta_borrado
from {{ ref('piloto_snapshot') }}