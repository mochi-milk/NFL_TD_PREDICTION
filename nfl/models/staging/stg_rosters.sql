-- One row per player per season: ID, name and position
select distinct
    season,
    gsis_id as player_id,                                           -- same ID format as the play-by-play data
    coalesce(full_name, concat(first_name, ' ', last_name)) as player_name,
    position
from {{ source('bronze', 'rosters') }}
where gsis_id is not null       -- a few players have no ID; they can't be matched to plays