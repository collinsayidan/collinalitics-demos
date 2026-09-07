#!/usr/bin/env python3
"""
One-command PostgreSQL loader for the Scotland ITS Analytics Platform.
======================================================================

Loads all 27 warehouse tables straight into PostgreSQL over the normal database
connection. It deliberately avoids every mechanism that commonly fails:

  * no psql  ->  so "\\copy is not a command" in the pgAdmin Query Tool cannot happen
  * no server-side COPY  ->  so "could not open file ... Permission denied" cannot happen
  * no relative paths  ->  so the working directory does not matter
  * no import wizard  ->  so column mapping cannot drift

Usage
-----
    pip install psycopg2-binary

    python postgres/load_to_postgres.py --password YOUR_PASSWORD

    # other options
    --host localhost --port 5432 --user postgres --dbname its_analytics
    --data-dir path/to/powerbi/exports      (default: ../powerbi/exports)
    --dry-run           check the files and headers, connect to nothing
    --skip-constraints  load only, add keys and indexes later
"""

import argparse
import csv
import io
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DATA = os.path.normpath(os.path.join(HERE, "..", "powerbi", "exports"))

EXPECTED = {
    "marts": {
        "dim_date": 1096, "dim_time": 24, "dim_site": 74, "dim_congestion": 4,
        "dim_incident": 6, "dim_event": 6, "dim_sensor_status": 3, "dim_weather": 3,
        "dim_model_metric": 21, "fct_traffic_observation": 96652,
        "fct_data_quality": 100000, "fct_risk_score": 96652,
        "agg_network_daily": 22838, "agg_site_hour_profile": 3551,
        "agg_corridor_month": 324, "agg_data_quality_daily": 59481,
        "agg_site_risk_ranking": 74,
    },
    "report": {
        "rpt_d1_executive": 792, "rpt_d2_congestion_profile": 3551,
        "rpt_d2_delay_attribution": 816, "rpt_d2_hour_dow_matrix": 3696,
        "rpt_d3_safety_monthly": 11779, "rpt_d3_risk_band_capture": 36,
        "rpt_d4_environment_monthly": 1548, "rpt_d4_aqi_matrix": 12090,
        "rpt_d5_governance_daily": 59481, "rpt_d5_rule_failures": 52224,
    },
}

# Load dimensions first so the foreign keys added afterwards validate cleanly.
ORDER = (["dim_date", "dim_time", "dim_site", "dim_congestion", "dim_incident",
          "dim_event", "dim_sensor_status", "dim_weather", "dim_model_metric",
          "fct_traffic_observation", "fct_data_quality", "fct_risk_score",
          "agg_network_daily", "agg_site_hour_profile", "agg_corridor_month",
          "agg_data_quality_daily", "agg_site_risk_ranking"]
         + list(EXPECTED["report"].keys()))


def schema_of(table):
    return "report" if table.startswith("rpt_") else "marts"


def say(msg, indent=0):
    print(" " * indent + msg, flush=True)


# ---------------------------------------------------------------- pre-flight
def preflight(data_dir):
    say("Checking source files")
    missing, mismatched = [], []
    for t in ORDER:
        path = os.path.join(data_dir, f"{t}.csv")
        if not os.path.exists(path):
            missing.append(t)
            continue
        with open(path, encoding="utf-8", newline="") as fh:
            header = next(csv.reader(fh))
        if not header or any(c.strip() == "" for c in header):
            mismatched.append(t)
    if missing:
        say(f"MISSING {len(missing)} file(s): {', '.join(missing)}", 2)
        say(f"Expected them in: {data_dir}", 2)
        return False
    if mismatched:
        say(f"BAD HEADER in: {', '.join(mismatched)}", 2)
        return False
    say(f"all 27 files present in {data_dir}", 2)
    return True


# ------------------------------------------------------------------- loading
def run_sql_file(cur, path, label):
    say(label)
    with open(path, encoding="utf-8") as fh:
        sql = fh.read()
    # strip psql meta-commands, which are not valid SQL
    sql = "\n".join(l for l in sql.split("\n")
                    if not l.strip().startswith("\\"))
    cur.execute(sql)
    say("done", 2)


def copy_table(cur, table, data_dir):
    schema = schema_of(table)
    path = os.path.join(data_dir, f"{table}.csv")
    size_mb = os.path.getsize(path) / 1e6
    t0 = time.time()
    with open(path, "r", encoding="utf-8", newline="") as fh:
        cur.copy_expert(
            f"COPY {schema}.{table} FROM STDIN WITH (FORMAT csv, HEADER true, NULL '')",
            fh,
        )
    cur.execute(f"SELECT count(*) FROM {schema}.{table}")
    n = cur.fetchone()[0]
    exp = EXPECTED[schema][table]
    flag = "ok " if n == exp else "!! "
    say(f"{flag}{schema}.{table:<28} {n:>7,} rows "
        f"({size_mb:5.1f} MB, {time.time()-t0:4.1f}s)"
        + ("" if n == exp else f"  EXPECTED {exp:,}"), 2)
    return n == exp


# ---------------------------------------------------------------- validation
CHECKS = [
    ("Journey Time Index", 1.167, 0.002,
     "SELECT round(avg(journey_time_index)::numeric,3) FROM marts.fct_traffic_observation"),
    ("Congested hours %", 8.14, 0.02,
     "SELECT round((100.0*sum(CASE WHEN congestion_key>=3 THEN 1 ELSE 0 END)/count(*))::numeric,2)"
     " FROM marts.fct_traffic_observation"),
    ("Annualised cost GBP m", 1353.3, 0.2,
     "SELECT round((sum(annualised_cost_gbp)/1e6)::numeric,1) FROM marts.fct_traffic_observation"),
    ("Carbon share %", 44.3, 0.2,
     "SELECT round((100.0*sum(carbon_cost_gbp*annualisation_factor)/sum(annualised_cost_gbp))::numeric,1)"
     " FROM marts.fct_traffic_observation"),
    ("Collisions", 344, 0.5,
     "SELECT sum(accident_flag) FROM marts.fct_traffic_observation"),
    ("Conformance %", 95.70, 0.02,
     "SELECT round((100.0*sum(is_fully_conformant)/count(*))::numeric,2) FROM marts.fct_data_quality"),
    ("Quarantine %", 3.35, 0.02,
     "SELECT round((100.0*sum(is_quarantined)/count(*))::numeric,2) FROM marts.fct_data_quality"),
    ("Rule 1 violations", 0, 0.5,
     "SELECT count(*) FROM marts.fct_traffic_observation WHERE vehicle_count IS NULL"
     " OR car_count IS NULL OR bus_count IS NULL OR hgv_count IS NULL"
     " OR motorcycle_count IS NULL OR van_count IS NULL"
     " OR vehicle_count <> car_count+bus_count+hgv_count+motorcycle_count+van_count"),
    ("D1 serving reconciles", 96652, 0.5,
     "SELECT sum(observation_count) FROM report.rpt_d1_executive"),
    ("D5 serving reconciles", 100000, 0.5,
     "SELECT sum(records_received) FROM report.rpt_d5_governance_daily"),
]


def validate(cur):
    say("")
    say("Validating against the verified warehouse")
    ok = True
    for name, expected, tol, sql in CHECKS:
        cur.execute(sql)
        got = cur.fetchone()[0]
        good = got is not None and abs(float(got) - float(expected)) <= tol
        ok = ok and good
        say(f"{'PASS' if good else 'FAIL'}  {name:<26} {got}"
            + ("" if good else f"   expected {expected}"), 2)
    return ok


# ------------------------------------------------------------------- driver
def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--host", default=os.environ.get("PGHOST", "localhost"))
    ap.add_argument("--port", default=os.environ.get("PGPORT", "5432"))
    ap.add_argument("--user", default=os.environ.get("PGUSER", "postgres"))
    ap.add_argument("--password", default=os.environ.get("PGPASSWORD", ""))
    ap.add_argument("--dbname", default=os.environ.get("PGDATABASE", "its_analytics"))
    ap.add_argument("--data-dir", default=DEFAULT_DATA)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--skip-constraints", action="store_true")
    a = ap.parse_args()

    say("=" * 66)
    say("  Scotland ITS Analytics Platform  ->  PostgreSQL")
    say("=" * 66)

    if not preflight(a.data_dir):
        sys.exit(1)
    if a.dry_run:
        say("\nDry run complete. Files are readable; nothing was written.")
        return

    try:
        import psycopg2
    except ImportError:
        say("\npsycopg2 is not installed. Run:")
        say("    pip install psycopg2-binary", 4)
        sys.exit(1)

    # ---- create the database if it does not exist --------------------------
    try:
        admin = psycopg2.connect(host=a.host, port=a.port, user=a.user,
                                 password=a.password, dbname="postgres")
        admin.autocommit = True
        with admin.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (a.dbname,))
            if cur.fetchone():
                say(f"\nDatabase '{a.dbname}' already exists")
            else:
                cur.execute(f'CREATE DATABASE "{a.dbname}"')
                say(f"\nCreated database '{a.dbname}'")
        admin.close()
    except Exception as e:
        say(f"\nCould not connect to PostgreSQL: {e}")
        say("Check the host, port, user and password. See TROUBLESHOOTING.md.", 2)
        sys.exit(1)

    conn = psycopg2.connect(host=a.host, port=a.port, user=a.user,
                            password=a.password, dbname=a.dbname)
    conn.autocommit = False
    cur = conn.cursor()

    t0 = time.time()
    try:
        run_sql_file(cur, os.path.join(HERE, "01_create_schema.sql"),
                     "\nCreating 27 tables in schemas 'marts' and 'report'")
        conn.commit()

        say("\nLoading data")
        all_ok = True
        for t in ORDER:
            all_ok &= copy_table(cur, t, a.data_dir)
        conn.commit()

        if not a.skip_constraints:
            run_sql_file(cur, os.path.join(HERE, "03_indexes_constraints.sql"),
                         "\nApplying primary keys, foreign keys and 25 indexes")
            conn.commit()

        good = validate(cur)
        say("")
        say("=" * 66)
        if all_ok and good:
            say(f"  SUCCESS - warehouse loaded and verified in {time.time()-t0:.0f}s")
            say("  Next: point Power BI at this database (Get Data > PostgreSQL)")
        else:
            say("  LOADED WITH DISCREPANCIES - see the FAIL lines above")
        say("=" * 66)
        sys.exit(0 if (all_ok and good) else 2)

    except Exception as e:
        conn.rollback()
        say(f"\nFAILED, rolled back: {type(e).__name__}: {e}")
        say("Nothing was left half-loaded. See TROUBLESHOOTING.md.", 2)
        sys.exit(1)
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
