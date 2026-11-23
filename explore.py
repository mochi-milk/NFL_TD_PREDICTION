import nflreadpy as nfl
import polars as pl

plays = nfl.load_pbp([2025])

run_pass = plays.filter(pl.col("play_type").is_in(["run", "pass"]))

# you want to see the value in that column
# print(plays["play_type"].value_counts())

counts = (run_pass.group_by("posteam").agg((pl.col("play_type") == "pass").sum().alias("passes"), (pl.col("play_type") == "run").sum().alias("runs")).with_columns((pl.col("passes") / (pl.col("passes") + pl.col("runs"))).round(3).alias("pass_rate")))
print(counts)

plays.write_parquet("nfl_2025.parquet")