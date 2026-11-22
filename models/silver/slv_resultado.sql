with base as (
    select * 
    from {{ ref('stg_set_up__tabla_cruda')}}
)

select
    id_resultado,
    id_carrera
from base