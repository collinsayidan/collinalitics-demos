"""
Rebuild data.js for a Collinalitics demo project.

Reads the warehouse exports and writes this project's entire data layer to
data.js (~26 KB) in the same folder as this script.

Run it from anywhere:

    python demos/scotland-its/build_data.py

It finds its own source data, then prints every headline figure next to the
value Power BI should be showing. If a row is marked CHECK, do not deploy —
the site and the report have drifted apart.
"""

import json
import os
import sys
from pathlib import Path

import duckdb
import numpy as np

HERE = Path(__file__).resolve().parent          # demos/scotland-its
ROOT = HERE.parents[1]                          # project root
OUT  = HERE / "data.js"

# Figures Power BI should agree with. Update these when the warehouse changes
# and you have confirmed the new values in the report.
EXPECTED = {
    "cost_m":      1353.3,
    "jti":            1.167,
    "carbon_pct":    44.3,
    "obs":        96652,
    "collisions":   344,
    "co2_mt":         2.196,
    "top10_pct":     34.0,
}


# ── locate the source data ───────────────────────────────────────────────

def find_source():
    """Prefer Parquet; fall back to the CSV exports. Returns (dir, extension)."""
    candidates = [
        (ROOT / "site" / "sources" / "its", "parquet"),
        (ROOT / "powerbi" / "exports",      "csv"),
        (Path(r"C:/its_data/exports"),      "csv"),
    ]
    for path, ext in candidates:
        if (path / f"rpt_d1_executive.{ext}").exists():
            return path, ext
    print("ERROR: could not find the warehouse exports. Looked in:", file=sys.stderr)
    for path, ext in candidates:
        print(f"  {path}  (*.{ext})", file=sys.stderr)
    sys.exit(1)


SRC, EXT = find_source()

# The fact table is large and lives apart from the serving tables when Parquet.
FCT = ROOT / "site" / "static" / "data" / "fct_traffic_observation.parquet"
if not FCT.exists():
    FCT = SRC / f"fct_traffic_observation.{EXT}"

print(f"source : {SRC}  (*.{EXT})")
print(f"fact   : {FCT}")
print(f"output : {OUT}\n")

con = duckdb.connect()
q = lambda sql: con.execute(sql).fetchdf()

t    = lambda name: f"'{SRC / f'{name}.{EXT}'}'"
d1   = t("rpt_d1_executive")
site = t("dim_site")
risk = t("agg_site_risk_ranking")
cong = t("dim_congestion")
fct  = f"'{FCT}'"


# ── build ────────────────────────────────────────────────────────────────

D = {}

D["headline"] = q(f"""
    select round(sum(annualised_cost_gbp) / 1e6, 1)                      as cost_m,
           round(sum(mean_journey_time_index * observation_count)
                 / sum(observation_count), 3)                            as jti,
           round(100.0 * sum(annualised_carbon_cost_gbp)
                 / sum(annualised_cost_gbp), 1)                          as carbon_pct,
           sum(observation_count)                                        as obs,
           sum(collisions)                                               as collisions,
           round(sum(annualised_co2_tonnes) / 1e6, 3)                    as co2_mt
    from {d1}
""").to_dict("records")[0]

D["headline"].update(conformance=95.70, received=100000)

D["costComponents"] = [
    {"name": name,
     "value": round(float(q(f"select sum({col}) / 1e6 as v from {d1}").v[0]), 1)}
    for name, col in [
        ("Carbon",     "annualised_carbon_cost_gbp"),
        ("Delay",      "annualised_delay_cost_gbp"),
        ("Collisions", "annualised_collision_cost_gbp"),
        ("Breakdown",  "annualised_breakdown_cost_gbp"),
    ]
]

D["monthly"] = q(f"""
    select month_year_label                                              as lbl,
           year_month                                                    as ym,
           sum(total_vehicles)                                           as vehicles,
           round(sum(mean_journey_time_index * observation_count)
                 / sum(observation_count), 3)                            as jti,
           round(sum(annualised_cost_gbp) / 1e6, 1)                      as cost_m
    from {d1}
    group by 1, 2
    order by ym
""").to_dict("records")

D["corridors"] = q(f"""
    select corridor,
           round(sum(mean_journey_time_index * observation_count)
                 / sum(observation_count), 3)                            as jti,
           round(sum(annualised_cost_gbp) / 1e6, 1)                      as cost_m,
           round(100.0 * sum(annualised_carbon_cost_gbp)
                 / sum(annualised_cost_gbp), 0)                          as carbon_pct
    from {d1}
    group by 1
    order by cost_m desc
""").to_dict("records")

D["sites"] = q(f"""
    select s.site_code                                                   as code,
           s.road_name                                                   as road,
           s.city_name                                                   as city,
           s.corridor,
           s.urbanisation_band                                           as setting,
           s.road_type                                                   as type,
           round(s.latitude, 4)                                          as lat,
           round(s.longitude, 4)                                         as lon,
           round(r.annualised_cost_gbp / 1e6, 2)                         as cost_m,
           round(r.mean_journey_time_index, 3)                           as jti,
           round(r.congested_hours_pct, 1)                               as congested_pct,
           round(r.mean_collision_risk, 4)                               as risk,
           r.observed_accidents                                          as collisions,
           r.total_vehicles                                              as vehicles,
           r.scored_hours                                                as obs
    from {site} s
    join {risk} r on r.site_key = s.site_key
    order by r.annualised_cost_gbp desc
""").to_dict("records")

D["congestion"] = q(f"""
    select d.congestion_level                                            as level,
           d.display_colour_hex                                          as colour,
           count(*)                                                      as obs,
           round(100.0 * count(*) / sum(count(*)) over (), 1)            as obs_pct,
           round(sum(f.annualised_cost_gbp) / 1e6, 1)                    as cost_m,
           round(100.0 * sum(f.annualised_cost_gbp)
                 / sum(sum(f.annualised_cost_gbp)) over (), 1)           as cost_pct
    from {fct} f
    join {cong} d on d.congestion_key = f.congestion_key
    group by 1, 2, d.congestion_key
    order by d.congestion_key
""").to_dict("records")

top10 = sum(s["cost_m"] for s in D["sites"][:10])
D["headline"].update(
    top10_m=round(top10, 1),
    top10_pct=round(100 * top10 / D["headline"]["cost_m"], 1),
)


# ── write ────────────────────────────────────────────────────────────────

def clean(o):
    if isinstance(o, dict):        return {k: clean(v) for k, v in o.items()}
    if isinstance(o, list):        return [clean(v) for v in o]
    if isinstance(o, np.integer):  return int(o)
    if isinstance(o, np.floating): return float(o)
    return o

OUT.write_text("const ITS = " + json.dumps(clean(D), separators=(",", ":")) + ";\n",
               encoding="utf-8")


# ── verify ───────────────────────────────────────────────────────────────

print(f"wrote {OUT.name}  —  {OUT.stat().st_size:,} bytes\n")
print(f"{'figure':<16}{'built':>12}{'expected':>12}   status")
print("-" * 54)

drift = False
for key, expect in EXPECTED.items():
    got = float(D["headline"][key])
    ok = abs(got - expect) < 0.051
    drift = drift or not ok
    print(f"{key:<16}{got:>12,.3f}{expect:>12,.3f}   {'ok' if ok else '*** CHECK ***'}")

print("-" * 54)
print(f"{len(D['sites'])} sites · {len(D['monthly'])} months · {len(D['corridors'])} corridors")

comp = sum(c["value"] for c in D["costComponents"])
cong_total = sum(c["cost_m"] for c in D["congestion"])
print(f"\ncost components sum to £{comp:,.1f}m")
print(f"congestion levels sum to £{cong_total:,.1f}m")
print(f"headline total is      £{D['headline']['cost_m']:,.1f}m")

if drift:
    print("\nFIGURES HAVE MOVED. Confirm the new values in Power BI, update EXPECTED "
          "at the top of this file, then deploy.")
    sys.exit(1)

print("\nAll figures reconcile. Safe to deploy.")