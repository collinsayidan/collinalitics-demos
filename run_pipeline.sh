#!/usr/bin/env bash
# =============================================================================
#  Scotland ITS Analytics Platform - end to end pipeline
#  Usage:  ./run_pipeline.sh
#  In production this maps 1:1 onto six Airflow / Dagster tasks, so a failure
#  is attributable to a stage rather than to "the pipeline".
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ITS_DUCKDB_PATH="${ITS_DUCKDB_PATH:-$ROOT/data/its_warehouse.duckdb}"
export ITS_ML_OUT="${ITS_ML_OUT:-$ROOT/data/ml}"
DBT_FLAGS="--profiles-dir $ROOT/dbt"
VARS="{ml_output_path: $ITS_ML_OUT}"

cd "$ROOT/dbt"

echo "== 1/6  reference data ==============================================="
dbt seed $DBT_FLAGS

echo "== 2/6  bronze -> staging -> intermediate -> marts ===================="
dbt run $DBT_FLAGS --exclude tag:ml --vars "$VARS"

echo "== 3/6  train and score predictive models ============================"
python3 "$ROOT/ml/train_score.py"

echo "== 4/6  machine learning marts ======================================="
dbt run $DBT_FLAGS --select tag:ml --vars "$VARS"

echo "== 5/6  assurance suite =============================================="
dbt test $DBT_FLAGS --vars "$VARS"

echo "== 6/6  export gold marts for Power BI ==============================="
ROOT="$ROOT" python3 - <<'PY'
import duckdb, os
root = os.environ["ROOT"]
db   = os.environ["ITS_DUCKDB_PATH"]
out  = os.path.join(root, "powerbi", "exports")
os.makedirs(out, exist_ok=True)
c = duckdb.connect(db, read_only=True)
for (t,) in c.execute("""select table_name from information_schema.tables
                          where table_schema='marts' order by table_name""").fetchall():
    c.execute(f"COPY (select * from marts.{t}) TO '{out}/{t}.csv' (HEADER, DELIMITER ',')")
    print(f"  exported {t}")
c.close()
PY

echo
echo "Pipeline complete. Lineage docs:  dbt docs generate && dbt docs serve"
