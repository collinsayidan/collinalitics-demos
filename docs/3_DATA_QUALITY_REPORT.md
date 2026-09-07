# Data Quality Report — Scotland ITS Dataset

**Scope:** `scotland_its_dataset.csv`, 100,000 records × 40 columns
**Assessment date:** 2026-08-09
**Verdict:** Fit for purpose, **with intentional defects**. This dataset was built for teaching and testing data-quality engineering, so roughly **4.5% of rows carry a deliberate defect signature**. Everything below is a catalogue of those defects, not a list of bugs.

---

## 1. Executive summary

| Dimension | Result | Status |
|---|---|---|
| Completeness | 2,268 blank cells across 13 columns; 1,320 rows (1.32%) have ≥1 blank | ⚠️ By design |
| Uniqueness (`Record_ID`) | 100,000 / 100,000 unique | ✅ Pass |
| Uniqueness (site-hour key) | 1,635 surplus rows share a (`Date`,`Time`,`Road_ID`,`Latitude`,`Longitude`) key | ⚠️ By design |
| Validity (ranges) | 213 speeds > 150 km/h; 221 negative speeds; 161 rows with a negative count | ⚠️ By design |
| Consistency (Rule 1 arithmetic) | 99.84% of complete rows pass exactly | ✅ Pass |
| Referential integrity | City→Council 1:1; Road→Road_Type 1:1; site→coords/limit stable | ✅ Pass |
| Business-logic consistency | Collision ⇒ Accident_Flag=1: 0 violations. Event flag ⇔ Event_Type: 0 violations. Lane closure always attributable: 0 orphans | ✅ Pass |
| Timeliness / coverage | All 36 months populated; 33,106 / 33,627 / 33,267 rows per year | ✅ Pass |
| Anomaly rate | 4.5% of rows (target: 2–5%) | ✅ Within spec |

---

## 2. Defect catalogue

Injected by `generate_its_dataset.py` (counts printed by the generator at run time):

| # | Defect class | Rows | % of file | How it manifests | How to detect |
|---|---|---|---|---|---|
| 1 | **Sensor failure (dead-zero)** | 638 | 0.64% | `Vehicle_Count = 0` and all five class counts 0, including in the middle of peak periods; `CO2_Emission_kg = 0`. Status set to `Faulty`. | `Vehicle_Count == 0 AND Hour BETWEEN 6 AND 20` |
| 2 | **Implausible speed** | 625 | 0.63% | Three sub-types: physically impossible (190–320 km/h, 213 rows), exact 0.0 km/h while flow is non-zero, and negative readings (221 rows down to −14.9). | `Average_Speed_kmh > Speed_Limit_kmh * 1.15 OR Average_Speed_kmh <= 0` |
| 3 | **Missing traffic readings** | 618 | 0.62% | 1–3 of {Vehicle_Count, class counts, Average_Speed_kmh, Journey_Time_Minutes} blanked, which also breaks the Rule 1 identity for those rows. | `IS NULL` on traffic columns |
| 4 | **Missing weather readings** | 702 | 0.70% | 1–2 of {Temperature_C, Rainfall_mm, Wind_Speed_kmh, Visibility_km, Air_Quality_Index} blanked. Traffic fields remain valid. | `IS NULL` on environmental columns |
| 5 | **Extreme traffic spike** | 456 | 0.46% | All counts multiplied by 3.0–6.5×, producing values up to 40,420 veh/h (~10× realistic motorway capacity). Rule 1 is preserved, so arithmetic checks will *not* catch these. | `Vehicle_Count > 4 × median(site, hour)` → 267 rows flagged |
| 6 | **Negative values** | 161 | 0.16% | One of Vehicle_Count / Car_Count / Van_Count set to −1…−40. | `< 0` on any count |
| 7 | **Duplicate timestamps** | 900 injected | 0.90% | Same site + `Date` + `Time` reported twice. 55% are exact replicas (double-reporting); 45% differ slightly in flow and speed (contradictory readings from redundant loops). | Group by (`Date`,`Time`,`Road_ID`,`Latitude`,`Longitude`) having count > 1 |

**Total injected:** 3,200 anomaly rows (3.20%) + 900 duplicate rows (0.90%) = **4.10%**.

**Additional incidental duplication:** because observations are sampled independently, a further ~735 site-hour keys collide by chance. The full duplicate-key population is **3,248 rows in 1,613 groups (1,635 surplus rows)**, of which **468 rows are byte-identical** on every column except `Record_ID`. Treat this as a realistic characteristic of a merged multi-source detector feed rather than a separate defect class.

**Union of all defect signatures (excluding duplicate keys):** 2,897 rows = **2.90%**. Including surplus duplicates: **≈4.5%**.

---

## 3. Completeness detail

2,268 blank cells, spread across 13 columns. No column exceeds 0.24% missing.

| Column | Missing | % | Column | Missing | % |
|---|---|---|---|---|---|
| Temperature_C | 240 | 0.24% | Motorcycle_Count | 174 | 0.17% |
| Visibility_km | 213 | 0.21% | Bus_Count | 161 | 0.16% |
| Air_Quality_Index | 207 | 0.21% | Car_Count | 160 | 0.16% |
| Rainfall_mm | 194 | 0.19% | Van_Count | 154 | 0.15% |
| Wind_Speed_kmh | 183 | 0.18% | Journey_Time_Minutes | 152 | 0.15% |
| — | — | — | Vehicle_Count | 147 | 0.15% |
| — | — | — | HGV_Count | 146 | 0.15% |
| — | — | — | Average_Speed_kmh | 137 | 0.14% |

**Missingness mechanism:** MAR, not MCAR. Missingness is strongly conditional on `Traffic_Sensor_Status`, which makes it a legitimate target for imputation modelling:

| Sensor status | Rows | Defect rate |
|---|---|---|
| Active | 92,132 | **1.27%** |
| Maintenance | 4,396 | **12.40%** |
| Faulty | 3,472 | **34.04%** |

Columns with **zero** missing values: `Record_ID`, all date/time parts, `City`, `Council_Area`, `Road_ID`, `Road_Type`, `Latitude`, `Longitude`, `Speed_Limit_kmh`, `Congestion_Level`, `Journey_Time_Index`, all five flags, `Incident_Type`, `Event_Type`, `CO2_Emission_kg`, `Traffic_Sensor_Status`.

> **Loader trap:** `Incident_Type` and `Event_Type` contain the literal string `"None"` for the no-incident / no-event case. Pandas' default NA list converts this to `NaN`, which will make ~97% of those columns look missing. Load with `keep_default_na=False, na_values=[""]` (or an explicit `na_values` list). This is a deliberate teaching hazard and does not indicate missing data.

---

## 4. Validity checks

| Check | Rows failing | Interpretation |
|---|---|---|
| `Average_Speed_kmh` > 150 km/h | 213 | Impossible on any UK road |
| `Average_Speed_kmh` > `Speed_Limit_kmh` × 1.15 | 213 | Same rows — no legitimate mild over-speeding is misclassified |
| `Average_Speed_kmh` ≤ 0 | 412 | 191 exact zeros + 221 negatives |
| Negative value in any count column | 161 | Physically impossible |
| `Vehicle_Count` = 0 | 638 | All are injected dead-zero failures |
| `Vehicle_Count` > 4 × site-hour median | 267 | Spike detector catches ~59% of the 456 injected spikes; the rest fall inside plausible bounds and are effectively undetectable — a realistic recall ceiling |
| `Journey_Time_Index` < 1.0 | 0 | Index is bounded below at free flow by construction |
| Coordinates outside Scotland bounding box | 0 | Lat 55.73–57.53, Lon −4.60 to −1.98 |
| `Temperature_C` outside [−25, 35] | 0 | Range −8.1 to 29.7 °C |
| `Rainfall_mm` < 0 or > 25 | 0 | Range 0 to 5.98 mm/h |

---

## 5. Consistency and integrity

**Passed with zero violations:**

- `Incident_Type = 'Collision'` ⇒ `Accident_Flag = 1` (0 violations).
- `Public_Event_Flag = 1` ⇔ `Event_Type ≠ 'None'` (0 violations).
- `Lane_Closure_Flag = 1` always accompanied by roadworks, an accident or a non-`None` incident (0 orphan closures).
- Each `City` maps to exactly one `Council_Area`; each `Road_ID` to exactly one `Road_Type`.
- Each sensor site (lat/lon pair) has a constant `Speed_Limit_kmh`, `Road_Type` and `City` throughout.
- `Congestion_Level` bands are perfectly consistent with `Journey_Time_Index` thresholds.

**Expected, documented asymmetry:** 58 rows have `Accident_Flag = 1` with `Incident_Type ≠ 'Collision'` (Vehicle Fire, Debris, Severe Weather). This is intentional — `Accident_Flag` marks any reportable accident, while `Incident_Type` names the dominant incident category. Document this in any downstream data contract.

**Rule 1 arithmetic:** of 99,432 rows with all six count fields present, 99,271 (99.84%) satisfy the identity exactly. All 161 failures are the negative-value defect class.

---

## 6. Suggested cleaning pipeline

```python
import pandas as pd

df = pd.read_csv("scotland_its_dataset.csv",
                 keep_default_na=False, na_values=[""],
                 parse_dates=["Date"])

COUNTS = ["Car_Count","Bus_Count","HGV_Count","Motorcycle_Count","Van_Count"]

# 1. Quarantine, do not silently drop
df["dq_negative"]    = (df[["Vehicle_Count"]+COUNTS] < 0).any(axis=1)
df["dq_speed"]       = (df.Average_Speed_kmh > df.Speed_Limit_kmh*1.15) | (df.Average_Speed_kmh <= 0)
df["dq_deadzero"]    = (df.Vehicle_Count == 0) & df.Hour.between(6, 20)
df["dq_missing"]     = df[["Vehicle_Count","Average_Speed_kmh"]+COUNTS].isna().any(axis=1)
df["dq_sum_mismatch"]= df.Vehicle_Count.notna() & (df[COUNTS].sum(axis=1) != df.Vehicle_Count)

site_hour = df.groupby(["Road_ID","Latitude","Hour"]).Vehicle_Count.transform("median")
df["dq_spike"]       = df.Vehicle_Count > 4*site_hour

dup_key = ["Date","Time","Road_ID","Latitude","Longitude"]
df["dq_duplicate"]   = df.duplicated(subset=dup_key, keep="first")

df["dq_any"] = df.filter(like="dq_").any(axis=1)

# 2. Analysis-ready view
clean = df[~df.dq_any]                              # ~95.5% of rows

# 3. Impute weather only (MAR given sensor status, city, month, hour)
for c in ["Temperature_C","Wind_Speed_kmh","Visibility_km","Air_Quality_Index"]:
    clean[c] = clean[c].fillna(clean.groupby(["City","Month","Hour"])[c].transform("median"))
clean["Rainfall_mm"] = clean.Rainfall_mm.fillna(0.0)  # zero-inflated: default to dry
```

**Deduplication policy:** for exact replicas keep the first row. For contradictory pairs (same key, different readings) prefer the row whose `Traffic_Sensor_Status = 'Active'`, then the one closer to the site-hour median; or average the two flows and take the harmonic mean of the speeds — harmonic, not arithmetic, because these are space-mean speeds.

**Imputation caution:** do not impute `Vehicle_Count` or `Average_Speed_kmh` before modelling congestion. Missingness is concentrated in `Faulty`/`Maintenance` sensors, so naive imputation injects a systematic bias exactly where the signal is weakest.

---

## 7. Known limitations of the synthetic generation

Stated plainly so no one over-claims from this data:

1. **Sites are synthetic.** Coordinates are plausible points on corridors radiating from each city centre, not the true positions of Traffic Scotland detectors. Do not geocode them against real infrastructure.
2. **Observations are sampled, not continuous.** Each row is an independently drawn site-hour, so the panel is unbalanced and sparse (~100k of ~1.95M possible site-hours). There is **no autocorrelation between consecutive hours at the same site** — this dataset therefore does not support genuine time-series modelling of a single detector. Aggregate to city-hour or city-day level for time-series work.
3. **No network topology.** Links are independent; there is no upstream/downstream propagation, no route choice and no queue spillback between sites.
4. **Weather is regionally, not spatially, coherent.** A shared daily anomaly per city makes weather realistic within a city-day but there is no continuous spatial field across Scotland.
5. **Calendar effects are approximate.** School holidays follow a generic Scottish pattern rather than per-council term dates; public holidays (Christmas Day, New Year, bank holidays) are not separately modelled beyond the school-holiday flag.
6. **No demographic, fleet-composition or fuel-mix drift.** Emission factors are constant across 2023–2025, so the dataset will not show EV-driven CO₂ decline.
7. **Anomalies are labelled by construction but not flagged in the file.** There is no ground-truth `is_anomaly` column — by design, so anomaly detection can be evaluated honestly. The generator's console output gives exact injected counts if you need approximate ground truth.
