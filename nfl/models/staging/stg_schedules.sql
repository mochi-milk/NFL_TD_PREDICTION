-- One row per game: who played, when, and the betting lines
select
    game_id,
    season,
    week,
    game_type,          -- REG for regular season, or a playoff round
    gameday,
    home_team,
    away_team,
    home_score,         -- empty for games not played yet
    away_score,
    spread_line,        -- betting spread
    total_line,         -- expected total points
    roof,               -- dome, outdoors, open or closed
    div_game            -- 1 if the teams are in the same division
from {{ source('bronze', 'schedules') }}
where game_id is not null