-- =====================================================================
-- Macros de formato para la capa de staging (1:1 con bronze).
-- Solo cambian el FORMATO del dato, nunca su significado:
-- las correcciones de negocio (unidades, defaults, duplicados) van en silver.
-- =====================================================================


-- Texto numérico -> NUMBER.
-- Acepta coma decimal y quita lo que acompañe al número
-- ('25,5 ºC' -> 25.5 ; '80%' -> 80 ; ' 12 ' -> 12).
-- Si no hay número, devuelve NULL en lugar de romper la carga.
{% macro limpiar_numero(columna, escala=2) -%}
    try_to_number(
        regexp_substr(replace(trim({{ columna }}), ',', '.'), '-?[0-9]+([.][0-9]+)?'),
        38, {{ escala }}
    )
{%- endmacro %}


-- Texto de lista cerrada (Enum) -> formato canónico del modelo.
-- Quita espacios, tildes y unifica mayúsculas:
-- ' PORTÁTIL ' -> 'Portatil' ; 'secándose' -> 'Secandose'.
-- Lo que no sea un valor válido se queda tal cual para que lo cace el test accepted_values.
{% macro limpiar_enum(columna) -%}
    nullif(initcap(translate(lower(trim({{ columna }})), 'áéíóúü', 'aeiouu')), '')
{%- endmacro %}


-- Texto sí/no -> BOOLEAN. Lo que no se reconozca queda NULL.
{% macro limpiar_booleano(columna) -%}
    case
        when lower(trim({{ columna }})) in ('true', 't', '1', 'si', 'sí', 's', 'yes', 'y') then true
        when lower(trim({{ columna }})) in ('false', 'f', '0', 'no', 'n')                  then false
    end
{%- endmacro %}