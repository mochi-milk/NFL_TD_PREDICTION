-- Share of each team's targets that went to tight ends over its last 4 games (upcoming games included)
with targets as (
    select pg.team, pg.game_id,
           sum(case when r.position = 'TE' then pg.targets else 0 end) as te_targets,
           sum(pg.targets) as all_targets
    from {{ ref('player_games') }} pg
    join {{ ref('stg_rosters') }} r
      on pg.player_id = r.player_id and pg.season = r.season
    group by pg.team, pg.game_id
),
by_game as (
    select tg.team, tg.game_id, tg.season, tg.week, t.te_targets, t.all_targets
    from {{ ref('team_game') }} tg
    left join targets t on t.team = tg.team and t.game_id = tg.game_id
)
select team, game_id, season, week,
       safe_divide(sum(te_targets) over last_4, sum(all_targets) over last_4) as te_target_share_last4
from by_game
window last_4 as (partition by team order by season, week rows between 4 preceding and 1 preceding)