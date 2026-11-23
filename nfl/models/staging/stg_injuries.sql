-- One row per player per week on the injury report
select
    gsis_id as player_id, team, season, week, position,
    report_status,                                          -- Out, Doubtful, Questionable or empty
    report_status = 'Questionable'          as is_questionable,
    report_status in ('Out', 'Doubtful')    as is_out,      -- doubtful players almost never play
    practice_status like 'Limited%'         as limited_practice
from {{ source('bronze', 'injuries') }}
where gsis_id is not null