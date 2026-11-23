-- Rushing and passing TDs each defense allowed over its last 4 games (upcoming games included)
with tds as (
    select defense_team, game_id,
           sum(case when play_type = 'run'  and td_player_id = rusher_player_id   then 1 else 0 end) as rush_tds_allowed,
           sum(case when play_type = 'pass' and td_player_id = receiver_player_id then 1 else 0 end) as pass_tds_allowed
    from {{ ref('stg_plays') }}
    group by defense_team, game_id
),
by_game as (
    select tg.team as defense_team, tg.game_id, tg.season, tg.week,
           tds.rush_tds_allowed, tds.pass_tds_allowed
    from {{ ref('team_game') }} tg
    left join tds on tds.defense_team = tg.team and tds.game_id = tg.game_id
)
select defense_team, game_id, season, week,
       avg(rush_tds_allowed) over last_4 as rush_tds_allowed_last4,
       avg(pass_tds_allowed) over last_4 as pass_tds_allowed_last4
from by_game
window last_4 as (partition by defense_team order by season, week rows between 4 preceding and 1 preceding)