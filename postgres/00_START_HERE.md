# Start here — loading the platform into PostgreSQL

You have PostgreSQL open. This gets the whole warehouse into it in about ten minutes,
with no dbt, no Python and no porting. Work through the four scripts in order.

---

## Step 0 — create the database (1 min)

In psql, or in pgAdmin's Query Tool connected to `postgres`:

```sql
CREATE DATABASE its_analytics;
```

Then connect to it. Everything below assumes you are **in the `its_analytics` database**
and that your terminal's working directory is the `its_analytics_platform` folder —
the `\copy` paths are relative to it.

```bash
cd its_analytics_platform
psql -U postgres -d its_analytics
```

---

## Step 1 — create the tables (10 sec)

```bash
psql -U postgres -d its_analytics -f postgres/01_create_schema.sql
```

Creates two schemas and 27 tables:

- **`marts`** — the star schema: 8 dimensions, 3 facts, 5 aggregates
- **`report`** — the serving layer: 10 pre-aggregates, one set per dashboard

## Step 2 — load the data (1–2 min)

```bash
psql -U postgres -d its_analytics -f postgres/02_load_data.sql
```

Uses client-side `\copy`, so PostgreSQL needs no filesystem permissions and this works
against a remote server too. Roughly 550,000 rows in total.

> **If you are in pgAdmin rather than psql:** `\copy` is a psql command and will not run
> in the Query Tool. Either use the psql terminal, or right-click each table →
> *Import/Export Data* → Import, pick the matching CSV in `powerbi/exports/`, set
> Header = Yes, Delimiter = `,`, NULL string = empty.

## Step 3 — add keys and indexes (30 sec)

```bash
psql -U postgres -d its_analytics -f postgres/03_indexes_constraints.sql
```

Primary keys, 10 foreign keys and 25 indexes. Two things worth knowing:

- Constraints go on **after** the load, not before. Validating them afterwards proves the
  data is sound; enforcing them during the load just makes it slower.
- PostgreSQL does **not** index foreign key columns automatically, and every star-schema
  join uses one. These indexes are the difference between a 40 ms and a 4 s dashboard query.

## Step 4 — prove it loaded correctly (10 sec)

```bash
psql -U postgres -d its_analytics -f postgres/04_validation.sql
```

Every expected value is printed as a comment next to the query. You should see:

| Check | Expected |
|---|---|
| `fct_traffic_observation` rows | 96,652 |
| `fct_data_quality` rows | 100,000 |
| Journey Time Index | 1.167 |
| Annualised cost | £1,353.3m |
| Carbon share | 44.3% |
| Conformance | 95.70% |
| Rule 1 violations | **0** |
| Mean speed by congestion | 94.6 → 80.8 → 62.9 → 40.4 |
| Every serving table | 96,652 |

If a row count is short, the `\copy` hit a malformed row — rerun that one table.
If the measures are wrong but counts are right, you have a type mismatch; check the
`numeric` columns loaded as numbers rather than text.

---

## Then what?

**Point Power BI at PostgreSQL instead of the CSVs.** In Power BI Desktop:
*Get Data → PostgreSQL database* → server `localhost`, database `its_analytics` →
select all 27 tables. Everything else in `docs/02_POWERBI_BUILD_GUIDE.md` — relationships,
DAX, theme, RLS — is unchanged. The table and column names are identical.

Choose **Import** mode, not DirectQuery. At 96,652 rows the whole model compresses to a
few MB in memory and every visual renders instantly; DirectQuery would send a query per
visual to Postgres for no benefit at this size.

---

## Three ways to work, and which to pick

| Path | Effort | When it's right |
|---|---|---|
| **A. Load the CSVs into Postgres** *(these scripts)* | 10 min | You want the warehouse in Postgres now, to query with SQL and serve Power BI. **Start here.** |
| **B. Keep DuckDB as the build engine** | none | Already done. `./run_pipeline.sh` rebuilds everything from the raw CSV in ~90 seconds. |
| **C. Re-point dbt to build *inside* Postgres** | half a day | You want the transformation pipeline running natively in Postgres — the production shape. |

Path C is the honest one to flag: the dbt models are written in DuckDB SQL and would need
porting first. The specific incompatibilities are:

| DuckDB | PostgreSQL equivalent |
|---|---|
| `read_csv_auto(...)` | `COPY` into a landing table, or the `file_fdw` extension |
| `read_parquet(...)` | `COPY` from CSV, or `parquet_fdw` |
| `median(x)` | `percentile_cont(0.5) WITHIN GROUP (ORDER BY x)` |
| `quantile_cont(x, 0.95)` | `percentile_cont(0.95) WITHIN GROUP (ORDER BY x)` |
| `strftime(d, '%Y%m%d')` | `to_char(d, 'YYYYMMDD')` |
| `unnest(generate_series(...))` | `generate_series(...)` (already set-returning) |
| `date_diff('day', a, b)` | `(b - a)` for dates |
| `SELECT * EXCLUDE (col)` | list the columns explicitly |
| `VALUES` in a bare `FROM` | `FROM (VALUES ...) AS t(col, ...)` — mostly already compatible |

A `postgres` target is already stubbed in `dbt/profiles.yml`. Install `dbt-postgres`,
port the ten items above, and `dbt build --target postgres` — the tests, star schema and
serving layer come across unchanged.

---

## Useful first queries

```sql
-- Where is the money?
SELECT s.city_name,
       round((sum(f.annualised_cost_gbp)/1e6)::numeric, 1) AS annual_cost_gbp_m,
       round(avg(f.journey_time_index)::numeric, 3)        AS jti
FROM marts.fct_traffic_observation f
JOIN marts.dim_site s USING (site_key)
GROUP BY 1 ORDER BY 2 DESC;

-- What does disruption actually cost per hour?
SELECT disruption_cause,
       count(*)                                     AS hours,
       round(avg(journey_time_index)::numeric, 3)   AS jti,
       round(avg(delay_cost_gbp)::numeric)          AS cost_per_hour
FROM marts.fct_traffic_observation
GROUP BY 1 ORDER BY 1;

-- Which detectors should maintenance fix first?
SELECT site_code, city_name, operating_unit,
       sum(records_received)                                                    AS records,
       round((100.0*sum(records_quarantined)/sum(records_received))::numeric,2) AS quarantine_pct
FROM report.rpt_d5_governance_daily
GROUP BY 1,2,3
HAVING sum(records_received) > 500
ORDER BY quarantine_pct DESC
LIMIT 15;
```
