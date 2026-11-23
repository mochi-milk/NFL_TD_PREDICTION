-- How often each team ran inside the 20 over its last 4 games (upcoming games included)
with rz as (
    select offense_team as team, game_id,
           avg(case when play_type = 'run' then 1 else 0 end) as rz_run_rate
    from {{ ref('stg_plays') }}
    where is_red_zone
    group by offense_team, game_id
),
by_game as (
    select tg.team, tg.game_id, tg.season, tg.week, rz.rz_run_rate
    from {{ ref('team_game') }} tg
    left join rz on rz.team = tg.team and rz.game_id = tg.game_id
)
select team, game_id, season, week,
       avg(rz_run_rate) over last_4 as rz_run_rate_last4
from by_game
window last_4 as (partition by team order by season, week rows between 4 preceding and 1 preceding)