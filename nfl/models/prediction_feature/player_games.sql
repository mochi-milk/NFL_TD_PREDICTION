-- One row per player per game, plus a blank row for each player's next game
with touches as (
    select game_id, season, week, offense_team as team, defense_team as opponent,
           rusher_player_id as player_id, 1 as carry, 0 as target, is_red_zone,
           case when td_player_id = rusher_player_id then 1 else 0 end as td
    from {{ ref('stg_plays') }}
    where play_type = 'run' and rusher_player_id is not null

    union all

    select game_id, season, week, offense_team, defense_team,
           receiver_player_id, 0, 1, is_red_zone,
           case when td_player_id = receiver_player_id then 1 else 0 end
    from {{ ref('stg_plays') }}
    where play_type = 'pass' and receiver_player_id is not null
),
played as (
    select player_id, team, opponent, game_id, season, week,
           sum(carry) as carries,
           sum(target) as targets,
           sum(case when is_red_zone then carry + target else 0 end) as rz_touches,
           sum(td) as touchdowns
    from touches
    group by player_id, team, opponent, game_id, season, week
),
last_game as (              -- each player's most recent game and team
    select player_id, team, season, week
    from played
    where true
    qualify row_number() over (partition by player_id order by season desc, week desc) = 1
),
next_game as (              -- each team's next unplayed game this season
    select team, opponent, game_id, season, week
    from {{ ref('team_game') }}
    where not is_played
      and season = (select max(season) from {{ ref('team_game') }})
    qualify row_number() over (partition by team order by week) = 1
),
upcoming as (               -- players who played in the last 4 weeks get a row for that game
    select l.player_id, n.team, n.opponent, n.game_id, n.season, n.week,
           cast(null as int64) as carries, cast(null as int64) as targets,
           cast(null as int64) as rz_touches, cast(null as int64) as touchdowns
    from last_game l
    join next_game n
      on n.team = l.team and n.season = l.season and n.week - l.week <= 4
)
select * from played
union all
select * from upcoming