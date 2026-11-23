-- Each player's touchdowns in his last 3 games against this opponent
select
    player_id, opponent, game_id, season, week,
    sum(touchdowns) over last_3 as h2h_tds_last3,
    count(*)        over last_3 as h2h_games_found
from {{ ref('player_games') }}
window last_3 as (partition by player_id, opponent order by season, week
                  rows between 3 preceding and 1 preceding)