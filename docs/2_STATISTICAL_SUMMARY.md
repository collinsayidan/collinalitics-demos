# Statistical Summary — Scotland ITS Dataset

100,000 records · 40 columns · 2023-01-01 → 2025-12-31 · 74 sensor sites · 22 MB CSV (~105 MB in pandas)

All figures are computed by `validate_and_profile.py` (cached in `profile.json`). Unless stated otherwise, **behavioural statistics use the "clean" subset**: `Traffic_Sensor_Status = Active`, non-null flow, flow > 0, speed between 3 and 160 km/h → **91,997 rows (92.0%)**. Distributional statistics cover all 100,000 rows and therefore include injected defects.

---

## 1. Numeric distributions (all rows)

| Variable | Mean | Std | Min | P5 | Median | P95 | Max | Missing |
|---|---|---|---|---|---|---|---|---|
| Vehicle_Count | 1,949.7 | 1,972.2 | −40 | 125 | 1,362 | 6,125 | 40,420 | 147 |
| Car_Count | 1,481.0 | 1,485.9 | −40 | 94 | 1,041 | 4,514 | 32,178 | 160 |
| Bus_Count | 53.3 | 67.2 | 0 | 1 | 31 | 189 | 1,575 | 161 |
| HGV_Count | 156.2 | 177.8 | 0 | 10 | 101 | 538 | 4,456 | 146 |
| Motorcycle_Count | 26.1 | 32.0 | 0 | 1 | 15 | 94 | 920 | 174 |
| Van_Count | 233.0 | 256.3 | −35 | 12 | 150 | 782 | 5,576 | 154 |
| Average_Speed_kmh | 88.6 | 22.1 | −14.9 | 54.1 | 92.6 | 115.0 | 319.9 | 137 |
| Speed_Limit_kmh | 98.2 | 16.6 | 64 | 64 | 96 | 112 | 112 | 0 |
| Journey_Time_Minutes | 5.52 | 2.87 | 1.80 | 2.31 | 5.20 | 10.25 | 91.92 | 152 |
| Journey_Time_Index | 1.168 | 0.344 | 1.000 | 1.007 | 1.066 | 1.637 | 9.000 | 0 |
| Temperature_C | 9.09 | 5.54 | −8.1 | 0.3 | 9.0 | 18.3 | 29.7 | 240 |
| Rainfall_mm | 0.114 | 0.348 | 0.0 | 0.0 | 0.0 | 0.81 | 5.98 | 194 |
| Wind_Speed_kmh | 18.28 | 9.89 | 0.5 | 5.9 | 16.4 | 37.1 | 93.0 | 183 |
| Visibility_km | 29.38 | 5.66 | 0.15 | 20.15 | 29.45 | 38.47 | 45.0 | 213 |
| Air_Quality_Index | 44.1 | 16.8 | 11 | 23 | 41 | 76 | 174 | 207 |
| CO2_Emission_kg | 3,621.9 | 3,777.0 | 0.0 | 233.7 | 2,365.4 | 11,538.5 | 27,836.3 | 0 |

**External sanity anchors.** Monthly mean temperatures run 3.9 °C (Dec) to 15.3 °C (Jul), matching Scottish climatology. Mean rainfall of 0.114 mm/h implies ~1,000 mm/yr nationally and ~1,190 mm/yr in Glasgow — consistent with Met Office long-term averages (west ≫ east). Mean wind of 18.3 km/h with a 99th percentile near 50 km/h and a maximum of 93 km/h reflects an exposed maritime climate.

## 2. Categorical distributions (all rows)

| Field | Distribution |
|---|---|
| **Congestion_Level** | Low 71.01% · Medium 20.85% · High 5.87% · Severe 2.27% |
| **Traffic_Sensor_Status** | Active 92.13% · Maintenance 4.40% · Faulty 3.47% |
| **Road_Type** | Trunk Dual Carriageway 52.9% · Motorway 42.1% · Trunk Single Carriageway 5.0% |
| **Speed_Limit_kmh** | 112 km/h: 49.2% · 96: 28.4% · 64: 12.8% · 80: 9.5% |
| **Incident_Type** (non-`None` = 2,720 rows, 2.72%) | Breakdown 1,678 · Debris 526 · Collision 303 · Severe Weather 112 · Vehicle Fire 101 |
| **Event_Type** (non-`None` = 2,976 rows, 2.98%) | Public Gathering 1,421 · Concert 676 · Football Match 490 · Festival 366 · Marathon 23 |
| **Year** | 2023: 33,106 · 2024: 33,627 · 2025: 33,267 |
| **Quarter** | Q1 24,737 · Q2 24,853 · Q3 25,409 · Q4 25,001 |
| **Council_Area** | Glasgow City 24,530 · City of Edinburgh 22,454 · Aberdeen City 13,564 · Dundee City 10,484 · Stirling 10,001 · Perth and Kinross 9,875 · Highland 9,092 |

Binary flag prevalence: `School_Holiday_Flag` 24.34% · `Roadworks_Flag` 9.19% · `Lane_Closure_Flag` 5.68% · `Public_Event_Flag` 2.98% · `Accident_Flag` 0.36%.

## 3. Geography

### By city (clean subset)

| City | n | Mean flow (veh/h) | Mean speed (km/h) | Mean JTI | % Severe | Accident rate | Mean AQI |
|---|---|---|---|---|---|---|---|
| **Glasgow** | 22,594 | **3,055** | 85.2 | **1.28** | **5.11%** | 0.43% | **49.7** |
| **Edinburgh** | 20,666 | **2,533** | 90.5 | 1.23 | 3.37% | 0.30% | 46.3 |
| Aberdeen | 12,469 | 1,465 | 81.2 | 1.12 | 0.80% | 0.39% | 39.5 |
| Stirling | 9,176 | 1,366 | 101.8 | 1.08 | 0.27% | 0.27% | 40.2 |
| Perth | 9,084 | 1,274 | 92.3 | 1.07 | 0.36% | 0.35% | 42.8 |
| Dundee | 9,611 | 1,116 | 97.1 | 1.09 | 0.62% | 0.38% | 42.1 |
| Inverness | 8,397 | 754 | 76.4 | 1.07 | 0.26% | 0.31% | 38.2 |

Glasgow and Edinburgh lead on every congestion measure, as specified. The Glasgow : Inverness flow ratio is **4.05 : 1**, and Glasgow records severe congestion roughly 20× more often than Perth or Stirling.

### By road (clean subset)

| Road | Type | n | Mean flow | Mean speed | HGV share |
|---|---|---|---|---|---|
| M74 | Motorway | 5,909 | **3,530** | 94.1 | **12.2%** |
| M8 | Motorway | 18,488 | 3,220 | 87.1 | 8.1% |
| M77 | Motorway | 4,600 | 3,146 | 90.5 | 5.5% |
| M90 | Motorway | 9,787 | 2,351 | 99.2 | 9.1% |
| A1 | Dual | 4,568 | 1,629 | 86.3 | 5.8% |
| A90 | Dual | 19,726 | 1,380 | 90.5 | 6.4% |
| A96 | Dual | 10,275 | 1,271 | 83.9 | 6.8% |
| A9 | Dual | 14,035 | 944 | 86.7 | 8.2% |
| A82 | Single | 4,609 | **426** | **74.3** | 3.4% |

The M74 (the Scotland–England freight spine) carries the highest HGV share; the A82 (rural single carriageway, Loch Lomond corridor) has the lowest flow and lowest speeds.

## 4. Temporal patterns

### Hour of day (clean subset)

| Hour | Flow | Speed | JTI | | Hour | Flow | Speed | JTI |
|---|---|---|---|---|---|---|---|---|
| 00 | 497 | 96.9 | 1.05 | | 12 | 2,910 | 84.1 | 1.21 |
| **03** | **229** | 97.1 | 1.05 | | 13 | 2,910 | 83.9 | 1.22 |
| 05 | 725 | 97.0 | 1.05 | | 14 | 2,924 | 83.3 | 1.22 |
| 06 | 1,677 | 91.9 | 1.09 | | 15 | 3,119 | 81.2 | 1.27 |
| **07** | 2,867 | 80.9 | 1.31 | | **16** | 3,432 | 76.5 | 1.41 |
| **08** | **3,064** | **78.3** | **1.40** | | **17** | **3,482** | **75.8** | **1.43** |
| 09 | 2,653 | 85.9 | 1.19 | | 18 | 3,039 | 80.8 | 1.30 |
| 10 | 2,509 | 88.1 | 1.15 | | 20 | 1,802 | 92.9 | 1.07 |
| 11 | 2,712 | 86.5 | 1.18 | | 23 | 778 | 96.4 | 1.05 |

A clean bimodal profile: sharp AM peak at 08:00 and a broader, slightly higher PM peak spanning 16:00–17:00 — the standard UK urban-motorway signature. Peak (07/08/17) flow averages **3,140 veh/h** against **554 veh/h** overnight (01–04, 22–23): a **5.7× peak-to-trough ratio**. Speed bottoms at 75.8 km/h at 17:00, 22% below the 97 km/h overnight free-flow level.

### Day of week (clean subset)

| Day | Mean flow | Mean speed |
|---|---|---|
| Monday | 2,076 | 88.1 |
| Tuesday | 2,127 | 87.3 |
| Wednesday | 2,124 | 87.4 |
| Thursday | 2,192 | 86.8 |
| **Friday** | **2,295** | 85.7 |
| Saturday | 1,590 | 91.6 |
| Sunday | 1,351 | 93.5 |

Weekday vs weekend, decomposed by time band:

- **Commuter peak (07/08/17):** weekday 3,840 vs weekend 1,398 veh/h → **weekend peak-period traffic is 64% lower**.
- **Midday leisure window (11:00–14:00):** weekday 2,911 vs weekend 2,749 veh/h → **only 5.6% lower**.

That is exactly the pattern required: weekends shed the commuter peak almost entirely but retain — proportionally, dominate with — leisure travel through the middle of the day.

### Month / season

| Month | Temp °C | Rain mm/h | Visibility km | Wind km/h | Flow | Accident rate | AQI |
|---|---|---|---|---|---|---|---|
| Jan | 4.0 | 0.13 | **24.2** | 22.2 | 1,814 | 0.40% | 40.8 |
| Feb | 4.0 | 0.11 | 24.9 | 21.2 | 1,834 | 0.49% | 42.1 |
| Mar | 5.7 | 0.11 | 26.9 | 20.1 | 1,951 | 0.36% | 41.7 |
| Apr | 7.9 | 0.10 | 29.5 | 17.6 | 1,953 | 0.34% | 44.0 |
| May | 11.0 | 0.10 | 32.0 | 15.8 | 2,015 | 0.42% | 46.5 |
| Jun | 13.6 | 0.09 | 33.9 | 14.5 | 2,002 | 0.31% | 47.8 |
| Jul | **15.3** | 0.10 | **34.4** | **14.1** | 1,980 | 0.32% | 47.7 |
| Aug | 15.1 | 0.11 | 33.7 | 14.5 | 2,066 | 0.28% | **48.4** |
| Sep | 12.6 | 0.12 | 31.9 | 16.7 | **2,101** | **0.22%** | 46.0 |
| Oct | 9.4 | 0.13 | 29.3 | 19.0 | 1,987 | 0.36% | 42.7 |
| Nov | 6.2 | 0.13 | 26.8 | 21.1 | 1,920 | 0.44% | 41.0 |
| Dec | **3.9** | 0.13 | 24.8 | **22.9** | **1,762** | 0.41% | 40.2 |

Winter (Dec–Feb) vs summer (Jun–Aug): **visibility 24.6 km vs 34.0 km** and **accident rate 0.431% vs 0.303%** — a **42% winter uplift in collision risk**, driven by low visibility, sub-zero surface temperatures, higher rainfall frequency and higher winds. July flow sits below June/August because school-holiday commuter suppression bites hardest there. September is the busiest month (return to school and work with good conditions still holding).

## 5. Verification of the specified causal rules

### Congestion ↔ speed ↔ journey time (Rules 5, 6)

| Congestion_Level | n | Mean speed | Mean JTI | Mean flow | Mean journey time |
|---|---|---|---|---|---|
| Low | 71,012 | **94.6** | 1.05 | 1,215 | 5.09 min |
| Medium | 20,847 | 80.8 | 1.25 | 3,232 | 5.82 min |
| High | 5,873 | 62.9 | 1.65 | 5,119 | 7.18 min |
| Severe | 2,268 | **40.4** | 2.80 | 4,955 | 12.19 min |

Speed decreases monotonically across all four levels (94.6 → 80.8 → 62.9 → 40.4 km/h) and journey time increases monotonically. Mean flow *drops* from High to Severe: this is the hypercongestion branch of the fundamental diagram — once demand exceeds capacity, throughput falls while delay keeps rising. This is correct traffic-engineering behaviour, not an inconsistency.

**Correlation structure (clean subset):**

| Pair | r |
|---|---|
| Speed ↔ Journey_Time_Index | **−0.531** |
| Speed ↔ Vehicle_Count | −0.354 |
| Vehicle_Count ↔ Journey_Time_Index | +0.447 |
| Vehicle_Count ↔ CO2_Emission_kg | **+0.830** |
| Vehicle_Count ↔ Air_Quality_Index | +0.510 |
| Wind_Speed ↔ Air_Quality_Index | **−0.494** |
| Journey_Time_Index ↔ Accident_Flag | +0.269 |
| Rainfall ↔ Visibility | −0.198 |
| Temperature ↔ Visibility | +0.428 |

### Rainfall (Rule 7)

| | Dry hours | Wet hours | Change |
|---|---|---|---|
| Mean JTI | 1.162 | 1.193 | +2.7% |
| % High or Severe congestion | 7.93% | 9.28% | **+17% relative** |
| Accident rate | 0.344% | 0.443% | **+29% relative** |

### Roadworks (Rule 9)

| | No roadworks | Roadworks active | Change |
|---|---|---|---|
| Mean JTI | 1.143 | **1.408** | +23% |
| % High or Severe congestion | 7.08% | **18.85%** | **2.7×** |

### Accidents (Rule 10)

| | No accident | Accident | Change |
|---|---|---|---|
| Mean JTI | 1.162 | **2.711** | 2.3× |
| Mean speed | 88.8 km/h | **45.2 km/h** | −49% |
| Mean journey time | 5.50 min | **12.15 min** | 2.2× |

### Vehicle-count identity (Rule 1)

99,432 rows have all six count fields populated; **99,271 (99.84%) satisfy `Vehicle_Count = Car + Bus + HGV + Motorcycle + Van` exactly**. The 161 exceptions are the deliberately injected negative-value defects catalogued in the Data Quality Report.

## 6. Emissions and air quality

Mean link CO₂ is **3,622 kg per sensor-hour** (median 2,365 kg, P95 11,539 kg), scaling near-linearly with flow (r = 0.83) plus a stop-start penalty of up to +62% at very low average speeds. Summed across the 100,000 observed link-hours the dataset represents **≈362,000 tonnes of CO₂**.

Air Quality Index averages 44 (median 41, P95 76, max 174). Highest in Glasgow (49.7), lowest in Inverness (38.2). It tracks traffic through the day (r = +0.18 with hour, +0.51 with flow) and is strongly suppressed by wind (r = −0.49) and by rainfall washout, with a winter-inversion uplift on calm cold days.
