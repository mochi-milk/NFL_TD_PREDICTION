-- TDs each defense allowed to RBs, WRs and TEs over its last 4 games (upcoming games included)
with positions as (
    select season, player_id, any_value(position) as position
    from {{ ref('stg_rosters') }}
    group by season, player_id
),
pos as (
    select 'RB' as position union all select 'WR' union all select 'TE'
),
tds as (
    select pg.opponent as defense_team, pg.game_id, p.position, sum(pg.touchdowns) as tds_allowed
    from {{ ref('player_games') }} pg
    join positions p on p.player_id = pg.player_id and p.season = pg.season
    group by pg.opponent, pg.game_id, p.position
),
by_game as (
    select tg.team as defense_team, tg.game_id, tg.season, tg.week, pos.position,
           case when tg.is_played then coalesce(tds.tds_allowed, 0) end as tds_allowed
    from {{ ref('team_game') }} tg
    cross join pos
    left join tds on tds.defense_team = tg.team and tds.game_id = tg.game_id
                 and tds.position = pos.position
)
select defense_team, game_id, season, week, position,
       avg(tds_allowed) over last_4 as pos_tds_allowed_last4
from by_game
window last_4 as (partition by defense_team, position order by season, week
                  rows between 4 preceding and 1 preceding)