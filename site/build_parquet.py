#!/usr/bin/env python3
"""
Convert the warehouse CSV exports to ZSTD-compressed Parquet for the
Collinalitics ITS public site.

Evidence's DuckDB connector exposes any .parquet file placed in a source
directory as a queryable table named after the file, so this script writes
straight into site/sources/its/.

The large fact table is written separately into site/static/data/ because it
is not needed at build time -- it is fetched by the browser only when a
visitor opens the Explore page.

Usage:
    python build_parquet.py
    python build_parquet.py --exports ../powerbi/exports --check
"""

import argparse
import glob
import os
import sys

import duckdb

# Tables the Evidence pages query at build time.
SOURCE_TABLES = {
    "rpt_d1_executive",
    "rpt_d2_congestion_profile",
    "rpt_d2_delay_attribution",
    "rpt_d2_hour_dow_matrix",
    "rpt_d3_safety_monthly",
    "rpt_d3_risk_band_capture",
    "rpt_d4_environment_monthly",
    "rpt_d4_aqi_matrix",
    "rpt_d5_governance_daily",
    "rpt_d5_rule_failures",
    "dim_site",
    "dim_date",
    "dim_time",
    "dim_congestion",
    "dim_incident",
    "dim_event",
    "dim_sensor_status",
    "dim_weather",
    "dim_model_metric",
    "agg_site_risk_ranking",
    "agg_corridor_month",
    "agg_site_hour_profile",
}

# Tables shipped to the browser for client-side exploration.
STATIC_TABLES = {
    "fct_traffic_observation",
}

HERE = os.path.dirname(os.path.abspath(__file__))


def convert(csv_path: str, out_path: str, con: duckdb.DuckDBPyConnection) -> tuple:
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    con.execute(
        f"COPY (SELECT * FROM read_csv_auto('{csv_path}')) "
        f"TO '{out_path}' (FORMAT PARQUET, COMPRESSION ZSTD)"
    )
    csv_rows = con.execute(
        f"SELECT count(*) FROM read_csv_auto('{csv_path}')"
    ).fetchone()[0]
    pq_rows = con.execute(f"SELECT count(*) FROM '{out_path}'").fetchone()[0]
    return csv_rows, pq_rows, os.path.getsize(csv_path), os.path.getsize(out_path)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--exports", default=os.path.join(HERE, "..", "powerbi", "exports"))
    ap.add_argument("--check", action="store_true",
                    help="fail if any table's row count changes in conversion")
    args = ap.parse_args()

    exports = os.path.abspath(args.exports)
    if not os.path.isdir(exports):
        print(f"ERROR: exports directory not found: {exports}", file=sys.stderr)
        return 1

    src_dir = os.path.join(HERE, "sources", "its")
    static_dir = os.path.join(HERE, "static", "data")

    con = duckdb.connect()
    results, mismatches = [], []
    total_csv = total_pq = 0

    for csv_path in sorted(glob.glob(os.path.join(exports, "*.csv"))):
        table = os.path.basename(csv_path)[:-4]
        if table in SOURCE_TABLES:
            out_dir = src_dir
        elif table in STATIC_TABLES:
            out_dir = static_dir
        else:
            print(f"  skip  {table} (not referenced by the site)")
            continue

        out_path = os.path.join(out_dir, f"{table}.parquet")
        csv_rows, pq_rows, csv_b, pq_b = convert(csv_path, out_path, con)
        total_csv += csv_b
        total_pq += pq_b
        if csv_rows != pq_rows:
            mismatches.append((table, csv_rows, pq_rows))
        results.append((table, pq_rows, csv_b, pq_b))

    print()
    print(f"{'table':<34}{'rows':>10}{'csv MB':>10}{'parquet MB':>12}{'ratio':>8}")
    print("-" * 74)
    for table, rows, csv_b, pq_b in results:
        print(f"{table:<34}{rows:>10,}{csv_b/1e6:>10.2f}{pq_b/1e6:>12.2f}"
              f"{csv_b/max(pq_b,1):>7.1f}x")
    print("-" * 74)
    print(f"{'TOTAL':<34}{'':>10}{total_csv/1e6:>10.2f}{total_pq/1e6:>12.2f}"
          f"{total_csv/max(total_pq,1):>7.1f}x")

    if mismatches:
        print("\nROW COUNT MISMATCH:", file=sys.stderr)
        for table, c, p in mismatches:
            print(f"  {table}: csv={c:,} parquet={p:,}", file=sys.stderr)
        return 1 if args.check else 0

    print("\nAll row counts reconcile.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
