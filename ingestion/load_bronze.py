import os
from pathlib import Path

ROOT = Path(__file__).parent.parent                      # the NFL Prediction folder
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(ROOT / "key.json")

import nflreadpy as nfl
import polars as pl
from google.cloud import storage, bigquery
CURRENT = nfl.get_current_season()
BUCKET = "nfl-td-vanessa"
PROJECT = "nfl-td-predictor"
SEASONS = range(CURRENT, CURRENT + 1)              # backfill step: change to range(2015, 2027)
DATA_DIR = ROOT / "data"       # local copies go here, not all over your folders
DATA_DIR.mkdir(exist_ok=True)

# Turn datasets on one at a time: remove the # and run again
DATASETS = {
    "pbp": nfl.load_pbp,
    "schedules": nfl.load_schedules,
    "rosters": nfl.load_rosters,
    "injuries": nfl.load_injuries,
    "depth_charts": nfl.load_depth_charts,
}

def match_schema(df, schema):
    """Make an older season's columns and types match the newest season's."""
    missing = [pl.lit(None, dtype=t).alias(c) for c, t in schema.items() if c not in df.columns]
    return df.with_columns(missing).select(list(schema)).cast(dict(schema), strict=False)

def table_name(name, season):
    """Depth charts changed format in 2025, so newer seasons get their own table."""
    if name == "depth_charts" and season >= 2025:
        return "depth_charts_daily"
    return name

def save_to_bronze(df, table, season):
    """Save one season of one table to Cloud Storage."""
    local_file = DATA_DIR / f"{table}_{season}.parquet"
    df.write_parquet(local_file)
    path = f"bronze/{table}/season={season}/data.parquet"   # same path every run, so reruns replace it
    blob = storage.Client().bucket(BUCKET).blob(path, chunk_size=5 * 1024 * 1024)  # upload in 5 MB pieces
    blob.upload_from_filename(str(local_file), timeout=300)        
    print(f"Saved {table} {season}: {df.height} rows")

def load_table(table):
    """Load every season of one table into BigQuery."""
    settings = bigquery.LoadJobConfig(source_format="PARQUET", write_disposition="WRITE_TRUNCATE")
    job = bigquery.Client().load_table_from_uri(
        f"gs://{BUCKET}/bronze/{table}/*",
        f"{PROJECT}.nfl_bronze.{table}",
        job_config=settings,
    )
    job.result()
    print(f"Loaded table {table}")

for name, loader in DATASETS.items():
    schemas = {}                                        # newest season's columns, per table
    for season in sorted(SEASONS, reverse=True):        # newest season first
        df = loader([season])
        table = table_name(name, season)
        schemas.setdefault(table, df.schema)            # the first (newest) season sets the shape
        save_to_bronze(match_schema(df, schemas[table]), table, season)
    for table in schemas:
        load_table(table)