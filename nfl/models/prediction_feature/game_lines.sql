-- Points each team is expected to score, from the betting lines (upcoming games included)
-- spread_line is positive when the home team is favored
select game_id, season, week, home_team as team,
       (total_line + spread_line) / 2 as implied_points
from {{ ref('stg_schedules') }}
union all
select game_id, season, week, away_team as team,
       (total_line - spread_line) / 2 as implied_points
from {{ ref('stg_schedules') }}