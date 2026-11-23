-- =====================================================================
-- dim_caso01_club
-- Caso de uso 1: neumático más adecuado para ser rápido en tierra con lluvia.
-- Dimensión club: solo los atributos que el caso necesita (filtrar por superficie).
-- En gold las claves pasan de id_ a key_.
-- =====================================================================

select
    id_club         as key_club,
    nombre          as nombre_club,
    superficie
from {{ ref('slv_club') }}