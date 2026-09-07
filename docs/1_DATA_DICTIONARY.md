# Data Dictionary — Scotland ITS Dataset

**File:** `scotland_its_dataset.csv`
**Records:** 100,000
**Columns:** 40
**Period:** 2023-01-01 → 2025-12-31 (hourly sensor observations)
**Coverage:** 7 cities, 9 strategic roads, 74 distinct sensor sites
**Encoding:** UTF-8, comma-delimited, header row, no index column
**Grain:** one row = one roadside detector site × one hour

---

## ⚠️ Read this before loading

`Incident_Type` and `Event_Type` use the literal string `"None"` as a valid category (as specified). Pandas treats `"None"` as a null by default. Load with:

```python
df = pd.read_csv("scotland_its_dataset.csv",
                 keep_default_na=True,
                 na_values=["", " "],          # override the default NA list
                 parse_dates=["Date"])
```

Or simply `pd.read_csv(path, keep_default_na=False, na_values=[""])` if you want blanks-only as missing.

---

## Column reference

| # | Column | Type | Unit / Format | Domain & meaning |
|---|--------|------|---------------|------------------|
| 1 | `Record_ID` | string | `ITS-NNNNNN` | Surrogate primary key. 100,000 unique values, assigned in chronological order. **Never null, never duplicated.** |
| 2 | `Date` | date | `YYYY-MM-DD` | Calendar date of the observation. Range 2023-01-01 → 2025-12-31. |
| 3 | `Time` | time | `HH:MM:SS` | Clock time. Minutes take values 00/15/30/45 to mimic detector polling offsets. |
| 4 | `Year` | int | 2023–2025 | Derived from `Date`. |
| 5 | `Month` | int | 1–12 | Derived from `Date`. |
| 6 | `Quarter` | string | `Q1`–`Q4` | Calendar quarter. |
| 7 | `Week` | int | 1–52 | ISO-8601 week number. Note: early-January dates may carry week 52/53 of the prior ISO year — this is correct ISO behaviour, not an error. |
| 8 | `Day_of_Week` | string | Monday…Sunday | Full weekday name. |
| 9 | `Hour` | int | 0–23 | Hour of day; the analytical time key. |
| 10 | `City` | string | 7 values | Glasgow, Edinburgh, Aberdeen, Dundee, Inverness, Stirling, Perth. |
| 11 | `Council_Area` | string | 7 values | Scottish local authority: Glasgow City, City of Edinburgh, Aberdeen City, Dundee City, Highland, Stirling, Perth and Kinross. 1:1 with `City`. |
| 12 | `Road_ID` | string | 9 values | M8, M74, M77, M90, A9, A90, A82, A1, A96. |
| 13 | `Road_Type` | string | 3 values | `Motorway`, `Trunk Dual Carriageway`, `Trunk Single Carriageway`. Functionally determined by `Road_ID`. |
| 14 | `Latitude` | float | decimal degrees (WGS84) | 55.73 – 57.53. Sensor site location; sites sit on corridors radiating 1.5–22 km from the city centre. |
| 15 | `Longitude` | float | decimal degrees (WGS84) | −4.60 – −1.98. |
| 16 | `Vehicle_Count` | int | vehicles/hour | Total observed flow past the detector. **Business rule: equals the sum of the five class counts** (columns 17–21) in all non-defective rows. |
| 17 | `Car_Count` | int | vehicles/hour | Cars. ~76% of flow on average. |
| 18 | `Bus_Count` | int | vehicles/hour | Buses and coaches. Higher on urban links and in commuter peaks. |
| 19 | `HGV_Count` | int | vehicles/hour | Heavy goods vehicles (>3.5t). Highest on M74 (~12%) and A9 (~8%); collapses at weekends, peaks overnight. |
| 20 | `Motorcycle_Count` | int | vehicles/hour | Strongly seasonal (May–Sep ≈ 2× December). |
| 21 | `Van_Count` | int | vehicles/hour | LGVs. Concentrated in the working day, low at weekends. |
| 22 | `Average_Speed_kmh` | float | km/h, 1 dp | Time-mean speed across the link. Derived from a BPR speed-flow curve; falls monotonically as congestion rises. |
| 23 | `Speed_Limit_kmh` | int | km/h | Posted limit: 112 (70 mph), 96 (60 mph), 80 (50 mph managed motorway), 64 (40 mph urban trunk). Fixed per site. |
| 24 | `Congestion_Level` | string | 4 ordered levels | `Low` (JTI < 1.15) → `Medium` (1.15–1.45) → `High` (1.45–2.00) → `Severe` (≥ 2.00). Derived from `Journey_Time_Index`, so the ordering is internally consistent by construction. |
| 25 | `Journey_Time_Minutes` | float | minutes, 2 dp | Time to traverse the monitored segment (segment lengths 3.5–12.0 km, fixed per site) = segment_km / speed × 60. |
| 26 | `Journey_Time_Index` | float | ratio, 3 dp | Observed journey time ÷ free-flow journey time. 1.000 = free flow. Range 1.000–9.000. The core congestion KPI. |
| 27 | `Temperature_C` | float | °C, 1 dp | Air temperature. Month climatology + city offset + persistent daily synoptic anomaly + diurnal cycle (min ~02:00, max ~14:00). |
| 28 | `Rainfall_mm` | float | mm in the hour | 0.0 on dry hours (~80% of hours). Gamma-distributed intensity when wet; west coast (Glasgow) wetter than the east. |
| 29 | `Wind_Speed_kmh` | float | km/h, 1 dp | Gamma-distributed, seasonal (winter windier), coastal cities windier. |
| 30 | `Visibility_km` | float | km, 2 dp | Reduced by rain, overnight mist and winter radiation/freezing fog. Winter mean ≈ 24.6 km vs summer ≈ 34.0 km. |
| 31 | `Accident_Flag` | int | 0 / 1 | 1 if a road traffic collision was recorded on the link in that hour. |
| 32 | `Incident_Type` | string | 6 values | `None`, `Collision`, `Breakdown`, `Debris`, `Severe Weather`, `Vehicle Fire`. `Collision` implies `Accident_Flag = 1`. |
| 33 | `Roadworks_Flag` | int | 0 / 1 | Active roadworks. Skewed to summer months and to 21:00–05:00 (overnight working). |
| 34 | `Lane_Closure_Flag` | int | 0 / 1 | At least one lane closed. Caused by roadworks, collisions or obstructions; directly reduces effective link capacity. |
| 35 | `Public_Event_Flag` | int | 0 / 1 | A traffic-generating event was in progress near the link. |
| 36 | `Event_Type` | string | 6 values | `None`, `Football Match`, `Concert`, `Festival`, `Marathon`, `Public Gathering`. `Festival` concentrates in Edinburgh in August; `Football Match` on Saturday afternoons and midweek evenings. |
| 37 | `School_Holiday_Flag` | int | 0 / 1 | Approximate Scottish school holidays (summer ~1 Jul–14 Aug, Oct week, Christmas/New Year, February break, Easter). Suppresses the commuter peak, lifts midday travel. |
| 38 | `Air_Quality_Index` | int | index, 0–200 scale | Composite roadside pollution index. Rises with flow, HGV/bus share and urbanity; falls with wind speed and rainfall; winter inversions and summer photochemistry add a seasonal signal. |
| 39 | `CO2_Emission_kg` | float | kg CO₂ in the hour | Link-level tailpipe CO₂ = Σ(class count × emission factor × segment km) × congestion penalty. Factors (kg/km): car 0.168, van 0.232, bus 0.822, HGV 0.905, motorcycle 0.095. |
| 40 | `Traffic_Sensor_Status` | string | 3 values | `Active` (~92%), `Maintenance` (~4.5%), `Faulty` (~3.4%). Non-`Active` rows carry a much higher defect rate. |

---

## Derived / functionally dependent fields

These are safe to drop when modelling, to avoid leakage or collinearity:

| Field | Determined by |
|-------|---------------|
| `Year`, `Month`, `Quarter`, `Week`, `Day_of_Week` | `Date` |
| `Hour` | `Time` |
| `Council_Area` | `City` |
| `Road_Type`, `Speed_Limit_kmh`, `Latitude`, `Longitude` | site (`City` + `Road_ID` + coordinates) |
| `Congestion_Level` | `Journey_Time_Index` (hard-thresholded) |
| `Journey_Time_Minutes` | segment length ÷ `Average_Speed_kmh` |
| `Vehicle_Count` | sum of the five class counts |
| `CO2_Emission_kg` | class counts, speed, segment length |

> **Leakage warning:** if you predict `Congestion_Level`, you must exclude `Journey_Time_Index`, `Journey_Time_Minutes` and `Average_Speed_kmh` — the label is a deterministic function of them.

---

## Suggested star schema (for BI / warehouse work)

- **Fact:** `fact_traffic_observation` — grain (site_key, date_key, hour). Measures: `Vehicle_Count`, class counts, `Average_Speed_kmh`, `Journey_Time_Minutes`, `Journey_Time_Index`, `CO2_Emission_kg`, `Air_Quality_Index`, flags.
- **Dim Date:** `Date`, `Year`, `Quarter`, `Month`, `Week`, `Day_of_Week`, `School_Holiday_Flag`.
- **Dim Time:** `Hour`, peak/off-peak band.
- **Dim Site:** `Latitude`, `Longitude`, `Road_ID`, `Road_Type`, `Speed_Limit_kmh`, `City`, `Council_Area`.
- **Dim Incident / Dim Event:** `Incident_Type`, `Event_Type`.
- **Dim Sensor Status:** `Traffic_Sensor_Status`.

A natural key for the fact table is (`Latitude`, `Longitude`, `Road_ID`, `Date`, `Time`) — note this key is **intentionally not unique** (~3,200 rows are duplicate-timestamp defects; see the Data Quality Report).

---

## Reproducibility

The dataset is generated by `generate_its_dataset.py` with a fixed seed (`SEED = 20260809`). Re-running the script reproduces the file byte-for-byte. Adjust `N_RECORDS`, `START`/`END` or the parameter blocks at the top of the script to produce variants.
