-- =====================================================================
-- stg_set_up__tabla_cruda
-- Capa: staging (1:1 con bronze: SET_UP.TABLA_CRUDA)
-- Grano: un set-up de un piloto (coche) en una carrera (club + fecha).
--
-- Qué hace:   cast de VARCHAR a su tipo, renombrado y formato homogéneo
--             (fechas, tiempos, enums, booleanos, números, teléfono, email).
-- Qué NO hace (va en silver): deduplicar, imponer defaults, corregir
--             unidades (ºF -> ºC, dm -> m), filtrar filas ni normalizar en tablas.
-- Nada se filtra: salen las mismas 25.250 filas que hay en bronze.
-- =====================================================================

with origen as (

    select * from {{ source('set_up', 'tabla_cruda') }}

),

preparado as (

    -- Texto recortado de las columnas con varios formatos posibles
    select
        *,
        trim(fecha)               as fecha_txt,
        regexp_replace(lower(trim(tiempo_total)), '^([0-9]{1,2})[.]([0-9]{2})[.]([0-9]{2})$', '\\1:\\2:\\3') as tiempo_txt
    from origen

),

tiempos as (

    -- tiempo_total a segundos, admitiendo hh:mm:ss, mm:ss, segundos sueltos o '45m 12s'
    select
        *,
        case
            when tiempo_txt rlike '[0-9]{1,2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?'
                then split_part(tiempo_txt, ':', 1)::number * 3600
                   + split_part(tiempo_txt, ':', 2)::number * 60
                   + split_part(tiempo_txt, ':', 3)::number(10, 3)
            when tiempo_txt rlike '[0-9]{1,3}:[0-9]{2}([.][0-9]+)?'                  -- mm:ss
                then split_part(tiempo_txt, ':', 1)::number * 60
                   + split_part(tiempo_txt, ':', 2)::number(10, 3)
            when tiempo_txt rlike '[0-9]+([.][0-9]+)?'                               -- segundos
                then tiempo_txt::number(10, 3)
            when tiempo_txt rlike '.*[0-9]+ *(h|m|min|s).*'                          -- 0h 45m 12s
                then coalesce(regexp_substr(tiempo_txt, '([0-9]+) *h', 1, 1, 'e', 1)::number, 0) * 3600
                   + coalesce(regexp_substr(tiempo_txt, '([0-9]+) *m', 1, 1, 'e', 1)::number, 0) * 60
                   + coalesce(regexp_substr(tiempo_txt, '([0-9]+) *s', 1, 1, 'e', 1)::number, 0)
        end as tiempo_total_seg
    from preparado

),

renombrado as (

    select
        -- ---------- Claves de origen (texto: silver genera las claves subrogadas)
        upper(trim(id_resultado))                       as id_resultado,
        upper(trim(id_carrera))                         as id_carrera,
        upper(trim(id_club))                            as id_club,
        upper(trim(id_piloto))                          as id_piloto,
        upper(trim(id_coche))                           as id_coche,
        upper(trim(id_modelo))                          as id_modelo,

        -- ---------- Carrera
        case
            when fecha_txt rlike '[0-9]{1,2}/[0-9]{1,2}/[0-9]{2}' then try_to_date(fecha_txt, 'DD/MM/YY')
            when fecha_txt rlike '[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}' then try_to_date(fecha_txt, 'DD/MM/YYYY')
            when fecha_txt rlike '[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}' then try_to_date(fecha_txt, 'DD-MM-YYYY')
            when fecha_txt rlike '[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}' then try_to_date(fecha_txt, 'YYYY-MM-DD')
            when fecha_txt rlike '[0-9]{4}/[0-9]{1,2}/[0-9]{1,2}' then try_to_date(fecha_txt, 'YYYY/MM/DD')
        end                                             as fecha_carrera,
        {{ limpiar_numero('numero_vueltas', 0) }}       as numero_vueltas,
        {{ limpiar_numero('numero_pilotos', 0) }}       as numero_pilotos,

        -- ---------- Meteorología (unidades tal cual vienen: se corrigen en silver)
        {{ limpiar_numero('temperatura') }}             as temperatura,
        {{ limpiar_numero('humedad') }}                 as humedad,
        {{ limpiar_enum('condicion') }}                 as condicion_meteo,
        {{ limpiar_numero('viento') }}                  as viento,

        -- ---------- Club / circuito
        trim(nombre_club)                               as nombre_club,
        {{ limpiar_numero('numero_socios', 0) }}        as numero_socios,
        {{ limpiar_numero('numero_curvas', 0) }}        as numero_curvas,
        {{ limpiar_numero('numero_saltos', 0) }}        as numero_saltos,
        {{ limpiar_enum('superficie') }}                as superficie,
        {{ limpiar_numero('longitud') }}                as longitud_circuito,

        -- ---------- Piloto
        {{ limpiar_numero('licencia', 0) }}             as licencia,
        trim(nombre_piloto)                             as nombre_piloto,
        lower(trim(email))                              as email,
        nullif(regexp_replace(telefono, '[^0-9+]', ''), '') as telefono,
        nullif(trim(club_piloto), '')                   as nombre_club_piloto,   -- NULL = independiente
        {{ limpiar_enum('maleta') }}                    as maleta,
        {{ limpiar_booleano('mecanico') }}              as tiene_mecanico,

        -- ---------- Coche y modelo
        {{ limpiar_enum('estado') }}                    as estado_coche,
        trim(modelo)                                    as modelo,
        {{ limpiar_enum('clase') }}                     as clase,
        nullif(trim(marca), '')                         as marca,

        case
            when escala rlike '.*[/:].*'                                          -- '1/8' o '1:8' -> 8
                then try_to_number(regexp_substr(trim(escala), '[0-9]+$'))
            when {{ limpiar_numero('escala', 3) }} > 0
             and {{ limpiar_numero('escala', 3) }} < 1                             -- '0.125' -> 8
                then round(1 / {{ limpiar_numero('escala', 3) }})
            else {{ limpiar_numero('escala', 0) }}                                 -- '8' -> 8
        end                                             as escala,



        {{ limpiar_numero('anio_produccion', 0) }}      as anio_produccion,
        {{ limpiar_enum('motorizacion') }}              as motorizacion,

        -- ---------- Set-up
        {{ limpiar_enum('neumatico') }}                 as neumatico,
        {{ limpiar_numero('grosor_muelle') }}           as grosor_muelle,
        {{ limpiar_numero('altura_chasis') }}           as altura_chasis,
        {{ limpiar_booleano('contrapesos') }}           as lleva_contrapesos,    -- el default false se pone en silver
        {{ limpiar_numero('densidad_silicona_diferencial') }} as densidad_silicona_diferencial,
        {{ limpiar_numero('grado_inclinacion_aleron') }}      as grado_inclinacion_aleron,

        -- ---------- Resultado
        case
            when tiempo_total_seg is not null
                then time_from_parts(0, 0, floor(tiempo_total_seg),
                                     round((tiempo_total_seg - floor(tiempo_total_seg)) * 1e9))
        end                                             as tiempo_total,
        tiempo_total_seg,

        -- ---------- Metadato de carga
        _loaded_at

        -- vuelta_promedio se descarta: es un derivado (tiempo_total / numero_vueltas)
        -- y se recalcula en gold, así no arrastramos un valor que pueda ser incoherente.

    from tiempos

)

select * from renombrado