-- One row per team per scheduled game, past and upcoming
select game_id, season, week, home_team as team, away_team as opponent,
       home_score is not null as is_played
from {{ ref('stg_schedules') }}
union all
select game_id, season, week, away_team as team, home_team as opponent,
       away_score is not null as is_played
from {{ ref('stg_schedules') }}