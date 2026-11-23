from google.cloud import bigquery

PROJECT = "nfl-td-predictor"   # use your exact project ID

SQL = """
create or replace table `nfl_gold.predictions_latest` as
select
  current_date() as run_date,
  player_id, season, week,
  predicted_scored_td_probs
from ml.predict(
  model `nfl_gold.td_model`,
  (select * from `nfl_silver.features` where season = 2026)
)
"""

bigquery.Client(project=PROJECT).query(SQL).result()   # run it and wait
print("Predictions saved")