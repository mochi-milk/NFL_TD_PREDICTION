-- One row per run or pass play, with clear column names
select
    concat(game_id, '-', cast(play_id as string)) as play_key,  -- unique ID for each play
    season,
    week,
    game_id,
    posteam as offense_team,
    defteam as defense_team,
    play_type,                           -- 'run' or 'pass'
    yardline_100 <= 20 as is_red_zone,   -- true when inside the 20
    rusher_player_id,
    receiver_player_id,
    td_player_id,                        -- who scored, if anyone
    touchdown
from {{ source('bronze', 'pbp') }}
where play_type in ('run', 'pass')