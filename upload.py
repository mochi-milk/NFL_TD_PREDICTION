from google.cloud import storage, bigquery
import os


os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(Path(__file__).parent / "key.json")

from google.cloud import storage, bigquery

BUCKET = "nfl-td-vanessa"       # your bucket name
PROJECT = "nfl-td-predictor"    # your project ID

# Step 1: upload the file to Cloud Storage
bucket = storage.Client().bucket(BUCKET)
bucket.blob("bronze/nfl_2025.parquet").upload_from_filename("nfl_2025.parquet")

# Step 2: load the file into a BigQuery table
settings = bigquery.LoadJobConfig(source_format="PARQUET", write_disposition="WRITE_TRUNCATE")
job = bigquery.Client().load_table_from_uri(
    f"gs://{BUCKET}/bronze/nfl_2025.parquet",   # where the file is
    f"{PROJECT}.nfl_bronze.plays_2025",          # the table to create
    job_config=settings,
)
job.result()   # wait until it finishes
print("Loaded!")