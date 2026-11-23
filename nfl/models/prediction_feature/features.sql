with positions as (
    select season, player_id, any_value(position) as position
    from {{ ref('stg_rosters') }}
    group by season, player_id
)
select
    f.player_id, f.game_id, f.season, f.week,
    f.scored_td,
    p.position,
    f.rz_touches_last4, f.tds_last4,
    t.rz_run_rate_last4,
    te.te_target_share_last4,
    d.rush_tds_allowed_last4, d.pass_tds_allowed_last4,
    h.h2h_tds_last3, h.h2h_games_found,
    gl.implied_points,
    dp.pos_tds_allowed_last4,
    coalesce(i.is_questionable, false) as is_questionable,
    coalesce(i.is_out, false)          as is_out,
    coalesce(o.players_out, 0)
      - case when coalesce(i.is_out, false) then 1 else 0 end as teammates_out_same_pos
from {{ ref('player_recent_form') }} f
left join positions p                         on p.player_id = f.player_id and p.season = f.season
left join {{ ref('team_identity') }} t        on t.team = f.team and t.game_id = f.game_id
left join {{ ref('team_te_share') }} te       on te.team = f.team and te.game_id = f.game_id
left join {{ ref('defense_allowed') }} d      on d.defense_team = f.opponent and d.game_id = f.game_id
left join {{ ref('head_to_head') }} h         on h.player_id = f.player_id and h.game_id = f.game_id
left join {{ ref('game_lines') }} gl          on gl.team = f.team and gl.game_id = f.game_id
left join {{ ref('defense_vs_position') }} dp on dp.defense_team = f.opponent and dp.game_id = f.game_id
                                             and dp.position = p.position
left join {{ ref('stg_injuries') }} i         on i.player_id = f.player_id and i.team = f.team
                                             and i.season = f.season and i.week = f.week
left join {{ ref('teammate_injuries') }} o    on o.team = f.team and o.season = f.season
                                             and o.week = f.week and o.position = p.position