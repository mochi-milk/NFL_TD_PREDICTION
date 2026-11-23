-- Each player's last 4 games, NOT counting the current game
select
    player_id, team, opponent, game_id, season, week,
    touchdowns > 0 as scored_td,               -- the answer the model learns from
    avg(rz_touches) over last_4 as rz_touches_last4,
    sum(touchdowns) over last_4 as tds_last4
from {{ ref('player_games') }}
window last_4 as (
    partition by player_id                     -- one player at a time
    order by season, week                      -- in date order
    rows between 4 preceding and 1 preceding   -- the 4 games before this one
)