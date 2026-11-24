-- =====================================================================
-- int_set_up__limpio
-- Capa: intermedia, previa a silver (convención Cívica: int_ -> slv_).
-- Grano: un set-up (id_resultado), ya SIN duplicados.
--
-- Qué hace (reglas fila a fila, ver claude/decisiones_limpieza_silver.md):
--   1. Traduce erratas y abreviaturas de las listas cerradas.
--   2. Lo que siga fuera de lista o de rango pasa a NULL: lo rellenará la
--      moda de su entidad en cada modelo slv_.
--   3. Aplica las reglas de unidades del set-up (muelle, altura, densidad, alerón).
--   4. Deduplica: por cada id_resultado se queda la versión más rica en información.
-- =====================================================================

-- Columnas que cuentan para la "riqueza" de cada versión de un set-up duplicado
{% set columnas_calidad = [
    'temperatura', 'humedad', 'viento', 'condicion_meteo',
    'superficie', 'longitud_circuito',
    'licencia', 'email', 'telefono', 'maleta', 'tiene_mecanico',
    'estado_coche', 'clase', 'anio_produccion', 'motorizacion',
    'neumatico', 'grosor_muelle', 'altura_chasis', 'densidad_silicona_diferencial',
    'grado_inclinacion_aleron', 'tiempo_total'
] %}

with staging as (

    select * from {{ ref('stg_set_up__tabla_cruda') }}

),

reglas as (

    select
        -- ---------- Claves y datos sin reglas
        id_resultado,
        id_carrera,
        id_club,
        id_piloto,
        id_coche,
        id_modelo,
        fecha_carrera,
        numero_vueltas,
        numero_pilotos,
        nombre_club,
        numero_socios,
        numero_curvas,
        numero_saltos,
        nombre_piloto,
        email,
        telefono,
        licencia,
        modelo,
        marca,
        escala,                                      -- el 10 lo corrige la moda del modelo

        -- ---------- Carrera: fuera de rango -> NULL (lo rellena la moda de la carrera)
        case when temperatura between -15 and 50 then temperatura end         as temperatura,
        case when humedad between 0 and 100 then humedad end                  as humedad,
        case when viento >= 0 then viento end                                 as viento,
        case
            when condicion_meteo = 'Llovisna' then 'Llovizna'
            when condicion_meteo in ('Lluvia', 'Llovizna', 'Secandose', 'Seco') then condicion_meteo
        end                                                                   as condicion_meteo,

        -- ---------- Club: fuera de lista o de rango -> NULL (moda del club)
        case when superficie in ('Tierra', 'Asfalto', 'Moqueta') then superficie end as superficie,
        case when longitud_circuito between 50 and 1000 then longitud_circuito end   as longitud_circuito,

        -- ---------- Piloto
        case
            when lower(trim(nombre_club_piloto)) in ('independiente', '-', '--', 'n/a', 'ninguno', 'sin club')
                then null                                                     -- NULL = independiente
            else nombre_club_piloto
        end                                                                   as nombre_club_piloto,
        case when maleta in ('Ruedas', 'Portatil', 'Otra') then maleta end    as maleta,
        tiene_mecanico,

        -- ---------- Coche (el estado no varía con el tiempo: moda del coche)
        case
            when estado_coche = 'Usdo'  then 'Usado'
            when estado_coche = 'Nueva' then 'Nuevo'
            when estado_coche in ('Nuevo', 'Usado', 'Viejo') then estado_coche
        end                                                                   as estado_coche,

        -- ---------- Modelo
        case
            when clase = 'Bugy' then 'Buggy'
            when clase in ('Buggy', 'Truggy') then clase
        end                                                                   as clase,
        case
            when anio_produccion between 2000 and year(current_date()) then anio_produccion
        end                                                                   as anio_produccion,
        case
            when motorizacion in ('Gasoliba', 'Gas', 'Nitro') then 'Gasolina'
            when motorizacion in ('Gasolina', 'Electrico') then motorizacion
        end                                                                   as motorizacion,

        -- ---------- Set-up (reglas propias de cada fila)
        case
            when neumatico in ('B', 'Super Blando') then 'Blando'
            when neumatico = 'M' then 'Medio'
            when neumatico = 'D' then 'Duro'
            when neumatico in ('Blando', 'Medio', 'Duro') then neumatico
        end                                                                   as neumatico,
        case
            when grosor_muelle > 5 then grosor_muelle / 10                    -- décimas de mm -> mm
            else grosor_muelle
        end                                                                   as grosor_muelle,
        case
            when abs(altura_chasis) > 10 then abs(altura_chasis) / 10        -- mm -> cm
            else abs(altura_chasis)
        end                                                                   as altura_chasis,
        coalesce(lleva_contrapesos, false)                                    as lleva_contrapesos,
        abs(densidad_silicona_diferencial)                                    as densidad_silicona_diferencial,
        case
            when grado_inclinacion_aleron between 0 and 90 then grado_inclinacion_aleron
        end                                                                   as grado_inclinacion_aleron,
        tiempo_total,
        tiempo_total_seg,

        _loaded_at

    from staging

),

puntuado as (

    select
        *,
        -- Número de columnas con dato válido: cuanto más alto, más rica es la versión
        {% for columna in columnas_calidad -%}
        iff({{ columna }} is not null, 1, 0){% if not loop.last %} + {% endif %}
        {% endfor -%}
        as calidad
    from reglas

)

select * exclude (calidad)
from puntuado
-- Entre versiones igual de ricas, gana la que llegó más tarde a bronze
-- (además hace la elección determinista y la necesita el incremental de slv_resultado)
qualify row_number() over (partition by id_resultado order by calidad desc, _loaded_at desc) = 1