-- How many players at each position each team has ruled out that week
select team, season, week, position, count(*) as players_out
from {{ ref('stg_injuries') }}
where is_out
group by team, season, week, position